import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_app/widgets/dice_and_cup.dart';
import 'package:cacho_app/widgets/panels.dart';
import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frente MESA de la CORRECCIÓN FLUTTER ronda 3 (26-oct,
/// informe en `audit/comparacion_ejemplo/ronda3_flutter.md`).
/// Solo geometría pura, consola y presupuesto de revelación.
void main() {
  test('ronda3 F3e SUPERADO 27-oct: vaso superior-central sin tapar la placa',
      () {
    final l = sketchLayout(
      screenW: 844,
      screenH: 390,
      rivals: 5,
      myDiceCount: 5,
      consoleH: 72,
    );
    final byAngle = {for (final s in l.seats) s.angleDeg: s};
    final top = byAngle[270]!;
    // La RONDA 3 ponía el vaso a centro 57 (hueco 5 px) y con
    // eso la placa widget de 132 px quedaba bajo el vaso y el
    // vaso superior-derecho tapaba al central en widget. La
    // corrección 27-oct lo corre a centro 76 (geom left cx+48,
    // hueco 24 geom al avatar): el vaso widget empieza 12 px
    // a la derecha de la placa widget y del avatar widget.
    // CORRECCIÓN 28-oct (placa superior truncada): la placa
    // de una línea pasa a 180 px, así que el vaso se corre
    // otros 20 px (geom left cx+68, centro 96, hueco 44 geom
    // al avatar): el vaso widget sigue empezando 12 px a la
    // derecha de la placa widget (478..490 a 844×390).
    expect(top.cup.left - top.avatar.right, 44);
    expect(top.cup.cx - top.avatar.cx, 96);
    expect(top.cup.cx, 518);
    // La placa geométrica corrida a la izquierda no toca el
    // vaso ni el avatar en rect.
    expect(top.plate.right, lessThanOrEqualTo(top.cup.left));
    expect(l.overlaps(), isEmpty);
  });

  test('ronda3 F3e: vasos inferiores dentro del óvalo visual', () {
    // Óvalo visual de _sketchTable: ancho = alto × 3,08 (con
    // inset si sobra), centrado en la pantalla. Se comprueba
    // que las CUATRO esquinas del vaso inferior queden dentro
    // de la elipse, a mesa 232 (consola abierta) y a mesa 290
    // (sin consola), antes y después del cambio de sideX.
    for (final tableH in [232.0, 290.0]) {
      final l = sketchLayout(
        screenW: 844,
        screenH: 56 + tableH + 72,
        rivals: 5,
        myDiceCount: 5,
        consoleH: 72,
      );
      final targetW = tableH * 3.08;
      final inset = l.tableW > targetW ? (l.tableW - targetW) / 2 : 0.0;
      final vw = l.tableW - inset * 2;
      final cx = 422.0;
      final cy = 56 + tableH / 2;
      final rx = vw / 2;
      final ry = tableH / 2;
      bool inside(double x, double y) {
        final dx = (x - cx) / rx;
        final dy = (y - cy) / ry;
        return dx * dx + dy * dy <= 1.001;
      }

      final byAngle = {for (final s in l.seats) s.angleDeg: s};
      for (final angle in [135.0, 45.0]) {
        final cup = byAngle[angle]!.cup;
        for (final x in [cup.left, cup.right]) {
          for (final y in [cup.top, cup.bottom]) {
            expect(inside(x, y), isTrue,
                reason: 'mesa $tableH asiento $angle esquina ($x,$y) '
                    'fuera del óvalo (cx $cx cy $cy rx $rx ry $ry)');
          }
        }
      }
      expect(l.overlaps(), isEmpty);
    }
  });

  test('ronda3 F3a: revelación compacta con aire en el peor caso', () {
    // Caso típico (veredicto 1 línea, sin eliminado).
    expect(revealContentHeight(6, step2: true, compact: true),
        lessThanOrEqualTo(290));
    // Peor caso (veredicto a 2 líneas + eliminado): contenido +
    // padding 4 debe dejar aire en el marco de 334 (nunca a 3 px
    // ni cortado: 334 − 321 = 13 px totales, ~6 abajo).
    final worst = revealContentHeight(6,
        step2: true, compact: true, verdictLines: 2, eliminated: true);
    expect(worst, lessThanOrEqualTo(322));
    expect(worst + 4, lessThanOrEqualTo(326));
    // Conteo (paso 1) también cabe con aire.
    expect(revealContentHeight(6, step2: false, compact: true),
        lessThanOrEqualTo(290));
    // Una fila de 5 dados a 36 + paso 58 cabe en la celda de 406.
    expect(5 * 36 + 4 * 22, lessThanOrEqualTo(406 - 16));
  });

  testWidgets('ronda3 F3b: consola centrada, APOSTAR sin moverse',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final c = MatchController.local(
      nickname: 'Ana',
      botCount: 1,
      difficulty: BotDifficulty.media,
      config: GameConfig.clasico(),
      useTurnTimer: false,
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBidBar(
          controller: c,
          armed: null,
          onArmedChanged: (_) {},
          onFold: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byType(BottomBidBar));
    expect(bar.height, 58);
    // Padding izquierdo 10 (era 8): la primera tile empieza en 10.
    final tile = tester.getRect(find.ancestor(
      of: find.text('1'),
      matching: find.byType(AnimatedContainer),
    ));
    expect(tile.left, 10);
    expect(tile.width, 44);
    // APOSTAR sigue a la derecha (botón 636..786 en captura; el
    // texto centrado queda dentro de ese rango).
    final apostar = tester.getRect(find.text('APOSTAR'));
    expect(apostar.left, greaterThanOrEqualTo(636));
    expect(apostar.right, lessThanOrEqualTo(786));
    final cerrar = tester.getRect(find.byTooltip('Cerrar'));
    expect(cerrar.right, lessThanOrEqualTo(844));
  });

  testWidgets('ronda3 F3d SUPERADO 27-oct: mi placa ya no solapa el avatar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PlayerSeat(
            nickname: 'Jugador',
            seed: 'yo',
            diceCount: 5,
            landscape: true,
            sketchPlate: true,
            plateSide: SketchPlateSide.below,
            plateWidth: 120,
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    // La RONDA 3 subía la placa −18 px sobre el avatar (solape
    // ~4,5 px). La corrección 27-oct la baja +2: queda 2 px por
    // debajo del avatar, sin taparlo, y sigue 8 px antes de la
    // consola (cuelga sobre la tira VER, zona central vacía).
    final transforms = tester.widgetList<Transform>(find.byType(Transform));
    expect(
        transforms.any((t) => t.transform.getTranslation().y == 2), isTrue,
        reason: 'ningún Transform con offset +2 en mi asiento');
    expect(
        transforms.any((t) => t.transform.getTranslation().y == -18),
        isFalse,
        reason: 'la placa ya no debe solapar el avatar con offset -18');
    // El avatar (64) y la placa (120 de ancho) siguen centrados.
    final plate = tester.getRect(find.text('Jugador'));
    expect(plate.width, lessThanOrEqualTo(120));
  });
}
