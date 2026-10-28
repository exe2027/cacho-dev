import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cacho_app/widgets/bid_pop.dart';
import 'package:cacho_app/widgets/cup_shake.dart';
import 'package:cacho_app/widgets/resolution_overlay.dart';

/// Animaciones nuevas del layout-sin-solapes (§3): existen,
/// terminan en reposo exacto y respetan el gate de apagado.
/// No prueban sonido ni captura real (eso solo se confirma en
/// vivo); prueban que el widget monta, anima y se libera sin
/// errores, y que con el gate apagado no mueve nada.
void main() {
  testWidgets('CupShake: agita y termina con el hijo intacto',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CupShake(
          child: SizedBox(width: 56, height: 64, child: Text('vaso')),
        ),
      ),
    );
    expect(find.text('vaso'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('vaso'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('vaso'), findsOneWidget);
    // Al terminar (700 ms) el hijo sigue en su sitio.
    await tester.pumpAndSettle();
    expect(find.text('vaso'), findsOneWidget);
  });

  testWidgets('CupShake apagado: pinta el hijo sin Transform',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CupShake(
          enabled: false,
          child: SizedBox(width: 56, height: 64, child: Text('vaso')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('vaso'), findsOneWidget);
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('BidPop: pop de 300 ms y reposo en escala 1',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BidPop(child: Text('POZO 600')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    // A mitad del pop la escala es > 1.
    final mid = tester.widget<Transform>(find.byType(Transform).first);
    expect(mid.transform.getMaxScaleOnAxis(), greaterThan(1.0));
    await tester.pumpAndSettle();
    final end = tester.widget<Transform>(find.byType(Transform).first);
    expect(end.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.001));
    expect(find.text('POZO 600'), findsOneWidget);
  });

  testWidgets('BidPop apagado: sin Transform', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BidPop(enabled: false, child: Text('POZO 600')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('VerdictFlash: borde verde/rojo sin tapar el hijo',
      (tester) async {
    for (final win in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: VerdictFlash(
            win: win,
            active: true,
            child: const Text('veredicto'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('veredicto'), findsOneWidget);
      // El borde es solo decoración (ignoring: true): el hijo
      // sigue visible y nada lo cubre con fondo opaco.
      expect(
          find.byWidgetPredicate(
              (w) => w is IgnorePointer && w.ignoring),
          findsOneWidget);
    }
  });

  testWidgets('VerdictFlash inactivo: solo el hijo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VerdictFlash(
          win: true,
          active: false,
          child: Text('veredicto'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring),
        findsNothing);
  });

  testWidgets('RevealCellAnim: sube escalonada y termina opaca',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RevealCellAnim(index: 0, child: Text('celda')),
      ),
    );
    await tester.pumpAndSettle();
    final opacity =
        tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, 1.0);
    expect(find.text('celda'), findsOneWidget);
  });
}
