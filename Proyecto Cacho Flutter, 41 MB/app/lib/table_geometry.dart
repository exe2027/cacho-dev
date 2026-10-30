import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dimensiones del óvalo de la mesa en coordenadas de pantalla.
/// La geometría de la mesa se centra aquí y se escala según el viewport.
class TableSize {
  final double centerX;
  final double centerY;
  final double radiusX; // semieje mayor horizontal
  final double radiusY; // semieje menor vertical

  const TableSize({
    required this.centerX,
    required this.centerY,
    required this.radiusX,
    required this.radiusY,
  });

  double get ovalWidth => radiusX * 2;
  double get ovalHeight => radiusY * 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableSize &&
          runtimeType == other.runtimeType &&
          centerX == other.centerX &&
          centerY == other.centerY &&
          radiusX == other.radiusX &&
          radiusY == other.radiusY;

  @override
  int get hashCode => Object.hash(centerX, centerY, radiusX, radiusY);
}

/// Geometría de un asiento: posición, tamaño y rotación.
class SeatGeometry {
  final double angleDeg; // ángulo en grados (0-360)
  final Offset avatarCenter;
  final Size avatarSize;
  final Offset cupCenter;
  final Size cupSize;
  final Offset plateCenter;
  final Size plateSize;
  final bool singleLinePlate;

  const SeatGeometry({
    required this.angleDeg,
    required this.avatarCenter,
    required this.avatarSize,
    required this.cupCenter,
    required this.cupSize,
    required this.plateCenter,
    required this.plateSize,
    this.singleLinePlate = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeatGeometry &&
          runtimeType == other.runtimeType &&
          angleDeg == other.angleDeg &&
          avatarCenter == other.avatarCenter &&
          avatarSize == other.avatarSize &&
          cupCenter == other.cupCenter &&
          cupSize == other.cupSize &&
          plateCenter == other.plateCenter &&
          plateSize == other.plateSize &&
          singleLinePlate == other.singleLinePlate;

  @override
  int get hashCode => Object.hash(
    angleDeg,
    avatarCenter,
    avatarSize,
    cupCenter,
    cupSize,
    plateCenter,
    plateSize,
    singleLinePlate,
  );
}

/// Geometría completa de la mesa: asientos, pozo y metadata.
class TableGeometry {
  final TableSize tableSize;
  final List<SeatGeometry> seats;
  final SeatGeometry mySeat;
  final Rect potRect;
  final Rect consoleRect;

  const TableGeometry({
    required this.tableSize,
    required this.seats,
    required this.mySeat,
    required this.potRect,
    required this.consoleRect,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableGeometry &&
          runtimeType == other.runtimeType &&
          tableSize == other.tableSize &&
          _listEquals(seats, other.seats) &&
          mySeat == other.mySeat &&
          potRect == other.potRect &&
          consoleRect == other.consoleRect;

  @override
  int get hashCode => Object.hash(
    tableSize,
    Object.hashAll(seats),
    mySeat,
    potRect,
    consoleRect,
  );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Generador de geometría de mesa según el viewport y número de jugadores.
/// Esta clase replica la lógica de `sketchLayout` pero usa TableGeometry.
class TableGeometryGenerator {
  /// Genera la geometría completa de la mesa.
  static TableGeometry generate({
    required double screenWidth,
    required double screenHeight,
    required double barTop, // altura de la barra superior (56 px)
    required double consoleHeight, // altura de la consola (72 px)
    required int playerCount, // 1 (yo) + número de rivales
  }) {
    final tableH = screenHeight - barTop - consoleHeight;
    
    // Dimensiones del óvalo
    final tableSize = TableSize(
      centerX: screenWidth / 2,
      centerY: barTop + tableH / 2,
      radiusX: 189, // 378 / 2
      radiusY: 45, // 90 / 2
    );

    // Pozo: centrado arriba
    final potRect = Rect.fromCenter(
      center: Offset(screenWidth / 2, barTop + 36),
      width: 180,
      height: 40,
    );

    // Consola: abajo
    final consoleRect = Rect.fromLTWH(
      0,
      screenHeight - consoleHeight,
      screenWidth,
      consoleHeight,
    );

    // Generar asientos rivales
    final rivalCount = playerCount - 1;
    final seats = <SeatGeometry>[];

    if (rivalCount <= 6) {
      // Referencia: puestos fijos
      seats.addAll(_generateFixedSeats(screenWidth, tableSize, rivalCount));
    } else {
      // Arco igual: distribución sobre la elipse
      seats.addAll(_generateArcSeats(screenWidth, tableSize, rivalCount));
    }

    // Mi asiento (siempre abajo)
    final mySeat = _generateMySeat(screenWidth, tableSize);

    return TableGeometry(
      tableSize: tableSize,
      seats: seats,
      mySeat: mySeat,
      potRect: potRect,
      consoleRect: consoleRect,
    );
  }

  /// Genera asientos en posiciones fijas para ≤6 rivales.
  static List<SeatGeometry> _generateFixedSeats(
    double screenW,
    TableSize tableSize,
    int count,
  ) {
    final seats = <SeatGeometry>[];
    final cx = tableSize.centerX;
    final cy = tableSize.centerY;

    switch (count) {
      case 1:
        // Superior derecha
        seats.add(_createSeat(
          angleDeg: -45,
          avatarCenter: Offset(cx + 140, cy - 110),
          cupCenter: Offset(cx + 180, cy - 70),
        ));
        break;
      case 2:
        // Superior izquierda y derecha
        seats.add(_createSeat(
          angleDeg: -135,
          avatarCenter: Offset(cx - 140, cy - 110),
          cupCenter: Offset(cx - 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: -45,
          avatarCenter: Offset(cx + 140, cy - 110),
          cupCenter: Offset(cx + 180, cy - 70),
        ));
        break;
      case 3:
        // Superior izquierda, derecha y lateral
        seats.add(_createSeat(
          angleDeg: -135,
          avatarCenter: Offset(cx - 140, cy - 110),
          cupCenter: Offset(cx - 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: -45,
          avatarCenter: Offset(cx + 140, cy - 110),
          cupCenter: Offset(cx + 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: 0,
          avatarCenter: Offset(cx + 210, cy),
          cupCenter: Offset(cx + 240, cy),
        ));
        break;
      case 4:
        // Superior y costados
        seats.add(_createSeat(
          angleDeg: -135,
          avatarCenter: Offset(cx - 140, cy - 110),
          cupCenter: Offset(cx - 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: -45,
          avatarCenter: Offset(cx + 140, cy - 110),
          cupCenter: Offset(cx + 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: 0,
          avatarCenter: Offset(cx + 210, cy),
          cupCenter: Offset(cx + 240, cy),
        ));
        seats.add(_createSeat(
          angleDeg: 180,
          avatarCenter: Offset(cx - 210, cy),
          cupCenter: Offset(cx - 240, cy),
        ));
        break;
      case 5:
        // 4 anterior + inferior
        seats.add(_createSeat(
          angleDeg: -135,
          avatarCenter: Offset(cx - 140, cy - 110),
          cupCenter: Offset(cx - 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: -45,
          avatarCenter: Offset(cx + 140, cy - 110),
          cupCenter: Offset(cx + 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: 0,
          avatarCenter: Offset(cx + 210, cy),
          cupCenter: Offset(cx + 240, cy),
        ));
        seats.add(_createSeat(
          angleDeg: 180,
          avatarCenter: Offset(cx - 210, cy),
          cupCenter: Offset(cx - 240, cy),
        ));
        seats.add(_createSeat(
          angleDeg: 45,
          avatarCenter: Offset(cx + 100, cy + 110),
          cupCenter: Offset(cx + 60, cy + 160),
        ));
        break;
      case 6:
        // Referencia completa: 2 superiores, 2 costados, 2 inferiores
        seats.add(_createSeat(
          angleDeg: -135,
          avatarCenter: Offset(cx - 140, cy - 110),
          cupCenter: Offset(cx - 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: -45,
          avatarCenter: Offset(cx + 140, cy - 110),
          cupCenter: Offset(cx + 180, cy - 70),
        ));
        seats.add(_createSeat(
          angleDeg: 0,
          avatarCenter: Offset(cx + 210, cy),
          cupCenter: Offset(cx + 240, cy),
        ));
        seats.add(_createSeat(
          angleDeg: 180,
          avatarCenter: Offset(cx - 210, cy),
          cupCenter: Offset(cx - 240, cy),
        ));
        seats.add(_createSeat(
          angleDeg: 45,
          avatarCenter: Offset(cx + 100, cy + 110),
          cupCenter: Offset(cx + 60, cy + 160),
        ));
        seats.add(_createSeat(
          angleDeg: 135,
          avatarCenter: Offset(cx - 100, cy + 110),
          cupCenter: Offset(cx - 60, cy + 160),
        ));
        break;
    }

    return seats;
  }

  /// Genera asientos distribuidos equidistantemente para >6 rivales.
  static List<SeatGeometry> _generateArcSeats(
    double screenW,
    TableSize tableSize,
    int count,
  ) {
    final seats = <SeatGeometry>[];
    final cx = tableSize.centerX;
    final cy = tableSize.centerY;

    // Ángulos excluyendo zona inferior (donde está mi asiento)
    // Rango: -180 a 0 (arriba y costados)
    final angleStep = 180.0 / (count + 1);

    for (int i = 0; i < count; i++) {
      final angle = -180 + (i + 1) * angleStep;
      final angleRad = angle * math.pi / 180;

      // Posición radial en la elipse
      final avatarX =
          cx + tableSize.radiusX * math.cos(angleRad) * 1.2;
      final avatarY =
          cy + tableSize.radiusY * math.sin(angleRad) * 1.2;

      // Vaso radial hacia afuera
      final cupX =
          cx + tableSize.radiusX * math.cos(angleRad) * 1.5;
      final cupY =
          cy + tableSize.radiusY * math.sin(angleRad) * 1.5;

      seats.add(_createSeat(
        angleDeg: angle,
        avatarCenter: Offset(avatarX, avatarY),
        cupCenter: Offset(cupX, cupY),
      ));
    }

    return seats;
  }

  /// Genera el asiento del jugador (siempre abajo, centrado).
  static SeatGeometry _generateMySeat(double screenW, TableSize tableSize) {
    final cx = screenW / 2;
    return _createSeat(
      angleDeg: 0, // no relevante para el jugador
      avatarCenter: Offset(cx, tableSize.centerY + 120),
      cupCenter: Offset(cx, tableSize.centerY + 160),
    );
  }

  /// Helper para crear un SeatGeometry con dimensiones estándar.
  static SeatGeometry _createSeat({
    required double angleDeg,
    required Offset avatarCenter,
    required Offset cupCenter,
    Size? avatarSize,
    Size? cupSize,
    Offset? plateCenter,
    Size? plateSize,
    bool singleLinePlate = false,
  }) {
    avatarSize ??= const Size(56, 56);
    cupSize ??= const Size(56, 64);
    plateCenter ??= Offset(avatarCenter.dx, avatarCenter.dy + 70);
    plateSize ??= const Size(88, 34);

    return SeatGeometry(
      angleDeg: angleDeg,
      avatarCenter: avatarCenter,
      avatarSize: avatarSize,
      cupCenter: cupCenter,
      cupSize: cupSize,
      plateCenter: plateCenter,
      plateSize: plateSize,
      singleLinePlate: singleLinePlate,
    );
  }
}
