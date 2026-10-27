import 'package:cacho_app/table_themes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tiers por apuesta: nombres nuevos docs/19 C7, montos sin cambiar', () {
    expect(stakeTierName(0), 'Sin apuesta');
    expect(stakeTierName(100), 'La Taberna');
    expect(stakeTierName(250), 'El Boliche');
    expect(stakeTierName(500), 'El Casino');
    expect(stakeTierName(1000), 'La Mansión');
    expect(stakeTierName(2500), 'El Club VIP');
    // Los paños por monto no cambian: solo el nombre.
    expect(tierLookFor(100).name, 'La Taberna');
    expect(tierLookFor(250).name, 'El Boliche');
    expect(tierLookFor(500).name, 'El Casino');
    expect(tierLookFor(1000).name, 'La Mansión');
    expect(tierLookFor(2500).name, 'El Club VIP');
    expect(tierLookFor(500).feltCenter.value, 0xFF171717);
  });

  test('mesas: nombres y validación (D1: Casino Dorado por defecto)', () {
    expect(defaultTableTheme, 'dorado');
    expect(tableThemeName('pub'), 'El Pub');
    expect(tableThemeName('dorado'), 'Casino Dorado');
    expect(tableThemeName('neon'), 'Neón Nocturno');
    expect(tableThemeName('otro'), 'Casino Dorado');
    expect(isValidTableTheme('pub'), isTrue);
    expect(isValidTableTheme('dorado'), isTrue);
    expect(isValidTableTheme('neon'), isTrue);
    expect(isValidTableTheme('8ball'), isFalse);
    expect(isValidTableTheme(null), isFalse);
  });
}
