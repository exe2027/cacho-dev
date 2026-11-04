
import 'package:cacho_app/screens/game_screen.dart';
import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:cacho_engine/bots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GameScreen render test landscape', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = MatchController.local(
      nickname: 'Juan',
      botCount: 5,
      difficulty: BotDifficulty.media,
      config: GameConfig.clasico(),
      useTurnTimer: false,
    );
    c.startLocal();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(controller: c, leather: const Color(0xFF6B4226)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    c.dispose();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
