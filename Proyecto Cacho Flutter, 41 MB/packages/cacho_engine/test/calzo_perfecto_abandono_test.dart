import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

GameEngine engine(GameConfig config, List<int> script,
    [List<String> ids = const ['A', 'B']]) {
  return GameEngine(
    config: config,
    roller: ScriptedDiceRoller(script),
    playerList: [for (final id in ids) (id: id, name: id)],
  );
}

void main() {
  group('calzo perfecto (con los 5 dados)', () {
    test('exacto con 5 dados: todos los demás pierden un dado', () {
      final g = engine(GameConfig.clasico(), [
        6, 1, 1, // desempate: parte A
        6, 6, 6, 2, 3, // A: tres 6
        2, 2, 3, 4, 5, // B
        2, 3, 4, 5, 6, // C: un 6 → total de 6 en la mesa: 4
        // ronda 2: A y B con 4, C con 5
        2, 2, 2, 2,
        3, 3, 3, 3,
        4, 4, 4, 4, 4,
      ], ['A', 'B', 'C']);
      g.startGame();
      g.bid('A', const Bid(3, 6));
      g.bid('B', const Bid(4, 6));
      final res = g.calzo('C');
      expect(res.actualCount, 4);
      expect(res.loserId, isNull);
      expect(res.gainerId, isNull);
      expect(res.massLoserIds, ['A', 'B']);
      expect(g.playerById('A').diceCount, 4);
      expect(g.playerById('B').diceCount, 4);
      expect(g.playerById('C').diceCount, 5);
      expect(g.phase, GamePhase.playing);
      expect(g.roundNumber, 2);
      expect(g.currentPlayerId, 'C'); // parte quien calzó
    });

    test('exacto con 5 dados puede eliminar y cerrar la partida', () {
      final g = engine(GameConfig.clasico(), [
        1, 6, // desempate: parte B
        2, 2, 2, 2, 2, 3, 3, 3, 3, 3, // R1: B apuesta falso y pierde → 4
        2, 2, 2, 2, 2, 3, 3, 3, 3, // R2: B → 3
        2, 2, 2, 2, 2, 3, 3, 3, // R3: B → 2
        2, 2, 2, 2, 2, 3, 3, // R4: B → 1
        6, 6, 6, 2, 2, 3, // R5: B apuesta 1 Tren (hay 1) y A calza exacto
      ]);
      g.startGame();
      for (var r = 0; r < 4; r++) {
        g.bid('B', const Bid(5, 6)); // no hay ningún 6 ni ningún 1
        final res = g.dudo('A');
        expect(res.loserId, 'B');
      }
      expect(g.playerById('B').diceCount, 1);
      g.bid('B', const Bid(1, 3));
      final res = g.calzo('A');
      expect(res.actualCount, 1);
      expect(res.massLoserIds, ['B']);
      expect(g.playerById('B').diceCount, 0);
      expect(g.phase, GamePhase.finished);
      expect(g.winnerId, 'A');
    });

    test('exacto con menos de 5 dados: recupera como siempre', () {
      final g = engine(GameConfig.clasico(), [
        6, 1, // parte A
        2, 2, 2, 2, 2, 6, 3, 3, 3, 3, // R1: A apuesta falso y pierde → 4
        6, 2, 2, 2, 3, 3, 3, 3, 3, // R2: A(4) y B(5)
        2, 2, 2, 2, 2, 3, 3, 3, 3, 3, // R3
      ]);
      g.startGame();
      g.bid('A', const Bid(5, 6)); // solo hay un 6 (de B)
      final r1 = g.dudo('B');
      expect(r1.loserId, 'A');
      expect(g.playerById('A').diceCount, 4);
      g.bid('A', const Bid(1, 6)); // hay un 6
      g.bid('B', const Bid(3, 2)); // hay tres 2 (de A)
      final res = g.calzo('A');
      expect(res.actualCount, 3);
      expect(res.gainerId, 'A');
      expect(res.massLoserIds, isEmpty);
      expect(g.playerById('A').diceCount, 5);
    });

    test('fallido con 5 dados: pierde solo quien calzó', () {
      final g = engine(GameConfig.clasico(), [
        6, 1, 1,
        6, 6, 6, 2, 3,
        2, 2, 3, 4, 5,
        2, 3, 4, 5, 6, // total de 6: 4
        // ronda 2
        2, 2, 2, 2, 2,
        3, 3, 3, 3, 3,
        4, 4, 4, 4,
      ], ['A', 'B', 'C']);
      g.startGame();
      g.bid('A', const Bid(3, 6));
      g.bid('B', const Bid(5, 6));
      final res = g.calzo('C'); // hay 4, no 5
      expect(res.actualCount, 4);
      expect(res.loserId, 'C');
      expect(res.massLoserIds, isEmpty);
      expect(g.playerById('C').diceCount, 4);
      expect(g.playerById('A').diceCount, 5);
      expect(g.playerById('B').diceCount, 5);
    });
  });

  group('abandono (forceEliminate)', () {
    test('a mitad de ronda: se corta y parte el siguiente vivo', () {
      final g = engine(GameConfig.clasico(), [
        6, 1, 1,
        2, 2, 2, 2, 2, // A
        3, 3, 3, 3, 3, // B
        4, 4, 4, 4, 4, // C
        // ronda 2: solo A y C
        2, 2, 2, 2, 2,
        4, 4, 4, 4, 4,
      ], ['A', 'B', 'C']);
      g.startGame();
      g.bid('A', const Bid(1, 2));
      g.bid('B', const Bid(2, 3));
      final res = g.forceEliminate('B');
      expect(res.type, ResolutionType.abandono);
      expect(res.loserId, 'B');
      expect(res.revealedHands['B'], [3, 3, 3, 3, 3]);
      expect(g.playerById('B').diceCount, 0);
      expect(g.playerById('B').alive, isFalse);
      expect(g.phase, GamePhase.playing);
      expect(g.roundNumber, 2);
      expect(g.currentBid, isNull);
      expect(g.currentPlayerId, 'C'); // el siguiente vivo tras B
      expect(g.totalDiceInPlay, 10);
    });

    test('si queda un solo jugador, ese gana la partida', () {
      final g = engine(GameConfig.clasico(), [
        6, 1,
        2, 2, 2, 2, 2,
        3, 3, 3, 3, 3,
      ]);
      g.startGame();
      g.bid('A', const Bid(1, 2));
      final res = g.forceEliminate('B');
      expect(res.type, ResolutionType.abandono);
      expect(g.phase, GamePhase.finished);
      expect(g.winnerId, 'A');
    });

    test('durante la oferta de Kamikaze: parte el designado si no es él',
        () {
      final g = engine(GameConfig.cachoCompleto(), [
        1, 6, 1, // desempate: parte B
        2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, // R1: B → 4
        2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, // R2: B → 3
        2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, // R3: B → 2
        2, 2, 2, 2, 2, 3, 3, 4, 4, 4, 4, 4, // R4: B → 1, oferta para B
        2, 2, 2, 2, 2, 4, 4, 4, 4, 4, // R5: solo A y C
      ], ['A', 'B', 'C']);
      g.startGame();
      for (var r = 0; r < 4; r++) {
        g.bid('B', const Bid(5, 6)); // falso: no hay 6 ni 1
        final res = g.dudo('C');
        expect(res.loserId, 'B');
      }
      expect(g.phase, GamePhase.kamikazeOffer);
      expect(g.kamikazeOfferPlayerId, 'B');
      final res = g.forceEliminate('B');
      expect(res.type, ResolutionType.abandono);
      expect(g.phase, GamePhase.playing);
      expect(g.roundNumber, 5);
      // El designado era el propio B: parte el siguiente vivo (C).
      expect(g.currentPlayerId, 'C');
      expect(g.playerById('B').alive, isFalse);
    });
  });
}
