import 'package:flutter/material.dart';
import '../models/room_config.dart';

export '../models/room_config.dart';

const RoomConfig roomTutorial = RoomConfig(
  id: 'tutorial',
  name: 'Tutorial Guiado',
  entryFee: 0,
  defaultPot: 0,
  tableAssetPath: 'assets/images/mesa_2d_taberna.png',
  cupAssetPath: 'assets/images/cup_cafe.png',
  primaryColor: Color(0xFF0F6E42),  // Verde póker (igual que Taberna)
  accentColor: Color(0xFFD4A84E),
  roomBackgroundAssetPath: 'assets/images/bg_taberna.jpg',
);

const RoomConfig roomTaberna = RoomConfig(
  id: 'taberna',
  name: 'La Taberna',
  entryFee: 100,
  defaultPot: 600,
  tableAssetPath: 'assets/images/mesa_2d_taberna.png',
  cupAssetPath: 'assets/images/cup_cafe.png',
  primaryColor: Color(0xFF0F6E42),  // Verde póker más rico
  accentColor: Color(0xFFD4A84E),   // Dorado/latón cálido
  roomBackgroundAssetPath: 'assets/images/bg_taberna.jpg',
);

const RoomConfig roomBoliche = RoomConfig(
  id: 'boliche',
  name: 'El Boliche',
  entryFee: 250,
  defaultPot: 1500,
  tableAssetPath: 'assets/images/mesa_2d_boliche.png',
  cupAssetPath: 'assets/images/cup_petroleo.png',
  primaryColor: Color(0xFF183D5A),  // Azul marino real más luminoso
  accentColor: Color(0xFF42E8FF),   // Cyan eléctrico
  roomBackgroundAssetPath: 'assets/images/bg_boliche.jpg',
);

const RoomConfig roomCasino = RoomConfig(
  id: 'casino',
  name: 'El Casino',
  entryFee: 500,
  defaultPot: 3000,
  tableAssetPath: 'assets/images/mesa_2d_casino.png',
  cupAssetPath: 'assets/images/cup_burdeos.png',
  primaryColor: Color(0xFF6A1E28),  // Burdeos/vino profundo más vivo
  accentColor: Color(0xFFF0B818),   // Dorado imperial
  roomBackgroundAssetPath: 'assets/images/bg_casino.jpg',
);

const RoomConfig roomMansion = RoomConfig(
  id: 'mansion',
  name: 'La Mansión',
  entryFee: 1000,
  defaultPot: 6000,
  tableAssetPath: 'assets/images/mesa_2d_mansion.png',
  cupAssetPath: 'assets/images/cup_burdeos.png',
  primaryColor: Color(0xFF3A1B4A),  // Púrpura imperial más saturado
  accentColor: Color(0xFFF5A623),   // Ámbar dorado
  roomBackgroundAssetPath: 'assets/images/bg_mansion.jpg',
);

const RoomConfig roomVip = RoomConfig(
  id: 'vip',
  name: 'El Club VIP',
  entryFee: 2500,
  defaultPot: 15000,
  tableAssetPath: 'assets/images/mesa_2d_vip.png',
  cupAssetPath: 'assets/images/cup_negro.png',
  primaryColor: Color(0xFF0E0E14),  // Negro terciopelo (como la referencia)
  accentColor: Color(0xFFFFD700),   // Oro puro 24K
  roomBackgroundAssetPath: 'assets/images/bg_clubvip.jpg',
);

const List<RoomConfig> kRoomConfigs = [
  roomTutorial,
  roomTaberna,
  roomBoliche,
  roomCasino,
  roomMansion,
  roomVip,
];

RoomConfig get defaultRoomConfig => roomTaberna;

RoomConfig getRoomConfigById(String? id) {
  if (id == null) return defaultRoomConfig;
  return kRoomConfigs.firstWhere(
    (r) => r.id.toLowerCase() == id.toLowerCase(),
    orElse: () => defaultRoomConfig,
  );
}

RoomConfig getRoomConfigByStake(int stake) {
  if (stake <= 0) return roomTutorial;
  if (stake <= 100) return roomTaberna;
  if (stake <= 250) return roomBoliche;
  if (stake <= 500) return roomCasino;
  if (stake <= 1000) return roomMansion;
  return roomVip;
}
