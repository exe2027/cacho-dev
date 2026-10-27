# CACHO — El Dudo Chileno

Juego tradicional chileno del Cacho / Dudo (el arte de mentir con dados ocultos en un cacho de cuero). 
**Arquitectura unificada 100% en Flutter (Dart)** para todos los destinos: **Web, Android y Apple (iOS)**, integrando renders y assets 3D de alta fidelidad modelados en Blender. Motor de reglas puro en Dart con 77/77 tests exhaustivos y servidor autoritativo Node.js + WebSockets / Cloudflare Workers con 37/37 tests unitarios en verde.

Toda la aplicación es **estrictamente horizontal** (844×390 de referencia): tanto el Menú Principal / Lobby de mesas estilo casino como la Mesa de juego.

> **Regla de oro:** El usuario es el dueño del proyecto. Nada se despliega a producción ni se commitea sin su sí explícito.

---

## Estado del Proyecto

### 1. Lo que se Hizo
* **Motor de reglas puro en Dart (`packages/cacho_engine`):** 77/77 tests unitarios en verde. Reglas chilenas oficiales: subida clásica, ases restrictivos (no al inicio, mitad para entrar, doble+1 para salir), Paso (5 dados, faroleable, límites por ronda), Calzo estricto con umbral de recuperación (`totalActual × 2 > totalInicial`), Calzo perfecto (bloqueado en total bajo) y Kamikaze a ciegas.
* **Servidor autoritativo (`server/`):** 37/37 tests pasando. Gestión de salas privadas, privacidad estricta de dados por WebSockets, bots de reemplazo, temporizador de 60 s con 3 strikes y señalización WebRTC para voz y música DJ de YouTube.
* **Modelado 3D de Assets (Blender Cycles):** Mesa ovalada de madera oscura, vasos de cuero ("cachos"), dados con pipas nítidas, monedas 3D y texturas de paño carbón y dorado mate `#C9A24B`.
* **Rediseño del Lobby Horizontal (`home_screen.dart`):** Inspirado en Monopoly Poker (`WhatsApp Image 2026-10-26 at 8.09.18 PM (3).jpeg`) con carrusel horizontal interactivo de 6 tiers (Tutorial Guiado, La Taberna $100, El Boliche $250, El Casino $500, La Mansión $1.000 y El Club VIP $2.500), doble barra de saldo (fichas doradas + cash virtual `$0`), botón de rescate diario y cápsula inferior de perfil del jugador.
* **Mesa de Juego 6 Jugadores (`game_screen.dart`):** Alineada con [`img/mockup.jpeg`](img/mockup.jpeg): mesa ovalada con 6 posiciones sin solapes, sello "CACHO O DUDO", pozo central estilo ficha de casino con gradiente azul marino y borde dorado, dados ocultos bajo el cacho con botón VER / agitar, consola inferior con tiles 1–6 + CALZO + DUDO + PASO, botón flotante de chat/reacciones (`Icons.chat_bubble_rounded`) y modal interactivo de frases típicas chilenas.

* **Conexión Total Lobby-Mesa (`home_screen.dart`):** Selección interactiva en carrusel con tap-to-focus, bordes de neón activos, cobro de buy-in automático según tier (`$100` a `$2.500`), pozo fijo correspondiente a 6 jugadores, fondos temáticos dinámicos y acceso directo con un toque para crear salas privadas en línea.

### 2. Lo que se está haciendo
* **Validación con el Usuario:** Revisión del diseño consolidado de la mesa y el lobby horizontal para aprobar el paso a la siguiente fase.

### 3. Lo que está por hacerse
* **Autenticación y Billetera en la Nube:** Firebase Auth (Google y email link) con persistencia de saldo por UID en Firestore (sin perder la experiencia anónima inicial).
* **Tienda y Personalización:** Cosméticos para cachos de cuero y dados (visibles por rivales/propios).
* **Sistema de Progresión:** Ligas (Bronce, Plata, Oro), rankings globales y niveles (tope 300) con XP por partidas ganadas.

---

## Producción

* **Web:** https://cacho.pages.dev (Cloudflare Pages, proyecto `cacho`)
* **Servidor:** wss://cacho-server.vikingosfoodspa.workers.dev (Worker `cacho-server`, Durable Object `CachoRooms`)
* **Salud:** https://cacho-server.vikingosfoodspa.workers.dev/health

---

## Estructura del Código

```text
app/                    Cliente Flutter unificado (Web, iOS y Android horizontal)
  lib/                  Pantallas (Home, Lobby, Mesa), estado, widgets y audio
  web/                  index.html, yt_bridge.js (puente YouTube en web)
  assets/images/        Sprites y texturas de alta resolución (mesa, vasos, dados, botones)
  assets/sounds/        Música procedural y efectos de sonido
packages/cacho_engine/  Motor puro en Dart (reglas, bots y validaciones, sin UI)
server/                 Servidor autoritativo (Node.js + WebSockets)
  src/                  manager.js (salas), engine.js (reglas), server.js
  do/                   Worker de Cloudflare (Durable Object CachoRooms)
  test/                 Tests del servidor (37/37 en verde)
docs/                   Documentación del proyecto (01–19)
img/                    Mockups y referencias de diseño (mockup.jpeg, Monopoly Poker, Parchisi Star)
memory.md               Memoria de decisiones maestras, historial y backlog del proyecto
README.md               Visión general y estado activo del proyecto
```

---

## Ejecución y Pruebas

### Motor en Dart (sin Flutter)
```bash
cd packages/cacho_engine
dart pub get
dart test
```

### Cliente Flutter
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome          # Web en desarrollo (horizontal 844x390)
flutter build web --release    # Compilación de producción
```

### Servidor Node.js
```bash
cd server
npm install
npm start                      # WebSockets en puerto 8080
npm test                       # Suite completa de tests (37 tests)
```

---

## Reglas del Juego en Resumen

Subida clásica; primera apuesta nunca ases; Paso con límites (máx 1 por jugador por ronda, nunca primero, nunca dos seguidos); Calzo siempre permitido pero con recuperación solo si `totalActual × 2 > totalInicial`; Calzo perfecto (5 dados exactos) quita 1 dado a los demás salvo con total bajo, donde no da ni quita nada; Kamikaze a ciegas entre rondas; 2 a 6 jugadores; mis dados ocultos bajo mi vaso con botón VER (agitar = tirar, VER = mirar); 60 s por turno, 3 vencimientos seguidos = eliminación por abandono.

## Juego Social
Cacho es un juego social con monedas virtuales sin valor monetario ni apuestas de dinero real.
