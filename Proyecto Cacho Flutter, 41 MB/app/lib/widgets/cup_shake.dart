import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Agite de vaso al inicio de ronda (layout-sin-solapes, §3a).
///
/// TODOS los vasos se sacuden al arrancar la ronda: rotación
/// ±8° (0,14 rad) con oscilación amortiguada, leve desplazamiento
/// lateral (±3 px) y 700 ms de duración (dentro del 600–800 ms
/// pedido). El vaso propio ya se agitaba así —y más— por
/// `_playRollClosed` en `game_screen.dart` (700 ms + sonido de
/// dados + golpe de vaso); este widget cubre los vasos RIVALES,
/// que hasta ahora eran estáticos. Se clavea por ronda
/// (`ValueKey` con la ronda en el padre): al cambiar la ronda
/// se crea una instancia nueva y el agite dispara una sola vez;
/// dentro de la misma ronda no se repite en cada rebuild.
///
/// Con [enabled] false (animaciones apagadas o efectos
/// reducidos) pinta el hijo directo, sin controlador ni
/// movimiento. El controlador se libera en [dispose] y la
/// animación nunca bloquea botones ni retrasa el turno: es
/// puramente visual y no toca el motor.
class CupShake extends StatefulWidget {
  final Widget child;

  /// Gate de animaciones (padre: `CasinoAnims.enabledIn` y
  /// `!reducedEffects`).
  final bool enabled;

  const CupShake({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<CupShake> createState() => _CupShakeState();
}

class _CupShakeState extends State<CupShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final env = 1 - t;
        final rot = math.sin(t * math.pi * 4) * env * 0.14;
        final dx = math.sin(t * math.pi * 4) * env * 3;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: rot,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
