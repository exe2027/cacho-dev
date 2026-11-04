import 'package:flutter/material.dart';

/// Formas físicas distintivas de los vasos de Cacho
enum CupShapeType {
  leather,     // Cono tradicional de cuero artesanal
  chifle,      // Cuerno curvado con virola de plata
  barrel,      // Barril abombado de roble con zunchos de hierro
  goblet,      // Cáliz imperial de oro macizo 24K con gemas
  skull,       // Calavera gótica forjada en magma y obsidiana
  cyberPrism,  // Prisma hexagonal futurista con circuitos neón
  crystalFrost,// Glaciar tallado en cristal de hielo
  pirate,      // Calavera pirata con monedas de oro
  wizard,      // Sombrero cónico de mago con estrellas
  samurai,     // Cuenco lacado de samurai con kanji dorado
  wineCup,     // Copa de cristal rojo semitransparente
  tiki,        // Tótem tiki polinesiano con llama tropical
  robot,       // Domo robótico cromado con LEDs
  natura,      // Tronco rústico del bosque con musgo
}

/// Modelo de datos para las skins de vasos (Cachos)
class CupSkinModel {
  final String id;
  final String name;
  final String description;
  final int priceCash; // Precio en Billetes (Cash)
  final String assetPath;
  final CupShapeType shapeType;
  final bool isAnimated;
  final Color glowColor;
  final List<Color> gradientColors;

  const CupSkinModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCash,
    required this.assetPath,
    this.shapeType = CupShapeType.leather,
    this.isAnimated = false,
    this.glowColor = const Color(0xFFD4AF37),
    this.gradientColors = const [Color(0xFF5A3825), Color(0xFF2E190E)],
  });

  // ── Skins originales ────────────────────────────────────────────────────

  static const CupSkinModel standard = CupSkinModel(
    id: 'cup_standard',
    name: 'Cacho de Cuero Clásico',
    description: 'Cuero curtido a mano con remaches de bronce.',
    priceCash: 0,
    shapeType: CupShapeType.leather,
    assetPath: 'assets/images/cup_cafe.png',
    glowColor: Color(0xFF8B5A2B),
    gradientColors: [Color(0xFF7A4B29), Color(0xFF381F0E)],
  );

  static const CupSkinModel chifle = CupSkinModel(
    id: 'cup_chifle',
    name: 'Chifle de Huaso',
    description: 'Cuerno de toro curvado con punta pulida y virola de plata.',
    priceCash: 120,
    shapeType: CupShapeType.chifle,
    isAnimated: true,
    assetPath: 'assets/images/cup_cafe.png',
    glowColor: Color(0xFFE2E8F0),
    gradientColors: [Color(0xFF2D3748), Color(0xFF1A202C)],
  );

  static const CupSkinModel roble = CupSkinModel(
    id: 'cup_roble',
    name: 'Barril de Taberna',
    description: 'Duelas de roble añejado en barrica con zunchos forjados y runas místicas.',
    priceCash: 180,
    shapeType: CupShapeType.barrel,
    isAnimated: true,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFF00E5FF),
    gradientColors: [Color(0xFF1E3A5F), Color(0xFF0F1E2A)],
  );

  static const CupSkinModel dorado = CupSkinModel(
    id: 'cup_dorado',
    name: 'Cáliz Imperial 24K',
    description: 'Cáliz real bañado en oro macizo con gemas de rubí y destellos de diamantes.',
    priceCash: 350,
    shapeType: CupShapeType.goblet,
    isAnimated: true,
    assetPath: 'assets/images/cup_burdeos.png',
    glowColor: Color(0xFFFFD700),
    gradientColors: [Color(0xFF8B2535), Color(0xFF3E0D16)],
  );

  static const CupSkinModel fuego = CupSkinModel(
    id: 'cup_fuego',
    name: 'Calavera del Inframundo',
    description: 'Cráneo gótico forjado en obsidiana con ojos de fuego y llamaradas vivas.',
    priceCash: 500,
    shapeType: CupShapeType.skull,
    isAnimated: true,
    assetPath: 'assets/images/cup_negro.png',
    glowColor: Color(0xFFFF3300),
    gradientColors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  static const CupSkinModel cyber = CupSkinModel(
    id: 'cup_cyber',
    name: 'Hexacacho Cyberpunk',
    description: 'Prisma hexagonal de aleación de titanio con circuitos de neón cian y fucsia.',
    priceCash: 450,
    shapeType: CupShapeType.cyberPrism,
    isAnimated: true,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFF00F0FF),
    gradientColors: [Color(0xFF0A192F), Color(0xFF020C1B)],
  );

  static const CupSkinModel glaciar = CupSkinModel(
    id: 'cup_glaciar',
    name: 'Cacho Glaciar Ártico',
    description: 'Tallado en hielo puro de glaciares milenarios con partículas de escarcha.',
    priceCash: 400,
    shapeType: CupShapeType.crystalFrost,
    isAnimated: true,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFF80D8FF),
    gradientColors: [Color(0xFF0F2B48), Color(0xFF041220)],
  );

  // ── Skins nuevas ────────────────────────────────────────────────────────

  static const CupSkinModel pirata = CupSkinModel(
    id: 'cup_pirata',
    name: 'Calavera Pirata',
    description: 'Cráneo pirata con monedas de oro desbordantes y efecto de coral marino.',
    priceCash: 800,
    shapeType: CupShapeType.pirate,
    isAnimated: true,
    assetPath: 'assets/images/cup_negro.png',
    glowColor: Color(0xFFFFB300),
    gradientColors: [Color(0xFF3E2000), Color(0xFF1A0D00)],
  );

  static const CupSkinModel mago = CupSkinModel(
    id: 'cup_mago',
    name: 'Sombrero del Mago',
    description: 'Copa cónica de terciopelo nocturno con estrellas animadas y chispas mágicas.',
    priceCash: 1200,
    shapeType: CupShapeType.wizard,
    isAnimated: true,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFFBB86FC),
    gradientColors: [Color(0xFF1A0533), Color(0xFF0A0218)],
  );

  static const CupSkinModel samurai = CupSkinModel(
    id: 'cup_samurai',
    name: 'Cuenco Samurai',
    description: 'Laca negra y roja con kanji dorado grabado a fuego y seda carmesí.',
    priceCash: 1400,
    shapeType: CupShapeType.samurai,
    isAnimated: true,
    assetPath: 'assets/images/cup_negro.png',
    glowColor: Color(0xFFFF1744),
    gradientColors: [Color(0xFF1A0000), Color(0xFF0D0000)],
  );

  static const CupSkinModel vino = CupSkinModel(
    id: 'cup_vino',
    name: 'Copa de Vino Tinto',
    description: 'Copa de cristal rubí semitransparente que brilla con la luz del casino.',
    priceCash: 600,
    shapeType: CupShapeType.wineCup,
    isAnimated: true,
    assetPath: 'assets/images/cup_burdeos.png',
    glowColor: Color(0xFFC62828),
    gradientColors: [Color(0xFF4A0010), Color(0xFF1A0007)],
  );

  static const CupSkinModel tiki = CupSkinModel(
    id: 'cup_tiki',
    name: 'Tótem Tiki',
    description: 'Máscara polinesiana de madera tropical con ojos brillantes y llama sagrada.',
    priceCash: 1000,
    shapeType: CupShapeType.tiki,
    isAnimated: true,
    assetPath: 'assets/images/cup_cafe.png',
    glowColor: Color(0xFFFF6D00),
    gradientColors: [Color(0xFF3E1A00), Color(0xFF1A0A00)],
  );

  static const CupSkinModel robot = CupSkinModel(
    id: 'cup_robot',
    name: 'Cúpula Robótica',
    description: 'Domo de aleación cromada con LEDs parpadeantes y visor holográfico.',
    priceCash: 1600,
    shapeType: CupShapeType.robot,
    isAnimated: true,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFF40C4FF),
    gradientColors: [Color(0xFF0D1117), Color(0xFF050709)],
  );

  static const CupSkinModel natura = CupSkinModel(
    id: 'cup_natura',
    name: 'Tronco del Bosque',
    description: 'Madera rústica con musgo vivo, hongos luminiscentes y raíces animadas.',
    priceCash: 900,
    shapeType: CupShapeType.natura,
    isAnimated: true,
    assetPath: 'assets/images/cup_cafe.png',
    glowColor: Color(0xFF69F0AE),
    gradientColors: [Color(0xFF0D2B1A), Color(0xFF05100A)],
  );

  static const List<CupSkinModel> allSkins = [
    standard,
    chifle,
    roble,
    dorado,
    fuego,
    cyber,
    glaciar,
    pirata,
    mago,
    samurai,
    vino,
    tiki,
    robot,
    natura,
  ];

  static CupSkinModel getById(String? id) {
    if (id == null) return standard;
    return allSkins.firstWhere(
      (s) => s.id == id,
      orElse: () => standard,
    );
  }
}
