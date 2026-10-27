# Brainstorm — Diseño final de Cacho

Fecha: 2026-10-24 (noche). Estado: BRAINSTORM (nada de esto está
construido, no se despliega nada, no se toca el servidor ni
producción, no se modifica código en esta ronda).
Alcance: el diseño final COMPLETO — mesa horizontal oval, lobby,
creación de sala, hoja de ajustes en partida, revancha y
presentación de la tienda futura — no solo la mesa.

## 0. Punto de partida y regla de lectura

### 0.1 Fuentes, en orden de autoridad

1. `docs/08-revision-repositorios-diseno-final.md` — revisión de
   esta ronda; punto de partida. Conclusión que se hereda tal
   cual: ningún repositorio externo cambia el diseño final; el
   insumo mayor son las capturas del usuario, las sentencias
   vigentes y los assets propios.
2. `docs/01-arquitectura-y-decisiones.md` (decisiones 1–33) —
   fuente de verdad de reglas y economía. Solo lectura: tiene
   cambios sin commitear de otra sesión y NO se edita aquí.
3. `docs/02-guia-de-diseno.md` (Cuero y Paño), `docs/05-propuesta-
   v2-casino.md` (Fase A construida, Fase B por presentar,
   Fase C como está), `docs/06-brainstorm-frontend-8bp.md`
   (B1–B22), `docs/07-brainstorm-mesa-horizontal.md`
   (H/V/P/O/CU).
4. Sentencias vigentes, autoridad que no se re-juzga:
   `audit/tribunal/sentencia_v2_frontend.md` (16 aceptadas,
   5 condicionadas, B20 rechazada) y
   `audit/tribunal/sentencia_mesa_horizontal.md` (20 aceptadas,
   17 condicionadas, H8 rechazada; camino final HORIZONTAL
   unánime en ronda 3, vertical solo como fallback congelado).

### 0.2 Visión ya clara (no se reabre; se consolida)

Cacho con estilo propio (mundo Cuero y Paño, Casino Dorado, pub
chileno). Mesa HORIZONTAL oval estilo Monopoly Poker como
COMPOSICIÓN (asientos alrededor, pozo al centro, mis dados y mi
vaso abajo al centro, botones de acción abajo). VASOS VISIBLES
de todos los jugadores sobre la mesa (cerrados, sin revelar
dados, Kamikaze a ciegas intacto). Sala profesional alrededor
con el paño limpio y oscuro. Tarjetas de salas por tier con
apuesta y pozo reales. Lobby y creación coherentes con la mesa.
Referencias solo como ejemplos de composición: 8 Ball Pool,
Parchisi Star, Monopoly Poker. Nada de arte, marca, logo,
sonido ni sistema ajeno; composición prestada sí, estilo
prestado no (principio rector, sentencia horizontal).

### 0.3 El prototipo `prototipo-horizontal` es insumo, no rival

El prototipo se construye con el alcance exacto de 13 puntos de
la sentencia horizontal (óvalo, yo al centro, hueco 104,
escenario 0,6, consola lateral plegable con barra abajo, barra
superior, pozo en el paño solo si cabe, aro = semáforo, sala
PIL primero con Blender solo comparando, vasos visibles bajo
CU4, orientación, fondo estático + modo ligero, tarjetas de
tier, piso de texto, capturas obligatorias). En esta revisión
la rama `prototipo-horizontal` está en el commit de Fase A
(`1f45bbe`), sin commits propios del prototipo todavía: por
eso este brainstorm parte del alcance sentenciado de esos 13
puntos, no de un diff de código, y marca en §7 dónde el diseño
final lo CONFIRMA, lo AJUSTA o lo EXTIENDE. Las extensiones
nuevas de este documento son: lobby completo, creación local
y en línea, hoja de ajustes, revancha y presentación de la
tienda (Fase B, sin construirla). Nada de lo aquí propuesto
compite con el prototipo ni lo re-juzga.

### 0.4 Medidas reales ya medidas en el código actual (no supuestas)

Medidas tomadas de `app/lib/theme.dart`,
`app/lib/table_themes.dart`, `app/lib/screens/game_screen.dart`,
`app/lib/widgets/dice_and_cup.dart` y `app/lib/widgets/panels.dart`
en esta revisión. Todo lo que no está en esta tabla es medida
SUPUESTA hasta captura en iPhone real (ver §8, riesgo 1).

| Elemento | Medida real hoy | Piso del diseño final |
|---|---|---|
| Paño | `#0B5D3B → #06402A` (`feltCenter/feltEdge`) | Igual, sin cambio |
| Madera / burdeos / dorado / marfil / fondo | `#2B1810 / #5A1A1A / #C9A24B / #F5EBD7 / #120C09` | Igual; dorado solo en tonos mates de `#C9A24B` |
| Rojo casino / verde calzo / ámbar / azul paso | `#B3202A / #0E7A4F / #F2B705 / #14586B` | Igual; semáforo 60–30 verde, 30–15 ámbar, últimos 15 rojo |
| Mi vaso | 168 × 196 px, boca abajo (`mouthDown`) | Igual; escala 0,6 es techo en horizontal (D6) |
| Mis dados / hueco / mi avatar | 44 px / hueco 104 / avatar 56 (radio 27 fijo) | Intactos en horizontal, fila SIMÉTRICA (H3) |
| Vaso rival (propuesto) | No existe hoy | ~0,5 del mío ≈ 84 × 98, medido en captura (D3, CU1) |
| Nombre rival / estado / EN TURNO / burbuja | 13 / 12 / 10 / 11,5 px | Suben a ≥14 px (D2); lo actual NO se hereda |
| Píldora de pozo actual | Texto 12,5 px | Sube a ≥14 px (D9) |
| Botones de lobby actuales | `minHeight` 34 px | Suben a ≥44 px (D17) |
| Botón de acción actual | `minHeight` 60, etiqueta 14,5, subtítulo 10,5 px | Etiqueta ≥14; subtítulo sube a ≥14 o se elimina (D13) |
| Consola actual (`BidDock`) | Pintas 48 px, nombres de pinta 9,5 px, fila armada 21/18 px, chip probabilidad 44 px alto y 14 px, APOSTAR 58 px alto y 15,5 px | Nombres y textos de ayuda suben a ≥14 sin bajar pintas (D12); si la columna supera 334 px, no se entrega tal cual (H7) |
| Tarjeta de estado / hoja | Azul marino `#141B28` | Igual |
| Mesas | El Pub / Casino Dorado (por defecto, D1) / Neón Nocturno; neón `#37E6FF` solo dentro del rectángulo-mesa | Igual; neón nunca en chrome, botones ni títulos |
| Tiers (código, `stakeTierName`) | Barrio 100 / Salón 250 / Casino 500 / VIP 1.000 / High Roller 2.500 | Igual; ver conflicto C4 sobre los nombres largos de docs/05 |

Medidas SUPUESTAS hasta medición real (de docs/07, no del
código): pantalla horizontal 844 × 390, barra 56 px, consola
lateral ~300 px, mesa resultante ~544 × 334 px, asientos
superiores ~109 px cada uno con 5 arriba. SafeArea, notch e
indicador de inicio recortan ese rectángulo por debajo de
544 × 334; ninguna medida de mesa se fija antes de medirla
tras SafeArea en iPhone real.

## 1. Mesa horizontal oval

### Asientos y óvalo

- **D1. Óvalo con llenado fijo y asientos fijos en partida.**
  Qué: elipse con arco superior 5, laterales 2+2, arco
  inferior 2 + yo abajo al centro; mapeo monótono del orden
  del motor alrededor del óvalo, sin saltos ni cruces; orden
  de llenado: arriba de centro hacia afuera, costados, abajo;
  el asiento central superior solo existe con 3+ rivales
  arriba. Al eliminar, el asiento queda vacío: nunca se
  recompacta ni se altera el orden de turno. Dónde: mesa
  horizontal, en lugar del rectángulo H1. Verificable:
  captura con 11 rivales, consola abierta y cerrada, cero
  solape, laterales dentro de SafeArea y sin acercarse al
  escenario; si el óvalo apiña el arco superior, se mantiene
  el rectángulo H1 (condición O1). Procedencia: hereda O1
  (refina H1, condicionada) y H1 (condicionada); composición
  de Monopoly Poker (óvalo con asientos alrededor), sin su
  color rojo ni su arte.
- **D2. Todos los textos de asiento suben a ≥14 px, sin
  excepción.** Qué: nombre (hoy 13), estado (hoy 12),
  pastilla EN TURNO (hoy 10), burbuja de última jugada (hoy
  11,5), etiqueta PASO (hoy 9), cuenta de desconexión
  (hoy 11) y `×N` de mis dados (hoy ya 14) quedan en ≥14 px;
  nombre a una línea con elipsis, ancho máximo medido
  contra el asiento vecino, nunca invadiéndolo; fila
  superior compacta sin burbuja (como hoy en compacto).
  Contraste ≥4,5:1 de cada texto contra el fondo elegido
  (paño y sala). Verificable: captura con nombres largos y
  11 rivales. Procedencia: hereda el punto 12 del alcance
  del prototipo y la condición H1; tensión heredada de
  docs/08 (piso 14 contra textos actuales) ya decidida por
  la sentencia: se sube, no se hereda.

### Vasos visibles (dirección prioritaria del usuario)

- **D3. Un vaso cerrado por asiento, delante del avatar,
  nunca interactivo.** Qué: cada rival muestra su vaso
  boca abajo con el mismo sprite Blender por color, a ~0,5
  del mío (≈ 84 × 98 px, valor de partida medido en
  captura, no fijo), delante de su avatar, sin tapar
  nombre, pipas, aro, consola, escenario, mi fila ni mi
  hueco 104. Los vasos rivales no se tocan, no se levantan,
  no se mueven por turno ni cambian en partida. Mi vaso
  sigue siendo el único interactivo del centro (agitar,
  espiar, peek). Verificable: puerta CU4 (§6) antes de
  entregar. Procedencia: hereda CU1 (condicionada) y CU4
  (aceptada, bloqueante); dirección prioritaria del
  usuario en docs/07 §H (ver los vasos como en persona).
- **D4. Agitación de inicio de ronda idéntica para todos.**
  Qué: al partir la ronda, todos los vasos se agitan a la
  vez con UNA sola animación y, si lo hay, UNA sola
  muestra de sonido compartidas, duración fija, sin ningún
  parámetro derivado de la mano, la cantidad de dados, el
  jugador ni una semilla por jugador; idéntica también en
  Kamikaze a ciegas; solo al partir la ronda, nunca durante
  una cuenta de turno; aro siempre visible durante la
  agitación; sin pausar ni retrasar el temporizador de
  60 s ni bloquear la primera acción; reducida o
  desactivada con efectos reducidos; sin brillo ni
  partículas extra. Verificable: comparación cuadro a
  cuadro de dos asientos cualesquiera. Procedencia: hereda
  CU2 (condicionada).
- **D5. Color de vaso = color elegido en Personalizar,
  congelado toda la partida.** Qué: cada vaso muestra el
  color elegido por su jugador (los 4 cueros de docs/02:
  café, negro, burdeos, azul petróleo; café por defecto
  sin elección); el color viaja con el jugador
  (perfil/sala), no se sortea ni se inventa; congelado
  durante toda la partida; nunca indicador de turno,
  peligro, eliminación ni resultado; nunca tiñe el aro;
  el semáforo intacto y autoritativo; sin leyenda, orden,
  precio, rareza, tier ni botón de tienda en partida. Los
  vasos de tienda de Fase B entran solo bajo esta misma
  regla (ver D27). Verificable: captura con 11 rivales que
  demuestre que el semáforo se lee sin ambigüedad junto a
  cada uno de los 4 colores; el color que se confunda con
  verde, amarillo o rojo no entra en partida (ver
  conflicto C6, burdeos). Procedencia: hereda CU3
  (condicionada) y D2 de docs/05 (bandas aprobadas, no
  precios nuevos).

### Escenario, hueco y peek

- **D6. Escenario al centro, escala 0,6 como techo, dados
  siempre a 44 px.** Qué: mi escenario (vaso + dados) va
  al centro de la mesa horizontal, sin escala compacta
  0,72 ni desplazamiento por consola abierta (la consola
  va al costado, H7, y abrirla no roba alto de mesa; se
  jubila la alineación 0,66 del vertical). 0,6 es valor de
  partida y TECHO, no fijo: si algo roza, baja solo la
  escala del vaso, nunca la de los dados; la fila de
  dados queda fuera de la escala del vaso o con su tamaño
  interno compensado, para que mida 44 px en pantalla.
  Animación de agitar/caer/levantar sin cambios.
  Verificable: captura con vaso limpio de los asientos
  superiores y mis dados en peek limpios de mi nombre y
  legibles, consola abierta y cerrada. Procedencia: hereda
  H5 (aceptada con resguardos) y H3 (resguardo de medición).
- **D7. Hueco 104 simétrico sobre mi avatar.** Qué: mi fila
  de dados sigue partida en dos grupos con un hueco de
  104 centrado exactamente sobre mi avatar (56 px), dados
  44 px, reparto `floor(n/2)` / `ceil(n/2)`; en horizontal
  hay ancho de sobra, así que la fila se centra DE VERDAD
  (simétrica, hueco en el centro de la fila) y se jubila
  el truco vertical `left = 98 − L` de la sentencia v53,
  que solo existía por falta de ancho. Mi número de dados
  grande junto a las pipas, en la misma fila, sin invadir
  el hueco 104 (B10). Verificable: captura de peek que
  demuestre hueco medido a 104 px y dados a 44 px.
  Procedencia: hereda H3 (aceptada), H2 (aceptada: yo en
  (0,1) bajo mi vaso, elevado sobre el SafeArea inferior)
  y H4 (aceptada: ningún asiento vuelve sobre el
  escenario; un hueco visual arriba se acepta antes que
  un asiento tapado).
- **D8. Peek igual que hoy; Kamikaze a ciegas idéntico en
  ambos layouts.** Qué: tocar el vaso (toque único, sin
  gesto ni puntería fina) lo levanta y muestra mis dados
  en la misma fila con hueco; en Kamikaze a ciegas el vaso
  se cierra a la fuerza y la mano no se envía ni se
  muestra en ningún layout, tampoco al reconectar; los
  vasos rivales siguen cerrados e idénticos. Sin cambios
  de mecánica ni de reglas. Procedencia: hereda H6
  (aceptada) y la regla 11 de docs/01 (Kamikaze a ciegas).

### Pozo, barra superior y turno

- **D9. Pozo fijado: canónico en la barra, en el paño solo
  si cabe sin mover nada.** Qué: la píldora de pozo vive
  en la barra superior (D10) con el rótulo exacto "Pozo
  fijado al partir" y el valor `apuesta × jugadores
  iniciales`, nunca recalculado al eliminar o salir;
  texto ≥14 px (hoy 12,5). Solo si cabe en el hueco
  existente del borde superior del paño, sin mover
  asientos ni escenario y sin tapar asientos, aros ni
  escenario, se añade además la pareja "Pozo fijado al
  partir" + apuesta vigente rotulada por separado (nunca
  sumada al pozo), en dorado mate, sin pila de fichas ni
  fichas con M, texto ≥14 px y contraste ≥4,5:1. Si no
  cabe, O2 cae y el pozo queda solo en la barra. La
  placa dorada de la apuesta vigente NO se reintroduce
  en el centro: el centro del paño lo ocupa mi vaso.
  Verificable: captura con 11 rivales, consola abierta y
  cerrada, que demuestre cero solape en ambas variantes.
  Procedencia: hereda B8 (condicionada: pozo fijado, sin
  fila nueva, vuelo al ganador ≤300 ms, sin partículas,
  desactivado con efectos reducidos), H10 (condicionada)
  y O2 (condicionada, con su caída explícita); composición
  de Monopoly Poker (pozo al centro), sin su arte. Ver
  conflicto C2.
- **D10. Barra superior fija en 56 px, tres zonas, DJ
  compacto, billetera de la modalidad en curso.** Qué:
  altura fija 56 px, sin crecer con DJ ni nombre largo;
  izquierda: Salir + engranaje de ajustes (D24), ambos
  ≥44 px y separados para no salir por error en turno;
  centro: píldora de pozo fijado (D9) + pastilla de turno
  con el nombre de quien juega (B9, crece dentro de su
  franja sin invadir la fila superior, sin tapar el aro
  del jugador en turno y sin desplazar la mesa ni un
  píxel); derecha: mi saldo + tier de la sala con su
  apuesta exacta (Barrio 100 / Salón 250 / Casino 500 /
  VIP 1.000 / High Roller 2.500) — saldo de la billetera
  de la modalidad en curso (local o en línea, sin
  mezclarlas). En línea, la barra de música (DJ) va
  compacta en esta barra, sin controles extra y sin tapar
  pozo ni pastilla de turno, nunca sobre la mesa. Los
  rivales NO van en la barra: son asientos (D1). Cada
  zona a una línea con elipsis. El micrófono queda fuera
  del engranaje: sigue solo sobre mi foto (regla 21).
  Verificable: captura con tier largo, nombre largo y DJ
  en línea, cero desborde y cero solape con los aros.
  Procedencia: hereda H10 (condicionada), B9 (aceptada),
  B8 (condicionada) y la regla 21 de docs/01.
- **D11. Turno sin señales nuevas: el aro ES el semáforo.**
  Qué: el turno se lee como hoy y con nada más: aro
  semáforo en el asiento (verde/amarillo/rojo según el
  tiempo restante) + pastilla de turno con nombre + barra
  fina de mi turno cuando soy yo + 3 pitidos solo en mi
  turno (a los 3, 2 y 1 s finales, sonido `beep.wav`
  880 Hz, respetando el interruptor de efectos). En su
  turno, el círculo entero del avatar —borde y brillo—
  toma el color semáforo (`seatRingColor`); fuera de
  turno conserva su color de identidad; el arco fino
  sigue mostrando la fracción con el mismo color. Sin
  verde fijo de póker, sin brillo extra fuera de turno,
  sin grosor extra que tape nombres o pipas, sin flechas,
  banners flotantes ni destacados nuevos sobre asientos,
  sin animación que degrade los 60 fps. Procedencia:
  hereda H11 (aceptada), O3 (aceptada), decisión 31
  (semáforo + pitidos) y decisión 32 (círculo entero) de
  docs/01; composición del aro brillante de Monopoly
  Poker, que convive con el semáforo sin reemplazarlo.

### Consola lateral y barra mínima

- **D12. Consola en columna lateral derecha, medida
  ≤334 px sin desplazamiento interno.** Qué: el `BidDock`
  se vuelve columna de ~300 px de ancho y alto de mesa:
  pintas en rejilla 2×3 (cada pinta ≥44 px), debajo el
  control de cantidad, la fila armada con atajos +1 y
  ▲ pinta (B11, sin mantener presionado), el chip de
  probabilidad de 44 px (B12, apagado en Kamikaze a
  ciegas), y abajo DUDO / CALZO / PASO + APOSTAR, en ese
  orden, sin cambiar contenido, validación ni reglas.
  La columna achica la mesa, no la tapa. Altura total
  medida de la columna ≤334 px, sin desplazamiento
  interno en turno; todos los textos ≥14 px: los nombres
  de pinta (hoy 9,5) y los textos de ayuda (hoy 12,5 /
  11,5 / 10,5) suben a 14; la ficha APUESTA ACTUAL /
  APUESTA MÍNIMA queda en una línea con elipsis; la fila
  armada conserva su lectura grande (hoy 21/18). Si la
  columna no cabe en ≤334 px sin scroll, H7 no se
  entrega tal cual y aplica D13 plegada (ver conflicto
  C8). El chip de probabilidad es solo informativo de la
  apuesta armada, calculado con la regla vigente
  (ases/comodines, dados en juego) a partir de mis dados
  + dados desconocidos contados, nunca con manos ocultas
  ajenas y nunca recomendando jugada; si el cálculo no
  está construido, no se muestra hasta Fase C.
  Procedencia: hereda H7 (condicionada), B11
  (condicionada: fuera el mantener presionado, veto de
  móvil por riesgo de sobreapuesta y long-press de iOS)
  y B12 (condicionada).
- **D13. Consola plegable + barra mínima abajo, sin
  perder la apuesta armada.** Qué: botón ≥44 px, separado
  de APOSTAR, pliega la columna: la mesa recupera todo el
  ancho y queda solo una barra mínima abajo al centro,
  ≤56 px, por encima del inset SafeArea inferior y
  separada de la zona de deslizamiento de inicio, con
  DUDO / CALZO / PASO / APOSTAR en ese orden, botones
  ≥44 px; la apuesta armada (cantidad + pinta) siempre
  visible junto a APOSTAR; plegar o desplegar nunca
  cancela, cobra ni modifica la apuesta armada;
  desplegar restaura la apuesta intacta en 1 toque sin
  bloquear toques; plegar/desplegar no pausa ni reinicia
  el temporizador ni el semáforo. Plegado nunca por
  defecto al iniciar mi turno (condición H9). La banda
  azul de desafío de Paso pendiente ("X dijo PASO") va
  encima de la columna cuando está desplegada, o en la
  barra mínima cuando está plegada, con DUDAR PASO /
  CALZAR PASO ≥44 px y texto ≥14 px (hoy 12 px y botones
  12 px). Verificable: captura con la barra plegada y 11
  rivales que demuestre que la barra no tapa mi fila, mi
  hueco ni mi avatar y no encoge el escenario por debajo
  de la lectura. Procedencia: hereda H9 (condicionada) y
  O4 (condicionada: prohibidos VER/igualar, ALL-IN, el
  PASAR de póker y cualquier botón nuevo). Ver conflicto
  C8 (H1 contra H9 sobre el plegado por defecto en mesa
  de 12).
- **D14. Sin botón VER en la consola ni en la barra.**
  Qué: no se crea ningún botón VER/igualar en Cacho. La
  traducción de la barra de acciones de Monopoly Poker es
  la barra (D13), no el botón: las acciones de Cacho son
  DUDO / CALZO / PASO / APOSTAR, sin inventar ninguna.
  El "VER tus dados" actual de la consola vertical (el
  peek, D8) no es el VER del póker y no se confunde con
  él: en horizontal el peek sigue siendo tocar el vaso.
  Procedencia: veto expreso de la sentencia horizontal
  (crear un VER sería un cambio de reglas; las reglas
  están cerradas) y lista G.3.

### Sala, fondo y orientación

- **D15. Sala PIL primero por tema, Blender solo
  comparando, zona calma obligatoria.** Qué: fondo
  estático por tema (nunca 3D en tiempo real, partículas
  ni video). Receta ganadora PIL, adaptada a horizontal,
  la misma que ganó para `bg_pub.png`: madera en
  perspectiva trapezoidal para marco y sala, paño con
  grano (`felt_bg.png`), bokeh cálido FUERA del paño,
  luz cenital elíptica sobre el centro, viñeta profunda.
  Por tema: El Pub mantiene su foto de bar; Casino Dorado
  (por defecto, D1 de docs/05) sigue esa receta con
  madera de bar, cuero, burdeos y dorado envejecido;
  Neón Nocturno: fondo casi negro, marco cian solo
  dentro del rectángulo-mesa, resto en Cuero y Paño. En
  la misma entrega se compara por captura con UNA
  variante Blender en perspectiva del mismo Dorado
  (cámara en ángulo, lámparas cálidas desenfocadas,
  fondo oscuro, 128 samples + denoise, Cycles por CPU);
  si el render no supera al compuesto en legibilidad,
  zona calma y prueba de parecido, no entra; si ninguna
  variante pasa la zona calma, el prototipo sale con
  paño oscuro plano. Zona calma obligatoria: bajo dados,
  avatares, nombres, pipas y aros no va bokeh, ni
  detalle, ni brillo; la sala vive FUERA del paño, no
  debajo del juego; contraste ≥4,5:1 en cada asiento con
  el fondo elegido. Prueba de parecido: si una captura
  del prototipo podría confundirse con 8 Ball Pool (marco
  ornamentado plateado, azul noche, dorado brillante de
  moneda, utilería de pool, troneras), se descarta ese
  fondo aunque se vea bien. Modo ligero intacto: bajo
  60 fps o con efectos reducidos, se apaga el brillo y
  queda paño oscuro + acento mínimo, automático y real.
  Procedencia: hereda H12, H14, H15, H20 y H22
  (aceptadas), H13 (condicionada), B22 (aceptada) y
  docs/08 tensión 3 (la sala Dorado sigue la receta PIL
  que ganó, no inventa un estilo nuevo).
- **D16. Solo la mesa en horizontal; menús en vertical;
  giro sin perder estado.** Qué: inicio, lobby, hojas de
  creación, perfil, Personalizar, tienda, Cómo se juega
  y DJ quedan en vertical como hoy. Solo la pantalla de
  partida cambia de layout. Al entrar a la mesa con el
  teléfono en vertical, un aviso PREVIO a la mesa (fuera
  de la partida, no es texto narrativo en juego): "Gira
  el teléfono para jugar en horizontal", con icono propio
  de girar y botón "Jugar igual en vertical" ≥44 px y
  texto ≥14 px, que lleva al layout actual; nunca en
  plena partida ni bloqueando el acceso a la mesa; sin
  forzar rotación por código ni pedir pantalla completa;
  detección por tamaño sin fullscreen, sin permiso y sin
  bloqueo de orientación; elección recordada en la
  sesión; sin insistir si el bloqueo de orientación está
  activo. Al girar, solo cambia el layout: mismo
  controlador y mismo estado, asientos reanimados con
  `AnimatedAlign` 260 ms como hoy, sin reiniciar ronda,
  sin reenviar nada al servidor, sin tocar el
  temporizador de 60 s. Condición H18 (la más exigente):
  giro probado en mi turno en los últimos 15 s, con el
  semáforo en rojo y la apuesta armada, sin reiniciar
  `turnEndsAt` ni las marcas de pitidos, sin salto de
  aro, sin perder la apuesta armada, sin bloquear toques
  durante la animación de 260 ms, sin alterar la cuenta
  de abandono, la de desconexión ni el estado Kamikaze a
  ciegas; si algo de eso falla, el giro en mi turno se
  difiere a fin de turno (ver §8, riesgo 6).
  Procedencia: hereda H16 (aceptada), H17 (aceptada:
  vertical intacto como fallback, incluido hueco 104 y
  `left = 98 − L`, verificado con la misma suite de
  capturas y sin parpadeo cuando Safari muestra u oculta
  sus barras; el vertical se CONGELA, no se mejora en
  paralelo) y H18 (condicionada).
- **D17. Revelación, victoria y anuncio de ronda sin
  cambios de contenido, con textos a ≥14 px.** Qué: la
  revelación sigue en 3 pasos con conteo lento fijo
  (170 ms/dado), título corto, una línea de contexto,
  número grande y veredicto como solo consecuencia, y se
  cierra sola 3 s después del veredicto (Seguir salta
  antes); velo al 92% para que la mesa no se cuele. La
  pantalla de victoria muestra lluvia de monedas Blender
  propia + pozo contado + una fila de datos REALES de la
  partida (dados quitados, faroles/Dudos ganados, calzos
  acertados); lo no guardado aún no se muestra hasta
  Fase C. Fanfarria por tier (B21): Barrio tintineo
  simple, Casino fanfarria actual, High Roller fanfarria
  larga + lluvia mayor, solo con efectos activados y sin
  bloquear ni retrasar Salir/OTRA VEZ; con efectos
  reducidos, sonido corto y sin lluvia extra; no cambia
  pozo ni añade monedas. Cada ronda anuncia quién parte
  y por qué ("Ronda N: parte X — perdió un dado / calzó
  justo / salió en el sorteo / activó el Kamikaze") en la
  franja de turno, sin fila nueva, texto ≥14 px (hoy el
  subtítulo de victoria y textos de contexto están en
  11,5–13,5 px y suben). Procedencia: hereda B14 y B21
  (aceptadas), docs/02 (revelación precisa, corrección
  del usuario) y la regla de anuncio de ronda de docs/02.

## 2. Lobby

- **D18. Tarjeta de sala por tier: POZO, fórmula y
  miniatura propia, nunca PREMIO ni ×N aislado.** Qué:
  cada tarjeta de sala muestra: nombre del tier junto a
  su apuesta exacta, miniatura propia de su mesa (render
  o compuesto propio, nunca arte ajeno; la miniatura
  Neón muestra el neón solo dentro del recuadro-mesa),
  entrada (apuesta real) y pozo. Rótulo literal POZO,
  nunca PREMIO. Fórmula visible "pozo = apuesta × N
  jugadores" con la palabra jugadores siempre junto a
  ×N; prohibido "×N" aislado (un "×N" mal leído parece
  bonificación). Pozo de lobby solo en sala existente y
  rotulado provisional ("pozo si se parte ahora, se fija
  al partir"); en creación, solo la fórmula, sin pozo si
  no hay jugadores. Entrada visible en el botón; botón
  Entrar/JUGAR ≥44 px; texto ≥14 px, contraste ≥4,5:1;
  sin pila de monedas ni cofre; emblema puramente
  decorativo, sin corona de liga ni connotación de nivel
  o desbloqueo; estilo Cuero y Paño con dorado mate.
  El texto de la tarjeta usa la apuesta exacta de la
  tabla cerrada y la billetera de la modalidad (sin
  mezclar local y en línea). Procedencia: hereda P1
  (condicionada, unánime), P3 (aceptada con resguardos),
  O5 (condicionada, refina P1), B5 (aceptada: pozo vivo =
  apuesta × jugadores actuales, no el "premio = el doble"
  de 8BP) y docs/08 tensión 2 (P1/P3 y B5/B6 se consolidan
  en UNA presentación de tarjetas). Ver conflicto C4.
- **D19. Filtro por tier como chips de selección, no como
  navegador de salas.** Qué: chips en una sola fila con
  desplazamiento horizontal, ≥44 px de alto, texto ≥14 px,
  neutros (fondo oscuro, texto marfil, activo dorado
  envejecido, sin colorear cada chip con su sala):
  Todos / Barrio / Salón / Casino / VIP / High Roller.
  Superficie: el filtro vive en el selector de tier de
  creación (§3) y, si una vista de salas propias llega a
  existir, en ella; NO se inventa un navegador público de
  salas ajenas para darle superficie (no existe, y la
  entrada a salas en línea sigue siendo por código o por
  sala activa, D22). Ver conflicto C3: B6 presupone una
  lista; esta propuesta conserva el contenido del filtro
  y cambia solo su superficie, y el tribunal confirma
  si eso basta o si B6 queda en espera. Procedencia:
  hereda B6 (aceptada con resguardos) y la cerca "sin
  inventar navegador público de salas".
- **D20. El lobby de la sala conserva todo lo que ya
  funciona, con textos a ≥14 px.** Qué: en el lobby se
  mantiene: apuesta y pozo de la sala elegida por el
  anfitrión, lista de jugadores con asientos, relleno con
  bots (contador visible), botón de lápiz junto a mi fila
  para cambiar mi nombre (solo en lobby; en partida el
  servidor responde `en_partida`, y el nombre nuevo
  también queda guardado como nombre de perfil),
  bloqueo por saldo insuficiente sin cobrar, y aviso de
  desconexión en partida con cuenta de 60 s visible en
  el asiento ("⏳ m:ss para volver") + eliminación si no
  vuelve (el bot cubre sus turnos mientras tanto; volver
  a tiempo la cancela y se avisa a toda la mesa). Los
  botones del lobby (hoy `minHeight` 34 px) suben a
  ≥44 px; las líneas de apuesta/pozo (hoy 12,5 px) suben
  a ≥14 px. El micrófono sigue solo sobre la foto de
  perfil (regla 21), nunca en la hoja de ajustes.
  Procedencia: hereda decisiones 27, 28 y 29 de docs/01,
  B5 (aceptada) y la regla 21 de docs/01.
- **D21. Sala activa: aviso dorado en el inicio, sin
  cambios de flujo.** Qué: al abrir el inicio, si hay
  código guardado y el servidor lo valida (existe, fase,
  asiento propio por token de billetera), el inicio
  muestra el aviso dorado "Entrar a la sala activa": con
  partida en curso y asiento propio entra DIRECTO a la
  mesa recuperando el asiento (`rejoin` solo si el
  asiento está desconectado; un asiento conectado no se
  puede robar); si la sala está en lobby entra al lobby.
  El aviso se borra solo con `game_over`, sala muerta o
  la ✕; salir de la partida NO lo borra. Sin cambios de
  diseño: el aviso conserva su color dorado y su
  posición en el inicio, y no se convierte en tarjeta de
  sala ni en lista. Procedencia: hereda la decisión 25 de
  docs/01 tal cual.

## 3. Creación de sala

- **D22. Creación local: una hoja, mesa + tier + bots +
  dificultad + guiada, con la fórmula del pozo.** Qué:
  la hoja de partida local (vertical, como hoy) reúne en
  este orden: selector de mesa con 3 miniaturas
  elegibles (El Pub, Casino Dorado por defecto, Neón
  Nocturno; cada opción ≥44 px; la miniatura Neón con
  neón solo dentro del recuadro), selector de apuesta
  con nombre de tier (Barrio 100 / Salón 250 / Casino
  500 / VIP 1.000 / High Roller 2.500, montos sin
  cambiar; defecto 500; opción sin apuesta = guiada
  gratis), contador de bots 1–11 con dificultad, y la
  fórmula del pozo en vivo "Pozo: apuesta × (bots + 1)
  jugadores · tu saldo: X" con números reales de la
  billetera local (si el saldo no alcanza la apuesta
  elegida, la hoja baja a la apuesta que sí alcanza o
  muestra el bloqueo, como hoy; nunca promete un pozo
  que no se pueda pagar). La partida guiada (2 bots
  lentos que explican jugando, sin repetirse) se ofrece
  como opción propia de la hoja, no como sala ni como
  tier. Al partir, la mesa, los bots, la dificultad, la
  apuesta y el tema quedan fijados para la revancha
  (D25). Procedencia: hereda B7 (aceptada), D1 de
  docs/05 (Casino Dorado por defecto), la decisión 33 de
  docs/01 (selector en hoja local) y el comportamiento
  actual de la hoja local (bots 1–11, apuesta, saldo).
- **D23. Creación en línea: misma hoja, tema que viaja,
  código y saldo verificado antes de cobrar.** Qué: la
  hoja de creación en línea (vertical) reúne: selector
  de mesa (igual que D22), apuesta con nombre de tier
  (igual que D22), relleno con bots ("la sala puede
  rellenarse con bots"), y creación con código de sala
  (4–6) para compartir; la mesa viaja con la sala (campo
  `theme`; valor inválido cae a dorado) y todos ven la
  misma. El lobby muestra la mesa de la sala con su
  miniatura. El servidor verifica y cobra al partir
  (`saldo_insuficiente` bloquea el inicio sin cobrar);
  salir a mitad = perder la apuesta. Sin navegador
  público: no hay lista de salas ajenas, ni tarjetas de
  salas que no sean la propia o la activa (D21), ni
  contadores de salas, jugadores en línea ni
  espectadores inventados. Procedencia: hereda B7
  (aceptada), la decisión 33 de docs/01 (tema que viaja,
  `potFixed` en servidor al partir) y la decisión 20 de
  docs/01 (billetera en línea por `walletToken`).
- **D24. Inicio sin scroll: tres tarjetas, saldo y
  rescate como tira, nada nuevo que empuje.** Qué: el
  inicio conserva su estructura actual sin scroll (logo,
  3 tarjetas, sin densificar como el home de Parchisi):
  botón primario unificado con degradado solo entre
  tonos mates de `#C9A24B`, 56 px mínimo, etiqueta +
  icono, sin cambiar orden ni texto (B3). Barra superior
  con saldo + racha (B1): la llama de racha solo en
  dorado envejecido `#C9A24B`, sin naranja ni rojo, y
  solo cuando exista registro real de racha (Fase C);
  si el dato aún no se guarda, el campo se omite, no se
  estima ni se pone un cero inventado. "Rescate del día"
  (B2) como tira fina visible dentro del inicio actual
  cuando el saldo no alcanza la mínima, con botón
  "Rescatar" (+1.000/día, local); si ni la tira cabe, el
  rescate queda donde está hoy (tarjeta de apuesta).
  No se añaden tarjetas al inicio sin scroll (condición
  P1). Procedencia: hereda B1, B2 y B3 (aceptadas con
  resguardos), la decisión 20 de docs/01 (rescate) y el
  mandato de inicio sin scroll del master prompt.

## 4. Hoja de ajustes en partida

- **D25. Engranaje único en partida: solo historial,
  glosario y sonido.** Qué: en la barra superior (D10),
  el engranaje abre una hoja con exactamente tres
  entradas, en este orden: Historial (la hoja de
  historial agrupado por ronda, como hoy), Glosario
  (pintas As/Pato/Tren/Cuadra/Quinta/Sexta y reglas
  resumidas, como hoy) y Sonido (interruptores de música
  y de efectos, como hoy; volumen DJ 0–50, defecto 15,
  decisión 26). Nada más: sin micrófono (sigue solo sobre
  mi foto, regla 21), sin reglas como entrada separada
  del glosario, sin personalización ni tienda en plena
  partida, sin reacciones ni emojis. Cada entrada ≥44 px
  de alto, texto ≥14 px. La hoja no pausa ni reinicia el
  temporizador ni el semáforo; si al probar la hoja
  estorba en turno (la disidencia de móvil de B13: un
  toque pasa a dos más hoja en plena cuenta de 60 s), se
  deshace sin tocar nada más (condición de la sentencia).
  Procedencia: hereda B13 (condicionada: micrófono fuera,
  choque separable quitado) y la decisión 33 de docs/01
  (ajustes bajo un solo engranaje). Ver conflicto C7.

## 5. Revancha

- **D26. "OTRA VEZ" solo en local, en un toque, misma
  mesa, mismos bots, misma dificultad, misma apuesta y
  mismo tema.** Qué: en la pantalla de victoria de una
  partida local, junto a Salir, botón dorado "OTRA VEZ"
  (≥44 px, texto ≥14 px) que rearma la misma sala en un
  toque: misma mesa, mismos bots, misma dificultad,
  misma apuesta y mismo tema; sin pantalla extra, sin
  volver al inicio, sin re-elegir nada. La revancha en
  línea NO se diseña en el diseño final: queda en espera
  de la condición B4 (solo si TODOS aceptan
  explícitamente ANTES de cobrar, con reverificación de
  saldo de todos y bloqueo por saldo insuficiente; sin
  aceptación total no se rearma ni se cobra a nadie; si
  aceptar añade espera o pantalla extra, la revancha en
  línea queda fuera). En la pantalla de victoria local,
  el saldo mostrado es el de la billetera local y el
  pozo es el fijado al partir (D9). Procedencia: hereda
  B4 (condicionada: mitad local) y la decisión 33 de
  docs/01 (revancha solo local).

## 6. Presentación de la tienda futura (Fase B, sin construirla)

La tienda NO se construye en el diseño final: solo se
PRESENTA dentro de Personalizar, para que la Fase B la
construya sin rediseñar. Nada de precios nuevos: solo las
bandas ya aprobadas (D2 de docs/05).

- **D27. Personalizar reúne cuatro secciones, en este
  orden: Vasos, Dados, Marcos, Celebraciones.** Qué: la
  tienda vive dentro de Personalizar en el inicio (no
  como pantalla nueva confusa), en vertical, como
  cuadrícula de tarjetas por sección. Cada tarjeta:
  render propio del objeto (vaso Blender / dado / marco
  / celebración), nombre, precio en monedas dentro de
  la banda aprobada, y estado ("Equipado" dorado /
  "Comprar"). Tocar = vista previa en vivo (D28). Sin
  packs, sin azar, sin moneda premium, sin dinero real,
  sin SALE, sin gemas, sin cofres, sin bundles, sin BUY
  ALL: compra directa con precio visible, una por una.
  Si el saldo no alcanza, la tienda lo dice y no vende
  (igual que `saldo_insuficiente` al crear sala). La
  compra queda guardada en el dispositivo (local) y en
  el token de billetera (en línea), como los saldos, y
  la tarjeta indica siempre qué billetera se está usando
  (local o en línea, sin mezclarlas). Procedencia:
  hereda B16 (aceptada con resguardo de bandas D2),
  docs/05 §Tienda (Fase B dentro de Personalizar) y las
  listas de rechazo H19/F.5/G.3.
- **D28. Vista previa en vivo sin equipar sin pagar.**
  Qué: al tocar un vaso o unos dados en la tienda, mi
  asiento de la mesa de fondo (o un vaso de muestra)
  cambia al instante, antes de comprar; sin pantalla
  nueva ni compra a ciegas; no se equipa sin pagar. La
  vista previa muestra el objeto en su contexto real:
  el vaso, sobre el paño, delante del avatar, con el
  aro de identidad (no el semáforo, que solo existe en
  turno); los dados, con su símbolo de pinta visible.
  Procedencia: hereda B17 (aceptada).
- **D29. Los vasos comprados se ven en la mesa bajo la
  regla CU3, sin excepciones.** Qué: un vaso de tienda
  (dorado casino, neón nocturno u otro futuro dentro de
  las bandas) solo entra en partida si cumple D5
  intacta: color elegido congelado toda la partida,
  nunca indicador de turno, peligro, eliminación ni
  resultado, nunca tiñe el aro, semáforo autoritativo, y
  pasa la puerta CU4 (§7, D31) con captura de 11 rivales
  junto a cada color. Un vaso de tienda que se confunda
  con verde, amarillo o rojo no entra en partida aunque
  ya se haya vendido su vista previa: la venta no
  promete visibilidad en partida que CU4 no haya
  pasado. Procedencia: hereda CU3 (condicionada: "los
  vasos de tienda de Fase B entran solo bajo esta misma
  regla") y D2 de docs/05.
- **D30. Dados y marcos de tienda: símbolo antes que
  color, aro intacto.** Qué: los dados de tienda
  (esmeralda casino, neón, y los 4 actuales: marfil base,
  rojo translúcido, negro con puntos dorados, hueso
  antiguo) mantienen la regla de accesibilidad de
  docs/02: cada pinta se distingue por forma/símbolo, no
  solo por color; el 1 sigue con su punto rojo (comodín
  visible). Los marcos de avatar de tienda (variantes
  burdeos, neón, y el dorado actual) son solo el marco
  del asiento fuera de turno: en turno, el círculo entero
  toma el semáforo (D11) y ningún marco lo tiñe ni lo
  tapa. Las celebraciones de tienda (destellos dorados
  intensos, chispas neón, y la lluvia de monedas actual)
  solo se ven en la pantalla de victoria (D17), nunca
  como animación sobre la mesa en turno ni como
  flotante sobre asientos (B20 rechazada, no resucita).
  Bandas: vasos 500–1500, dados 300–1000, marcos
  200–500, celebraciones 500 (D2 de docs/05, aprobadas;
  ningún precio puntual nuevo se fija aquí).
  Procedencia: hereda B16 (aceptada), docs/02
  (accesibilidad de pintas), docs/05 §Tienda y B20
  (rechazada).

## 7. Puerta bloqueante y relación con el prototipo

- **D31. Puerta CU4 antes de entregar cualquier vaso
  visible (bloqueante, no informativa).** Qué: antes de
  entregar D3, D4, D5 y D29, captura obligatoria con 11
  rivales, consola abierta y cerrada, en mi turno y en
  turno ajeno, y Kamikaze a ciegas con vasos rivales
  cerrados e idénticos. Un solo solape o una sola
  diferencia de animación tumba D3 y D4; cualquier fuga
  (dados, cantidad o delación por animación) bloquea
  todo CU; nunca se achican textos ni pipas para que un
  vaso quepa: se reduce o se reubica el vaso antes de
  entrar. Procedencia: hereda CU4 (aceptada, bloqueante)
  tal cual.
- **D32. Capturas obligatorias del diseño final (las del
  prototipo, más las extensiones).** Qué: horizontal
  844 × 390 y además Safari de iPhone real (no solo
  simulador); 2, 5 y 11 rivales; consola abierta y
  cerrada; mi turno con semáforo; peek con consola
  abierta y cerrada; Kamikaze a ciegas; asiento con
  cuenta de desconexión; nombres largos; tier largo con
  DJ en línea; giro en mi turno en rojo con apuesta
  armada; turno pasando de asiento en asiento alrededor
  del óvalo; puerta CU4 (D31); tarjeta de tier por cada
  uno de los 5 tiers; hoja de creación local y en línea;
  hoja de ajustes; pantalla de victoria local con OTRA
  VEZ; vista previa de tienda por sección (sin comprar).
  Todo rotulado como partida local con bots donde sea
  local, mostrando solo el saldo de la billetera local y
  sin prometer nada en línea que aún no esté verificado.
  Procedencia: hereda el punto 13 del alcance del
  prototipo y la condición H21 (prototipo local Dorado,
  sin desplegar, sin APK).

### Relación con el prototipo (13 puntos): confirma, ajusta, extiende

| Punto del prototipo | Diseño final |
|---|---|
| 1. Óvalo (H1+O1) | CONFIRMA (D1), con la caída a rectángulo si apiña |
| 2. Yo al centro + hueco 104 + sin asiento sobre el vaso | CONFIRMA (D7) |
| 3. Escenario 0,6 + peek + Kamikaze | CONFIRMA (D6, D8) |
| 4. Consola lateral plegable + barra abajo | CONFIRMA (D12, D13), con el conflicto C8 señalado |
| 5. Barra superior + pozo en el paño solo si cabe | CONFIRMA (D9, D10), con el conflicto C2 señalado |
| 6. Turno sin señales + aro = semáforo | CONFIRMA (D11) |
| 7. Sala PIL + Blender comparando + zona calma + pub chileno | CONFIRMA (D15) |
| 8. Vasos visibles bajo CU4 | CONFIRMA (D3, D4, D5, D31) |
| 9. Orientación | CONFIRMA (D16) |
| 10. Fondo estático + modo ligero | CONFIRMA (D15) |
| 11. Tarjetas de tier | CONFIRMA (D18), EXTENDIDA a lobby y creación (D19, D22, D23) |
| 12. Piso de texto | CONFIRMA y APLICA a todas las superficies (D2, D9, D12, D13, D18, D20, D25, D26) |
| 13. Capturas obligatorias | CONFIRMA y EXTENDIDA (D32) |
| — (fuera del prototipo) | EXTENSIONES NUEVAS: lobby completo (D19–D21), creación (D22–D24), ajustes (D25), revancha (D26), tienda presentada (D27–D30) |

## 8. Conflictos señalados (no resueltos por este brainstorm)

El brainstorm NO resuelve los conflictos entre herencias: los
señala con sus dos fuentes para que el tribunal (o el usuario,
donde sea su palabra) decida. Nada de lo listado aquí se da
por cerrado en las propuestas de arriba: donde una propuesta
necesita una de las dos variantes, lo dice y remite aquí.

- **C1. Piso de texto 14 px contra textos actuales.**
  Fuentes: sentencia horizontal punto 12 y docs/08 tensión 1
  (piso 14) contra `game_screen.dart` / `dice_and_cup.dart` /
  `panels.dart` actuales (nombre 13, estado 12, EN TURNO 10,
  burbuja 11,5, PASO 9, pozo 12,5, ayuda de consola 12,5 /
  11,5 / 10,5, subtítulos de acción 10,5). Estado: la
  sentencia ya decidió que se sube y no se hereda; el
  conflicto real que queda es de MEDIDA, no de criterio:
  subir los nombres de pinta (9,5) y los subtítulos dentro
  de la columna ≤334 px (D12) puede no caber, y la
  sentencia no dice qué se recorta primero. El tribunal
  debe pesar ese orden de recorte (ver §9, riesgo 5).
- **C2. Pozo en la barra contra pozo en el paño.**
  Fuentes: B8/H10 (pozo en la franja/barra superior, con
  franja propia reservada) contra O2 (pozo y apuesta
  vigente en el borde superior del paño). Estado: la
  sentencia condiciona O2 a que quepa sin mover nada y
  ordena su caída a la barra si no cabe; este brainstorm
  mantiene la barra como canónica y el paño como añadido
  condicional (D9), sin resolver por su cuenta cuál de
  las dos ubicaciones ve el jugador cuando ambas caben
  (¿duplicado barra + paño, o solo una?). El tribunal
  decide si el pozo duplicado ayuda o confunde.
- **C3. Filtro por tier (B6) contra "sin navegador público
  de salas".** Fuentes: B6 aceptada ("chips arriba del
  lobby/lista") contra la cerca de este encargo (no
  inventar un navegador público de salas, que no existe).
  Estado: D19 conserva el filtro como selector de tier en
  creación, no como navegador; si el tribunal entiende
  que B6 exige una lista para tener sentido, B6 queda en
  espera hasta que exista una superficie real, y no se
  inventa ninguna.
- **C4. Nombres de tier largos contra cortos.**
  Fuentes: docs/05 ("Mesa de Barrio", "El Salón",
  "Casino", "VIP", "High Roller") contra `stakeTierName`
  en código y la decisión 33 de docs/01 ("Barrio", "Salón",
  "Casino", "VIP", "High Roller"). Estado: las propuestas
  usan la forma corta ya construida (D10, D18, D22) y
  señalan la variante larga; el tribunal confirma qué
  etiqueta va en cada superficie (tarjeta, barra, hoja)
  o si la larga es solo nombre de sala y la corta solo
  etiqueta. No se unifica por cuenta propia.
- **C5. Placa dorada de la apuesta: altura pendiente de la
  palabra del usuario.** Fuentes: decisión 30 de docs/01
  y docs/05 ("pendiente de su palabra: bajar la placa
  dorada 38→26–28") contra el diseño final, donde la
  placa central no reaparece (el centro lo ocupa mi vaso,
  D9). Estado: no se fija ninguna altura nueva aquí; si
  la placa reaparece en alguna variante (por ejemplo,
  como parte de O2), su altura queda pendiente de esa
  palabra y no se decide en este documento.
- **C6. Vaso burdeos contra semáforo rojo.**
  Fuentes: CU3 (los 4 cueros de docs/02, incluido el
  burdeos `#5E2129`) contra CU3 misma condición ("el color
  que se confunda con verde, amarillo o rojo no entra en
  partida") y D11 (el semáforo es autoritativo). Estado:
  el burdeos es familia del rojo casino `#B3202A`; este
  brainstorm no recolorea ningún vaso por su cuenta. La
  captura de D5/D31 debe demostrar que el semáforo se
  lee sin ambigüedad junto al burdeos; si no lo
  demuestra, el tribunal decide (y no este documento) si
  el burdeos queda fuera de partida o con qué resguardo
  entra.
- **C7. Engranaje único (B13) contra la disidencia de
  móvil.** Fuentes: B13 aceptada condicionada por mayoría
  (4/5: agrupar historial, glosario y sonido bajo un
  engranaje) contra la disidencia anotada en la propia
  sentencia (el juez de móvil rechazaba agrupar del todo:
  un toque pasa a dos más hoja en plena cuenta de 60 s).
  Estado: D25 mantiene la hoja con su condición de
  reversión sin tocar nada más; si la prueba en turno la
  muestra estorbando, se deshace y no se discute de nuevo
  el contenido de la hoja.
- **C8. Plegado por defecto en mesa de 12 (H1) contra
  "plegado nunca por defecto al iniciar mi turno" (H9).**
  Fuentes: condición H1 ("captura con 11 rivales y consola
  abierta que demuestre cero solape, o H9 plegada por
  defecto en mesa de 12") contra condición H9 ("plegado
  nunca por defecto al iniciar mi turno"). Estado:
  conflicto explícito entre dos condiciones de la misma
  sentencia. Este brainstorm propone ambas reglas tal
  cual (D12, D13) y NO establece precedencia: si la
  captura con 11 rivales muestra solape con la columna
  abierta, el tribunal debe decidir cuál de las dos
  condiciones cede (o si la columna adelgaza por debajo
  de ~300 px para que ambas se cumplan). La medición con
  11 rivales es el árbitro, no este documento.

## 9. Riesgos que el tribunal debe pesar

1. **Medidas reales contra supuestas.** 844 × 390, mesa
   544 × 334 y ~109 px por asiento superior son geometría
   de docs/07, no medidas de un iPhone real. SafeArea,
   notch, indicador de inicio y las barras de Safari que
   aparecen y desaparecen recortan el rectángulo útil por
   debajo de 544 × 334, y los textos actuales (13/12/10 px)
   ya están bajo el mínimo de 14 px. Sin medición en
   iPhone real, el simulador miente (riesgo 1 de la
   sentencia horizontal).
2. **SafeArea y notch en horizontal.** En horizontal el
   notch come un costado y el indicador de inicio come el
   borde inferior: mi asiento (D7), la barra mínima abajo
   (D13) y los asientos laterales (D1) son los primeros
   en quedar bajo una zona no táctil o recortada. Todas
   las medidas de mesa se calculan tras SafeArea (H20);
   ninguna captura en simulador basta.
3. **11 vasos + 11 aros + pozo + barra compitiendo en
   334 px de alto.** Con 5 asientos arriba, cada uno tiene
   ~109 px de ancho para nombre + avatar 56 + vaso ~84 +
   pipas + aro, y el centro debe seguir limpio para mi
   vaso 168 × 196 a escala 0,6. El primer solape será la
   pita del rival central o el aro del asiento superior
   (riesgo 2 de la sentencia horizontal). La puerta CU4
   (D31) es la que decide si los vasos entran, no el
   gusto por verlos.
4. **Giro en rojo con apuesta armada.** Rotar en mi turno,
   en los últimos 15 s, con el semáforo en rojo y la
   apuesta armada, puede recrear el layout, saltar el aro
   o los pitidos, o dejar un botón bajo una zona no
   táctil. H18 exige esa prueba exacta; si algo falla, el
   giro en mi turno se difiere a fin de turno (D16). Sin
   esa prueba, H18 es promesa y no garantía.
5. **Subir todos los textos puede romper la columna
   ≤334 px.** Los nombres de pinta (9,5 → 14), los
   subtítulos de acción (10,5 → 14) y las líneas de ayuda
   (12,5/11,5 → 14) crecen dentro de la misma columna que
   debe medir ≤334 px sin scroll (D12). Si no cabe, la
   sentencia no dice qué se recorta primero (ver C1): la
   columna, la ficha de mínimo, los subtítulos o el
   plegado por defecto (ver C8). El tribunal debe pesar
   ese orden antes de construir, no después.
6. **Pozo confundido: fijado contra vivo, provisional
   contra garantizado, ×N como bonificación.** Un pozo
   mal rotulado es una promesa falsa con monedas del
   jugador en juego (riesgo 3 de la sentencia
   horizontal). Por eso D9, D18 y D22 repiten el rótulo
   exacto ("Pozo fijado al partir", "pozo si se parte
   ahora, se fija al partir", "pozo = apuesta × N
   jugadores") en cada superficie, y por eso el
   duplicado barra + paño (C2) necesita decisión
   explícita.
7. **Fuga por vasos y color como estado.** Cualquier
   diferencia mínima entre vasos (duración, sonido,
   movimiento, color) es una señal legible sobre manos
   ocultas en un juego de farol; un vaso burdeos junto a
   un aro rojo puede leerse como turno aunque el color
   sea cosmético (riesgos 4 y 5 de la sentencia
   horizontal). CU4 es bloqueante por esto, no
   informativa; la venta de un vaso de tienda (D29) no
   promete visibilidad que CU4 no haya pasado.
8. **Dos mesas vivas.** El vertical queda como fallback
   congelado (H17), no como juego paralelo: construir el
   vertical mejorado en paralelo sería mantener dos mesas
   y duplicar la superficie de prueba y el riesgo de
   divergencia de reglas (consola, semáforo, apuesta
   armada, Kamikaze a ciegas). El comparativo fue un
   puente a la decisión del usuario, no un estado final.
9. **Falsa promesa local.** El prototipo y las capturas
   son partida local con bots hasta verificación en línea
   (turno de 60 s, desconexión con 60 s y rejoin, Kamikaze
   a ciegas, pozo fijado, sin cambios de servidor).
   Mostrarlo como en línea, o mezclar las billeteras
   local y en línea, es la falta más grave de todas
   (riesgo 10 de la sentencia horizontal); por eso D10,
   D18, D22, D23 y D32 nombran la billetera en cada
   superficie.
10. **Deriva de estilo.** Dorado brillante de moneda, mesa
    roja de póker, marco ornamentado, silueta de Parchisi
    (panel + esquinas), corona de liga repintada:
    recolorear no basta; la prueba de parecido se hace
    en captura conjunta (H12, H22, D15). Si el resultado
    se parece a otro juego en estilo, se descarta aunque
    se vea bien.

## 10. Cercas (inquebrantables, verificadas contra cada propuesta)

- Reglas cerradas y economía intactas (docs/01, decisiones
  1–33): subida clásica, ases mitad/doble+1 con interruptor,
  presets, pintas, calzo siempre, calzo perfecto, abandono a
  los 3 turnos, Kamikaze a ciegas, salas de 12, desconexión
  60 s, sala activa con rejoin, renombre solo en lobby,
  semáforo + 3 pitidos, círculo con semáforo, DJ volumen 15,
  turno máx 60 s, NO partir con ases, sorteo visible, vaso
  boca abajo; nacer con 5.000, apuestas 100/250/500/1.000/
  2.500, pozo = apuesta × jugadores sin comisión, empate
  devuelve, salir a mitad = perderla, rescate +1.000/día.
- Listas de rechazo H19/F.5/G.3 vigentes y ratificadas:
  arte/logo/sonidos ajenos, espejo 1v1, niveles/XP/rating,
  monedas premium, dinero real, cajas/packs de azar, salas
  bloqueadas por nivel, reglas especiales por sala, puntería,
  tarjetas de ciudad, chat en partida, reacciones (B20, no
  resucita ni por la barra ni por la consola ni por el DJ),
  multi-moneda, SALE, gemas, cofres de azar, bundles, BUY
  ALL, ciegas como sistema, ALL-IN, VER/igualar, PASAR de
  póker, modos 1 ON 1 / TEAM UP, navegación inferior
  Shop/Friends/Events/Clubs, tablero de parchís.
- Sin botón VER (D14); sin chat, reacciones ni emojis en
  partida (B20); sin textos narrativos en partida (el aviso
  de girar es previo a la mesa, D16, no texto en juego).
- Textos de mesa ≥14 px, targets ≥44 px, contraste ≥4,5:1.
- Vasos solo bajo la puerta bloqueante CU4 (D31): cualquier
  solape o diferencia de animación los tumba.
- Solo web, nunca APK; sin desplegar en esta ronda.
- Cero números falsos: todo número mostrado es real
  (saldo, apuesta, pozo, jugadores, racha y victorias solo
  cuando exista registro real; lo no guardado se omite).
- La sala va FUERA del paño, el paño queda limpio y oscuro
  (D15); el neón vive solo dentro del rectángulo-mesa; el
  dorado, solo en tonos mates de `#C9A24B`.
- Fallback vertical CONGELADO: no se mejora en paralelo
  (H17, V1–V5 documentados, no construidos).
