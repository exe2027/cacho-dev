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
/// escalonado 8% del tiempo por índice (64 ms a 800 ms, dentro
/// del 50–100 ms pedido) y todos terminan juntos al final del
/// controlador, así que el lanzamiento completo dura 800 ms
/// aunque haya 5 dados, no 800 ms por dado.
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
  const stagger = 0.08;
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
      // Vuelo con rotación por dado: la fase lleva index * 1.7
      // (pseudo-aleatoria por dado, no uniforme) y VUELVE a 0
      // al asentarse: la "rotación final aleatoria" pedida se
      // realiza como rodaje en vuelo, no como cara inclinada en
      // reposo — una cara inclinada al final sería ilegible y
      // rompería la regla "todo legible". Las caras decididas
      // nunca cambian.
      rotation: (1 - q) * 0.9 * math.sin(q * math.pi * 3 + index * 1.7),
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

/// Tirada visible de turno con dados BLANCOS (28-oct, idea del
/// usuario: "cada vez que le toca a algún jugador, todos vemos
/// como lanza los dados a la mesa, sin ver las pintas").
///
/// Garantía dura anti-filtración: esta animación NUNCA recibe
/// valores, caras ni manos. Su constructor solo toma la
/// cantidad de dados, el origen (centro del vaso del jugador en
/// turno) y la zona de aterrizaje; cada dado es un [BlankDie]
/// (cubo blanco liso, sin puntos ni números). No hay ningún
/// camino por el que una cara real llegue aquí: ni siquiera
/// como parámetro. Al terminar, los dados se desvanecen en la
/// zona de aterrizaje y el overlay se retira (`onDone`); nunca
/// quedan tapando mesa, pozo, avatares ni placas (la zona de
/// aterrizaje se elige en `game_screen.dart` libre de todos
/// ellos). El vuelo en sí cruza el paño con arco y puede pasar
/// brevemente por encima de algún borde (es un lanzamiento, no
/// un reposo); el reposo final es solo la zona libre.
/// Con animaciones apagadas el overlay no se crea (el disparo
/// en `game_screen.dart` lo exige), así que no aparece nada.

/// Duración total de la tirada de turno: 800 ms de vuelo (igual
/// que [diceThrowDuration], misma física de arco) + 200 ms de
/// desvanecimiento en la zona de aterrizaje.
const Duration turnThrowDuration = Duration(milliseconds: 1000);

/// Altura del arco del vuelo de turno (px hacia arriba).
const double turnThrowArcHeight = 28.0;

/// Centro de un dado de la tirada de turno.
///
/// [from] es el centro del vaso del jugador en turno y [to] el
/// centro de la fila de aterrizaje; [index]/[count] sitúan al
/// dado en esa fila ([dieSize] + [gap] por dado, centrada en
/// [to]). [q] es el progreso del VUELO (0..1, no del total con
/// desvanecimiento): 0 = en el vaso, 1 = en su sitio de
/// aterrizaje. La x interpola con ease-out y la y añade el arco
/// (seno, hacia arriba) para que el vuelo pase por encima del
/// paño y no arrastre en línea recta sobre las placas.
Offset turnThrowDieCenter(
  Offset from,
  Offset to,
  double q, {
  required int index,
  required int count,
  required double dieSize,
  required double gap,
}) {
  final p = q.clamp(0.0, 1.0);
  final targetX = to.dx + (index - (count - 1) / 2) * (dieSize + gap);
  final ease = 1 - math.pow(1 - p, 3).toDouble();
  final x = from.dx + (targetX - from.dx) * ease;
  final y = from.dy +
      (to.dy - from.dy) * ease -
      turnThrowArcHeight * math.sin(math.pi * p);
  return Offset(x, y);
}

/// Opacidad de la tirada de turno en el progreso TOTAL [t]
/// (0..1 sobre [turnThrowDuration]): 1 durante el vuelo
/// (t < 0.8) y desvanecimiento lineal en el último 20%.
double turnThrowOpacity(double t) {
  if (t < 0.8) return 1.0;
  return (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
}

/// Rebote final del vaso al terminar de subir con VER (28-oct).
///
/// Pura (testeable): [settleT] es el progreso 0..1 del rebote de
/// 300 ms y [lift] la elevación actual (0..1). Devuelve los px
/// extra que sube el vaso: 0 al inicio y al final, 8 en la mitad
/// con el vaso arriba, y 0 si el vaso está abajo (al cerrar, el
/// rebote se cancela y no hay subida fantasma). No toca caras,
/// turnos ni el estado de abierto: solo desplaza el vaso.
double cupSettleDy(double settleT, double lift) {
  final t = settleT.clamp(0.0, 1.0);
  final l = lift.clamp(0.0, 1.0);
  return 8.0 * math.sin(math.pi * t) * l;
}

/// Zona de aterrizaje de la tirada de turno, en coordenadas
/// relativas a la mesa (las que usa `_sketchTable`).
///
/// Normal (tableH ≥ 262): centro entre el pozo y la placa
/// superior, como antes. Mesa corta (tableH < 262): la columna
/// central está ocupada (pozo, mi vaso, mi avatar) y la placa
/// superior vive en el bolsillo izquierdo, así que el centro
/// caería sobre mi vaso; el aterrizaje se mueve al bolsillo
/// libre de arriba a la derecha (entre el pozo y el vaso
/// lateral superior derecho): centro x = centro + 161, y = 30,
/// con la fila de ≤5 dados (116 px) a ≥11 px del pozo y a ≥3 px
/// del vaso lateral (a 844; más aire a anchos mayores). Sigue
/// sin recibir caras: solo coordenadas.
Offset turnThrowLanding({
  required double tableH,
  required double screenW,
  required double potBottomRel,
  required double topPlateTopRel,
}) {
  if (tableH < 262) return Offset(screenW / 2 + 161, 30);
  return Offset(screenW / 2, (potBottomRel + topPlateTopRel) / 2);
}

/// ¿Debe dispararse la tirada de turno?
///
/// Pura (testeable sin UI): solo al cambiar el jugador activo,
/// en fase `playing`, sin resolución abierta y con animaciones
/// activadas. No toca ningún estado del juego: solo decide si
/// mostrar la animación. El primer actor de la partida también
/// dispara (oldActor null → true si hay nuevo actor): su
/// tirada es la tirada inicial de la ronda, no una revelación.
bool shouldStartTurnThrow({
  required String? oldActor,
  required String? newActor,
  required String phase,
  required bool hasResolution,
  required bool animationsEnabled,
}) {
  if (newActor == null || oldActor == newActor) return false;
  if (phase != 'playing' || hasResolution) return false;
  return animationsEnabled;
}

/// Dado blanco liso de la tirada de turno: SIN pintas, SIN
/// números, SIN valores. Un cubo blanco con borde sutil y
/// sombra, para que se lea como dado sin revelar nada.
class BlankDie extends StatelessWidget {
  final double size;
  const BlankDie({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFF9AA0A6), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

/// Overlay de la tirada de turno: [count] dados blancos que
/// vuelan desde el vaso ([from]) hasta la zona de aterrizaje
/// ([landCenter]) y se desvanecen. Al completar llama a
/// [onDone] para que el llamador retire el overlay. No recibe
/// caras, valores ni manos: es imposible filtrar pintas por
/// aquí (ver cabecera de la sección).
class TurnThrowOverlay extends StatefulWidget {
  final Offset from;
  final Offset landCenter;
  final int count;
  final double dieSize;
  final double gap;
  final VoidCallback? onDone;
  const TurnThrowOverlay({
    super.key,
    required this.from,
    required this.landCenter,
    required this.count,
    this.dieSize = 20,
    this.gap = 4,
    this.onDone,
  });

  @override
  State<TurnThrowOverlay> createState() => _TurnThrowOverlayState();
}

class _TurnThrowOverlayState extends State<TurnThrowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: turnThrowDuration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone?.call();
    });

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final flight = (t / 0.8).clamp(0.0, 1.0);
          final opacity = turnThrowOpacity(t);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < widget.count; i++)
                Builder(builder: (context) {
                  final center = turnThrowDieCenter(
                    widget.from,
                    widget.landCenter,
                    flight,
                    index: i,
                    count: widget.count,
                    dieSize: widget.dieSize,
                    gap: widget.gap,
                  );
                  return Positioned(
                    left: center.dx - widget.dieSize / 2,
                    top: center.dy - widget.dieSize / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: (1 - flight) *
                            1.2 *
                            math.sin(flight * math.pi * 3 + i),
                        child: BlankDie(
                          key: ValueKey('blank-die-$i'),
                          size: widget.dieSize,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
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
