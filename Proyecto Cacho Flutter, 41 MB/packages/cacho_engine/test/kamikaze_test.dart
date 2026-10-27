import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

GameConfig completoDp(int dice) =>
    GameConfig.cachoCompleto().copyWith(dicePerPlayer: dice);

/// Motor 1v1 (2 dados) ya en fase de oferta Kamikaze para A:
/// A apostó 1 Sexta sin ningún 6 en la mesa, B dudó y A bajó a 1 dado.
GameEngine offerForA(List<int> extraScript) {
  final g = GameEngine(
    config: completoDp(2),
    roller: ScriptedDiceRoller([
      6, 1, // desempate: parte A
      2, 2, // A ronda 1
      2, 2, // B ronda 1
      ...extraScript,
    ]),
    playerList: const [(id: 'A', name: 'A'), (id: 'B', name: 'B')],
  );
  g.startGame();
  g.bid('A', const Bid(1, 6));
  g.dudo('B'); // falsa: pierde A -> queda con 1, único -> oferta
  return g;
}

void main() {
  group('kamikaze', () {
    test('se ofrece solo al único jugador con 1 dado; rechazar consume la oportunidad', () {
      final g = offerForA([
        2, // ronda 2: A (1 dado)
        2, 2, // B (2)
      ]);
      expect(g.phase, GamePhase.kamikazeOffer);
      expect(g.kamikazeOfferPlayerId, 'A');
      g.respondKamikaze('A', accept: false);
      expect(g.playerById('A').kamikazeOfferedOnce, isTrue);
      expect(g.phase, GamePhase.playing);
      // A vuelve a perder y queda eliminado: nunca hubo segunda oferta.
      g.bid('A', const Bid(1, 6));
      g.dudo('B');
      expect(g.phase, GamePhase.finished);
      expect(g.winnerId, 'B');
    });

    test('el activador puede morir por su propio número', () {
      final g = offerForA([
        6, // Kamikaze: A lanza su único dado y sale el número elegido
        6, 3, // B pierde uno y sobrevive con 1
      ]);
      g.respondKamikaze('A', accept: true);
      expect(g.phase, GamePhase.kamikazeChoice);
      final res = g.chooseKamikazeFace('A', 6);
      expect(res.kamikazeLosses, {'A': 1, 'B': 1});
      expect(g.playerById('A').eliminated, isTrue);
      expect(g.phase, GamePhase.finished);
      expect(g.winnerId, 'B');
    });

    test('si todos quedan sin dados a la vez: empate sin ganador', () {
      final g = offerForA([
        6, // A pierde su dado
        6, 6, // B pierde los dos
      ]);
      g.respondKamikaze('A', accept: true);
      g.chooseKamikazeFace('A', 6);
      expect(g.phase, GamePhase.finished);
      expect(g.isDraw, isTrue);
      expect(g.winnerId, isNull);
    });

    test('un Calzo fallido que deja a un jugador en 1 dado gatilla la oferta', () {
      final g = GameEngine(
        config: completoDp(3),
        roller: ScriptedDiceRoller([
          6, 1, 1, // parte A
          2, 2, 2, 2, 2, 2, 2, 2, 2, // ronda 1 (3 c/u)
          2, 2, 2, 2, 2, 2, 2, 2, // ronda 2 (A2 B3 C3)
          2, 2, 2, 2, 2, 2, 2, // ronda 3 (A2 B2 C3)
          2, 2, 2, 2, 2, 2, // ronda 4 (2 c/u)
        ]),
        playerList: const [
          (id: 'A', name: 'A'),
          (id: 'B', name: 'B'),
          (id: 'C', name: 'C'),
        ],
      );
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.dudo('B'); // falsa: A baja a 2
      g.bid('A', const Bid(1, 6));
      g.calzo('B'); // no exacta (0): B baja a 2
      g.bid('B', const Bid(1, 6));
      g.calzo('C'); // no exacta: C baja a 2
      g.bid('C', const Bid(1, 6));
      g.calzo('A'); // no exacta: A baja de 2 a 1, único con 1
      expect(g.phase, GamePhase.kamikazeOffer);
      expect(g.kamikazeOfferPlayerId, 'A');
    });

    test('varios con 1 dado a la vez: nadie recibe oferta y la oportunidad queda pendiente', () {
      final g = GameEngine(
        config: completoDp(2),
        roller: ScriptedDiceRoller([
          6, 1, 1, // parte A
          2, 2, 2, 2, 2, 2, // ronda 1 (2 c/u)
          // Kamikaze de A (elige Pato): A se salva, B y C caen a 1 a la vez
          3, // A
          2, 5, // B pierde 1
          2, 5, // C pierde 1
          // ronda siguiente (1 c/u)
          3, 4, 5,
          // ronda tras la oferta diferida a C (parte B): A1 B2 C1
          2, 2, 2, 2,
        ]),
        playerList: const [
          (id: 'A', name: 'A'),
          (id: 'B', name: 'B'),
          (id: 'C', name: 'C'),
        ],
      );
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.dudo('B'); // A baja a 1, único -> oferta
      expect(g.kamikazeOfferPlayerId, 'A');
      g.respondKamikaze('A', accept: true);
      final res = g.chooseKamikazeFace('A', 2);
      expect(res.kamikazeLosses, {'A': 0, 'B': 1, 'C': 1});
      // B y C quedaron con 1 AL MISMO TIEMPO: sin oferta para nadie.
      expect(g.phase, GamePhase.playing);
      expect(g.kamikazeOfferPlayerId, isNull);
      expect(g.playerById('B').kamikazeOfferedOnce, isFalse);
      expect(g.playerById('C').kamikazeOfferedOnce, isFalse);
      // Ronda siguiente: B calza exacto (hay un solo Tren) pero el
      // total en mesa es 3 de 6 iniciales (la mitad exacta): desde
      // el 25-oct la recuperación exige ESTRICTAMENTE más de la
      // mitad, así que B NO recupera y los tres quedan con 1 dado:
      // sigue sin oferta para nadie (la oportunidad queda pendiente).
      expect(g.currentPlayerId, 'A'); // parte el activador, que sobrevivió
      g.bid('A', const Bid(1, 3));
      final resCalzo = g.calzo('B');
      expect(resCalzo.recoveryBlocked, isTrue);
      expect(g.playerById('B').diceCount, 1);
      expect(g.phase, GamePhase.playing);
      expect(g.kamikazeOfferPlayerId, isNull);
      expect(g.playerById('B').kamikazeOfferedOnce, isFalse);
      expect(g.playerById('C').kamikazeOfferedOnce, isFalse);
    });

    test('oferta diferida tras calzo con total sobre la mitad', () {
      // Misma situación que el test anterior (B y C con 1 dado a la
      // vez, sin oferta previa), pero con el total sobre la mitad:
      // 4 jugadores, 20 iniciales, 12 en mesa. B calza exacto,
      // recupera (12*2 > 20) y C queda único con 1 dado -> oferta
      // diferida a C. Estado simulado directamente (manos y dados
      // consistentes) para no guionar 8 pérdidas previas.
      final g = GameEngine(
        config: GameConfig.cachoCompleto(),
        roller: ScriptedDiceRoller([
          6, 1, 2, 3, // desempate: parte A
          ...List.filled(20, 2), // ronda 1 (se sobrescribe abajo)
          ...List.filled(80, 2), // cola para la ronda siguiente
        ]),
        playerList: const [
          (id: 'A', name: 'A'),
          (id: 'B', name: 'B'),
          (id: 'C', name: 'C'),
          (id: 'D', name: 'D'),
        ],
      );
      g.startGame();
      g.playerById('A').hand = [6, 6, 2, 2, 2];
      g.playerById('B').hand = [6];
      g.playerById('C').hand = [4];
      g.playerById('D').hand = [5, 5, 5, 5, 5];
      g.playerById('A').diceCount = 5;
      g.playerById('B').diceCount = 1;
      g.playerById('C').diceCount = 1;
      g.playerById('D').diceCount = 5;
      // B y C nunca recibieron oferta (flags en false por defecto).
      g.currentBid = const Bid(3, 6); // hay exactamente 3 seises
      g.currentPlayerId = 'B';
      expect(g.totalDiceInPlay, 12);
      final res = g.calzo('B');
      expect(res.gainerId, 'B');
      expect(res.recoveryBlocked, isFalse);
      expect(g.playerById('B').diceCount, 2);
      expect(g.phase, GamePhase.kamikazeOffer);
      expect(g.kamikazeOfferPlayerId, 'C');
      g.respondKamikaze('C', accept: false);
      expect(g.phase, GamePhase.playing);
      expect(g.currentPlayerId, 'B'); // parte quien recuperó el dado
    });

    test('en el preset Clásico no hay Kamikaze', () {
      final g = GameEngine(
        config: GameConfig.clasico().copyWith(dicePerPlayer: 2),
        roller: ScriptedDiceRoller([
          6, 1,
          2, 2, 2, 2, // ronda 1
          2, 2, 2, // ronda 2: A1 B2
        ]),
        playerList: const [(id: 'A', name: 'A'), (id: 'B', name: 'B')],
      );
      g.startGame();
      g.bid('A', const Bid(1, 6));
      g.dudo('B'); // A baja a 1, pero la regla está desactivada
      expect(g.phase, GamePhase.playing);
      expect(g.kamikazeOfferPlayerId, isNull);
    });
  });
}
