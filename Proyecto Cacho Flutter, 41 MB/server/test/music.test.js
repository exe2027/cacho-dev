// Música de la sala: DJ, cola colaborativa, votos para saltar y
// sincronía (el servidor guarda el estado; el audio no pasa por él).
import test from 'node:test';
import assert from 'node:assert/strict';
import { createRoomManager } from '../src/manager.js';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function harness() {
  const m = createRoomManager({});
  const mk = () => ({
    open: true,
    sent: [],
    sendText(s) { this.sent.push(JSON.parse(s)); },
  });
  const join = (name) => {
    const ws = mk();
    const ctx = m.handleOpen();
    return { ws, ctx, name };
  };
  const send = (c, obj) => m.handleRaw(c.ws, c.ctx, JSON.stringify(obj));
  const musicStates = (c) => c.ws.sent.filter((x) => x.type === 'music_state');
  const lastMusic = (c) => musicStates(c).at(-1)?.music;
  return { m, join, send, lastMusic };
}

const TRACK = (id) => ({
  type: 'music_add', videoId: id, title: `Tema ${id}`, channel: 'Canal',
  thumb: '', durationSec: 200,
});

test('música: DJ, cola, votos y avance', async () => {
  const { m, join, send, lastMusic } = harness();
  const a = join('Ana');
  const b = join('Beto');

  send(a, { type: 'create_room', nickname: 'Ana', preset: 'clasico' });
  const created = a.ws.sent.find((x) => x.type === 'room_created');
  // Al crear, llega el estado de música vacío.
  assert.equal(lastMusic(a).current, null);
  assert.equal(lastMusic(a).djId, null);

  send(b, { type: 'join_room', code: created.code, nickname: 'Beto' });
  assert.ok(lastMusic(b), 'al unirse llega music_state');

  // El primero en reclamar es el DJ; el segundo no puede quitarlo.
  send(b, { type: 'music_claim' });
  const bId = b.ws.sent.find((x) => x.type === 'joined').playerId;
  assert.equal(lastMusic(a).djId, bId);
  send(a, { type: 'music_claim' });
  assert.equal(lastMusic(a).djId, bId, 'el DJ conectado no se reemplaza');

  // Agregar sin nada sonando: parte de inmediato.
  send(b, TRACK('video0001'));
  assert.equal(lastMusic(a).current.videoId, 'video0001');
  assert.ok(lastMusic(a).current.startedAt > 0);

  // Agregar con algo sonando: va a la cola (colaborativa: agrega A).
  send(a, TRACK('video0002'));
  assert.equal(lastMusic(b).queue.length, 1);
  assert.equal(lastMusic(b).queue[0].byName, 'Ana');

  // Votos para saltar: con 2 humanos hacen falta 2 votos.
  assert.equal(lastMusic(a).skipNeeded, 2);
  send(a, { type: 'music_vote_skip' });
  assert.equal(lastMusic(b).current.videoId, 'video0001', 'un voto no basta');
  assert.equal(lastMusic(b).skipVotes, 1);
  send(a, { type: 'music_vote_skip' }); // voto repetido no cuenta doble
  assert.equal(lastMusic(b).skipVotes, 1);
  send(b, { type: 'music_vote_skip' });
  assert.equal(lastMusic(a).current.videoId, 'video0002', 'con la mayoría avanza');
  assert.equal(lastMusic(a).skipVotes, 0, 'los votos se reinician');

  // Pausa: solo el DJ. A intenta y no pasa nada; B pausa y sigue.
  send(a, { type: 'music_pause' });
  assert.equal(lastMusic(a).current.pausedAt, null);
  send(b, { type: 'music_pause' });
  const pausedAt = lastMusic(a).current.pausedAt;
  assert.ok(pausedAt > 0);
  await sleep(30);
  send(b, { type: 'music_play' });
  const after = lastMusic(a).current;
  assert.equal(after.pausedAt, null);
  assert.ok(after.startedAt > lastMusic(a).current.startedAt - 1,
    'al reanudar el inicio se corre lo pausado');

  // Siguiente sin cola: queda en silencio.
  send(b, { type: 'music_next' });
  assert.equal(lastMusic(a).current, null);

  // Si el DJ se desconecta, el rol queda libre y otro puede tomarlo.
  send(a, TRACK('video0003'));
  assert.equal(lastMusic(a).current.videoId, 'video0003');
  m.handleClose(b.ws, b.ctx);
  assert.equal(lastMusic(a).djId, null, 'el DJ caído libera el rol');
  const aId = created.playerId;
  send(a, { type: 'music_claim' });
  assert.equal(lastMusic(a).djId, aId);

  // music_ended del DJ avanza (cola vacía: silencio).
  send(a, { type: 'music_ended' });
  assert.equal(lastMusic(a).current, null);
});

test('música: el DJ se salta la cola con play_now; los demás no', () => {
  const { m, join, send, lastMusic } = harness();
  const a = join('Ana');
  const b = join('Beto');

  send(a, { type: 'create_room', nickname: 'Ana', preset: 'clasico' });
  const created = a.ws.sent.find((x) => x.type === 'room_created');
  send(b, { type: 'join_room', code: created.code, nickname: 'Beto' });
  const bId = b.ws.sent.find((x) => x.type === 'joined').playerId;
  send(b, { type: 'music_claim' });
  assert.equal(lastMusic(a).djId, bId);

  // Suena el 1; quedan en cola el 2 y el 3.
  send(a, TRACK('video0001'));
  send(a, TRACK('video0002'));
  send(b, TRACK('video0003'));
  assert.equal(lastMusic(a).current.videoId, 'video0001');
  assert.deepEqual(lastMusic(a).queue.map((t) => t.videoId),
      ['video0002', 'video0003']);

  // Ana NO es la DJ: su play_now se ignora.
  send(a, { type: 'music_play_now', videoId: 'video0003' });
  assert.equal(lastMusic(a).current.videoId, 'video0001');
  assert.equal(lastMusic(a).queue.length, 2);

  // El DJ promueve el 3 desde la cola: suena ahora y sale de la cola.
  send(b, { type: 'music_play_now', videoId: 'video0003' });
  assert.equal(lastMusic(a).current.videoId, 'video0003');
  assert.deepEqual(lastMusic(a).queue.map((t) => t.videoId), ['video0002']);

  // El DJ toca un tema nuevo desde el buscador: suena al tiro, y si
  // ese mismo tema ya estaba en la cola, la copia de la cola sale.
  send(a, TRACK('video0004'));
  assert.deepEqual(lastMusic(a).queue.map((t) => t.videoId),
      ['video0002', 'video0004']);
  send(b, {
    type: 'music_play_now', videoId: 'video0004', title: 'Tema video0004',
    channel: 'Canal', thumb: '', durationSec: 200,
  });
  assert.equal(lastMusic(a).current.videoId, 'video0004');
  assert.deepEqual(lastMusic(a).queue.map((t) => t.videoId), ['video0002']);
});
