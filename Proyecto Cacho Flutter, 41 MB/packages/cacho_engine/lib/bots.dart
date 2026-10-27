import 'dart:math';

import 'cacho_engine.dart';

/// Bots de Cacho. Juegan SOLO con información pública y su propia mano
/// (la misma vista que un humano): jamás leen manos ajenas.
///
/// Estrategia: probabilidad binomial exacta sobre los dados desconocidos.
/// Dados desconocidos = total en juego - dados propios. Cada dado ajeno
/// coincide con la pinta apostada con probabilidad:
/// - 1/6 si la pinta es As o si los comodines están desactivados,
/// - 2/6 si hay comodines (la pinta o un 1).

enum BotDifficulty { facil, media, dificil }

enum BotActionType { bid, dudo, calzo, paso, dudoPaso, calzoPaso }

class BotAction {
  final BotActionType type;
  final Bid? bid;

  /// Explicación en una línea, en español simple (partida guiada y
  /// globos de la mesa). La genera el cerebro con lo que el bot "pensó".
  final String? reason;
  const BotAction(this.type, [this.bid, this.reason]);
  @override
  String toString() => 'BotAction(${type.name}${bid != null ? ' $bid' : ''})';
}

/// Vista del bot: su mano y lo público. Nada más entra aquí.
class BotContext {
  final String selfId;
  final List<int> ownHand;
  final Bid? currentBid;
  final int totalDiceInPlay;
  final Map<String, int> diceCounts;
  final String? pendingPasoPlayerId;
  final bool canCalzo;
  final bool canPaso;
  final GameConfig config;

  const BotContext({
    required this.selfId,
    required this.ownHand,
    required this.currentBid,
    required this.totalDiceInPlay,
    required this.diceCounts,
    required this.pendingPasoPlayerId,
    required this.canCalzo,
    required this.canPaso,
    required this.config,
  });
}

double _comb(int n, int k) {
  if (k < 0 || k > n) return 0;
  final kk = k > n - k ? n - k : k;
  var result = 1.0;
  for (var i = 0; i < kk; i++) {
    result = result * (n - i) / (i + 1);
  }
  return result;
}

/// P(X = k) con X ~ Binomial(n, p).
double binomialPmf(int n, int k, double p) {
  if (k < 0 || k > n) return 0;
  return _comb(n, k) * pow(p, k).toDouble() * pow(1 - p, n - k).toDouble();
}

/// P(al menos [needed] éxitos en [n] dados con probabilidad [p] cada uno).
double probabilityAtLeast(int n, int needed, double p) {
  if (needed <= 0) return 1;
  if (needed > n) return 0;
  var sum = 0.0;
  for (var k = needed; k <= n; k++) {
    sum += binomialPmf(n, k, p);
  }
  return sum;
}

/// P(exactamente [needed] éxitos).
double probabilityExactly(int n, int needed, double p) {
  if (needed < 0 || needed > n) return 0;
  return binomialPmf(n, needed, p);
}

class BotBrain {
  final BotDifficulty difficulty;
  final Random _random;

  BotBrain(this.difficulty, [Random? random]) : _random = random ?? Random();

  double get _dudoThreshold => switch (difficulty) {
        BotDifficulty.facil => 0.30,
        BotDifficulty.media => 0.38,
        BotDifficulty.dificil => 0.32,
      };

  double get _calzoThreshold => switch (difficulty) {
        BotDifficulty.facil => 0.45,
        BotDifficulty.media => 0.30,
        BotDifficulty.dificil => 0.22,
      };

  double get _bluffProbability => switch (difficulty) {
        BotDifficulty.facil => 0.05,
        BotDifficulty.media => 0.08,
        BotDifficulty.dificil => 0.15,
      };

  double _matchP(int face, GameConfig config) {
    if (face == 1 || !config.wildcardsEffective) return 1 / 6;
    return 2 / 6;
  }

  int _ownMatches(List<int> hand, int face, GameConfig config) {
    var n = 0;
    for (final d in hand) {
      if (d == face) {
        n++;
      } else if (config.wildcardsEffective && face != 1 && d == 1) {
        n++;
      }
    }
    return n;
  }

  BotAction decide(BotContext ctx) {
    // 1) Paso pendiente de otro: desafiarlo es favorable en promedio
    //    (una mano al azar es Paso con prob. ~13%), salvo en fácil,
    //    que a veces sigue jugando.
    if (ctx.pendingPasoPlayerId != null &&
        ctx.pendingPasoPlayerId != ctx.selfId) {
      if (difficulty == BotDifficulty.facil && _random.nextDouble() < 0.5) {
        // sigue jugando: cae al flujo normal
      } else {
        return const BotAction(BotActionType.dudoPaso, null,
            'Ese Paso me huele falso.');
      }
    }

    final bidNow = ctx.currentBid;
    if (bidNow == null) return _openingBid(ctx);

    final p = _matchP(bidNow.face, ctx.config);
    final unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
    final own = _ownMatches(ctx.ownHand, bidNow.face, ctx.config);
    final needed = bidNow.quantity - own;
    final probTrue = probabilityAtLeast(unknown, needed, p);
    final probExact = probabilityExactly(unknown, needed, p);

    // 2) Calzo si la exacta es creíble.
    if (ctx.canCalzo && probExact >= _calzoThreshold) {
      return const BotAction(BotActionType.calzo, null,
          'Para mí es exacto.');
    }

    // 3) Paso propio si la mano lo es y la apuesta vigente no es sólida.
    if (ctx.canPaso &&
        GameEngine.isPasoHand(ctx.ownHand) &&
        probTrue < 0.75 &&
        difficulty != BotDifficulty.facil) {
      return const BotAction(BotActionType.paso, null,
          'Tengo el Paso.');
    }

    // 4) Dudo si la apuesta vigente es poco probable.
    final noise = difficulty == BotDifficulty.facil
        ? (_random.nextDouble() - 0.5) * 0.2
        : 0.0;
    if (probTrue < _dudoThreshold + noise) {
      return BotAction(BotActionType.dudo, null,
          'No alcanza: dudo.');
    }

    // 5) Subir: elegir la subida legal con mejor probabilidad propia.
    return _raise(ctx, bidNow);
  }

  BotAction _openingBid(BotContext ctx) {
    // Pinta propia más fuerte (los 1 refuerzan cualquier pinta no-As).
    var bestFace = 6;
    var bestCount = -1;
    for (var face = 2; face <= 6; face++) {
      final c = _ownMatches(ctx.ownHand, face, ctx.config);
      if (c > bestCount) {
        bestCount = c;
        bestFace = face;
      }
    }
    // Nunca partir con ases (regla de la casa).
    final unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
    final p = _matchP(bestFace, ctx.config);
    final expected = unknown * p;
    var qty = bestCount + (expected * 0.5).round();
    if (qty < 1) qty = 1;
    if (qty > ctx.totalDiceInPlay) qty = ctx.totalDiceInPlay;
    if (difficulty == BotDifficulty.facil && _random.nextDouble() < 0.25) {
      qty = 1 + _random.nextInt(3);
      bestFace = 2 + _random.nextInt(5);
      if (qty > ctx.totalDiceInPlay) qty = ctx.totalDiceInPlay;
    }
    return BotAction(BotActionType.bid, Bid(qty, bestFace),
        'Parto con mi pinta fuerte.');
  }

  BotAction _raise(BotContext ctx, Bid current) {
    final candidates = <Bid>[];
    void add(Bid b) {
      if (GameEngine.raiseError(current, b, ctx.totalDiceInPlay,
              acesRuleEnabled: ctx.config.acesRuleEnabled) ==
          null) {
        candidates.add(b);
      }
    }

    if (current.face != 1) {
      add(Bid(current.quantity + 1, current.face));
      if (current.face < 6) add(Bid(current.quantity, current.face + 1));
      add(Bid(current.quantity + 2, current.face));
      // Entrar a ases solo si tengo ases reales que lo respalden.
      add(Bid((current.quantity + 1) ~/ 2, 1));
    } else {
      add(Bid(current.quantity + 1, 1));
      // Salir de ases hacia mi mejor pinta.
      var bestFace = 6;
      var bestCount = -1;
      for (var face = 2; face <= 6; face++) {
        final c = _ownMatches(ctx.ownHand, face, ctx.config);
        if (c > bestCount) {
          bestCount = c;
          bestFace = face;
        }
      }
      add(Bid(current.quantity * 2 + 1, bestFace));
    }

    if (candidates.isEmpty) {
      // Sin subida legal posible: dudar.
      return const BotAction(BotActionType.dudo, null,
          'Sin buena subida: dudo.');
    }

    double probOf(Bid b) {
      final p = _matchP(b.face, ctx.config);
      final unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
      final own = _ownMatches(ctx.ownHand, b.face, ctx.config);
      return probabilityAtLeast(unknown, b.quantity - own, p);
    }

    candidates.sort((a, b) => probOf(b).compareTo(probOf(a)));
    final best = candidates.first;
    final bluff = _random.nextDouble() < _bluffProbability;
    if (probOf(best) < 0.35 && !bluff) {
      return const BotAction(BotActionType.dudo, null,
          'No me convence: dudo.');
    }
    if (bluff && probOf(best) < 0.5) {
      return BotAction(BotActionType.bid, best,
          'Subo igual, a ver si pasa.');
    }
    return BotAction(BotActionType.bid, best,
        'Tengo apoyo para subir.');
  }

  /// Kamikaze: aceptar si los rivales tienen suficientes dados que perder
  /// (cada dado rival cae con prob. 1/6; el propio también, pero es 1 solo).
  bool shouldAcceptKamikaze(BotContext ctx) {
    final othersDice = ctx.totalDiceInPlay - (ctx.diceCounts[ctx.selfId] ?? 1);
    if (difficulty == BotDifficulty.facil) {
      return _random.nextDouble() < 0.3;
    }
    return othersDice >= 3;
  }

  /// El número se elige ANTES de lanzar: ninguna cara tiene ventaja
  /// informativa, así que se elige al azar.
  int chooseKamikazeFace() => 1 + _random.nextInt(6);
}
