// src/manager.js
import { randomInt as randomInt2, randomUUID } from "node:crypto";

// src/engine.js
import { randomInt } from "node:crypto";
var IllegalMove = class extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
};
var PINTAS = [null, "As", "Pato", "Tren", "Cuadra", "Quinta", "Sexta"];
var bidToString = (b) => `${b.quantity} ${PINTAS[b.face]}`;
function defaultConfig(overrides = {}) {
  return {
    wildcardsEnabled: true,
    acesRuleEnabled: true,
    pasoEnabled: true,
    kamikazeEnabled: true,
    calzoEnabled: true,
    calzoMinFraction: 0.5,
    maxPasosPerPlayerPerRound: 1,
    pasoAsFirstPlayAllowed: false,
    pasoTwiceInARowAllowed: false,
    dicePerPlayer: 5,
    minPlayers: 2,
    maxPlayers: 12,
    turnTimerSeconds: 60,
    ...overrides
  };
}
function configForPreset(preset, overrides = {}) {
  if (!preset || preset === "completo") return defaultConfig(overrides);
  if (preset === "clasico") {
    return defaultConfig({ pasoEnabled: false, kamikazeEnabled: false, ...overrides });
  }
  if (preset === "custom") return defaultConfig(overrides);
  throw new IllegalMove("preset_invalido", `preset desconocido: ${preset}`);
}
var calzoThreshold = (config, initialTotalDice) => Math.ceil(initialTotalDice * config.calzoMinFraction);
var RandomDiceRoller = class {
  rollDie() {
    return randomInt(1, 7);
  }
};
var wildcardsEffective = (config) => config.wildcardsEnabled && config.acesRuleEnabled !== false;
function raiseError(current, next, totalDiceInPlay, acesRuleEnabled = true) {
  if (!next || next.face < 1 || next.face > 6) return "pinta_invalida";
  if (next.quantity < 1) return "cantidad_invalida";
  if (next.quantity > totalDiceInPlay) return "cantidad_supera_total";
  if (current == null) return next.face === 1 ? "ases_para_partir" : null;
  if (!acesRuleEnabled || current.face !== 1 && next.face !== 1) {
    if (next.quantity > current.quantity) return null;
    if (next.quantity === current.quantity && next.face > current.face) return null;
    return "apuesta_no_supera";
  }
  if (current.face !== 1 && next.face === 1) {
    const minQty = Math.ceil(current.quantity / 2);
    return next.quantity >= minQty ? null : "ases_mitad";
  }
  if (current.face === 1 && next.face !== 1) {
    const minQty = current.quantity * 2 + 1;
    return next.quantity >= minQty ? null : "salida_ases_doble_mas_uno";
  }
  return next.quantity > current.quantity ? null : "apuesta_no_supera";
}
function countForBid(hands, bid, wildcardsEnabled) {
  let total = 0;
  for (const hand of hands) {
    for (const die of hand) {
      if (die === bid.face) total++;
      else if (wildcardsEnabled && bid.face !== 1 && die === 1) total++;
    }
  }
  return total;
}
function isPasoHand(hand) {
  if (hand.length !== 5) return false;
  if (new Set(hand).size === 5) return true;
  const counts = {};
  for (const die of hand) counts[die] = (counts[die] ?? 0) + 1;
  const sorted = Object.values(counts).sort((a, b) => a - b);
  return sorted.length === 2 && sorted[0] === 2 && sorted[1] === 3;
}
var GameEngine = class {
  constructor({ config, roller, players }) {
    this.config = config;
    this.roller = roller;
    if (players.length < config.minPlayers || players.length > config.maxPlayers) {
      throw new Error(`jugadores fuera de rango: ${players.length}`);
    }
    if (new Set(players.map((p) => p.id)).size !== players.length) {
      throw new Error("ids de jugador duplicados");
    }
    this.players = players.map((p) => ({
      id: p.id,
      name: p.name,
      diceCount: config.dicePerPlayer,
      hand: [],
      kamikazeOfferedOnce: false,
      kamikazeUsed: false,
      get eliminated() {
        return this.diceCount <= 0;
      },
      get alive() {
        return this.diceCount > 0;
      }
    }));
    this.initialTotalDice = players.length * config.dicePerPlayer;
    this.calzoThresholdDice = calzoThreshold(config, this.initialTotalDice);
    this.phase = "lobby";
    this.roundNumber = 0;
    this.currentBid = null;
    this.lastBidderId = null;
    this.currentPlayerId = null;
    this.pendingPasoPlayerId = null;
    this.kamikazeOfferPlayerId = null;
    this.kamikazeActivatorId = null;
    this.winnerId = null;
    this.isDraw = false;
    this.lastResolution = null;
    this.history = [];
    this._roundHistory = [];
    this._pasosThisRound = {};
    this._lastActionThisRound = {};
    this._actionsThisRound = 0;
    this._pendingStarterId = null;
  }
  playerById(id) {
    const p = this.players.find((x) => x.id === id);
    if (!p) throw new Error(`jugador desconocido: ${id}`);
    return p;
  }
  get alivePlayers() {
    return this.players.filter((p) => p.alive);
  }
  get totalDiceInPlay() {
    return this.alivePlayers.reduce((s, p) => s + p.diceCount, 0);
  }
  get canCalzoNow() {
    return this.config.calzoEnabled;
  }
  get roundHistory() {
    return [...this._roundHistory];
  }
  handOf(playerId) {
    return [...this.playerById(playerId).hand];
  }
  nextAliveAfter(id) {
    const idx = this.players.findIndex((p) => p.id === id);
    for (let i = 1; i <= this.players.length; i++) {
      const p = this.players[(idx + i) % this.players.length];
      if (p.alive) return p.id;
    }
    throw new Error("no quedan jugadores vivos");
  }
  startGame() {
    if (this.phase !== "lobby") throw new IllegalMove("fase_invalida", "la partida ya comenz\xF3");
    let candidates = this.players.map((p) => p.id);
    let starter;
    while (true) {
      const rolls = {};
      let maxRoll = -1;
      for (const id of candidates) {
        rolls[id] = this.roller.rollDie();
        if (rolls[id] > maxRoll) maxRoll = rolls[id];
      }
      const tied = candidates.filter((id) => rolls[id] === maxRoll);
      if (tied.length === 1) {
        starter = tied[0];
        break;
      }
      candidates = tied;
    }
    this._beginRound(starter);
    return starter;
  }
  _beginRound(starterId) {
    this.roundNumber++;
    for (const p of this.players) {
      p.hand = p.alive ? Array.from({ length: p.diceCount }, () => this.roller.rollDie()) : [];
    }
    this.currentBid = null;
    this.lastBidderId = null;
    this.pendingPasoPlayerId = null;
    this.kamikazeOfferPlayerId = null;
    this.kamikazeActivatorId = null;
    this._pasosThisRound = {};
    this._lastActionThisRound = {};
    this._roundHistory = [];
    this._actionsThisRound = 0;
    this.currentPlayerId = starterId;
    this.phase = "playing";
  }
  _requireTurn(playerId) {
    if (this.phase !== "playing") throw new IllegalMove("fase_invalida", "no hay ronda en curso");
    if (this.currentPlayerId !== playerId) {
      throw new IllegalMove("no_es_tu_turno", "todav\xEDa no es tu turno");
    }
    const p = this.playerById(playerId);
    if (p.eliminated) throw new IllegalMove("jugador_eliminado", "ese jugador ya sali\xF3");
    return p;
  }
  _record(playerId, type, bid = null) {
    const e = { round: this.roundNumber, playerId, type, bid };
    this.history.push(e);
    this._roundHistory.push(e);
    this._lastActionThisRound[playerId] = type;
    this._actionsThisRound++;
  }
  _advanceTurn() {
    this.currentPlayerId = this.nextAliveAfter(this.currentPlayerId);
  }
  bid(playerId, next) {
    this._requireTurn(playerId);
    const error = raiseError(this.currentBid, next, this.totalDiceInPlay, this.config.acesRuleEnabled !== false);
    if (error) throw new IllegalMove(error, `apuesta ilegal: ${next ? bidToString(next) : next}`);
    this.pendingPasoPlayerId = null;
    this.currentBid = { quantity: next.quantity, face: next.face };
    this.lastBidderId = playerId;
    this._record(playerId, "bid", this.currentBid);
    this._advanceTurn();
  }
  paso(playerId) {
    const p = this._requireTurn(playerId);
    if (!this.config.pasoEnabled) {
      throw new IllegalMove("paso_deshabilitado", "el Paso no est\xE1 activo en esta sala");
    }
    if (p.diceCount !== this.config.dicePerPlayer || p.diceCount !== 5) {
      throw new IllegalMove("paso_requiere_5_dados", "solo puedes pasar con tus 5 dados completos");
    }
    if (this._actionsThisRound === 0 && !this.config.pasoAsFirstPlayAllowed) {
      throw new IllegalMove("paso_primera_jugada", "no se puede pasar como primera jugada de la ronda");
    }
    if ((this._pasosThisRound[playerId] ?? 0) >= this.config.maxPasosPerPlayerPerRound) {
      throw new IllegalMove("paso_limite_ronda", "ya usaste tu Paso de esta ronda");
    }
    if (!this.config.pasoTwiceInARowAllowed && this._lastActionThisRound[playerId] === "paso") {
      throw new IllegalMove("paso_dos_veces_seguidas", "no puedes pasar dos veces seguidas");
    }
    this.pendingPasoPlayerId = playerId;
    this._pasosThisRound[playerId] = (this._pasosThisRound[playerId] ?? 0) + 1;
    this._record(playerId, "paso");
    this._advanceTurn();
  }
  dudo(playerId) {
    this._requireTurn(playerId);
    const bidNow = this.currentBid;
    if (!bidNow) throw new IllegalMove("sin_apuesta", "no hay apuesta que dudar");
    this.pendingPasoPlayerId = null;
    const actual = countForBid(this.alivePlayers.map((p) => p.hand), bidNow, wildcardsEffective(this.config));
    const bidder = this.lastBidderId;
    const loser = actual >= bidNow.quantity ? playerId : bidder;
    const revealedHands = Object.fromEntries(this.alivePlayers.map((p) => [p.id, [...p.hand]]));
    this._record(playerId, "dudo");
    this._applyLoss(loser);
    const res = { type: "dudo", loserId: loser, gainerId: null, revealedHands, actualCount: actual, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    this._finishResolution(loser, res);
    return res;
  }
  calzo(playerId) {
    this._requireTurn(playerId);
    const bidNow = this.currentBid;
    if (!bidNow) throw new IllegalMove("sin_apuesta", "no hay apuesta que calzar");
    if (!this.config.calzoEnabled) throw new IllegalMove("calzo_deshabilitado", "el Calzo no est\xE1 activo");
    this.pendingPasoPlayerId = null;
    const actual = countForBid(this.alivePlayers.map((p) => p.hand), bidNow, wildcardsEffective(this.config));
    const revealedHands = Object.fromEntries(this.alivePlayers.map((p) => [p.id, [...p.hand]]));
    this._record(playerId, "calzo");
    const exact = actual === bidNow.quantity;
    let massLoserIds = [];
    if (exact) {
      if (this.playerById(playerId).diceCount >= this.config.dicePerPlayer) {
        massLoserIds = this.alivePlayers.filter((p) => p.id !== playerId).map((p) => p.id);
        for (const id of massLoserIds) this._applyLoss(id);
      } else {
        this._applyGain(playerId);
      }
    } else {
      this._applyLoss(playerId);
    }
    const res = { type: "calzo", loserId: exact ? null : playerId, gainerId: exact && massLoserIds.length === 0 ? playerId : null, revealedHands, actualCount: actual, kamikazeFace: null, kamikazeLosses: {}, massLoserIds };
    this._finishResolution(playerId, res);
    return res;
  }
  dudoPaso(playerId) {
    this._requireTurn(playerId);
    const pasoId = this.pendingPasoPlayerId;
    if (!pasoId) throw new IllegalMove("sin_paso_pendiente", "no hay Paso que dudar");
    const pasoPlayer = this.playerById(pasoId);
    const truth = isPasoHand(pasoPlayer.hand);
    const revealedHands = { [pasoId]: [...pasoPlayer.hand] };
    this._record(playerId, "dudoPaso");
    const loser = truth ? playerId : pasoId;
    this._applyLoss(loser);
    const res = { type: "dudoPaso", loserId: loser, gainerId: null, revealedHands, actualCount: null, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    this._finishResolution(loser, res);
    return res;
  }
  calzoPaso(playerId) {
    this._requireTurn(playerId);
    const pasoId = this.pendingPasoPlayerId;
    if (!pasoId) throw new IllegalMove("sin_paso_pendiente", "no hay Paso que calzar");
    if (!this.config.calzoEnabled) throw new IllegalMove("calzo_deshabilitado", "el Calzo no est\xE1 activo");
    const pasoPlayer = this.playerById(pasoId);
    const truth = isPasoHand(pasoPlayer.hand);
    const revealedHands = { [pasoId]: [...pasoPlayer.hand] };
    this._record(playerId, "calzoPaso");
    if (truth) this._applyGain(playerId);
    else this._applyLoss(playerId);
    const res = { type: "calzoPaso", loserId: truth ? null : playerId, gainerId: truth ? playerId : null, revealedHands, actualCount: null, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    this._finishResolution(playerId, res);
    return res;
  }
  respondKamikaze(playerId, accept) {
    if (this.phase !== "kamikazeOffer") throw new IllegalMove("fase_invalida", "no hay oferta de Kamikaze");
    if (this.kamikazeOfferPlayerId !== playerId) {
      throw new IllegalMove("no_es_tu_oferta", "el Kamikaze no te fue ofrecido a ti");
    }
    const p = this.playerById(playerId);
    p.kamikazeOfferedOnce = true;
    if (!accept) {
      this.kamikazeOfferPlayerId = null;
      this._beginRound(this._pendingStarterId);
      return;
    }
    p.kamikazeUsed = true;
    this.kamikazeActivatorId = playerId;
    this.kamikazeOfferPlayerId = null;
    this.phase = "kamikazeChoice";
    this.currentPlayerId = playerId;
  }
  chooseKamikazeFace(playerId, face) {
    if (this.phase !== "kamikazeChoice") throw new IllegalMove("fase_invalida", "no hay Kamikaze en elecci\xF3n");
    if (this.kamikazeActivatorId !== playerId) {
      throw new IllegalMove("no_es_tu_oferta", "solo el activador elige el n\xFAmero");
    }
    if (face < 1 || face > 6) throw new IllegalMove("pinta_invalida", "el n\xFAmero debe ser 1..6");
    this._record(playerId, "kamikaze");
    const revealedHands = {};
    const kamikazeLosses = {};
    for (const p of this.alivePlayers) {
      const roll = Array.from({ length: p.diceCount }, () => this.roller.rollDie());
      p.hand = roll;
      revealedHands[p.id] = [...roll];
      const lost = roll.filter((d) => d === face).length;
      kamikazeLosses[p.id] = lost;
      p.diceCount -= lost;
    }
    const res = { type: "kamikaze", loserId: null, gainerId: null, revealedHands, actualCount: null, kamikazeFace: face, kamikazeLosses, massLoserIds: [] };
    this._finishResolution(playerId, res);
    return res;
  }
  /// Elimina a un jugador de inmediato (abandono: 3 tiempos de turno
  /// vencidos seguidos). La ronda en curso se corta y parte la
  /// siguiente el siguiente jugador vivo en el reloj. Espejo del
  /// motor Dart.
  forceEliminate(playerId) {
    if (this.phase === "finished") throw new IllegalMove("partida_terminada", "la partida ya termin\xF3");
    const p = this.playerById(playerId);
    if (!p.alive) throw new IllegalMove("jugador_eliminado", "ese jugador ya estaba eliminado");
    const revealedHands = { [playerId]: [...p.hand] };
    p.diceCount = 0;
    p.hand = [];
    if (this.kamikazeOfferPlayerId === playerId) this.kamikazeOfferPlayerId = null;
    if (this.kamikazeActivatorId === playerId) this.kamikazeActivatorId = null;
    const res = { type: "abandono", loserId: playerId, gainerId: null, revealedHands, actualCount: null, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    let candidate = playerId;
    if (this.phase === "kamikazeOffer" && this._pendingStarterId && this._pendingStarterId !== playerId && this.playerById(this._pendingStarterId).alive) {
      candidate = this._pendingStarterId;
    }
    this._finishResolution(candidate, res);
    return res;
  }
  _applyLoss(playerId) {
    const p = this.playerById(playerId);
    if (p.diceCount > 0) p.diceCount--;
  }
  _applyGain(playerId) {
    const p = this.playerById(playerId);
    if (p.diceCount < this.config.dicePerPlayer) p.diceCount++;
  }
  _finishResolution(starterCandidateId, res) {
    this.lastResolution = res;
    this.pendingPasoPlayerId = null;
    this.currentPlayerId = null;
    const alive = this.alivePlayers;
    if (alive.length === 0) {
      this.phase = "finished";
      this.isDraw = true;
      this.winnerId = null;
      return;
    }
    if (alive.length === 1) {
      this.phase = "finished";
      this.winnerId = alive[0].id;
      return;
    }
    const starter = this.playerById(starterCandidateId).alive ? starterCandidateId : this.nextAliveAfter(starterCandidateId);
    if (this.config.kamikazeEnabled) {
      const candidates = alive.filter((p) => p.diceCount === 1 && !p.kamikazeOfferedOnce);
      if (candidates.length === 1) {
        this.phase = "kamikazeOffer";
        this.kamikazeOfferPlayerId = candidates[0].id;
        this._pendingStarterId = starter;
        return;
      }
    }
    this._beginRound(starter);
  }
};

// src/bots.js
function comb(n, k) {
  if (k < 0 || k > n) return 0;
  const kk = k > n - k ? n - k : k;
  let r = 1;
  for (let i = 0; i < kk; i++) r = r * (n - i) / (i + 1);
  return r;
}
function binomialPmf(n, k, p) {
  if (k < 0 || k > n) return 0;
  return comb(n, k) * Math.pow(p, k) * Math.pow(1 - p, n - k);
}
function probabilityAtLeast(n, needed, p) {
  if (needed <= 0) return 1;
  if (needed > n) return 0;
  let s = 0;
  for (let k = needed; k <= n; k++) s += binomialPmf(n, k, p);
  return s;
}
function probabilityExactly(n, needed, p) {
  if (needed < 0 || needed > n) return 0;
  return binomialPmf(n, needed, p);
}
var PARAMS = {
  facil: { dudo: 0.3, calzo: 0.45, bluff: 0.05 },
  media: { dudo: 0.38, calzo: 0.3, bluff: 0.08 },
  dificil: { dudo: 0.32, calzo: 0.22, bluff: 0.15 }
};
var BotBrain = class {
  constructor(difficulty = "media", rng = Math.random) {
    this.difficulty = PARAMS[difficulty] ? difficulty : "media";
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
      if (!(this.difficulty === "facil" && this.rng() < 0.5)) {
        return { type: "dudoPaso", reason: "Ese Paso me huele falso." };
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
    if (ctx.canCalzo && probExact >= this.params.calzo) return { type: "calzo", reason: "Para m\xED es exacto." };
    if (ctx.canPaso && isPasoHand(ctx.ownHand) && probTrue < 0.75 && this.difficulty !== "facil") {
      return { type: "paso", reason: "Tengo el Paso." };
    }
    const noise = this.difficulty === "facil" ? (this.rng() - 0.5) * 0.2 : 0;
    if (probTrue < this.params.dudo + noise) return { type: "dudo", reason: `No alcanza: dudo.` };
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
    const unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
    const p = this.matchP(bestFace, ctx.config);
    let qty = bestCount + Math.round(unknown * p * 0.5);
    qty = Math.max(1, Math.min(qty, ctx.totalDiceInPlay));
    if (this.difficulty === "facil" && this.rng() < 0.25) {
      qty = Math.min(1 + Math.floor(this.rng() * 3), ctx.totalDiceInPlay);
      bestFace = 2 + Math.floor(this.rng() * 5);
    }
    return { type: "bid", bid: { quantity: qty, face: bestFace }, reason: "Parto con mi pinta fuerte." };
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
    if (!candidates.length) return { type: "dudo", reason: "Sin buena subida: dudo." };
    const probOf = (b) => {
      const p = this.matchP(b.face, ctx.config);
      const unknown = ctx.totalDiceInPlay - ctx.ownHand.length;
      const own = this.ownMatches(ctx.ownHand, b.face, ctx.config);
      return probabilityAtLeast(unknown, b.quantity - own, p);
    };
    candidates.sort((a, b) => probOf(b) - probOf(a));
    const best = candidates[0];
    const bluff = this.rng() < this.params.bluff;
    if (probOf(best) < 0.35 && !bluff) return { type: "dudo", reason: "No me convence: dudo." };
    return { type: "bid", bid: best, reason: `Tengo apoyo para subir.` };
  }
  shouldAcceptKamikaze(ctx) {
    const others = ctx.totalDiceInPlay - (ctx.diceCounts[ctx.selfId] ?? 1);
    if (this.difficulty === "facil") return this.rng() < 0.3;
    return others >= 3;
  }
  chooseKamikazeFace() {
    return 1 + Math.floor(this.rng() * 6);
  }
};
function botContext(engine, botId, { canPaso }) {
  return {
    selfId: botId,
    ownHand: engine.handOf(botId),
    currentBid: engine.currentBid,
    totalDiceInPlay: engine.totalDiceInPlay,
    diceCounts: Object.fromEntries(engine.players.map((p) => [p.id, p.diceCount])),
    pendingPasoPlayerId: engine.pendingPasoPlayerId,
    canCalzo: engine.canCalzoNow,
    canPaso,
    config: engine.config
  };
}

// src/manager.js
var CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
var BOT_NAMES = ["El Guat\xF3n", "La Cuca", "Don Chalo", "La Pituca", "El Huaso", "La Rusa", "El Flaco", "La Morocha", "Don Lucho", "El Pije", "La Juanita", "El Rucio"];
var CONFIG_KEYS = [
  "wildcardsEnabled",
  "acesRuleEnabled",
  "pasoEnabled",
  "kamikazeEnabled",
  "calzoEnabled",
  "calzoMinFraction",
  "maxPasosPerPlayerPerRound",
  "pasoAsFirstPlayAllowed",
  "pasoTwiceInARowAllowed",
  "dicePerPlayer",
  "turnTimerSeconds"
];
function makeCode(rooms, len = 5) {
  while (true) {
    let code = "";
    for (let i = 0; i < len; i++) code += CODE_ALPHABET[randomInt2(CODE_ALPHABET.length)];
    if (!rooms.has(code)) return code;
  }
}
function cleanNickname(v) {
  const s = typeof v === "string" ? v.trim() : "";
  return s.length >= 1 && s.length <= 16 ? s : null;
}
function cleanConfigOverrides(raw) {
  const out = {};
  if (raw && typeof raw === "object") {
    for (const k of CONFIG_KEYS) {
      if (raw[k] !== void 0) out[k] = raw[k];
    }
  }
  if (out.dicePerPlayer !== void 0 && (!Number.isInteger(out.dicePerPlayer) || out.dicePerPlayer < 2 || out.dicePerPlayer > 5)) {
    throw new IllegalMove("config_invalida", "dicePerPlayer debe ser 2..5");
  }
  if (out.turnTimerSeconds !== void 0 && (!Number.isFinite(out.turnTimerSeconds) || out.turnTimerSeconds < 5 || out.turnTimerSeconds > 180)) {
    throw new IllegalMove("config_invalida", "turnTimerSeconds debe ser 5..180");
  }
  return out;
}
function createRoomManager(options = {}) {
  const botDelayMs = options.botDelayMs ?? 1800;
  const turnTimeoutMs = options.turnTimeoutMs ?? null;
  const reconnectGraceMs = options.reconnectGraceMs ?? 6e4;
  const rollerFactory = options.rollerFactory ?? (() => new RandomDiceRoller());
  const notifier = options.notifier ?? (() => {
  });
  const STAKES = [100, 250, 500, 1e3, 2500];
  const WELCOME_COINS = 5e3;
  const _memWallets = /* @__PURE__ */ new Map();
  const wallet = options.wallet ?? {
    get: (t) => _memWallets.get(t),
    set: (t, b) => _memWallets.set(t, b)
  };
  function cleanStake(v) {
    const n = Number(v);
    return STAKES.includes(n) ? n : 500;
  }
  function cleanWalletToken(v) {
    const t = typeof v === "string" ? v.trim() : "";
    return t.length >= 8 && t.length <= 64 ? t : null;
  }
  function ensureBalance(token) {
    let b = wallet.get(token);
    if (typeof b !== "number") {
      b = WELCOME_COINS;
      wallet.set(token, b);
    }
    return b;
  }
  function sendBalance(seat) {
    if (seat && seat.walletToken) {
      sendSeat(seat, { type: "balance", balance: ensureBalance(seat.walletToken) });
    }
  }
  const rooms = /* @__PURE__ */ new Map();
  function send(ws, obj) {
    if (ws && ws.open) {
      try {
        ws.sendText(JSON.stringify(obj));
      } catch {
      }
    }
  }
  function sendSeat(seat, obj) {
    if (seat && !seat.isBot) send(seat.ws, obj);
  }
  function broadcast(room, obj) {
    for (const seat of room.seats) sendSeat(seat, obj);
  }
  function publicState(room) {
    const e = room.engine;
    if (!e) return null;
    return {
      phase: e.phase,
      round: e.roundNumber,
      currentBid: e.currentBid,
      lastBidderId: e.lastBidderId,
      currentPlayerId: e.currentPlayerId,
      pendingPasoPlayerId: e.pendingPasoPlayerId,
      kamikazeOfferPlayerId: e.kamikazeOfferPlayerId,
      kamikazeActivatorId: e.kamikazeActivatorId,
      canCalzo: e.canCalzoNow,
      calzoThresholdDice: e.calzoThresholdDice,
      totalDiceInPlay: e.totalDiceInPlay,
      winnerId: e.winnerId,
      isDraw: e.isDraw,
      stake: room.stake ?? 0,
      pot: (room.stake ?? 0) * e.players.length,
      players: e.players.map((p) => {
        const seat = room.seatById(p.id);
        return {
          id: p.id,
          nickname: seat?.nickname ?? p.name,
          isBot: seat?.isBot ?? false,
          connected: seat?.connected ?? false,
          dcDeadline: seat?.dcDeadline ?? null,
          micOn: seat?.micOn ?? false,
          diceCount: p.diceCount,
          eliminated: p.eliminated
        };
      }),
      turnEndsAt: room.turnEndsAt ?? null,
      events: e.roundHistory.map((ev) => ({
        round: ev.round,
        playerId: ev.playerId,
        type: ev.type,
        bid: ev.bid
      }))
    };
  }
  function musicSnapshot(room) {
    const m = room.music;
    const humans = room.seats.filter((x) => !x.isBot).length;
    return {
      djId: m.djId,
      current: m.current ? { ...m.current } : null,
      queue: m.queue.map((t) => ({ ...t })),
      skipVotes: m.skipVotes.length,
      skipNeeded: Math.floor(Math.max(humans, 1) / 2) + 1,
      sentAt: Date.now()
    };
  }
  function broadcastMusic(room) {
    broadcast(room, { type: "music_state", music: musicSnapshot(room) });
  }
  function advanceMusic(room) {
    const m = room.music;
    const next = m.queue.shift() ?? null;
    m.current = next ? { ...next, startedAt: Date.now(), pausedAt: null } : null;
    m.skipVotes = [];
    m.lastAdvanceAt = Date.now();
    broadcastMusic(room);
  }
  function cleanTrack(msg) {
    const videoId = String(msg.videoId ?? "");
    if (!/^[A-Za-z0-9_-]{6,20}$/.test(videoId)) return null;
    const title = String(msg.title ?? "Sin t\xEDtulo").slice(0, 140);
    const channel = String(msg.channel ?? "").slice(0, 80);
    const thumb = String(msg.thumb ?? "").slice(0, 300);
    let durationSec = Number(msg.durationSec ?? 0);
    if (!Number.isFinite(durationSec) || durationSec < 0) durationSec = 0;
    if (durationSec > 7200) durationSec = 7200;
    return { videoId, title, channel, thumb, durationSec };
  }
  function broadcastState(room) {
    const state = publicState(room);
    if (state) broadcast(room, { type: "state", state });
  }
  function broadcastLobby(room) {
    for (const seat of room.seats) {
      if (seat.isBot) continue;
      sendSeat(seat, {
        type: "lobby",
        code: room.code,
        hostId: room.hostId,
        status: room.status,
        stake: room.stake ?? 0,
        myBalance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
        players: room.seats.map((x) => ({
          id: x.id,
          nickname: x.nickname,
          isBot: x.isBot,
          ready: x.ready,
          connected: x.connected,
          micOn: !!x.micOn,
          balance: x.walletToken ? ensureBalance(x.walletToken) : null
        }))
      });
    }
  }
  function dealHandsIfNeeded(room) {
    const e = room.engine;
    if (!e || e.phase !== "playing") return;
    if (room.handDealtForRound === e.roundNumber) return;
    room.handDealtForRound = e.roundNumber;
    for (const seat of room.seats) {
      if (!seat.isBot && seat.connected) {
        sendSeat(seat, { type: "your_hand", round: e.roundNumber, dice: e.handOf(seat.id) });
      }
    }
  }
  function currentActor(room) {
    const e = room.engine;
    if (!e) return null;
    if (e.phase === "playing") return e.currentPlayerId;
    if (e.phase === "kamikazeOffer") return e.kamikazeOfferPlayerId;
    if (e.phase === "kamikazeChoice") return e.kamikazeActivatorId;
    return null;
  }
  function pasoEligible(e, playerId) {
    const p = e.playerById(playerId);
    return e.config.pasoEnabled && p.diceCount === e.config.dicePerPlayer && p.diceCount === 5 && e.roundHistory.length > 0;
  }
  function clearTimers(room) {
    if (room.turnTimer) clearTimeout(room.turnTimer);
    if (room.botTimer) clearTimeout(room.botTimer);
    room.turnTimer = null;
    room.botTimer = null;
    room.turnEndsAt = null;
  }
  function afterChange(room, resolution) {
    if (resolution) broadcast(room, { type: "resolution", resolution });
    broadcastState(room);
    {
      const e2 = room.engine;
      if (e2 && e2.phase === "playing" && e2.currentPlayerId && e2.roundNumber !== room._lastRoundNotice) {
        room._lastRoundNotice = e2.roundNumber;
        const seat = room.seats.find((x) => x.id === e2.currentPlayerId);
        const res = e2.lastResolution;
        let why = "sigue la ronda";
        if (!res) why = "sali\xF3 en el sorteo";
        else if (res.type === "kamikaze") why = "activ\xF3 el Kamikaze";
        else if (res.type === "abandono") why = "el que no jugaba qued\xF3 eliminado";
        else if (res.loserId === e2.currentPlayerId) why = "perdi\xF3 un dado";
        else if (res.gainerId === e2.currentPlayerId) why = "calz\xF3 justo";
        broadcast(room, { type: "notice", kind: "starter", text: `Ronda ${e2.roundNumber}: parte ${seat ? seat.nickname : ""} (${why})` });
      }
    }
    dealHandsIfNeeded(room);
    const e = room.engine;
    if (e && e.phase === "finished") {
      clearTimers(room);
      room.status = "finished";
      settleCoins(room);
      broadcast(room, {
        type: "game_over",
        winnerId: e.winnerId,
        isDraw: e.isDraw,
        pot: (room.stake ?? 0) * e.players.length,
        stake: room.stake ?? 0
      });
      maybeCleanupRoom(room);
      return;
    }
    scheduleDrive(room);
  }
  function settleCoins(room) {
    if (room.coinsSettled || !room.escrow) return;
    room.coinsSettled = true;
    const e = room.engine;
    const pot = (room.stake ?? 0) * e.players.length;
    for (const seat of room.seats) {
      if (!seat.walletToken) continue;
      if (e.isDraw) {
        wallet.set(seat.walletToken, ensureBalance(seat.walletToken) + room.escrow);
      } else if (seat.id === e.winnerId) {
        wallet.set(seat.walletToken, ensureBalance(seat.walletToken) + pot);
      }
      sendBalance(seat);
    }
    room.escrow = 0;
  }
  function scheduleDrive(room) {
    clearTimers(room);
    const e = room.engine;
    if (!e || e.phase === "finished" || room.status !== "playing") return;
    const actor = currentActor(room);
    if (!actor) return;
    const seat = room.seatById(actor);
    if (!seat) return;
    if (seat.isBot || seat.auto) {
      room.botTimer = setTimeout(() => driveSeat(room, actor, {}), botDelayMs + Math.floor(Math.random() * botDelayMs * 0.5));
    } else {
      notifier({ kind: "your_turn", roomCode: room.code, playerId: actor });
      const ms = turnTimeoutMs ?? e.config.turnTimerSeconds * 1e3;
      room.turnEndsAt = Date.now() + ms;
      room.turnTimer = setTimeout(() => {
        seat.strikes = (seat.strikes ?? 0) + 1;
        if (seat.strikes >= 3) {
          seat.strikes = 0;
          broadcast(room, { type: "notice", kind: "afk_eliminated", playerId: actor });
          try {
            const res = e.forceEliminate(actor);
            afterChange(room, res);
          } catch {
            driveSeat(room, actor, { asTimeout: true });
          }
        } else {
          broadcast(room, { type: "notice", kind: "turn_timeout", playerId: actor, strikes: seat.strikes });
          driveSeat(room, actor, { asTimeout: true });
        }
      }, ms);
    }
  }
  function driveSeat(room, seatId, { asTimeout = false }) {
    const e = room.engine;
    if (!e) return;
    const seat = room.seatById(seatId);
    if (!seat) return;
    const brain = new BotBrain(seat.isBot ? seat.difficulty : "media");
    try {
      if (e.phase === "playing" && e.currentPlayerId === seatId) {
        const action = brain.decide(botContext(e, seatId, { canPaso: pasoEligible(e, seatId) }));
        applyAction(room, seatId, action, { fromBot: true });
      } else if (e.phase === "kamikazeOffer" && e.kamikazeOfferPlayerId === seatId) {
        let accept = false;
        if (!asTimeout || seat.isBot) {
          accept = brain.shouldAcceptKamikaze(botContext(e, seatId, { canPaso: false }));
        }
        e.respondKamikaze(seatId, accept);
        afterChange(room, null);
      } else if (e.phase === "kamikazeChoice" && e.kamikazeActivatorId === seatId) {
        const res = e.chooseKamikazeFace(seatId, brain.chooseKamikazeFace());
        afterChange(room, res);
      }
    } catch {
      try {
        if (e.phase === "playing" && e.currentPlayerId === seatId) {
          const res = e.currentBid ? e.dudo(seatId) : (e.bid(seatId, { quantity: 1, face: 2 }), null);
          afterChange(room, res ?? null);
        }
      } catch {
      }
    }
  }
  function applyAction(room, playerId, msg, { fromBot = false } = {}) {
    const e = room.engine;
    const seat = room.seatById(playerId);
    try {
      let res = null;
      switch (msg.type) {
        case "bid":
          e.bid(playerId, msg.bid);
          break;
        case "paso":
          e.paso(playerId);
          break;
        case "dudo":
          res = e.dudo(playerId);
          break;
        case "calzo":
          res = e.calzo(playerId);
          break;
        case "dudoPaso":
          res = e.dudoPaso(playerId);
          break;
        case "calzoPaso":
          res = e.calzoPaso(playerId);
          break;
        default:
          throw new IllegalMove("accion_invalida", `acci\xF3n desconocida: ${msg.type}`);
      }
      if (!fromBot && seat) seat.strikes = 0;
      afterChange(room, res);
    } catch (err) {
      if (fromBot) throw err;
      sendSeat(seat, {
        type: "error",
        code: err instanceof IllegalMove ? err.code : "error_interno",
        message: err.message
      });
    }
  }
  function maybeCleanupRoom(room) {
    const anyHumanConnected = room.seats.some((s) => !s.isBot && s.connected);
    if (!anyHumanConnected && room.status !== "playing") {
      clearTimers(room);
      rooms.delete(room.code);
    }
  }
  function requireRoom(ws, ctx) {
    const room = ctx.roomCode ? rooms.get(ctx.roomCode) : null;
    if (!room) {
      send(ws, { type: "error", code: "sin_sala", message: "no est\xE1s en una sala" });
      return null;
    }
    return room;
  }
  function handleMessage(ws, ctx, msg) {
    switch (msg.type) {
      case "ping":
        send(ws, { type: "pong" });
        return;
      case "room_status": {
        const code = String(msg.code ?? "").toUpperCase();
        const room = rooms.get(code);
        if (!room) {
          send(ws, { type: "room_status", code, exists: false, member: false });
          return;
        }
        const wt = cleanWalletToken(msg.walletToken);
        const seat = wt ? room.seats.find((s) => !s.isBot && s.walletToken === wt) : null;
        send(ws, {
          type: "room_status",
          code: room.code,
          exists: true,
          phase: room.status,
          member: !!seat,
          connected: seat ? seat.connected : false,
          stake: room.stake
        });
        return;
      }
      case "create_room": {
        const nickname = cleanNickname(msg.nickname);
        if (!nickname) throw new IllegalMove("apodo_invalido", "apodo de 1 a 16 caracteres");
        const config = configForPreset(msg.preset ?? "completo", cleanConfigOverrides(msg.config));
        const code = makeCode(rooms, 5);
        const seat = {
          id: randomUUID(),
          nickname,
          isBot: false,
          difficulty: null,
          ready: true,
          connected: true,
          deviceToken: randomUUID(),
          ws,
          auto: false,
          strikes: 0,
          walletToken: cleanWalletToken(msg.walletToken)
        };
        const room = {
          code,
          hostId: seat.id,
          seats: [seat],
          engine: null,
          config,
          status: "lobby",
          turnTimer: null,
          botTimer: null,
          turnEndsAt: null,
          handDealtForRound: 0,
          stake: cleanStake(msg.stake),
          escrow: 0,
          coinsSettled: false,
          music: { djId: null, current: null, queue: [], skipVotes: [], lastAdvanceAt: 0 },
          seatById(id) {
            return this.seats.find((s) => s.id === id) ?? null;
          }
        };
        rooms.set(code, room);
        ctx.roomCode = code;
        ctx.playerId = seat.id;
        send(ws, {
          type: "room_created",
          code,
          playerId: seat.id,
          deviceToken: seat.deviceToken,
          balance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
          stake: room.stake
        });
        broadcastLobby(room);
        send(ws, { type: "music_state", music: musicSnapshot(room) });
        return;
      }
      case "join_room": {
        const nickname = cleanNickname(msg.nickname);
        if (!nickname) throw new IllegalMove("apodo_invalido", "apodo de 1 a 16 caracteres");
        const room = rooms.get(String(msg.code ?? "").toUpperCase());
        if (!room) throw new IllegalMove("sala_no_existe", "ese c\xF3digo no existe");
        if (room.status !== "lobby") throw new IllegalMove("sala_en_partida", "la partida ya empez\xF3");
        if (room.seats.length >= room.config.maxPlayers) {
          throw new IllegalMove("sala_llena", "la sala est\xE1 llena");
        }
        const seat = {
          id: randomUUID(),
          nickname,
          isBot: false,
          difficulty: null,
          ready: false,
          connected: true,
          deviceToken: randomUUID(),
          ws,
          auto: false,
          strikes: 0,
          walletToken: cleanWalletToken(msg.walletToken)
        };
        room.seats.push(seat);
        ctx.roomCode = room.code;
        ctx.playerId = seat.id;
        send(ws, {
          type: "joined",
          code: room.code,
          playerId: seat.id,
          deviceToken: seat.deviceToken,
          balance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
          stake: room.stake
        });
        broadcastLobby(room);
        send(ws, { type: "music_state", music: musicSnapshot(room) });
        return;
      }
      case "rejoin": {
        const room = rooms.get(String(msg.code ?? "").toUpperCase());
        if (!room) throw new IllegalMove("sala_no_existe", "ese c\xF3digo no existe");
        let seat = room.seatById(String(msg.playerId ?? ""));
        if (!seat || seat.isBot || seat.deviceToken !== msg.deviceToken) {
          const wt = cleanWalletToken(msg.walletToken);
          const byWallet = wt ? room.seats.find(
            (s) => !s.isBot && s.walletToken === wt && !s.connected
          ) : null;
          if (!byWallet) {
            throw new IllegalMove("token_invalido", "no se pudo verificar tu lugar en la sala");
          }
          seat = byWallet;
        }
        seat.ws = ws;
        seat.connected = true;
        seat.auto = false;
        seat.strikes = 0;
        cancelDisconnect(room, seat);
        ctx.roomCode = room.code;
        ctx.playerId = seat.id;
        send(ws, {
          type: "rejoined",
          code: room.code,
          playerId: seat.id,
          deviceToken: seat.deviceToken,
          balance: seat.walletToken ? ensureBalance(seat.walletToken) : null
        });
        send(ws, { type: "music_state", music: musicSnapshot(room) });
        if (room.status === "lobby") {
          broadcastLobby(room);
        } else {
          broadcastState(room);
          if (room.engine && room.engine.phase === "playing") {
            sendSeat(seat, {
              type: "your_hand",
              round: room.engine.roundNumber,
              dice: room.engine.handOf(seat.id)
            });
          }
          scheduleDrive(room);
        }
        return;
      }
      case "set_ready": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (seat) seat.ready = !!msg.ready;
        broadcastLobby(room);
        return;
      }
      case "set_nickname": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.status !== "lobby") {
          throw new IllegalMove("en_partida", "el nombre se cambia en la sala, antes de partir");
        }
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const nickname = cleanNickname(msg.nickname);
        if (!nickname) throw new IllegalMove("apodo_invalido", "apodo de 1 a 16 caracteres");
        seat.nickname = nickname;
        broadcastLobby(room);
        return;
      }
      case "start_game": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.hostId !== ctx.playerId) {
          throw new IllegalMove("no_es_anfitrion", "solo el anfitri\xF3n parte la partida");
        }
        if (room.status !== "lobby") throw new IllegalMove("fase_invalida", "la partida ya empez\xF3");
        if (room.seats.some((s) => !s.ready)) {
          throw new IllegalMove("no_todos_listos", "faltan jugadores por estar listos");
        }
        const fill = Number.isInteger(msg.fillBots) ? msg.fillBots : 0;
        if (fill < 0 || fill > 11) throw new IllegalMove("bots_invalidos", "fillBots debe ser 0..11");
        const total = room.seats.length + fill;
        if (total < room.config.minPlayers) {
          throw new IllegalMove("jugadores_insuficientes", `se necesitan al menos ${room.config.minPlayers} jugadores (hay ${total})`);
        }
        if (total > room.config.maxPlayers) {
          throw new IllegalMove("sala_llena", `m\xE1ximo ${room.config.maxPlayers} jugadores`);
        }
        for (const seat of room.seats) {
          if (!seat.walletToken) continue;
          const bal = ensureBalance(seat.walletToken);
          if (bal < room.stake) {
            throw new IllegalMove(
              "saldo_insuficiente",
              `${seat.nickname} no tiene monedas para la apuesta de ${room.stake} (tiene ${bal})`
            );
          }
        }
        for (const seat of room.seats) {
          if (!seat.walletToken) continue;
          wallet.set(seat.walletToken, ensureBalance(seat.walletToken) - room.stake);
          sendBalance(seat);
        }
        room.escrow = room.stake;
        room.coinsSettled = false;
        const difficulty = ["facil", "media", "dificil"].includes(msg.botDifficulty) ? msg.botDifficulty : "media";
        for (let i = 0; i < fill; i++) {
          room.seats.push({
            id: randomUUID(),
            nickname: `Bot ${BOT_NAMES[i % BOT_NAMES.length]}`,
            isBot: true,
            difficulty,
            ready: true,
            connected: true,
            deviceToken: null,
            ws: null,
            auto: true
          });
        }
        room.engine = new GameEngine({
          config: room.config,
          roller: rollerFactory(),
          players: room.seats.map((s) => ({ id: s.id, name: s.nickname }))
        });
        const starterId = room.engine.startGame();
        room.status = "playing";
        const starterSeat = room.seats.find((x) => x.id === starterId);
        broadcast(room, { type: "notice", kind: "starter", text: `Sorteo: parte ${starterSeat ? starterSeat.nickname : ""}` });
        room._lastRoundNotice = room.engine.roundNumber;
        room.handDealtForRound = 0;
        broadcast(room, { type: "game_started", code: room.code });
        afterChange(room, null);
        return;
      }
      case "mic": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        seat.micOn = !!msg.on;
        broadcast(room, { type: "mic", playerId: seat.id, on: seat.micOn });
        return;
      }
      case "voice_signal": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const target = room.seatById(String(msg.to ?? ""));
        if (!target || target.isBot || target.id === ctx.playerId) return;
        if (!msg.data || typeof msg.data !== "object") return;
        sendSeat(target, { type: "voice_signal", from: ctx.playerId, data: msg.data });
        return;
      }
      case "music_claim": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const djSeat = room.music.djId ? room.seatById(room.music.djId) : null;
        if (!room.music.djId || !djSeat || !djSeat.connected || room.music.djId === seat.id) {
          room.music.djId = seat.id;
          broadcastMusic(room);
        }
        return;
      }
      case "music_release": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.music.djId === ctx.playerId) {
          room.music.djId = null;
          broadcastMusic(room);
        }
        return;
      }
      case "music_add": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const track = cleanTrack(msg);
        if (!track) return;
        const item = { ...track, byId: seat.id, byName: seat.nickname };
        if (!room.music.current) {
          room.music.current = { ...item, startedAt: Date.now(), pausedAt: null };
          room.music.skipVotes = [];
          room.music.lastAdvanceAt = Date.now();
        } else if (room.music.queue.length < 30) {
          room.music.queue.push(item);
        } else {
          return;
        }
        broadcastMusic(room);
        return;
      }
      case "music_remove": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const idx = Number(msg.index);
        const item = room.music.queue[idx];
        if (!item) return;
        if (room.music.djId === seat.id || item.byId === seat.id) {
          room.music.queue.splice(idx, 1);
          broadcastMusic(room);
        }
        return;
      }
      case "music_pause": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.music.djId !== ctx.playerId) return;
        const cur = room.music.current;
        if (cur && !cur.pausedAt) {
          cur.pausedAt = Date.now();
          broadcastMusic(room);
        }
        return;
      }
      case "music_play": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.music.djId !== ctx.playerId) return;
        const cur = room.music.current;
        if (cur && cur.pausedAt) {
          cur.startedAt += Date.now() - cur.pausedAt;
          cur.pausedAt = null;
          broadcastMusic(room);
        }
        return;
      }
      case "music_next": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.music.djId !== ctx.playerId) return;
        advanceMusic(room);
        return;
      }
      case "music_play_now": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        if (room.music.djId !== seat.id) return;
        let item = null;
        if (msg.videoId) {
          const idx = room.music.queue.findIndex(
            (t) => t.videoId === String(msg.videoId)
          );
          if (idx >= 0) item = room.music.queue.splice(idx, 1)[0];
        }
        if (!item) {
          const track = cleanTrack(msg);
          if (!track) return;
          item = { ...track, byId: seat.id, byName: seat.nickname };
          room.music.queue = room.music.queue.filter(
            (t) => t.videoId !== item.videoId
          );
        }
        room.music.current = { ...item, startedAt: Date.now(), pausedAt: null };
        room.music.skipVotes = [];
        room.music.lastAdvanceAt = Date.now();
        broadcastMusic(room);
        return;
      }
      case "music_vote_skip": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot || !room.music.current) return;
        if (!room.music.skipVotes.includes(seat.id)) {
          room.music.skipVotes.push(seat.id);
        }
        const snap = musicSnapshot(room);
        if (snap.skipVotes >= snap.skipNeeded) {
          advanceMusic(room);
        } else {
          broadcastMusic(room);
        }
        return;
      }
      case "music_ended": {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot || !room.music.current) return;
        const now = Date.now();
        if (seat.id === room.music.djId || now - room.music.lastAdvanceAt > 5e3 && now - room.music.current.startedAt > 8e3) {
          advanceMusic(room);
        }
        return;
      }
      case "action": {
        const room = requireRoom(ws, ctx);
        if (!room || room.status !== "playing") return;
        applyAction(room, ctx.playerId, msg.action ?? {}, {});
        return;
      }
      case "kamikaze_response": {
        const room = requireRoom(ws, ctx);
        if (!room || !room.engine) return;
        try {
          room.engine.respondKamikaze(ctx.playerId, !!msg.accept);
          const seat = room.seatById(ctx.playerId);
          if (seat) seat.strikes = 0;
          afterChange(room, null);
        } catch (err) {
          sendSeat(room.seatById(ctx.playerId), {
            type: "error",
            code: err instanceof IllegalMove ? err.code : "error_interno",
            message: err.message
          });
        }
        return;
      }
      case "kamikaze_face": {
        const room = requireRoom(ws, ctx);
        if (!room || !room.engine) return;
        try {
          const res = room.engine.chooseKamikazeFace(ctx.playerId, msg.face);
          const seat = room.seatById(ctx.playerId);
          if (seat) seat.strikes = 0;
          afterChange(room, res);
        } catch (err) {
          sendSeat(room.seatById(ctx.playerId), {
            type: "error",
            code: err instanceof IllegalMove ? err.code : "error_interno",
            message: err.message
          });
        }
        return;
      }
      default:
        send(ws, { type: "error", code: "mensaje_invalido", message: `tipo desconocido: ${msg.type}` });
    }
  }
  function handleOpen() {
    return { roomCode: null, playerId: null };
  }
  function handleRaw(ws, ctx, raw) {
    let msg;
    try {
      msg = JSON.parse(typeof raw === "string" ? raw : raw.toString());
    } catch {
      send(ws, { type: "error", code: "json_invalido", message: "mensaje no es JSON v\xE1lido" });
      return;
    }
    try {
      handleMessage(ws, ctx, msg);
    } catch (err) {
      send(ws, {
        type: "error",
        code: err instanceof IllegalMove ? err.code : "error_interno",
        message: err.message
      });
    }
  }
  function handleClose(ws, ctx) {
    const room = ctx.roomCode ? rooms.get(ctx.roomCode) : null;
    if (!room) return;
    const seat = room.seatById(ctx.playerId);
    if (!seat || seat.ws !== ws) return;
    seat.ws = null;
    seat.connected = false;
    if (seat.micOn) {
      seat.micOn = false;
      broadcast(room, { type: "mic", playerId: seat.id, on: false });
    }
    let musicChanged = false;
    if (room.music.djId === seat.id) {
      room.music.djId = null;
      musicChanged = true;
    }
    const voteIdx = room.music.skipVotes.indexOf(seat.id);
    if (voteIdx >= 0) {
      room.music.skipVotes.splice(voteIdx, 1);
      musicChanged = true;
    }
    if (room.status === "lobby") {
      room.seats = room.seats.filter((s) => s.id !== seat.id);
      if (room.hostId === seat.id) {
        const nextHost = room.seats.find((s) => !s.isBot);
        if (nextHost) room.hostId = nextHost.id;
      }
      if (!room.seats.length) {
        rooms.delete(room.code);
        return;
      }
      broadcastLobby(room);
      if (musicChanged) broadcastMusic(room);
    } else {
      seat.auto = true;
      if (room.status === "playing" && room.engine && room.engine.phase !== "finished") {
        seat.dcDeadline = Date.now() + reconnectGraceMs;
        broadcast(room, {
          type: "notice",
          kind: "player_left",
          playerId: seat.id,
          seconds: Math.round(reconnectGraceMs / 1e3)
        });
        if (seat.dcTimer) clearTimeout(seat.dcTimer);
        seat.dcTimer = setTimeout(() => eliminateDisconnected(room, seat), reconnectGraceMs);
        if (seat.dcTimer && typeof seat.dcTimer.unref === "function") seat.dcTimer.unref();
      }
      notifier({ kind: "player_disconnected", roomCode: room.code, playerId: seat.id, graceMs: reconnectGraceMs });
      broadcastState(room);
      if (musicChanged) broadcastMusic(room);
      scheduleDrive(room);
      const t = setTimeout(() => maybeCleanupRoom(room), reconnectGraceMs + 1e3);
      if (t && typeof t.unref === "function") t.unref();
    }
  }
  function cancelDisconnect(room, seat) {
    if (!seat.dcDeadline) return;
    if (seat.dcTimer) {
      clearTimeout(seat.dcTimer);
      seat.dcTimer = null;
    }
    seat.dcDeadline = null;
    broadcast(room, { type: "notice", kind: "player_returned", playerId: seat.id });
  }
  function eliminateDisconnected(room, seat) {
    seat.dcTimer = null;
    seat.dcDeadline = null;
    if (!rooms.has(room.code) || room.status !== "playing") return;
    if (seat.connected || seat.isBot) return;
    const e = room.engine;
    if (!e || e.phase === "finished") return;
    const p = e.players.find((x) => x.id === seat.id);
    if (!p || p.eliminated) return;
    broadcast(room, { type: "notice", kind: "disconnect_eliminated", playerId: seat.id });
    try {
      const res = e.forceEliminate(seat.id);
      afterChange(room, res);
    } catch {
    }
  }
  function clearAll() {
    for (const room of rooms.values()) clearTimers(room);
  }
  return { rooms, handleOpen, handleRaw, handleClose, clearAll };
}

// do/worker.js
var CachoRooms = class {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this._wallets = /* @__PURE__ */ new Map();
    this.manager = createRoomManager({
      wallet: {
        get: (t) => this._wallets.get(t),
        set: (t, b) => {
          this._wallets.set(t, b);
          this._persistWallets();
        }
      }
    });
    state.blockConcurrencyWhile(async () => {
      try {
        const raw = await state.storage.get("wallets");
        if (raw) this._wallets = new Map(Object.entries(JSON.parse(raw)));
      } catch {
      }
    });
  }
  _persistWallets() {
    try {
      const obj = Object.fromEntries(this._wallets);
      this.state.storage.put("wallets", JSON.stringify(obj)).catch(() => {
      });
    } catch {
    }
  }
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return Response.json({ ok: true, rooms: this.manager.rooms.size, v: 3 });
    }
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Cacho server \u2014 se esperaba una conexi\xF3n WebSocket.\n", {
        status: 426,
        headers: { "content-type": "text/plain; charset=utf-8" }
      });
    }
    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    server.accept();
    const handle = {
      open: true,
      sendText(str) {
        try {
          server.send(str);
        } catch {
        }
      }
    };
    const ctx = this.manager.handleOpen();
    server.addEventListener("message", (ev) => {
      const data = typeof ev.data === "string" ? ev.data : new TextDecoder().decode(ev.data);
      this.manager.handleRaw(handle, ctx, data);
    });
    const onGone = () => {
      if (!handle.open) return;
      handle.open = false;
      this.manager.handleClose(handle, ctx);
    };
    server.addEventListener("close", onGone);
    server.addEventListener("error", onGone);
    return new Response(null, { status: 101, webSocket: client });
  }
};
var worker_default = {
  async fetch(request, env) {
    const stub = env.ROOMS.get(env.ROOMS.idFromName("global-v3"));
    return stub.fetch(request);
  }
};
export {
  CachoRooms,
  worker_default as default
};
