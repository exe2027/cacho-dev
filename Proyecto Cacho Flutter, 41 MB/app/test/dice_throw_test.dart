import 'package:cacho_app/widgets/dice_throw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dice_throw (solo visual, nunca cambia el resultado)', () {
    test('al final (progreso 1) el dado queda exactamente en su sitio',
        () {
      for (var count = 1; count <= 5; count++) {
        for (var i = 0; i < count; i++) {
          final t = diceThrowTransform(
            1,
            index: i,
            count: count,
            dieSize: 32,
            gap: 4,
          );
          expect(t.offset, Offset.zero);
          expect(t.rotation, 0);
          expect(t.scale, 1);
        }
      }
    });

    test('al inicio el dado arranca agrupado bajo el cacho, no en su sitio',
        () {
      // Dados exteriores: arrancan desplazados hacia el centro.
      final left = diceThrowTransform(
        0,
        index: 0,
        count: 5,
        dieSize: 32,
        gap: 4,
      );
      expect(left.offset.dx, greaterThan(0));
      expect(left.offset.dy, lessThan(0));
      // Dado central: arranca solo hacia arriba (ya está centrado).
      final center = diceThrowTransform(
        0,
        index: 2,
        count: 5,
        dieSize: 32,
        gap: 4,
      );
      expect(center.offset.dx, 0);
      expect(center.offset.dy, lessThan(0));
      // Escala inicial menor que la final: el dado "cae" a su tamaño.
      expect(left.scale, lessThan(1));
    });

    test('el escalonado no alarga el lanzamiento: todos terminan en 1',
        () {
      // A t=0.05 solo arrancó el dado 0 (el 1 arranca en 0.06); a t=1
      // todos terminaron juntos.
      for (var i = 0; i < 5; i++) {
        expect(diceThrowLocalProgress(0.05, i, 5),
            i == 0 ? greaterThan(0) : 0);
        expect(diceThrowLocalProgress(1, i, 5), 1);
      }
      // Duración total del controlador: 800 ms, no 800 por dado.
      expect(diceThrowDuration, const Duration(milliseconds: 800));
    });

    testWidgets('ThrownDie con animaciones apagadas pinta el hijo directo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThrownDie(
            index: 0,
            count: 5,
            dieSize: 32,
            active: true,
            enabled: false,
            child: Text('dado-3'),
          ),
        ),
      );
      expect(find.text('dado-3'), findsOneWidget);
    });

    testWidgets('ThrownDie animado termina sin error y conserva el hijo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThrownDie(
            index: 4,
            count: 5,
            dieSize: 32,
            active: true,
            enabled: true,
            child: Text('dado-6'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(diceThrowDuration);
      expect(find.text('dado-6'), findsOneWidget);
    });
  });
}
