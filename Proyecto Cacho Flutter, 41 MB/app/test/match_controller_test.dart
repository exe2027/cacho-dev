import 'package:cacho_app/state/match_controller.dart';
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('partida local: reparte, apuesto y el bot responde dudando', () async {
    final c = MatchController.local(
      nickname: 'Ana',
      botCount: 1,
      difficulty: BotDifficulty.media,
      config: GameConfig.clasico(),
      roller: ScriptedDiceRoller([
        6, 1, // desempate: parto yo
        6, 6, 6, 1, 2, // mi mano: cuatro sextas contando el comodín
        6, 5, 4, 3, 2, // mano del bot
        ...List.filled(40, 3), // rondas siguientes
      ]),
      botDelay: const Duration(milliseconds: 200),
      useTurnTimer: false,
    );
    c.startLocal();
    expect(c.phase, 'playing');
    expect(c.currentPlayerId, 'yo');
    expect(c.myHand, [6, 6, 6, 1, 2]);
    expect(c.players.length, 2);

    c.doBid(const Bid(4, 6)); // hay 5 en la mesa: el bot debería dudar
    expect(c.currentPlayerId, 'bot1');

    await Future<void>.delayed(const Duration(milliseconds: 350));
    // El bot dudó, la apuesta era cierta: pierde él y parte la ronda 2.
    expect(c.uiResolution?.type, 'dudo');
    expect(c.playerById('bot1')?.diceCount, 4);
    expect(c.round, 2);
    expect(c.currentPlayerId, 'bot1');
    c.dispose();
  });

  test('apuesta ilegal: queda el error y no pasa el turno', () {
    final c = MatchController.local(
      nickname: 'Ana',
      botCount: 1,
      difficulty: BotDifficulty.media,
      config: GameConfig.clasico(),
      roller: ScriptedDiceRoller([
        6, 1,
        2, 2, 2, 2, 2,
        3, 3, 3, 3, 3,
      ]),
      useTurnTimer: false,
    );
    c.startLocal();
    c.doBid(const Bid(11, 6)); // solo hay 10 dados en la mesa
    expect(c.errorMessage, isNotNull);
    expect(c.currentPlayerId, 'yo');
    c.dispose();
  });
}
