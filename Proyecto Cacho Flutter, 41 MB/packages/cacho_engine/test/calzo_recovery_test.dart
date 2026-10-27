import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

/// Regla de recuperación del Calzo (usuario, 25-oct): el Calzo exacto
/// solo recupera un dado si los dados totales en juego son
/// ESTRICTAMENTE MÁS de la mitad del total inicial:
/// totalActual * 2 > totalInicial. Ejemplo del usuario: 4 jugadores
/// (20 iniciales), con 11+ se recupera, con 10 o menos no.
/// El intento sigue siempre permitido (24-oct): aquí se prueba la
/// GANANCIA, no el bloqueo del intento.

GameEngine game(List<String> ids, GameConfig config) {
  final script = <int>[
    // Desempate sin empates: A parte.
    6, 1, 2, 3,
    // Ronda 1 (se sobrescribe en cada test) + cola para la ronda 2.
    ...List.filled(20, 2),
    ...List.filled(80, 2),
  ];
  final g = GameEngine(
    config: config,
    roller: ScriptedDiceRoller(script),
    playerList: [for (final id in ids) (id: id, name: id)],
  );
  g.startGame();
  return g;
}

void setCalzoScenario(
  GameEngine g, {
  required Map<String, List<int>> hands,
  required Map<String, int> counts,
  required Bid bid,
  required String calzer,
}) {
  for (final e in hands.entries) {
    g.playerById(e.key).hand = List.of(e.value);
  }
  for (final e in counts.entries) {
    g.playerById(e.key).diceCount = e.value;
  }
  g.currentBid = bid;
  g.currentPlayerId = calzer;
}

void main() {
  group('recuperación del Calzo (25-oct): total estricto sobre la mitad', () {
    test('20 iniciales, 11 en mesa: exacto recupera', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2],
            'B': [6, 3, 3],
            'C': [4, 4, 4],
            'D': [5, 5],
          },
          counts: {'A': 3, 'B': 3, 'C': 3, 'D': 2},
          bid: const Bid(3, 6),
          calzer: 'B');
      expect(g.initialTotalDice, 20);
      expect(g.totalDiceInPlay, 11);
      expect(g.calzoRecoveryAllowed, isTrue);
      final res = g.calzo('B');
      expect(res.actualCount, 3);
      expect(res.gainerId, 'B');
      expect(res.loserId, isNull);
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('B').diceCount, 4);
      expect(g.currentPlayerId, 'B'); // parte quien calzó
    });

    test('20 iniciales, 10 en mesa: exacto NO recupera ni pierde', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2],
            'B': [6, 3],
            'C': [4, 4, 4],
            'D': [5, 5],
          },
          counts: {'A': 3, 'B': 2, 'C': 3, 'D': 2},
          bid: const Bid(3, 6),
          calzer: 'B');
      expect(g.totalDiceInPlay, 10);
      expect(g.calzoRecoveryAllowed, isFalse);
      final res = g.calzo('B');
      expect(res.actualCount, 3);
      expect(res.gainerId, isNull);
      expect(res.loserId, isNull);
      expect(res.recoveryBlocked, isTrue);
      expect(g.playerById('B').diceCount, 2);
      expect(g.currentPlayerId, 'B'); // parte quien calzó igual
    });

    test('20 iniciales, 10 en mesa, calzo fallido: pierde siempre', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2],
            'B': [6, 3],
            'C': [4, 4, 4],
            'D': [5, 5],
          },
          counts: {'A': 3, 'B': 2, 'C': 3, 'D': 2},
          bid: const Bid(4, 6), // hay 3: no es exacto
          calzer: 'B');
      final res = g.calzo('B');
      expect(res.actualCount, 3);
      expect(res.loserId, 'B');
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('B').diceCount, 1);
    });

    test('intento permitido con total bajo: sin error de bloqueo', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2],
            'B': [6, 3],
            'C': [4, 4],
            'D': [5, 5],
          },
          counts: {'A': 3, 'B': 2, 'C': 2, 'D': 2},
          bid: const Bid(4, 6),
          calzer: 'B');
      expect(g.totalDiceInPlay, 9);
      expect(g.canCalzoNow, isTrue);
      final res = g.calzo('B'); // legal: resuelve, no lanza
      expect(res.type, ResolutionType.calzo);
      expect(res.loserId, 'B');
    });

    test('15 iniciales, 8 en mesa: exacto recupera', () {
      final g = game(['A', 'B', 'C'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2],
            'B': [6, 3, 3],
            'C': [4, 4],
          },
          counts: {'A': 3, 'B': 3, 'C': 2},
          bid: const Bid(3, 6),
          calzer: 'B');
      expect(g.initialTotalDice, 15);
      expect(g.totalDiceInPlay, 8);
      expect(g.calzoRecoveryAllowed, isTrue);
      final res = g.calzo('B');
      expect(res.gainerId, 'B');
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('B').diceCount, 4);
    });

    test('15 iniciales, 7 en mesa: exacto NO recupera ni pierde', () {
      final g = game(['A', 'B', 'C'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2],
            'B': [6, 3],
            'C': [4, 4],
          },
          counts: {'A': 3, 'B': 2, 'C': 2},
          bid: const Bid(3, 6),
          calzer: 'B');
      expect(g.totalDiceInPlay, 7);
      expect(g.calzoRecoveryAllowed, isFalse);
      final res = g.calzo('B');
      expect(res.gainerId, isNull);
      expect(res.loserId, isNull);
      expect(res.recoveryBlocked, isTrue);
      expect(g.playerById('B').diceCount, 2);
    });
  });

  group('recuperación del CalzoPaso (misma regla)', () {
    test('20 iniciales, 10 en mesa, Paso verdadero: no gana ni pierde', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.cachoCompleto());
      for (final e in {
        'A': [1, 2, 3, 4, 5],
        'B': [2, 2],
        'C': [3, 3],
        'D': [4],
      }.entries) {
        g.playerById(e.key).hand = List.of(e.value);
      }
      for (final e in {'A': 5, 'B': 2, 'C': 2, 'D': 1}.entries) {
        g.playerById(e.key).diceCount = e.value;
      }
      g.pendingPasoPlayerId = 'A';
      g.currentPlayerId = 'B';
      expect(g.totalDiceInPlay, 10);
      final res = g.calzoPaso('B');
      expect(res.gainerId, isNull);
      expect(res.loserId, isNull);
      expect(res.recoveryBlocked, isTrue);
      expect(g.playerById('B').diceCount, 2);
    });

    test('20 iniciales, 10 en mesa, Paso falso: pierde quien calzó', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.cachoCompleto());
      for (final e in {
        'A': [2, 2, 2, 2, 3],
        'B': [2, 2],
        'C': [3, 3],
        'D': [4],
      }.entries) {
        g.playerById(e.key).hand = List.of(e.value);
      }
      for (final e in {'A': 5, 'B': 2, 'C': 2, 'D': 1}.entries) {
        g.playerById(e.key).diceCount = e.value;
      }
      g.pendingPasoPlayerId = 'A';
      g.currentPlayerId = 'B';
      final res = g.calzoPaso('B');
      expect(res.loserId, 'B');
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('B').diceCount, 1);
    });

    test('20 iniciales, 14 en mesa, Paso verdadero: recupera', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.cachoCompleto());
      for (final e in {
        'A': [1, 2, 3, 4, 5],
        'B': [2, 2, 2],
        'C': [3, 3, 3],
        'D': [4, 4, 4],
      }.entries) {
        g.playerById(e.key).hand = List.of(e.value);
      }
      for (final e in {'A': 5, 'B': 3, 'C': 3, 'D': 3}.entries) {
        g.playerById(e.key).diceCount = e.value;
      }
      g.pendingPasoPlayerId = 'A';
      g.currentPlayerId = 'B';
      expect(g.totalDiceInPlay, 14);
      final res = g.calzoPaso('B');
      expect(res.gainerId, 'B');
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('B').diceCount, 4);
    });
  });

  group('C11 (26-oct): Calzo perfecto bloqueado con total bajo', () {
    test('(a) exacto + 5 dados + 17 de 20: los demás pierden un dado, el calzador no gana', () {
      final g = game(['A', 'B', 'C', 'D'], GameConfig.clasico());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2, 2, 2],
            'B': [6, 3, 3, 3],
            'C': [4, 4, 4, 4],
            'D': [5, 5, 5, 5],
          },
          counts: {'A': 5, 'B': 4, 'C': 4, 'D': 4},
          bid: const Bid(3, 6),
          calzer: 'A');
      expect(g.totalDiceInPlay, 17);
      expect(g.calzoRecoveryAllowed, isTrue);
      final res = g.calzo('A');
      expect(res.actualCount, 3);
      expect(res.massLoserIds, ['B', 'C', 'D']);
      expect(res.gainerId, isNull);
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('A').diceCount, 5);
      expect(g.playerById('B').diceCount, 3);
      expect(g.playerById('C').diceCount, 3);
      expect(g.playerById('D').diceCount, 3);
      expect(g.currentPlayerId, 'A'); // parte quien calzó
    });

    test('(b) exacto + 5 dados + 10 de 20: nadie gana ni pierde, recoveryBlocked, el calzador parte', () {
      // C11 reemplaza la postura anterior (25-oct) que mantenía el
      // perfecto con total bajo: ahora queda bloqueado, igual que el
      // exacto sin recuperación (C4). Preset completo (no Clásico)
      // para que la oferta de Kamikaze a D esté activa en el cierre.
      final g = game(['A', 'B', 'C', 'D'], GameConfig.cachoCompleto());
      setCalzoScenario(g,
          hands: {
            'A': [6, 6, 2, 2, 2],
            'B': [6, 3],
            'C': [4, 4],
            'D': [5],
          },
          counts: {'A': 5, 'B': 2, 'C': 2, 'D': 1},
          bid: const Bid(3, 6),
          calzer: 'A');
      expect(g.totalDiceInPlay, 10);
      expect(g.calzoRecoveryAllowed, isFalse);
      final res = g.calzo('A');
      expect(res.actualCount, 3);
      expect(res.massLoserIds, isEmpty);
      expect(res.gainerId, isNull);
      expect(res.loserId, isNull);
      expect(res.recoveryBlocked, isTrue);
      expect(g.playerById('A').diceCount, 5);
      expect(g.playerById('B').diceCount, 2);
      expect(g.playerById('C').diceCount, 2);
      expect(g.playerById('D').diceCount, 1);
      // D queda con 1 dado: se le ofrece el Kamikaze y, al rechazarlo,
      // la ronda siguiente la parte el calzador.
      expect(g.phase, GamePhase.kamikazeOffer);
      expect(g.kamikazeOfferPlayerId, 'D');
      g.respondKamikaze('D', accept: false);
      expect(g.phase, GamePhase.playing);
      expect(g.currentPlayerId, 'A');
    });
  });
}
