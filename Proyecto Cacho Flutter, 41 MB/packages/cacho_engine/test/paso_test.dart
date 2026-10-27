import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

GameEngine engine(List<int> script, {GameConfig? config}) {
  return GameEngine(
    config: config ?? GameConfig.cachoCompleto(),
    roller: ScriptedDiceRoller(script),
    playerList: const [
      (id: 'A', name: 'A'),
      (id: 'B', name: 'B'),
      (id: 'C', name: 'C'),
    ],
  );
}

Matcher illegal(String code) =>
    throwsA(isA<IllegalMove>().having((e) => e.code, 'code', code));

void main() {
  group('paso', () {
    test('bloqueado como primera jugada de la ronda', () {
      final g = engine([
        6, 1, 1,
        6, 6, 6, 6, 6, 1, 2, 3, 4, 5, 2, 3, 4, 5, 6,
      ]);
      g.startGame();
      expect(() => g.paso('A'), illegal('paso_primera_jugada'));
    });

    test('paso verdadero dudado: pierde quien dudó y solo se revela su mano', () {
      final g = engine([
        6, 1, 1, // parte A
        6, 6, 6, 6, 6, // A
        2, 2, 3, 3, 3, // B: full -> Paso verdadero
        2, 3, 4, 5, 6, // C
        // ronda 2 (parte C, que pierde)
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, // A5 B5 C4 de puros 2
      ]);
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.paso('B');
      expect(g.pendingPasoPlayerId, 'B');
      expect(g.currentBid, const Bid(1, 6)); // el Paso NO cambia la apuesta
      final res = g.dudoPaso('C');
      expect(res.revealedHands.keys, ['B']); // SOLO la mano de quien pasó
      expect(res.loserId, 'C'); // el Paso era verdadero
      expect(g.playerById('C').diceCount, 4);
      expect(g.currentPlayerId, 'C'); // parte el perdedor
    });

    test('paso falso calzado: pierde quien calzó', () {
      final g = engine([
        6, 1, 1,
        6, 6, 6, 6, 6, // A
        2, 2, 3, 3, 4, // B: NO es Paso (2,2,1)
        2, 3, 4, 5, 6, // C
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, // ronda 2
      ]);
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.paso('B'); // farol: se puede declarar igual
      final res = g.calzoPaso('C'); // C afirma que es verdadero: falso
      expect(res.loserId, 'C');
      expect(res.gainerId, isNull);
      expect(g.playerById('B').diceCount, 5); // quien pasó no pierde nada
    });

    test('calzar un paso verdadero devuelve al jugador a 5 dados y puede volver a pasar', () {
      final g = engine([
        6, 1, 1, // parte A
        // ronda 1: C duda una apuesta cierta y baja a 4
        6, 2, 2, 2, 2, // A
        6, 3, 3, 3, 3, // B
        2, 2, 2, 2, 2, // C
        // ronda 2 (parte C): B tiene Paso verdadero (cinco distintos)
        2, 2, 2, 2, 2, // A
        1, 2, 3, 4, 5, // B
        2, 2, 2, 2, // C (4)
        // ronda 3
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      ]);
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.bid('B', const Bid(2, 6));
      g.dudo('C'); // había 2: pierde C
      expect(g.playerById('C').diceCount, 4);
      // ronda 2
      g.bid('C', const Bid(1, 6));
      g.bid('A', const Bid(2, 6));
      g.paso('B');
      final res = g.calzoPaso('C'); // verdadero: C recupera
      expect(res.gainerId, 'C');
      expect(g.playerById('C').diceCount, 5);
      // ronda 3: de vuelta con 5, C puede volver a pasar (no como primera jugada)
      expect(g.currentPlayerId, 'C');
      g.bid('C', const Bid(1, 6));
      g.bid('A', const Bid(2, 6));
      g.bid('B', const Bid(3, 6));
      g.paso('C'); // no debe lanzar
      expect(g.pendingPasoPlayerId, 'C');
      // si el siguiente sigue jugando, el Paso queda firme y ya no se puede dudar
      g.bid('A', const Bid(4, 6));
      expect(g.pendingPasoPlayerId, isNull);
      expect(() => g.dudoPaso('B'), illegal('sin_paso_pendiente'));
    });

    test('con menos de 5 dados el Paso está bloqueado', () {
      final g = engine([
        6, 1, 1,
        // ronda 1: B duda una apuesta cierta (hay muchos 2) y baja a 4
        2, 2, 2, 2, 2, // A
        3, 3, 3, 3, 3, // B
        2, 2, 2, 2, 2, // C
        // ronda 2 (parte B)
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, // A5 B4 C5
      ]);
      g.startGame();
      g.bid('A', const Bid(1, 2)); // hay 10 patos: cierta
      g.dudo('B');
      expect(g.playerById('B').diceCount, 4);
      expect(g.currentPlayerId, 'B');
      expect(() => g.paso('B'), illegal('paso_requiere_5_dados'));
    });

    test('límite de pasos por ronda y no dos veces seguidas', () {
      GameEngine build(GameConfig config) {
        final g = GameEngine(
          config: config,
          roller: ScriptedDiceRoller([
            6, 1, 1, 1, // parte A
            ...List.filled(20, 2), // ronda 1: 4 jugadores x 5
          ]),
          playerList: const [
            (id: 'A', name: 'A'),
            (id: 'B', name: 'B'),
            (id: 'C', name: 'C'),
            (id: 'D', name: 'D'),
          ],
        );
        g.startGame();
        g.bid('A', const Bid(1, 6));
        g.paso('B');
        g.bid('C', const Bid(2, 6));
        g.bid('D', const Bid(3, 6));
        g.bid('A', const Bid(4, 6));
        return g; // turno de B por segunda vez en la ronda
      }

      // Máximo 1 por ronda (default)
      final g1 = build(GameConfig.cachoCompleto());
      expect(() => g1.paso('B'), illegal('paso_limite_ronda'));

      // Con límite 3, manda la regla de no repetir
      final g2 = build(
          GameConfig.cachoCompleto().copyWith(maxPasosPerPlayerPerRound: 3));
      expect(() => g2.paso('B'), illegal('paso_dos_veces_seguidas'));
    });

    test('en el preset Clásico el Paso no existe', () {
      final g = engine([
        6, 1, 1,
        6, 6, 6, 6, 6, 1, 2, 3, 4, 5, 2, 3, 4, 5, 6,
      ], config: GameConfig.clasico());
      g.startGame();
      g.bid('A', const Bid(1, 6));
      expect(() => g.paso('B'), illegal('paso_deshabilitado'));
    });
  });
}
