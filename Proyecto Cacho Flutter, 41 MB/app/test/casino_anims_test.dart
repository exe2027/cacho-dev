// Animaciones de casino (sentencia AN, 2026-10-25): funciones puras y
// el interruptor global. Los widgets animados se verifican en vivo;
// aquí se cubre lo que decide el comportamiento sin frames.
import 'package:flutter_test/flutter_test.dart';
import 'package:cacho_app/state/settings.dart';
import 'package:cacho_app/widgets/casino_anims.dart';

void main() {
  setUp(() => Settings.instance.animationsEnabled = true);
  tearDown(() => Settings.instance.animationsEnabled = true);

  test('rollerDigit: al inicio muestra 0 y al final el objetivo', () {
    expect(rollerDigit(0, 5), 0);
    expect(rollerDigit(1, 5), 5);
    expect(rollerDigit(2, 5), 5);
  });

  test('rollerDigit: gira por dígitos sin pasarse del objetivo', () {
    // spins=2 -> 25 pasos: 0.99*25 = 24 -> 24 % 10 = 4.
    expect(rollerDigit(0.99, 5, spins: 2), 4);
    expect(rollerDigit(0.5, 0), 0);
    expect(rollerDigit(0.03, 7), 0);
  });

  test('CasinoAnims.dur respeta el interruptor global', () {
    expect(CasinoAnims.dur(const Duration(seconds: 2)),
        const Duration(seconds: 2));
    Settings.instance.animationsEnabled = false;
    expect(CasinoAnims.dur(const Duration(seconds: 2)), Duration.zero);
    expect(CasinoAnims.enabled, isFalse);
  });
}
