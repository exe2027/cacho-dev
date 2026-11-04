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
  final String effectType; // 'none', 'gold', 'neon', 'fire', 'frost', 'galaxy', 'valhalla'

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

  static const List<AvatarFrameModel> allFrames = [
    none,
    oro,
    neon,
    fuego,
    frost,
    galaxy,
    valhalla,
  ];

  static AvatarFrameModel getById(String? id) {
    if (id == null) return none;
    return allFrames.firstWhere(
      (f) => f.id == id,
      orElse: () => none,
    );
  }
}
