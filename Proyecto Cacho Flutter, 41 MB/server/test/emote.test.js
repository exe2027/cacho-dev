// Reacciones rápidas (docs/19 C9, chat fuera): relevo puro en la
// sala, sin estado en el servidor y sin tocar ningún mensaje
// existente. El glifo se valida contra el conjunto fijo de la app.
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
  waitFor(pred, timeout = 5000, label = 'mensaje') {
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

async function twoPlayers(t) {
  const app = createCachoServer({ botDelayMs: 15 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());
  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'clasico' });
  const created = await a.waitType('room_created');
  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Beto' });
  const joined = await b.waitType('joined');
  await a.waitFor((m) => m.type === 'lobby' && m.players.length === 2);
  return { a, b, aId: created.playerId, bId: joined.playerId };
}

test('emote: el glifo válido se difunde a la sala con el remitente', async (t) => {
  const { a, b, aId } = await twoPlayers(t);
  t.after(() => { a.close(); b.close(); });
  a.send({ type: 'emote', emote: '🔥' });
  const got = await b.waitFor((m) => m.type === 'emote' && m.playerId === aId);
  assert.equal(got.emote, '🔥');
});

test('emote: un glifo fuera del conjunto fijo no se difunde ni da error', async (t) => {
  const { a, b } = await twoPlayers(t);
  t.after(() => { a.close(); b.close(); });
  a.send({ type: 'emote', emote: '💣' });
  await sleep(400);
  assert.equal(b.messages.some((m) => m.type === 'emote'), false);
  assert.equal(a.messages.some((m) => m.type === 'error'), false);
});
