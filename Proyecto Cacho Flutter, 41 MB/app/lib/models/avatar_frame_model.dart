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
  final String effectType; // 'none', 'gold', 'neon', 'fire'

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
    name: 'Marco de Oro',
    description: 'Bisel forjado en lingotes de oro con brillo de alta sociedad.',
    priceCash: 120,
    isAnimated: true,
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFD4AF37),
    borderWidth: 2.5,
    effectType: 'gold',
  );

  static const AvatarFrameModel neon = AvatarFrameModel(
    id: 'frame_neon',
    name: 'Neón VIP',
    description: 'Tubos de neón azul cian eléctrico de club nocturno.',
    priceCash: 250,
    isAnimated: true,
    primaryColor: Color(0xFF00F0FF),
    secondaryColor: Color(0xFF7000FF),
    borderWidth: 2.5,
    effectType: 'neon',
  );

  static const AvatarFrameModel fuego = AvatarFrameModel(
    id: 'frame_fuego',
    name: 'Aura de Fuego',
    description: 'Llamas ardientes envolviendo la foto del jugador.',
    priceCash: 400,
    isAnimated: true,
    primaryColor: Color(0xFFFF3300),
    secondaryColor: Color(0xFFFF9900),
    borderWidth: 3.0,
    effectType: 'fire',
  );

  static const List<AvatarFrameModel> allFrames = [
    none,
    oro,
    neon,
    fuego,
  ];

  static AvatarFrameModel getById(String? id) {
    if (id == null) return none;
    return allFrames.firstWhere(
      (f) => f.id == id,
      orElse: () => none,
    );
  }
}

