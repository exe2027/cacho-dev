import 'package:cacho_app/widgets/sketch_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Medición de solapes en el asiento propio (vaso, dados, avatar, placa).
/// No hay asserts, solo medición e impresión de resultados.
void main() {
  test('solapes mi asiento: vaso, dados, avatar, placa (medición)', () {
    final anchos = [667, 750, 844];
    final alturasMedio = List.generate(11, (i) => 340 + i * 10); // 340, 350, ..., 440

    // Encabezado de tabla
    // ignore: avoid_print
    print('\n=== MEDICIÓN DE SOLAPES EN MI ASIENTO ===\n');
    // ignore: avoid_print
    print(
        'ancho | totalH | tableH | compact | solapes/límites');
    // ignore: avoid_print
    print(
        '-------|--------|--------|---------|------------------------------------------');

    for (final ancho in anchos) {
      for (final totalH in alturasMedio) {
        // Calcular tableH como lo hace _buildLandscape:
        // totalH - safeTop(56) - VER(44) - consoleH(72) = totalH - 172
        final tableH = totalH - 56 - 44 - 72;

        // Si tableH es negativo, no hay espacio válido
        if (tableH <= 0) {
          // ignore: avoid_print
          print(
              '$ancho    | $totalH    | ${tableH.toStringAsFixed(0).padRight(6)} | N/A     | (sin espacio: tableH=$tableH)');
          continue;
        }

        // Llamar a sketchLayout con los parámetros
        final layout = sketchLayout(
          screenW: ancho.toDouble(),
          screenH: totalH.toDouble(),
          rivals: 0, // Sin rivales para medir solo mi asiento
          myDiceCount: 5,
          consoleH: 72,
        );

        // Recolectar rectángulos de mi asiento
        final vaso = layout.myCup;
        final avatar = layout.myAvatar;
        final placa = layout.myPlate;
        final dados = layout.myDice;

        // Verificar solapes entre pares
        final List<String> problemas = [];

        // Vaso vs Avatar
        if (vaso.overlaps(avatar)) {
          final area = vaso.overlapArea(avatar);
          problemas.add('vaso~avatar=${area.toStringAsFixed(0)}px²');
        }

        // Vaso vs Placa
        if (vaso.overlaps(placa)) {
          final area = vaso.overlapArea(placa);
          problemas.add('vaso~placa=${area.toStringAsFixed(0)}px²');
        }

        // Vaso vs Dados
        for (var i = 0; i < dados.length; i++) {
          if (vaso.overlaps(dados[i])) {
            final area = vaso.overlapArea(dados[i]);
            problemas.add('vaso~dado$i=${area.toStringAsFixed(0)}px²');
          }
        }

        // Avatar vs Placa
        if (avatar.overlaps(placa)) {
          final area = avatar.overlapArea(placa);
          problemas.add('avatar~placa=${area.toStringAsFixed(0)}px²');
        }

        // Avatar vs Dados
        for (var i = 0; i < dados.length; i++) {
          if (avatar.overlaps(dados[i])) {
            final area = avatar.overlapArea(dados[i]);
            problemas.add('avatar~dado$i=${area.toStringAsFixed(0)}px²');
          }
        }

        // Placa vs Dados
        for (var i = 0; i < dados.length; i++) {
          if (placa.overlaps(dados[i])) {
            final area = placa.overlapArea(dados[i]);
            problemas.add('placa~dado$i=${area.toStringAsFixed(0)}px²');
          }
        }

        // Verificar que nada se sale de la pantalla
        // (bottom <= totalH)
        if (vaso.bottom > totalH) {
          problemas.add('vaso fuera: bottom=${vaso.bottom.toStringAsFixed(0)} > $totalH');
        }
        if (avatar.bottom > totalH) {
          problemas.add(
              'avatar fuera: bottom=${avatar.bottom.toStringAsFixed(0)} > $totalH');
        }
        if (placa.bottom > totalH) {
          problemas.add(
              'placa fuera: bottom=${placa.bottom.toStringAsFixed(0)} > $totalH');
        }
        for (var i = 0; i < dados.length; i++) {
          if (dados[i].bottom > totalH) {
            problemas.add(
                'dado$i fuera: bottom=${dados[i].bottom.toStringAsFixed(0)} > $totalH');
          }
        }

        // Verificar izquierda (left >= 0)
        if (vaso.left < 0) {
          problemas.add('vaso izquierda: left=${vaso.left.toStringAsFixed(0)} < 0');
        }
        if (avatar.left < 0) {
          problemas.add(
              'avatar izquierda: left=${avatar.left.toStringAsFixed(0)} < 0');
        }
        if (placa.left < 0) {
          problemas.add('placa izquierda: left=${placa.left.toStringAsFixed(0)} < 0');
        }
        for (var i = 0; i < dados.length; i++) {
          if (dados[i].left < 0) {
            problemas.add('dado$i izquierda: left=${dados[i].left.toStringAsFixed(0)} < 0');
          }
        }

        // Verificar derecha (right <= screenW)
        if (vaso.right > ancho) {
          problemas.add(
              'vaso derecha: right=${vaso.right.toStringAsFixed(0)} > $ancho');
        }
        if (avatar.right > ancho) {
          problemas.add(
              'avatar derecha: right=${avatar.right.toStringAsFixed(0)} > $ancho');
        }
        if (placa.right > ancho) {
          problemas.add(
              'placa derecha: right=${placa.right.toStringAsFixed(0)} > $ancho');
        }
        for (var i = 0; i < dados.length; i++) {
          if (dados[i].right > ancho) {
            problemas.add(
                'dado$i derecha: right=${dados[i].right.toStringAsFixed(0)} > $ancho');
          }
        }

        // Imprimir resultado
        final compactStr = layout.compact ? 'true' : 'false';
        final problema = problemas.isEmpty ? 'OK' : problemas.join(', ');
        // ignore: avoid_print
        print(
            '$ancho    | $totalH    | ${tableH.toStringAsFixed(0).padRight(6)} | $compactStr    | $problema');
      }
    }

    // Final: no hay asserts, solo medición
    expect(true, isTrue);
  });
}
