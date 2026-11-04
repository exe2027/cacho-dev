import 'package:flutter/material.dart';

class RoomConfig {
  final String id;
  final String name;
  final int entryFee;
  final int defaultPot;
  final String tableAssetPath;
  final String cupAssetPath;
  final Color primaryColor;
  final Color accentColor;
  final String roomBackgroundAssetPath;

  const RoomConfig({
    required this.id,
    required this.name,
    required this.entryFee,
    required this.defaultPot,
    required this.tableAssetPath,
    required this.cupAssetPath,
    required this.primaryColor,
    required this.accentColor,
    this.roomBackgroundAssetPath = 'assets/images/bg_taberna.jpg',
  });
}
