# Brainstorm — Rediseño completo de Cacho (Fase 2)

**Fecha:** 25-oct-2026 · **Estado:** SOLO documento. No modifica código,
no despliega nada, no toca producción, servidor ni APK. No es el
tribunal: estas propuestas las juzgarán 5 jueces después.

**Entrada principal:** `audit/rediseno/recon.md` (30 ideas candidatas
R-01–R-30). Este brainstorm CONSTRUYE sobre ese recon: cada propuesta
indica qué idea del recon hereda, y no contradice el recon salvo que
lo señale. **No se re-propone lo ya construido** por la sentencia del
diseño final (su sección "Alcance exacto"): mesa H1 844×390, sala PIL
por tema, barra superior de 56 px sin desborde (D10), placa C5 en
28 px (solo horizontal), lobby/creación con fórmula POZO (D18),
ajustes en un engranaje sin micrófono (D25), revancha OTRA VEZ solo
local (D26), tienda PRESENTADA sin compra (D27–D30), tiers con nombre,
pozo fijado al partir, atajos +1 y ▲ pinta, chip de probabilidad 44 px
apagado en Kamikaze a ciegas, semáforo + 3 pitidos, avatar al centro
bajo el vaso, hueco 104 simétrico.

**Alcance de esta ronda:** TODO lo visual que falta. Home y hojas
siguen siendo los viejos; solo la mesa horizontal (rectángulo H1,
sala PIL por tema, desplegada) y partes del lobby/creación se
rediseñaron. La mesa NO se rehace: solo se integra y se refina
visualmente (familia R-MESA-ELEGANTE). Los menús quedan en vertical
y la mesa en horizontal: decidido, no se reabre.

**Evidencia vista:** `audit/rediseno/antes_home.jpg`,
`antes_contra_maquina.jpg`, `antes_mesa_cortada.jpg` (producción,
25-oct 01:17). Referencias solo de COMPOSICIÓN, nunca de estilo,
marca, arte ni textos: 8 Ball Pool, Parchisi Star, Monopoly Poker.
Código leído (sin modificar): `app/lib/screens/home_screen.dart`,
`lobby_screen.dart`, `game_screen.dart`, `widgets/panels.dart`,
`widgets/music_sheet.dart`, `widgets/store_showcase.dart`,
`theme.dart`, `table_themes.dart`, `app/web/manifest.json`,
`app/web/index.html`.

**Cercas innegociables (toda propuesta que las viole queda fuera,
no se incluye "para ver"):** estilo PROPIO Cuero y Paño / Casino
Dorado / pub chileno (composición prestada sí, estilo prestado no).
Reglas y economía INTACTAS (apuestas 100–2500, pozo = apuesta ×
jugadores, rescate, presets, Kamikaze a ciegas, semáforo, puerta CU4,
SIN vasos rivales por decisión del usuario 25-oct). POZO nunca
PREMIO. Textos ≥ 14 px, targets ≥ 44 px, contraste ≥ 4,5:1. Nada de
chat/reacciones/emojis en partida, nada de botón VER, nada de
multi-moneda/SALE/gemas/bundles, nada de H19/F.5/G.3. Cero números
falsos (todo contador, saldo y pozo mostrado es real). Solo web.
Sin cambios de servidor. Lo rechazado en sentencias anteriores
sigue rechazado (H8, B20, H19/F.5/G.3, VER, vasos rivales).

**Cómo leer cada propuesta.** Formato fijo: qué cambia
(antes → después en una línea), de qué referencia viene LA
COMPOSICIÓN (si viene de alguna), qué sentencia/decisión hereda, y
qué NO cambia (reglas, economía, datos). Concreto y construible:
color, tamaño, posición, jerarquía, componente. Nada de "hacerlo
más bonito" sin decir cómo.

**Marca de honestidad.** Las hojas de amigos, lobby, ajustes,
tienda y DJ no tienen captura ANTES en esta ronda: toda propuesta
que descanse solo en descripción de código lleva la marca
**sin verificar (solo código)**, para que el tribunal la condicione
a captura.

---

## 1. HOME (R1–R8)

### R1. Franja superior única en menús: saldo + rescate + ajustes + ayuda
- **Antes → después:** dos `IconButton` sueltos arriba a la derecha
  (personalizar y ayuda, sin etiqueta ni fondo, perdidos sobre la
  foto del pub) → una franja superior única de 56 px en cuero
  oscuro con filete dorado fino abajo, que concentra: píldora de
  saldo (moneda + cifra real, la misma de hoy), rescate del día
  solo cuando exista, botón Ajustes (engranaje, 44×44, con etiqueta
  "Ajustes" o fondo de píldora) y botón Ayuda ("?", 44×44, con
  fondo de píldora). Nada suelto sobre foto.
- **Composición:** 8 Ball Pool (una sola barra que concentra todo
  el estado), sin copiar su arte ni sus colores.
- **Hereda:** recon R-01; sentencia del diseño final D10 (lógica de
  barra: un estado por zona, sin iconos sueltos), aplicada a menús
  sin copiar la geometría de la barra de mesa.
- **NO cambia:** saldo real y billetera (local en menús; la de la
  modalidad en curso en partida), rescate +1.000/día, destino de
  Ajustes y de Ayuda/CÓMO SE JUEGA.

### R2. Panel de estado único + 4 tarjetas con un solo lenguaje
- **Antes → después:** saludo "Hola, Jugador" + píldora de saldo
  suelta + tarjeta guiada dorada translúcida y 3 tarjetas
  `navyCard` `#141B28` (dos lenguajes: casino arriba, app social
  abajo) → UN panel de estado (saludo a 16 px + saldo real a 20 px
  en negrita + rescate/sala activa solo si existen, ver R8) y las
  4 tarjetas con el MISMO fondo cuero/madera `#3E2312` y el MISMO
  borde dorado mate de 1 px; la tarjeta guiada se distingue SOLO
  por un filete dorado de 2 px y una placa "EMPIEZA AQUÍ" a 14 px,
  no por cambiar de familia de color. Todas con la misma
  estructura: icono dorado 28 px + título Cinzel + subtítulo
  Montserrat a 14 px + flecha `>`.
- **Composición:** Parchisi Star (panel de estado arriba + tarjetas
  uniformes con título/dato/flecha).
- **Hereda:** recon R-04; sentencia diseño final D18 (tarjetas con
  nombre + dato real) y D24 (estructura del inicio intacta, sin
  añadir tarjetas).
- **NO cambia:** las 4 entradas, su orden, su destino ni ningún
  dato; no se añade tarjeta de racha (ver R8).

### R3. El vaso héroe pasa a sello: 150 px → 84 px, sobre el panel
- **Antes → después:** `CachoCup` de 128×150 px + sombra entre el
  logo y el saludo, que con el logo ocupa ~45% del alto y empuja
  las tarjetas hacia abajo → el mismo vaso Blender (mismo sprite,
  misma inicial grabada) a 84 px de alto, centrado, con su sombra
  elíptica y una viñeta suave detrás, colocado ENCIMA del panel de
  estado (R2), no entre logo y saludo. Jerarquía: logo → vaso-sello
  → panel de estado → tarjetas.
- **Composición:** ninguna (marca propia; el vaso es identidad
  DUDO, no composición prestada).
- **Hereda:** recon R-10; sentencia diseño final D31 ("nunca se
  achican textos ni pipas para que un vaso quepa: se reduce o
  reubica el vaso"), aplicada aquí al home.
- **NO cambia:** el sprite del vaso, la inicial, la corona del logo
  ni el logo DUDO en CaveatBrush.

### R4. Textos bajo 14 px: subirlos, no maquillarlos
- **Antes → después:** eslogan 12,5 px, "CACHO · EL DUDO CHILENO"
  10,5 px, subtítulos de tarjeta 12,5 px, pie 11,5 px, rescate
  13 px → eslogan a 14 px en dorado mate con tracking, subtítulo
  del logo a 14 px, subtítulos de tarjeta a 14 px, rescate a 14 px;
  el pie "Sin cuentas y sin dinero real: solo apodo, dados y
  farol." (11,5 px, `white38`) se ELIMINA del home y vive dentro de
  la hoja CÓMO SE JUEGA a 14 px, porque no informa una acción y no
  puede quedarse por debajo del piso.
- **Composición:** ninguna (piso del tribunal).
- **Hereda:** recon R-21; sentencia diseño final D2 (todos los
  textos ≥ 14 px; el costo se paga reduciendo o reubicando, nunca
  bajando el texto).
- **NO cambia:** el texto del eslogan, del subtítulo ni del pie
  (solo su tamaño o su ubicación); ninguna palabra nueva.

### R5. Fondo del home: madera oscura + pub atenuado arriba, no foto a pantalla completa
- **Antes → después:** `pubDecoration` (foto de bar `bg_pub.png`)
  a pantalla completa compitiendo con las tarjetas → fondo de MENÚ
  (ver R31): madera oscura `#120C09` con viñeta, y la foto del pub
  solo como franja superior atenuada (al 55%, con degradado a
  madera en su borde inferior) detrás de logo y vaso-sello. El home
  anuncia el Pub sin tapar las tarjetas.
- **Composición:** 8 Ball Pool R-02 (sala oscura que no compite),
  traducida a menú: fondo quieto, contenido protagonista.
- **Hereda:** recon R-18; sentencia diseño final D15 (zona calma
  obligatoria bajo textos; si una captura podría confundirse con
  otro juego, ese fondo se descarta).
- **NO cambia:** los assets (`bg_pub.png`, `wood.png`); solo se
  reorganizan. No se cambia el tema del Pub.

### R6. Miniatura real de la mesa en cada tarjeta de juego
- **Antes → después:** tarjetas de juego sin ninguna mesa (el salto
  home → mesa horizontal es un cambio de mundo sin puente) → en
  cada tarjeta de juego (guiada, contra la máquina, con amigos),
  a la derecha del subtítulo o como franja inferior de 56 px de
  alto dentro de la tarjeta, una miniatura REAL del tema por
  defecto (Casino Dorado: paño + marco madera + filete dorado, el
  mismo `landscapeTableDecoration` en pequeño), no un rectángulo
  de color. El neón, si se muestra, solo dentro de su miniatura.
- **Composición:** Monopoly Poker (la mesa se reconoce antes de
  entrar), solo composición.
- **Hereda:** recon R-11 y R-14; sentencia diseño final D18
  (miniatura propia por tier/tema) y D23 (el tema viaja con la sala).
- **NO cambia:** tema por defecto (Casino Dorado, decisión D1 de la
  v2.0), destinos de las tarjetas ni reglas.

### R7. El home cabe sin scroll: alturas fijas, scroll solo como red
- **Antes → después:** `Column` sin scroll ni `LayoutBuilder`,
  con dos `Spacer` (en viewport corto desborda; en viewport alto
  deja aire muerto entre saldo/tarjetas y tarjetas/pie) → alturas
  fijas: franja 56 + logo ~64 + vaso-sello 84 + panel ~76 +
  4 tarjetas de 76 px + separaciones de 12 px, y `SingleChildScrollView`
  SOLO como red de seguridad en viewports extremos; el scroll
  nunca es necesario para alcanzar ninguna tarjeta en un viewport
  vertical normal. Se eliminan los dos `Spacer`.
- **Composición:** Parchisi Star R-06 (vertical profesional: contenido
  central despejado, controles abajo), solo para menús.
- **Hereda:** recon R-03 y R-06; sentencia diseño final D24 (inicio
  sin scroll) y D16 (detección por tamaño, sin forzar rotación).
- **NO cambia:** estructura del inicio (logo, tarjetas, sin
  densificar), orden ni textos; el scroll de emergencia no añade
  contenido.

### R8. Sala activa y rescate viven DENTRO del panel, nunca como tarjeta nueva
- **Antes → después:** aviso dorado de sala activa y rescate como
  elementos sueltos (hoy el aviso dorado existe como renglón
  aparte) → dentro del panel de estado (R2), dos renglones
  opcionales a 14 px: "Rescate del día disponible: +1.000" solo
  cuando exista, y "Entrar a la sala activa" dorado solo cuando
  exista una sala activa real. Si no hay dato real, el renglón se
  omite (no se pone un cero ni se estima).
- **Composición:** Parchisi Star (panel de estado único con datos
  reales).
- **Hereda:** recon R-04; sentencia diseño final D21 (sala activa
  sin cambios de flujo; aviso dorado, sin convertirse en tarjeta
  ni lista) y D24 (llama de racha solo con registro real; si el
  dato no se guarda, el campo se omite).
- **NO cambia:** flujo de sala activa (validación del servidor,
  `rejoin` solo con asiento desconectado, borrado solo con
  `game_over`, sala muerta o ✕), rescate +1.000/día, ni economía.
  La racha diaria (Fase C) NO aparece: no existe como dato real.

---

## 2. HOJAS (R9–R18)

### R9. Las hojas de creación como pantallas propias, no como bottom sheets que tapan el logo
- **Antes → después:** `showModalBottomSheet` (`isScrollControlled:
  true`, fondo madera, borde superior 18 px) que sube hasta tapar
  la corona del logo DUDO y deja el home como franja oscura arriba
  → la hoja local y la hoja con amigos son PANTALLAS propias con
  la misma franja superior que el home (R1), el mismo fondo de
  menú (R31) y botón atrás `‹` 44×44. Si el tribunal mantiene el
  bottom sheet, condición: altura máxima del 85% del alto visible,
  scroll interno y asa visible, y nunca tapar la identidad.
- **Composición:** ninguna (corrección de jerarquía propia).
- **Hereda:** recon R-12; sentencia diseño final D22/D23 (hoja
  vertical en orden: mesa + tier + bots + fórmula).
- **NO cambia:** contenido ni orden de la hoja (ver R10–R14), ni
  el flujo crear/unirse, ni el código de sala.

### R10. Tiers en rejilla sin scroll: 5 tiers en 2 filas, todos visibles, nunca "High R"
- **Antes → después:** `StakePicker` con scroll horizontal sin
  señal visual (en `antes_contra_maquina.jpg` se lee "High R"
  cortado en el borde; un jugador puede no descubrir nunca High
  Roller) → rejilla de 2 filas (3 + 2) con las 5 tarjetas de tier
  completas y visibles: nombre corto + apuesta exacta (Barrio 100 /
  Salón 250 / Casino 500 / VIP 1.000 / High Roller 2.500, siempre
  junto a su apuesta), tarjeta seleccionada con borde dorado de
  2 px y fondo dorado mate, resto cuero con borde dorado de 1 px.
  Cada tarjeta ≥ 44 px de alto, texto ≥ 14 px.
- **Composición:** Parchisi Star (tarjetas de liga como
  presentación: nombre + cifra), solo presentación.
- **Hereda:** recon R-05 y R-13; sentencia diseño final D18
  (etiqueta corta + apuesta exacta; POZO nunca PREMIO) y D19
  (chips neutros, activo dorado envejecido, ≥ 44 px, ≥ 14 px).
- **NO cambia:** las 5 apuestas, el defecto 500, la fórmula del
  pozo ni el bloqueo por saldo insuficiente sin cobrar.

### R11. Dificultad en segmentado compacto de 3 opciones en una fila
- **Antes → después:** tres filas de radio con título + subtítulo
  y separaciones de 12 px (~1/3 de la hoja) → segmentado de 3
  opciones en una fila (Fácil / Media / Difícil), cada una ≥ 44 px
  de alto, seleccionada en dorado mate, resto cuero; el subtítulo
  ("juegan más al azar" / "piensan un poco sus apuestas" /
  "calculan probabilidades y hacen faroles") solo en la opción
  seleccionada, a 14 px, en una línea debajo del segmentado. Ahorra
  alto para tier + mesa + JUGAR.
- **Composición:** ninguna (densidad propia, sin cambiar opciones).
- **Hereda:** recon §2.2 (dificultad con mucho aire vertical);
  sentencia diseño final D22 (contador de bots 1–11 con dificultad).
- **NO cambia:** las 3 dificultades, su comportamiento de bots ni
  la guiada (2 bots lentos que explican, opción propia de la hoja).

### R12. Selector de mesa con miniaturas REALES del tema, no rectángulo de color
- **Antes → después:** `TableThemePicker` con rectángulo de color
  de 44×18 px + nombre (el jugador elige "Casino Dorado" sin ver el
  paño, el marco ni la sala) → 3 tarjetas con miniatura REAL del
  tema (paño + marco + filete del mismo `landscapeTableDecoration`
  en pequeño, 3 tarjetas en una fila, cada una ≥ 44 px de alto):
  El Pub (madera + foto atenuada), Casino Dorado (paño verde +
  marco madera + filete dorado, seleccionado por defecto), Neón
  Nocturno (plano oscuro + marco cian, cian SOLO dentro de la
  miniatura). Nombre a 14 px debajo de la miniatura.
- **Composición:** Monopoly Poker (selector de mesas con tarjetas).
- **Hereda:** recon R-14; sentencia diseño final D15 (neón solo
  dentro del rectángulo-mesa) y D22 (selector de mesa, cada opción
  ≥ 44 px).
- **NO cambia:** los 3 temas, el defecto Casino Dorado ni el hecho
  de que el tema viaja con la sala (D23).

### R13. Placa del pozo fija justo sobre JUGAR: pozo y saldo separados, a ≥ 14 px
- **Antes → después:** "Pozo: 500 × 4 jugadores = 2.000 · tu saldo:
  5.000" en texto corrido a 12,5 px (la información más importante
  de la hoja en el texto más chico) → placa dorada fija justo sobre
  el botón JUGAR, con dos líneas a 14 px: "POZO = 500 × 4 jugadores
  = 2.000" y, debajo y en menor jerarquía pero también a 14 px,
  "Tu saldo: 5.000". La placa se recalcula en vivo con bots y tier
  reales; la palabra "jugadores" siempre junto a ×N, prohibido ×N
  aislado.
- **Composición:** ninguna (jerarquía propia).
- **Hereda:** recon §2.2 (fórmula del pozo en texto corrido);
  sentencia diseño final D18 (fórmula visible, rótulo literal
  POZO, nunca PREMIO) y D22 (fórmula del pozo en vivo con números
  reales de la billetera local).
- **NO cambia:** la fórmula (pozo = apuesta × jugadores), el
  defecto 500, el bloqueo por saldo insuficiente ni la billetera
  (local en esta hoja; en línea, la del servidor, sin mezclar).

### R14. Contador de bots legible: stepper 44 px + rango real "1–11"
- **Antes → después:** "Bots en la mesa: ⊖ 3 ⊕" sin rango visible
  → misma fila, con botones ⊖/⊕ de 44×44, número a 20 px en
  negrita, y etiqueta a 14 px "Bots en la mesa (1–11)". Al llegar a
  1 u 11, el botón correspondiente se deshabilita (dorado al 30%,
  sin desaparecer). El total de jugadores (yo + bots) alimenta la
  placa del pozo (R13) en vivo.
- **Composición:** ninguna.
- **Hereda:** sentencia diseño final D22 (contador de bots 1–11);
  recon §2.2.
- **NO cambia:** rango 1–11, bots de relleno ni dificultad; el
  número mostrado es siempre el real.

### R15. Hoja CON AMIGOS: código de sala en Cinzel grande y copiable + invitación anunciada — sin verificar (solo código)
- **Antes → después:** código de sala como un campo de texto más
  dentro del mismo bottom sheet (descripción por código, sin
  captura) → en la pantalla propia (R9), el código se muestra en
  Cinzel a 24 px con tracking, en placa cuero con borde dorado,
  con botón "Copiar" 44×44 al lado; debajo, a 14 px, "Comparte este
  código o invita por WhatsApp" (la invitación ya existe en el
  lobby y se anuncia desde esta hoja, no se crea un flujo nuevo).
  Tier, mesa y crear/unirse iguales que la hoja local (R10–R13).
- **Composición:** ninguna.
- **Hereda:** recon R-15; sentencia diseño final D23 (código de
  sala 4–6 para compartir; el servidor verifica y cobra al partir).
- **NO cambia:** código de sala, flujo crear/unirse, cobro al
  partir (`saldo_insuficiente` bloquea sin cobrar), salir a mitad
  = perder la apuesta.
- **Marca:** sin verificar (solo código) — no hay captura ANTES de
  esta hoja en `audit/rediseno/`; el tribunal debe pedirla antes de
  sentenciar.

### R16. Presets legibles: "Cacho completo / Clásico" a ≥ 14 px y "Ver qué cambia" a 14 px
- **Antes → después:** chips de preset con texto a 13,5 px y enlace
  "Ver qué cambia" a 13 px (bajo el piso; en la captura se ven
  "✓ Cacho completo" y "Clásico" como dos píldoras sueltas) →
  mismos dos chips a 44 px de alto, texto a 14 px, seleccionado en
  dorado mate con ✓, resto cuero con borde dorado; "Ver qué cambia"
  a 14 px en dorado mate, como texto táctil de 44 px de alto, que
  abre la misma explicación que hoy (sin pantalla nueva).
- **Composición:** ninguna.
- **Hereda:** recon R-21 (escala mínima); decisiones cerradas de
  presets (Clásico sin Paso ni Kamikaze; Cacho completo con todo).
- **NO cambia:** los presets, sus reglas (subida clásica; ases
  mitad/doble+1 con interruptor; pintas As/Pato/Tren/Cuadra/Quinta/
  Sexta) ni el contenido de "Ver qué cambia".

### R17. Creación en línea: la misma hoja que la local, con su billetera indicada — sin verificar (solo código)
- **Antes → después:** hoja en línea descrita por código como
  "la misma hoja" pero sin evidencia visual de que se lea como
  tal → misma pantalla propia (R9), misma rejilla de tiers (R10),
  mismas miniaturas de tema (R12) y misma placa de pozo (R13), con
  una línea a 14 px sobre la placa: "Billetera en línea" (sin cifra
  mezclada con la local). El tema elegido viaja con la sala; valor
  inválido cae a Dorado (regla existente, no cambia).
- **Composición:** ninguna.
- **Hereda:** sentencia diseño final D23 (misma hoja que D22; tema
  que viaja con la sala); recon R-15 (uniformar creación y lobby).
- **NO cambia:** flujo en línea, cobro al partir, código 4–6,
  bloqueo por saldo insuficiente ni servidor.
- **Marca:** sin verificar (solo código) — no hay captura ANTES de
  la hoja en línea; el tribunal debe pedirla.

### R18. JUGAR último, a ancho completo, 56 px, sin nada debajo que lo empuje fuera
- **Antes → después:** botón JUGAR dorado al final de la hoja (ya
  es así y se conserva) → se fija como regla de la hoja: JUGAR es
  siempre el último elemento, a ancho completo, 56 px de alto,
  texto Cinzel a 18 px, dorado mate (ver R33); nada debajo de él
  (ni pie, ni enlace, ni placa) que lo empuje fuera de pantalla.
  La placa del pozo (R13) queda JUSTO SOBRE JUGAR, nunca debajo.
- **Composición:** 8 Ball Pool R-03 (botón primario último, grande,
  al alcance del pulgar), solo para hojas verticales.
- **Hereda:** recon R-03; sentencia diseño final D24 (botón
  primario unificado de 56 px mínimo, degradado solo entre tonos
  mates de `#C9A24B`).
- **NO cambia:** texto "▶ JUGAR", destino (partida local o sala en
  línea según la hoja) ni orden de la hoja.

---

## 3. LOBBY DE SALAS (R19–R21) — todo sin verificar (solo código)

### R19. Lobby con fondo de MENÚ + miniatura real de la mesa en cabecera — sin verificar (solo código)
- **Antes → después:** `feltDecoration` (paño verde a pantalla
  completa) con `AppBar` transparente y título "SALA", que ni
  anuncia la mesa ni continúa el home → fondo de MENÚ (R31: madera
  oscura + viñeta) y, en cabecera, la miniatura REAL de la mesa de
  la sala (mismo `landscapeTableDecoration` en pequeño, con su
  tema y su marco), para que el lobby se lea como la mesa que
  viene. El paño verde a pantalla completa se descarta (ver R32).
- **Composición:** Monopoly Poker (sala que se reconoce antes de
  entrar).
- **Hereda:** recon R-16; sentencia diseño final D20 (lobby
  conserva lo que funciona) y D23 (lobby que muestra la mesa con
  su miniatura).
- **NO cambia:** apuesta y pozo de la sala del anfitrión, lista de
  jugadores, relleno con bots, sala activa ni renombre.
- **Marca:** sin verificar (solo código) — no hay captura ANTES
  del lobby; la verificación en vivo del lobby quedó pendiente en
  la entrega anterior (servidor sin respuesta desde el navegador
  de la VM).

### R20. Cabecera fija (código + tier + pozo fórmula) + asientos como tarjetas uniformes — sin verificar (solo código)
- **Antes → después:** `ListView` con código, tier, pozo,
  jugadores y botones "Estoy listo" / "Rellenar con bots" en el
  mismo plano → cabecera FIJA (no se desplaza con la lista):
  código en Cinzel 44 px (se conserva), tier con su apuesta exacta
  y pozo fórmula ("POZO = apuesta × N jugadores", provisional
  "pozo si se parte ahora, se fija al partir" solo en sala
  existente) a 14 px; debajo, lista de asientos como tarjetas
  uniformes: avatar + nombre + saldo real + estado Listo/
  Esperando, mismo aro y mismo dorado que la mesa. Botones "Estoy
  listo" y "Rellenar con bots" a 44 px, al final de la cabecera,
  no dentro de la lista.
- **Composición:** Monopoly Poker R-08 (tarjetas de lobby con
  buy-in visible), solo presentación; "buy-in" aquí es la apuesta
  cerrada, nunca ciegas de póker.
- **Hereda:** recon R-08; sentencia diseño final D18 (fórmula con
  la palabra jugadores junto a ×N), D20 (botones del lobby de 34
  a ≥ 44 px; líneas de apuesta/pozo de 12,5 a ≥ 14 px) y D19.
- **NO cambia:** flujo del lobby, relleno con bots con contador
  visible, lápiz junto a mi fila solo en lobby (en partida el
  servidor responde `en_partida`), bloqueo por saldo insuficiente
  sin cobrar, aviso de desconexión con cuenta de 60 s en el
  asiento.
- **Marca:** sin verificar (solo código) — misma falta de captura
  que R19.

### R21. Etiquetas del lobby a ≥ 14 px; código Cinzel 44 px se conserva — sin verificar (solo código)
- **Antes → después:** etiqueta "CÓDIGO DE LA SALA" a 11 px y
  líneas de lista a 11–12,5 px → etiqueta a 14 px en dorado mate
  con tracking, líneas de lista a 14 px, estados (Listo/Esperando)
  a 14 px; el código en Cinzel 44 px NO cambia (ya cumple y es la
  identidad de la sala). Los textos con alfa (`white60`, `white70`)
  se miden mezclados sobre su fondo real antes de sentenciarse
  (ver R35).
- **Composición:** ninguna.
- **Hereda:** recon R-21; sentencia diseño final D2 y D20.
- **NO cambia:** contenido de las etiquetas ni del código.
- **Marca:** sin verificar (solo código) — misma falta de captura
  que R19.

---

## 4. AJUSTES (R22–R23) — sin verificar (solo código)

### R22. Hoja de ajustes: engranaje único, tres entradas, sin micrófono, todo ≥ 44/≥ 14 — sin verificar (solo código)
- **Antes → después:** ajustes descritos por código (engranaje
  único ya construido en partida, D25) sin evidencia visual de
  que la hoja se lea como sistema → hoja con el mismo fondo de
  menú (R31) y la misma franja (R1): exactamente tres entradas en
  orden Historial, Glosario y Sonido (volumen DJ 0–50, defecto 15),
  cada entrada ≥ 44 px y texto ≥ 14 px; el micrófono NO está en
  esta hoja (sigue solo sobre mi foto, regla 21); sin
  personalización ni tienda en plena partida, sin reacciones ni
  emojis. En menús, la misma hoja añade, debajo y separado, el
  renglón de pantalla completa / añadir a inicio (R23).
- **Composición:** ninguna.
- **Hereda:** sentencia diseño final D25 (engranaje único, con su
  condición de reversión intacta: la hoja no pausa ni reinicia
  temporizador ni semáforo; si estorba en mi turno en rojo con
  apuesta armada, se deshace sin tocar nada más); recon §2.3.
- **NO cambia:** contenido de las tres entradas, volumen DJ
  0–50/defecto 15, regla del micrófono ni temporizador/semáforo.
- **Marca:** sin verificar (solo código) — no hay captura ANTES
  de la hoja de ajustes en esta ronda.

### R23. En ajustes (solo menús): renglón de pantalla completa y de "Añadir a pantalla de inicio" según la familia R-PANTALLA-COMPLETA — sin verificar (solo código)
- **Antes → después:** ningún renglón que explique pantalla
  completa ni añadir a inicio → en la hoja de ajustes abierta
  desde MENÚS (nunca en plena partida), un renglón por opción,
  cada uno ≥ 44 px y texto ≥ 14 px, con el texto exacto que fije
  la familia R-PANTALLA-COMPLETA (R48/R49): en Android/escritorio,
  botón real de pantalla completa; en iPhone, NINGÚN botón de
  pantalla completa (o renglón explicativo sin acción, nunca un
  botón muerto); "Añadir a pantalla de inicio" solo si el PWA ya
  está corregido (R49), explicado como función oficial de Safari.
- **Composición:** ninguna.
- **Hereda:** recon R-29/R-30 y §4; sentencia diseño final D25
  (sin personalización ni tienda en plena partida: estas opciones
  viven en menús, no en partida).
- **NO cambia:** nada de partida, servidor ni economía.
- **Marca:** sin verificar (solo código) — la hoja de ajustes no
  tiene captura ANTES; además, la opción de añadir a inicio queda
  condicionada a la corrección PWA (R49).

---

## 5. TIENDA PRESENTADA, NO CONSTRUIDA (R24–R26) — sin verificar (solo código)

### R24. Tienda presentada: cuadrícula uniforme por sección, bandas aprobadas, billetera indicada — sin verificar (solo código)
- **Antes → después:** `StoreShowcase` descrito por código con
  descripciones a 12 px → cuadrícula vertical por sección en
  orden Vasos, Dados, Marcos, Celebraciones, con el mismo lenguaje
  de tarjeta que R2 (fondo cuero, borde dorado 1 px, seleccionado
  2 px); cada tarjeta: render propio, nombre a 14 px, precio
  visible DENTRO de las bandas aprobadas (vasos 500–1500, dados
  300–1000, marcos 200–500, celebraciones 500; ningún precio
  puntual nuevo) y estado "Equipado" dorado / "Comprar"; cada
  tarjeta indica qué billetera se usa (local o en línea) sin
  mezclarlas. Compra directa una por una; sin packs, azar, moneda
  premium, dinero real, SALE, gemas, cofres, bundles ni BUY ALL.
  Sin saldo no vende.
- **Composición:** ninguna (presentación propia).
- **Hereda:** sentencia diseño final D27 (tienda PRESENTADA, no
  construida; es presentación para que la Fase B la construya sin
  rediseñar; en esta entrega no se cobra nada); recon §2.7.
- **NO cambia:** bandas, secciones, orden ni economía; NO se cobra
  nada en esta ronda (presentación, no construcción).
- **Marca:** sin verificar (solo código) — no hay captura ANTES
  de la tienda presentada en esta ronda.

### R25. Vista previa en vivo sin equipar sin pagar — sin verificar (solo código)
- **Antes → después:** vista previa descrita por código → al tocar
  un vaso o unos dados, mi asiento de la mesa de fondo (o un vaso
  de muestra) cambia al instante, sin pantalla nueva ni compra a
  ciegas; el vaso sobre el paño delante del avatar con aro de
  identidad (no semáforo, que solo existe en turno); los dados con
  su símbolo de pinta visible. Al salir sin comprar, vuelve lo
  equipado. La vista previa respeta CU4: un vaso de tienda solo se
  muestra en partida si cumple D5 intacta y pasa la puerta CU4;
  un vaso que se confunda con verde, amarillo o rojo no entra
  aunque ya se haya vendido su vista previa.
- **Composición:** ninguna.
- **Hereda:** sentencia diseño final D28 y D29 (vasos de tienda
  en partida solo bajo D5 + CU4); recon §2.7.
- **NO cambia:** lo equipado, precios, bandas ni reglas; la vista
  previa no cobra ni equipa.
- **Marca:** sin verificar (solo código) — misma falta de captura
  que R24.

### R26. Textos de tienda a ≥ 14 px; dados por símbolo, marcos sin teñir el semáforo — sin verificar (solo código)
- **Antes → después:** descripciones de tienda a 12 px
  (`white60`) → todas las descripciones y estados a 14 px;
  dados distinguibles por forma/símbolo, no solo por color, y el
  1 sigue con su punto rojo; marcos solo como marco del asiento
  FUERA de turno (en turno el círculo entero toma el semáforo y
  ningún marco lo tiñe ni lo tapa); celebraciones solo en la
  pantalla de victoria, nunca como animación sobre la mesa en
  turno ni flotante sobre asientos (B20 no resucita).
- **Composición:** ninguna.
- **Hereda:** sentencia diseño final D30; recon R-21.
- **NO cambia:** dados, marcos, celebraciones ni bandas.
- **Marca:** sin verificar (solo código) — misma falta de captura
  que R24.

---

## 6. DJ / COLA (R27–R28)

### R27. Barra de música: cuero con filete dorado, texto a 14 px, plegable en altura escasa
- **Antes → después:** `MusicBar` como píldora navy a 12 px
  ("Música de la sala: sin DJ") que en `antes_mesa_cortada.jpg`
  ocupa una fila completa y resta altura a la mesa → fondo cuero
  con filete dorado de 1 px (no navy), texto a 14 px ("Música de la
  sala: sin DJ" / tema en curso); en altura escasa (ver R46) se
  pliega a icono ♫ 44×44 + nombre del tema a 14 px, devolviendo
  ~34 px a la fila. El DJ y la cola siguen en su hoja (R28), que
  no se rehace.
- **Composición:** ninguna (corrección de sistema propio: el navy
  es ajeno al cuero).
- **Hereda:** recon R-17; sentencia diseño final D10 (DJ compacto
  sin controles extra, sin tapar pozo ni pastilla de turno y nunca
  sobre la mesa).
- **NO cambia:** DJ por reclamo (el primero), cola colaborativa,
  votos para saltar por mayoría, pausa con posición preservada,
  ducking a 11 cuando cualquier micrófono se abre, volumen DJ
  0–50/defecto 15, ni sincronía anclada a horas del servidor.

### R28. Hoja DJ/cola: solo DJ, sin micrófono, textos ≥ 14 px — sin verificar (solo código)
- **Antes → después:** `MusicSheet` (hoja Cola/Buscar/Mi YouTube)
  descrita por código con textos de 11–13,5 px → misma hoja, mismo
  fondo de menú (R31), mismas tres secciones (Cola / Buscar / Mi
  YouTube), con todos los textos a ≥ 14 px (títulos de canción,
  artista, duraciones y estados); "Tocar ahora" solo DJ (sale de
  la cola si estaba); sin micrófono en esta hoja (el micrófono
  sigue solo sobre mi foto); sin reacciones ni emojis. Mi YouTube
  sigue pendiente del ID de cliente OAuth (no se inventa flujo).
- **Composición:** ninguna.
- **Hereda:** decisiones 25–26 (DJ por reclamo; volumen DJ);
  sentencia diseño final D10 y D25 (sin micrófono fuera de mi
  foto); recon §2.4.
- **NO cambia:** DJ, cola, votos, búsqueda de YouTube, Mi YouTube
  (pendiente de OAuth), ducking ni servidor.
- **Marca:** sin verificar (solo código) — no hay captura ANTES
  de la hoja DJ/cola en esta ronda.

---

## 7. BARRAS SUPERIORES (R29–R30)

### R29. Una sola barra por pantalla: tabla de qué muestra cada una y qué no
- **Antes → después:** iconos sueltos + píldoras sueltas + barras
  duplicadas según la pantalla → UNA barra por pantalla, con tres
  zonas (izquierda: salir/atrás; centro: estado; derecha: saldo o
  ajustes), sin duplicar ningún dato entre barra y contenido:

| Pantalla | Barra muestra | Barra NO muestra |
|---|---|---|
| Home (R1) | Saldo + rescate (si existe) + Ajustes + Ayuda | Sala activa (va en el panel, R8), tarjetas |
| Hojas (R9) | Atrás + título de la hoja + saldo de la modalidad | Pozo (va en placa sobre JUGAR, R13), tier |
| Lobby (R20) | Atrás + código + tier + pozo fórmula (cabecera fija) | Lista de asientos (va debajo), botones de listo |
| Mesa horizontal | Lo ya construido (D10, 56 px): Salir \| turno + apuesta vigente + pozo fijado \| saldo + tier + engranaje | Rivales, DJ con controles, micrófono |
| DJ/cola (R28) | Atrás + "Música de la sala" + DJ actual | Cola completa (va en la hoja) |

  Ningún dato aparece en dos lugares a la vez: el saldo vive en la
  barra, no en las tarjetas; el pozo vive en la placa (hojas) o en
  la barra (mesa), no en ambos.
- **Composición:** 8 Ball Pool R-01 (una sola barra que concentra
  el estado).
- **Hereda:** recon R-01; sentencia diseño final D10 (tres zonas a
  una línea con elipsis; Salir y engranaje ≥ 44 px y separados).
- **NO cambia:** contenido de la barra de mesa (D10 intacta),
  datos mostrados (todos reales) ni flujos.

### R30. Regla de no-duplicación: ningún icono suelto sobre foto, ninguna segunda barra en partida
- **Antes → después:** iconos sueltos del home sobre la foto del
  pub y píldora navy de música como segunda fila → regla: todo
  icono de barra lleva etiqueta visible o fondo de píldora, nunca
  icono solo sobre foto; en partida no se añade ninguna barra
  nueva (ni segunda fila de estado, ni barra de DJ con controles,
  ni banner flotante): el DJ compacto vive dentro de la barra de
  56 px (D10) y la barra de música (R27) es la única fila
  secundaria, plegable (R46).
- **Composición:** 8 Ball Pool R-01.
- **Hereda:** recon R-01 y §2.4; sentencia diseño final D10 y D11
  (turno sin señales nuevas).
- **NO cambia:** barra de mesa, semáforo, DJ ni micrófono.

---

## 8. FONDOS (R31–R32)

### R31. Un sistema común para los 4 fondos: menú / sala / mesa / neón, con zona calma
- **Antes → después:** cuatro fondos sin regla común (home: foto
  de bar a pantalla completa; lobby: paño verde a pantalla
  completa; mesa Dorado: sala foto + rectángulo paño; mesa Pub:
  foto + rectángulo madera; mesa Neón: plano `#05070C` + marco
  cian) → sistema de 4 fondos con los MISMOS assets
  reorganizados, cada uno con zona calma obligatoria bajo textos,
  avatares, nombres, pipas y aros:
  - **MENÚ** (home, hojas, lobby, ajustes, tienda, DJ): madera
    oscura `#120C09` + viñeta + foto del pub solo atenuada arriba
    (R5). Nunca paño verde a pantalla completa.
  - **SALA** (alrededor de la mesa, por tema): PIL por tema — foto
    Dorado, foto Pub, textura oscura propia Neón (R41) — con
    viñeta progresiva en los bordes (R40).
  - **MESA** (rectángulo H1): paño/marco/filete del tema, sin
    excepciones (R38–R39).
  - **NEÓN**: textura oscura sutil propia en la sala (no plano
    vacío), cian SOLO dentro del rectángulo-mesa.
- **Composición:** 8 Ball Pool R-02 (sala oscura que no compite).
- **Hereda:** recon R-18 y R-02; sentencia diseño final D15 (PIL
  primero por tema, zona calma obligatoria, modo ligero intacto;
  prueba de parecido: si una captura podría confundirse con otro
  juego, ese fondo se descarta).
- **NO cambia:** assets existentes (`bg_pub`, `room_dorado`,
  `felt_bg`, `wood`), temas ni reglas. La textura Neón es el único
  asset nuevo, propio y oscuro (no cian, no marca ajena).

### R32. Fondo que se descarta: paño verde a pantalla completa en el lobby (y plano vacío Neón)
- **Antes → después:** lobby con paño verde a pantalla completa
  (parece otra app: ni anuncia la mesa ni continúa el home) y sala
  Neón como plano `#05070C` (se lee como vacío sin terminar) →
  ambos se DESCARTAN: el lobby pasa a fondo de MENÚ (R19) y la sala
  Neón a textura oscura propia (R41). Criterio del tribunal: si
  una captura del lobby o de la sala Neón podría confundirse con
  otro juego, o se lee como "sin terminar", ese fondo queda fuera
  aunque se vea bien.
- **Composición:** ninguna (criterio de descarte propio).
- **Hereda:** recon R-02 y R-16; sentencia diseño final D15
  (prueba de parecido) y C6 (sin demostrar no entra).
- **NO cambia:** el paño verde sigue existiendo DENTRO del
  rectángulo-mesa (es el paño del tema Dorado); solo deja de ser
  fondo de pantalla completa.

---

## 9. BOTONES Y TIPOGRAFÍA (R33–R35)

### R33. Sistema de botones: el APOSTAR azul #0B84FF se va; botón del sistema en dorado mate
- **Antes → después:** tres lenguajes conviviendo (`BronzeButton`
  dorado mate; `_HomeButton` navy + borde dorado; consola con
  `_MiniAction` y botón APOSTAR azul `#0B84FF` en `panels.dart`,
  azul eléctrico genérico que NO está en `CachoColors` y se parece
  al azul de marca de otras apps) → UN sistema, sin cambiar el
  significado ni el orden de ningún botón (DUDO/CALZO/PASO/
  APOSTAR, H9):
  - **Primario (JUGAR, APOSTAR, Entrar, Confirmar):** dorado mate
    `#C9A24B` con degradado SOLO entre tonos mates de `#C9A24B`,
    texto oscuro `#2B1810` a ≥ 14 px, 56 px en hojas / 44 px en
    consola. APOSTAR pasa del azul `#0B84FF` a dorado mate y se
    distingue de DUDO/CALZO/PASO por ser el único dorado de la
    consola, no por ser azul.
  - **DUDO:** rojo casino `#B3202A`, texto marfil.
  - **CALZO:** verde esmeralda `#0E7A4F`, texto marfil.
  - **PASO:** azul petróleo `#14586B`, texto marfil.
  - **Secundario (Borrar, Plegar, Copiar, Volver):** cuero
    `#3E2312` con borde dorado de 1 px, texto marfil.
  - Todos ≥ 44 px, radios: 12 px en menús, 16 px en paneles de
    juego (ver R42).
- **Composición:** ninguna (sistema propio; el azul se va por
  brand-guardián, no por gusto).
- **Hereda:** recon R-19 y R-20; sentencia diseño final D24
  (botón primario unificado de 56 px, degradado solo entre tonos
  mates de `#C9A24B`) y D14 (sin VER; acciones solo DUDO/CALZO/
  PASO/APOSTAR).
- **NO cambia:** significado, orden, validación ni reglas de
  ningún botón; DUDO/CALZO/PASO conservan su color y su orden.

### R34. Estados del botón del sistema: normal, presionado, deshabilitado, seleccionado
- **Antes → después:** estados implícitos o por opacidad ad hoc
  (p. ej. APOSTAR deshabilitado como azul al 30%) → estados
  definidos para TODO el sistema (R33): normal (color pleno);
  presionado (mismo color, 8% más oscuro, sin cambio de tamaño);
  deshabilitado (color al 30% + texto al 50%, sin desaparecer, sin
  cambiar de posición: el botón que falta por saldo o por regla
  se ve deshabilitado, no ausente); seleccionado (borde dorado de
  2 px + fondo dorado mate, como R10). Ningún estado baja el texto
  de 14 px ni el target de 44 px, y ningún estado usa verde/
  amarillo/rojo de semáforo fuera de turno (el semáforo solo vive
  en el aro).
- **Composición:** ninguna.
- **Hereda:** recon R-19; sentencia diseño final D11 (semáforo
  solo en el aro) y D20 (bloqueo por saldo insuficiente sin cobrar,
  visible como bloqueo, no como ausencia).
- **NO cambia:** reglas de habilitación (saldo, turno, apuesta
  mínima) ni contenido de los botones.

### R35. Escala tipográfica con piso 14 y jerarquía fija; contraste mezclado a medir
- **Antes → después:** familias válidas (Cinzel títulos,
  CaveatBrush logo y "Tu apuesta", Montserrat cuerpo) con tamaños
  dispersos y 20+ textos bajo 14 px → escala fija, sin excepción
  por debajo de 14 px en pantalla:
  - Logo DUDO: CaveatBrush 44 px (home) / 30 px (barras), sin cambio.
  - Títulos de pantalla/hoja: Cinzel ≥ 20 px.
  - Títulos de tarjeta: Cinzel ≥ 17 px.
  - Cuerpo y etiquetas: Montserrat ≥ 14 px.
  - Cifras (saldo, pozo, apuesta): Montserrat negrita ≥ 16 px.
  - Código de sala: Cinzel 44 px (lobby, se conserva) / 24 px
    (hoja amigos, R15).
  - Todo texto menor de 14 px se elimina o se integra en otro
    elemento (como el pie del home, R4); nunca se achica para que
    quepa. Los pares principales YA pasan 4,5:1 (dorado `#C9A24B` /
    fondo `#120C09` = 8,09:1; marfil / navy = 14,58:1; blanco / rojo
    casino = 6,65:1; marfil / paño = 6,71:1, medidos en el recon);
    condición para el tribunal: medir los textos con alfa
    (`white38`, `white70`, dorado al 85%) MEZCLADOS sobre su fondo
    real antes de sentenciar, porque el recon no midió mezclas.
- **Composición:** ninguna.
- **Hereda:** recon R-21; sentencia diseño final D2 (≥ 14 px,
  contraste ≥ 4,5:1, el costo se paga reduciendo o reubicando).
- **NO cambia:** familias tipográficas, textos ni datos; solo
  tamaños y ubicación de los textos bajo el piso.

---

## 10. INTEGRACIÓN CON LA MESA YA CONSTRUIDA (R36–R37)

### R36. El tema viaja y se reconoce: misma miniatura, mismo marco, mismo paño de home a mesa
- **Antes → después:** home y hojas sin mesa visible; lobby con
  paño verde; mesa horizontal con sala PIL (tres mundos sin
  puente) → la miniatura REAL del tema (R6, R12, R19) es la misma
  en home, hojas y lobby, y es la misma mesa que el jugador
  encuentra al entrar: mismo paño, mismo marco madera, mismo
  filete dorado (Dorado), misma madera (Pub), mismo marco cian
  dentro del rectángulo (Neón). El tema elegido en la hoja viaja
  con la sala (D23) y la cabecera del lobby lo muestra (R19); al
  entrar a la mesa, el marco y el paño son los ya vistos en la
  miniatura, sin sorpresa.
- **Composición:** Monopoly Poker (la mesa se reconoce antes de
  entrar).
- **Hereda:** recon R-11 y R-14; sentencia diseño final D15 (PIL
  por tema), D18 (miniatura propia) y D23 (tema que viaja).
- **NO cambia:** la mesa horizontal (H1, asientos, escenario,
  consola, barra), los temas ni el tema por defecto (Casino
  Dorado).

### R37. Transición home → mesa: mismo dorado, misma placa de pozo, mismo avatar al centro anunciado
- **Antes → después:** salto home → mesa sin continuidad (el home
  no anuncia ni el pozo fijado ni mi asiento) → continuidad en
  tres puntos, sin tocar la mesa: (a) el dorado mate `#C9A24B` es
  el mismo en franja (R1), tarjetas (R2), placa de pozo (R13) y
  barra de mesa (D10); (b) la placa de pozo de la hoja (R13) usa
  el mismo rótulo "POZO" y la misma fórmula que la barra de mesa
  ("Pozo fijado al partir", D9); (c) la tarjeta de juego y la
  cabecera del lobby anuncian "tu asiento al centro, bajo tu vaso"
  con la misma miniatura (R6, R19), para que mi avatar al centro
  bajo el vaso no sea una sorpresa al entrar. Nada de esto añade
  elementos a la mesa.
- **Composición:** ninguna (continuidad de sistema propio).
- **Hereda:** sentencia diseño final D9 (pozo fijado canónico en
  la barra), D21 (sala activa) y decisión 28 (mi avatar al centro,
  bajo mi vaso).
- **NO cambia:** la mesa, el hueco 104, mi vaso, mi avatar, el
  pozo fijado ni las reglas.

---

## 11. R-MESA-ELEGANTE — refinamiento visual SOLO (R38–R43)

**Familia obligatoria. Explícito en cada propuesta: NO se toca H1,
escenario 330×140, dados 44, hueco 104, peek, Kamikaze, CU4, barra
56, consola 300, barra plegada 44, semáforo. Burdeos en partida
sigue sin demostrar (C6) y no entra por esta vía. Sin vasos
rivales (puerta CU4 + decisión del usuario 25-oct). Solo bordes,
luz, textura, radios y sombra: nada de geometría, nada de reglas.**

### R38. Doble filete en el marco de la mesa
- **Antes → después:** borde madera 8 px + filete interior dorado
  1,5 px al 55% (`landscapeTableDecoration`,
  `landscapeFilletColor`) → filete exterior madera oscura + filete
  interior dorado mate + una línea fina marfil al 20% por dentro,
  como el ribete de un paño de casino real. Solo código (bordes),
  sin tocar assets ni geometría.
- **Composición:** ninguna (paño de casino real, no referencia de
  videojuego).
- **Hereda:** recon R-22; sentencia diseño final D15 (dorado
  envejecido, sin brillo de moneda).
- **NO cambia:** H1, escenario, dados, hueco, peek, Kamikaze, CU4,
  barra, consola, semáforo. Burdeos no entra (C6).

### R39. Luz cenital radial sobre el paño
- **Antes → después:** paño `felt_bg.png` plano con el color de
  borde → degradado radial sutil POR ENCIMA de la textura (centro
  apenas más claro, bordes apenas más oscuros), como lámpara de
  casino sobre la mesa. No cambia la textura ni el color firma;
  solo la luz. En Neón, la luz es fría y tenue y el cian sigue
  solo en el marco.
- **Composición:** ninguna (luz de casino, D15).
- **Hereda:** recon R-23; sentencia diseño final D15 (luz cenital
  elíptica, bokeh cálido FUERA del paño, zona calma obligatoria).
- **NO cambia:** textura, color firma, H1, escenario, dados,
  hueco, peek, Kamikaze, CU4, barra, consola, semáforo. Burdeos no
  entra (C6).

### R40. Sala PIL con viñeta y zona calma, no con detalle
- **Antes → después:** sala Dorado foto (`room_dorado.png`) y sala
  Pub foto (`bg_pub.png`) sin viñeta sistemática → viñeta oscura
  progresiva en los bordes de la sala + zona calma detrás de los
  asientos (obligatoria bajo dados, avatares, nombres, pipas y
  aros), para que la sala se sienta profunda sin competir con el
  paño. La sala no gana detalle nuevo: gana profundidad por
  viñeta.
- **Composición:** 8 Ball Pool R-02 (sala oscura que no compite).
- **Hereda:** recon R-24; sentencia diseño final D15 (zona calma
  obligatoria; bokeh FUERA del paño).
- **NO cambia:** H1, escenario, dados, hueco, peek, Kamikaze, CU4,
  barra, consola, semáforo. Burdeos no entra (C6).

### R41. Textura propia para la sala Neón (hoy plano vacío)
- **Antes → después:** sala Neón como plano `#05070C` sin textura
  (se lee como vacío sin terminar, no como oscuridad elegante) →
  textura oscura sutil propia (grano + viñeta, en la familia de
  `felt_bg`/`wood` pero casi negra, sin cian, sin marca ajena) en
  la sala, con el cian SOLO dentro del rectángulo-mesa (marco).
  La textura no lleva brillo, partículas ni animación.
- **Composición:** 8 Ball Pool R-02 (oscuridad elegante, no vacío).
- **Hereda:** recon R-02 y R-24; sentencia diseño final D15 (Neón
  casi negro con cian solo dentro del rectángulo-mesa y resto en
  Cuero y Paño).
- **NO cambia:** H1, escenario, dados, hueco, peek, Kamikaze, CU4,
  barra, consola, semáforo, tema Neón. Burdeos no entra (C6).

### R42. Radios coherentes: mesa 28, panel 16, tarjeta 12
- **Antes → después:** rectángulo-mesa radio 28 px, consola lateral
  radios 24 px solo a la izquierda, tarjetas de menú 12–16 px (sin
  regla) → regla fija: 28 px SOLO para la mesa (es el mueble),
  16 px para paneles de juego (consola, barras, hojas de partida),
  12 px para tarjetas de menú (home, hojas, lobby, tienda). Sin
  tocar tamaños: solo radios.
- **Composición:** ninguna (coherencia de sistema propio).
- **Hereda:** recon R-25; sentencia diseño final D15 (mueble vs.
  panel vs. tarjeta, implícito en la jerarquía de la sala).
- **NO cambia:** tamaños, H1, escenario, dados, hueco, peek,
  Kamikaze, CU4, barra, consola, semáforo. Burdeos no entra (C6).

### R43. Sombra única bajo cada asiento, con la misma luz que R39
- **Antes → después:** vaso con sombra elíptica y asientos solo
  con aro → sombra suave y ÚNICA bajo cada asiento (misma
  dirección de luz que la cenital de R39), para asentar los
  avatares sobre la sala, sin animaciones nuevas. La sombra no
  lleva color de turno: el aro sigue siendo el semáforo, y la
  sombra nunca tiñe ni tapa el aro.
- **Composición:** ninguna.
- **Hereda:** recon R-27; sentencia diseño final D11 (el aro ES el
  semáforo; sin señales nuevas).
- **NO cambia:** H1, escenario, dados, hueco, peek, Kamikaze, CU4,
  barra, consola, semáforo, colores de identidad. Burdeos no entra
  (C6).

---

## 12. R-PANTALLA-COMPLETA — requisito duro (R44–R49)

**Familia obligatoria. Criterio de verificación de TODA la familia
(requisito duro, literal): nada jugable cortado en ningún viewport
con cromo visible, con o sin pantalla completa, y el juego se ve
completo SIN instalar nada (la app no está en la App Store y
ninguna solución puede depender de instalar fuera de ella).
Jerarquía fijada por el usuario: (a) el arreglo principal, en el
navegador tal cual SIN instalar nada; (b) botón de pantalla
completa SOLO donde el navegador lo permite de verdad; (c)
"Añadir a pantalla de inicio" SOLO como opción extra voluntaria.
"Usa Chrome en iPhone" NO se propone porque es falso (Chrome en
iPhone usa WebKit por obligación de Apple y TAMPOCO permite
pantalla completa de página).**

**Diagnóstico que estas propuestas resuelven (recon §4.2, captura
`antes_mesa_cortada.jpg`):** en Safari real de iPhone con cromo
visible, la consola lateral queda cortada por abajo y los botones
DUDO/CALZO/PASO/APOSTAR quedan bajo el cromo. Causa: la consola
(`SideBidDock`, ~295–320 px intrínsecos) no tiene scroll ni modo
compacto, mientras la mesa SÍ tiene modo ajustado (122 px) y la
barra plegada (44 px) es el único estado horizontal a prueba de
cromo. La consola es el único componente grande sin equivalente
compacto.

### R44. Layout a la altura visible REAL: altura dinámica + SafeArea + viewport-fit=cover
- **Antes → después:** layout que presupone alturas mínimas en
  sus hijos y `app/web/index.html` SIN `<meta name="viewport">`
  ni `viewport-fit=cover`, sin código de altura dinámica,
  `visualViewport`, `100dvh`/`100svh` ni Fullscreen API → el
  layout mide la altura visible REAL en cada cambio (altura
  dinámica / `visualViewport`, no altura supuesta; reacción a que
  Safari muestre u oculte sus barras) y deriva de ella el modo de
  consola (R45); `index.html` gana `<meta name="viewport"
  content="width=device-width, initial-scale=1,
  viewport-fit=cover">` y el layout respeta `SafeArea` real
  (notch/indicador) sin suponerlos. Sin esto, cualquier modo
  compacto seguirá midiendo mal.
- **Composición:** ninguna (corrección de plataforma).
- **Hereda:** recon Vía A (A3) y §4.2.4; sentencia diseño final
  D16 (cambio de SafeArea cuando Safari muestra/oculta sus barras,
  probado en la prueba H18).
- **NO cambia:** geometría de diseño (844×390, mesa 544×334) como
  referencia nominal; H1, escenario, dados, hueco, peek, Kamikaze,
  CU4, barra 56, consola 300, barra plegada 44, semáforo. La altura
  real en Safari de iPhone con cromo visible NO está medida (el
  recon usa `H_visible ≈ 330` como ejemplo, no como medición): el
  tribunal debe exigir la medición real antes de fijar el umbral
  de R45.

### R45. Modo compacto de consola dentro de la página, con orden de encogimiento fijo
- **Antes → después:** consola lateral sin scroll ni
  encogimiento (cabecera 44 + chip de apuesta ~28 + fila de 6
  dados ~52 + fila de apuesta armada ~32 + chip de probabilidad
  20–44 + fila DUDO/CALZO/PASO 46 + botón APOSTAR 44 + separadores
  ~21 + padding 8 ≈ 295–320 px; con `H_visible` bajo, lo que sobra
  cae fuera por abajo y lo primero que cae son los botones) →
  por debajo del umbral de altura real (a fijar por el tribunal
  con la medición de R44), la consola entra en MODO COMPACTO
  dentro de la página (misma información, menos aire), con este
  orden de encogimiento, sin romper pisos:
  1. Primero el aire: separadores y padding (de ~21 + 8 a ~8 + 4).
  2. Segundo los elementos informativos plegables: chip de
     probabilidad a una línea con elipsis (y oculto solo si el
     cálculo no existe, como ya manda D12) y mensajes
     informativos a una línea.
  3. Tercero la densidad de la fila de dados (separación entre
     dados, no tamaño: los dados siguen a 44 px y las pintas a
     ≥ 44 px).
  4. NUNCA se encogen los botones de acción por debajo de 44 px,
     nunca el texto por debajo de 14 px, nunca se toca el
     semáforo, nunca cambia el orden DUDO/CALZO/PASO/APOSTAR,
     nunca se cancela ni modifica la apuesta armada al compactar.
  El modo compacto es el equivalente de la consola al modo
  `tight` de la mesa (122 px): la consola deja de ser el único
  componente grande sin equivalente compacto.
- **Composición:** ninguna (corrección propia, espejo del `tight`
  de la mesa).
- **Hereda:** recon Vía A (A1) y R-28; sentencia diseño final D12
  (consola ≤ usable tras SafeArea) y C1 (orden de recorte: piso
  14 px, pintas 44 px y dados 44 px innegociables).
- **NO cambia:** contenido, validación, reglas, orden de botones,
  semáforo, peek, Kamikaze, CU4, apuesta armada, temporizador de
  60 s ni pitidos. El umbral exacto lo fija el tribunal con
  medición real (R44), no este brainstorm.

### R46. Barras plegables dentro de la página: música a icono, barra 56 intacta, barra plegada 44 segura
- **Antes → después:** barra de música como fila completa (~34 px)
  siempre visible en línea, restando altura a la fila mesa +
  consola → en altura escasa, la barra de música (R27) se pliega
  a icono ♫ 44×44 + nombre del tema a 14 px, devolviendo ~34 px a
  la fila; la barra superior de 56 px NO se pliega (lleva turno,
  pozo y saldo) y la barra plegada de 44 px NO se recorta (es el
  estado seguro: `FoldedActionBar` como último hijo de la
  `Column` siempre queda dentro de la pantalla). Plegar la música
  nunca pausa ni reinicia temporizador ni semáforo, y la hoja
  DJ/cola (R28) sigue accesible en 1 toque desde el icono.
- **Composición:** ninguna.
- **Hereda:** recon Vía A (A2) y R-17; sentencia diseño final D10
  (DJ compacto sin tapar pozo ni pastilla) y D13 (barra mínima).
- **NO cambia:** DJ, cola, temporizador, semáforo, barra 56,
  barra plegada 44 ni apuesta armada.

### R47. Scroll interno de emergencia SOLO si el modo compacto no da, con decisión D12 para el tribunal
- **Antes → después:** consola sin scroll (hoy, si no cabe, corta
  botones) → red de seguridad, ÚLTIMO recurso, no el diseño: si
  aun en modo compacto (R45) la altura no da (viewport extremo),
  la consola pasa a scroll interno ANTES de cortar ningún botón.
  El tribunal debe decidir expresamente si este scroll de
  emergencia en viewport extremo viola D12 ("consola sin scroll
  en turno" para la altura de diseño) o es su excepción
  documentada; este brainstorm no decide por él: propone el scroll
  solo como excepción, con DUDO/CALZO/PASO/APOSTAR siempre
  visibles y tocables a ≥ 44 px como criterio (si el scroll los
  esconde, no sirve y cae).
- **Composición:** ninguna.
- **Hereda:** recon Vía A (A4); sentencia diseño final D12 y C1
  ("nunca desplazamiento interno en turno" — la tensión con esta
  propuesta queda señalada para el tribunal, no resuelta aquí).
- **NO cambia:** botones, textos, semáforo, reglas ni apuesta
  armada; el scroll de emergencia no es el diseño normal.

### R48. Botón de pantalla completa SOLO donde el navegador lo permite de verdad; en iPhone no se muestra, nunca un botón muerto
- **Antes → después:** ningún código de pantalla completa en el
  repo (hoy no existe: hay que construirlo por interop JS, porque
  Flutter web no tiene widget de pantalla completa) → botón de
  pantalla completa (Fullscreen API, `requestFullscreen` con
  gesto del usuario) SOLO en Android Chrome y escritorio (Chrome,
  Edge, Firefox, Safari de escritorio según soporte), ubicado
  junto al engranaje de ajustes (R23, en menús; nunca tapando
  asientos ni la barra de 56 px); al salir, el layout vuelve al
  modo de R44/R45 sin romper la partida ni la apuesta armada. En
  iPhone (Safari Y Chrome Y cualquier navegador iOS: todos usan
  WebKit por obligación de Apple y NO permiten pantalla completa
  de página, solo video) el botón NO se muestra; como máximo, un
  renglón explicativo sin acción ("en iPhone la pantalla completa
  de página no está permitida; el juego se ve completo sin
  ella"), pero NUNCA un botón muerto que no haga nada al pulsarlo.
  La pantalla completa es MEJORA, no arreglo: el requisito duro
  debe cumplirse también SIN ella, y un diseño que solo funcione
  en pantalla completa está rechazado por definición.
- **Composición:** ninguna (capacidad de plataforma, no diseño).
- **Hereda:** recon Vía B y R-29; sentencia diseño final D16 (sin
  forzar rotación ni fullscreen).
- **NO cambia:** partida, apuesta armada, temporizador, semáforo
  ni servidor. "Usa Chrome en iPhone" NO se propone: es falso.

### R49. "Añadir a pantalla de inicio" SOLO como opción extra voluntaria, CONDICIONADA a corregir primero el PWA
- **Antes → después:** PWA a medias con residuos de plantilla y
  ninguna opción ofrecida → "Añadir a pantalla de inicio" se
  ofrece SOLO como opción extra voluntaria en ajustes de menús
  (R23), explicada con texto exacto: función oficial de Safari
  (Compartir → Añadir a pantalla de inicio); NO es instalar por
  fuera, NO es sideload, NO pasa por la App Store, NO instala
  código ajeno: crea un icono que abre LA MISMA WEB
  (https://cacho.pages.dev) sin las barras del navegador. Y SOLO
  DESPUÉS de corregir el PWA, porque hoy abriría una "app" con
  identidad ajena. Corrección previa obligatoria (verificado en
  `app/web/`):
  - `manifest.json` `name`/`short_name`: `cacho_app` → DUDO (o
    "Cacho · El Dudo Chileno" / "DUDO", a fijar por el tribunal).
  - `manifest.json` `description`: "A new Flutter project." →
    descripción real de Cacho (sin promesas falsas).
  - `manifest.json` `theme_color`/`background_color`: `#0175C2`
    (azul plantilla Flutter) → dorado mate `#C9A24B` / fondo
    `#120C09` propios.
  - `manifest.json` `orientation`: `portrait-primary` → revisar
    para no contradecir la mesa horizontal (en iOS se ignora en
    gran parte, pero en Android orienta la app instalada).
  - Iconos 192/512 + maskable: arte actual = logo de Flutter
    (verificado visualmente en el recon) → icono DUDO propio.
  - `index.html` `<title>` y meta description: `cacho_app` /
    "A new Flutter project." → identidad DUDO real.
  - `index.html` `apple-mobile-web-app-capable`: AUSENTE →
    añadir (meta clásica de iOS para abrir sin cromo).
  - `index.html` `apple-mobile-web-app-title`: `cacho_app` → DUDO.
  - `index.html` `apple-touch-icon`: `icons/Icon-192.png` (logo
    Flutter) → icono DUDO propio.
  - `index.html` viewport + `viewport-fit=cover`: AUSENTES →
    añadir (ver R44).
  - Sin corregir esta tabla, la opción NO se ofrece. Con la tabla
    corregida, sigue siendo opcional: el juego debe verse
    completo sin usarla.
- **Composición:** ninguna.
- **Hereda:** recon Vía C y R-30; decisión del usuario 25-oct
  (Añadir a pantalla de inicio solo como opción extra voluntaria,
  nunca como requisito; ninguna solución puede depender de
  instalar fuera de la App Store).
- **NO cambia:** nada de partida, servidor ni economía. El service
  worker del build y `apple-touch-startup-image` no están en el
  fuente de `app/web/`: sin verificar (no se afirma ni se niega
  desde el fuente).

**Verificación obligatoria de la familia R44–R49 (el tribunal debe
exigirla):** misma partida, misma consola abierta, en: 844×390 sin
cromo; Safari iPhone con pestañas + direcciones visibles (el caso
de `antes_mesa_cortada.jpg`); Safari iPhone con cromo colapsado al
desplazar; PWA instalada (opción voluntaria, R49); Android Chrome
con y sin pantalla completa; escritorio. En todos, DUDO/CALZO/PASO/
APOSTAR visibles y tocables a ≥ 44 px, sin scroll sorpresa, con
texto ≥ 14 px y semáforo intacto.

---

## 13. IDEAS DEL RECON DESCARTADAS (con motivo; no entran en R1–R49)

| Idea del recon | Motivo del descarte |
|---|---|
| R-07(b) brillo sutil del asiento en turno | Sentencia diseño final D11: el aro ES el semáforo; "sin brillo extra fuera de turno" y "turno sin señales nuevas". Un brillo, aunque sea en turno, es una señal nueva junto al semáforo. No se propone. |
| R-07(a) / R-26 pozo al centro del paño | Condicionado a captura C2 (sentencia diseño final C2: duplicado solo si la captura con 11 rivales demuestra cero solape, mismo valor y mismo rótulo). Esa captura NO existe. No se propone hasta que C2 se demuestre; no es un rechazo definitivo, es un apartado por falta de evidencia. Sin esa captura, el pozo queda solo en la barra (D9). |
| R-03 leído como "barra abajo en horizontal" | H8 rechazada (consola abajo en horizontal). La lectura válida de R-03 (botón primario último en hojas verticales) sí entró como R18. |
| R-06 leído como "rehacer la mesa en vertical" | Camino horizontal decidido, no se reabre; vertical de partida congelado como fallback (H17, sentencia mesa horizontal). La lectura válida (vertical profesional solo para hojas/lobby) entró como R7/R9. |
| Racha diaria en el panel del home | D1 de la v2.0 cayó a Fase C: no existe como dato real. Mostrarla sería un número falso. El panel (R2/R8) muestra solo saldo, rescate y sala activa. |
| Vaso burdeos `#5E2129` en partida | C6 sin demostrar: entra solo si la captura CU4 demuestra que el semáforo se lee sin ambigüedad junto a él y junto a los otros 3 cueros. No entra por esta vía; sigue en Personalizar y vista previa. |
| Vasos rivales sobre la mesa | Puerta CU4 bloqueante + decisión del usuario 25-oct ("Mantengo la puerta, sin vasos rivales"). Veredicto medido: 17 solapes a 544×334 y 11 a 844×290. No vuelve. |
| "Usa Chrome en iPhone para pantalla completa" | FALSO: Chrome en iPhone usa WebKit por obligación de Apple y tampoco permite pantalla completa de página (solo video). No se propone. |
| "Instala la app" como arreglo del corte | La app no está en la App Store y ninguna solución puede depender de instalar fuera de ella. La instalación es solo opción voluntaria (R49), nunca el arreglo. |
| Botón VER / igualar / ALL-IN / PASAR de póker | G.3 + sentencia diseño final D14: crear VER sería un cambio de reglas; las reglas están cerradas. El peek es tocar el vaso (D8). |
| Multi-moneda, SALE, gemas, bundles, BUY ALL, cofres, ligas, XP, trofeos con progresión | Cercas de economía + F.5/G.3/H19. Nada de esto se adapta: se descarta. |
| Chat, emojis, reacciones en partida | B20 rechazada: serían señales en juego de farol. |
| Arte, marca, colores y textos de 8BP / Parchisi / Monopoly | H19/F.5/G.3 + estilo propio Cuero y Paño. Solo composición prestada, nunca estilo. |
| Navegador público de salas, contadores de salas/jugadores en línea, espectadores inventados | Sentencia diseño final C3/D23: no se inventa navegador público; D19 basta como selector de tier en creación. Cero números falsos. |
| Cambiar H1 por óvalo, mover la consola abajo, cambiar el paño verde Dorado por otro color, neón fuera del rectángulo-mesa | Fuera del alcance de esta ronda: la mesa no se rehace (H1 rectángulo vigente tras la caída del óvalo por apiñamiento); H8 rechazada; Dorado es el tema por defecto (D1 v2.0); neón solo dentro del rectángulo (Fase A). |
| Precios puntuales nuevos de tienda | Sentencia diseño final D27: solo bandas aprobadas (vasos 500–1500, dados 300–1000, marcos 200–500, celebraciones 500). Ningún precio puntual nuevo. |
| Revancha en línea | Sentencia diseño final D26/B4: fuera hasta aceptación explícita de TODOS antes de cobrar, con reverificación de saldo. No se diseña aquí. |

---

## 14. PROPUESTAS "SIN VERIFICAR (SOLO CÓDIGO)" — el tribunal debe condicionarlas a captura

Estas propuestas descansan solo en descripción de código, porque sus
pantallas no tienen captura ANTES en esta ronda (`audit/rediseno/`):

- **R15** — Hoja CON AMIGOS: código legible + invitación anunciada.
- **R17** — Creación en línea: misma hoja que la local, billetera indicada.
- **R19** — Lobby con fondo de MENÚ + miniatura real de mesa en cabecera.
- **R20** — Lobby: cabecera fija + asientos como tarjetas uniformes.
- **R21** — Lobby: etiquetas a ≥ 14 px, código Cinzel 44 px conservado.
- **R22** — Hoja de ajustes: engranaje único, tres entradas, sin micrófono.
- **R23** — Ajustes (menús): renglón de pantalla completa / añadir a inicio.
- **R24** — Tienda presentada: cuadrícula uniforme, bandas, billetera indicada.
- **R25** — Tienda: vista previa en vivo sin equipar sin pagar.
- **R26** — Tienda: textos a ≥ 14 px, dados por símbolo, marcos sin teñir el semáforo.
- **R28** — Hoja DJ/cola: solo DJ, sin micrófono, textos ≥ 14 px.

Además, sin verificar y fuera de estas propuestas: altura visible
real en Safari de iPhone con cromo visible (número exacto de puntos;
el umbral de R45 debe fijarse con esa medición); mezcla de colores
con alfa sobre fondos reales (R35, condición de medición); service
worker del build y `apple-touch-startup-image` (R49, no en el fuente
de `app/web/`); comportamiento exacto de Flutter web ante el colapso
de las barras de Safari (la familia R44–R49 debe probarse en Safari
real, como exige D32).

**Propuestas con evidencia visual (captura ANTES) y por tanto no en
esta lista:** R1–R8 (home, `antes_home.jpg`), R9–R14, R16, R18 (hoja
local, `antes_contra_maquina.jpg`), R27 (barra de música,
`antes_mesa_cortada.jpg`), R29–R43 (sistema y mesa, capturas +
código + sentencias), R44–R49 (corte verificado en
`antes_mesa_cortada.jpg`; solo el umbral numérico de R45 queda
pendiente de medición real).

---

*Fin del brainstorm. 49 propuestas (R1–R49). Nada de código modificado,
nada desplegado, nada tocado en producción, servidor ni APK.*
