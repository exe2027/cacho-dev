# Cacho — Guía de diseño

Concepto: mesa de casino elegante y nocturna con alma de cacho chileno. Protagonista: el cacho de cuero realista. Diseño original, sin marcas de casinos reales.

## Paleta

| Uso | Color |
|---|---|
| Mesa (centro → borde) | `#0B5D3B` → `#06402A`, radial, textura de paño sutil |
| Borde de mesa | Madera oscura `#2B1810`, acolchado burdeos `#5A1A1A`, costuras doradas |
| Acentos / títulos / botón principal | Dorado envejecido `#C9A24B` |
| Dudo / alertas / Kamikaze | Rojo casino `#B3202A` (Kamikaze con aura pulsante) |
| Dados / texto principal | Marfil `#F5EBD7` |
| Fondo fuera de la mesa | Casi negro cálido `#120C09`, viñeta tipo lámpara de casino |
| Paso | Azul petróleo |
| Calzo | Verde esmeralda |
| Cuero del cacho | `#6B3F22` → `#3E2312`, grano visible, costuras, banda dorada/remache |

Cachos personalizables: cuero café, negro, burdeos o azul petróleo; banda e iniciales grabadas.
Dados cosméticos: marfil (base, 1 con punto rojo = comodín visible), rojo translúcido casino, negro con puntos dorados, hueso antiguo. Las pintas se distinguen también por forma/símbolo (accesibilidad daltonismo), no solo por color: As, Pato, Tren, Cuadra, Quinta, Sexta.

## Tipografía

- Títulos: serif art déco (Cinzel / Playfair Display).
- Números y botones: sans legible (Inter / Montserrat), textos escalables.

## Pantalla de partida (vertical)

- **Arriba:** barra madera/dorado: sala, temporizador de turno, botones reglas y silencio.
- **Centro:** mesa de fieltro; cachos rivales en semicírculo (boca abajo, mini-dados marfil = cuántos le quedan, apodo y avatar con marco dorado); al centro, placa dorada con la apuesta actual (cantidad + dado de la pinta).
- **Abajo:** tu cacho grande en primer plano y tus dados (solo tú los ves; botón tapar/destapar).
- **Franja inferior:** selector de cantidad y pinta + botones grandes tipo placa de bronce: **Subir** (dorado), **Paso** (azul petróleo, deshabilitado si no tienes 5 dados), **Dudo** (rojo), **Calzo** (verde), **Kamikaze** (rojo brillante pulsante, solo visible cuando está ofrecido).
- Historial de la ronda: cinta deslizable/cajón con íconos por jugada.

## Animación y sonido (60 fps, opción "efectos reducidos")

- Agitar: botón o sacudir el celular (acelerómetro); el cacho se sacude, suenan los dados dentro, vibra; al soltar, golpe seco sobre el paño.
- Revelación (Dudo/Calzo): todos los cachos se levantan a la vez, dados con leve rebote, conteo uno a uno resaltando coincidencias.
- Perder dado: se desintegra/apaga + sacudón. Ganar: destello dorado + tintineo.
- Calzo exitoso: lluvia de destellos dorados. Dudo: luz roja breve + golpe.
- Kamikaze: se atenúa la sala, foco sobre el jugador, redoble, rueda 1-6 para elegir, todos agitan y revelan a la vez; los dados coincidentes se prenden en rojo y explotan en chispas; vibración fuerte.
- Eliminación: el cacho cae y se oscurece, avatar apagado. Victoria: confeti dorado, fichas cayendo, cacho ganador al centro con foco.
- Sonido: dados en cuero, golpe de cacho, fichas, murmullo de casino + jazz/lounge muy bajo; volumen por canal y silencio; un sonido/voz distinto para Dudo, Calzo, Paso y Kamikaze. Háptica al lanzar, apostar, dudar, calzar y en Kamikaze. Pantalla siempre encendida en partida.
- Gráficos vectoriales + Rive/Lottie, texturas comprimidas.

## Filosofía visual: "Cuero y Paño" (22-oct, con las skills de diseño)
Dirección de arte única y sobria: materiales honestos de la mesa real —
paño verde botella con grano, madera oscura con veta, cuero con costura
y grano, dorado envejecido como ÚNICO acento, dados marfil. La osadía
vive en un solo lugar por pantalla (el vaso y su secuencia; el panel de
apuesta cuando aparece); todo lo demás es quieto y disciplinado.
Texturas generativas con semilla (tools/gen_textures.py): felt_bg.png y
wood.png. Tipografía: Cinzel para títulos (con tracking), Montserrat
para la UI; ninguna etiqueta decorativa que no informe. Sin textos
narrativos durante la partida (orden del usuario): el turno se lee en la
flecha, el aro, el vaso y el sonido.

## 3D real con Blender (22-oct, orden del usuario)
El vaso y los dados son renders 3D de Blender (Cycles, fondo
transparente) usados como sprites: tools/render_blender.py modela el
vaso torneado en cuero (banda dorada, grano por ruido) en los 4 colores
de cuero y los 6 dados marfil biselados con pipas en relieve en las 6
caras (opuestos suman 7; el 1 es rojo y grande). Salida:
app/assets/images/cup_{cafe,negro,burdeos,petroleo}.png y die_1..6.png.
EEVEE no corre en esta VM (falta libEGL); Cycles CPU sí. Detalle: al
renderizar, verificar SIEMPRE los archivos en disco — los avisos de
"proceso terminado" llegaron antes que los renders más de una vez.
El panel de apuesta (BidDock) vive DENTRO de la mesa: se abre solo al
llegar mi turno (lógica por nivel en _onChange, no por borde: si la
partida parte conmigo el borde no existe) y compara mis dados con la
pinta elegida en vivo.

## Mundo pub (22-oct, referencias del usuario) — supersede al paño en la partida
- La partida vive en un bar oscuro: fondo `bg_pub.png` (bokeh cálido + mesa de madera con luz cenital, compuesto en PIL en `tools/gen_plate.py`; el render Blender del plato quedó descartado por soso, el vaso sí es Blender), logo DUDO en Caveat Brush con corona, asientos con aro de color por jugador + punto de presencia + pipas de dados restantes, tarjeta de estado azul marino `#141B28`.
- Vaso protagonista: sprite Blender v2 con costuras crema, gigante al centro; la inicial del jugador va sobre el sprite.
- Consola de apuesta integrada (su diseño): se arma TOCANDO las pintas (cada toque +1 a esa cara; otra cara reinicia en 1; tope = dados en juego con vibración); lectura grande "N × Pinta" con Borrar (deshacer); ficha APUESTA ACTUAL / APUESTA MÍNIMA (de la cara elegida); si falta, APOSTAR dice "Faltan N para llegar a M Pintas"; VER y DUDO a los lados; CALZO/PASO en fila fina. La consola se abre sola al llegar mi turno (apertura DERIVADA del estado, no por evento).
- Mesa responsive: si el alto disponible es < 470 px (consola abierta), los asientos pasan a compactos y el vaso se escala a 0,62 y sube; sin solapes con 2–6 jugadores.
- Dados de juego = caras planas de marfil con pipas grandes (los cubos isométricos 3D no se leían; corrección suya). Los sprites `die_*.png` ya no se usan en la mesa.
- Revelación precisa (corrección suya): SIN selector de velocidad; el conteo es siempre lento (170 ms/dado); título corto ("¡DUDO!"), una línea de contexto, número grande con el conteo y detalle mínimo (exactos/comodines/se apostó); veredicto = solo la consecuencia ("X pierde 1 dado."); botón "Seguir"; velo al 92% para que la mesa no se cuele.

## Correcciones del usuario post-tribunal (22-oct, tarde)
- Con la consola abierta la barra de acciones se OCULTA: DUDO/CALZO/PASO viven solo en la consola (nada duplicado). El botón de la barra se llama APOSTAR ("Arma tu apuesta" / "Parte la ronda"); subir se hace con las pintas.
- Asientos: 3 rivales van TODOS arriba; los laterales bajan a y=0.42; en modo compacto desaparece la línea de estado (queda la corona del turno) y se ocultan las burbujas de los asientos laterales y del central superior (el vaso las tapaba).
- Cada ronda anuncia quién parte y por qué: "Ronda N: parte X (perdió un dado / calzó justo / salió en el sorteo / activó el Kamikaze)" — local y en línea (manager.js, kind 'starter').
- La revelación se cierra SOLA 3 s después del veredicto (Seguir sigue sirviendo para saltar antes).
- Los bots piensan: base + azar hasta la mitad de la base (1,8–2,7 s; guiada 2,4–3,6 s); en el servidor igual (botDelayMs 1800 + jitter proporcional).
