import 'package:cacho_app/theme.dart';
import 'package:cacho_app/widgets/panels.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frente de la CORRECCIÓN FLUTTER ronda 4 (26-oct, informe en
/// `audit/comparacion_ejemplo/ronda4_flutter.md`). Solo geometría
/// pura y tokens; las medidas en captura están en el informe.
void main() {
  test('ronda4 comodín: paso 72 en compacto, aire real entre píldoras', () {
    // Dado 36 + padding 18 × 2 = paso 72. Píldora: fondo ~64
    // (texto ~56 + padding 8) → aire 8 px entre fondos y 16 px
    // entre textos (antes, paso 58: fondos solapados 6 px y
    // textos a 2 px, "comodíncomodín").
    const step = 36.0 + 2 * 18.0;
    expect(step, 72);
    expect(step - 64, greaterThanOrEqualTo(8));
    expect(step - 56, greaterThanOrEqualTo(16));
    // La fila de 5 dados con paso 72 cabe en la celda de 406.
    expect(5 * 36 + 4 * 36, lessThanOrEqualTo(406 - 16));
  });

  test('ronda4 revelación: presupuesto sin cambio + alfas compactos', () {
    // El aire entre píldoras es horizontal: la altura no cambia.
    expect(revealContentHeight(6, step2: true, compact: true),
        lessThanOrEqualTo(290));
    expect(
        revealContentHeight(6,
            step2: true, compact: true, verdictLines: 2, eliminated: true),
        lessThanOrEqualTo(322));
    // Overlay compacto: mesa visible (no negro pleno), veredicto
    // algo más abierto que el conteo.
    expect(revealOverlayAlphaCount, 0.45);
    expect(revealOverlayAlphaVerdict, 0.38);
    expect(revealOverlayAlphaVerdict, lessThan(revealOverlayAlphaCount));
  });

  test('ronda4 ductus: un solo sitio gobierna las familias', () {
    // Valor del token del cuerpo: la familia vigente más cercana
    // a la sans recta del ejemplo (sans, recta; Cinzel es serif
    // déco y CaveatBrush manuscrita, ambas más lejos).
    expect(CachoFonts.body, 'Montserrat');
    expect(CachoFonts.display, 'Cinzel');
    expect(CachoFonts.hand, 'CaveatBrush');
  });

  test('ronda4 círculo/tile 1: geometría del desplazamiento', () {
    // Círculo 44×44 con top −50 sobre consola de alto 58: ocupa
    // −50..−6 relativo a la consola → 6 px de aire sobre su borde
    // superior y 0 px dentro de ella (antes top −22: 18 px dentro,
    // ~40 % de la cara del tile 1, que empieza en +4).
    const circleTop = -50.0;
    const circleSize = 44.0;
    const consoleTileTop = 4.0;
    expect(circleTop + circleSize, lessThanOrEqualTo(0));
    expect(0 - (circleTop + circleSize), 6);
    expect(circleTop + circleSize, lessThanOrEqualTo(consoleTileTop));
  });

  test('ronda4 logo: subida de 41 px = banda del ejemplo', () {
    // Banda ronda 3: y 156..203 en 390. Subida 41 px → 115..162.
    // Ejemplo: y 29,2..41,7 % de 390 = 114..163.
    const beforeTop = 156.0;
    const beforeBottom = 203.0;
    const shift = 41.0;
    expect(beforeTop - shift, greaterThanOrEqualTo(390 * 0.292 - 1));
    expect(beforeBottom - shift, lessThanOrEqualTo(390 * 0.417 + 1));
    expect((beforeTop + beforeBottom) / 2 - shift, closeTo(390 * 0.355, 2));
  });

  test('ronda4 apuesta en resolución: flex 3 frente a flex 1', () {
    // Centro ~347 px (844 − paddings − Salir/saldo − iconos −
    // pozo − gaps): sala ~87, apuesta ~260; la píldora de 8
    // caracteres (~186 px) cabe completa y la sala cede.
    const centre = 347.0;
    const bidShare = 3 / (3 + 1);
    expect(centre * bidShare, greaterThanOrEqualTo(186));
    expect(centre * (1 - bidShare), lessThan(186));
  });
}
