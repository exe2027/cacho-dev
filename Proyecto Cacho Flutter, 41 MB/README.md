# Cacho

Juego chileno del Dudo: Flutter unificado (Web, Android, iOS, paisaje horizontal 844×390) + servidor Node.js/WebSockets autoritativo + motor de reglas en Dart puro testeado.

## Estructura

```
cacho/
  docs/
    01-arquitectura-y-decisiones.md   Reglas fijadas y arquitectura
    02-guia-de-diseno.md              Paleta casino/cuero, tipografías, animaciones
    03-correr-y-publicar.md           Emulador, celular real, Play Store y App Store
  packages/
    cacho_engine/                     Motor Dart puro + bots (con tests)
      lib/cacho_engine.dart
      lib/bots.dart
      test/
  server/                             Salas en línea (Node + WebSockets) — hito 3
  app/                                Flutter — hito 4
```

## Probar el motor (sin Flutter)

```bash
cd packages/cacho_engine
../../toolchain/dart-sdk/bin/dart pub get
../../toolchain/dart-sdk/bin/dart test
```
