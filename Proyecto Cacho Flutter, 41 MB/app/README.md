# app — Flutter (hito 4, pendiente)

Un solo código para **APK Android, web (PWA) e iOS**, solo vertical,
pensada para una mano. La web sirve además para probar en iPhone sin
App Store; jugadores web y APK comparten las mismas salas del servidor.
Compila con `flutter build apk` y `flutter build web` desde el mismo
código — ver `docs/03-correr-y-publicar.md`.
Consume `packages/cacho_engine` directamente para el modo contra bots
(offline) y se conecta al `server/` para salas en línea, detrás de la
interfaz abstracta `GameTransport` (la fase 2 de cercanía —Nearby
Connections / Multipeer, con el celular anfitrión como servidor— se
implementa como otro `GameTransport` sin tocar UI ni motor).

Pantallas: inicio (apodo/avatar) → crear/unirse a sala (código o enlace
WhatsApp) → lobby (listos) → partida (mesa casino según
`docs/02-guia-de-diseno.md`) → fin de partida.

Requisitos en partida: agitar con acelerómetro (+ botón), háptica,
pantalla siempre encendida, textos en español de Chile, opción de efectos
reducidos, modo daltonismo por símbolos en las pintas.
