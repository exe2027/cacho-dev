// Modelo puro + física para el carrusel de salas con fling multi-sala.
//
// El problema anterior: un gesto solo movía 1 sala (umbral de arrastre
// 0.18 de página y velocidad 300 px/s) y la ruleta se cortaba al
// cambiar de selección, así que un barrido rápido no se oía.
// Ahora: umbrales más sensibles, pasos por velocidad y un tack por
// sala que pasa, sin que un toque accidental cambie de sala.
//
// Umbrales (sensibilidad): distancia 0.08 de página (antes 0.18) y
// velocidad 150 px/s (antes 300). Un toque o un arrastre mínimo
// (velocidad < 150 Y distancia < 0.08) devuelve 0 pasos: no cambia
// de sala sin querer. Un movimiento ligero y rápido (velocidad
// >= 150) ya mueve 1 sala, aunque el arrastre sea corto.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Número de salas que avanza un gesto, solo por magnitud.
///
/// [velocity] en px/s (primaryVelocity del arrastre en home, o
/// velocidad de scroll en PageView). [offset] en páginas (fracción
/// de página arrastrada en home, o diferencia de página en PageView).
/// [itemCount], si se pasa, limita los pasos para no dar la vuelta
/// completa: como máximo itemCount - 1.
int carouselFlingSteps({
  required double velocity,
  required double offset,
  int? itemCount,
}) {
  const distanceThreshold = 0.08;
  const velocityThreshold = 150.0;
  final v = velocity.abs();
  final d = offset.abs();
  if (v < velocityThreshold && d < distanceThreshold) return 0;
  final int byVelocity;
  if (v >= 2600) {
    byVelocity = 4;
  } else if (v >= 1400) {
    byVelocity = 3;
  } else if (v >= 600) {
    byVelocity = 2;
  } else {
    byVelocity = 1;
  }
  if (itemCount != null) {
    return byVelocity.clamp(0, math.max(0, itemCount - 1));
  }
  return byVelocity;
}

/// Duración de cada paso del carrusel de home: 120 ms, dentro del
/// rango 100-140 ms pedido, para que un fling de 3 salas tarde
/// ~360 ms y cada tarjeta se vea pasar, no un salto instantáneo.
const int carouselStepDurationMs = 120;

/// Física de PageView que permite un fling multi-página.
///
/// La física nativa de PageView solo va a la página vecina. Esta
/// física calcula el destino con [carouselFlingSteps] a partir de
/// la velocidad y del desplazamiento desde [activePage] (la página
/// en la que empezó el gesto), y anima con un muelle rápido hasta
/// esa página. El listener del PageController suena un tack cada
/// vez que la página redondeada cambia, así que un fling de 3
/// tarjetas se oye tack tack tack al pasar por cada una.
class MultiPageScrollPhysics extends PageScrollPhysics {
  const MultiPageScrollPhysics({
    super.parent,
    required this.itemCount,
    required this.activePage,
  });

  final int itemCount;
  final int activePage;

  @override
  MultiPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MultiPageScrollPhysics(
      parent: buildParent(ancestor),
      itemCount: itemCount,
      activePage: activePage,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    if (position is! PageMetrics) {
      return super.createBallisticSimulation(position, velocity);
    }
    final page = position.page ?? activePage.toDouble();
    final offset = page - activePage;
    final steps = carouselFlingSteps(
      velocity: velocity,
      offset: offset,
      itemCount: itemCount,
    );
    if (steps == 0) {
      // Sin pasos: volver a la página activa (snap back), no a la
      // más cercana, para que un arrastre < 0.08 no cambie de sala.
      final pageExtent = math.max(
        1.0,
        position.viewportDimension * position.viewportFraction,
      );
      final targetPixels = activePage * pageExtent;
      if ((targetPixels - position.pixels).abs() < 1.0) return null;
      return ScrollSpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1.0,
          stiffness: 250.0,
          ratio: 1.0,
        ),
        position.pixels,
        targetPixels,
        velocity,
        tolerance: toleranceFor(position),
      );
    }
    // Dirección: la velocidad manda si supera el umbral; si no, el
    // signo del desplazamiento (en PageView, velocidad y página
    // positivas avanzan a la tarjeta siguiente).
    final dir = velocity.abs() >= 150
        ? (velocity > 0 ? 1 : -1)
        : (offset >= 0 ? 1 : -1);
    final targetPage =
        (activePage + dir * steps).clamp(0, math.max(0, itemCount - 1));
    final pageExtent = math.max(
      1.0,
      position.viewportDimension * position.viewportFraction,
    );
    final targetPixels = targetPage * pageExtent;
    if ((targetPixels - position.pixels).abs() < 1.0) return null;
    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 250.0,
        ratio: 1.0,
      ),
      position.pixels,
      targetPixels,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
