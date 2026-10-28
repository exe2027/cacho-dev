import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frente MESA de la CORRECCIÓN FLUTTER ronda 2 (26-oct,
/// informe en `audit/comparacion_ejemplo/ronda2_flutter.md`).
/// Solo geometría pura del layout: la dirección de los vasos
/// mockup-6 (F3) y que el cambio no rompa el 0 solapes.
void main() {
  test('ronda2 F3 SUPERADO 27-oct, INVERTIDO 28-oct: avatar fuera, vaso dentro',
      () {
    // La RONDA 2 ponía los vasos superiores hacia dentro; la
    // corrección 27-oct los puso TODOS hacia fuera; la foto en
    // vivo del 28-oct mostró que eso dejaba al avatar sobre el
    // paño y al vaso en el borde exterior, al revés de lo que
    // el usuario quiere ("el vaso dentro de la mesa y el avatar
    // fuera"). Ahora el AVATAR va hacia fuera y el VASO hacia
    // el centro, con la misma distancia 62 y 0 solapes.
    for (final h in [390.0, 350.0]) {
      final l = sketchLayout(
        screenW: 844,
        screenH: h,
        rivals: 5,
        myDiceCount: 5,
        consoleH: h >= 390 ? 72.0 : 64.0,
      );
      final byAngle = {for (final s in l.seats) s.angleDeg: s};
      // Laterales: avatar exterior, vaso hacia el centro
      // (distancia avatar~vaso 62, como antes, solo invertida).
      expect(byAngle[225]!.avatar.cx, lessThan(byAngle[225]!.cup.cx));
      expect(byAngle[315]!.avatar.cx, greaterThan(byAngle[315]!.cup.cx));
      expect(byAngle[135]!.avatar.cx, lessThan(byAngle[135]!.cup.cx));
      expect(byAngle[45]!.avatar.cx, greaterThan(byAngle[45]!.cup.cx));
      final upLeftGap = byAngle[225]!.avatar.cx - byAngle[225]!.cup.cx;
      expect(upLeftGap.abs(), closeTo(62, 0.01));
      // Placa centrada bajo el avatar nuevo, no bajo el centro viejo.
      expect(byAngle[225]!.plate.cx, byAngle[225]!.avatar.cx);
      expect(byAngle[315]!.plate.cx, byAngle[315]!.avatar.cx);
      // Sin solapes con la geometría nueva.
      expect(l.overlaps(), isEmpty);
    }
  });

  test('ronda2 F3: referencia 6 rivales sin solapes y vasos junto al avatar',
      () {
    final l = sketchLayout(
      screenW: 844,
      screenH: 390,
      rivals: 6,
      myDiceCount: 5,
      consoleH: 72,
    );
    expect(l.seats.length, 6);
    expect(l.overlaps(), isEmpty);
    // Cada vaso queda a ≥ 62 del centro de su avatar (64 radial
    // arriba, 74 en costados, 62,1 en inferiores 60/120 por el
    // dy −4): hueco ≥ 5 px (radios 28 + 29 = 57).
    for (final s in l.seats) {
      final dx = s.cup.cx - s.avatar.cx;
      final dy = s.cup.cy - s.avatar.cy;
      final dist = (dx * dx + dy * dy);
      expect(dist, greaterThanOrEqualTo(62 * 62));
    }
  });
}
