import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_app/state/music.dart';
import 'package:cacho_app/widgets/game/game_hud_widget.dart';
import 'package:cacho_app/widgets/dice_and_cup.dart';
import 'package:cacho_app/config/room_configs.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Audio Ducking & Mic Toggle Integration', () {
    test('Ducking volume calculation', () {
      // Sin micrófono: volumen original
      expect(duckedVolume(25, false), 25);
      expect(duckedVolume(50, false), 50);

      // Con micrófono abierto: ducking con tope en 11
      expect(duckedVolume(25, true), 11);
      expect(duckedVolume(50, true), 11);
      expect(duckedVolume(5, true), 5); // si es menor a 11, se mantiene bajo
    });

    test('Local MatchController toggles mic and syncs ducking state', () async {
      final c = MatchController.local(
        nickname: 'Player1',
        botCount: 2,
        difficulty: BotDifficulty.media,
        config: GameConfig.clasico(),
        useTurnTimer: false,
      );
      addTearDown(c.dispose);

      expect(c.myMicOn, false);
      expect(c.anyMicOpen, false);

      // Alternar micrófono en modo local
      await c.toggleMic();
      expect(c.myMicOn, true);
      expect(c.anyMicOpen, true);

      // Apagar micrófono
      await c.toggleMic();
      expect(c.myMicOn, false);
      expect(c.anyMicOpen, false);
    });

    testWidgets('GameHUDWidget displays MIC button and fires onToggleMic', (tester) async {
      bool micToggled = false;
      bool isMicOn = false;

      Widget buildHud() {
        return MaterialApp(
          home: Scaffold(
            body: GameHUDWidget(
              roomConfig: kRoomConfigs.first,
              pot: 500,
              isAudioMuted: false,
              onToggleAudio: () {},
              onExit: () {},
              isMicOn: isMicOn,
              onToggleMic: () => micToggled = true,
              isMyTurn: false,
              onSelectFace: (_) {},
              onAdjustQuantity: (_) {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildHud());
      expect(find.byIcon(Icons.mic_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic_off));
      await tester.pump();
      expect(micToggled, true);
    });
  });
}
