# Brainstorm mesa horizontal — Cacho pasa la mesa a horizontal

Fecha: 2026-10-24. Estado: BRAINSTORM (nada de esto está construido;
va a tribunal antes de implementarse).
Base: sentencia v2.0 (`audit/tribunal/sentencia_v2_frontend.md`,
propuestas B1–B22 ya juzgadas), propuesta v2.0
(`05-propuesta-v2-casino.md`, decisiones D1–D6), decisión 33 en
`docs/01-arquitectura-y-decisiones.md` (Fase A construida en local,
sin desplegar), y las capturas de 8 Ball Pool que mostró el usuario
el 24-oct: COMPOSICIÓN como referencia solamente (barra superior,
mesa grande con marco, sala oscura alrededor). No se usó ni se
copió ningún asset, logo, sonido ni imagen de Miniclip.
Antecedente: la prueba de fondo Dorado vertical queda PAUSADA; en
horizontal la sala se compone distinto (sala ancha alrededor de
una mesa con marco), así que ese trabajo se rehace en horizontal
si el tribunal lo aprueba, no se rescata el vertical.
Aclaración del usuario (24-oct, principio rector): Cacho debe
tener su PROPIO estilo. Las capturas de 8 Ball Pool son solo
EJEMPLOS de composición (mesa ancha, barra superior, sala
alrededor), no un modelo visual a seguir. La identidad del
prototipo horizontal nace del mundo propio de Cacho (Cuero y
Paño, casino dorado, carácter chileno de pub), no de parecerse
a 8 Ball Pool. Toda propuesta que huela a imitación de 8BP en
estilo va marcada para rechazar o reformular con estilo propio
(ver principio B7, H12 reformulado, H19 y H22).

## A. Por qué horizontal (el problema que resuelve)

La mesa vertical (verificada en 390×844) tiene tres roces
estructurales que ya costaron tres rondas de ajuste:

1. La consola se come casi la mitad del alto de mesa; con la
   consola abierta el escenario tuvo que bajar (alineación con
   dock abierto 0.66) para que el vaso no tapara el nombre del
   rival central, y aun así roza la pita central de ese rival.
2. Los asientos se apilan arriba y abajo en un ancho de 390 px;
   con 11 rivales hay un asiento central SOBRE el vaso
   (`lowCenter`, sentencia vertical) que solo existe por falta
   de ancho.
3. La sala no tiene dónde verse: el fondo es un rectángulo
   vertical donde solo cabe paño o foto, no una sala.

En horizontal (iPhone girado, ~844×390) la mesa es ancha de
verdad: los asientos van alrededor de un rectángulo, la
consola va al costado sin robar alto de mesa, y la sala por
fin tiene espacio alrededor. La geometría manda: con barra
superior de ~56 px y consola lateral de ~300 px, la mesa
queda en ~544×334 px, espacio suficiente para asientos
(~80 px), escenario (~150 px) y mi asiento (~90 px). Con
consola abajo, en cambio, la mesa quedaría en ~844×174 px:
injugable. Por eso la consola lateral es la propuesta
principal y la inferior es solo alternativa a juzgar.

## B. Principios de traducción a horizontal

1. **Las reglas no se tocan.** Toda la lista cerrada de
   `docs/01` (decisiones 1–33) queda intacta: subida clásica,
   ases mitad/doble+1 con interruptor, presets, pintas,
   calzo siempre, calzo perfecto, abandono a los 3 turnos,
   Kamikaze a ciegas, salas de 12, desconexión 60 s, renombre
   solo en lobby, semáforo + 3 pitidos, círculo del avatar
   con semáforo, sala activa con rejoin, DJ volumen 15,
   turno máx 60 s, NO partir con ases, sorteo visible, sin
   textos narrativos en partida, vaso boca abajo, economía
   (nacer con 5.000, apuestas 100/250/500/1.000/2.500, pozo =
   apuesta × jugadores sin comisión).
2. **Jugabilidad por sobre estética, como siempre.** Nada
   tapa dados, nombres, avatares ni aros. Targets ≥44 px,
   texto ≥14 px, contraste ≥4.5:1, efectos reducidos.
3. **12 jugadores ≠ 1v1.** 8 Ball Pool muestra 2 jugadores en
   espejo arriba; Cacho tiene hasta 12 asientos. La barra
   superior lleva información de sala (pozo, turno, saldo),
   NO un espejo de jugadores: los rivales son asientos
   alrededor de la mesa, como hoy.
4. **El layout es cliente, no servidor.** El servidor ya
   envía `theme` y `potFixed`; la orientación no cambia el
   protocolo ni las reglas. El prototipo es local (bots)
   primero, como en Fase A; en línea se verifica después.
5. **Sin copiar.** Nada de arte, logo, bola 8, taco, colores
   exactos ni sonidos de Miniclip (lista explícita en H19).
6. **Solo web.** Como todo v2.0: nunca APK sin orden suya.
7. **Estilo propio, composición prestada (principio rector,
   aclaración del usuario 24-oct).** De 8 Ball Pool se toma
   SOLO cómo se ordena la pantalla (mesa ancha, barra
   superior, sala alrededor). La identidad visual es de
   Cacho y de nadie más: Cuero y Paño (`docs/02`: fondo
   #120C09, madera oscura #2B1810, burdeos #5A1A1A, dorado
   envejecido #C9A24B, paño verde botella #0B5D3B→#06402A,
   marfil #F5EBD7, Cinzel + Montserrat, vaso de cuero y
   dados de marfil Blender, carácter chileno de pub). Si
   una propuesta, un fondo o una captura se parece a 8BP
   en estilo (no en composición), se reformula o se
   rechaza aunque se vea bien.
8. **Dos caminos, una decisión (segundo set: Parchisi
   Star).** Parchisi demuestra que el vertical PUEDE
   verse profesional y bien acomodado, así que el
   horizontal NO se asume como única salida: el
   tribunal evalúa DOS caminos (mesa horizontal H y
   vertical mejorado V) antes de decidir el camino del
   prototipo. Las referencias de Parchisi son, como
   las de 8BP, solo composición y presentación, con
   estilo propio de Cacho, nunca arte ni sistemas
   copiados.
9. **Óvalo y vasos visibles (tercer set: Monopoly
   Poker, dirección prioritaria).** Es la referencia
   más cercana a Cacho: mesa oval con asientos
   alrededor, pozo al centro, mi juego abajo al centro
   y botones abajo. La dirección prioritaria del
   usuario: VER LOS VASOS de todos sobre la mesa, como
   jugando en persona (propuestas CU). El aro de turno
   del póker convive con el semáforo de Cacho, no lo
   reemplaza. Monopoly refuerza el camino horizontal
   para la mesa, pero el tribunal sigue evaluando
   horizontal vs vertical mejorado antes de decidir.

## C. Propuestas concretas (para el tribunal)

### Asientos en horizontal (a)

- **H1. Mesa rectangular con 12 asientos alrededor.**
  Mesa completa (yo + 11 rivales): arriba 5, costados 2+2,
  abajo 2 rivales + yo al centro abajo. Coordenadas de
  partida (Alignment, como `_slotFor` actual): arriba
  (-0.95,-1), (-0.48,-1), (0,-1), (0.48,-1), (0.95,-1);
  izquierda (-1,-0.35), (-1,0.35); derecha (1,-0.35),
  (1,0.35); abajo (-0.7,1), (0.7,1); yo (0,1). Con menos
  jugadores se rellena en orden: arriba de centro hacia
  afuera, costados, abajo; el asiento central superior
  (0,-1) solo existe con 3+ rivales arriba. Desaparece
  `lowCenter` (el asiento sobre el vaso): en horizontal
  ningún asiento queda sobre el escenario.
- **H2. Yo abajo al centro, bajo mi vaso, como hoy.**
  Mi asiento sigue en (0,1), mi avatar bajo mi vaso, mi
  fila de dados entre el escenario y mi asiento. No cambia
  de sitio: cambia la mesa a su alrededor.

### Avatar al centro + hueco 104 (b)

- **H3. La regla se traduce, no se reemplaza.** Mi fila de
  dados sigue partida en dos grupos con un hueco de 104
  centrado exactamente sobre mi avatar, dados propios de
  44 px, número grande junto a las pipas en la misma fila
  (B10, sentencia v2.0). Lo que SÍ cambia: en horizontal
  hay ancho de sobra, así que la fila se centra de verdad
  (simétrica, hueco en el centro de la fila), y se jubila
  el truco vertical `left = 98 − L` (sentencia v53), que
  solo existía por falta de ancho. El hueco sigue siendo
  104 y el avatar sigue siendo 56.
- **H4. Sin asiento sobre el vaso.** Consecuencia de H1:
  con 11 rivales ya no hay `lowCenter`; el escenario
  central queda limpio siempre. Si un conteo bajo dejara
  un hueco visual arriba, se acepta: mejor hueco que
  asiento tapado.

### Escenario del vaso y dados propios (c)

- **H5. Escenario al centro, escala fija de partida 0.6.**
  El escenario (`_myStage`: vaso + dados) va al centro de
  la mesa horizontal, sin escala compacta 0.72 y sin
  desplazamiento por consola abierta: como la consola va
  al costado (H7), abrirla no roba alto de mesa y el
  truco de alineación 0.66 del vertical se jubila. Valor
  0.6 de partida, a confirmar por captura: el vaso debe
  quedar limpio de los asientos superiores y mis dados
  limpios de mi nombre. La animación de agitar/caer/
  levantar el vaso no cambia.
- **H6. Peek igual que hoy.** Tocar el vaso lo levanta y
  muestra mis dados en la misma fila con hueco; en
  Kamikaze a ciegas el vaso se cierra a la fuerza y el
  servidor no envía la mano, como hoy. Sin cambios de
  mecánica ni de reglas.

### Consola de apuesta (d)

- **H7. Consola en columna lateral derecha (propuesta
  principal).** El `BidDock` se vuelve columna de ~300 px
  de ancho y alto de mesa: pintas en rejilla 2×3 (cada
  pinta ≥44 px), debajo el control de cantidad, la fila
  armada con atajos +1 y ▲ pinta (B11, sin mantener
  presionado), el chip de probabilidad de 44 px (B12,
  apagado en Kamikaze a ciegas), y abajo DUDO / CALZO /
  PASO + APOSTAR, en ese orden, sin cambiar contenido,
  validación ni reglas. La columna no tapa la mesa: la
  mesa se achica a su ancho, no se cubre.
- **H8. Consola abajo en horizontal (alternativa).**
  Misma consola en franja inferior de ancho completo.
  Geometría en contra: la mesa quedaría en ~174 px de
  alto, injugable con asientos + escenario + mi asiento.
  Va al tribunal como alternativa con el argumento
  geométrico en contra, no como recomendación.
- **H9. Consola lateral plegable + barra mínima.**
  Botón ≥44 px pliega la columna: la mesa recupera todo
  el ancho y queda solo una barra mínima de acciones
  (DUDO / CALZO / PASO / APOSTAR) abajo, sin armar
  apuesta hasta desplegar. Plegar no cierra una apuesta
  armada: si hay apuesta armada, el botón APOSTAR sigue
  visible en la barra mínima. Al desplegar, vuelve la
  columna con la apuesta intacta.

### Barra superior (e)

- **H10. Barra superior de sala, no espejo de jugadores.**
  Altura ~56 px, tres zonas: izquierda, Salir +
  engranaje de ajustes (B13: solo historial, glosario y
  sonido; micrófono fuera, sigue solo sobre mi foto,
  regla 21); centro, píldora de pozo fijado (B8, pozo =
  apuesta × jugadores iniciales, nunca recalculado) +
  pastilla de turno con el nombre de quien juega (B9,
  dentro de su franja, sin tapar aros); derecha, mi saldo
  + tier de la sala (Barrio/Salón/Casino/VIP/High
  Roller) + apuesta. En línea, la barra de música (DJ)
  va compacta en esta barra, no sobre la mesa. Los
  rivales NO van en la barra: son asientos (H1).
- **H11. Turno ajeno sin señales nuevas.** El turno se
  lee como hoy: aro semáforo en el asiento (verde/
  amarillo/rojo según el tiempo restante) + pastilla de
  turno con nombre + barra fina de mi turno cuando soy
  yo + 3 pitidos solo en mi turno. Nada de banners
  flotantes, nada de flechas ni destacados nuevos sobre
  asientos: en un juego de farol, una señal nueva es
  una ventaja nueva.

### Sala y fondo profesional (f)

- **H12. Composición: sala ancha alrededor de mesa con
  marco, paño limpio al centro.** Fondo oscuro de sala
  (madera oscura / burdeos profundo, Cuero y Paño),
  marco de mesa con baranda de madera y costuras
  doradas propias (madera oscura de bar, cuero, burdeos;
  NUNCA marco ornamentado plateado ni dorado brillante
  tipo 8BP: el marco es de pub chileno, no de salón de
  pool), paño verde botella limpio al centro,
  viñeta profunda fuera del paño, luz cálida cenital
  sobre el paño. Zona calma obligatoria: bajo dados,
  avatares, nombres, pipas y aros no va bokeh, ni
  detalle, ni brillo; la sala vive FUERA del paño, no
  debajo del juego. El neón (mesa Neón) sigue solo
  dentro del rectángulo-mesa; el dorado, solo en tonos
  mates de #C9A24B. Prueba de parecido: si una captura
  del prototipo podría confundirse con 8 Ball Pool, se
  descarta ese fondo aunque se vea bien.
- **H13. Vía Blender en perspectiva (variante de
  comparación).** Render de la sala en perspectiva, no
  plato plano: cámara en ángulo viendo la mesa
  rectangular con marco + ambiente (lámparas cálidas
  desenfocadas, fondo oscuro), recorte a la zona de
  mesa. Binario en `~/blender/blender`, Cycles por CPU
  (EEVEE no corre en la VM), 128 samples + denoise,
  una imagen por tema (Dorado primero). Riesgo honesto:
  el plato plano de Blender del 22-oct salió lavado y
  se descartó; la perspectiva con luz focal es otro
  trabajo, pero si sale lavado se descarta igual y
  queda H14. Un render no es un motor 3D: cuesta una
  imagen estática, cero en el juego.
- **H14. Vía PIL compuesta (receta ganadora del pub,
  adaptada a horizontal).** Misma receta que ganó para
  `bg_pub.png` (`tools/gen_plate.py`, `gen_bokeh.py`):
  madera en perspectiva trapezoidal para marco y sala,
  paño con grano (`felt_bg.png`), bokeh cálido fuera
  del paño, luz cenital elíptica sobre el centro,
  viñeta profunda. Iteración en segundos, no minutos,
  y precedente ganador en esta VM.
- **H15. Recomendación para el prototipo: PIL primero.**
  El prototipo se construye con H14 (rápido, precedente
  ganador) y, en la misma entrega, se compara por
  captura con UNA variante H13 (Blender en perspectiva)
  del mismo Dorado. Se elige por captura, no por
  teoría: si el render no supera al compuesto, no
  entra. El prototipo no espera al render para
  existir.

### Orientación (g)

- **H16. Solo la mesa en horizontal; menús en vertical.**
  Inicio, lobby, hojas de creación, perfil, Personalizar,
  tienda, Cómo se juega y DJ quedan en vertical como
  hoy. Solo la pantalla de partida cambia de layout.
  Al entrar a la mesa con el teléfono en vertical, un
  aviso previo a la mesa (fuera de la partida, no es
  texto narrativo en juego): "Gira el teléfono para
  jugar en horizontal", con icono propio de girar y
  botón "Jugar igual en vertical" que lleva al layout
  actual. No se fuerza rotación por código ni se pide
  pantalla completa: en web Safari no se puede
  bloquear la orientación sin fullscreen, y pedirlo
  sería intrusivo.
- **H17. Si no gira, juega en vertical como hoy.**
  El layout vertical actual queda como fallback
  intacto: `game_screen` elige layout por orientación
  (ancho > alto → horizontal; si no, vertical actual).
  Nadie se queda sin jugar por no girar, y ninguna
  regla cambia entre layouts: mismo controlador, mismo
  servidor, misma consola en contenido.
- **H18. Girar en plena partida no pierde el juego.**
  Al girar, solo cambia el layout: mismo controlador y
  mismo estado, asientos reanimados con `AnimatedAlign`
  260 ms como hoy, sin reiniciar ronda, sin reenviar
  nada al servidor, sin tocar el temporizador de 60 s
  (el aro semáforo y los pitidos siguen su curso).

### Rendimiento y reglas de diseño (transversal)

- **H20. Fondo estático, modo ligero intacto.** El fondo
  es una imagen estática por tema (PIL o render), no 3D
  en tiempo real, no partículas, no video. El modo
  ligero de la sentencia v2.0 (B22) aplica igual: bajo
  60 fps o con efectos reducidos, se apaga el brillo y
  queda paño oscuro + acento mínimo. Safari en iPhone:
  sin háptica real (los ticks son visuales), audio solo
  tras toque, y `SafeArea` en los bordes (notch e
  indicador de inicio en horizontal).
- **H21. Alcance del prototipo: local, Dorado, captura.**
  El prototipo es: mesa horizontal en partida local
  (bots), tema Casino Dorado con fondo H14 (+ variante
  H13 para comparar), asientos H1, yo H2–H3, escenario
  H5–H6, consola H7 (+ H9 si el tribunal la acepta),
  barra H10–H11, orientación H16–H18. Se captura en
  horizontal 844×390 con 2, 5 y 11 rivales, consola
  abierta y cerrada, y mi turno con semáforo. En línea
  se verifica después, sin cambios de servidor: el
  layout es cliente y el `theme` ya viaja con la sala.

## D. H19. Lo que NO se copia de 8 Ball Pool (lista explícita)

- Arte, logo, bola 8, taco, colores exactos ni sonidos
  de Miniclip. Nada de "8 Ball" en ningún texto.
- Espejo 1v1 con dos avatares arriba: Cacho tiene 12
  asientos, no 2 jugadores.
- Niveles, XP, rating, monedas premium, dinero real,
  cajas o packs de azar, salas bloqueadas por nivel.
- Reglas especiales por sala (cantar tronera, etc.):
  las reglas de Cacho son unas y parejas.
- Mecánica de puntería: taco, carril de bolas, bola de
  efecto, rueda de puntería, barra de potencia, línea
  de trayectoria, "bola en mano", faltas.
- Tarjetas de ciudad (Londres, Tokio, Las Vegas) y
  nombres de salas de 8BP: las salas de Cacho son
  Barrio/Salón/Casino/VIP/High Roller, montos cerrados.
- Pantalla de victoria con trofeo 8BP, chat en partida,
  animaciones de celebración sobre la mesa, y cualquier
  reacción flotante tipo emoji (B20, ya rechazada en
  la sentencia v2.0: no resucita en horizontal).
- Layout horizontal como excusa para dos manos: la
  consola lateral queda al alcance del pulgar derecho
  y el vaso al centro; nada exige puntería fina ni
  gestos de dos manos.
- Estilo visual de 8BP: marco ornamentado plateado,
  UI azul noche, dorado brillante de moneda, casino
  genérico internacional. La paleta es Cuero y Paño
  (docs/02) y la sala huele a pub chileno, no a salón
  de pool (principio rector B7).
- Parecido aunque sea "sin querer": si el resultado se
  parece a 8BP en estilo, se descarta aunque se vea
  bien. La composición se comparte; la identidad, no.

### Identidad propia (transversal)

- **H22. Carácter propio chileno en la sala.** La sala
  horizontal del prototipo se construye con carácter de
  pub chileno, no de casino genérico: madera oscura de
  bar, cuero, luz cálida de lámpara de bar, burdeos y
  dorado envejecido de `docs/02`, vaso de cuero y dados
  de marfil Blender ya propios. Verificación del
  prototipo: paleta chequeada contra `docs/02`, ningún
  elemento identificable de 8BP (marco ornamentado,
  azul noche, dorado moneda), y presencia visible del
  carácter pub (madera/cuero/luz cálida). Si la sala
  parece de otro juego, no entra, por bien compuesta
  que esté.

## E. Riesgos que el tribunal debe pesar

1. **Ancho robado por la consola lateral:** 300 px de
   consola dejan la mesa en ~544 px; con 5 asientos
   arriba, cada asiento tiene ~109 px: nombre (máx 104
   hoy) + avatar 56 caben, pero sin holgura. Si el
   tribunal ve apretura, la consola debe adelgazar o
   plegarse por defecto (H9).
2. **Alto en horizontal:** 390 px totales son menos
   que los 844 de vertical; la barra (56) + mesa (334)
   no perdonan: un píxel de más en la barra es un
   píxel menos de asiento. La barra no crece.
3. **Dos layouts que mantener:** vertical fallback +
   horizontal duplican la superficie de pruebas de la
   mesa (capturas por conteo de rivales × 2 layouts).
   El vertical no se borra: se congela, no se mejora
   en paralelo.
4. **Fondo que compite con el juego:** una sala
   profesional mal compuesta tapa la lectura de pipas
   y aros peor que un paño plano. La zona calma de H12
   es la que decide si la sala entra o no.
5. **Giro a mitad de partida:** si el cambio de layout
   reinicia o traba el temporizador, el prototipo no
   sirve. H18 es condición, no adorno.
6. **Falsa promesa de "como 8BP":** la referencia es
   composición, no identidad. Si el resultado se parece
   a 8 Ball Pool en arte o marca, se descarta aunque
   se vea bien.
7. **Imitación de estilo (principio rector B7):** el
   riesgo no es solo copiar un logo, es copiar un
   lenguaje (marco ornamentado, azul noche, dorado
   moneda, casino genérico). El tribunal debe oler
   cada propuesta y cada fondo: composición prestada
   sí, estilo prestado no. H22 es el filtro.

## F. Segundo set de referencias: Parchisi Star (composición, no estilo)

Fecha: 2026-10-24. El usuario pasó 5 capturas de Parchisi Star.
Regla igual que con 8BP: son EJEMPLOS de composición y
presentación, con estilo propio de Cacho, NUNCA copiar arte,
assets, marcas ni sistemas de Parchisi Star. Es un juego de
dados como Cacho: se observan dados, marcos de jugador y
jerarquía, no el parchís en sí.

### F.1 Lo observado (solo composición)

- **Partida en vertical:** panel superior de premios
  estructurado (modo RÁPIDO, 1º 6000 monedas + cofre, 2º
  2000); avatares con marco en las esquinas (arriba
  izquierda/derecha, abajo izquierda/derecha) con nombre
  debajo; tablero al centro con marco de madera; zona
  inferior limpia con dados, botón de lanzar y acciones.
  La partida vertical se ve profesional y bien acomodada
  SIN girar el teléfono: esa es la lección principal.
- **Tarjetas de liga:** emblema + nombre del tier
  (SILVER, TRAINEE, BRONZE) arriba; "WIN!" con pila de
  monedas + cofre; fila de estadísticas (estrella, llama);
  multiplicador X1.3; botón grande de entrada con precio
  (10K, 500, 2000); flechas laterales para recorrer
  tiers; barra superior con monedas y gemas.
- **Pantalla principal:** barra superior con avatar,
  saldos y engranaje; tarjetas grandes de modo (1 ON 1,
  TEAM UP, TROPHY ARENA, LEAGUE, BIG WIN); banner
  promocional; navegación inferior de 5 secciones.
- **Jerarquía de dados:** los dados son la acción y se
  ven como tal: grandes, abajo, tocables, sin competir
  con el resto. Cacho ya tiene eso (vaso + dados); la
  lección es jerarquía, no arte de dados.

### F.2 Camino vertical mejorado (propuestas V)

- **V1. Panel superior de premios estructurado
  (vertical).** En la mesa vertical, el pozo deja de ser
  solo píldora suelta y pasa a una tarjeta superior
  compacta dentro de la franja actual (sin fila nueva
  ni más alto): tier + apuesta + pozo fijado (apuesta ×
  jugadores iniciales, B8 condicionado: nunca se
  recalcula) + jugadores en mesa. Solo números reales.
  La barra no crece: misma franja, mejor orden.
- **V2. Asientos anclados a esquinas con marco propio
  (vertical).** Los rivales se anclan a las esquinas
  primero (superior izquierda/derecha, media
  izquierda/derecha con margen real de esquina) y luego
  a bordes; cada asiento lleva marco dorado mate +
  avatar + nombre + pipas, sin solaparse entre sí ni
  con el escenario. Yo sigo abajo al centro bajo mi
  vaso (decisión 28 intacta). Con 11 rivales se mantiene
  la distribución actual adaptada: si con 12 no cabe
  sin solape, `lowCenter` queda como hoy, sin empeorar.
  No se promete eliminar `lowCenter`: se promete no
  apiñar.
- **V3. Zona inferior limpia (vertical).** Jerarquía
  fija: vaso protagonista al centro, mis dados con
  hueco 104 (sentencia v53 intacta), consola abajo sin
  cambios de contenido. Nada nuevo entre vaso, dados y
  consola: lo profesional aquí es orden, no elementos.
- **V4. Fondo vertical profesional, misma receta
  ganadora.** Sala pub compuesta en PIL (madera en
  perspectiva, bokeh fuera del paño, luz cenital,
  viñeta) adaptada a composición vertical, zona calma
  bajo el juego. Es H14 en vertical, no el plato plano
  descartado del 22-oct. El vertical no necesita sala
  ancha para verse profesional: necesita sala bien
  compuesta.
- **V5. Vertical mejorado no toca orientación.**
  Se juega como hoy, sin aviso de girar, sin layout
  nuevo que mantener en paralelo, sin riesgo de giro a
  mitad de partida. Ventaja real frente a H: cero
  maquinaria de orientación y cero duplicación de
  pruebas de mesa.

### F.3 Tarjetas de tier (propuestas P, presentación)

- **P1. Tarjetas de tier con entrada + pozo vivo + ×N
  (solo números reales).** En el lobby (sala existente)
  cada tarjeta muestra: nombre del tier
  (Barrio/Salón/Casino/VIP/High Roller), entrada
  (apuesta real), pozo vivo (apuesta × jugadores
  actuales de esa sala) y "×N jugadores" como
  multiplicador real (pozo/apuesta = jugadores, no
  bonificación). En creación (sin sala aún): entrada +
  fórmula "pozo = apuesta × jugadores", SIN pozo
  inventado. Si no hay jugadores, no hay pozo que
  mostrar. El botón es "Entrar" o "Crear" con la
  apuesta visible.
- **P2. Nada de sistemas de Parchisi en la tarjeta.**
  Sin estrellas, llamas, cofres de azar ("Chance to
  get"), gemas, SALE, niveles, bloqueos por nivel ni
  premios extra. La tarjeta Cacho no promete nada fuera
  de entrada + pozo real. Sin precio sorpresa, sin
  segunda moneda, sin azar pagado.
- **P3. Estilo propio de la tarjeta.** Cuero y Paño
  (madera oscura, dorado mate #C9A24B, marfil,
  Cinzel/Montserrat), emblema propio por tier (no
  corona de liga copiada), miniatura de la mesa propia
  (render/compuesto propio, nunca arte de Parchisi).
  La tarjeta se reconoce como Cacho, no como liga de
  otro juego.

### F.4 Decisión de camino (lo que el tribunal debe decidir)

- El tribunal juzga H (ronda 1) y V+P (ronda 2) y
  recomienda UN camino para el prototipo: horizontal o
  vertical mejorado. El camino no elegido queda
  documentado, no se borra. Si no hay mayoría clara
  (empate), el prototipo es comparativo: ambos layouts
  en local con las mismas capturas (2, 5 y 11 rivales,
  consola abierta y cerrada, mi turno con semáforo) y
  decide el usuario por captura. Las tarjetas P son
  independientes del camino: entran en cualquiera de
  los dos si el tribunal las acepta.

### F.5 Lo que NO se toma de Parchisi Star (lista explícita)

- Botones EMOJI y CHAT en partida: en Cacho serían
  señales en juego de farol (B20, ya rechazada en la
  sentencia v2.0: no resucita ni en vertical ni en
  horizontal).
- Multi-moneda (monedas + gemas), banners SALE, cofres
  con recompensa aleatoria, estrellas y llamas de XP,
  bloqueos por nivel (TROPHY ARENA Level 15), arena
  de trofeos, tienda con dinero real.
- Modos 1 ON 1 / TEAM UP como modos de Cacho: Cacho
  tiene partida local y salas con amigos, no modos.
- Navegación inferior Shop/Friends/Events/Clubs: el
  inicio de Cacho queda sin scroll con sus 3 tarjetas
  (master prompt), no se densifica como el home de
  Parchisi.
- El tablero de parchís, sus colores por jugador, sus
  fichas y su arte de dados: el vaso de Cacho es de
  cuero Blender y los dados de marfil, y quedan.
- Multiplicador X1.3 como bonificación: en Cacho el
  único "×N" es jugadores reales (P1). Nada de
  bonificar el pozo.

### F.6 Riesgos añadidos por el segundo set

8. **Panel superior duplicado (V1):** si la tarjeta de
   premios crece, empuja la mesa y reaparece el roce
   vertical que V viene a curar. V1 vive o muere por
   no crecer la franja.
9. **Esquinas con 12 (V2):** anclar a esquinas no crea
   ancho: con 11 rivales el apiñamiento puede seguir
   y `lowCenter` puede sobrevivir. V2 no promete lo
   que no cabe.
10. **Multiplicador mentiroso (P1):** un "×N" mal
    leído parece bonificación de premio. Si la tarjeta
    no deja cristalino que ×N = jugadores reales, P1
    se cae aunque los números sean reales.
11. **Dos caminos, doble trabajo (F.4):** si el
    tribunal no decide y el prototipo comparativo se
    vuelve permanente, se mantienen dos mesas. El
    comparativo es un puente a la decisión del
    usuario, no un estado final.

## G. Tercer set de referencias: Monopoly Poker (composición, no estilo)

Fecha: 2026-10-24. 4 capturas. Regla igual: solo
composición, estilo propio de Cacho, NUNCA arte, marca,
personaje (Mr. Monopoly) ni sistemas. Es la referencia
MÁS cercana a Cacho y refuerza el camino horizontal para
la mesa, pero el tribunal sigue evaluando horizontal vs
vertical mejorado antes de decidir.

### G.1 Lo observado (solo composición)

- **Mesa oval roja en horizontal:** asientos alrededor
  (arriba izquierda/derecha, costados, abajo), pozo al
  centro en fichas (132K, 60,188), mi juego abajo al
  centro, botones de acción abajo (RETIRARSE / VER /
  ALL-IN en mi turno; PASAR/RETIRARSE / VER LA ACTUAL
  / VER CUALQUIERA en turno ajeno: botones de póker,
  no de Cacho).
- **Aro brillante verde en el jugador en turno:**
  mismo concepto que el semáforo de Cacho (verde/
  amarillo/rojo + pitidos).
- **Barra superior con saldos;** botones laterales
  (BUY ALL, bundle, calendario) y burbuja de chat
  abajo a la izquierda: sistemas prohibidos.
- **Lobby:** tarjetas verticales de mesas (CASH GAME
  1K/2K CIEGAS, BUY-IN 20K-100K, JUGAR AHORA; otras
  con LVL 3 / LVL 10 bloqueadas), barra inferior de
  modos (COMUNIDAD, BLACKJACK, etc.).

### G.2 Propuestas óvalo (O, refinan H)

- **O1. Óvalo en vez de rectángulo (refina H1).** Los
  asientos siguen una elipse alrededor del paño (arco
  superior 5, arcos laterales 2+2, arco inferior 2 + yo
  abajo al centro), no un rectángulo: las esquinas del
  rectángulo apiñan; el óvalo reparte. Mismos conteos
  que H1, geometría oval. Con menos jugadores, mismo
  orden de llenado (arriba de centro hacia afuera,
  costados, abajo).
- **O2. Pozo y apuesta vigente en el eje central del
  paño (refina H10).** La píldora de pozo fijado + la
  apuesta vigente se muestran centradas en el borde
  superior del paño (entre los asientos superiores y
  el escenario), como el pozo al centro del póker, sin
  invadir el escenario: el centro del paño lo ocupa mi
  vaso, no el pozo. La barra superior conserva turno,
  saldo y tier. Si el borde superior no da sin tapar
  asientos, el pozo queda en la barra (H10) y O2 cae.
- **O3. El aro de turno convive con el semáforo, no
  lo reemplaza.** El aro brillante del póker es el
  mismo concepto que el semáforo de Cacho; no se crea
  aro nuevo. El brillo del aro en turno usa el color
  semáforo vigente (verde/amarillo/rojo) + los 3
  pitidos en mi turno, como hoy (`seatRingColor`).
  Ningún color nuevo, ningún brillo fijo.
- **O4. Barra de acciones abajo en horizontal (refina
  H9).** Con la consola plegada, la barra mínima va
  abajo al centro con DUDO / CALZO / PASO / APOSTAR en
  grande (≥44 px), como los botones de póker abajo.
  Nota explícita: el VER del póker (igualar) NO existe
  en Dudo y NO se crea; la traducción es la barra, no
  el botón. Las acciones de Cacho son esas cuatro, sin
  inventar ninguna.
- **O5. Tarjetas de sala del lobby (refina P1).** La
  tarjeta lleva apuesta (buy-in) + pozo vivo + botón
  JUGAR que entra directo a la sala, sin pantallas
  extra. Las ciegas del póker NO se traducen como
  sistema: en Cacho no hay ciegas; la "entrada" es la
  apuesta del tier. Todo con números reales (P1
  intacto).

### G.3 Lo que NO se toma de Monopoly Poker (lista explícita)

- Mr. Monopoly, marca, nombre, arte, cartas, fichas
  con M, dados del juego, color rojo de la mesa oval
  como identidad: el paño de Cacho es verde botella
  (docs/02); el óvalo es geometría, no color.
- Burbuja de chat en partida (señal en juego de
  farol; B20).
- BUY ALL, bundles, multi-moneda, blackjack y modos
  extra, bloqueos por nivel (LVL 3/10), calendario de
  eventos, rangos (SIN RANGO).
- Mecánica de póker: ciegas como sistema, ALL-IN,
  VER/igualar, PASAR como acción de póker, cartas
  comunitarias, "CARTA ALTA" como evaluación de mano.

## H. Propuesta central: vasos visibles en cada asiento (dirección prioritaria del usuario)

Razón del usuario: poder VER LOS VASOS sobre la mesa
para sentirse como jugando en persona. Dirección
prioritaria para brainstorm y sentencia.

- **CU1. Cada asiento tiene SU vaso visible sobre la
  mesa, delante de su avatar.** Vaso cerrado boca
  abajo, objeto físico, nunca revela dados. Los vasos
  de rivales NO son interactivos (no se tocan, no se
  levantan, no se animan por turno); solo están, como
  en persona. Mi vaso sigue siendo el interactivo del
  centro (agitar, espiar, peek). Los vasos rivales usan
  el mismo sprite Blender por color a escala menor
  (~0,5 del mío), delante del avatar, sin tapar nombre,
  pipas ni aro. Alcance: óvalo horizontal; en vertical
  queda pendiente de variante (el vertical conserva su
  vaso único al centro en este prototipo).
- **CU2. Agitación de inicio de ronda.** Al partir la
  ronda, TODOS los vasos se agitan brevemente a la vez
  (misma animación, misma duración, mismo sonido si
  lo hay), sensación física real. La animación es
  IDÉNTICA para todos: sin variación por mano, sin
  duración por cantidad de dados, sin sonido distinto
  por jugador. Si algo variara por jugador, se rechaza:
  una animación que delata es información.
- **CU3. Color de vaso por jugador.** Cada vaso muestra
  el color elegido por su jugador en Personalizar (los
  4 colores actuales; en Fase B, los vasos de tienda).
  Visible en partida, sin ventaja: el color no cambia
  dados, turnos ni probabilidades. Sin elección, café
  por defecto. El color viaja con el jugador
  (perfil/sala), no se inventa ni se sortea.
- **CU4. Verificación anti-tapa y anti-fuga.** Ningún
  vaso tapa nombres, avatares, pipas, aros ni consola
  (captura con 11 rivales, consola abierta y cerrada);
  ningún vaso rival se levanta, se mueve por turno,
  cambia de color en partida ni anima distinto; en
  Kamikaze a ciegas los vasos rivales siguen cerrados
  e idénticos (el servidor no envía la mano, como hoy,
  sin cambios). Si una variante filtrara dados, cantidad
  o delatara por animación, se rechaza o se condiciona
  a vaso siempre cerrado e idéntico en animación para
  todos.

### H.1 Riesgos añadidos

12. **Vasos que tapan:** 11 vasos extra en el óvalo
    pueden tapar pipas y aros si la escala o la posición
    fallan; CU1 vive o muere por la captura con 11
    rivales.
13. **Animación que delata:** una agitación con
    duración, sonido o rebote distinto por mano es una
    filtración; CU2 exige identidad total o no entra.
14. **Color como señal:** si el color del vaso se leyera
    como estado (ej. "vaso rojo = peligro"), sería una
    señal nueva; CU3 exige que el color sea solo
    cosmético elegido, nunca estado de juego.
15. **Camino y vasos:** CU es horizontal-oval; si el
    camino fuera vertical, los vasos visibles quedan
    pendientes de variante y el prototipo vertical sale
    sin ellos (sin bloquear el camino).
