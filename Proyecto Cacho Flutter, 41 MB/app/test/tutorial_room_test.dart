import 'package:cacho_app/main.dart';
import 'package:cacho_app/state/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('sala tutorial desaparece al completarse', (tester) async {
    tester.view.physicalSize = const Size(2400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 1. Estado inicial: tutorial no completado
    Settings.instance.guidedDone = false;

    await tester.pumpWidget(const CachoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // Debe existir la tarjeta del tutorial guiado
    expect(find.text('TU PRIMERA PARTIDA GUIADA'), findsOneWidget);
    expect(find.text('JUGAR TUTORIAL'), findsOneWidget);

    // 2. Jugador completa el tutorial
    await Settings.instance.markGuidedDone();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // La tarjeta del tutorial DEBE haber desaparecido por completo
    expect(find.text('TU PRIMERA PARTIDA GUIADA'), findsNothing);
    expect(find.text('JUGAR TUTORIAL'), findsNothing);

    // Y las salas reales deben permanecer activas (ej. La Taberna)
    expect(find.text('LA TABERNA'), findsOneWidget);

    // Dejar morir temporizador del probe
    await tester.pump(const Duration(seconds: 6));
  });
}
