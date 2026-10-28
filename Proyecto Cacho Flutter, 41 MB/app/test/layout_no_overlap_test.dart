import 'package:flutter_test/flutter_test.dart';

import 'package:cacho_app/widgets/seat_layout.dart';
import 'package:cacho_app/widgets/sketch_layout.dart';

/// Layout sin solapes (encargo 28-oct): la mesa horizontal no
/// puede tener ningún elemento tapando a otro en los 3 tamaños
/// pedidos (640×360, 844×390, 932×430) con 2, 3, 4 y 5 jugadores
/// en total (1–4 rivales), ni contra POZO, VER, consola ni
/// barra inferior. Además se incluye el caso de 6 jugadores
/// (5 rivales, fuera del rango pedido) porque es el único que
/// contiene el asiento superior en su bolsillo angosto: si ese
/// caso fallara, el bolsillo angosto estaría roto aunque el
/// rango pedido pasara.
///
/// Geometría widget real (`widgetLayoutFor` + `checkElementOverlaps`
/// en `seat_layout.dart`), no la geométrica: los widgets miden
/// más que sus rects (placa 180/150/120, vaso 73×72, avatar 64/56/48).
/// El POZO aquí es la píldora de la BARRA SUPERIOR (x centrada,
/// y 14..42): el pozo ya no vive en la mesa, así que ningún vaso
/// puede taparlo por construcción, y este test lo comprueba
/// contra todos los asientos.
///
/// Nota honesta: el logo "CACHO DUDO" de la foto es arte del
/// fondo de la mesa, no un widget con rect; la zona central
/// comprobable es la unión mi vaso + mis dados. La tira VER se
/// modela con sus rects reales: VER en x 8..~95 y el botón único
/// de chat/reacciones en x (ancho−52)..(ancho−8), ambos en la
/// fila de 44 px bajo la mesa.
void main() {
  WidgetTableLayout buildTable(
      double screenW, double screenH, int rivals, int myDice) {
    final tableH = screenH - 56 - 44 - 72;
    final layout = sketchLayout(
      screenW: screenW,
      screenH: 56 + tableH + 72,
      rivals: rivals,
      myDiceCount: myDice,
      consoleH: 72,
    );
    return widgetLayoutFor(layout);
  }

  group('cero solapes en los 3 tamaños', () {
    const sizes = [
      (640.0, 360.0),
      (844.0, 390.0),
      (932.0, 430.0),
    ];
    for (final (w, h) in sizes) {
      for (var rivals = 1; rivals <= 5; rivals++) {
        for (final dice in [5, 3, 1]) {
          test('${w.toInt()}×${h.toInt()}, ${rivals + 1} jugadores, '
              '$dice dados', () {
            final t = buildTable(w, h, rivals, dice);
            expect(checkElementOverlaps(t), isEmpty,
                reason: 'solapes de elementos en ${w}x$h, '
                    '${rivals + 1} jugadores, $dice dados');
            // Todos los rects dentro del ancho de pantalla.
            final boxes = [
              for (final s in t.seats) ...[s.avatar, s.plate, s.cup],
              ...t.myDice,
              t.myCup,
              t.myAvatar,
              t.myPlate,
            ];
            for (final b in boxes) {
              expect(b.left, greaterThanOrEqualTo(0),
                  reason: '${b.label} sale por la izquierda en ${w}x$h');
              expect(b.right, lessThanOrEqualTo(w),
                  reason: '${b.label} sale por la derecha en ${w}x$h');
            }
            // Mi placa termina 8 px antes de la consola.
            expect(t.myPlate.bottom, lessThanOrEqualTo(t.consoleTop - 8),
                reason: 'mi placa toca la consola en ${w}x$h');
            // Pozo de la barra superior: disjunto de todo asiento.
            for (final s in t.seats) {
              for (final b in [s.avatar, s.plate, s.cup]) {
                expect(t.pot.overlaps(b), isFalse,
                    reason: 'POZO de barra tapa ${b.label} en ${w}x$h');
              }
            }
            expect(t.pot.top, 14);
            expect(t.pot.height, 28);
          });
        }
      }
    }
  });

  group('tira VER + botón de chat: sin tapar a nadie', () {
    const sizes = [
      (640.0, 360.0),
      (844.0, 390.0),
      (932.0, 430.0),
    ];
    for (final (w, h) in sizes) {
      test('${w.toInt()}×${h.toInt()}', () {
        final t = buildTable(w, h, 5, 5);
        // La tira vive bajo la mesa: mesa termina en tableBottom
        // = 56 + tableH; la tira ocupa 44 px desde ahí.
        final tableBottom = 56 + t.tableH;
        final ver = WidgetBox('VER', 8, tableBottom, 87, 44);
        final chat = WidgetBox('chat', w - 52, tableBottom, 44, 44);
        for (final strip in [ver, chat]) {
          for (final b in [t.myPlate, t.myAvatar]) {
            expect(strip.overlaps(b), isFalse,
                reason: '${strip.label} tapa ${b.label} en ${w}x$h');
          }
          for (final s in t.seats) {
            // Laterales inferiores (315/45): sus placas cuelgan
            // hacia la tira; la tira central no las toca.
            if (s.angleDeg == 315 || s.angleDeg == 45) {
              expect(strip.overlaps(s.plate), isFalse,
                  reason: '${strip.label} tapa ${s.plate.label} en ${w}x$h');
            }
          }
        }
      });
    }
  });

  group('zona central reservada: solo mis dados y mi vaso', () {
    const sizes = [
      (640.0, 360.0),
      (844.0, 390.0),
      (932.0, 430.0),
    ];
    for (final (w, h) in sizes) {
      for (var rivals = 1; rivals <= 5; rivals++) {
        test('${w.toInt()}×${h.toInt()}, ${rivals + 1} jugadores', () {
          final t = buildTable(w, h, rivals, 5);
          final center = WidgetBox.union('centro', [t.myCup, ...t.myDice]);
          for (final s in t.seats) {
            for (final b in [s.avatar, s.plate, s.cup]) {
              expect(center.overlaps(b), isFalse,
                  reason: '${b.label} invade la zona central en ${w}x$h');
            }
          }
        });
      }
    }
  });
}
