# Master Prompt v2 (recibido 2026-10-22, DESPUÉS de los hitos 1-4)

Documento rector de la mejora de la app. Si algo de la app actual lo
contradice, manda este documento. El texto completo está en el chat
(side chat Cacho, mensaje del usuario 2026-10-22 03:19 -03); este archivo
resume los mandatos operativos y las diferencias contra lo construido.

## Mandatos clave
- Principio rector: un principiante hace su primera apuesta y puede
  explicar por qué perdió un dado, sin ayuda externa. Cada pantalla
  responde: qué pasó, qué me toca hacer, qué pasa si lo hago.
- URL del servidor en configuración interna (wss pública); sin campo
  "Servidor" en la app; 10.0.2.2 jamás en producción.
- Apodo máximo 12 caracteres.
- Apuesta siempre como "4 × [dado] Cuadras" (número + dado + nombre).
- Home SIN scroll: logo, Contra la máquina, Con amigos, Cómo se juega;
  apodo y cuero dentro de "Personalizar".
- Onboarding "Cómo se juega" en 4 pantallas + primera partida guiada
  (bots lentos que explican su jugada en una línea, globos y flechas,
  se puede saltar, no se repite) + glosario "?" + opción "Ayuda para
  principiantes" (estimación de probabilidad de mi apuesta).
- Mesa estilo esquinas (yo abajo a la izquierda), globos con la última
  jugada de cada jugador, aro de progreso = temporizador en el turno,
  historial completo en cajón (últimas 3 al centro), texto mínimo 14px.
- Mi cacho grande abajo: dados ocultos, se ven al mantener presionado
  o con el ojo, bandeja encima del cacho; en mi turno se muestran solos
  (opción de ocultar). SIN botón fijo "Agita tu cacho" en la partida:
  el lanzamiento es animación al inicio de cada ronda + gesto de agitar.
- Banner fijo de estado con frases completas (qué pasó / qué me toca).
- Barra de acciones SIEMPRE visible (nunca "…"): Subir/Dudo/Calzo/Paso/
  Kamikaze, ≥56px, subtítulos ("No te creo", "Es exacto"…), deshabilitado
  con el motivo escrito.
- Panel de apuesta como hoja inferior: "Vas a decir: 6 Sextas" +
  traducción, controles Cantidad y Pinta separados, atajos (+1 cantidad /
  misma cantidad pinta mayor), mínimo permitido, dados en mesa y míos,
  explicación al entrar/salir de ases, confirmar con la apuesta final.
- Revelación en 3 pasos con velocidad ajustable y botón Saltar:
  encabezado, dados iluminados (comodines etiquetados), contador
  animado, veredicto en una oración con motivo, botón
  "Seguir (parte [nombre])".
- Presets con "Ver qué cambia" generado desde la configuración real.
- Sonidos nuevos: fichas, murmullo de fondo, distintivos por acción;
  volumen separado y silencio general. Opción de efectos reducidos.
- Temporizador de turno configurable por sala.
- Código de sala 4-6 caracteres (hoy 5: compatible).

## Confirmado por el usuario (2026-10-22 03:23)
1. Nombre del 2: **Pato** (manda su corrección del 22-oct, no "Tonto").
2. **Hacer el modo en línea**: servidor público con wss (propuesta
   aceptada: Cloudflare Workers + Durable Objects, misma cuenta).
3. Partida guiada: **2 bots** lentos.
4. Temporizador de turno por defecto: **30 s** — "Correcto".

## Dirección de diseño pedida por él (2026-10-22 04:02, con captura de Parchís)
- La mesa debe leerse como MESA de verdad, estilo Parchís: cada jugador
  anclado a una esquina de la pantalla (avatar redondo + apodo en pastilla
  oscura), el tablero/paño al centro; el turno se nota en la esquina
  activa (brillo/flecha). Yo abajo a la izquierda.
- Mi esquina: avatar + SOLO un vaso/cacho grande, sin bandeja permanente.
- Flujo del lanzamiento como momento: girar/agitar el vaso → el vaso SE
  LEVANTA → se ven mis dados → recién ahí aparece la pantalla de apostar.
- Ritmo más rápido que el actual, sin perder claridad (la guiada sigue
  lenta: está enseñando).
- Proceso fijado por él (03:59): auditoría primero; corregir UNA pantalla
  por vez en orden partida → panel de apuesta → revelación → inicio;
  detenerse con captura en cada pantalla hasta su aprobación; sin cambiar
  reglas y sin agregar funciones no pedidas.
- Sus capturas de "lo que está mal" son de la versión ANTERIOR al
  rediseño v2 (caché de la PWA en su iPhone): campo servidor, botón
  "Agita tu cacho" y botón "…" solo existen en esa build.

## Skills de diseño aplicadas (orden suya, 2026-10-22 04:06)
Desde ahora el frontend de Cacho se revisa con las skills que él instaló
para DRIPPZY (están en ~/.claude/skills/, de la otra herramienta):
**ui-ux-pro-max** (la principal; buscador local de sistemas de diseño),
penpot-uiux-design y refactoring-ui.
- Consulta de sistema de diseño para "mobile board game casino dice":
  recomienda verde paño + dorado sobre oscuro, estilo táctil/esqueuomórfico
  para juegos → valida la guía docs/02 tal cual; la tipografía Nunito que
  sugiere NO se adopta (manda el master prompt: Cinzel + Montserrat).
- Controles aplicados a la mesa parchís: targets táctiles ≥44 px,
  contraste de textos ≥4.5:1, animaciones 150–300 ms con significado,
  respetar "efectos reducidos", RepaintBoundary en el vaso animado,
  nada de emojis como iconos (verificado: no hay).
