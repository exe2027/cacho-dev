// Servidor de salas de Cacho: Node.js + WebSockets, AUTORITATIVO.
// El servidor posee la instancia del motor, tira los dados y valida todo.
// A cada cliente le envía SOLO su mano (your_hand); las manos ajenas
// viajan únicamente dentro de una resolución/revelación.
//
// Push de turno: se invoca options.notifier({kind:'your_turn', ...}) —
// el gancho para conectar FCM/APNs cuando existan credenciales; sin
// credenciales no se envía push real y la partida no lo necesita.
import { randomInt, randomUUID } from 'node:crypto';
import {
  GameEngine,
  IllegalMove,
  RandomDiceRoller,
  configForPreset,
} from './engine.js';
import { BotBrain, botContext } from './bots.js';

const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const BOT_NAMES = ['El Guatón', 'La Cuca', 'Don Chalo', 'La Pituca', 'El Huaso', 'La Rusa', 'El Flaco', 'La Morocha', 'Don Lucho', 'El Pije', 'La Juanita', 'El Rucio'];
const CONFIG_KEYS = [
  'wildcardsEnabled', 'acesRuleEnabled', 'pasoEnabled', 'kamikazeEnabled', 'calzoEnabled',
  'calzoMinFraction', 'maxPasosPerPlayerPerRound', 'pasoAsFirstPlayAllowed',
  'pasoTwiceInARowAllowed', 'dicePerPlayer', 'turnTimerSeconds',
];

function makeCode(rooms, len = 5) {
  while (true) {
    let code = '';
    for (let i = 0; i < len; i++) code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
    if (!rooms.has(code)) return code;
  }
}

function cleanNickname(v) {
  const s = typeof v === 'string' ? v.trim() : '';
  return s.length >= 1 && s.length <= 16 ? s : null;
}

function cleanConfigOverrides(raw) {
  const out = {};
  if (raw && typeof raw === 'object') {
    for (const k of CONFIG_KEYS) {
      if (raw[k] !== undefined) out[k] = raw[k];
    }
  }
  if (out.dicePerPlayer !== undefined &&
      (!Number.isInteger(out.dicePerPlayer) || out.dicePerPlayer < 2 || out.dicePerPlayer > 5)) {
    throw new IllegalMove('config_invalida', 'dicePerPlayer debe ser 2..5');
  }
  if (out.turnTimerSeconds !== undefined &&
      (!Number.isFinite(out.turnTimerSeconds) || out.turnTimerSeconds < 5 || out.turnTimerSeconds > 180)) {
    throw new IllegalMove('config_invalida', 'turnTimerSeconds debe ser 5..180');
  }
  return out;
}

export function createRoomManager(options = {}) {
  const botDelayMs = options.botDelayMs ?? 1800;
  const turnTimeoutMs = options.turnTimeoutMs ?? null; // null = usar config de la sala
  const reconnectGraceMs = options.reconnectGraceMs ?? 60_000;
  const rollerFactory = options.rollerFactory ?? (() => new RandomDiceRoller());
  const notifier = options.notifier ?? (() => {});

  // ----- monedas (ficticias) -----
  // Billetera por token anónimo de dispositivo. Adapter síncrono
  // {get,set}; el Durable Object lo respalda con su storage y los
  // tests usan el mapa en memoria por defecto.
  const STAKES = [100, 250, 500, 1000, 2500];
  const WELCOME_COINS = 5000;
  const _memWallets = new Map();
  const wallet = options.wallet ?? {
    get: (t) => _memWallets.get(t),
    set: (t, b) => _memWallets.set(t, b),
  };
  function cleanStake(v) {
    const n = Number(v);
    return STAKES.includes(n) ? n : 500;
  }
  // Mesa temática (Fase A v2.0): solo las tres válidas; cualquier
  // otro valor cae a Casino Dorado (D1).
  function cleanTheme(v) {
    return ['pub', 'dorado', 'neon'].includes(v) ? v : 'dorado';
  }
  function cleanWalletToken(v) {
    const t = typeof v === 'string' ? v.trim() : '';
    return t.length >= 8 && t.length <= 64 ? t : null;
  }
  function ensureBalance(token) {
    let b = wallet.get(token);
    if (typeof b !== 'number') {
      b = WELCOME_COINS;
      wallet.set(token, b);
    }
    return b;
  }
  function sendBalance(seat) {
    if (seat && seat.walletToken) {
      sendSeat(seat, { type: 'balance', balance: ensureBalance(seat.walletToken) });
    }
  }

  const rooms = new Map();


  // ---------- utilidades de sala ----------

  function send(ws, obj) {
    if (ws && ws.open) {
      try { ws.sendText(JSON.stringify(obj)); } catch { /* socket muerto */ }
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
      // B8 (sentencia v2.0): el pozo queda FIJADO al partir; nunca
      // se recalcula si alguien sale o es eliminado.
      pot: room.potFixed ?? (room.stake ?? 0) * e.players.length,
      potFixed: room.potFixed ?? null,
      theme: room.theme ?? 'dorado',
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
          eliminated: p.eliminated,
        };
      }),
      turnEndsAt: room.turnEndsAt ?? null,
      events: e.roundHistory.map((ev) => ({
        round: ev.round, playerId: ev.playerId, type: ev.type, bid: ev.bid,
      })),
    };
  }

  // ---------- música de la sala (DJ de YouTube) ----------
  // El servidor guarda el estado compartido (DJ, tema actual con su
  // instante de inicio, cola y votos para saltar). El audio NUNCA pasa
  // por aquí: cada cliente reproduce el mismo video en su equipo con
  // el reproductor embebido de YouTube, sincronizado por estos datos.

  function musicSnapshot(room) {
    const m = room.music;
    const humans = room.seats.filter((x) => !x.isBot).length;
    return {
      djId: m.djId,
      current: m.current ? { ...m.current } : null,
      queue: m.queue.map((t) => ({ ...t })),
      skipVotes: m.skipVotes.length,
      skipNeeded: Math.floor(Math.max(humans, 1) / 2) + 1,
      sentAt: Date.now(),
    };
  }

  function broadcastMusic(room) {
    broadcast(room, { type: 'music_state', music: musicSnapshot(room) });
  }

  function advanceMusic(room) {
    const m = room.music;
    const next = m.queue.shift() ?? null;
    m.current = next
      ? { ...next, startedAt: Date.now(), pausedAt: null }
      : null;
    m.skipVotes = [];
    m.lastAdvanceAt = Date.now();
    broadcastMusic(room);
  }

  function cleanTrack(msg) {
    const videoId = String(msg.videoId ?? '');
    if (!/^[A-Za-z0-9_-]{6,20}$/.test(videoId)) return null;
    const title = String(msg.title ?? 'Sin título').slice(0, 140);
    const channel = String(msg.channel ?? '').slice(0, 80);
    const thumb = String(msg.thumb ?? '').slice(0, 300);
    let durationSec = Number(msg.durationSec ?? 0);
    if (!Number.isFinite(durationSec) || durationSec < 0) durationSec = 0;
    if (durationSec > 7200) durationSec = 7200;
    return { videoId, title, channel, thumb, durationSec };
  }

  function broadcastState(room) {
    const state = publicState(room);
    if (state) broadcast(room, { type: 'state', state });
  }

  function broadcastLobby(room) {
    for (const seat of room.seats) {
      if (seat.isBot) continue;
      sendSeat(seat, {
        type: 'lobby',
        code: room.code,
        hostId: room.hostId,
        status: room.status,
        stake: room.stake ?? 0,
        theme: room.theme ?? 'dorado',
        myBalance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
        players: room.seats.map((x) => ({
          id: x.id, nickname: x.nickname, isBot: x.isBot,
          ready: x.ready, connected: x.connected,
          micOn: !!x.micOn,
          balance: x.walletToken ? ensureBalance(x.walletToken) : null,
        })),
      });
    }
  }

  function dealHandsIfNeeded(room) {
    const e = room.engine;
    if (!e || e.phase !== 'playing') return;
    if (room.handDealtForRound === e.roundNumber) return;
    room.handDealtForRound = e.roundNumber;
    for (const seat of room.seats) {
      if (!seat.isBot && seat.connected) {
        sendSeat(seat, { type: 'your_hand', round: e.roundNumber, dice: e.handOf(seat.id) });
      }
    }
  }

  function currentActor(room) {
    const e = room.engine;
    if (!e) return null;
    if (e.phase === 'playing') return e.currentPlayerId;
    if (e.phase === 'kamikazeOffer') return e.kamikazeOfferPlayerId;
    if (e.phase === 'kamikazeChoice') return e.kamikazeActivatorId;
    return null;
  }

  function pasoEligible(e, playerId) {
    const p = e.playerById(playerId);
    return (
      e.config.pasoEnabled &&
      p.diceCount === e.config.dicePerPlayer &&
      p.diceCount === 5 &&
      e.roundHistory.length > 0
    );
  }

  function clearTimers(room) {
    if (room.turnTimer) clearTimeout(room.turnTimer);
    if (room.botTimer) clearTimeout(room.botTimer);
    room.turnTimer = null;
    room.botTimer = null;
    room.turnEndsAt = null;
  }

  function afterChange(room, resolution) {
    if (resolution) broadcast(room, { type: 'resolution', resolution });
    broadcastState(room);
    // Al partir cada ronda se anuncia quién parte y por qué
    // (regla: parte quien perdió un dado; si el Calzo fue exacto,
    // parte quien calzó).
    {
      const e = room.engine;
      if (e && e.phase === 'playing' && e.currentPlayerId &&
          e.roundNumber !== room._lastRoundNotice) {
        room._lastRoundNotice = e.roundNumber;
        const seat = room.seats.find((x) => x.id === e.currentPlayerId);
        const res = e.lastResolution;
        let why = 'sigue la ronda';
        if (!res) why = 'salió en el sorteo';
        else if (res.type === 'kamikaze') why = 'activó el Kamikaze';
        else if (res.type === 'abandono') why = 'el que no jugaba quedó eliminado';
        else if (res.loserId === e.currentPlayerId) why = 'perdió un dado';
        else if (res.gainerId === e.currentPlayerId) why = 'calzó justo';
        broadcast(room, { type: 'notice', kind: 'starter', text: `Ronda ${e.roundNumber}: parte ${seat ? seat.nickname : ''} (${why})` });
      }
    }
    dealHandsIfNeeded(room);
    const e = room.engine;
    if (e && e.phase === 'finished') {
      clearTimers(room);
      room.status = 'finished';
      settleCoins(room);
      broadcast(room, {
        type: 'game_over', winnerId: e.winnerId, isDraw: e.isDraw,
        pot: room.potFixed ?? (room.stake ?? 0) * e.players.length, stake: room.stake ?? 0,
      });
      maybeCleanupRoom(room);
      return;
    }
    scheduleDrive(room);
  }

  /// Liquida las monedas UNA vez: el ganador humano se lleva el
  /// pozo; en empate se devuelve la apuesta a cada humano.
  function settleCoins(room) {
    if (room.coinsSettled || !room.escrow) return;
    room.coinsSettled = true;
    const e = room.engine;
    const pot = room.potFixed ?? (room.stake ?? 0) * e.players.length;
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
    if (!e || e.phase === 'finished' || room.status !== 'playing') return;
    const actor = currentActor(room);
    if (!actor) return;
    const seat = room.seatById(actor);
    if (!seat) return;
    if (seat.isBot || seat.auto) {
      // Los bots "piensan": base + azar hasta la mitad (1.8-2.7 s).
      room.botTimer = setTimeout(() => driveSeat(room, actor, {}), botDelayMs + Math.floor(Math.random() * botDelayMs * 0.5));
    } else {
      notifier({ kind: 'your_turn', roomCode: room.code, playerId: actor });
      const ms = turnTimeoutMs ?? e.config.turnTimerSeconds * 1000;
      room.turnEndsAt = Date.now() + ms;
      room.turnTimer = setTimeout(() => {
        // Abandono (regla del usuario, 22-oct): al TERCER turno seguido
        // dejando vencer el tiempo, el jugador queda eliminado en vez
        // de que el bot juegue por él. Resuelve al que se salió del
        // juego, perdió internet o dejó el teléfono botado.
        seat.strikes = (seat.strikes ?? 0) + 1;
        if (seat.strikes >= 3) {
          seat.strikes = 0;
          broadcast(room, { type: 'notice', kind: 'afk_eliminated', playerId: actor });
          try {
            const res = e.forceEliminate(actor);
            afterChange(room, res);
          } catch {
            driveSeat(room, actor, { asTimeout: true });
          }
        } else {
          broadcast(room, { type: 'notice', kind: 'turn_timeout', playerId: actor, strikes: seat.strikes });
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
    const brain = new BotBrain(seat.isBot ? seat.difficulty : 'media');
    try {
      if (e.phase === 'playing' && e.currentPlayerId === seatId) {
        const action = brain.decide(botContext(e, seatId, { canPaso: pasoEligible(e, seatId) }));
        applyAction(room, seatId, action, { fromBot: true });
      } else if (e.phase === 'kamikazeOffer' && e.kamikazeOfferPlayerId === seatId) {
        // Por tiempo vencido (humano) la oferta se rechaza; un bot decide.
        let accept = false;
        if (!asTimeout || seat.isBot) {
          accept = brain.shouldAcceptKamikaze(botContext(e, seatId, { canPaso: false }));
        }
        e.respondKamikaze(seatId, accept);
        afterChange(room, null);
      } else if (e.phase === 'kamikazeChoice' && e.kamikazeActivatorId === seatId) {
        const res = e.chooseKamikazeFace(seatId, brain.chooseKamikazeFace());
        afterChange(room, res);
      }
    } catch {
      // Respaldo: la partida nunca se traba por un error del bot.
      try {
        if (e.phase === 'playing' && e.currentPlayerId === seatId) {
          const res = e.currentBid ? e.dudo(seatId) : (e.bid(seatId, { quantity: 1, face: 2 }), null);
          afterChange(room, res ?? null);
        }
      } catch { /* fase ya cambió */ }
    }
  }

  function applyAction(room, playerId, msg, { fromBot = false } = {}) {
    const e = room.engine;
    const seat = room.seatById(playerId);
    try {
      let res = null;
      switch (msg.type) {
        case 'bid': e.bid(playerId, msg.bid); break;
        case 'paso': e.paso(playerId); break;
        case 'dudo': res = e.dudo(playerId); break;
        case 'calzo': res = e.calzo(playerId); break;
        case 'dudoPaso': res = e.dudoPaso(playerId); break;
        case 'calzoPaso': res = e.calzoPaso(playerId); break;
        default:
          throw new IllegalMove('accion_invalida', `acción desconocida: ${msg.type}`);
      }
      if (!fromBot && seat) seat.strikes = 0; // jugó: cuenta de abandono en cero
      afterChange(room, res);
    } catch (err) {
      if (fromBot) throw err; // lo captura driveSeat y usa el respaldo
      sendSeat(seat, {
        type: 'error',
        code: err instanceof IllegalMove ? err.code : 'error_interno',
        message: err.message,
      });
    }
  }

  function maybeCleanupRoom(room) {
    const anyHumanConnected = room.seats.some((s) => !s.isBot && s.connected);
    if (!anyHumanConnected && room.status !== 'playing') {
      clearTimers(room);
      rooms.delete(room.code);
    }
  }

  // ---------- mensajes ----------

  function requireRoom(ws, ctx) {
    const room = ctx.roomCode ? rooms.get(ctx.roomCode) : null;
    if (!room) {
      send(ws, { type: 'error', code: 'sin_sala', message: 'no estás en una sala' });
      return null;
    }
    return room;
  }

  function handleMessage(ws, ctx, msg) {
    switch (msg.type) {
      case 'ping':
        send(ws, { type: 'pong' });
        return;

      case 'room_status': {
        // Consulta sin efectos (banner "Entrar a la sala activa" de
        // la app): ¿la sala sigue viva y este dispositivo (por su
        // token de billetera) tiene un asiento en ella?
        const code = String(msg.code ?? '').toUpperCase();
        const room = rooms.get(code);
        if (!room) {
          send(ws, { type: 'room_status', code, exists: false, member: false });
          return;
        }
        const wt = cleanWalletToken(msg.walletToken);
        const seat = wt
          ? room.seats.find((s) => !s.isBot && s.walletToken === wt)
          : null;
        send(ws, {
          type: 'room_status', code: room.code, exists: true,
          phase: room.status, member: !!seat,
          connected: seat ? seat.connected : false,
          stake: room.stake,
        });
        return;
      }

      case 'create_room': {
        const nickname = cleanNickname(msg.nickname);
        if (!nickname) throw new IllegalMove('apodo_invalido', 'apodo de 1 a 16 caracteres');
        const config = configForPreset(msg.preset ?? 'completo', cleanConfigOverrides(msg.config));
        const code = makeCode(rooms, 5);
        const seat = {
          id: randomUUID(), nickname, isBot: false, difficulty: null,
          ready: true, connected: true, deviceToken: randomUUID(), ws, auto: false,
          strikes: 0,
          walletToken: cleanWalletToken(msg.walletToken),
        };
        const room = {
          code, hostId: seat.id, seats: [seat], engine: null, config,
          status: 'lobby', turnTimer: null, botTimer: null, turnEndsAt: null, handDealtForRound: 0,
          stake: cleanStake(msg.stake), escrow: 0, coinsSettled: false, potFixed: null,
          theme: cleanTheme(msg.theme),
          music: { djId: null, current: null, queue: [], skipVotes: [], lastAdvanceAt: 0 },
          seatById(id) { return this.seats.find((s) => s.id === id) ?? null; },
        };
        rooms.set(code, room);
        ctx.roomCode = code;
        ctx.playerId = seat.id;
        send(ws, {
          type: 'room_created', code, playerId: seat.id, deviceToken: seat.deviceToken,
          balance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
          stake: room.stake,
          theme: room.theme,
        });
        broadcastLobby(room);
        send(ws, { type: 'music_state', music: musicSnapshot(room) });
        return;
      }

      case 'join_room': {
        const nickname = cleanNickname(msg.nickname);
        if (!nickname) throw new IllegalMove('apodo_invalido', 'apodo de 1 a 16 caracteres');
        const room = rooms.get(String(msg.code ?? '').toUpperCase());
        if (!room) throw new IllegalMove('sala_no_existe', 'ese código no existe');
        if (room.status !== 'lobby') throw new IllegalMove('sala_en_partida', 'la partida ya empezó');
        if (room.seats.length >= room.config.maxPlayers) {
          throw new IllegalMove('sala_llena', 'la sala está llena');
        }
        const seat = {
          id: randomUUID(), nickname, isBot: false, difficulty: null,
          ready: false, connected: true, deviceToken: randomUUID(), ws, auto: false,
          strikes: 0,
          walletToken: cleanWalletToken(msg.walletToken),
        };
        room.seats.push(seat);
        ctx.roomCode = room.code;
        ctx.playerId = seat.id;
        send(ws, {
          type: 'joined', code: room.code, playerId: seat.id, deviceToken: seat.deviceToken,
          balance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
          stake: room.stake,
        });
        broadcastLobby(room);
        send(ws, { type: 'music_state', music: musicSnapshot(room) });
        return;
      }

      case 'rejoin': {
        const room = rooms.get(String(msg.code ?? '').toUpperCase());
        if (!room) throw new IllegalMove('sala_no_existe', 'ese código no existe');
        let seat = room.seatById(String(msg.playerId ?? ''));
        if (!seat || seat.isBot || seat.deviceToken !== msg.deviceToken) {
          // Reclamo por billetera (banner "sala activa"): el
          // dispositivo que vuelve — recargó la página, tocó "atrás"
          // — ya no tiene el playerId/deviceToken de la sesión
          // anterior, pero su token de billetera coincide con un
          // asiento humano DESCONECTADO: es el mismo jugador y
          // recupera su lugar. Un asiento conectado jamás se roba.
          const wt = cleanWalletToken(msg.walletToken);
          const byWallet = wt
            ? room.seats.find(
                (s) => !s.isBot && s.walletToken === wt && !s.connected)
            : null;
          if (!byWallet) {
            throw new IllegalMove('token_invalido', 'no se pudo verificar tu lugar en la sala');
          }
          seat = byWallet;
        }
        seat.ws = ws;
        seat.connected = true;
        seat.auto = false; // recupera el control de su asiento en la misma partida
        seat.strikes = 0; // y vuelve con la cuenta de abandono en cero
        cancelDisconnect(room, seat); // y se cancela su cuenta regresiva
        ctx.roomCode = room.code;
        ctx.playerId = seat.id;
        send(ws, {
          type: 'rejoined', code: room.code, playerId: seat.id,
          deviceToken: seat.deviceToken,
          balance: seat.walletToken ? ensureBalance(seat.walletToken) : null,
        });
        send(ws, { type: 'music_state', music: musicSnapshot(room) });
        if (room.status === 'lobby') {
          broadcastLobby(room);
        } else {
          broadcastState(room);
          // La mano solo viaja en fase 'playing': durante la oferta
          // y la elección del Kamikaze nadie puede ver sus dados
          // (regla del usuario, 22-oct), ni reconectando.
          if (room.engine && room.engine.phase === 'playing') {
            sendSeat(seat, {
              type: 'your_hand',
              round: room.engine.roundNumber,
              dice: room.engine.handOf(seat.id),
            });
          }
          scheduleDrive(room);
        }
        return;
      }

      case 'set_ready': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (seat) seat.ready = !!msg.ready;
        broadcastLobby(room);
        return;
      }

      case 'set_nickname': {
        // Cambiar el nombre estando DENTRO de la sala (pedido del
        // usuario, 24-oct): vale mientras la sala está en el lobby;
        // con la partida andando el nombre ya está en juego.
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.status !== 'lobby') {
          throw new IllegalMove('en_partida', 'el nombre se cambia en la sala, antes de partir');
        }
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const nickname = cleanNickname(msg.nickname);
        if (!nickname) throw new IllegalMove('apodo_invalido', 'apodo de 1 a 16 caracteres');
        seat.nickname = nickname;
        broadcastLobby(room);
        return;
      }

      case 'start_game': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.hostId !== ctx.playerId) {
          throw new IllegalMove('no_es_anfitrion', 'solo el anfitrión parte la partida');
        }
        if (room.status !== 'lobby') throw new IllegalMove('fase_invalida', 'la partida ya empezó');
        if (room.seats.some((s) => !s.ready)) {
          throw new IllegalMove('no_todos_listos', 'faltan jugadores por estar listos');
        }
        const fill = Number.isInteger(msg.fillBots) ? msg.fillBots : 0;
        if (fill < 0 || fill > 5) throw new IllegalMove('bots_invalidos', 'fillBots debe ser 0..5');
        const total = room.seats.length + fill;
        if (total < room.config.minPlayers) {
          throw new IllegalMove('jugadores_insuficientes', `se necesitan al menos ${room.config.minPlayers} jugadores (hay ${total})`);
        }
        if (total > room.config.maxPlayers) {
          throw new IllegalMove('sala_llena', `máximo ${room.config.maxPlayers} jugadores`);
        }
        // Monedas: todos los humanos deben poder pagar la apuesta;
        // se cobra al partir (el pozo se liquida en settleCoins).
        for (const seat of room.seats) {
          if (!seat.walletToken) continue;
          const bal = ensureBalance(seat.walletToken);
          if (bal < room.stake) {
            throw new IllegalMove('saldo_insuficiente',
              `${seat.nickname} no tiene monedas para la apuesta de ${room.stake} (tiene ${bal})`);
          }
        }
        for (const seat of room.seats) {
          if (!seat.walletToken) continue;
          wallet.set(seat.walletToken, ensureBalance(seat.walletToken) - room.stake);
          sendBalance(seat);
        }
        room.escrow = room.stake;
        room.coinsSettled = false;
        const difficulty = ['facil', 'media', 'dificil'].includes(msg.botDifficulty)
          ? msg.botDifficulty : 'media';
        for (let i = 0; i < fill; i++) {
          room.seats.push({
            id: randomUUID(), nickname: `Bot ${BOT_NAMES[i % BOT_NAMES.length]}`,
            isBot: true, difficulty, ready: true, connected: true,
            deviceToken: null, ws: null, auto: true,
          });
        }
        room.engine = new GameEngine({
          config: room.config,
          roller: rollerFactory(),
          players: room.seats.map((s) => ({ id: s.id, name: s.nickname })),
        });
        const starterId = room.engine.startGame();
        // B8: el pozo se fija aquí, con los jugadores iniciales.
        room.potFixed = room.stake * room.engine.players.length;
        room.status = 'playing';
        const starterSeat = room.seats.find((x) => x.id === starterId);
        broadcast(room, { type: 'notice', kind: 'starter', text: `Sorteo: parte ${starterSeat ? starterSeat.nickname : ''}` });
        room._lastRoundNotice = room.engine.roundNumber;
        room.handDealtForRound = 0;
        broadcast(room, { type: 'game_started', code: room.code });
        afterChange(room, null);
        return;
      }

      case 'mic': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        seat.micOn = !!msg.on;
        broadcast(room, { type: 'mic', playerId: seat.id, on: seat.micOn });
        return;
      }

      case 'emote': {
        // Reacciones rápidas (docs/19 C9, chat fuera): relevo puro,
        // sin estado en el servidor y sin tocar ningún mensaje
        // existente. Glifo validado contra el conjunto fijo de la
        // app; cualquier otro valor se ignora en silencio. Los
        // clientes que no conozcan el tipo lo ignoran (sin default
        // en su switch), así que es compatible hacia atrás.
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const glyph = String(msg.emote ?? '');
        if (!['😂', '👏', '👍', '😮', '🔥'].includes(glyph)) return;
        broadcast(room, { type: 'emote', playerId: seat.id, emote: glyph });
        return;
      }

      case 'voice_signal': {
        // Relevo de señalización WebRTC (ofertas, respuestas e ICE):
        // solo entre asientos humanos de la MISMA sala. El audio viaja
        // directo entre jugadores (malla P2P); el servidor no lo toca.
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const target = room.seatById(String(msg.to ?? ''));
        if (!target || target.isBot || target.id === ctx.playerId) return;
        if (!msg.data || typeof msg.data !== 'object') return;
        sendSeat(target, { type: 'voice_signal', from: ctx.playerId, data: msg.data });
        return;
      }

      case 'music_claim': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        const djSeat = room.music.djId ? room.seatById(room.music.djId) : null;
        if (!room.music.djId || !djSeat || !djSeat.connected ||
            room.music.djId === seat.id) {
          room.music.djId = seat.id;
          broadcastMusic(room);
        }
        return;
      }

      case 'music_release': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.music.djId === ctx.playerId) {
          room.music.djId = null;
          broadcastMusic(room);
        }
        return;
      }

      case 'music_add': {
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

      case 'music_remove': {
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

      case 'music_pause': {
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

      case 'music_play': {
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

      case 'music_next': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        if (room.music.djId !== ctx.playerId) return;
        advanceMusic(room);
        return;
      }

      case 'music_play_now': {
        // El DJ se salta la cola (pedido del usuario, 22-oct): pone a
        // sonar AHORA un tema de la cola (por videoId) o uno recién
        // elegido (track completo desde el buscador). Solo el DJ.
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot) return;
        if (room.music.djId !== seat.id) return;
        let item = null;
        if (msg.videoId) {
          const idx = room.music.queue.findIndex(
              (t) => t.videoId === String(msg.videoId));
          if (idx >= 0) item = room.music.queue.splice(idx, 1)[0];
        }
        if (!item) {
          const track = cleanTrack(msg);
          if (!track) return;
          item = { ...track, byId: seat.id, byName: seat.nickname };
          // Si ese tema ya estaba esperando en la cola, sale de ahí.
          room.music.queue = room.music.queue.filter(
              (t) => t.videoId !== item.videoId);
        }
        room.music.current = { ...item, startedAt: Date.now(), pausedAt: null };
        room.music.skipVotes = [];
        room.music.lastAdvanceAt = Date.now();
        broadcastMusic(room);
        return;
      }

      case 'music_vote_skip': {
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

      case 'music_ended': {
        const room = requireRoom(ws, ctx);
        if (!room) return;
        const seat = room.seatById(ctx.playerId);
        if (!seat || seat.isBot || !room.music.current) return;
        // Avanza si lo reporta el DJ, o cualquiera pasado un margen
        // (red de seguridad por si el DJ perdió su reproductor).
        const now = Date.now();
        if (seat.id === room.music.djId ||
            (now - room.music.lastAdvanceAt > 5000 &&
             now - room.music.current.startedAt > 8000)) {
          advanceMusic(room);
        }
        return;
      }

      case 'action': {
        const room = requireRoom(ws, ctx);
        if (!room || room.status !== 'playing') return;
        applyAction(room, ctx.playerId, msg.action ?? {}, {});
        return;
      }

      case 'kamikaze_response': {
        const room = requireRoom(ws, ctx);
        if (!room || !room.engine) return;
        try {
          room.engine.respondKamikaze(ctx.playerId, !!msg.accept);
          const seat = room.seatById(ctx.playerId);
          if (seat) seat.strikes = 0;
          afterChange(room, null);
        } catch (err) {
          sendSeat(room.seatById(ctx.playerId), {
            type: 'error',
            code: err instanceof IllegalMove ? err.code : 'error_interno',
            message: err.message,
          });
        }
        return;
      }

      case 'kamikaze_face': {
        const room = requireRoom(ws, ctx);
        if (!room || !room.engine) return;
        try {
          const res = room.engine.chooseKamikazeFace(ctx.playerId, msg.face);
          const seat = room.seatById(ctx.playerId);
          if (seat) seat.strikes = 0;
          afterChange(room, res);
        } catch (err) {
          sendSeat(room.seatById(ctx.playerId), {
            type: 'error',
            code: err instanceof IllegalMove ? err.code : 'error_interno',
            message: err.message,
          });
        }
        return;
      }

      default:
        send(ws, { type: 'error', code: 'mensaje_invalido', message: `tipo desconocido: ${msg.type}` });
    }
  }

  function handleOpen() {
    return { roomCode: null, playerId: null };
  }

  function handleRaw(ws, ctx, raw) {
    let msg;
    try {
      msg = JSON.parse(typeof raw === 'string' ? raw : raw.toString());
    } catch {
      send(ws, { type: 'error', code: 'json_invalido', message: 'mensaje no es JSON válido' });
      return;
    }
    try {
      handleMessage(ws, ctx, msg);
    } catch (err) {
      send(ws, {
        type: 'error',
        code: err instanceof IllegalMove ? err.code : 'error_interno',
        message: err.message,
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
      broadcast(room, { type: 'mic', playerId: seat.id, on: false });
    }
    // Música: si el DJ se va, el rol queda libre (la música sigue);
    // su voto para saltar se retira.
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
    if (room.status === 'lobby') {
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
      // En partida: el bot cubre el asiento de inmediato (la partida
      // no se detiene) Y parte la cuenta regresiva de la regla del
      // usuario (24-oct): se avisa a TODA la mesa y el jugador tiene
      // reconnectGraceMs (60 s) para volver; si no vuelve, queda
      // eliminado de la mesa (ver eliminateDisconnected).
      seat.auto = true;
      if (room.status === 'playing' && room.engine && room.engine.phase !== 'finished') {
        seat.dcDeadline = Date.now() + reconnectGraceMs;
        broadcast(room, {
          type: 'notice', kind: 'player_left', playerId: seat.id,
          seconds: Math.round(reconnectGraceMs / 1000),
        });
        if (seat.dcTimer) clearTimeout(seat.dcTimer);
        seat.dcTimer = setTimeout(() => eliminateDisconnected(room, seat), reconnectGraceMs);
        if (seat.dcTimer && typeof seat.dcTimer.unref === 'function') seat.dcTimer.unref();
      }
      notifier({ kind: 'player_disconnected', roomCode: room.code, playerId: seat.id, graceMs: reconnectGraceMs });
      broadcastState(room);
      if (musicChanged) broadcastMusic(room);
      scheduleDrive(room);
      const t = setTimeout(() => maybeCleanupRoom(room), reconnectGraceMs + 1000);
      if (t && typeof t.unref === 'function') t.unref();
    }
  }

  /// Cancela la cuenta regresiva de desconexión (el jugador volvió):
  /// avisa a la mesa que está de vuelta.
  function cancelDisconnect(room, seat) {
    if (!seat.dcDeadline) return;
    if (seat.dcTimer) { clearTimeout(seat.dcTimer); seat.dcTimer = null; }
    seat.dcDeadline = null;
    broadcast(room, { type: 'notice', kind: 'player_returned', playerId: seat.id });
  }

  /// Venció la cuenta regresiva sin que el jugador volviera:
  /// queda eliminado de la mesa (pierde sus dados y su apuesta,
  /// igual que el abandono por tiempos vencidos).
  function eliminateDisconnected(room, seat) {
    seat.dcTimer = null;
    seat.dcDeadline = null;
    if (!rooms.has(room.code) || room.status !== 'playing') return;
    if (seat.connected || seat.isBot) return;
    const e = room.engine;
    if (!e || e.phase === 'finished') return;
    const p = e.players.find((x) => x.id === seat.id);
    if (!p || p.eliminated) return;
    broadcast(room, { type: 'notice', kind: 'disconnect_eliminated', playerId: seat.id });
    try {
      const res = e.forceEliminate(seat.id);
      afterChange(room, res);
    } catch { /* el motor ya lo resolvió por otra vía */ }
  }

  function clearAll() {
    for (const room of rooms.values()) clearTimers(room);
  }

  return { rooms, handleOpen, handleRaw, handleClose, clearAll };
}
