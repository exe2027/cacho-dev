// Integración WebSocket en vivo contra el servidor real.
import test from 'node:test';
import assert from 'node:assert/strict';
import WebSocket from 'ws';
import { createCachoServer } from '../src/server.js';

class Client {
  constructor(url) {
    this.ws = new WebSocket(url);
    this.messages = [];
    this.waiters = [];
    this.ws.on('message', (d) => {
      const m = JSON.parse(d.toString());
      this.messages.push(m);
      this.waiters = this.waiters.filter((w) => {
        if (w.pred(m)) {
          w.resolve(m);
          return false;
        }
        return true;
      });
    });
  }
  ready() {
    return new Promise((res, rej) => {
      this.ws.on('open', res);
      this.ws.on('error', rej);
    });
  }
  send(obj) {
    this.ws.send(JSON.stringify(obj));
  }
  waitFor(pred, timeout = 5000, label = 'mensaje') {
    const found = this.messages.find(pred);
    if (found) return Promise.resolve(found);
    return new Promise((resolve, reject) => {
      const w = { pred, resolve };
      this.waiters.push(w);
      setTimeout(() => {
        reject(new Error(`timeout esperando ${label}; llegó: ${this.messages.map((m) => m.type).join(',')}`));
      }, timeout);
    });
  }
  waitType(type, timeout) {
    return this.waitFor((m) => m.type === type, timeout, type);
  }
  latestState() {
    const states = this.messages.filter((m) => m.type === 'state');
    return states[states.length - 1]?.state;
  }
  clear() {
    this.messages.length = 0;
  }
  close() {
    this.ws.close();
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitUntil(fn, timeout = 6000, label = 'condición') {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const v = fn();
    if (v) return v;
    await sleep(50);
  }
  throw new Error(`timeout esperando ${label}`);
}

test('servidor de salas: flujo completo 1v1, privacidad, reconexión y bots', async (t) => {
  const app = createCachoServer({ botDelayMs: 20, turnTimeoutMs: 4000, reconnectGraceMs: 600 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const health = await (await fetch(`http://127.0.0.1:${port}/health`)).json();
  assert.equal(health.ok, true);

  // --- crear y unirse ---
  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'clasico' });
  const created = await a.waitType('room_created');
  assert.match(created.code, /^[A-Z2-9]{5}$/);
  const code = created.code;

  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code, nickname: 'Beto' });
  const joined = await b.waitType('joined');
  const bId = joined.playerId;
  const bToken = joined.deviceToken;

  b.send({ type: 'set_ready', ready: true });
  await a.waitFor((m) => m.type === 'lobby' && m.players.find((p) => p.id === bId)?.ready === true);
  a.send({ type: 'start_game', fillBots: 0 });
  await a.waitType('game_started');
  await b.waitType('game_started');

  const handA = await a.waitType('your_hand');
  const handB = await b.waitType('your_hand');
  assert.equal(handA.dice.length, 5);
  assert.equal(handB.dice.length, 5);

  // Privacidad: ningún 'state' trae manos; B recibió exactamente UNA mano (la suya).
  for (const m of b.messages.filter((x) => x.type === 'state')) {
    assert.ok(!JSON.stringify(m.state).includes('"hand"'), 'el estado público no debe traer manos');
  }
  assert.equal(b.messages.filter((x) => x.type === 'your_hand').length, 1);

  // --- jugada fuera de turno -> error con código del motor ---
  const st = a.latestState();
  assert.equal(st.phase, 'playing');
  const currentId = st.currentPlayerId;
  const other = currentId === created.playerId ? b : a;
  other.send({ type: 'action', action: { type: 'dudo' } });
  const err = await other.waitFor((m) => m.type === 'error');
  assert.equal(err.code, 'no_es_tu_turno');

  // --- una ronda completa: apuesta + dudo -> resolución pública ---
  const cur = currentId === created.playerId ? a : b;
  cur.send({ type: 'action', action: { type: 'bid', bid: { quantity: 1, face: 2 } } });
  await b.waitFor((m) => m.type === 'state' && m.state.currentBid?.quantity === 1);
  a.clear();
  b.clear();
  other.send({ type: 'action', action: { type: 'dudo' } });
  const res = await a.waitType('resolution');
  assert.deepEqual(Object.keys(res.resolution.revealedHands).sort(), [created.playerId, bId].sort());
  const st2 = await waitUntil(() => {
    const s = a.latestState();
    return s && s.round === 2 ? s : null;
  }, 5000, 'estado de ronda 2');
  const totalDice = st2.players.reduce((s, p) => s + p.diceCount, 0);
  assert.equal(totalDice, 9); // cayó exactamente un dado
  const handB2 = await b.waitFor((m) => m.type === 'your_hand' && m.round === 2);
  assert.equal(handB2.dice.length, st2.players.find((p) => p.id === bId).diceCount);

  // --- reconexión con token: recupera asiento y mano ---
  b.close();
  await sleep(150);
  const b2 = new Client(url);
  await b2.ready();
  b2.send({ type: 'rejoin', code, playerId: bId, deviceToken: bToken });
  await b2.waitType('rejoined');
  const reHand = await b2.waitType('your_hand');
  const reState = b2.latestState();
  assert.equal(reHand.dice.length, reState.players.find((p) => p.id === bId).diceCount);
  b2.close();
  a.close();

  // --- sala mixta: el bot juega su turno solo ---
  const c = new Client(url);
  await c.ready();
  c.send({ type: 'create_room', nickname: 'Solo', preset: 'completo' });
  const created2 = await c.waitType('room_created');
  c.send({ type: 'start_game', fillBots: 1, botDifficulty: 'media' });
  await c.waitType('game_started');
  const botId = await waitUntil(() => {
    const s = c.latestState();
    return s?.players.find((p) => p.isBot)?.id ?? null;
  }, 5000, 'bot en el estado');
  // Conducir: cuando es turno del humano jugamos simple; el bot debe
  // terminar actuando por su cuenta (evento público con su id).
  const deadline = Date.now() + 8000;
  let botActed = false;
  while (Date.now() < deadline && !botActed) {
    const s = c.latestState();
    if (s?.events?.some((e) => e.playerId === botId)) {
      botActed = true;
      break;
    }
    if (s?.phase === 'playing' && s.currentPlayerId === created2.playerId) {
      if (!s.currentBid) {
        c.send({ type: 'action', action: { type: 'bid', bid: { quantity: 1, face: 2 } } });
      } else {
        c.send({ type: 'action', action: { type: 'dudo' } });
      }
    } else if (s?.phase === 'kamikazeOffer' && s.kamikazeOfferPlayerId === created2.playerId) {
      c.send({ type: 'kamikaze_response', accept: false });
    }
    await sleep(60);
  }
  assert.ok(botActed, 'el bot debió actuar en su turno sin que nadie lo mueva');
  c.close();
});
