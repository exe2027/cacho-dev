import 'package:cacho_app/screens/home_screen.dart';
import 'package:cacho_app/screens/how_to_play_screen.dart';
import 'package:cacho_app/state/settings.dart';
import 'package:cacho_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Wrapper mínimo para renderizar HomeScreen en tests
// (evita _AuthGate que requiere Firebase inicializado)
Widget _testApp(Widget home) => MaterialApp(
      theme: buildCachoTheme(),
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('inicio sin scroll: marca, caminos y personalizar',
      (tester) async {
    // TODO-horizontal (26-oct): el home solo existe en horizontal; el
    // _PortraitGate tapa el home en portrait, así que este test bombea
    // landscape (mismos píxeles, orientación invertida). Las aserciones
    // no cambian: marca, caminos y personalizar deben estar presentes.
    tester.view.physicalSize = const Size(2400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Usar HomeScreen directamente (sin _AuthGate de Firebase)
    await tester.pumpWidget(_testApp(const HomeScreen()));
    await tester.pump();
    // AN1: el telón de apertura (350 ms) muestra el logo una segunda
    // vez mientras está cerrado; al completarse solo queda el del home.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('DUDO'), findsOneWidget);
    expect(find.text('CACHO · EL DUDO CHILENO'), findsOneWidget);
    expect(find.text('¿QUÉ TAN BUENO ERES MINTIENDO?'), findsOneWidget);
    expect(find.text('TU PRIMERA PARTIDA GUIADA'), findsOneWidget);
    expect(find.text('JUGAR CONTRA LA MÁQUINA'), findsOneWidget);
    expect(find.text('JUGAR CON AMIGOS'), findsOneWidget);
    expect(find.text('CÓMO SE JUEGA'), findsWidgets);
    // Sin campo de servidor en ninguna parte (la URL es interna).
    expect(find.byType(TextField), findsNothing);
    // Dejar morir el temporizador del probe de conexión (5 s).
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('cómo se juega: 4 pantallas y glosario con las pintas',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));
    await tester.pump();
    expect(find.textContaining('Tus dados son secretos'), findsOneWidget);
    // Avanzar hasta el glosario.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text(i == 3 ? 'VER EL GLOSARIO' : 'SIGUIENTE'));
      await tester.pumpAndSettle();
    }
    expect(find.text('LAS PINTAS'), findsOneWidget);
    expect(find.text('Pato'), findsOneWidget);
    expect(find.text('Sexta'), findsOneWidget);
    expect(find.byType(GlossaryContent), findsOneWidget);
  });
}
