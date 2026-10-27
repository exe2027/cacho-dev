// Sala activa (pedido del usuario, 22-oct en la noche): si el
// jugador sale sin querer del navegador (atrás, recarga, cierra la
// pestaña) y vuelve, la app le ofrece "Entrar a la sala activa".
// El servidor lo soporta con dos piezas: 'room_status' (consulta sin
// efectos: ¿la sala vive? ¿este dispositivo tiene asiento?) y el
// reclamo de asiento por token de billetera en 'rejoin' (el
// dispositivo que vuelve ya no guarda playerId/deviceToken de la
// sesión anterior; la billetera es su identidad persistente).
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
  waitFor(pred, timeout = 15000, label = 'mensaje') {
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

test('room_status y reclamo de asiento por billetera', async (t) => {
  const app = createCachoServer({ botDelayMs: 15, turnTimeoutMs: 60000 });
  const port = await app.listen(0);
  const url = `ws://127.0.0.1:${port}`;
  t.after(() => app.close());

  // Sonda: un socket suelto que solo pregunta.
  const probe = new Client(url);
  await probe.ready();
  const ask = async (code, walletToken) => {
    probe.messages = probe.messages.filter((m) => m.type !== 'room_status');
    probe.send({ type: 'room_status', code, walletToken });
    return probe.waitType('room_status');
  };

  const noRoom = await ask('ZZZZZ', 'wallet-ana');
  assert.equal(noRoom.exists, false);
  assert.equal(noRoom.member, false);

  const a = new Client(url);
  await a.ready();
  a.send({ type: 'create_room', nickname: 'Ana', preset: 'clasico', walletToken: 'wallet-ana' });
  const created = await a.waitType('room_created');

  const b = new Client(url);
  await b.ready();
  b.send({ type: 'join_room', code: created.code, nickname: 'Beto', walletToken: 'wallet-beto' });
  const joined = await b.waitType('joined');

  const inLobby = await ask(created.code, 'wallet-ana');
  assert.equal(inLobby.exists, true);
  assert.equal(inLobby.phase, 'lobby');
  assert.equal(inLobby.member, true);
  assert.equal(inLobby.connected, true);

  const stranger = await ask(created.code, 'wallet-nadie');
  assert.equal(stranger.exists, true);
  assert.equal(stranger.member, false);

  b.send({ type: 'set_ready', ready: true });
  await a.waitFor((m) => m.type === 'lobby' && m.players.length === 2 &&
      m.players.every((p) => p.ready));
  a.send({ type: 'start_game', fillBots: 0 });
  await a.waitType('game_started');

  // Beto "se sale del navegador": cierra el socket. Su asiento queda
  // en la mesa, cubierto por un bot.
  b.close();
  await new Promise((r) => setTimeout(r, 300));

  const inGame = await ask(created.code, 'wallet-beto');
  assert.equal(inGame.exists, true);
  assert.equal(inGame.phase, 'playing');
  assert.equal(inGame.member, true);
  assert.equal(inGame.connected, false);

  // Beto vuelve en un socket nuevo, sin playerId ni deviceToken:
  // solo su token de billetera. Recupera SU asiento.
  const b2 = new Client(url);
  await b2.ready();
  b2.send({ type: 'rejoin', code: created.code, walletToken: 'wallet-beto' });
  const rejoined = await b2.waitType('rejoined');
  assert.equal(rejoined.playerId, joined.playerId);
  assert.ok(rejoined.deviceToken, 'el reclamo devuelve el deviceToken del asiento');
  await b2.waitType('state');

  // Con Beto conectado de nuevo, un tercero con su billetera NO
  // puede robarle el asiento.
  const thief = new Client(url);
  await thief.ready();
  thief.send({ type: 'rejoin', code: created.code, walletToken: 'wallet-beto' });
  const err = await thief.waitType('error');
  assert.equal(err.code, 'token_invalido');

  probe.close();
  a.close();
  b2.close();
  thief.close();
});
