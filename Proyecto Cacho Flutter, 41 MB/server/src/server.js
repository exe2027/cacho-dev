// Servidor de salas de Cacho: Node.js + WebSockets, AUTORITATIVO.
// Adaptador delgado: la lógica de salas vive en manager.js (agnóstica de
// transporte) y aquí solo se conecta con http + el paquete `ws`.
// El mismo manager corre dentro del Durable Object de Cloudflare
// (server/do/worker.js) para el despliegue público wss.
import http from 'node:http';
import { pathToFileURL } from 'node:url';
import { WebSocketServer } from 'ws';
import { createRoomManager } from './manager.js';

export function createCachoServer(options = {}) {
  const manager = createRoomManager(options);
  const rooms = manager.rooms;

  const httpServer = http.createServer((req, res) => {
    if (req.url === '/health') {
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ ok: true, rooms: rooms.size }));
    } else if (req.url === '/') {
      res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
      res.end('Cacho server — WebSocket en esta misma dirección.\n');
    } else {
      res.writeHead(404);
      res.end();
    }
  });
  const wss = new WebSocketServer({ server: httpServer });

  wss.on('connection', (ws) => {
    const handle = {
      get open() { return ws.readyState === 1; },
      sendText(str) { ws.send(str); },
    };
    const ctx = manager.handleOpen();
    ws.on('message', (data) => manager.handleRaw(handle, ctx, data.toString()));
    ws.on('close', () => manager.handleClose(handle, ctx));
  });

  return {
    httpServer,
    wss,
    rooms,
    listen(port = 0) {
      return new Promise((resolve) => {
        httpServer.listen(port, () => resolve(httpServer.address().port));
      });
    },
    async close() {
      manager.clearAll();
      for (const client of wss.clients) client.terminate();
      await new Promise((r) => wss.close(() => r()));
      await new Promise((r) => httpServer.close(() => r()));
    },
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT ?? 8080);
  const app = createCachoServer({
    notifier: (n) => {
      if (n.kind === 'your_turn') {
        // Gancho FCM/APNs: aquí irá el push real cuando haya credenciales.
        console.log(`[push] turno de ${n.playerId} en sala ${n.roomCode}`);
      }
    },
  });
  app.listen(port).then((p) => console.log(`Cacho server escuchando en :${p}`));
}
