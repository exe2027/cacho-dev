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

Matcher illegal(String code) => throwsA(isA<IllegalMove>()
    .having((e) => e.code, 'code', code));

void main() {
  group('dudo', () {
    test('apuesta cierta: pierde quien dudó; parte el perdedor', () {
      final g = engine(GameConfig.clasico(), [
        6, 1, // desempate inicial: A parte
        6, 6, 6, 1, 2, // A
        6, 5, 4, 3, 2, // B
        // ronda 2
        2, 2, 2, 2, 2, // A (5)
        3, 3, 3, 3, // B (4)
      ]);
      expect(g.startGame(), 'A');
      g.bid('A', const Bid(4, 6)); // hay 5 seises (3 + comodín + 1 de B)
      final res = g.dudo('B');
      expect(res.actualCount, 5);
      expect(res.loserId, 'B');
      expect(g.playerById('B').diceCount, 4);
      expect(g.phase, GamePhase.playing);
      expect(g.currentPlayerId, 'B'); // parte quien perdió
      expect(g.roundNumber, 2);
    });

    test('apuesta falsa: pierde quien apostó', () {
      final g = engine(GameConfig.clasico(), [
        6, 1,
        2, 2, 2, 2, 2, // A
        3, 3, 3, 3, 3, // B
        2, 2, 2, 2, // ronda 2: A (4)
        3, 3, 3, 3, 3, // B (5)
      ]);
      g.startGame();
      g.bid('A', const Bid(3, 6)); // no hay ningún 6 ni ningún 1
      final res = g.dudo('B');
      expect(res.actualCount, 0);
      expect(res.loserId, 'A');
      expect(g.playerById('A').diceCount, 4);
    });

    test('sin comodines: los 1 no salvan la apuesta', () {
      final g = engine(
          GameConfig.clasico().copyWith(wildcardsEnabled: false), [
        6, 1,
        1, 1, 1, 1, 1, // A: puros ases
        6, 2, 2, 2, 2, // B: un solo 6 real
        2, 2, 2, 2, // ronda 2: A (4)
        3, 3, 3, 3, 3,
      ]);
      g.startGame();
      g.bid('A', const Bid(5, 6));
      final res = g.dudo('B');
      expect(res.actualCount, 1); // con comodines serían 6
      expect(res.loserId, 'A');
    });

    test('apuesta de ases: solo cuentan los 1 reales', () {
      final g = engine(GameConfig.clasico(), [
        6, 1,
        1, 1, 2, 2, 2, // A
        1, 3, 3, 3, 3, // B
        2, 2, 2, 2, 2, // ronda 2: A (5)
        3, 3, 3, 3, // B (4)
      ]);
      g.startGame();
      // No se puede partir con ases: A abre normal y B entra a ases.
      g.bid('A', const Bid(2, 2));
      g.bid('B', const Bid(4, 1)); // dice 4 ases: hay exactamente 3
      final res = g.dudo('A');
      expect(res.actualCount, 3);
      expect(res.loserId, 'B'); // la apuesta era falsa
    });

    test('regla de ases desactivada: los 1 no son comodines aunque la opción de comodines esté activa', () {
      final g = engine(
          GameConfig.clasico().copyWith(acesRuleEnabled: false), [
        6, 1,
        1, 1, 1, 1, 1, // A: puros ases (ya no valen como comodín)
        6, 2, 2, 2, 2, // B: un solo 6 real
        2, 2, 2, 2, // ronda 2: A (4)
        3, 3, 3, 3, 3,
      ]);
      g.startGame();
      g.bid('A', const Bid(5, 6));
      final res = g.dudo('B');
      expect(res.actualCount, 1);
      expect(res.loserId, 'A');
    });

    test('no es tu turno / sin apuesta', () {
      final g = engine(GameConfig.clasico(), [
        6, 1,
        2, 2, 2, 2, 2,
        3, 3, 3, 3, 3,
      ]);
      g.startGame();
      expect(() => g.bid('B', const Bid(1, 2)), illegal('no_es_tu_turno'));
      expect(() => g.dudo('A'), illegal('sin_apuesta'));
    });
  });

  group('calzo', () {
    test('calzo exacto recupera un dado y parte quien calzó', () {
      final g = engine(GameConfig.clasico(), [
        6, 1, 1, // desempate: A
        // ronda 1: C pierde un dado dudando una apuesta cierta
        6, 2, 2, 2, 2, // A
        6, 3, 3, 3, 3, // B
        2, 2, 2, 2, 2, // C
        // ronda 2 (parte C): hay exactamente tres 6 en la mesa
        6, 6, 2, 2, 2, // A
        6, 3, 3, 3, 3, // B
        2, 2, 2, 2, // C (4)
        // ronda 3
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      ], ['A', 'B', 'C']);
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.bid('B', const Bid(2, 6)); // hay 2: cierta
      g.dudo('C');
      expect(g.playerById('C').diceCount, 4);
      // ronda 2
      expect(g.currentPlayerId, 'C');
      g.bid('C', const Bid(1, 6));
      g.bid('A', const Bid(2, 6));
      g.bid('B', const Bid(3, 6));
      final res = g.calzo('C'); // exactamente 3
      expect(res.actualCount, 3);
      expect(res.gainerId, 'C');
      expect(res.loserId, isNull);
      expect(g.playerById('C').diceCount, 5); // recuperó
      expect(g.currentPlayerId, 'C'); // parte quien calzó
    });

    test('calzo con 5 dados: perfecto, el otro pierde un dado, parte quien calzó', () {
      final g = engine(GameConfig.clasico(), [
        6, 1,
        6, 2, 2, 2, 2, // A: un 6
        3, 3, 3, 3, 3, // B
        2, 2, 2, 2, // ronda 2: A con 4
        3, 3, 3, 3, 3,
      ]);
      g.startGame();
      g.bid('A', const Bid(1, 6)); // hay exactamente 1
      final res = g.calzo('B');
      // Regla del usuario (22-oct): calzo exacto con los 5 dados →
      // todos los demás pierden un dado (él no gana: ya está al tope).
      expect(res.gainerId, isNull);
      expect(res.massLoserIds, ['A']);
      expect(g.playerById('B').diceCount, 5); // tope
      expect(g.playerById('A').diceCount, 4);
      expect(g.currentPlayerId, 'B');
    });

    test('sin umbral (24-oct): con menos de la mitad de los dados originales SÍ se puede calzar', () {
      // Antes el Calzo se bloqueaba bajo la mitad de los dados
      // originales (con 4 jugadores, bajo 10) y el final de partida
      // quedaba sin Calzo; el usuario lo eliminó tras probarlo.
      // Guion: todas las manos son 2s (la apuesta 1 Sexta siempre es
      // falsa y pierde quien apuesta): 20 -> 9 dados en 11 rondas.
      final script = <int>[6, 1, 1, 1]; // desempate: parte A
      for (var total = 20; total >= 9; total--) {
        script.addAll(List.filled(total, 2));
      }
      // Cola: la ronda que parte tras el calzo (el calzo ahora sí
      // resuelve y la partida sigue).
      script.addAll(List.filled(60, 2));
      final g = engine(GameConfig.clasico(), script, ['A', 'B', 'C', 'D']);
      g.startGame();
      while (g.totalDiceInPlay > 9) {
        final starter = g.currentPlayerId!;
        g.bid(starter, const Bid(1, 6));
        g.dudo(g.currentPlayerId!);
      }
      expect(g.totalDiceInPlay, 9);
      expect(g.canCalzoNow, isTrue);
      final starter = g.currentPlayerId!;
      g.bid(starter, const Bid(1, 6));
      final calzer = g.currentPlayerId!;
      // Hay cero Sextas en la mesa: el calzo no es exacto y pierde
      // quien calzó — pero la jugada ES legal (no lanza error).
      final res = g.calzo(calzer);
      expect(res.type, ResolutionType.calzo);
      expect(res.loserId, calzer);
    });
  });
}
