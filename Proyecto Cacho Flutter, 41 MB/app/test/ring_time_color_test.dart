import 'package:cacho_app/theme.dart';
import 'package:cacho_app/widgets/dice_and_cup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ringTimeColor (semáforo del aro-temporizador)', () {
    test('verde con la mitad o más del turno', () {
      expect(ringTimeColor(1.0), CachoColors.calzoGreen);
      expect(ringTimeColor(0.5), CachoColors.calzoGreen);
    });

    test('amarillo entre la mitad y el último cuarto', () {
      expect(ringTimeColor(0.49), CachoColors.timeAmber);
      expect(ringTimeColor(0.25), CachoColors.timeAmber);
    });

    test('rojo en el último cuarto', () {
      expect(ringTimeColor(0.24), CachoColors.casinoRed);
      expect(ringTimeColor(0.0), CachoColors.casinoRed);
    });
  });

  group('seatRingColor (círculo del avatar)', () {
    test('en su turno toma el semáforo', () {
      expect(
          seatRingColor(
              identity: CachoColors.gold, isTurn: true, fraction: 0.9),
          CachoColors.calzoGreen);
      expect(
          seatRingColor(
              identity: CachoColors.gold, isTurn: true, fraction: 0.3),
          CachoColors.timeAmber);
      expect(
          seatRingColor(
              identity: CachoColors.gold, isTurn: true, fraction: 0.1),
          CachoColors.casinoRed);
    });

    test('fuera de turno conserva la identidad', () {
      expect(
          seatRingColor(
              identity: CachoColors.gold, isTurn: false, fraction: 0.1),
          CachoColors.gold);
      expect(
          seatRingColor(
              identity: CachoColors.gold, isTurn: true, fraction: null),
          CachoColors.gold);
    });
  });

  group('isBeepSecond (pitidos de apuro)', () {
    test('solo en los segundos 13-15 (semáforo rojo)', () {
      // Pitidos cuando el aro pasa a rojo: 15, 14, 13 segundos
      expect(isBeepSecond(15), isTrue);
      expect(isBeepSecond(14), isTrue);
      expect(isBeepSecond(13), isTrue);
      // Fuera del rango: no suenan
      expect(isBeepSecond(16), isFalse);
      expect(isBeepSecond(12), isFalse);
      expect(isBeepSecond(3), isFalse);
      expect(isBeepSecond(1), isFalse);
      expect(isBeepSecond(0), isFalse);
    });
  });
}
