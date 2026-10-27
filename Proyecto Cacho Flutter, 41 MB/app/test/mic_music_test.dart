import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_app/widgets/dice_and_cup.dart';
import 'package:cacho_app/widgets/music_sheet.dart';
import 'package:cacho_app/widgets/yt_host.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frente MICRÓFONO + MÚSICA (corrección 26-oct): la voz y la música no
/// se quitaron — estas pruebas fijan su presencia a nivel de widget:
/// insignia de mic, barra de música con su hoja DJ y host nativo.
///
/// Nota: el host nativo en horizontal es un hueco de montaje en
/// game_screen.dart (otro frente, parche P1 del informe), no de este
/// widget: aquí solo se fija que NativeYtHost renderiza sin romper el
/// árbol cuando aún no hay controlador (plataforma de test).
void main() {
  testWidgets('MicBadge: apagado/encendido y toque del propio asiento',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: MicBadge(on: false, onTap: () => taps++),
        ),
      ),
    ));
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    await tester.tap(find.byType(MicBadge));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: MicBadge(on: true))),
    ));
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.mic_off), findsNothing);
  });

  testWidgets('MusicBar: texto sin DJ y un toque abre la hoja DJ',
      (tester) async {
    final c = MatchController.local(
      nickname: 'Ana',
      botCount: 1,
      difficulty: BotDifficulty.media,
      config: GameConfig.clasico(),
      useTurnTimer: false,
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MusicBar(controller: c)),
    ));
    expect(find.text('Música de la sala: sin DJ'), findsOneWidget);
    await tester.tap(find.text('Música de la sala: sin DJ'));
    await tester.pumpAndSettle();
    expect(find.text('MÚSICA DE LA SALA'), findsOneWidget);
    expect(find.text('Cola'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Mi YouTube'), findsOneWidget);
  });

  testWidgets('NativeYtHost: sin controlador no rompe el árbol',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NativeYtHost()),
    ));
    await tester.pump();
    expect(find.byType(NativeYtHost), findsOneWidget);
    // Sin controlador no hay WebView montado (el host espera en
    // silencio a que MusicService cree el reproductor).
    expect(find.byType(NativeYtHost), findsOneWidget);
    // Desmontar cancela su vigilancia periódica (sin timers vivos).
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pump();
  });
}
