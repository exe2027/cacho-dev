import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pop breve al aparecer una apuesta (layout-sin-solapes, §3e).
///
/// Cuando cambia la apuesta vigente (nuevo texto: cantidad,
/// pinta o autor), la píldora hace un pop de escala
/// 1 → ~1,18 → 1 en ~300 ms (curva seno) y queda en su tamaño
/// normal. Se clavea por el texto de la apuesta en el padre
/// (`ValueKey`): una apuesta nueva crea una instancia nueva y
/// el pop dispara una sola vez; la misma apuesta no vuelve a
/// saltar en cada rebuild.
///
/// Con [enabled] false (animaciones apagadas o efectos
/// reducidos) pinta el hijo directo, sin controlador. El
/// controlador se libera en [dispose] y el pop nunca bloquea
/// botones ni retrasa el turno: es puramente visual.
class BidPop extends StatefulWidget {
  final Widget child;

  /// Gate de animaciones (padre: `CasinoAnims.enabledIn`).
  final bool enabled;

  const BidPop({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<BidPop> createState() => _BidPopState();
}

class _BidPopState extends State<BidPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
        final scale = 1 + 0.18 * math.sin(math.pi * _ctrl.value);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
