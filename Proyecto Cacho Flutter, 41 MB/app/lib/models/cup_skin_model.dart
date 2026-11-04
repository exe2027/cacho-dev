import 'package:flutter/material.dart';

/// Modelo de datos para las skins de vasos (Cachos)
class CupSkinModel {
  final String id;
  final String name;
  final String description;
  final int priceCash; // Precio en Billetes (Cash)
  final String assetPath;
  final bool isAnimated;
  final Color glowColor;
  final List<Color> gradientColors;

  const CupSkinModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCash,
    required this.assetPath,
    this.isAnimated = false,
    this.glowColor = const Color(0xFFD4AF37),
    this.gradientColors = const [Color(0xFF5A3825), Color(0xFF2E190E)],
  });

  static const CupSkinModel standard = CupSkinModel(
    id: 'cup_standard',
    name: 'Vaso Estándar',
    description: 'Cuero tradicional artesanal cosido a mano.',
    priceCash: 0,
    assetPath: 'assets/images/cup_cafe.png',
    glowColor: Color(0xFF8B5A2B),
    gradientColors: [Color(0xFF7A4B29), Color(0xFF381F0E)],
  );

  static const CupSkinModel roble = CupSkinModel(
    id: 'cup_roble',
    name: 'Vaso de Roble',
    description: 'Madera de roble añejado en barrica de licor.',
    priceCash: 150,
    assetPath: 'assets/images/cup_petroleo.png',
    glowColor: Color(0xFF42E8FF),
    gradientColors: [Color(0xFF1E425E), Color(0xFF0F1E2A)],
  );

  static const CupSkinModel dorado = CupSkinModel(
    id: 'cup_dorado',
    name: 'Vaso Dorado VIP',
    description: 'Bañado en oro puro de 24K con grabados imperiales.',
    priceCash: 350,
    assetPath: 'assets/images/cup_burdeos.png',
    isAnimated: true,
    glowColor: Color(0xFFFFD700),
    gradientColors: [Color(0xFF8B2535), Color(0xFF3E0D16)],
  );

  static const CupSkinModel fuego = CupSkinModel(
    id: 'cup_fuego',
    name: 'Vaso en Llamas',
    description: 'Forjado en el inframundo con aura de fuego ardiente.',
    priceCash: 500,
    assetPath: 'assets/images/cup_negro.png',
    isAnimated: true,
    glowColor: Color(0xFFFF4500),
    gradientColors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  static const List<CupSkinModel> allSkins = [
    standard,
    roble,
    dorado,
    fuego,
  ];

  static CupSkinModel getById(String? id) {
    if (id == null) return standard;
    return allSkins.firstWhere(
      (s) => s.id == id,
      orElse: () => standard,
    );
  }
}

