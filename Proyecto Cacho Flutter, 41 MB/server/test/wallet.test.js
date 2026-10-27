// Monedas en línea: saldo inicial, cobro al partir, pozo al ganador
// y bloqueo por saldo insuficiente. Dos humanos con turnos cubiertos
// por el temporizador (como si fueran bots) hasta terminar la partida.
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
  waitFor(pred, timeout = 30000, label = 'mensaje') {
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
  lastBalance() {
    const bs = this.messages.filter((m) => m.type === 'balance');
    return bs.length ? bs[bs.length - 1].balance : null;
  }
  close() { this.ws.close(); }
}

test('monedas: bienvenida 5000, cobro al partir y pozo al ganador', async (t) => {
  const store = new Map();
  const wallet = { get: (k) => store.get(k), set: (k, v) => store.set(k, v) };
  const app = createCachoServer({
    botDelayMs: 15, turnTimeoutMs: 200, reconnectGraceMs: 400, wallet,
  });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'clasico', stake: 250, walletToken: 'token-ana-0001' });
  const created = await a.waitType('room_created');
  assert.equal(created.balance, 5000, 'saldo de bienvenida al crear');
  assert.equal(created.stake, 250);

  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Beto', walletToken: 'token-beto-002' });
  const joined = await b.waitType('joined');
  assert.equal(joined.balance, 5000, 'saldo de bienvenida al unirse');
  b.send({ type: 'set_ready', ready: true });

  await a.waitFor((m) => m.type === 'lobby' && m.players.length === 2 && m.players.every((p) => p.ready));
  a.send({ type: 'start_game', fillBots: 0 });
  await a.waitType('game_started');

  // Cobro al partir: ambos quedan en 4750.
  await a.waitFor((m) => m.type === 'balance' && m.balance === 4750);
  await b.waitFor((m) => m.type === 'balance' && m.balance === 4750);
  assert.equal(store.get('token-ana-0001'), 4750);
  assert.equal(store.get('token-beto-002'), 4750);

  // La partida se juega sola (temporizador) y liquida el pozo.
  const over = await a.waitType('game_over', 90000);
  assert.equal(over.pot, 500, 'pozo = 250 x 2');
  const winnerToken = over.winnerId === created.playerId ? 'token-ana-0001' : 'token-beto-002';
  const loserToken = over.winnerId === created.playerId ? 'token-beto-002' : 'token-ana-0001';
  assert.equal(store.get(winnerToken), 5250, 'el ganador se lleva el pozo');
  assert.equal(store.get(loserToken), 4750, 'el perdedor pierde su apuesta');
  a.close();
  b.close();
});

test('monedas: saldo insuficiente bloquea el inicio y no cobra', async (t) => {
  const store = new Map([['token-pobre-03', 120]]);
  const wallet = { get: (k) => store.get(k), set: (k, v) => store.set(k, v) };
  const app = createCachoServer({
    botDelayMs: 15, turnTimeoutMs: 200, reconnectGraceMs: 400, wallet,
  });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Pobre', preset: 'clasico', stake: 500, walletToken: 'token-pobre-03' });
  const created = await a.waitType('room_created');
  assert.equal(created.balance, 120, 'saldo existente se respeta (no se reinicia)');

  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Rico', walletToken: 'token-rico-004' });
  await b.waitType('joined');
  b.send({ type: 'set_ready', ready: true });
  await a.waitFor((m) => m.type === 'lobby' && m.players.length === 2 && m.players.every((p) => p.ready));
  a.send({ type: 'start_game', fillBots: 0 });
  const err = await a.waitFor((m) => m.type === 'error' && m.code === 'saldo_insuficiente');
  assert.match(err.message, /apuesta de 500/);
  assert.equal(store.get('token-pobre-03'), 120, 'no se cobró');
  assert.equal(store.get('token-rico-004'), 5000, 'al otro tampoco');
  a.close();
  b.close();
});
