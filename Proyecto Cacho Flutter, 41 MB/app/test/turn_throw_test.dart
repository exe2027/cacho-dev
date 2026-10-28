import 'package:cacho_app/widgets/dice_throw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tirada visible de turno con dados BLANCOS (28-oct, idea del
/// usuario): al cambiar el jugador activo, todos ven salir
/// dados del vaso del jugador en turno, SIN pintas, para saber
/// de quién es el turno.
///
/// Garantías que estos tests fijan:
/// - el disparo es solo al cambiar el actor, en `playing`, sin
///   resolución y con animaciones activadas;
/// - la animación NO recibe caras/valores: su API es solo
///   (origen, aterrizaje, cantidad) y pinta cubos blancos lisos;
/// - el vuelo empieza en el vaso y termina en la fila de
///   aterrizaje, con arco hacia arriba, y se desvanece ahí;
/// - la fila de aterrizaje de 5 dados mide 116 px (5×20 + 4×4),
///   dentro del hueco libre entre pozo y placa superior.
void main() {
  test('disparo: solo al cambiar el actor, en playing, sin resolución',
      () {
    expect(
      shouldStartTurnThrow(
        oldActor: 'a',
        newActor: 'b',
        phase: 'playing',
        hasResolution: false,
        animationsEnabled: true,
      ),
      isTrue,
    );
    // Primer actor de la ronda: también dispara (es su tirada
    // inicial, no una revelación).
    expect(
      shouldStartTurnThrow(
        oldActor: null,
        newActor: 'b',
        phase: 'playing',
        hasResolution: false,
        animationsEnabled: true,
      ),
      isTrue,
    );
    // Sin cambio de actor: nada.
    expect(
      shouldStartTurnThrow(
        oldActor: 'a',
        newActor: 'a',
        phase: 'playing',
        hasResolution: false,
        animationsEnabled: true,
      ),
      isFalse,
    );
    // Sin actor nuevo: nada.
    expect(
      shouldStartTurnThrow(
        oldActor: 'a',
        newActor: null,
        phase: 'playing',
        hasResolution: false,
        animationsEnabled: true,
      ),
      isFalse,
    );
    // Fuera de playing, con resolución o sin animaciones: nada.
    for (final args in [
      ('a', 'b', 'finished', false, true),
      ('a', 'b', 'playing', true, true),
      ('a', 'b', 'playing', false, false),
    ]) {
      expect(
        shouldStartTurnThrow(
          oldActor: args.$1,
          newActor: args.$2,
          phase: args.$3,
          hasResolution: args.$4,
          animationsEnabled: args.$5,
        ),
        isFalse,
        reason: 'no debe disparar con $args',
      );
    }
  });

  test('vuelo: del vaso al aterrizaje, con arco hacia arriba', () {
    const from = Offset(160, 49);
    const to = Offset(422, 66);
    // q=0: exactamente en el vaso.
    final start = turnThrowDieCenter(from, to, 0,
        index: 2, count: 5, dieSize: 20, gap: 4);
    expect(start.dx, closeTo(from.dx, 0.01));
    expect(start.dy, closeTo(from.dy, 0.01));
    // q=1: exactamente en su sitio de la fila (centro, índice 2).
    final end = turnThrowDieCenter(from, to, 1,
        index: 2, count: 5, dieSize: 20, gap: 4);
    expect(end.dx, closeTo(to.dx, 0.01));
    expect(end.dy, closeTo(to.dy, 0.01));
    // q=0.5: por encima de la interpolación lineal (arco).
    final mid = turnThrowDieCenter(from, to, 0.5,
        index: 2, count: 5, dieSize: 20, gap: 4);
    final linearY = (from.dy + to.dy) / 2;
    expect(mid.dy, lessThan(linearY));
    // La fila completa de 5 dados a q=1 mide 116 px.
    final centers = [
      for (var i = 0; i < 5; i++)
        turnThrowDieCenter(from, to, 1,
            index: i, count: 5, dieSize: 20, gap: 4),
    ];
    final span =
        centers.map((c) => c.dx).reduce((a, b) => a > b ? a : b) -
            centers.map((c) => c.dx).reduce((a, b) => a < b ? a : b) +
            20;
    expect(span, closeTo(116, 0.01));
  });

  test('opacidad: 1 durante el vuelo, desvanecimiento al final', () {
    expect(turnThrowOpacity(0), 1);
    expect(turnThrowOpacity(0.79), 1);
    expect(turnThrowOpacity(0.9), closeTo(0.5, 0.01));
    expect(turnThrowOpacity(1), closeTo(0, 0.001));
  });

  testWidgets('overlay: dados blancos sin pintas, y se retira al final',
      (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TurnThrowOverlay(
                from: const Offset(160, 49),
                landCenter: const Offset(422, 66),
                count: 3,
                onDone: () => done = true,
              ),
            ],
          ),
        ),
      ),
    );
    // 3 cubos blancos lisos, sin ningún texto (sin números ni
    // caras): la API no tiene por dónde filtrar una pinta.
    expect(find.byType(BlankDie), findsNWidgets(3));
    expect(find.byType(Text), findsNothing);
    // Tras la duración total (+margen para el tick final del
    // controlador), onDone avisa para retirar el overlay.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('overlay: sin dados no pinta nada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TurnThrowOverlay(
                from: Offset(160, 49),
                landCenter: Offset(422, 66),
                count: 0,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(BlankDie), findsNothing);
  });
}
