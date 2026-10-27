// Voz en sala: estado de micrófono y relevo de señalización WebRTC
// solo entre asientos de la misma sala.
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

test('voz: mic se difunde y la señalización solo viaja dentro de la sala', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, reconnectGraceMs: 400 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'clasico' });
  const created = await a.waitType('room_created');
  const aId = created.playerId;

  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Beto' });
  const joined = await b.waitType('joined');
  const bId = joined.playerId;
  await a.waitFor((m) => m.type === 'lobby' && m.players.length === 2);

  // --- mic: el aviso llega al otro y queda en el lobby ---
  a.send({ type: 'mic', on: true });
  const micMsg = await b.waitFor((m) => m.type === 'mic' && m.playerId === aId);
  assert.equal(micMsg.on, true);
  // El próximo lobby (al cambiar la lista) ya trae el estado del mic.
  b.send({ type: 'set_ready', ready: true });
  const lobby = await b.waitFor(
    (m) => m.type === 'lobby' && m.players.find((p) => p.id === aId)?.micOn === true,
  );
  assert.ok(lobby, 'el lobby refleja micOn');

  // --- señalización A -> B dentro de la sala ---
  a.send({ type: 'voice_signal', to: bId, data: { kind: 'offer', sdp: 'sdp-x', type: 'offer' } });
  const sig = await b.waitFor((m) => m.type === 'voice_signal' && m.from === aId);
  assert.equal(sig.data.sdp, 'sdp-x');

  // --- señalización a un id inexistente: no llega a nadie ---
  const before = b.messages.filter((m) => m.type === 'voice_signal').length;
  a.send({ type: 'voice_signal', to: 'no-existe', data: { kind: 'ice', candidate: 'c' } });
  await sleep(250);
  assert.equal(
    b.messages.filter((m) => m.type === 'voice_signal').length,
    before,
    'una señal a un id fuera de la sala no se releva',
  );

  // --- otra sala no recibe señales de esta ---
  const c = new Client(url);
  await c.ready();
  c.send({ type: 'create_room', nickname: 'Cata', preset: 'clasico' });
  const createdC = await c.waitType('room_created');
  a.send({ type: 'voice_signal', to: createdC.playerId, data: { kind: 'offer', sdp: 'x' } });
  await sleep(250);
  assert.equal(
    c.messages.filter((m) => m.type === 'voice_signal').length,
    0,
    'entre salas no hay relevo',
  );

  // --- al desconectarse con el mic encendido, se avisa el apagado ---
  a.close();
  const off = await b.waitFor(
    (m) => m.type === 'mic' && m.playerId === aId && m.on === false,
    5000,
    'mic off por desconexión',
  );
  assert.ok(off);
  b.close();
  c.close();
});
