// Sonda contra PRODUCCIÓN: ¿la sala acepta 12 y rechaza al 13?
import WebSocket from 'ws';

const URL = 'wss://cacho-server.vikingosfoodspa.workers.dev';

function client() {
  const ws = new WebSocket(URL);
  const c = { ws, msgs: [] };
  ws.on('message', (d) => c.msgs.push(JSON.parse(d.toString())));
  c.ready = new Promise((res, rej) => { ws.on('open', res); ws.on('error', rej); });
  c.send = (o) => ws.send(JSON.stringify(o));
  c.wait = (pred, ms = 12000) => new Promise((res, rej) => {
    const t0 = Date.now();
    const iv = setInterval(() => {
      const m = c.msgs.find(pred);
      if (m) { clearInterval(iv); res(m); }
      else if (Date.now() - t0 > ms) { clearInterval(iv); rej(new Error('timeout')); }
    }, 100);
  });
  return c;
}

const host = client();
await host.ready;
host.send({ type: 'create_room', nickname: 'Sonda', preset: 'completo', walletToken: 'probe-host' });
const created = await host.wait((m) => m.type === 'room_created');
console.log('SALA:', created.code);

const results = [];
for (let i = 1; i <= 12; i++) {
  const g = client();
  await g.ready;
  g.send({ type: 'join_room', code: created.code, nickname: 'Sonda' + i, walletToken: 'probe-' + i });
  try {
    const j = await g.wait((m) => m.type === 'joined' || m.type === 'error', 8000);
    results.push(i + ':' + (j.type === 'joined' ? 'joined' : 'ERROR ' + j.code));
  } catch {
    results.push(i + ':TIMEOUT');
  }
  g.ws.close();
}
console.log(results.join(' '));
host.ws.close();
process.exit(0);
