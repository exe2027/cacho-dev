import 'package:cacho_app/widgets/seat_layout.dart';
import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Corrección 27-oct del solapamiento en la mesa de 6 jugadores
/// (foto del usuario: el rival de arriba al centro quedaba tapado
/// por su propio cacho y por los de sus vecinos, su nameplate
/// solo se leía "H"; los cachos de los lados invadían el centro;
/// mis dados quedaban pegados al avatar "Jugador" y al pozo).
///
/// Causa medida: `sketch_layout.dart` medía rectángulos
/// geométricos (avatar 58, placa 88, vaso 56×64) y salía limpio,
/// pero los widgets reales son placa 132, vaso 73×72 y avatar
/// 64/56, con la placa pintada con offset −8 bajo el avatar y
/// bajo el vaso. Este test comprueba las HUELLAS WIDGET reales
/// (ver `seat_layout.dart`), no la geometría.
///
/// Viewports pedidos: 360×800, 390×844, 412×915 y 844×390. La
/// mesa de Cacho es horizontal: un viewport vertical se juega
/// girado, así que el tamaño efectivo es (máx, mín) de cada par.
/// El alto de mesa estándar es alto efectivo − barra 56 − tira
/// VER 44 − consola 72 (los parámetros con los que se llama a
/// `sketchLayout` en los tests viejos: screenH = alto efectivo,
/// consoleH = 72).
void main() {
  const viewports = <(double, double)>[
    (360, 800),
    (390, 844),
    (412, 915),
    (844, 390),
  ];

  test('huellas widget sin solapes en los 4 viewports (6 jugadores)',
      () {
    for (final vp in viewports) {
      final effW = vp.$1 > vp.$2 ? vp.$1 : vp.$2;
      final effH = vp.$1 > vp.$2 ? vp.$2 : vp.$1;
      for (final dice in [5, 3, 1]) {
        final layout = sketchLayout(
          screenW: effW,
          screenH: effH,
          rivals: 5,
          myDiceCount: dice,
          consoleH: 72,
        );
        final w = widgetLayoutFor(layout);
        final violations = debugCheckWidgetLayout(layout);
        // ignore: avoid_print
        print('viewport ${vp.$1.toInt()}×${vp.$2.toInt()} '
            'efectivo ${effW.toInt()}×${effH.toInt()} '
            'mesa ${w.tableW.toStringAsFixed(0)}×'
            '${w.tableH.toStringAsFixed(0)} unit '
            '${w.unit.toStringAsFixed(3)} fuente '
            '${w.nameFont.toStringAsFixed(1)} px dados=$dice: '
            '${violations.isEmpty ? 'LIMPIO' : violations.join(' | ')}');
        for (final s in w.seats) {
          // ignore: avoid_print
          print('  asiento ${s.angleDeg.round()}° avatar '
              '${s.avatar.left.toStringAsFixed(0)}..'
              '${s.avatar.right.toStringAsFixed(0)},'
              '${s.avatar.top.toStringAsFixed(0)}..'
              '${s.avatar.bottom.toStringAsFixed(0)} placa '
              '${s.plate.left.toStringAsFixed(0)}..'
              '${s.plate.right.toStringAsFixed(0)},'
              '${s.plate.top.toStringAsFixed(0)}..'
              '${s.plate.bottom.toStringAsFixed(0)} vaso '
              '${s.cup.left.toStringAsFixed(0)}..'
              '${s.cup.right.toStringAsFixed(0)},'
              '${s.cup.top.toStringAsFixed(0)}..'
              '${s.cup.bottom.toStringAsFixed(0)}');
        }
        // ignore: avoid_print
        print('  pozo ${w.pot.left.toStringAsFixed(0)}..'
            '${w.pot.right.toStringAsFixed(0)},'
            '${w.pot.top.toStringAsFixed(0)}..'
            '${w.pot.bottom.toStringAsFixed(0)} dados '
            '${w.myDice.map((d) => '${d.left.toStringAsFixed(0)}..'
                '${d.right.toStringAsFixed(0)},'
                '${d.top.toStringAsFixed(0)}..'
                '${d.bottom.toStringAsFixed(0)}').join(' ')} '
            'mi-vaso ${w.myCup.left.toStringAsFixed(0)}..'
            '${w.myCup.right.toStringAsFixed(0)},'
            '${w.myCup.top.toStringAsFixed(0)}..'
            '${w.myCup.bottom.toStringAsFixed(0)} mi-avatar '
            '${w.myAvatar.left.toStringAsFixed(0)}..'
            '${w.myAvatar.right.toStringAsFixed(0)},'
            '${w.myAvatar.top.toStringAsFixed(0)}..'
            '${w.myAvatar.bottom.toStringAsFixed(0)} mi-placa '
            '${w.myPlate.left.toStringAsFixed(0)}..'
            '${w.myPlate.right.toStringAsFixed(0)},'
            '${w.myPlate.top.toStringAsFixed(0)}..'
            '${w.myPlate.bottom.toStringAsFixed(0)} consola '
            '${w.consoleTop.toStringAsFixed(0)}');
        expect(violations, isEmpty,
            reason: 'viewport ${vp.$1}×${vp.$2} dados=$dice');
        // Dentro de la pantalla en horizontal.
        for (final s in w.seats) {
          expect(s.slot.right, lessThanOrEqualTo(effW),
              reason: 'slot ${s.angleDeg} fuera a derecha');
        }
        expect(w.pot.right, lessThanOrEqualTo(effW));
        expect(w.myPlate.right, lessThanOrEqualTo(effW));
      }
    }
  });

  test('reglas pedidas, una por una (844×390, 6 jugadores)', () {
    final layout = sketchLayout(
      screenW: 844,
      screenH: 390,
      rivals: 5,
      myDiceCount: 5,
      consoleH: 72,
    );
    final w = widgetLayoutFor(layout);
    final byAngle = {for (final s in w.seats) s.angleDeg: s};
    final top = byAngle[270.0]!;
    // 1. Rival de arriba al centro: cacho a un costado del
    // avatar, no sobre su nameplate: 12 px libres a la placa
    // widget y al avatar widget (antes: vaso a 5 px geométricos
    // y placa tapada en widget, solo se leía "H").
    expect(top.cup.left - top.plate.right, greaterThanOrEqualTo(8));
    expect(top.cup.left - top.avatar.right, greaterThanOrEqualTo(8));
    expect(top.plate.top, greaterThanOrEqualTo(top.avatar.bottom));
    // 2. Cachos laterales hacia el EXTERIOR (nunca al centro).
    expect(byAngle[225.0]!.cup.cx, lessThan(byAngle[225.0]!.avatar.cx));
    expect(byAngle[315.0]!.cup.cx, greaterThan(byAngle[315.0]!.avatar.cx));
    expect(byAngle[135.0]!.cup.cx, lessThan(byAngle[135.0]!.avatar.cx));
    expect(byAngle[45.0]!.cup.cx, greaterThan(byAngle[45.0]!.avatar.cx));
    // 3. Mis dados ~30% más chicos: 32 (antes 46 en el escenario,
    // 48 en geometría) y 22 en compacto; banda propia entre
    // pozo y mi avatar, con ≥12 px a pozo, avatar y nameplate.
    expect(w.myDice.first.width, 32);
    for (final d in w.myDice) {
      expect(d.top - w.pot.bottom, greaterThanOrEqualTo(12));
      expect(w.myAvatar.top - d.bottom, greaterThanOrEqualTo(12));
      expect(w.myPlate.top - d.bottom, greaterThanOrEqualTo(12));
      expect(d.top - top.plate.bottom, greaterThanOrEqualTo(12));
    }
    // 4. Pozo fijo arriba al centro, sin tapar a nadie.
    expect(w.pot.cx, 422);
    expect(w.pot.top, lessThan(top.avatar.top));
    // 5. Orden de capas (pintado en game_screen: mesa < cachos
    // < dados < avatares < nameplates < pozo < UI): aquí se
    // comprueba la parte geométrica, que ningún rectángulo de
    // capa superior quede tapado por uno inferior en los pares
    // que el chequeo ya declara limpios; el orden de pintado
    // en sí vive en _sketchTable (avatar, placa, vaso en ese
    // orden de lista, con el pozo primero y la consola después
    // de la mesa).
    expect(debugCheckWidgetLayout(layout), isEmpty);
  });

  test('placa superior: "El Huaso" completo sin recorte (844×390 y 360×800)',
      () {
    // Causa raíz medida (28-oct): la placa superior es de UNA
    // línea y en 132 px solo quedaban 53 px para el nombre
    // (pipas 61 + gap 6 + padding 12), mientras "El Huaso" mide
    // 112 px a 14 px. Por eso en vivo se leía "El H…", sin que
    // ningún vaso tapara el texto. Tras la corrección, la placa
    // superior mide 180, su nombre va a 12 px y sus pipas son
    // compactas de 7 px: el contenido completo debe caber.
    final nameTp = TextPainter(
      text: const TextSpan(
          text: 'El Huaso',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    const compactPipsW = 5 * (7.0 + 2 * 1.2); // 47 px
    final contentW = nameTp.width + compactPipsW + 6 + 12;
    expect(contentW, lessThanOrEqualTo(180),
        reason: 'contenido placa superior ${contentW.toStringAsFixed(1)} '
            'px debe caber en 180 px');
    for (final vp in [(844.0, 390.0), (360.0, 800.0)]) {
      final effW = vp.$1 > vp.$2 ? vp.$1 : vp.$2;
      final effH = vp.$1 > vp.$2 ? vp.$2 : vp.$1;
      final layout = sketchLayout(
        screenW: effW,
        screenH: effH,
        rivals: 5,
        myDiceCount: 5,
        consoleH: 72,
      );
      final w = widgetLayoutFor(layout);
      final top =
          w.seats.firstWhere((s) => s.angleDeg == 270.0);
      expect(top.plate.width, 180);
      expect(top.cup.left - top.plate.right, greaterThanOrEqualTo(8),
          reason: 'vaso superior debe quedar ≥8 px a la derecha '
              'de la placa ensanchada en ${vp.$1}×${vp.$2}');
      expect(top.plate.left, greaterThanOrEqualTo(0));
      expect(top.slot.right, lessThanOrEqualTo(effW));
      expect(debugCheckWidgetLayout(layout), isEmpty,
          reason: 'viewport ${vp.$1}×${vp.$2}');
    }
  });

  test('mis dados en compacto: 22 px y separaciones 12', () {
    final layout = sketchLayout(
      screenW: 800,
      screenH: 360,
      rivals: 5,
      myDiceCount: 5,
      consoleH: 72,
    );
    final w = widgetLayoutFor(layout);
    expect(w.tableH, lessThan(262));
    expect(w.myDice.first.width, 22);
    expect(debugCheckWidgetLayout(layout), isEmpty);
  });
}
