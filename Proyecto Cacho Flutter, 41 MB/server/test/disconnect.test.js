// Reglas del usuario (24-oct):
// 1) Desconexión en partida: se avisa a TODA la mesa, parte una
//    cuenta regresiva (reconnectGraceMs; 60 s en producción) y si
//    el jugador no vuelve queda eliminado. Si vuelve a tiempo, la
//    cuenta se cancela y también se avisa.
// 2) Cambiar el nombre dentro de la sala (solo en el lobby).
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
        if (w.pred(m)) { w.resolve(m); return false; }
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
  send(obj) { this.ws.send(JSON.stringify(obj)); }
  waitFor(pred, timeout = 20000, label = 'mensaje') {
    const found = this.messages.find(pred);
    if (found) return Promise.resolve(found);
    return new Promise((resolve, reject) => {
      const w = { pred, resolve };
      this.waiters.push(w);
      setTimeout(() => reject(new Error(`timeout esperando ${label}`)), timeout);
    });
  }
  waitType(type, timeout) {
    return this.waitFor((m) => m.type === type, timeout, type);
  }
  close() { this.ws.close(); }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function mesaDeDos(t, opts) {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 60000, ...opts });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());
  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'completo', walletToken: 'w-ana' });
  const created = await a.waitType('room_created');
  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Beto', walletToken: 'w-beto' });
  const joinedB = await b.waitType('joined');
  b.send({ type: 'set_ready', ready: true });
  a.send({ type: 'start_game', fillBots: 0 });
  await a.waitType('game_started');
  return { a, b, code: created.code, bId: joinedB.playerId, bToken: joinedB.deviceToken, url };
}

test('desconexión: aviso a la mesa, cuenta regresiva y eliminación', async (t) => {
  const { a, b, bId } = await mesaDeDos(t, { reconnectGraceMs: 900 });

  b.close();
  const left = await a.waitFor(
    (m) => m.type === 'notice' && m.kind === 'player_left' && m.playerId === bId,
    10000, 'aviso player_left');
  assert.equal(left.seconds, 1); // 900 ms redondeado en el aviso

  const st = await a.waitFor(
    (m) => m.type === 'state' && m.state.players.some(
      (p) => p.id === bId && typeof p.dcDeadline === 'number'),
    10000, 'estado con cuenta regresiva');
  assert.ok(st.state.players.find((p) => p.id === bId).dcDeadline > Date.now() - 1000);

  await a.waitFor(
    (m) => m.type === 'notice' && m.kind === 'disconnect_eliminated' && m.playerId === bId,
    10000, 'aviso de eliminación por desconexión');

  const over = await a.waitType('game_over', 10000);
  assert.equal(over.isDraw, false);
  a.close();
});

test('volver antes de los 60 s cancela la cuenta y avisa a la mesa', async (t) => {
  const { a, b, code, bId, bToken, url } = await mesaDeDos(t, { reconnectGraceMs: 1500 });

  b.close();
  await a.waitFor(
    (m) => m.type === 'notice' && m.kind === 'player_left' && m.playerId === bId,
    10000, 'aviso player_left');

  const b2 = new Client(url);
  await b2.ready();
  b2.send({ type: 'rejoin', code, playerId: bId, deviceToken: bToken });
  await b2.waitType('rejoined');
  await a.waitFor(
    (m) => m.type === 'notice' && m.kind === 'player_returned' && m.playerId === bId,
    10000, 'aviso player_returned');

  await sleep(2200); // más que la gracia: NO debe eliminarlo
  assert.equal(
    a.messages.some((m) => m.type === 'notice' && m.kind === 'disconnect_eliminated'),
    false);
  const st = a.messages.filter((m) => m.type === 'state').at(-1);
  const pb = st.state.players.find((p) => p.id === bId);
  assert.equal(pb.eliminated, false);
  assert.equal(pb.dcDeadline, null);
  a.close();
  b2.close();
});

test('cambiar el nombre dentro de la sala (lobby sí, en partida no)', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 60000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'completo', walletToken: 'w-ana' });
  const created = await a.waitType('room_created');
  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Beto', walletToken: 'w-beto' });
  await b.waitType('joined');

  b.send({ type: 'set_nickname', nickname: 'El Renombrado' });
  const lobby = await a.waitFor(
    (m) => m.type === 'lobby' && m.players.some((p) => p.nickname === 'El Renombrado'),
    10000, 'lobby con el nombre nuevo');
  assert.ok(lobby.players.some((p) => p.nickname === 'El Renombrado'));

  b.send({ type: 'set_ready', ready: true });
  a.send({ type: 'start_game', fillBots: 0 });
  await a.waitType('game_started');
  b.send({ type: 'set_nickname', nickname: 'Otro' });
  const err = await b.waitType('error');
  assert.equal(err.code, 'en_partida');
  a.close();
  b.close();
});
