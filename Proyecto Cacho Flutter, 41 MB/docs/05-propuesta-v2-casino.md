# Cacho v2.0 — Propuesta completa: "Noche de casino"

Fecha: 2026-10-24. Estado: PROPUESTA (nada de esto está construido;
cada fase se construye solo tras tu aprobación, con captura por
pantalla, como fijaste en el master prompt).
Punto de partida: checkpoint v1.0.0 (commit 81d8147, tag v1.0.0).

## La idea en una línea

El mismo Dudo de siempre, en una sala de casino de noche: el pub actual
se queda, y se suman mesas temáticas, salas con nombre según la
apuesta, una tienda de cosméticos y, más adelante, torneos, racha y
modo espectador. Todo inspirado en la estructura de 8 Ball Pool
(salas por apuesta, mesas temáticas, tienda, ligas, torneos, espectar),
sin copiar jamás su arte, su logo, sus sonidos ni su juego (pool):
aquí los assets son propios (vaso de cuero y dados de marfil Blender,
paño y madera generativos) y el juego sigue siendo Dudo chileno.

## Principios (no negociables)

1. **Las reglas no se tocan.** Toda la lista cerrada de
   `01-arquitectura-y-decisiones.md` (puntos 1–31) queda intacta:
   subida clásica, ases mitad/doble+1 con interruptor, presets
   Clásico/Cacho completo, pintas As/Pato/Tren/Cuadra/Quinta/Sexta,
   calzo siempre (sin umbral), calzo perfecto, abandono a los 3
   turnos vencidos, Kamikaze a ciegas, salas de 12, desconexión con
   60 s, sala activa con rejoin, renombre en lobby, avatar propio
   al centro bajo el vaso, hueco central en mis dados, aro
   semáforo, DJ de YouTube, voz por malla, vaso boca abajo.
2. **La economía no se toca en Fase A ni B.** Montos aprobados por
   ti: nacer con 5.000, apuestas 100/250/500/1.000/2.500 (defecto
   500), pozo = apuesta × jugadores sin comisión, empate devuelve,
   salir a mitad = perderla, rescate +1.000/día (local). Cualquier
   número nuevo (precios de tienda, bonos de racha) viene como
   SUGERENCIA y solo entra si lo apruebas tú.
3. **Todo lo que se muestra es real.** Nada de contadores
   inventados: espectadores, victorias, rachas y saldos salen de
   datos del servidor o del dispositivo. Si un dato no existe aún,
   la función que lo necesita espera a que exista.
4. **Cosmético nunca es ventaja.** Vaso, dados, marco o celebración
   no cambian probabilidades, dados ni turnos. Los dados nuevos
   mantienen la regla de accesibilidad de docs/02: cada pinta se
   distingue por forma/símbolo, no solo por color.
5. **Rendimiento y reglas de diseño vigentes.** Vertical, una mano,
   targets ≥44 px, contraste ≥4.5:1, animaciones 150–300 ms con
   significado, opción "efectos reducidos", sin textos narrativos
   en partida, sin emojis como iconos, música de casino
   procedural (Dm7–G7–Cmaj7–A7) intacta, DJ intacto.
6. **Nada se quita.** El mundo pub actual (bg_pub.png, bokeh
   cálido, logo DUDO) queda como una mesa más, no se borra.

## Tema visual: del pub al casino (evolución, no reemplazo)

La guía docs/02 ya es casino nocturno (paño verde botella
`#0B5D3B→#06402A`, madera oscura `#2B1810`, burdeos `#5A1A1A`,
dorado envejecido `#C9A24B`, rojo casino `#B3202A`, marfil
`#F5EBD7`, fondo `#120C09`, Cinzel + Montserrat). v2.0 la estira
hacia la sala completa, sin cambiar la UI cromada:

- **Luz:** lámparas colgantes cálidas sobre la mesa, viñeta más
  profunda fuera del paño, bokeh del pub conservado como ambiente.
- **Mesa:** paño con grano visible, costuras doradas, baranda de
  madera con veta; la placa dorada de la apuesta se mantiene
  (pendiente aparte tu palabra: bajarla de 38 a 26–28).
- **Pozo visible:** la apuesta acumulada se dibuja como pila de
  fichas junto a la placa (solo visual; el monto y el reparto no
  cambian: pozo = apuesta × jugadores, sin comisión).
- **Fichas y monedas:** las de la celebración actual (Blender)
  se reutilizan para el pozo y la victoria.
- **Neón, contenido:** el neón vive SOLO dentro de la mesa
  "Neón Nocturno" (ver abajo), nunca en botones, títulos ni
  chrome de la app. El dorado sigue siendo el único acento fuera
  de esa mesa.

## Mesas temáticas (Fase A)

Tres mesas, mismo juego y mismas reglas. La mesa es de la SALA
(la elige el anfitrión al crearla y se ve igual para todos; en
local se elige en la hoja de partida). El lobby muestra la mesa
de cada sala con su miniatura.

1. **El Pub** (actual, por defecto al migrar): bar oscuro, bokeh
   cálido, mesa de madera con luz cenital. Nada cambia para quien
   no quiera cambiar nada.
2. **Casino Dorado** (propuesta como mesa por defecto de las
   salas nuevas — decisión D1): paño verde botella, baranda
   burdeos con costuras doradas, araña cálida, fichas doradas.
   Es la mesa de la guía docs/02 llevada a sala completa.
3. **Neón Nocturno** (guiño a las mesas temáticas de 8 Ball Pool,
   estilo Osaka de neón, con arte propio): fondo casi negro,
   borde de neón frío en la mesa, paño verde profundo, acentos
   cian/magenta SOLO dentro de la mesa. Pensada para jugar de
   noche; si el teléfono es lento, cae a la versión sin brillo
   (respeta "efectos reducidos").

## Salas por apuesta = ligas (Fase A)

Las 5 apuestas oficiales, con nombre y color propios, sin cambiar
ni un monto. El nombre viaja en el lobby, en la sala y en la mesa:

| Apuesta | Nombre de sala | Identidad |
|---|---|---|
| 100 | Mesa de Barrio | Paño claro, luz de bar |
| 250 | El Salón | Madera cálida |
| 500 (defecto) | Casino | Dorado, la mesa clásica |
| 1.000 | VIP | Burdeos + dorado intenso |
| 2.500 | High Roller | Negro + dorado, luz focal |

El lobby permite filtrar por nombre/apuesta. No hay "liga" por
puntos en Fase A: la sala ES la liga (entras a la que puedes
pagar, como en 8 Ball Pool). La progresión por victorias queda
para Fase C, porque exige guardar victorias reales por jugador
(hoy el servidor guarda saldos, no historial de victorias).

## Tienda de cosméticos (Fase B, dentro de "Personalizar")

El master prompt ya pone apodo y cuero dentro de "Personalizar"
en el inicio. La tienda vive ahí, no como pantalla nueva
confusa. Se paga con las monedas que ya existen (sin moneda
nueva, sin dinero real). Todo cosmético, todo con arte propio:

- **Vasos:** los 4 cueros actuales (café, negro, burdeos,
  petróleo) + 2 acabados nuevos en Blender: dorado casino y
  neón nocturno (a juego con las mesas).
- **Dados:** los 4 juegos actuales (marfil base, rojo
  translúcido, negro con puntos dorados, hueso antiguo) +
  2 nuevos: esmeralda casino y neón (siempre con el símbolo
  de cada pinta visible, no solo el color).
- **Marcos de avatar:** dorado actual + variantes (burdeos,
  neón) para el aro del asiento.
- **Celebraciones:** lluvia de monedas actual + 2 variantes
  (destellos dorados intensos, chispas neón) para la victoria.

Precios SUGERIDOS (a aprobar por ti, decisión D2; si no los
apruebas, la tienda no abre): vasos 500–1.500, dados 300–1.000,
marcos 200–500, celebraciones 500. La compra queda guardada en
el dispositivo (local) y en el token de billetera (en línea),
como los saldos. Si el saldo no alcanza, la tienda lo dice y
no vende (igual que `saldo_insuficiente` al crear sala).

## Torneos (Fase C)

Formato propuesto (decisión D3): **torneo de mesas** — una serie
de 3 partidas en la misma sala, con tabla por puntos reales
(ganar una partida = puntos según el puesto al terminar:
1º 10, 2º 7, 3º 5, resto 2; empate en una partida = puntos
repartidos). Cada partida cobra y paga exactamente como hoy
(apuesta × jugadores al ganador, sin comisión ni cuota extra);
el torneo no cobra inscripción aparte. Al cerrar la serie, el
campeón se lleva un marco/título cosmético de torneo (no
monedas extra, para no tocar la economía). Alternativa si la
prefieres: cuadro simple de eliminación (4 u 8 jugadores, el
que pierde sale). El torneo es optativo: las salas normales
siguen existiendo igual.

## Racha diaria (Fase C)

Sobre el rescate actual (+1.000/día local): un contador de
días seguidos entrando (real, por fecha del dispositivo en
local y por fecha del servidor en línea). SUGERENCIA a aprobar
(decisión D4): día 3 seguido +250 extra, día 7 seguido +500
extra, siempre encima del rescate base. Si no apruebas los
bonos, la racha se muestra igual como contador, sin premio
extra. La racha nunca bloquea jugar: con saldo bajo, el
rescate base sigue disponible como hoy.

## Modo espectador (Fase C)

Entrar a una sala en curso SIN asiento: ves la mesa, las
apuestas y las revelaciones, pero NUNCA las
manos ocultas (la regla de privacidad de manos manda también
para espectadores: el servidor no les envía dados ajenos).
El espectador no juega, no abre micrófono (la malla de voz
sigue siendo solo para jugadores) y solo puede aplaudir
(botón de aplauso visible para la mesa, sin spam: un aplauso
cada 10 s por espectador). El contador de espectadores es
real (presencia del servidor). Útil para aprender mirando y
para que una sala de 12 se sienta llena aunque falten
jugadores.

## Fases y aprobación (tu proceso, sin atajos)

- **Fase A — La sala:** 3 mesas temáticas + selector en
  creación de sala y en partida local + nombres/colores de
  las 5 salas por apuesta + filtro en lobby + pozo en fichas.
  Sin tocar economía ni reglas. Verificación: tests motor /
  app / servidor en verde, build web + capturas escritorio y
  móvil, despliegue web verificado byte a byte; APK solo si
  la ordenas.
- **Fase B — La tienda:** Personalizar con vasos, dados,
  marcos y celebraciones + compra con monedas + guardado
  local y en línea. Requiere tu aprobación de precios (D2).
  Misma verificación que A.
- **Fase C — Competir y mirar:** torneos (D3), racha (D4) y
  espectador. Requiere trabajo de servidor (victorias,
  presencia) y tu aprobación de formato y bonos. Misma
  verificación que A, más pruebas en vivo con sala llena.

Cada fase termina con captura y tu "sí" antes de seguir a
la siguiente. Si algo se rompe, se vuelve al checkpoint
v1.0.0 (tag) o al checkpoint de la fase anterior.

## Fuera de alcance (no entra en v2.0)

- Cambiar reglas, montos, temporizador, DJ, voz, sala activa,
  rejoin, avatar al centro, hueco de dados o semáforo.
- Dinero real, cuentas obligatorias, unificar billeteras
  local/en línea (exige cuentas; fuera del MVP sin cuentas).
- Copiar arte, mesas, logo o sonidos de Miniclip o de ningún
  casino real.
- La prueba Blobatar en asientos humanos queda como está en
  v1 (verificación visual HECHA 24-oct en partida local,
  `audit/blobatar/mesa.png`: mi asiento muestra el Blobatar
  dorado en el hueco y los bots conservan sus retratos):
  D5 DECIDIDA 24-oct: queda (la verificación salió bien).

## Pendientes aparte (no son v2.0, no se mezclan)

- Tu palabra: bajar la placa dorada 38→26–28.
- Tu ID de cliente OAuth (origen cacho.pages.dev) para
  "Mi YouTube" y, si quieres búsqueda en APK, la segunda
  clave de API restringida a Android.
- APK con los cambios: diferida por tu orden (web primero).

## Decisiones — CERRADAS 24-oct (todas)

- **D1. Casino Dorado.** Mesa por defecto de las salas
  nuevas (decidido por él).
- **D2. Bandas sugeridas APROBADAS.** Vasos 500–1.500,
  dados 300–1.000, marcos 200–500, celebraciones 500.
- **D3. Serie de 3 con tabla de puntos.** Decidida por GOD
  por delegación suya ("lo que sea mejor"): funciona con
  2–12 jugadores (un cuadro no calza con 12), nadie queda
  esperando eliminado mientras otros juegan, y reutiliza
  la sala normal sin un flujo aparte. El cuadro de
  eliminación queda descartado.
- **D4. Con bonos.** Racha con +250 el día 3 y +500 el
  día 7, sobre el rescate base.
- **D5. Blobatar QUEDA.** Su condición era "solo si la
  verificación visual sale bien": salió bien el 24-oct
  (`audit/blobatar/mesa.png`), así que queda en los
  asientos humanos. No se vuelve a iniciales.
- **D6. Completo.** Orden A→B→C, construcción en curso
  desde Fase A.
