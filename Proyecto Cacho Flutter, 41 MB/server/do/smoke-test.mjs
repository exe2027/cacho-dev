// Smoke test contra el servidor público (wss) de Cacho.
// Uso: node do/smoke-test.mjs [wss-url]
import WebSocket from 'ws';
import { HttpsProxyAgent } from 'https-proxy-agent';

const URL = process.argv[2] ?? 'wss://cacho-server.vikingosfoodspa.workers.dev';
// En la VM el egress pasa por un proxy CONNECT; en una red normal el
// agente es innecesario (sin HTTPS_PROXY se conecta directo).
const agent = process.env.HTTPS_PROXY
  ? new HttpsProxyAgent(process.env.HTTPS_PROXY)
  : undefined;

function client(name) {
  const ws = new WebSocket(URL, { agent });
  const c = { name, ws, msgs: [], waiters: [] };
  ws.on('message', (d) => {
    const m = JSON.parse(d.toString());
    c.msgs.push(m);
    c.waiters = c.waiters.filter((w) => !w(m));
  });
  c.send = (o) => ws.send(JSON.stringify(o));
  c.waitFor = (type, timeoutMs = 8000) =>
    new Promise((resolve, reject) => {
      const found = c.msgs.find((m) => m.type === type);
      if (found) return resolve(found);
      const w = (m) => (m.type === type ? (resolve(m), true) : false);
      c.waiters.push(w);
      setTimeout(() => reject(new Error(`${name}: timeout esperando ${type}`)), timeoutMs);
    });
  // Espera un mensaje NUEVO (posterior a la llamada) que cumpla el predicado.
  c.waitMatch = (pred, label, timeoutMs = 8000) =>
    new Promise((resolve, reject) => {
      const w = (m) => (pred(m) ? (resolve(m), true) : false);
      c.waiters.push(w);
      setTimeout(() => reject(new Error(`${name}: timeout esperando ${label}`)), timeoutMs);
    });
  c.open = new Promise((res, rej) => { ws.on('open', res); ws.on('error', rej); });
  return c;
}

const assert = (cond, label) => {
  if (!cond) throw new Error(`FALLO: ${label}`);
  console.log(`ok - ${label}`);
};

const a = client('A');
const b = client('B');
await Promise.all([a.open, b.open]);
console.log('ok - ambos clientes conectaron por wss');

a.send({ type: 'create_room', nickname: 'Ana', preset: 'completo' });
const created = await a.waitFor('room_created');
const code = created.code;
assert(code && code.length === 5, `sala creada: ${code}`);

b.send({ type: 'join_room', nickname: 'Beto', code });
const joined = await b.waitFor('joined');
assert(joined.code === code, 'B se unió con el código');

b.send({ type: 'set_ready', ready: true });
// Esperar el lobby donde TODOS figuran listos (evita la carrera entre
// el set_ready de B y el start_game de A).
await new Promise((resolve, reject) => {
  const check = (m) => {
    if (m.type === 'lobby' && m.players.every((p) => p.ready)) { resolve(m); return true; }
    return false;
  };
  if (a.msgs.some(check)) return resolve();
  a.waiters.push(check);
  setTimeout(() => reject(new Error('timeout esperando lobby con todos listos')), 8000);
});
a.send({ type: 'start_game' });
await a.waitFor('game_started');
const [handA, handB] = await Promise.all([a.waitFor('your_hand'), b.waitFor('your_hand')]);
assert(handA.dice.length === 5 && handB.dice.length === 5, 'cada uno recibió SU mano de 5');

const stateA = await a.waitFor('state');
const pub = JSON.stringify(stateA.state);
assert(!pub.includes('hand'), 'el estado público no trae manos');
assert(stateA.state.players.length === 2, 'estado con 2 jugadores');
assert(stateA.state.turnEndsAt === null || typeof stateA.state.turnEndsAt === 'number',
  'estado trae turnEndsAt');

const turn = stateA.state.currentPlayerId;
const [first, other] = turn === created.playerId ? [a, b] : [b, a];
first.send({ type: 'action', action: { type: 'bid', bid: { quantity: 1, face: 2 } } });
const st2 = await other.waitMatch(
  (m) => m.type === 'state' && m.state.currentBid?.quantity === 1,
  'estado con la apuesta aplicada');
assert(st2.state.currentPlayerId !== turn, 'la apuesta se aplicó y rotó el turno');
other.send({ type: 'action', action: { type: 'dudo' } });
const res = await first.waitMatch((m) => m.type === 'resolution', 'resolución');
assert(res.resolution.type === 'dudo', 'resolución de dudo pública llegó');
const totalDice = Object.values(res.resolution.revealedHands).flat().length;
assert(totalDice === 10, `manos reveladas completas (${totalDice})`);
const st3 = await a.waitMatch(
  (m) => m.type === 'state' && m.state.round === 2, 'estado ronda 2');
assert(st3.state.totalDiceInPlay === 9, 'se perdió exactamente 1 dado en la mesa');

a.ws.close(); b.ws.close();
console.log('SMOKE TEST PÚBLICO: TODO OK');
process.exit(0);
