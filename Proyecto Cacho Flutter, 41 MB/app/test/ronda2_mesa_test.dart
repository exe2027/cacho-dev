import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frente MESA de la CORRECCIÓN FLUTTER ronda 2 (26-oct,
/// informe en `audit/comparacion_ejemplo/ronda2_flutter.md`).
/// Solo geometría pura del layout: la dirección de los vasos
/// mockup-6 (F3) y que el cambio no rompa el 0 solapes.
void main() {
  test('ronda2 F3: vasos superiores hacia dentro, inferiores hacia fuera',
      () {
    for (final h in [390.0, 350.0]) {
      final l = sketchLayout(
        screenW: 844,
        screenH: h,
        rivals: 5,
        myDiceCount: 5,
        consoleH: h >= 390 ? 72.0 : 64.0,
      );
      final byAngle = {for (final s in l.seats) s.angleDeg: s};
      // Superior-izquierda (225) y superior-derecha (315): el vaso
      // va hacia el centro (dentro del óvalo), no hacia fuera.
      expect(byAngle[225]!.cup.cx, greaterThan(byAngle[225]!.avatar.cx));
      expect(byAngle[315]!.cup.cx, lessThan(byAngle[315]!.avatar.cx));
      // Inferior-izquierda (135) e inferior-derecha (45): hacia
      // fuera como siempre, junto al avatar (hueco 5 px: centro
      // del vaso a 62 del centro del avatar, radios 28 + 29 = 57).
      expect(byAngle[135]!.cup.cx, lessThan(byAngle[135]!.avatar.cx));
      expect(byAngle[45]!.cup.cx, greaterThan(byAngle[45]!.avatar.cx));
      final upLeftGap = byAngle[225]!.avatar.cx - byAngle[225]!.cup.cx;
      expect(upLeftGap.abs(), closeTo(62, 0.01));
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
