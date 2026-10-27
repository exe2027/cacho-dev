// Fase A v2.0: la mesa viaja con la sala y el pozo queda fijado al partir.
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
  send(o) {
    this.ws.send(JSON.stringify(o));
  }
  waitType(type, pred = () => true) {
    const found = this.messages.find((m) => m.type === type && pred(m));
    if (found) return Promise.resolve(found);
    return new Promise((resolve) => {
      this.waiters.push({ pred: (m) => m.type === type && pred(m), resolve });
    });
  }
  close() {
    try { this.ws.close(); } catch { /* ya cerrado */ }
  }
}

test('tema neón viaja en la sala y el pozo se fija al partir', async (t) => {
  const app = createCachoServer({ botDelayMs: 20, turnTimeoutMs: 4000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());
  const a = new Client(url);
  await a.ready();
  t.after(() => a.close());
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'completo', stake: 500, theme: 'neon' });
  const created = await a.waitType('room_created');
  assert.equal(created.theme, 'neon');
  const lobby = await a.waitType('lobby');
  assert.equal(lobby.theme, 'neon');
  assert.equal(lobby.stake, 500);
  a.send({ type: 'start_game', fillBots: 1, botDifficulty: 'media' });
  await a.waitType('game_started');
  // 2 jugadores (Ana + 1 bot) × 500 = pozo fijo 1000.
  const state = await a.waitType('state', (m) => m.state && m.state.potFixed != null);
  assert.equal(state.state.theme, 'neon');
  assert.equal(state.state.potFixed, 1000);
  assert.equal(state.state.pot, 1000);
});

test('tema inválido cae a Casino Dorado', async (t) => {
  const app = createCachoServer({ botDelayMs: 20, turnTimeoutMs: 4000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());
  const a = new Client(url);
  await a.ready();
  t.after(() => a.close());
  a.send({ type: 'create_room', nickname: 'Beto', preset: 'completo', stake: 100, theme: '8ball' });
  const created = await a.waitType('room_created');
  assert.equal(created.theme, 'dorado');
});
