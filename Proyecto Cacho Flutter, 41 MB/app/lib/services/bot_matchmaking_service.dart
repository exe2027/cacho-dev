import 'dart:math';
import '../models/avatar_frame_model.dart';
import '../models/cup_skin_model.dart';
import '../models/bot_profile_model.dart';

/// Servicio para la generación procedural de perfiles y gamertags de bots estilo 8 Ball Pool.
/// REGLA ESTRICTA: Cero nombres de personas reales. Únicamente Gamer Tags, Leetspeak,
/// combinaciones de palabras + números y prefijos/sufijos de juego online competitivo.
class BotMatchmakingService {
  static final Random _rng = Random();

  /// 1. Gamer Tags / Leetspeak
  static const List<String> leetGamerTags = [
    'xX_Shadow_Xx',
    'K1ng_Player',
    'x_DarkViper_x',
    'Pro_Gamer99',
    'Sn1p3r_Dice',
    'El_Matad0r_X',
    'Dark_K1ng',
    'Th3_B0ss',
    'V01d_Walk3r',
    'L3g3nd_Dudo',
    'xX_Slayer_Xx',
    'Cr4zy_D1ce',
    'St0rm_R1der',
    'Bl4ck_Lotus',
    'Pwn3r_99',
    'Dud0_M4st3r',
    'Xx_V0rt3x_xX',
    'Gh0st_R1d3r',
  ];

  /// 2. Combinación Palabras + Números
  static const List<String> wordNumberTags = [
    'CyberWolf_77',
    'Lobo_Solitario_21',
    'NeonRider_2026',
    'MasterDice_007',
    'PokerFace_99',
    'TitanDice_404',
    'IronDudo_12',
    'Quantum_42',
    'ShadowFox_09',
    'ApexPredator_01',
    'GoldHunter_777',
    'OmegaDice_88',
    'Falcon_99',
    'Valkyrie_13',
    'DragonFury_07',
    'Vortex_360',
    'ThunderStrike_11',
    'AstroDice_24',
  ];

  /// 3. Sufijos/Prefijos con Guiones u Underscores
  static const List<String> prefixSuffixTags = [
    'Ghost-Player-88',
    'B0tt_Smash3r',
    'Zero_Cool_99',
    'Viper_Pro',
    'Alpha_Striker',
    'Dark-Specter',
    'Neo_Matrix_88',
    'Phantom_Dice',
    'Night-Hawk-07',
    'Steel_Titan',
    'Shadow-Hunter',
    'Ultra_Instinct',
    'Rogue_One_77',
    'Delta_Force_X',
    'Echo-Leader-99',
    'Cyber-Ninja_01',
  ];

  /// Componentes para generación procedural si se agotan o requieren mayor variabilidad
  static const List<String> _prefixes = [
    'xX_', 'Dark_', 'Cyber_', 'Neon_', 'Ghost_', 'Iron_', 'Shadow_', 'Viper_',
    'Apex_', 'Titan_', 'Pro_', 'Mega_', 'Ultra_', 'Hyper_', 'Zero_', 'Fatal_'
  ];

  static const List<String> _roots = [
    'Wolf', 'Hunter', 'Dice', 'Striker', 'Player', 'Slayer', 'Phantom', 'Master',
    'Specter', 'Viper', 'Matrix', 'Hawk', 'Lotus', 'Vortex', 'Predator', 'Titan',
    'Reaper', 'Falcon', 'Rider', 'Samurai', 'Cacho', 'Dudo', 'Ninja', 'Blade'
  ];

  static const List<String> _suffixes = [
    '_Xx', '_77', '_99', '_2026', '_007', '-88', '_404', '_Pro', '-X', '_V2',
    '_777', '_21', '_42', '_01', '-99', '_VIP', '_GG'
  ];

  /// Genera un nombre de bot que cumpla estrictamente con el formato gamertag.
  static String generateGamertag({Set<String>? excluded}) {
    final allPresets = [
      ...leetGamerTags,
      ...wordNumberTags,
      ...prefixSuffixTags,
    ];

    // Intentar primero de la lista curada no usada
    final available = allPresets
        .where((name) => excluded == null || !excluded.contains(name))
        .toList();

    if (available.isNotEmpty) {
      return available[_rng.nextInt(available.length)];
    }

    // Si ya se usaron los presets, generar proceduralmente
    for (int attempts = 0; attempts < 50; attempts++) {
      final pre = _prefixes[_rng.nextInt(_prefixes.length)];
      final root = _roots[_rng.nextInt(_roots.length)];
      final suf = _suffixes[_rng.nextInt(_suffixes.length)];
      final generated = '$pre$root$suf';
      if (excluded == null || !excluded.contains(generated)) {
        return generated;
      }
    }

    // Fallback garantizado
    return 'Player_${1000 + _rng.nextInt(9000)}';
  }

  /// Retorna una lista de contrincantes para la ruleta de matchmaking.
  /// Genera perfiles completos con Gamertag, nivel equilibrado con el buy-in,
  /// marco cosmético y skins equipadas.
  static List<BotProfile> generateOpponents({
    int count = 5,
    int roomStake = 100,
    String? localPlayerName,
  }) {
    final Set<String> usedNames = {};
    if (localPlayerName != null && localPlayerName.isNotEmpty) {
      usedNames.add(localPlayerName.toLowerCase());
    }

    final List<BotProfile> list = [];

    // Rango de nivel acorde al prestigio de la sala
    int minLvl;
    int maxLvl;
    if (roomStake <= 100) {
      minLvl = 2;
      maxLvl = 9;
    } else if (roomStake <= 250) {
      minLvl = 6;
      maxLvl = 16;
    } else if (roomStake <= 500) {
      minLvl = 12;
      maxLvl = 28;
    } else if (roomStake <= 1000) {
      minLvl = 20;
      maxLvl = 40;
    } else {
      minLvl = 30;
      maxLvl = 60;
    }

    final frames = AvatarFrameModel.allFrames;
    final cups = CupSkinModel.allSkins;

    for (int i = 0; i < count; i++) {
      final name = generateGamertag(excluded: usedNames);
      usedNames.add(name);

      final level = minLvl + _rng.nextInt(maxLvl - minLvl + 1);
      final winRate = 48 + _rng.nextInt(32); // 48% a 79%

      // Marcos cosméticos: bots de mayor nivel tienen probabilidad de marco épico
      AvatarFrameModel frame = AvatarFrameModel.none;
      if (level >= 8 && _rng.nextDouble() < 0.65) {
        final availableFrames = frames.where((f) => f.id != 'none').toList();
        if (availableFrames.isNotEmpty) {
          frame = availableFrames[_rng.nextInt(availableFrames.length)];
        }
      }

      // Skins de vaso: probabilidad de vaso personalizado
      CupSkinModel cup = CupSkinModel.standard;
      if (level >= 5 && _rng.nextDouble() < 0.55) {
        final availableCups = cups.where((c) => c.id != 'cup_standard').toList();
        if (availableCups.isNotEmpty) {
          cup = availableCups[_rng.nextInt(availableCups.length)];
        }
      }

      list.add(
        BotProfile(
          id: 'bot${i + 1}',
          username: name,
          level: level,
          frame: frame,
          cupSkin: cup,
          winRatePercent: winRate,
          coins: roomStake * (4 + _rng.nextInt(12)),
        ),
      );
    }

    return list;
  }
}
