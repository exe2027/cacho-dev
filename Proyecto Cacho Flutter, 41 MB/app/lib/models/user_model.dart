import 'dart:convert';

/// Modelo de datos del Usuario para autenticación, progresión, economía y cosméticos.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isGuest;

  // Progresión
  final int xp;
  final int level;

  // Economía Dual
  final int coins; // Monedas para buy-in en mesas
  final int cash;  // Billetes para comprar cosméticos

  // Estadísticas
  final int gamesPlayed;
  final int gamesWon;

  // Cosméticos equipados
  final String equippedCupSkinId;
  final String equippedFrameId;

  // Inventario de cosméticos adquiridos
  final List<String> ownedCupSkinIds;
  final List<String> ownedFrameIds;

  // Cambios de apodo (0 = 1er cambio gratis, 1+ = cuesta 500 Cash)
  final int nicknameChanges;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    this.avatarUrl = '',
    this.isGuest = true,
    this.xp = 0,
    this.level = 1,
    this.coins = 5000,
    this.cash = 100,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.equippedCupSkinId = 'cup_standard',
    this.equippedFrameId = 'frame_none',
    this.ownedCupSkinIds = const ['cup_standard'],
    this.ownedFrameIds = const ['frame_none'],
    this.nicknameChanges = 0,
  });

  /// XP requerida para alcanzar el siguiente nivel: nivel * 500 XP
  int get xpForNextLevel => level * 500;

  /// Progreso porcentual dentro del nivel actual (0.0 a 1.0)
  double get levelProgress {
    final needed = xpForNextLevel;
    if (needed <= 0) return 1.0;
    return (xp % needed) / needed;
  }

  /// Ratio de victorias
  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0.0;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isGuest,
    int? xp,
    int? level,
    int? coins,
    int? cash,
    int? gamesPlayed,
    int? gamesWon,
    String? equippedCupSkinId,
    String? equippedFrameId,
    List<String>? ownedCupSkinIds,
    List<String>? ownedFrameIds,
    int? nicknameChanges,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      cash: cash ?? this.cash,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      equippedCupSkinId: equippedCupSkinId ?? this.equippedCupSkinId,
      equippedFrameId: equippedFrameId ?? this.equippedFrameId,
      ownedCupSkinIds: ownedCupSkinIds ?? this.ownedCupSkinIds,
      ownedFrameIds: ownedFrameIds ?? this.ownedFrameIds,
      nicknameChanges: nicknameChanges ?? this.nicknameChanges,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isGuest': isGuest,
      'xp': xp,
      'level': level,
      'coins': coins,
      'cash': cash,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'equippedCupSkinId': equippedCupSkinId,
      'equippedFrameId': equippedFrameId,
      'ownedCupSkinIds': ownedCupSkinIds,
      'ownedFrameIds': ownedFrameIds,
      'nicknameChanges': nicknameChanges,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Jugador',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      isGuest: map['isGuest'] as bool? ?? true,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      coins: (map['coins'] as num?)?.toInt() ?? 5000,
      cash: (map['cash'] as num?)?.toInt() ?? 100,
      gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
      gamesWon: (map['gamesWon'] as num?)?.toInt() ?? 0,
      equippedCupSkinId: map['equippedCupSkinId'] as String? ?? 'cup_standard',
      equippedFrameId: map['equippedFrameId'] as String? ?? 'frame_none',
      ownedCupSkinIds: (map['ownedCupSkinIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['cup_standard'],
      ownedFrameIds: (map['ownedFrameIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['frame_none'],
      nicknameChanges: (map['nicknameChanges'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

