import 'dart:math';

import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

BotContext ctx({
  List<int> ownHand = const [2, 2, 2, 2, 2],
  Bid? currentBid,
  int totalDice = 10,
  Map<String, int> diceCounts = const {'bot': 5, 'x': 5},
  String? pendingPaso,
  bool canCalzo = true,
  bool canPaso = false,
  GameConfig? config,
}) {
  return BotContext(
    selfId: 'bot',
    ownHand: ownHand,
    currentBid: currentBid,
    totalDiceInPlay: totalDice,
    diceCounts: diceCounts,
    pendingPasoPlayerId: pendingPaso,
    canCalzo: canCalzo,
    canPaso: canPaso,
    config: config ?? GameConfig.cachoCompleto(),
  );
}

void main() {
  group('probabilidad binomial', () {
    test('casos borde', () {
      expect(probabilityAtLeast(10, 0, 1 / 3), 1.0);
      expect(probabilityAtLeast(5, 6, 1 / 3), 0.0);
      expect(probabilityExactly(5, 6, 1 / 3), 0.0);
    });

    test('valores conocidos', () {
      expect(probabilityAtLeast(2, 1, 0.5), closeTo(0.75, 1e-9));
      expect(probabilityExactly(2, 1, 0.5), closeTo(0.5, 1e-9));
      var sum = 0.0;
      for (var k = 0; k <= 6; k++) {
        sum += binomialPmf(6, k, 1 / 3);
      }
      expect(sum, closeTo(1.0, 1e-9));
    });
  });

  group('decisiones del bot (dificultad media)', () {
    final bot = BotBrain(BotDifficulty.media, Random(42));

    test('duda una apuesta imposible', () {
      // Apuesta: 9 Sextas. El bot no tiene ninguna y solo quedan 5 dados
      // ajenos: ni con todos los dados a favor llega a 9.
      final a = bot.decide(ctx(currentBid: const Bid(9, 6)));
      expect(a.type, BotActionType.dudo);
    });

    test('calza cuando la exacta es muy creíble', () {
      // Bot tiene cuatro 6; apuesta: cuatro 6; quedan 2 dados ajenos y la
      // probabilidad de que ninguno sea 6 ni 1 es (2/3)^2 = 0.44.
      final a = bot.decide(ctx(
        ownHand: const [6, 6, 6, 6],
        currentBid: const Bid(4, 6),
        totalDice: 6,
        diceCounts: const {'bot': 4, 'x': 2},
      ));
      expect(a.type, BotActionType.calzo);
    });

    test('su apuesta de apertura siempre es legal', () {
      final a = bot.decide(ctx(currentBid: null));
      expect(a.type, BotActionType.bid);
      expect(GameEngine.raiseError(null, a.bid!, 10), isNull);
    });

    test('usa el Paso si su mano lo es y la apuesta vigente es débil', () {
      final a = bot.decide(ctx(
        ownHand: const [1, 2, 3, 4, 6], // cinco distintos
        currentBid: const Bid(8, 6),
        totalDice: 15,
        canCalzo: false,
        canPaso: true,
      ));
      expect(a.type, BotActionType.paso);
    });

    test('ante un Paso pendiente, lo duda', () {
      final a = bot.decide(ctx(
        currentBid: const Bid(2, 6),
        pendingPaso: 'x',
      ));
      expect(a.type, BotActionType.dudoPaso);
    });

    test('kamikaze: acepta si los rivales tienen 3+ dados que perder', () {
      expect(
          bot.shouldAcceptKamikaze(ctx(
            totalDice: 6,
            diceCounts: const {'bot': 1, 'x': 3, 'y': 2},
          )),
          isTrue);
      expect(
          bot.shouldAcceptKamikaze(ctx(
            totalDice: 3,
            diceCounts: const {'bot': 1, 'x': 1, 'y': 1},
          )),
          isFalse);
    });
  });
}
