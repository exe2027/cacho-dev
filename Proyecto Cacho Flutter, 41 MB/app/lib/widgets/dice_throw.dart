import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animación de lanzamiento de dados (solo visual, nunca lógica).
///
/// Problema que resuelve: al levantar el vaso con VER, los dados
/// aparecían con un fundido/escalado en su sitio final, "flotando",
/// sin trayectoria desde el cacho. Con este widget cada dado sale
/// agrupado bajo el cacho, vuela con arco hacia su posición final
/// en la banda propia, da dos rebotes pequeños al tocar la mesa y
/// se asienta exactamente en su posición final.
///
/// Garantías duras:
/// - La cara del dado NUNCA cambia durante la animación: el hijo
///   (DiceCube/BlenderDie con el valor ya decidido por el motor)
///   se pinta siempre con ese valor; solo se traslada, gira en el
///   plano y escala. El resultado del juego no se toca.
/// - Al terminar (progreso 1), el desplazamiento es (0, 0), la
///   rotación es 0 y la escala es 1: la posición final es bit a bit
///   la misma que sin animación, así que no se rompen las
///   separaciones sin solape de la corrección 27-oct (banda propia,
///   17 px a mi avatar, lejos del pozo).
/// - Con animaciones apagadas ([enabled] false) el widget pinta
///   el hijo directo, sin controlador ni movimiento.
///
/// Parámetros de tiempo (petición del usuario, sin frenar el turno):
/// el controlador dura 800 ms en total; cada dado arranca
/// escalonado 6% del tiempo por índice y todos terminan juntos al
/// final del controlador, así que el lanzamiento completo dura
/// 800 ms aunque haya 5 dados, no 800 ms por dado.
const Duration diceThrowDuration = Duration(milliseconds: 800);

/// Transformación de un dado en un progreso local 0..1.
class DiceThrowTransform {
  final Offset offset;
  final double rotation;
  final double scale;
  const DiceThrowTransform({
    required this.offset,
    required this.rotation,
    required this.scale,
  });
}

/// Progreso local de un dado dentro del controlador global 0..1:
/// arranca más tarde cuanto mayor es su índice y termina en 1 para
/// todos (escalonado sin alargar el lanzamiento).
double diceThrowLocalProgress(double controllerT, int index, int count) {
  if (count <= 1) return controllerT.clamp(0.0, 1.0);
  const stagger = 0.06;
  final start = index * stagger;
  final span = 1.0 - (count - 1) * stagger;
  return ((controllerT - start) / span).clamp(0.0, 1.0);
}

/// Transformación pura de un dado.
///
/// [index]/[count] sitúan al dado en una fila uniforme de dados de
/// [dieSize] con separación [gap], centrada bajo el cacho: el dado
/// arranca agrupado hacia el centro (bajo el cacho, 44 px más
/// arriba) y vuela hacia su centro final. En la fila bosquejo de
/// la mesa horizontal el gap es 4; la rama vertical (fila partida
/// con hueco de 104) NO usa este widget, porque su geometría no
/// es una fila uniforme.
DiceThrowTransform diceThrowTransform(
  double localT, {
  required int index,
  required int count,
  required double dieSize,
  required double gap,
}) {
  final p = localT.clamp(0.0, 1.0);
  if (p >= 1) {
    return const DiceThrowTransform(
      offset: Offset.zero,
      rotation: 0,
      scale: 1,
    );
  }
  final finalCenterX = (index - (count - 1) / 2) * (dieSize + gap);
  const startDy = -44.0;
  final startDx = -finalCenterX * 0.85;
  if (p < 0.78) {
    // Vuelo: interpolación con ease-out + arco hacia arriba.
    final q = p / 0.78;
    final ease = 1 - math.pow(1 - q, 3).toDouble();
    final dx = startDx * (1 - ease);
    final dy = startDy * (1 - ease) - 24 * math.sin(math.pi * q);
    return DiceThrowTransform(
      offset: Offset(dx, dy),
      rotation: (1 - q) * 0.9 * math.sin(q * math.pi * 3 + index),
      scale: 0.85 + 0.15 * ease,
    );
  }
  // Asentamiento: dos rebotes pequeños y decrecientes sobre la mesa.
  final s = (p - 0.78) / 0.22;
  final dy = -7 * (1 - s) * math.sin(s * 2 * math.pi).abs();
  return DiceThrowTransform(
    offset: Offset(0, dy),
    rotation: 0,
    scale: 1,
  );
}

/// Envuelve un dado y lo lanza desde el cacho a su posición final
/// cuando [active] pasa a true (en la mesa, cuando VER levanta el
/// vaso: lift > 0.5). Cuando [active] vuelve a false el controlador
/// se resetea; el dado queda oculto por la opacidad del propio
/// _cubeDie con lift bajo, así que no se ve ningún salto.
/// Con [enabled] false pinta el hijo directo, sin animar.
class ThrownDie extends StatefulWidget {
  final int index;
  final int count;
  final double dieSize;
  final double gap;
  final bool active;
  final bool enabled;
  final Widget child;
  const ThrownDie({
    super.key,
    required this.index,
    required this.count,
    required this.dieSize,
    this.gap = 4,
    required this.active,
    required this.enabled,
    required this.child,
  });

  @override
  State<ThrownDie> createState() => _ThrownDieState();
}

class _ThrownDieState extends State<ThrownDie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: diceThrowDuration,
  );
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _wasActive = widget.active;
    if (widget.active && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active && widget.enabled) _c.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(ThrownDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && widget.active && !_wasActive) {
      _c.forward(from: 0);
    } else if (!widget.active && _wasActive) {
      _c.value = 0;
    }
    _wasActive = widget.active;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final local = diceThrowLocalProgress(
          _c.value,
          widget.index,
          widget.count,
        );
        final t = diceThrowTransform(
          local,
          index: widget.index,
          count: widget.count,
          dieSize: widget.dieSize,
          gap: widget.gap,
        );
        return Transform.translate(
          offset: t.offset,
          child: Transform.rotate(
            angle: t.rotation,
            child: Transform.scale(
              scale: t.scale,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
