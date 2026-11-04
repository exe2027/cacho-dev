import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/cup_skin_model.dart';
import '../models/avatar_frame_model.dart';
import '../state/wallet.dart';

/// Servicio central para la gestión del usuario, niveles/XP, estadísticas y skins equipadas.
/// Persiste localmente con SharedPreferences y en la nube con Firestore cuando el usuario está autenticado.
class UserService extends ChangeNotifier {
  static final UserService instance = UserService._();
  UserService._();

  UserModel _user = const UserModel(id: 'guest_default', name: 'Jugador');
  bool _loaded = false;

  UserModel get user => _user.copyWith(coins: Wallet.instance.balance);
  bool get loaded => _loaded;

  CupSkinModel get equippedCupSkin => CupSkinModel.getById(_user.equippedCupSkinId);
  AvatarFrameModel get equippedFrame => AvatarFrameModel.getById(_user.equippedFrameId);

  /// Referencia de Firestore para el usuario actual
  DocumentReference<Map<String, dynamic>>? get _firestoreRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> load() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Cargar desde Firestore si hay sesión activa
        await syncFromFirestore(firebaseUser);
      } else {
        // Sin sesión: cargar desde SharedPreferences (invitado local)
        await _loadFromLocal();
      }
    } catch (_) {
      // Fallback para entornos de test o sin red
      await _loadFromLocal();
    }

    // Escuchar Wallet.instance para que las monedas de las salas y perfil sean idénticas
    Wallet.instance.removeListener(_onWalletChanged);
    Wallet.instance.addListener(_onWalletChanged);

    _loaded = true;
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    try {
      final p = await SharedPreferences.getInstance();
      final jsonStr = p.getString('cacho_user_profile');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _user = UserModel.fromJson(jsonStr);
      } else {
        // Perfil predeterminado de invitado
        _user = UserModel(
          id: 'guest_local',
          name: 'Jugador',
          coins: Wallet.instance.balance,
          cash: 100,
          level: 1,
          xp: 0,
        );
        await _saveToLocal();
      }
      // Sincronizar monedas con Wallet
      _user = _user.copyWith(coins: Wallet.instance.balance);
    } catch (_) {}
  }

  /// Sincroniza el perfil desde Firestore. Si no existe el documento, lo crea.
  Future<void> syncFromFirestore(User firebaseUser) async {
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
      final doc = await ref.get();

      if (doc.exists && doc.data() != null) {
        // Cargar datos existentes de Firestore
        final data = doc.data()!;
        _user = UserModel.fromMap({
          ...data,
          'id': firebaseUser.uid,
          'isGuest': firebaseUser.isAnonymous,
          'email': firebaseUser.email ?? data['email'] ?? '',
          'avatarUrl': firebaseUser.photoURL ?? data['avatarUrl'] ?? '',
        });
      } else {
        // Primer login: combinar datos locales con datos de Firebase
        final localData = _user.toMap();
        _user = _user.copyWith(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? _user.name,
          email: firebaseUser.email ?? '',
          avatarUrl: firebaseUser.photoURL ?? '',
          isGuest: firebaseUser.isAnonymous,
        );
        // Guardar en Firestore (primer registro)
        await ref.set({
          ...localData,
          'id': firebaseUser.uid,
          'name': _user.name,
          'email': _user.email,
          'avatarUrl': _user.avatarUrl,
          'isGuest': _user.isGuest,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      // Sincronizar monedas con Wallet
      Wallet.instance.setBalance(_user.coins);
      _user = _user.copyWith(coins: Wallet.instance.balance);

      // Actualizar timestamp de último login
      await ref.update({'lastLogin': FieldValue.serverTimestamp()});
    } catch (e) {
      // Si falla Firestore, usar datos locales como fallback
      await _loadFromLocal();
    }
    notifyListeners();
  }

  /// Crea un perfil de invitado con el UID de Firebase (anónimo)
  Future<void> createGuestProfile({required String uid, String? nickname}) async {
    final r = uid.substring(0, 6);
    final name = nickname ?? 'Jugador $r';
    _user = _user.copyWith(
      id: uid,
      name: name,
      email: '',
      avatarUrl: '',
      isGuest: true,
    );
    // Los invitados también tienen documento en Firestore para poder migrar sus datos
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          ..._user.toMap(),
          'isGuest': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
    await _saveToLocal();
    notifyListeners();
  }

  /// Migra los datos del invitado local a la cuenta de Google en Firestore.
  /// Toma el máximo de monedas/cash y une los items comprados.
  Future<void> migrateGuestToGoogle(User firebaseUser) async {
    final localUser = _user;

    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
      final doc = await ref.get();
      final Map<String, dynamic> cloudData = doc.exists ? doc.data()! : {};

      // Merge: tomar el máximo de economía y unir inventarios
      final mergedCoins = [localUser.coins, (cloudData['coins'] as num?)?.toInt() ?? 0].reduce((a, b) => a > b ? a : b);
      final mergedCash = [localUser.cash, (cloudData['cash'] as num?)?.toInt() ?? 0].reduce((a, b) => a > b ? a : b);
      final mergedLevel = [localUser.level, (cloudData['level'] as num?)?.toInt() ?? 1].reduce((a, b) => a > b ? a : b);
      final mergedXp = [localUser.xp, (cloudData['xp'] as num?)?.toInt() ?? 0].reduce((a, b) => a > b ? a : b);

      final cloudCupSkins = (cloudData['ownedCupSkinIds'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {};
      final cloudFrames = (cloudData['ownedFrameIds'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {};
      final mergedCupSkins = {...localUser.ownedCupSkinIds, ...cloudCupSkins}.toList();
      final mergedFrames = {...localUser.ownedFrameIds, ...cloudFrames}.toList();

      _user = localUser.copyWith(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? localUser.name,
        email: firebaseUser.email ?? '',
        avatarUrl: firebaseUser.photoURL ?? '',
        isGuest: false,
        coins: mergedCoins,
        cash: mergedCash,
        level: mergedLevel,
        xp: mergedXp,
        ownedCupSkinIds: mergedCupSkins,
        ownedFrameIds: mergedFrames,
      );

      Wallet.instance.setBalance(mergedCoins);

      await ref.set({
        ..._user.toMap(),
        'isGuest': false,
        'lastLogin': FieldValue.serverTimestamp(),
        if (!doc.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Si falla, igual actualizamos localmente
      _user = localUser.copyWith(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? localUser.name,
        email: firebaseUser.email ?? '',
        avatarUrl: firebaseUser.photoURL ?? '',
        isGuest: false,
      );
    }

    await _saveToLocal();
    notifyListeners();
  }

  /// Limpia el perfil local al cerrar sesión
  Future<void> clearLocalProfile() async {
    _user = const UserModel(id: 'guest_default', name: 'Jugador');
    Wallet.instance.setBalance(_user.coins);
    await _saveToLocal();
    notifyListeners();
  }

  /// Actualiza el apodo del usuario.
  /// 1er cambio: GRATIS (nicknameChanges == 0).
  /// 2do cambio en adelante: cuesta 500 Cash.
  /// Retorna un mapa {'success': bool, 'message': String}.
  Future<Map<String, dynamic>> updateNickname(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return {'success': false, 'message': 'El apodo no puede estar vacío'};
    }
    if (trimmed.length > 12) {
      return {'success': false, 'message': 'El apodo no puede superar 12 caracteres'};
    }
    if (trimmed == _user.name) {
      return {'success': false, 'message': 'El apodo es idéntico al actual'};
    }

    final isFree = _user.nicknameChanges == 0;
    const cost = 500;

    if (!isFree && _user.cash < cost) {
      return {
        'success': false,
        'message': 'Necesitas \$500 Cash para cambiar de apodo (tienes \$${_user.cash})',
      };
    }

    final newCash = isFree ? _user.cash : _user.cash - cost;
    final newChanges = _user.nicknameChanges + 1;

    _user = _user.copyWith(
      name: trimmed,
      cash: newCash,
      nicknameChanges: newChanges,
    );

    await save();

    return {
      'success': true,
      'message': isFree
          ? '¡Apodo cambiado gratis a "$trimmed"!'
          : '¡Apodo cambiado a "$trimmed" por \$500 Cash!',
    };
  }

  void _onWalletChanged() {
    if (_user.coins != Wallet.instance.balance) {
      _user = _user.copyWith(coins: Wallet.instance.balance);
      save();
    }
  }

  Future<void> save() async {
    await _saveToLocal();
    await _saveToFirestore();
    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('cacho_user_profile', _user.toJson());
    } catch (_) {}
  }

  Future<void> _saveToFirestore() async {
    try {
      final ref = _firestoreRef;
      if (ref == null) return;
      await ref.set({
        ..._user.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void updateProfile(UserModel newUser) {
    _user = newUser;
    save();
  }

  /// Otorga XP al finalizar una partida y procesa eventos de subida de nivel (Level-Up)
  /// Retorna un mapa con { 'leveledUp': bool, 'oldLevel': int, 'newLevel': int, 'rewardCash': int, 'rewardCoins': int }
  Map<String, dynamic> addMatchResult({required bool won, required int stake}) {
    // XP base por jugar: 80 XP. Si ganó: +220 XP (total 300 XP) + bonus proporcional al stake
    final int xpGained = won ? (250 + (stake ~/ 10)) : 80;
    int newXp = _user.xp + xpGained;
    int currentLevel = _user.level;
    bool leveledUp = false;
    int rewardCash = 0;
    int rewardCoins = 0;

    // Verificar si superó el umbral del nivel actual: nivel * 500 XP
    int neededXp = currentLevel * 500;
    while (newXp >= neededXp) {
      newXp -= neededXp;
      currentLevel++;
      leveledUp = true;
      // Recompensas por Level-Up: +50 Billetes Cash y +1000 Monedas Coins por nivel
      rewardCash += 50;
      rewardCoins += 1000;
      neededXp = currentLevel * 500;
    }

    if (rewardCoins > 0) {
      Wallet.instance.credit(rewardCoins);
    }

    _user = _user.copyWith(
      xp: newXp,
      level: currentLevel,
      cash: _user.cash + rewardCash,
      coins: Wallet.instance.balance,
      gamesPlayed: _user.gamesPlayed + 1,
      gamesWon: won ? (_user.gamesWon + 1) : _user.gamesWon,
    );

    save();

    return {
      'leveledUp': leveledUp,
      'oldLevel': _user.level - (leveledUp ? 1 : 0),
      'newLevel': currentLevel,
      'xpGained': xpGained,
      'rewardCash': rewardCash,
      'rewardCoins': rewardCoins,
    };
  }

  /// Añade monedas (Coins) directamente a la billetera compartida de salas
  void addCoins(int amount) {
    if (amount <= 0) return;
    Wallet.instance.credit(amount);
    _user = _user.copyWith(coins: Wallet.instance.balance);
    save();
  }

  /// Consume monedas para apuestas (Coins) desde la billetera compartida
  bool deductCoins(int amount) {
    if (amount <= 0) return true;
    final ok = Wallet.instance.charge(amount);
    if (ok) {
      _user = _user.copyWith(coins: Wallet.instance.balance);
      save();
    }
    return ok;
  }

  /// Añade billetes (Cash)
  void addCash(int amount) {
    if (amount <= 0) return;
    _user = _user.copyWith(cash: _user.cash + amount);
    save();
  }

  /// Consume billetes (Cash)
  bool deductCash(int amount) {
    if (amount <= 0) return true;
    if (_user.cash < amount) return false;
    _user = _user.copyWith(cash: _user.cash - amount);
    save();
    return true;
  }

  /// Comprar y equipar skin de vaso
  bool purchaseCupSkin(CupSkinModel skin) {
    if (_user.ownedCupSkinIds.contains(skin.id)) {
      // Ya lo posee, solo equipar
      equipCupSkin(skin.id);
      return true;
    }

    if (_user.cash < skin.priceCash) return false;

    final updatedOwned = List<String>.from(_user.ownedCupSkinIds)..add(skin.id);
    _user = _user.copyWith(
      cash: _user.cash - skin.priceCash,
      ownedCupSkinIds: updatedOwned,
      equippedCupSkinId: skin.id,
    );
    save();
    return true;
  }

  void equipCupSkin(String skinId) {
    if (_user.ownedCupSkinIds.contains(skinId)) {
      _user = _user.copyWith(equippedCupSkinId: skinId);
      save();
    }
  }

  /// Comprar y equipar marco de avatar
  bool purchaseAvatarFrame(AvatarFrameModel frame) {
    if (_user.ownedFrameIds.contains(frame.id)) {
      // Ya lo posee, solo equipar
      equipAvatarFrame(frame.id);
      return true;
    }

    if (_user.cash < frame.priceCash) return false;

    final updatedOwned = List<String>.from(_user.ownedFrameIds)..add(frame.id);
    _user = _user.copyWith(
      cash: _user.cash - frame.priceCash,
      ownedFrameIds: updatedOwned,
      equippedFrameId: frame.id,
    );
    save();
    return true;
  }

  void equipAvatarFrame(String frameId) {
    if (_user.ownedFrameIds.contains(frameId)) {
      _user = _user.copyWith(equippedFrameId: frameId);
      save();
    }
  }
}
