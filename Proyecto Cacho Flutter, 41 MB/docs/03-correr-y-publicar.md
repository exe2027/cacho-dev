# Cacho — Correr y publicar

## Motor (sin Flutter, verificable hoy)

```bash
cd packages/cacho_engine
../../toolchain/dart-sdk/bin/dart pub get   # la VM ya trae el SDK en cacho/toolchain
../../toolchain/dart-sdk/bin/dart test
```

## App Flutter (hito 4)

Requiere Flutter SDK 3.x (no viene en esta VM Linux; en un Mac/PC de desarrollo):

```bash
cd app
flutter pub get
flutter run                    # emulador o celular conectado por USB
```

- **Emulador Android:** Android Studio → Device Manager → crear AVD (API 34) → `flutter run`.
- **Celular Android real:** activar Opciones de desarrollador + Depuración USB; o generar APK: `flutter build apk --release` e instalar el archivo.
- **iPhone real:** solo desde Mac con Xcode (cuenta Apple); en Windows/Linux usar CI (Codemagic / GitHub Actions con runner macOS) que firma y sube a TestFlight.
- **Web (mismo código):** `flutter build web --release` genera una carpeta estática que se sirve en cualquier hosting (incluido el mismo servidor o un CDN); queda como PWA instalable y es la vía rápida para probar en iPhone. El cliente web se conecta al mismo servidor WebSocket (`wss://`).

## Servidor (hito 3) y modo en línea público (master prompt v2, 22-oct)

```bash
cd server
npm install
npm start    # WebSockets en el puerto indicado por PORT (def. 8080)
```

La lógica de salas vive en `server/src/manager.js` (agnóstica de
transporte, con `turnEndsAt` en el estado público); `server.js` es el
adaptador Node/`ws` y `server/do/worker.js` corre el MISMO manager dentro
de un Durable Object de Cloudflare. Producción:

- **wss://cacho-server.vikingosfoodspa.workers.dev** (Worker `cacho-server`,
  binding ROOMS → clase `CachoRooms`, migración `new_sqlite_classes` por
  plan gratuito). La app lo lleva como constante interna (`lib/config.dart`);
  no hay campo de servidor en la UI y 10.0.2.2 quedó prohibida.
- Bundle: `node server/do/build.mjs` (esbuild, `node:crypto` externo con
  `nodejs_compat`). Despliegue:
  `python3 ~/workspace/custom-connectors/custom.legacy-cloudflare/bin/deploy-cacho-server.py --account-id 27afc37225a02fd92557f901c05dabee --bundle server/do/dist/worker.js`
- Prueba pública de humo (2 clientes, privacidad de manos, dudo):
  `node server/do/smoke-test.mjs` (en la VM requiere HTTPS_PROXY; en red
  normal conecta directo).
- Salud: `GET https://cacho-server.vikingosfoodspa.workers.dev/health`.

Web: `flutter build web --release` → despliegue directo a Cloudflare Pages
(proyecto `cacho`, https://cacho.pages.dev) con
`/tmp/cfvenv/bin/python ~/workspace/custom-connectors/custom.legacy-cloudflare/bin/deploy-pages.py --project cacho --dir app/build/web`.

## Publicación

**Google Play:** cuenta de desarrollador (USD 25 una vez) → `flutter build appbundle --release` → Play Console: ficha (sin prometer dinero: es juego social sin apuestas reales, declararlo así en el cuestionario de contenido), clasificación, política de privacidad (apodo + token de dispositivo; sin cuentas), prueba cerrada (14 días / 12 testers para cuentas nuevas) → producción.

**App Store:** Apple Developer (USD 99/año) → build desde Mac o CI → App Store Connect: ficha, revisión (declarar "sin apuestas de dinero real"), TestFlight → revisión → publicación.

Firma Android: conservar el keystore de release fuera del repo; perderlo impide actualizar la app.
