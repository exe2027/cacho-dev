import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

void main() {
  group('evaluateBid (desglose para la revelación)', () {
    test('marca exactos, comodines y fallos; apuesta no-ases', () {
      final ev = GameEngine.evaluateBid(
        {
          'a': [4, 4, 1, 2, 6],
          'b': [1, 3, 3, 5, 5],
        },
        const Bid(4, 4),
        true,
      );
      expect(ev.exact, 2); // los dos 4 de a
      expect(ev.wild, 2); // el 1 de a y el 1 de b
      expect(ev.total, 4);
      expect(ev.marks['a'],
          [DieMark.exact, DieMark.exact, DieMark.wild, DieMark.miss, DieMark.miss]);
      expect(ev.marks['b']!.first, DieMark.wild);
    });

    test('apuesta de ases: solo cuentan los 1 reales', () {
      final ev = GameEngine.evaluateBid(
        {
          'a': [1, 1, 4, 4, 4],
        },
        const Bid(2, 1),
        true,
      );
      expect(ev.exact, 2);
      expect(ev.wild, 0);
      expect(ev.total, 2);
    });

    test('sin comodines: el 1 no suma a otra pinta', () {
      final ev = GameEngine.evaluateBid(
        {
          'a': [1, 5, 5],
        },
        const Bid(2, 5),
        false,
      );
      expect(ev.total, 2);
      expect(ev.marks['a']!.first, DieMark.miss);
    });
  });

  group('GameConfig.describe (Ver qué cambia)', () {
    test('Clásico: sin Paso ni Kamikaze, con Calzo y comodines', () {
      final lines = GameConfig.clasico().describe().join('\n');
      expect(lines, contains('Paso desactivado'));
      expect(lines, contains('Kamikaze desactivado'));
      expect(lines, contains('Calzo activo'));
      expect(lines, contains('Comodines'));
    });

    test('Cacho completo: todo activo', () {
      final lines = GameConfig.cachoCompleto().describe().join('\n');
      expect(lines, contains('Paso activo'));
      expect(lines, contains('Kamikaze activo'));
      expect(lines, contains('60 segundos'));
    });

    test('sin regla de ases: lo dice y apaga comodines efectivos', () {
      final cfg = GameConfig.cachoCompleto().copyWith(acesRuleEnabled: false);
      final lines = cfg.describe().join('\n');
      expect(lines, contains('Ases como una pinta más'));
      expect(lines, contains('Sin comodines'));
    });
  });

  group('bots con explicación', () {
    test('toda acción del cerebro trae motivo en una línea', () {
      final brain = BotBrain(BotDifficulty.media);
      final ctx = BotContext(
        selfId: 'bot',
        ownHand: [6, 6, 2, 3, 4],
        currentBid: const Bid(4, 6),
        totalDiceInPlay: 10,
        diceCounts: {'bot': 5, 'x': 5},
        pendingPasoPlayerId: null,
        canCalzo: true,
        canPaso: false,
        config: GameConfig.clasico(),
      );
      final action = brain.decide(ctx);
      expect(action.reason, isNotNull);
      expect(action.reason, isNotEmpty);
    });
  });
}
