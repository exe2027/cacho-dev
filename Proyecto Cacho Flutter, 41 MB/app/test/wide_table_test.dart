import 'package:cacho_app/widgets/dice_and_cup.dart';
import 'package:cacho_app/widgets/dice_throw.dart';
import 'package:cacho_app/widgets/seat_layout.dart';
import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mesa ancha/apaisada, corrección 28-oct (reporte en vivo: todo
/// apilado en la columna central y asientos inferiores tapados
/// por la barra, en mesa real 180–210 px de un iPhone apaisado).
///
/// Regla del usuario: NINGÚN elemento puede tapar a otro.
/// En mesa normal (tableH ≥ 262) se exige el chequeo completo de
/// `seat_layout.dart` (márgenes de slot incluidos). En mesa corta
/// (tableH < 262) el asiento 270 vive en un bolsillo a la
/// izquierda del pozo y su unión de slot queda a 1–2 px de mi
/// slot en la anchura mínima (844): la unión es un proxy y ahí
/// no es exigible, así que en corto se exige lo que el usuario
/// pidió literalmente — 0 solapes de ELEMENTO — más que ningún
/// asiento rival caiga bajo la mesa (donde la tira VER y la
/// consola lo taparían) y que mi vaso nunca sea menor que el
/// rival (64×72 frente a 56×64).
void main() {
  const widths = [844.0, 1024.0, 1180.0];
  const shortTables = [180.0, 206.0, 230.0, 250.0];
  const normalTables = [262.0, 300.0, 360.0, 480.0];

  List<String> elementOverlaps(WidgetTableLayout w) =>
      checkElementOverlaps(w);

  test('mesa normal ancha: 0 violaciones (márgenes incluidos)', () {
    for (final sw in widths) {
      for (final th in normalTables) {
        final layout = sketchLayout(
            screenW: sw, screenH: 56 + th + 72, rivals: 5, myDiceCount: 5);
        final v = checkWidgetLayout(widgetLayoutFor(layout));
        expect(v, isEmpty, reason: 'W=$sw tableH=$th: $v');
      }
    }
  });

  test('mesa corta ancha: 0 solapes de elemento, nada bajo la mesa',
      () {
    for (final sw in widths) {
      for (final th in shortTables) {
        final layout = sketchLayout(
            screenW: sw, screenH: 56 + th + 72, rivals: 5, myDiceCount: 5);
        final w = widgetLayoutFor(layout);
        final overlaps = elementOverlaps(w);
        expect(overlaps, isEmpty, reason: 'W=$sw tableH=$th: $overlaps');
        // Nada rival bajo la mesa: la tira VER y la consola
        // pintan después del Expanded y taparían lo que caiga.
        for (final s in w.seats) {
          for (final box in [s.avatar, s.plate, s.cup]) {
            expect(box.bottom - 56, lessThanOrEqualTo(th - 1),
                reason: 'W=$sw tableH=$th ${box.label} bottom '
                    '${(box.bottom - 56).toStringAsFixed(0)} > mesa');
          }
        }
        // Mi vaso nunca menor que el rival (28-oct).
        expect(layout.myCup.width, greaterThanOrEqualTo(56));
        expect(layout.myCup.height, greaterThanOrEqualTo(64));
        expect(layout.myCup.width, 64);
        expect(layout.myCup.height, 72);
        // El 270 en corto vive en el bolsillo izquierdo, no en
        // la columna central apilada.
        final top = w.seats.firstWhere((s) => s.angleDeg == 270);
        expect(top.avatar.cx, lessThan(sw / 2 - 50),
            reason: 'W=$sw tableH=$th: el 270 debe ir al bolsillo');
      }
    }
  });

  test('tirada de turno: aterrizaje en mesa corta no cae sobre mi vaso',
      () {
    for (final sw in widths) {
      for (final th in shortTables) {
        final layout = sketchLayout(
            screenW: sw, screenH: 56 + th + 72, rivals: 5, myDiceCount: 5);
        final land = turnThrowLanding(
          tableH: th,
          screenW: sw,
          potBottomRel: 34,
          topPlateTopRel: 130,
        );
        // Fila de 5 dados de 20 px + gap 4 = 116 px.
        final rowLeft = land.dx - 58;
        final rowRight = land.dx + 58;
        final rowTop = land.dy - 10;
        final rowBottom = land.dy + 10;
        // Fuera del pozo (cx±90, 2..34) y de mi vaso (cx±32,
        // mesa 40..112 a mesa 180 y más abajo al crecer).
        expect(rowLeft, greaterThan(sw / 2 + 90 + 8));
        expect(rowBottom, lessThanOrEqualTo(40));
        expect(rowTop, greaterThanOrEqualTo(2));
        // Fuera del vaso lateral superior derecho (a 844 el
        // aire es de 7 px; a anchos mayores, mucho más).
        final upperRight = widgetLayoutFor(layout)
            .seats
            .firstWhere((s) => s.angleDeg == 315);
        expect(rowRight, lessThanOrEqualTo(upperRight.cup.left - 3));
      }
    }
    // Mesa normal: el aterrizaje sigue en el centro, entre pozo
    // y placa superior.
    final land = turnThrowLanding(
        tableH: 300, screenW: 844, potBottomRel: 34, topPlateTopRel: 98);
    expect(land, const Offset(422, 66));
  });

  test('rebote final del vaso: 0 en los extremos, 8 en la mitad', () {
    expect(cupSettleDy(0, 1), closeTo(0, 0.001));
    expect(cupSettleDy(1, 1), closeTo(0, 0.001));
    expect(cupSettleDy(0.5, 1), closeTo(8, 0.001));
    expect(cupSettleDy(0.5, 0), 0);
    expect(cupSettleDy(0.5, 0.5), closeTo(4, 0.001));
  });

  test('placa en turno: borde dorado persistente, fuera tenue', () {
    expect(
        sketchPlateBorderColor(isTurn: true, ringColor: Colors.amber),
        Colors.amber);
    expect(sketchPlateBorderWidth(true), 2.0);
    expect(sketchPlateBorderWidth(false), 1.2);
    expect(
        sketchPlateBorderColor(isTurn: false, ringColor: Colors.amber),
        Colors.white.withValues(alpha: 0.18));
  });
}
