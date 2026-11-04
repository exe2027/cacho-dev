import 'package:flutter/material.dart';

/// Modelo de datos para marcos de avatar (Avatar Frames)
class AvatarFrameModel {
  final String id;
  final String name;
  final String description;
  final int priceCash; // Precio en Cash
  final bool isAnimated;
  final Color primaryColor;
  final Color secondaryColor;
  final double borderWidth;
  final String effectType;

  const AvatarFrameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCash,
    this.isAnimated = false,
    this.primaryColor = Colors.white24,
    this.secondaryColor = Colors.transparent,
    this.borderWidth = 1.5,
    this.effectType = 'none',
  });

  // ── Marcos originales ───────────────────────────────────────────────────

  static const AvatarFrameModel none = AvatarFrameModel(
    id: 'frame_none',
    name: 'Sin Marco',
    description: 'Borde clásico sobrio para novatos.',
    priceCash: 0,
    primaryColor: Colors.white30,
    borderWidth: 1.5,
    effectType: 'none',
  );

  static const AvatarFrameModel oro = AvatarFrameModel(
    id: 'frame_oro',
    name: 'Oro Imperial',
    description: 'Bisel forjado en lingotes de oro con brillo rotativo y diamantes.',
    priceCash: 120,
    isAnimated: true,
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFD4AF37),
    borderWidth: 2.5,
    effectType: 'gold',
  );

  static const AvatarFrameModel neon = AvatarFrameModel(
    id: 'frame_neon',
    name: 'Neón Cyberpunk',
    description: 'Tubos de plasma láser cian y fucsia en rotación 360° con pulso continuo.',
    priceCash: 250,
    isAnimated: true,
    primaryColor: Color(0xFF00F0FF),
    secondaryColor: Color(0xFFFF0077),
    borderWidth: 2.5,
    effectType: 'neon',
  );

  static const AvatarFrameModel fuego = AvatarFrameModel(
    id: 'frame_fuego',
    name: 'Aura de Fuego Infernal',
    description: '14 llamaradas ardientes danzantes y chispas flotantes alrededor del avatar.',
    priceCash: 400,
    isAnimated: true,
    primaryColor: Color(0xFFFF3300),
    secondaryColor: Color(0xFFFF9900),
    borderWidth: 3.0,
    effectType: 'fire',
  );

  static const AvatarFrameModel frost = AvatarFrameModel(
    id: 'frame_frost',
    name: 'Escarcha Glaciar',
    description: 'Anillo de hielo ártico facetado con copos de nieve orbitantes y vapor gélido.',
    priceCash: 300,
    isAnimated: true,
    primaryColor: Color(0xFF80D8FF),
    secondaryColor: Color(0xFF00B0FF),
    borderWidth: 2.5,
    effectType: 'frost',
  );

  static const AvatarFrameModel galaxy = AvatarFrameModel(
    id: 'frame_galaxy',
    name: 'Vacío Cósmico',
    description: 'Vórtice interestelar púrpura profundo con polvo de estrellas y nebulosa.',
    priceCash: 450,
    isAnimated: true,
    primaryColor: Color(0xFF9D4EDD),
    secondaryColor: Color(0xFF5A189A),
    borderWidth: 3.0,
    effectType: 'galaxy',
  );

  static const AvatarFrameModel valhalla = AvatarFrameModel(
    id: 'frame_valhalla',
    name: 'Alas de Gran Maestro',
    description: 'Corona de laureles dorados y alas de campeón que coronan al jugador.',
    priceCash: 600,
    isAnimated: true,
    primaryColor: Color(0xFFFFE082),
    secondaryColor: Color(0xFFFFB300),
    borderWidth: 3.2,
    effectType: 'valhalla',
  );

  // ── Marcos nuevos ───────────────────────────────────────────────────────

  static const AvatarFrameModel sangre = AvatarFrameModel(
    id: 'frame_sangre',
    name: 'Pacto de Sangre',
    description: 'Marco rojo oscuro con gotitas animadas que caen alrededor del avatar.',
    priceCash: 800,
    isAnimated: true,
    primaryColor: Color(0xFFB71C1C),
    secondaryColor: Color(0xFF7F0000),
    borderWidth: 3.0,
    effectType: 'sangre',
  );

  static const AvatarFrameModel arcoiris = AvatarFrameModel(
    id: 'frame_arcoiris',
    name: 'Prisma Festivo',
    description: 'Arcoíris rotativo suave con colores vibrantes que nunca se detienen.',
    priceCash: 600,
    isAnimated: true,
    primaryColor: Color(0xFFFF4081),
    secondaryColor: Color(0xFF7C4DFF),
    borderWidth: 2.8,
    effectType: 'arcoiris',
  );

  static const AvatarFrameModel serpiente = AvatarFrameModel(
    id: 'frame_serpiente',
    name: 'Serpiente Emplumada',
    description: 'Quetzalcóatl dorado y verde esmeralda que serpentea alrededor del avatar.',
    priceCash: 1200,
    isAnimated: true,
    primaryColor: Color(0xFF00C853),
    secondaryColor: Color(0xFFFFD600),
    borderWidth: 3.0,
    effectType: 'serpiente',
  );

  static const AvatarFrameModel tormenta = AvatarFrameModel(
    id: 'frame_tormenta',
    name: 'Ojo de la Tormenta',
    description: 'Espiral de nubes oscuras con relámpagos que cruzan el marco sin parar.',
    priceCash: 1400,
    isAnimated: true,
    primaryColor: Color(0xFF546E7A),
    secondaryColor: Color(0xFFFFFF00),
    borderWidth: 3.2,
    effectType: 'tormenta',
  );

  static const AvatarFrameModel hoja = AvatarFrameModel(
    id: 'frame_hoja',
    name: 'Hoja de Otoño',
    description: 'Hojas de colores cálidos que caen en bucle alrededor del avatar.',
    priceCash: 700,
    isAnimated: true,
    primaryColor: Color(0xFFE65100),
    secondaryColor: Color(0xFFBF360C),
    borderWidth: 2.5,
    effectType: 'hoja',
  );

  static const AvatarFrameModel diamante = AvatarFrameModel(
    id: 'frame_diamante',
    name: 'Diamante Azul',
    description: 'Gemas de zafiro brillando en pulso rítmico con destellos de luz blanca.',
    priceCash: 1600,
    isAnimated: true,
    primaryColor: Color(0xFF1565C0),
    secondaryColor: Color(0xFF82B1FF),
    borderWidth: 3.2,
    effectType: 'diamante',
  );

  static const AvatarFrameModel dudo = AvatarFrameModel(
    id: 'frame_dudo',
    name: 'Corona del Dudo',
    description: 'Corona dorada exclusiva de campeón con partículas reales que flotan arriba.',
    priceCash: 2000,
    isAnimated: true,
    primaryColor: Color(0xFFFFC107),
    secondaryColor: Color(0xFFFF8F00),
    borderWidth: 3.5,
    effectType: 'dudo',
  );

  static const List<AvatarFrameModel> allFrames = [
    none,
    oro,
    neon,
    fuego,
    frost,
    galaxy,
    valhalla,
    sangre,
    arcoiris,
    serpiente,
    tormenta,
    hoja,
    diamante,
    dudo,
  ];

  static AvatarFrameModel getById(String? id) {
    if (id == null) return none;
    return allFrames.firstWhere(
      (f) => f.id == id,
      orElse: () => none,
    );
  }
}
