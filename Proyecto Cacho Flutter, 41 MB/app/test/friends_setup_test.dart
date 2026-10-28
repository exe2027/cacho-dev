import 'package:cacho_app/screens/setup_screens.dart';
import 'package:cacho_app/table_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'CON AMIGOS rediseño: sin selector de mesa, crea con Dorado',
      (tester) async {
    String? capturedTheme;
    int? capturedStake;
    String? capturedPreset;
    final joinCode = TextEditingController();
    addTearDown(joinCode.dispose);

    // Rama angosta apilada del pie: la rama ancha (≥700 px) usa un
    // botón CREAR de 210 px cuyo texto en la fuente Ahem de los
    // tests desborda 32 px (en el dispositivo real usa Cinzel y
    // cabe); ese desborde es preexistente, no de este rediseño,
    // y no se prueba aquí.
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: FriendsSetupScreen(
        initialPreset: 'completo',
        onlineOk: true,
        onRetryProbe: () {},
        joinCode: joinCode,
        onCreate: ({required stake, required tableTheme, required preset}) {
          capturedStake = stake;
          capturedTheme = tableTheme;
          capturedPreset = preset;
        },
        onJoin: (_) {},
      ),
    ));
    // Sin pumpAndSettle: el SweepGlow de CREAR SALA anima en bucle
    // infinito (3 s) y nunca se asienta. Bombeos con duración bastan
    // para que StaggerIn deje los textos presentes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Secciones en orden y con su contenido, sin textos recortados
    // por un scroll horizontal: la página ya no usa columnas de
    // 320 px con scroll horizontal.
    expect(find.text('CON AMIGOS'), findsOneWidget);
    expect(find.text('Cacho completo'), findsOneWidget);
    expect(find.text('Billetera en línea'), findsOneWidget);
    expect(find.textContaining('POZO ='), findsOneWidget);
    expect(find.text('CREAR SALA'), findsOneWidget);
    expect(find.text('UNIRSE'), findsOneWidget);

    // Selector de mesa eliminado SOLO de CON AMIGOS: ni El Pub,
    // ni Neón (ni su borde cian) aparecen en esta página.
    expect(find.byType(TableThemePicker), findsNothing);
    expect(find.text('El Pub'), findsNothing);
    expect(find.text('Neón'), findsNothing);
    expect(find.text('Neón Nocturno'), findsNothing);
    expect(
      find.byWidgetPredicate((w) =>
          w is SingleChildScrollView &&
          w.scrollDirection == Axis.horizontal),
      findsNothing,
    );

    // Crear sala sigue funcionando y usa el tema por defecto.
    await tester.tap(find.text('CREAR SALA'));
    await tester.pump();
    expect(capturedTheme, defaultTableTheme);
    expect(capturedTheme, 'dorado');
    expect(capturedStake, 500);
    expect(capturedPreset, 'completo');
  });
}
