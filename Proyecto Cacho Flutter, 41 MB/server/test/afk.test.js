// Abandono (regla del usuario, 22-oct): si a un jugador se le vence
// el tiempo del turno 3 veces seguidas, queda eliminado de la partida
// en vez de que el bot siga jugando por él. Cubre al que se salió del
// juego, perdió internet o dejó el teléfono botado.
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
  close() { this.ws.close(); }
}

test('abandono: 3 tiempos vencidos seguidos eliminan al jugador', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 120 });
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
  b.send({ type: 'set_ready', ready: true });
  await a.waitFor((m) => m.type === 'lobby' && m.players.length === 2 &&
      m.players.every((p) => p.ready));
  a.send({ type: 'start_game', fillBots: 0 });
  await a.waitType('game_started');

  // Nadie juega nunca: los turnos se vencen por temporizador y los
  // bots cubren los dos primeros de cada uno. Al tercero seguido, el
  // jugador queda eliminado y la partida termina con el otro ganador.
  const notice = await a.waitFor(
      (m) => m.type === 'notice' && m.kind === 'afk_eliminated', 30000,
      'aviso de eliminación por abandono');
  const eliminatedId = notice.playerId;
  assert.ok([created.playerId, joined.playerId].includes(eliminatedId));

  const res = await a.waitFor(
      (m) => m.type === 'resolution' && m.resolution.type === 'abandono',
      30000, 'resolución de abandono');
  assert.equal(res.resolution.loserId, eliminatedId);

  const over = await a.waitType('game_over', 30000);
  const winnerId = created.playerId === eliminatedId
      ? joined.playerId
      : created.playerId;
  assert.equal(over.winnerId, winnerId,
      'gana el jugador que sí estaba presente');

  // Antes de la eliminación hubo avisos de tiempo vencido con la
  // cuenta de strikes del eliminado (1 y 2).
  const strikes = a.messages
      .filter((m) => m.type === 'notice' && m.kind === 'turn_timeout' &&
          m.playerId === eliminatedId)
      .map((m) => m.strikes);
  assert.deepEqual(strikes, [1, 2]);

  a.close();
  b.close();
});
