import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_app/widgets/panels.dart';
import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:cacho_engine/bots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frente MESA del pase de CORRECCIÓN 26-oct (informe en
/// `audit/correccion_6jugadores_mesa.md`). Solo geometría pura,
/// consola y presupuesto de revelación: nada de motor, servidor
/// ni otros frentes.
void main() {
  test('mockup-6: 5 rivales limpios a 390 y a 350 (mesa 230)', () {
    for (final h in [390.0, 350.0]) {
      final consoleH = h >= 390 ? 72.0 : 64.0;
      for (final dice in [5, 3, 1]) {
        final l = sketchLayout(
          screenW: 844,
          screenH: h,
          rivals: 5,
          myDiceCount: dice,
          consoleH: consoleH,
        );
        expect(l.seats.length, 5);
        final ov = l.overlaps();
        expect(ov, isEmpty,
            reason: 'H=$h dados=$dice: '
                '${ov.map((e) => '${e.$1.label}~${e.$2.label}=${e.$3}').join(', ')}');
        // Puestos del mockup: 1 arriba al centro, 2 a la izquierda,
        // 2 a la derecha (orden de ocupación: pares y centro último).
        final byAngle = {for (final s in l.seats) s.angleDeg: s};
        expect(byAngle[270]!.avatar.cx, 422);
        expect(byAngle[225]!.avatar.cx, lessThan(422));
        expect(byAngle[315]!.avatar.cx, greaterThan(422));
        expect(byAngle[135]!.avatar.cx, lessThan(422));
        expect(byAngle[45]!.avatar.cx, greaterThan(422));
        // Placas SIEMPRE debajo del avatar y dentro de la mesa.
        for (final s in l.seats) {
          expect(s.plate.top, greaterThanOrEqualTo(s.avatar.bottom + 1));
          expect(s.plate.left, greaterThanOrEqualTo(l.table.left));
          expect(s.plate.right, lessThanOrEqualTo(l.table.right));
        }
        // El asiento superior no tapa la barra ni el pozo.
        expect(byAngle[270]!.avatar.top, greaterThanOrEqualTo(56));
        expect(l.pot.overlaps(byAngle[270]!.avatar), isFalse);
        expect(l.pot.overlaps(byAngle[270]!.cup), isFalse);
        // Mis dados pasan a ambos lados de la placa superior.
        for (final d in l.myDice) {
          expect(d.overlaps(byAngle[270]!.plate), isFalse);
        }
      }
    }
  });

  test('mockup-6: subconjuntos (2-5 jugadores) también limpios', () {
    for (var rivals = 1; rivals <= 4; rivals++) {
      final l = sketchLayout(
        screenW: 844,
        screenH: 390,
        rivals: rivals,
        myDiceCount: 5,
        consoleH: 72,
      );
      expect(l.seats.length, rivals);
      expect(l.overlaps(), isEmpty);
    }
  });

  test('mockup-6: mesa REAL en Column a total 350 (medición)', () {
    // screenH del layout = 56 + mesa + 72 (la consola real vive en
    // la Column; el rect de consola del layout no se usa).
    // Mesa 250 = turno rival; 206 = mi turno con consola plegada;
    // 178 = mi turno con consola abierta + tira VER.
    for (final mesa in [250.0, 206.0, 178.0]) {
      final l = sketchLayout(
        screenW: 844,
        screenH: 56 + mesa + 72,
        rivals: 5,
        myDiceCount: 5,
        consoleH: 72,
      );
      final ov = l.overlaps();
      // ignore: avoid_print
      print('mesa real $mesa: '
          '${ov.isEmpty ? 'LIMPIO' : ov.map((e) => '${e.$1.label}~${e.$2.label}=${e.$3.toStringAsFixed(0)}px²').join(', ')}');
      final underTable = [
        for (final s in l.seats)
          if (s.plate.bottom > l.tableBottom)
            '${s.plate.label} +${(s.plate.bottom - l.tableBottom).toStringAsFixed(0)}px bajo mesa',
      ];
      if (underTable.isNotEmpty) {
        // ignore: avoid_print
        print('mesa real $mesa: placas bajo mesa: ${underTable.join(', ')}');
      }
      if (mesa >= 206) expect(ov, isEmpty, reason: 'mesa $mesa');
    }
  });

  testWidgets('consola a 844: fila completa visible, Cerrar dentro',
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
    await tester.pump();
    expect(tester.takeException(), isNull);
    // RONDA 2: asentar la animación de 150 ms de las tiles
    // (sin esto la tile mide 49,5 en vez de 50).
    await tester.pumpAndSettle();
    final cerrar = tester.getRect(find.byTooltip('Cerrar'));
    expect(cerrar.right, lessThanOrEqualTo(844),
        reason: 'Cerrar debe quedar dentro del viewport, sin scroll');
    expect(cerrar.left, greaterThanOrEqualTo(0));
    // APOSTAR a 14 px y alto de botón 48 (nunca bajo 44).
    final apostar = tester.widget<Text>(find.text('APOSTAR'));
    expect(apostar.style!.fontSize, 14);
    final bar = tester.getRect(find.byType(BottomBidBar));
    // RONDA 2 (F12): alto 58 en ambos modos (era 72 normal /
    // 64 compacto): padding 4 + contenido 50 = 58 exactos, sin
    // fila cortada; la zona inferior totaliza 102 con la tira
    // VER (44) y la mesa sube a 232.
    expect(bar.height, 58);
    // RONDA 2 (F7/F12): tiles 44 de ancho (eran 40) y 49,5 de
    // alto real (50 nominal menos el filete dorado de 0,5 px
    // que vive dentro del alto 58 de la barra): blanco táctil
    // ≥ 44 en ambos ejes y fila completa dentro de 844. La
    // tile se mide por su AnimatedContainer ancestro del
    // número '1' (el finder semántico no expone el label en
    // este harness).
    final tile = tester.getRect(find.ancestor(
      of: find.text('1'),
      matching: find.byType(AnimatedContainer),
    ));
    expect(tile.width, 44);
    expect(tile.height, 49.5);
  });

  test('presupuesto de revelación: 6 manos caben a 844x390', () {
    // Dados Blender 56 en rejilla 2x3, nombres a 14, banda 30,
    // encabezado 18, fila veredicto 48: ver revealContentHeight.
    expect(revealDieSize, 56);
    expect(revealContentHeight(6, step2: false), lessThanOrEqualTo(378));
    expect(revealContentHeight(6, step2: true), lessThanOrEqualTo(378));
    expect(revealContentHeight(1, step2: true), lessThan(300));
    // Una fila de 5 dados a 56 cabe en la celda de 406 (844).
    expect(5 * revealDieSize + 4 * 4, lessThanOrEqualTo(406 - 16));
    // RONDA 2 corrección 2b (F11): el marco horizontal es 334
    // (390 − 56 de barra), no 390: el modo compacto (dado 44,
    // celda 3+3, gaps 4/6, veredicto 40) debe caber con su
    // padding 6, o la 3ª fila + Seguir quedan cortados como en
    // la captura ronda 2, pasada 3 (rejilla 99..379, sin Seguir;
    // causa: BlenderDie es cuadrado y la fila real es ~87 px).
    expect(revealContentHeight(6, step2: false, compact: true),
        lessThanOrEqualTo(328));
    expect(revealContentHeight(6, step2: true, compact: true),
        lessThanOrEqualTo(328));
    // RONDA 3 (F3a): una fila de 5 dados a 36 + paso 58 cabe en
    // la celda de 406 (era 44 + paso 48).
    expect(5 * 36 + 4 * 22, lessThanOrEqualTo(406 - 16));
  });
}
