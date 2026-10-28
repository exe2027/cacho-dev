import 'package:flutter/material.dart';

import 'sketch_layout.dart';

/// Un jugador de la mesa como UNIDAD ÚNICA (layout-sin-solapes).
///
/// Compromiso documentado (pedido del usuario, dos reglas en
/// tensión): el usuario pide a la vez (a) cada jugador como un
/// widget único `avatar → nombre → puntos → vaso` con gaps
/// fijos, y (b) en laterales avatar FUERA y vaso DENTRO, más
/// un orden de pintado fijo `mesa < vasos < dados < avatares <
/// UI`. Una `Column` literal no puede cumplir (b): en laterales
/// el vaso quedaría debajo de la placa (fuera de la mesa, no
/// dentro) y el pintado por jugador rompería el orden global
/// (el vaso del jugador 2 pintaría sobre el avatar del 1).
///
/// Solución: [SeatBlock] es la unidad única en código — un solo
/// objeto por jugador, construido desde UN único ancla
/// geométrica ([SketchSeat]) con gaps fijos entre sus tres
/// rectángulos — y expone sus tres capas para que `_sketchTable`
/// las pinte en el orden global fijo: todos los vasos, luego
/// el escenario propio (dados), luego todos los avatares, luego
/// todas las placas (UI). Como la geometría garantiza 0 solapes
/// entre jugadores (ver `seat_layout.dart`), el orden entre
/// capas solo importa dentro de cada jugador, donde es
/// vaso < avatar < placa, igual que antes.
///
/// Los widgets los construye `game_screen.dart` (que conoce al
/// jugador y al controlador); esta clase solo los agrupa y les
/// da el orden de pintado. No pinta nada por sí misma.
class SeatBlock {
  final SketchSeat geom;

  /// Vaso (capa vasos). Pinta primero.
  final Widget cup;

  /// Avatar (capa avatares). Pinta después de los dados.
  final Widget avatar;

  /// Placa nombre + puntos (capa UI). Pinta última.
  final Widget plate;

  /// Burbuja de reacción sobre el avatar, si la hay. Pinta con
  /// la capa de avatares.
  final Widget? emoteBubble;

  const SeatBlock({
    required this.geom,
    required this.cup,
    required this.avatar,
    required this.plate,
    this.emoteBubble,
  });

  /// Las capas en el orden de pintado dentro del jugador.
  List<Widget> get inPaintOrder => [
        cup,
        avatar,
        plate,
        if (emoteBubble != null) emoteBubble!,
      ];
}
