// Salas de 2 a 6 jugadores (corrección del usuario, 26-oct 09:35
// "me equivoqué eran 6", reemplaza el máximo 5 de la decisión 07:32):
// la sala acepta 6 humanos, el 7, 8 y 9 rebotan con 'sala_llena',
// fillBots solo admite 0..5 ('bots_invalidos') y la partida parte
// con 6 o con 2.
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

async function makeHost(t, url) {
  const host = new Client(url);
  await host.ready();
  host.send({ type: 'create_room', nickname: 'Anfitrion', preset: 'completo', walletToken: 'w-host' });
  const created = await host.waitType('room_created');
  return { host, code: created.code };
}

test('sala de 6: entran 6, el 7, 8 y 9 rebotan y la partida parte llena', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 60000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const { host, code } = await makeHost(t, url);

  const guests = [];
  for (let i = 1; i <= 5; i++) {
    const c = new Client(url);
    await c.ready();
    c.send({ type: 'join_room', code, nickname: `Invitado${i}`, walletToken: `w-g${i}` });
    const j = await c.waitType('joined');
    assert.ok(j.playerId, `invitado ${i} sin asiento`);
    guests.push(c);
  }

  // El lobby del anfitrión muestra a los 6.
  const lobby = await host.waitFor(
    (m) => m.type === 'lobby' && m.players.length === 6, 20000, 'lobby de 6');
  assert.equal(lobby.players.length, 6);

  // Los jugadores 7, 8 y 9 no caben (mismo tope maxPlayers = 6).
  for (let n = 7; n <= 9; n++) {
    const extra = new Client(url);
    await extra.ready();
    extra.send({ type: 'join_room', code, nickname: `El${n}`, walletToken: `w-${n}` });
    const err = await extra.waitType('error');
    assert.equal(err.code, 'sala_llena', `el jugador ${n} debe rebotar`);
    extra.close();
  }

  // Todos listos y el anfitrión parte con 6 (sin bots de relleno).
  for (const g of guests) g.send({ type: 'set_ready', ready: true });
  host.send({ type: 'start_game', fillBots: 0 });
  await host.waitType('game_started');
  const wrap = await host.waitFor(
    (m) => m.type === 'state' && m.state.players && m.state.players.length === 6,
    20000, 'estado con 6 jugadores');
  assert.equal(wrap.state.players.length, 6);
  assert.equal(wrap.state.totalDiceInPlay, 30);

  host.close();
  for (const g of guests) g.close();
});

test('fillBots 6 rebota con bots_invalidos; con 5 la partida parte con 6', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 60000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const { host, code } = await makeHost(t, url);
  host.send({ type: 'start_game', fillBots: 6 });
  const err = await host.waitType('error');
  assert.equal(err.code, 'bots_invalidos');

  host.send({ type: 'start_game', fillBots: 5 });
  await host.waitType('game_started');
  const wrap = await host.waitFor(
    (m) => m.type === 'state' && m.state.players && m.state.players.length === 6,
    20000, 'estado con 6 jugadores (1 humano + 5 bots)');
  assert.equal(wrap.state.players.length, 6);
  assert.equal(wrap.state.totalDiceInPlay, 30);
  host.close();
});

test('sala de 2: mínimo válido, parte con 2 jugadores', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 60000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const { host, code } = await makeHost(t, url);
  const guest = new Client(url);
  await guest.ready();
  guest.send({ type: 'join_room', code, nickname: 'Invitado', walletToken: 'w-g1' });
  await guest.waitType('joined');
  guest.send({ type: 'set_ready', ready: true });
  host.send({ type: 'start_game', fillBots: 0 });
  await host.waitType('game_started');
  const wrap = await host.waitFor(
    (m) => m.type === 'state' && m.state.players && m.state.players.length === 2,
    20000, 'estado con 2 jugadores');
  assert.equal(wrap.state.players.length, 2);
  assert.equal(wrap.state.totalDiceInPlay, 10);
  host.close();
  guest.close();
});
