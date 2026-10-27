// Motor de Cacho en JS: puerto fiel de packages/cacho_engine (Dart).
// Mismas reglas fijadas, mismos códigos de error. El servidor es dueño de
// la única instancia; los clientes jamás reciben manos ajenas salvo en
// una resolución/revelación.
import { randomInt } from 'node:crypto';

export class IllegalMove extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

export const PINTAS = [null, 'As', 'Pato', 'Tren', 'Cuadra', 'Quinta', 'Sexta'];
export const bidToString = (b) => `${b.quantity} ${PINTAS[b.face]}`;

export function defaultConfig(overrides = {}) {
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
    maxPlayers: 6, // Máximo 6 por orden del usuario 26-oct 09:35 ("me equivoqué eran 6", reemplaza el 5 de la decisión 07:32).
    turnTimerSeconds: 60,
    ...overrides,
  };
}

export function configForPreset(preset, overrides = {}) {
  if (!preset || preset === 'completo') return defaultConfig(overrides);
  if (preset === 'clasico') {
    return defaultConfig({ pasoEnabled: false, kamikazeEnabled: false, ...overrides });
  }
  if (preset === 'custom') return defaultConfig(overrides);
  throw new IllegalMove('preset_invalido', `preset desconocido: ${preset}`);
}

export const calzoThreshold = (config, initialTotalDice) =>
  Math.ceil(initialTotalDice * config.calzoMinFraction);

// ---------- rodadores de dados ----------

export class RandomDiceRoller {
  rollDie() {
    return randomInt(1, 7);
  }
}

export class ScriptedDiceRoller {
  constructor(values) {
    this.q = [...values];
  }
  rollDie() {
    if (!this.q.length) throw new Error('ScriptedDiceRoller agotado');
    return this.q.shift();
  }
  addAll(v) {
    this.q.push(...v);
  }
  get remaining() {
    return this.q.length;
  }
}

/** PRNG determinista (mulberry32). SOLO para tests de integración. */
export class SeededDiceRoller {
  constructor(seed) {
    this.s = seed >>> 0;
  }
  next() {
    this.s = (this.s + 0x6d2b79f5) >>> 0;
    let t = this.s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  rollDie() {
    return Math.floor(this.next() * 6) + 1;
  }
}

// ---------- reglas puras ----------

/** Comodines efectivos: caen si la regla de ases está desactivada. */
export const wildcardsEffective = (config) =>
  config.wildcardsEnabled && config.acesRuleEnabled !== false;

export function raiseError(current, next, totalDiceInPlay, acesRuleEnabled = true) {
  if (!next || next.face < 1 || next.face > 6) return 'pinta_invalida';
  if (next.quantity < 1) return 'cantidad_invalida';
  if (next.quantity > totalDiceInPlay) return 'cantidad_supera_total';
  if (current == null) return next.face === 1 ? 'ases_para_partir' : null;
  // Sin regla de ases, los ases son una pinta más: manda la clásica.
  if (!acesRuleEnabled || (current.face !== 1 && next.face !== 1)) {
    if (next.quantity > current.quantity) return null;
    if (next.quantity === current.quantity && next.face > current.face) return null;
    return 'apuesta_no_supera';
  }
  if (current.face !== 1 && next.face === 1) {
    const minQty = Math.ceil(current.quantity / 2);
    return next.quantity >= minQty ? null : 'ases_mitad';
  }
  if (current.face === 1 && next.face !== 1) {
    const minQty = current.quantity * 2 + 1;
    return next.quantity >= minQty ? null : 'salida_ases_doble_mas_uno';
  }
  return next.quantity > current.quantity ? null : 'apuesta_no_supera';
}

export function countForBid(hands, bid, wildcardsEnabled) {
  let total = 0;
  for (const hand of hands) {
    for (const die of hand) {
      if (die === bid.face) total++;
      else if (wildcardsEnabled && bid.face !== 1 && die === 1) total++;
    }
  }
  return total;
}

export function isPasoHand(hand) {
  if (hand.length !== 5) return false;
  if (new Set(hand).size === 5) return true;
  const counts = {};
  for (const die of hand) counts[die] = (counts[die] ?? 0) + 1;
  const sorted = Object.values(counts).sort((a, b) => a - b);
  return sorted.length === 2 && sorted[0] === 2 && sorted[1] === 3;
}

// ---------- motor ----------

export class GameEngine {
  constructor({ config, roller, players }) {
    this.config = config;
    this.roller = roller;
    if (players.length < config.minPlayers || players.length > config.maxPlayers) {
      throw new Error(`jugadores fuera de rango: ${players.length}`);
    }
    if (new Set(players.map((p) => p.id)).size !== players.length) {
      throw new Error('ids de jugador duplicados');
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
      },
    }));
    this.initialTotalDice = players.length * config.dicePerPlayer;
    this.calzoThresholdDice = calzoThreshold(config, this.initialTotalDice);
    this.phase = 'lobby';
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
    // Sin umbral de dados desde el 24-oct (orden del usuario tras
    // probarlo): el umbral fijo dejaba el final de partida sin
    // Calzo. Paridad con el motor Dart. El 25-oct separó intento de
    // recuperación: el intento sigue siempre permitido; solo la
    // GANANCIA queda condicionada (ver calzoRecoveryAllowed).
    return this.config.calzoEnabled;
  }

  get calzoRecoveryAllowed() {
    // 25-oct, ejemplo del usuario: 20 iniciales, con 11+ se recupera,
    // con 10 o menos no. Condición ESTRICTA, medida ANTES de aplicar
    // ganancia/pérdida: totalActual * 2 > totalInicial. NO usar
    // calzoThreshold() (= ceil(inicial * 0.5)): para 20 daría 10.
    // Paridad con el motor Dart.
    return this.totalDiceInPlay * 2 > this.initialTotalDice;
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
    throw new Error('no quedan jugadores vivos');
  }

  startGame() {
    if (this.phase !== 'lobby') throw new IllegalMove('fase_invalida', 'la partida ya comenzó');
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
      p.hand = p.alive
        ? Array.from({ length: p.diceCount }, () => this.roller.rollDie())
        : [];
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
    this.phase = 'playing';
  }

  _requireTurn(playerId) {
    if (this.phase !== 'playing') throw new IllegalMove('fase_invalida', 'no hay ronda en curso');
    if (this.currentPlayerId !== playerId) {
      throw new IllegalMove('no_es_tu_turno', 'todavía no es tu turno');
    }
    const p = this.playerById(playerId);
    if (p.eliminated) throw new IllegalMove('jugador_eliminado', 'ese jugador ya salió');
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
    this.pendingPasoPlayerId = null; // el Paso pendiente queda firme
    this.currentBid = { quantity: next.quantity, face: next.face };
    this.lastBidderId = playerId;
    this._record(playerId, 'bid', this.currentBid);
    this._advanceTurn();
  }

  paso(playerId) {
    const p = this._requireTurn(playerId);
    if (!this.config.pasoEnabled) {
      throw new IllegalMove('paso_deshabilitado', 'el Paso no está activo en esta sala');
    }
    if (p.diceCount !== this.config.dicePerPlayer || p.diceCount !== 5) {
      throw new IllegalMove('paso_requiere_5_dados', 'solo puedes pasar con tus 5 dados completos');
    }
    if (this._actionsThisRound === 0 && !this.config.pasoAsFirstPlayAllowed) {
      throw new IllegalMove('paso_primera_jugada', 'no se puede pasar como primera jugada de la ronda');
    }
    if ((this._pasosThisRound[playerId] ?? 0) >= this.config.maxPasosPerPlayerPerRound) {
      throw new IllegalMove('paso_limite_ronda', 'ya usaste tu Paso de esta ronda');
    }
    if (!this.config.pasoTwiceInARowAllowed && this._lastActionThisRound[playerId] === 'paso') {
      throw new IllegalMove('paso_dos_veces_seguidas', 'no puedes pasar dos veces seguidas');
    }
    this.pendingPasoPlayerId = playerId;
    this._pasosThisRound[playerId] = (this._pasosThisRound[playerId] ?? 0) + 1;
    this._record(playerId, 'paso');
    this._advanceTurn();
  }

  dudo(playerId) {
    this._requireTurn(playerId);
    const bidNow = this.currentBid;
    if (!bidNow) throw new IllegalMove('sin_apuesta', 'no hay apuesta que dudar');
    this.pendingPasoPlayerId = null;
    const actual = countForBid(this.alivePlayers.map((p) => p.hand), bidNow, wildcardsEffective(this.config));
    const bidder = this.lastBidderId;
    const loser = actual >= bidNow.quantity ? playerId : bidder;
    const revealedHands = Object.fromEntries(this.alivePlayers.map((p) => [p.id, [...p.hand]]));
    this._record(playerId, 'dudo');
    this._applyLoss(loser);
    const res = { type: 'dudo', loserId: loser, gainerId: null, revealedHands, actualCount: actual, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    this._finishResolution(loser, res);
    return res;
  }

  calzo(playerId) {
    this._requireTurn(playerId);
    const bidNow = this.currentBid;
    if (!bidNow) throw new IllegalMove('sin_apuesta', 'no hay apuesta que calzar');
    if (!this.config.calzoEnabled) throw new IllegalMove('calzo_deshabilitado', 'el Calzo no está activo');
    this.pendingPasoPlayerId = null;
    const actual = countForBid(this.alivePlayers.map((p) => p.hand), bidNow, wildcardsEffective(this.config));
    const revealedHands = Object.fromEntries(this.alivePlayers.map((p) => [p.id, [...p.hand]]));
    this._record(playerId, 'calzo');
    const exact = actual === bidNow.quantity;
    // Total ANTES de aplicar ganancia/pérdida (25-oct).
    const recoveryAllowed = this.calzoRecoveryAllowed;
    let massLoserIds = [];
    if (exact) {
      if (this.playerById(playerId).diceCount >= this.config.dicePerPlayer &&
          recoveryAllowed) {
        // Calzo perfecto con los dados completos (regla del usuario,
        // 22-oct): todos los demás pierden un dado. C11 (decisión
        // 26-oct): el perfecto solo aplica cuando la recuperación está
        // permitida (totalActual × 2 > totalInicial, medido antes de
        // aplicar ganancia/pérdida). Con total bajo el perfecto queda
        // BLOQUEADO: nadie gana ni pierde, la ronda termina y el
        // calzador parte la siguiente.
        massLoserIds = this.alivePlayers.filter((p) => p.id !== playerId).map((p) => p.id);
        for (const id of massLoserIds) this._applyLoss(id);
      } else if (recoveryAllowed) {
        this._applyGain(playerId);
      }
      // Exacto sin recuperación: no gana ni pierde (25-oct).
    } else {
      this._applyLoss(playerId);
    }
    const res = { type: 'calzo', loserId: exact ? null : playerId, gainerId: exact && massLoserIds.length === 0 && recoveryAllowed ? playerId : null, revealedHands, actualCount: actual, kamikazeFace: null, kamikazeLosses: {}, massLoserIds, recoveryBlocked: exact && massLoserIds.length === 0 && !recoveryAllowed };
    this._finishResolution(playerId, res);
    return res;
  }

  dudoPaso(playerId) {
    this._requireTurn(playerId);
    const pasoId = this.pendingPasoPlayerId;
    if (!pasoId) throw new IllegalMove('sin_paso_pendiente', 'no hay Paso que dudar');
    const pasoPlayer = this.playerById(pasoId);
    const truth = isPasoHand(pasoPlayer.hand);
    const revealedHands = { [pasoId]: [...pasoPlayer.hand] };
    this._record(playerId, 'dudoPaso');
    const loser = truth ? playerId : pasoId;
    this._applyLoss(loser);
    const res = { type: 'dudoPaso', loserId: loser, gainerId: null, revealedHands, actualCount: null, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    this._finishResolution(loser, res);
    return res;
  }

  calzoPaso(playerId) {
    this._requireTurn(playerId);
    const pasoId = this.pendingPasoPlayerId;
    if (!pasoId) throw new IllegalMove('sin_paso_pendiente', 'no hay Paso que calzar');
    if (!this.config.calzoEnabled) throw new IllegalMove('calzo_deshabilitado', 'el Calzo no está activo');
    const pasoPlayer = this.playerById(pasoId);
    const truth = isPasoHand(pasoPlayer.hand);
    const revealedHands = { [pasoId]: [...pasoPlayer.hand] };
    this._record(playerId, 'calzoPaso');
    // Misma regla de recuperación que el Calzo (25-oct): total ANTES
    // de aplicar ganancia/pérdida, estricto sobre la mitad inicial.
    const recoveryAllowed = this.calzoRecoveryAllowed;
    if (truth) {
      if (recoveryAllowed) this._applyGain(playerId);
      // Verdadero sin recuperación: no gana ni pierde.
    } else this._applyLoss(playerId);
    const res = { type: 'calzoPaso', loserId: truth ? null : playerId, gainerId: truth && recoveryAllowed ? playerId : null, revealedHands, actualCount: null, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [], recoveryBlocked: truth && !recoveryAllowed };
    this._finishResolution(playerId, res);
    return res;
  }

  respondKamikaze(playerId, accept) {
    if (this.phase !== 'kamikazeOffer') throw new IllegalMove('fase_invalida', 'no hay oferta de Kamikaze');
    if (this.kamikazeOfferPlayerId !== playerId) {
      throw new IllegalMove('no_es_tu_oferta', 'el Kamikaze no te fue ofrecido a ti');
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
    this.phase = 'kamikazeChoice';
    this.currentPlayerId = playerId;
  }

  chooseKamikazeFace(playerId, face) {
    if (this.phase !== 'kamikazeChoice') throw new IllegalMove('fase_invalida', 'no hay Kamikaze en elección');
    if (this.kamikazeActivatorId !== playerId) {
      throw new IllegalMove('no_es_tu_oferta', 'solo el activador elige el número');
    }
    if (face < 1 || face > 6) throw new IllegalMove('pinta_invalida', 'el número debe ser 1..6');
    this._record(playerId, 'kamikaze');
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
    const res = { type: 'kamikaze', loserId: null, gainerId: null, revealedHands, actualCount: null, kamikazeFace: face, kamikazeLosses, massLoserIds: [] };
    this._finishResolution(playerId, res);
    return res;
  }

  /// Elimina a un jugador de inmediato (abandono: 3 tiempos de turno
  /// vencidos seguidos). La ronda en curso se corta y parte la
  /// siguiente el siguiente jugador vivo en el reloj. Espejo del
  /// motor Dart.
  forceEliminate(playerId) {
    if (this.phase === 'finished') throw new IllegalMove('partida_terminada', 'la partida ya terminó');
    const p = this.playerById(playerId);
    if (!p.alive) throw new IllegalMove('jugador_eliminado', 'ese jugador ya estaba eliminado');
    const revealedHands = { [playerId]: [...p.hand] };
    p.diceCount = 0;
    p.hand = [];
    if (this.kamikazeOfferPlayerId === playerId) this.kamikazeOfferPlayerId = null;
    if (this.kamikazeActivatorId === playerId) this.kamikazeActivatorId = null;
    const res = { type: 'abandono', loserId: playerId, gainerId: null, revealedHands, actualCount: null, kamikazeFace: null, kamikazeLosses: {}, massLoserIds: [] };
    let candidate = playerId;
    if (this.phase === 'kamikazeOffer' && this._pendingStarterId &&
        this._pendingStarterId !== playerId && this.playerById(this._pendingStarterId).alive) {
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
      this.phase = 'finished';
      this.isDraw = true;
      this.winnerId = null;
      return;
    }
    if (alive.length === 1) {
      this.phase = 'finished';
      this.winnerId = alive[0].id;
      return;
    }
    const starter = this.playerById(starterCandidateId).alive
      ? starterCandidateId
      : this.nextAliveAfter(starterCandidateId);
    if (this.config.kamikazeEnabled) {
      const candidates = alive.filter((p) => p.diceCount === 1 && !p.kamikazeOfferedOnce);
      if (candidates.length === 1) {
        this.phase = 'kamikazeOffer';
        this.kamikazeOfferPlayerId = candidates[0].id;
        this._pendingStarterId = starter;
        return;
      }
    }
    this._beginRound(starter);
  }
}
