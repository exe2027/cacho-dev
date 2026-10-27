# server — Salas en línea (hito 3, HECHO y verificado el 22-oct-2026)

Node.js + WebSockets, **autoritativo**: el servidor posee la instancia del
reglamento, tira los dados con azar seguro y valida cada jugada. A cada
cliente le envía solo su propia mano; las manos ajenas viajan únicamente en
el mensaje de resolución/revelación.

## Correr

```bash
npm install
npm start        # puerto 8080 (o $PORT); GET /health -> {"ok":true,...}
npm test         # 8 tests: motor JS (paridad con Dart) + integración WS en vivo
```

## Protocolo (JSON)

- `create_room {nickname, preset: clasico|completo|custom, config?}` → `room_created {code, playerId, deviceToken}` (código de 5)
- `join_room {code, nickname}` → `joined {...}` + `lobby {players[], hostId}`
- `set_ready {ready}` / `start_game {fillBots, botDifficulty}` (solo anfitrión; mixto humanos+bots)
- `action {type: bid|dudo|calzo|paso|dudoPaso|calzoPaso, bid?}`
- `kamikaze_response {accept}` / `kamikaze_face {face}`
- difusión: `state {…solo información pública…}`, `resolution {…}` con lo revelado, `game_over`
- privado: `your_hand {dice[]}` — solo al dueño, al partir cada ronda y al reconectar
- `rejoin {code, playerId, deviceToken}`: recupera el asiento en la misma partida
- errores: `{type:'error', code, message}` con los mismos códigos del motor Dart

## Comportamiento en partida

- Temporizador por turno (config de sala): si vence, **un bot juega ese turno** y se avisa con `notice {kind:'turn_timeout'}`.
- Desconexión: el bot cubre el asiento de inmediato para que la partida no se detenga; gracia de 60 s y, aun después, el `rejoin` con token devuelve el control dentro de la misma partida.
- Bots de sala y de cobertura: mismo BotBrain binomial que el motor Dart; solo ven su propia mano.
- Push de turno: gancho `notifier({kind:'your_turn'})` en `src/server.js` — listo para conectar FCM/APNs cuando haya credenciales (sin credenciales no se envía push real).

Paridad de reglas: `src/engine.js` y `src/bots.js` son puertos del motor
Dart y comparten guiones y resultados esperados en los tests de ambos
lados (46 tests Dart + 7 unitarios JS + integración).
