import 'package:flutter/material.dart';

enum ShopItemType { coins, cash, cupSkin, avatarFrame }

/// Modelo para paquetes de la tienda (Monedas, Billetes o Cosméticos)
class ShopItemModel {
  final String id;
  final String title;
  final String subtitle;
  final ShopItemType type;
  final int amount; // Monedas o Billetes otorgados
  final int priceCash; // Costo en Cash si aplica
  final double realPriceUsd; // Precio de referencia simbólico
  final IconData icon;
  final Color accentColor;
  final String? bannerTag;

  const ShopItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.amount = 0,
    this.priceCash = 0,
    this.realPriceUsd = 0.0,
    required this.icon,
    this.accentColor = const Color(0xFFD4AF37),
    this.bannerTag,
  });

  /// Paquetes de Monedas (Coins) comprados con Cash o Ficticios
  static const List<ShopItemModel> coinPackages = [
    ShopItemModel(
      id: 'pack_coins_small',
      title: 'Bolsa de Fichas',
      subtitle: '+2.500 Fichas para mesas',
      type: ShopItemType.coins,
      amount: 2500,
      priceCash: 25,
      realPriceUsd: 0.99,
      icon: Icons.monetization_on,
      accentColor: Color(0xFFD4AF37),
    ),
    ShopItemModel(
      id: 'pack_coins_medium',
      title: 'Montón de Casino',
      subtitle: '+10.000 Fichas para mesas',
      type: ShopItemType.coins,
      amount: 10000,
      priceCash: 80,
      realPriceUsd: 2.99,
      icon: Icons.savings,
      accentColor: Color(0xFFFFD700),
      bannerTag: 'POPULAR',
    ),
    ShopItemModel(
      id: 'pack_coins_large',
      title: 'Bóveda de Oro',
      subtitle: '+50.000 Fichas de High Roller',
      type: ShopItemType.coins,
      amount: 50000,
      priceCash: 300,
      realPriceUsd: 9.99,
      icon: Icons.workspace_premium,
      accentColor: Color(0xFFFF9900),
      bannerTag: 'MEJOR VALOR',
    ),
  ];

  /// Paquetes de Billetes (Cash)
  static const List<ShopItemModel> cashPackages = [
    ShopItemModel(
      id: 'pack_cash_starter',
      title: 'Fajo de Billetes',
      subtitle: '+100 Billetes para Skins',
      type: ShopItemType.cash,
      amount: 100,
      realPriceUsd: 1.99,
      icon: Icons.payments,
      accentColor: Color(0xFF34C759),
    ),
    ShopItemModel(
      id: 'pack_cash_pro',
      title: 'Maletín de Billetes',
      subtitle: '+350 Billetes + Bono VIP',
      type: ShopItemType.cash,
      amount: 350,
      realPriceUsd: 4.99,
      icon: Icons.cases,
      accentColor: Color(0xFF30D158),
      bannerTag: 'RECOMENDADO',
    ),
    ShopItemModel(
      id: 'pack_cash_whale',
      title: 'Caja Fuerte Premium',
      subtitle: '+1.000 Billetes para todo el catálogo',
      type: ShopItemType.cash,
      amount: 1000,
      realPriceUsd: 12.99,
      icon: Icons.diamond,
      accentColor: Color(0xFF00F0FF),
      bannerTag: 'EXCLUSIVO',
    ),
  ];
}

