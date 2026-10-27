import 'package:flutter/material.dart';

import 'casino_anims.dart';

/// Transiciones animadas entre pantallas del menú (fase 2, frente C).
///
/// La app NO usa rutas nombradas ni `onGenerateRoute` (ver
/// `main.dart`): cada pantalla navega con rutas directas. Por eso no
/// hay nada que cablear en `MaterialApp`: el punto compartido es
/// este helper, y la integración consiste en sustituir
/// mecánicamente cada `CachoPageRoute` de menú por [pushMenuPage] /
/// [pushReplacementMenuPage] (lista exacta de parches en el informe
/// del frente C; las pantallas NO se tocan en este frente).
///
/// Efecto: fundido + deslizamiento leve hacia arriba (el mismo gesto
/// que el `CachoPageRoute` existente: 250 ms, fundido + 0,02 de alto),
/// aquí con duración configurable dentro de 150–600 ms y 300 ms por
/// defecto. Solo `Opacity`/`Transform` por dentro (`FadeTransition` +
/// `SlideTransition`): nunca escala, nunca mueve el layout, nunca
/// tapa botones ni textos.
///
/// Apagado honesto: con el interruptor de animaciones apagado o con
/// "reducir movimiento" del sistema ([CasinoAnims.enabledIn]), la
/// navegación es instantánea y sin animación, exactamente como antes
/// (el helper pasa duración cero y el `transitionsBuilder` devuelve
/// el hijo tal cual). Sin AN15 (barrido de turno, RECHAZADA) ni
/// efectos nuevos sobre la mesa en partida: esto es solo menú.

/// Duración por defecto de una transición de menú.
const Duration kMenuTransitionDuration = Duration(milliseconds: 300);

/// Rango permitido para [MenuPageRoute.duration]: 150–600 ms.
const Duration kMenuTransitionMin = Duration(milliseconds: 150);
const Duration kMenuTransitionMax = Duration(milliseconds: 600);

/// Ruta de menú: fundido + deslizamiento leve.
///
/// `duration` se limita a 150–600 ms, salvo [Duration.zero], que es
/// el centinela que usan [pushMenuPage] y [pushReplacementMenuPage]
/// cuando las animaciones están apagadas (navegación instantánea).
/// Un llamador directo que pase menos de 150 ms obtiene 150 ms, y
/// uno que pase más de 600 ms obtiene 600 ms; nunca fuera de rango.
class MenuPageRoute<T> extends PageRouteBuilder<T> {
  MenuPageRoute({
    required WidgetBuilder builder,
    Duration duration = kMenuTransitionDuration,
    Offset begin = const Offset(0, 0.02),
  }) : super(
          transitionDuration: _clamped(duration),
          reverseTransitionDuration: _clamped(duration),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            if (!CasinoAnims.enabledIn(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: begin,
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );

  static Duration _clamped(Duration d) {
    if (d <= Duration.zero) return Duration.zero;
    if (d < kMenuTransitionMin) return kMenuTransitionMin;
    if (d > kMenuTransitionMax) return kMenuTransitionMax;
    return d;
  }
}

/// Empuja una pantalla de menú con transición animada.
///
/// Uso (sustitución mecánica del `CachoPageRoute` actual):
/// ```dart
/// // Antes:
/// Navigator.of(context).push(CachoPageRoute(
///   builder: (_) => BuscarSalasScreen(...),
/// ));
/// // Después:
/// pushMenuPage(context, builder: (_) => BuscarSalasScreen(...));
/// ```
/// Con animaciones apagadas o reduce-motion, empuja con duración
/// cero: navegación instantánea, exactamente como antes.
Future<T?> pushMenuPage<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Duration duration = kMenuTransitionDuration,
}) {
  final animated = CasinoAnims.enabledIn(context);
  return Navigator.of(context).push<T>(
    MenuPageRoute<T>(
      builder: builder,
      duration: animated ? duration : Duration.zero,
    ),
  );
}

/// Como [pushMenuPage], pero sustituye la ruta actual (el caso del
/// lobby que, al partir, reemplaza la sala por la mesa).
Future<T?> pushReplacementMenuPage<T, TO>(
  BuildContext context, {
  required WidgetBuilder builder,
  Duration duration = kMenuTransitionDuration,
}) {
  final animated = CasinoAnims.enabledIn(context);
  return Navigator.of(context).pushReplacement<T, TO>(
    MenuPageRoute<T>(
      builder: builder,
      duration: animated ? duration : Duration.zero,
    ),
  );
}
