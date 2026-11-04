import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/cup_skin_model.dart';
import '../models/avatar_frame_model.dart';
import '../state/wallet.dart';

/// Servicio central para la gestión del usuario, niveles/XP, estadísticas y skins equipadas.
class UserService extends ChangeNotifier {
  static final UserService instance = UserService._();
  UserService._();

  UserModel _user = const UserModel(id: 'guest_default', name: 'Jugador');
  bool _loaded = false;

  UserModel get user => _user.copyWith(coins: Wallet.instance.balance);
  bool get loaded => _loaded;

  CupSkinModel get equippedCupSkin => CupSkinModel.getById(_user.equippedCupSkinId);
  AvatarFrameModel get equippedFrame => AvatarFrameModel.getById(_user.equippedFrameId);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final jsonStr = p.getString('cacho_user_profile');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _user = UserModel.fromJson(jsonStr);
      } else {
        // Inicializar perfil predeterminado
        _user = UserModel(
          id: 'guest_local',
          name: 'Jugador',
          coins: Wallet.instance.balance,
          cash: 100,
          level: 1,
          xp: 0,
        );
        await save();
      }
      // Asegurar sincronización inmediata con la billetera de las salas
      _user = _user.copyWith(coins: Wallet.instance.balance);
    } catch (_) {
      // Fallback para entornos de test
    }
    
    // Escuchar Wallet.instance para que las monedas de las salas y perfil sean idénticas
    Wallet.instance.removeListener(_onWalletChanged);
    Wallet.instance.addListener(_onWalletChanged);

    _loaded = true;
    notifyListeners();
  }

  void _onWalletChanged() {
    if (_user.coins != Wallet.instance.balance) {
      _user = _user.copyWith(coins: Wallet.instance.balance);
      save();
    }
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('cacho_user_profile', _user.toJson());
    } catch (_) {}
    notifyListeners();
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

