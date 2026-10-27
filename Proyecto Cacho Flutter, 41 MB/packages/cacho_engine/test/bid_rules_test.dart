import 'package:cacho_engine/cacho_engine.dart';
import 'package:test/test.dart';

void main() {
  group('subida clásica (raiseError)', () {
    test('primera apuesta: cualquier pinta, pero nunca ases', () {
      expect(GameEngine.raiseError(null, const Bid(3, 4), 20), isNull);
      expect(GameEngine.raiseError(null, const Bid(3, 1), 20),
          'ases_para_partir');
    });

    test('subir cantidad con cualquier pinta', () {
      expect(GameEngine.raiseError(const Bid(3, 4), const Bid(4, 2), 20), isNull);
    });

    test('misma cantidad con pinta mayor', () {
      expect(GameEngine.raiseError(const Bid(3, 4), const Bid(3, 5), 20), isNull);
    });

    test('no supera: igual, pinta menor con igual cantidad, cantidad menor', () {
      expect(GameEngine.raiseError(const Bid(3, 4), const Bid(3, 4), 20),
          'apuesta_no_supera');
      expect(GameEngine.raiseError(const Bid(3, 4), const Bid(3, 3), 20),
          'apuesta_no_supera');
      expect(GameEngine.raiseError(const Bid(3, 4), const Bid(2, 6), 20),
          'apuesta_no_supera');
    });

    test('cantidad no puede superar el total de dados en juego', () {
      expect(GameEngine.raiseError(const Bid(3, 4), const Bid(21, 4), 20),
          'cantidad_supera_total');
      expect(GameEngine.raiseError(null, const Bid(21, 4), 20),
          'cantidad_supera_total');
    });
  });

  group('ases: mitad / doble+1', () {
    test('entrar a ases exige la mitad hacia arriba', () {
      // 5 -> mínimo 3 ases
      expect(GameEngine.raiseError(const Bid(5, 3), const Bid(3, 1), 20), isNull);
      expect(GameEngine.raiseError(const Bid(5, 3), const Bid(2, 1), 20),
          'ases_mitad');
      // 4 -> mínimo 2 ases
      expect(GameEngine.raiseError(const Bid(4, 3), const Bid(2, 1), 20), isNull);
    });

    test('salir de ases exige el doble + 1', () {
      expect(GameEngine.raiseError(const Bid(2, 1), const Bid(5, 4), 20), isNull);
      expect(GameEngine.raiseError(const Bid(2, 1), const Bid(4, 4), 20),
          'salida_ases_doble_mas_uno');
    });

    test('de ases a ases solo sube la cantidad', () {
      expect(GameEngine.raiseError(const Bid(2, 1), const Bid(3, 1), 20), isNull);
      expect(GameEngine.raiseError(const Bid(2, 1), const Bid(2, 1), 20),
          'apuesta_no_supera');
    });
  });

  group('regla de ases desactivada: los ases son una pinta más', () {
    String? off(Bid? c, Bid n) =>
        GameEngine.raiseError(c, n, 20, acesRuleEnabled: false);

    test('sin conversión al entrar ni al salir de ases', () {
      // Entrar bajando la cantidad ya no vale (con la regla sería mitad).
      expect(off(const Bid(5, 3), const Bid(3, 1)), 'apuesta_no_supera');
      // Subir la cantidad hacia ases sí vale, como a cualquier pinta.
      expect(off(const Bid(5, 3), const Bid(6, 1)), isNull);
      // Salir de ases con la misma cantidad y pinta mayor vale (sin doble+1).
      expect(off(const Bid(2, 1), const Bid(2, 4)), isNull);
      expect(off(const Bid(2, 1), const Bid(4, 4)), isNull);
      // Dentro de ases se sigue subiendo la cantidad.
      expect(off(const Bid(4, 1), const Bid(5, 1)), isNull);
    });

    test('los ejemplos del usuario con la regla activa', () {
      // De 8 Cuadras -> 4 ases; de 7 Cuadras -> 4 ases.
      expect(GameEngine.raiseError(const Bid(8, 4), const Bid(4, 1), 30), isNull);
      expect(GameEngine.raiseError(const Bid(7, 4), const Bid(4, 1), 30), isNull);
      // De 4 ases -> 9 de cualquier pinta.
      expect(GameEngine.raiseError(const Bid(4, 1), const Bid(9, 6), 30), isNull);
      expect(GameEngine.raiseError(const Bid(4, 1), const Bid(8, 6), 30),
          'salida_ases_doble_mas_uno');
    });

    test('comodines efectivos: caen si la regla de ases está apagada', () {
      expect(const GameConfig().acesRuleEnabled, isTrue);
      expect(const GameConfig().wildcardsEffective, isTrue);
      expect(
          const GameConfig(wildcardsEnabled: true, acesRuleEnabled: false)
              .wildcardsEffective,
          isFalse);
    });
  });

  group('conteo con comodines', () {
    final hands = [
      [6, 6, 1, 2, 3],
      [6, 5, 4, 3, 2],
    ];

    test('los 1 cuentan como la pinta apostada', () {
      // seises reales: 3; comodín: 1 -> 4
      expect(GameEngine.countForBid(hands, const Bid(4, 6), true), 4);
    });

    test('sin comodines solo cuentan las caras reales', () {
      expect(GameEngine.countForBid(hands, const Bid(4, 6), false), 3);
    });

    test('con apuesta de ases los 1 no son comodín: solo cuentan los 1', () {
      expect(GameEngine.countForBid(hands, const Bid(1, 1), true), 1);
    });
  });

  group('mano de Paso (sin comodines)', () {
    test('cinco distintos', () {
      expect(GameEngine.isPasoHand([1, 2, 3, 4, 5]), isTrue);
      expect(GameEngine.isPasoHand([2, 3, 4, 5, 6]), isTrue);
    });

    test('full 3+2 en cualquier orden', () {
      expect(GameEngine.isPasoHand([2, 2, 3, 3, 3]), isTrue);
      expect(GameEngine.isPasoHand([4, 4, 4, 6, 6]), isTrue);
    });

    test('no son Paso', () {
      expect(GameEngine.isPasoHand([1, 1, 2, 3, 4]), isFalse); // par de ases
      expect(GameEngine.isPasoHand([2, 2, 2, 2, 3]), isFalse); // póker
      expect(GameEngine.isPasoHand([1, 2, 3, 4, 4]), isFalse); // un par
      expect(GameEngine.isPasoHand([2, 2, 3, 3]), isFalse); // 4 dados
    });
  });

  group('configuración y presets', () {
    test('umbral de Calzo: mitad hacia arriba, fijo al inicio', () {
      final c = GameConfig.cachoCompleto();
      expect(c.calzoThreshold(20), 10);
      expect(c.calzoThreshold(30), 15);
      expect(c.calzoThreshold(25), 13);
      expect(c.calzoThreshold(10), 5);
    });

    test('presets fijados', () {
      final clasico = GameConfig.clasico();
      expect(clasico.pasoEnabled, isFalse);
      expect(clasico.kamikazeEnabled, isFalse);
      expect(clasico.calzoEnabled, isTrue);
      expect(clasico.wildcardsEnabled, isTrue);
      final completo = GameConfig.cachoCompleto();
      expect(completo.pasoEnabled, isTrue);
      expect(completo.kamikazeEnabled, isTrue);
    });

    test('pintas chilenas', () {
      expect(Pinta.fromValor(1).nombre, 'As');
      expect(Pinta.fromValor(2).nombre, 'Pato');
      expect(Pinta.fromValor(3).nombre, 'Tren');
      expect(Pinta.fromValor(4).nombre, 'Cuadra');
      expect(Pinta.fromValor(5).nombre, 'Quinta');
      expect(Pinta.fromValor(6).nombre, 'Sexta');
      expect(const Bid(4, 3).toString(), '4 Tren');
    });
  });
}
