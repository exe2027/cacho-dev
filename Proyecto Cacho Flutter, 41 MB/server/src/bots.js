// Bots en JS: puerto del BotBrain de Dart (packages/cacho_engine/lib/bots.dart).
// Misma estrategia: probabilidad binomial sobre los dados desconocidos y
// SOLO la propia mano + información pública.
import { raiseError, isPasoHand, wildcardsEffective } from './engine.js';

function comb(n, k) {
  if (k < 0 || k > n) return 0;
  const kk = k > n - k ? n - k : k;
  let r = 1;
  for (let i = 0; i < kk; i++) r = (r * (n - i)) / (i + 1);
  return r;
}

export function binomialPmf(n, k, p) {
  if (k < 0 || k > n) return 0;
  return comb(n, k) * Math.pow(p, k) * Math.pow(1 - p, n - k);
}

export function probabilityAtLeast(n, needed, p) {
  if (needed <= 0) return 1;
  if (needed > n) return 0;
  let s = 0;
  for (let k = needed; k <= n; k++) s += binomialPmf(n, k, p);
  return s;
}

export function probabilityExactly(n, needed, p) {
  if (needed < 0 || needed > n) return 0;
  return binomialPmf(n, needed, p);
}

const PARAMS = {
  facil: { dudo: 0.3, calzo: 0.45, bluff: 0.05 },
  media: { dudo: 0.38, calzo: 0.3, bluff: 0.08 },
  dificil: { dudo: 0.32, calzo: 0.22, bluff: 0.15 },
};

export class BotBrain {
  constructor(difficulty = 'media', rng = Math.random) {
    this.difficulty = PARAMS[difficulty] ? difficulty : 'media';
    this.params = PARAMS[this.difficulty];
    this.rng = rng;
  }

  matchP(face, config) {
    if (face === 1 || !wildcardsEffective(config)) return 1 / 6;
    return 2 / 6;
  }

  ownMatches(hand, face, config) {
    let n = 0;
    for (const d of hand) {
      if (d === face) n++;
      else if (wildcardsEffective(config) && face !== 1 && d === 1) n++;
    }
    return n;
  }

  /** ctx: {selfId, ownHand, currentBid, totalDiceInPlay, diceCounts,
   *        pendingPasoPlayerId, canCalzo, canPaso, config} */
  decide(ctx) {
    if (ctx.pendingPasoPlayerId && ctx.pendingPasoPlayerId !== ctx.selfId) {
      if (!(this.difficulty === 'facil' && this.rng() < 0.5)) {
        return { type: 'dudoPaso', reason: 'Ese Paso me huele falso.' };
      }
    }
    const bidNow = ctx.currentBid;
    if (!bidNow) return this.openingBid(ctx);

    const p = this.matchP(bidNow.face, ctx.config);
    const unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
    const own = this.ownMatches(ctx.ownHand, bidNow.face, ctx.config);
    const needed = bidNow.quantity - own;
    const probTrue = probabilityAtLeast(unknown, needed, p);
    const probExact = probabilityExactly(unknown, needed, p);

    if (ctx.canCalzo && probExact >= this.params.calzo) return { type: 'calzo', reason: 'Para mí es exacto.' };

    if (ctx.canPaso && isPasoHand(ctx.ownHand) && probTrue < 0.75 && this.difficulty !== 'facil') {
      return { type: 'paso', reason: 'Tengo el Paso.' };
    }

    const noise = this.difficulty === 'facil' ? (this.rng() - 0.5) * 0.2 : 0;
    if (probTrue < this.params.dudo + noise) return { type: 'dudo', reason: `No alcanza: dudo.` };

    return this.raise(ctx, bidNow);
  }

  openingBid(ctx) {
    let bestFace = 6;
    let bestCount = -1;
    for (let face = 2; face <= 6; face++) {
      const c = this.ownMatches(ctx.ownHand, face, ctx.config);
      if (c > bestCount) {
        bestCount = c;
        bestFace = face;
      }
    }
    // Nunca partir con ases (regla de la casa).
    const unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
    const p = this.matchP(bestFace, ctx.config);
    let qty = bestCount + Math.round(unknown * p * 0.5);
    qty = Math.max(1, Math.min(qty, ctx.totalDiceInPlay));
    if (this.difficulty === 'facil' && this.rng() < 0.25) {
      qty = Math.min(1 + Math.floor(this.rng() * 3), ctx.totalDiceInPlay);
      bestFace = 2 + Math.floor(this.rng() * 5);
    }
    return { type: 'bid', bid: { quantity: qty, face: bestFace }, reason: 'Parto con mi pinta fuerte.' };
  }

  raise(ctx, current) {
    const candidates = [];
    const add = (b) => {
      if (raiseError(current, b, ctx.totalDiceInPlay, ctx.config.acesRuleEnabled !== false) === null) candidates.push(b);
    };
    if (current.face !== 1) {
      add({ quantity: current.quantity + 1, face: current.face });
      if (current.face < 6) add({ quantity: current.quantity, face: current.face + 1 });
      add({ quantity: current.quantity + 2, face: current.face });
      add({ quantity: Math.ceil(current.quantity / 2), face: 1 });
    } else {
      add({ quantity: current.quantity + 1, face: 1 });
      let bestFace = 6;
      let bestCount = -1;
      for (let face = 2; face <= 6; face++) {
        const c = this.ownMatches(ctx.ownHand, face, ctx.config);
        if (c > bestCount) {
          bestCount = c;
          bestFace = face;
        }
      }
      add({ quantity: current.quantity * 2 + 1, face: bestFace });
    }
    if (!candidates.length) return { type: 'dudo', reason: 'Sin buena subida: dudo.' };
    const probOf = (b) => {
      const p = this.matchP(b.face, ctx.config);
      const unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
      const own = this.ownMatches(ctx.ownHand, b.face, ctx.config);
      return probabilityAtLeast(unknown, b.quantity - own, p);
    };
    candidates.sort((a, b) => probOf(b) - probOf(a));
    const best = candidates[0];
    const bluff = this.rng() < this.params.bluff;
    if (probOf(best) < 0.35 && !bluff) return { type: 'dudo', reason: 'No me convence: dudo.' };
    return { type: 'bid', bid: best, reason: `Tengo apoyo para subir.` };
  }

  shouldAcceptKamikaze(ctx) {
    const others = ctx.totalDiceInPlay - (ctx.diceCounts[ctx.selfId] ?? 1);
    if (this.difficulty === 'facil') return this.rng() < 0.3;
    return others >= 3;
  }

  chooseKamikazeFace() {
    return 1 + Math.floor(this.rng() * 6);
  }
}

/** Construye el contexto del bot desde el motor (solo su mano y lo público). */
export function botContext(engine, botId, { canPaso }) {
  return {
    selfId: botId,
    ownHand: engine.handOf(botId),
    currentBid: engine.currentBid,
    totalDiceInPlay: engine.totalDiceInPlay,
    diceCounts: Object.fromEntries(engine.players.map((p) => [p.id, p.diceCount])),
    pendingPasoPlayerId: engine.pendingPasoPlayerId,
    canCalzo: engine.canCalzoNow,
    canPaso,
    config: engine.config,
  };
}
