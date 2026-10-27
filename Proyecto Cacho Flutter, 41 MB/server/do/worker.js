// Cacho en línea — Cloudflare Workers + Durable Objects.
//
// Un único Durable Object ("global-v1") contiene el MISMO administrador
// de salas que el servidor Node (server/src/manager.js): la lógica de
// juego es idéntica en local y en producción. El objeto usa WebSockets
// SIN hibernación (server.accept()): mientras haya sockets abiertos la
// instancia vive en memoria, igual que el proceso Node. Si la instancia
// se reinicia (despliegue/fallo), los clientes se reconectan y recuperan
// su asiento con rejoin + deviceToken, como en cualquier reinicio.
import { createRoomManager } from '../src/manager.js';

export class CachoRooms {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    // Billeteras de monedas (ficticias) persistidas en el storage
    // del Durable Object: mapa token -> saldo. Se hidratan antes de
    // atender cualquier mensaje (blockConcurrencyWhile) y se
    // guardan en cada movimiento.
    this._wallets = new Map();
    this.manager = createRoomManager({
      wallet: {
        get: (t) => this._wallets.get(t),
        set: (t, b) => {
          this._wallets.set(t, b);
          this._persistWallets();
        },
      },
    });
    state.blockConcurrencyWhile(async () => {
      try {
        const raw = await state.storage.get('wallets');
        if (raw) this._wallets = new Map(Object.entries(JSON.parse(raw)));
      } catch { /* parte con billeteras vacías */ }
    });
  }

  _persistWallets() {
    try {
      const obj = Object.fromEntries(this._wallets);
      this.state.storage.put('wallets', JSON.stringify(obj)).catch(() => {});
    } catch { /* la memoria sigue siendo la fuente viva */ }
  }

  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === '/health') {
      return Response.json({ ok: true, rooms: this.manager.rooms.size, v: 3 });
    }
    if (request.headers.get('Upgrade') !== 'websocket') {
      return new Response('Cacho server — se esperaba una conexión WebSocket.\n', {
        status: 426,
        headers: { 'content-type': 'text/plain; charset=utf-8' },
      });
    }
    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    server.accept();
    const handle = {
      open: true,
      sendText(str) {
        try { server.send(str); } catch { /* socket muerto */ }
      },
    };
    const ctx = this.manager.handleOpen();
    server.addEventListener('message', (ev) => {
      const data = typeof ev.data === 'string'
        ? ev.data
        : new TextDecoder().decode(ev.data);
      this.manager.handleRaw(handle, ctx, data);
    });
    const onGone = () => {
      if (!handle.open) return;
      handle.open = false;
      this.manager.handleClose(handle, ctx);
    };
    server.addEventListener('close', onGone);
    server.addEventListener('error', onGone);
    return new Response(null, { status: 101, webSocket: client });
  }
}

export default {
  async fetch(request, env) {
    // 'global-v3' (24-oct): la instancia v1 quedó sirviendo el
    // código anterior tras un despliegue (los DO con sockets
    // abiertos no migran al instante) y las salas seguían con el
    // tope de 6. Cada cambio de reglas fuerza una instancia nueva
    // cambiando el nombre; las billeteras en línea parten de
    // nuevo (5.000) y las salas vivas de la instancia anterior
    // se pierden.
    const stub = env.ROOMS.get(env.ROOMS.idFromName('global-v3'));
    return stub.fetch(request);
  },
};
