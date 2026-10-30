import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Medición de la mesa bosquejo (sentencia F1/F2): la geometría se
/// afirma con números, nunca con "se ve bien". La primera parte
/// imprime la tabla completa; los asserts duros están abajo y se
/// fijaron con los números medidos (ver salida del test).
void main() {
  test('tabla de solapes mesa bosquejo (solo medición)', () {
    for (final h in [390.0, 350.0]) {
      final consoleH = h >= 390 ? 72.0 : 64.0;
      for (var rivals = 0; rivals <= 11; rivals++) {
        for (final dice in [5, 3, 1]) {
          final l = sketchLayout(
            screenW: 844,
            screenH: h,
            rivals: rivals,
            myDiceCount: dice,
            consoleH: consoleH,
          );
          final ov = l.overlaps();
          if (ov.isEmpty) {
            // ignore: avoid_print
            print('H=$h rivales=$rivals dados=$dice: LIMPIO');
          } else {
            // ignore: avoid_print
            print('H=$h rivales=$rivals dados=$dice: '
                '${ov.map((e) => '${e.$1.label}~${e.$2.label}=${e.$3.toStringAsFixed(0)}px²').join(', ')}');
          }
        }
      }
    }
  });

  test('invariantes duros a 390 (avatares, pozo, mi asiento)', () {
    for (var rivals = 0; rivals <= 11; rivals++) {
      final l = sketchLayout(
        screenW: 844,
        screenH: 390,
        rivals: rivals,
        myDiceCount: 5,
        consoleH: 72,
      );
      // Avatares rivales nunca se tocan entre sí ni a mi avatar.
      // Medida círculo-círculo (referencia: círculo 56 + aro =
      // 58; arco igual 7+: círculo 46 + aro = 50; mi avatar 64).
      // La caja del widget incluye la sombra, que no es
      // información.
      final avatars = [
        for (final s in l.seats) s.avatar,
        l.myAvatar,
      ];
      for (var i = 0; i < avatars.length; i++) {
        for (var j = i + 1; j < avatars.length; j++) {
          final dx = avatars[i].cx - avatars[j].cx;
          final dy = avatars[i].cy - avatars[j].cy;
          final dist = dx * dx + dy * dy;
          final myPair =
              i == avatars.length - 1 || j == avatars.length - 1;
          final minDist = myPair
              ? (rivals >= 7 ? 57.0 : 61.0)
              : (rivals >= 7 ? 50.0 : 58.0);
          expect(dist >= minDist * minDist, isTrue,
              reason:
                  'H=390 rivales=$rivals: ${avatars[i].label} ~ ${avatars[j].label}');
        }
      }
      // El pozo nunca lo tapa ningún vaso.
      for (final s in l.seats) {
        expect(l.pot.overlaps(s.cup), isFalse,
            reason: 'H=390 rivales=$rivals: pozo ~ ${s.cup.label}');
      }
      // Mi asiento queda dentro de la pantalla y sobre la mesa.
      expect(l.myAvatar.bottom, lessThanOrEqualTo(390));
      expect(l.myAvatar.top, greaterThanOrEqualTo(l.tableTop));
      // Mi vaso no tapa mi avatar ni mi placa.
      expect(l.myCup.overlaps(l.myAvatar), isFalse);
      expect(l.myCup.overlaps(l.myPlate), isFalse);
    }
  });

  test('hasta 5 rivales limpio a 350 compacto (medido)', () {
    for (var rivals = 0; rivals <= 5; rivals++) {
      for (final dice in [5, 3, 1]) {
        final l = sketchLayout(
          screenW: 844,
          screenH: 350,
          rivals: rivals,
          myDiceCount: dice,
          consoleH: 64,
        );
        final ov = l.overlaps();
        expect(ov, isEmpty,
            reason: 'H=350 rivales=$rivals dados=$dice: '
                '${ov.map((e) => '${e.$1.label}~${e.$2.label}').join(', ')}');
      }
    }
  });

  // 12 jugadores (corrección 25-oct): rediseño con arco igual
  // antes de declarar no-cabe. sketchLayout con 11 rivales debe
  // devolver 11 asientos; el test de medición de arriba muestra
  // si el arco igual cierra sin solapes.
  test('11 rivales: arco igual devuelve 11 asientos (sin crash)', () {
    final l = sketchLayout(
      screenW: 844,
      screenH: 390,
      rivals: 11,
      myDiceCount: 5,
      consoleH: 72,
    );
    expect(l.seats.length, 11);
  });

  // Arco igual (7-11 rivales) a 390: MEDICIÓN, no assert de
  // limpieza. VEREDICTO 25-oct tras 7 rondas de rediseño
  // (referencia, arco igual, ry 70, placas divergentes, vasos
  // laterales hacia fuera, avatar 50, vaso 44×52, radial 52,
  // placas 84, stagger superior): ≤6 rivales LIMPIO (assert
  // arriba); 7 rivales: 1 roce de 18 px² (dados=5); 8 rivales:
  // 1-2 pares vaso~avatar (80-345 px²); 9-11 rivales: solapes
  // múltiples placa~placa y vaso~avatar. Causa estructural
  // medida: paso ~72 px con placas de 84 (el nombre más largo
  // real mide ~78-80 a 14 px) — en pares superiores no hay
  // separación vertical posible (barra arriba, avatar abajo)
  // y en diagonal el vaso no puede limpiar su propio avatar
  // (radial ≥47/51) y el vecino (radial ≤~44) a la vez. 10-12
  // jugadores = NO CABE con esta evidencia (ver informe).
  // Vía futura sin implementar (cambiaría la tipografía y
  // necesita aprobación): fuente condensada para placas.
  test('7-11 rivales arco igual a 390 (medición + nº asientos)', () {
    for (var rivals = 7; rivals <= 11; rivals++) {
      for (final dice in [5, 3, 1]) {
        final l = sketchLayout(
          screenW: 844,
          screenH: 390,
          rivals: rivals,
          myDiceCount: dice,
          consoleH: 72,
        );
        expect(l.seats.length, rivals);
        final ov = l.overlaps();
        // ignore: avoid_print
        print('H=390 rivales=$rivals dados=$dice: '
            '${ov.isEmpty ? 'LIMPIO' : ov.map((e) => '${e.$1.label}~${e.$2.label}=${e.$3.toStringAsFixed(0)}').join(', ')}');
      }
    }
  });

  // Límite medido (no el "hasta 8" de la sentencia): sin asiento
  // superior central (choca con el pozo) y sin diagonales
  // adyacentes, el cierre limpio llega a 6 rivales (7 jugadores).
  // Con 7+ rivales el test de medición de arriba muestra los
  // solapes; esa es la evidencia del no-cabe, no un fallo oculto.
  test('hasta 6 rivales limpio a 390 (medido)', () {
    for (var rivals = 0; rivals <= 6; rivals++) {
      for (final dice in [5, 3, 1]) {
        final l = sketchLayout(
          screenW: 844,
          screenH: 390,
          rivals: rivals,
          myDiceCount: dice,
          consoleH: 72,
        );
        final ov = l.overlaps();
        expect(ov, isEmpty,
            reason: 'H=390 rivales=$rivals dados=$dice: '
                '${ov.map((e) => '${e.$1.label}~${e.$2.label}').join(', ')}');
      }
    }
  });

  test('caso intermedio: unificación compact (screenH < 390)', () {
    // El desacuerdo ocurría: widget calculaba compact = (totalH < 390),
    // pero layout calculaba compact = (tableH < 262).
    // Con layout screenH = barra + tableH + consola = 56 + tableH + 72:
    // a screenH=390 → tableH=262 (no < 262: compact=false).
    // a screenH<390 → tableH<262 (compact=true en ambas capas).
    // Test verifica que layout.compact y el cálculo del widget concuerdan.
    for (final screenH in [389.0, 350.0, 340.0]) {
      final consoleH = 72.0;
      final tableH = screenH - 56.0 - consoleH;
      final expectedCompact = tableH < 262;

      final l = sketchLayout(
        screenW: 844,
        screenH: screenH,
        rivals: 3,
        myDiceCount: 5,
        consoleH: consoleH,
      );

      // Verificar que tableH real es cercano al esperado.
      expect(l.tableH, closeTo(tableH, 1.0),
          reason: 'screenH=$screenH: tableH=${l.tableH} vs esperado $tableH');

      // layout.compact debe coincidir con la regla: tableH < 262
      expect(l.compact, expectedCompact,
          reason: 'screenH=$screenH: tableH=${l.tableH} → compact debe ser '
              '$expectedCompact pero es ${l.compact}');
    }
  });
}
