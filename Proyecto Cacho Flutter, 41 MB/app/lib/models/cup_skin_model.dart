import 'package:flutter/material.dart';

/// Formas físicas distintivas de los vasos de Cacho
enum CupShapeType {
  leather,     // Cono tradicional de cuero artesanal chileno
  chifle,      // Cuerno curvado de huaso con virola de plata
  barrel,      // Barril abombado de roble con zunchos de hierro
  goblet,      // Cáliz imperial de oro macizo 24K con gemas
  skull,       // Calavera gótica forjada en magma y obsidiana
  cyberPrism,  // Prisma hexagonal futurista con circuitos neón
  crystalFrost // Glaciar tallado en cristal de hielo de la Patagonia
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

  static const CupSkinModel standard = CupSkinModel(
    id: 'cup_standard',
    name: 'Cacho de Cuero Clásico',
    description: 'Cuero curtido chileno cosido a mano con remaches de bronce.',
    priceCash: 0,
    shapeType: CupShapeType.leather,
    assetPath: 'assets/images/cup_cafe.png',
    glowColor: Color(0xFF8B5A2B),
    gradientColors: [Color(0xFF7A4B29), Color(0xFF381F0E)],
  );

  static const CupSkinModel chifle = CupSkinModel(
    id: 'cup_chifle',
    name: 'Chifle de Huaso',
    description: 'Cuerno de toro curvado tradicional con punta pulida y virola de plata.',
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
    description: 'Tallado en hielo puro de los glaciares patagónicos con partículas de escarcha.',
    priceCash: 400,
    shapeType: CupShapeType.crystalFrost,
    isAnimated: true,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFF80D8FF),
    gradientColors: [Color(0xFF0F2B48), Color(0xFF041220)],
  );

  static const List<CupSkinModel> allSkins = [
    standard,
    chifle,
    roble,
    dorado,
    fuego,
    cyber,
    glaciar,
  ];

  static CupSkinModel getById(String? id) {
    if (id == null) return standard;
    return allSkins.firstWhere(
      (s) => s.id == id,
      orElse: () => standard,
    );
  }
}
