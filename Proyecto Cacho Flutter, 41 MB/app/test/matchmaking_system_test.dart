import 'package:cacho_app/config/room_configs.dart';
import 'package:cacho_app/models/bot_profile_model.dart';
import 'package:cacho_app/services/bot_matchmaking_service.dart';
import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_app/widgets/game/matchmaking_overlay.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BotMatchmakingService & Gamer Tags Rules', () {
    test('Generates 5 distinct opponents with gamer tags and no real human names', () {
      final opponents = BotMatchmakingService.generateOpponents(
        count: 5,
        roomStake: 500,
        localPlayerName: 'MiUser',
      );

      expect(opponents.length, 5);

      final forbiddenNames = [
        'carlos', 'juan', 'manuel', 'pedro', 'chalo', 'cuca', 'guaton', 'pituca',
        'mateo', 'sofi', 'nacho', 'cata', 'lucho', 'pancho', 'diego', 'vale'
      ];

      for (final bot in opponents) {
        expect(bot.username.isNotEmpty, true);
        // Verificar que ningún nombre sea una persona real tradicional
        final lower = bot.username.toLowerCase();
        for (final forbidden in forbiddenNames) {
          expect(lower, isNot(equals(forbidden)),
              reason: '${bot.username} no debe ser un nombre de persona real');
        }

        // Verificar que tenga estilo gamertag (contenga _, -, o números/leetspeak)
        final isGamerTag = bot.username.contains('_') ||
            bot.username.contains('-') ||
            bot.username.contains(RegExp(r'\d')) ||
            bot.username.startsWith('xX_');
        expect(isGamerTag, true,
            reason: '${bot.username} debe tener formato de nickname/gamertag online');

        // Nivel coherente con sala stake 500 (12 a 28)
        expect(bot.level, greaterThanOrEqualTo(12));
        expect(bot.level, lessThanOrEqualTo(28));
      }

      // Nombres únicos entre sí
      final uniqueNames = opponents.map((b) => b.username).toSet();
      expect(uniqueNames.length, 5);
    });

    test('BotProfile serialization works correctly', () {
      final bot = BotProfile(
        id: 'bot1',
        username: 'CyberWolf_77',
        level: 24,
        winRatePercent: 62,
        coins: 5000,
      );

      final json = bot.toJson();
      final fromJson = BotProfile.fromJson(json);

      expect(fromJson.id, 'bot1');
      expect(fromJson.username, 'CyberWolf_77');
      expect(fromJson.level, 24);
      expect(fromJson.winRatePercent, 62);
      expect(fromJson.coins, 5000);
    });

    test('MatchController.local assigns custom gamertag bot names', () {
      final customNames = [
        'xX_Shadow_Xx',
        'CyberWolf_77',
        'K1ng_Player',
        'Ghost-Player-88',
        'NeonRider_2026',
      ];

      final c = MatchController.local(
        nickname: 'LocalHero',
        botCount: 5,
        difficulty: BotDifficulty.media,
        config: GameConfig.clasico(),
        customBotNames: customNames,
      );
      c.startLocal();
      addTearDown(c.dispose);

      final rivalNames = c.players.where((p) => p.id != c.myId).map((p) => p.nickname).toList();
      expect(rivalNames, customNames);
    });
  });

  group('MatchmakingOverlay Widget', () {
    testWidgets('Renders matchmaking overlay with room info and slots', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchmakingOverlay(
              roomConfig: kRoomConfigs.first,
              stake: 100,
              onMatched: (_) {},
            ),
          ),
        ),
      );

      // Debe mostrar el título inicial
      expect(find.text('BUSCANDO OPONENTES...'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);

      // Esperar un ciclo de animación
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('BUSCANDO OPONENTES...'), findsOneWidget);

      // Limpiar desmontando el widget para cancelar sus timers
      await tester.pumpWidget(const SizedBox());
    });
  });
}
