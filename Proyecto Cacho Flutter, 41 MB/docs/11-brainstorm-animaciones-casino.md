# 11 — BRAINSTORM: NUEVAS ANIMACIONES DE CASINO

**Orden del usuario (25-oct, 01:50):** brainstorm de nuevas animaciones. Es un juego
de casino y los casinos llevan muchas animaciones. Debe cubrir: apenas se abre la
aplicación o la web (como estamos ahora), al entrar a una sala, al seleccionar
sala, etc. Después va a tribunal. Esta ronda NO construye nada: propone, el
tribunal juzga, el usuario decide.

**Alcance:** solo web (la APK sigue diferida por su orden). Sin cambios de
servidor (todo es visual, del lado de la app). Sin despliegue sin su sí.

## Estado actual (lo que YA hay, para no re-proponerlo)

- Apertura: el home aparece directo, logo Dudo estático, fondo pub estático.
- Botones: estáticos, salvo el pulso del APOSTAR en partida y el semáforo del
  círculo del avatar en turno (decisiones 31–32).
- Vaso y dados: animación de agitar, levantar el vaso y rodar los dados; peek.
- Victoria: CoinRain (22 monedas) + count-up lineal del pozo en el overlay del
  ganador. Celebración con moneda de oro Blender.
- Música: MusicBar estática (título + controles); DJ con barra sobre la mesa.
- Turno: aro semáforo + barra fina + 3 pitidos (decisiones 31–32).
- Todo lo demás (selección de sala, entrada a sala, lobby, rescate, pozo en
  lobby) cambia de estado sin animación propia de casino.

## Cercas vigentes (mandan sobre cualquier propuesta)

- **Estilo propio Cuero y Paño / casino dorado / pub chileno.** Las referencias
  (8BP, Parchisi, Monopoly) son solo ejemplos de composición, nunca modelo
  visual a imitar ni a copiar.
- **H19 (8BP):** nada de su arte, logo, bola 8, taco, colores ni estilo.
- **F.5 (Parchisi):** nada de botones EMOJI ni CHAT en partida; nada de corona
  de liga, XP, rangos ni emojis como iconos.
- **G.3 (Monopoly):** nada de Mr. Monopoly, marca, nombre, personaje,
  bundles/BUY ALL ni packs/cofres.
- **B20 (rechazada):** nada de reacciones ni emojis flotantes; nada flotante
  sobre asientos en turno (tapa asientos y mete señales en juego de farol).
- **R26:** celebraciones SOLO en pantalla de victoria, nunca como animación
  sobre la mesa en turno ni flotante sobre asientos.
- **D11:** ningún brillo de turno como señal nueva: nada que un jugador pueda
  leer como información de otro.
- **Sin señales en partida:** ninguna animación puede revelar ni sugerir manos,
  apuestas, intenciones ni estado oculto de nadie.
- **Sin dinero real:** nada que sugiera apuestas reales (copy prohibido: BUY-IN,
  PREMIO, "×N" aislado, LVL, ciegas, corona). El rodillo de AN11 es solo
  animación de dígitos, sin azar ni premio.
- **Paleta:** dorado solo mate `#C9A24B`, nunca dorado brillante tipo moneda;
  cian solo dentro de la mesa Neón; sin navy en home ni MusicBar.
- **Rendimiento:** 60 fps en el teléfono; ninguna animación puede tapar un
  control jugable ni retrasar una acción.
- **Hereda:** decisiones 1–33 de `docs/01`, sentencias de diseño final, mesa
  horizontal, v2 frontend, v53 y rediseño completo (incluye R38–R43: la mesa
  solo se refina visualmente, sin animación nueva sobre el paño en turno).

## Propuestas

### AN1. Telón dorado de apertura (al abrir la app/web)
- **Antes → después:** el home aparece directo → al abrir, un telón dorado mate
  se abre de centro a lados (~0,8 s) revelando el home, con el logo Dudo
  emergiendo con un barrido de luz mate. Un toque lo salta.
- **Composición:** solo apertura; no vuelve a aparecer en la sesión.
- **Hereda:** estilo propio casino dorado; logo Dudo existente.
- **NO cambia:** home, hojas, mesa, reglas, economía.
- **Marca:** sin verificar (solo propuesta).

### AN2. Partículas doradas flotando en el home
- **Antes → después:** fondo pub estático → motas doradas mates flotando lento
  sobre el fondo del home (como polvo de casino en el aire), muy sutiles,
  sin tapar tarjetas ni botones.
- **Composición:** solo home (y hojas de inicio); nunca en mesa.
- **Hereda:** fondo pub v3; dorado mate.
- **NO cambia:** tarjetas, botones, saldos, reglas.
- **Marca:** sin verificar (solo propuesta).

### AN3. Barrido de luz en el logo Dudo
- **Antes → después:** logo estático → cada ~8 s un barrido de luz mate cruza
  el logo Dudo en el home (brillo que pasa, sin cambiar el logo).
- **Composición:** solo home; una sola pasada por ciclo, sin parpadeo.
- **Hereda:** logo Dudo existente (CaveatBrush).
- **NO cambia:** logo, tagline, tarjetas.
- **Marca:** sin verificar (solo propuesta).

### AN4. Shimmer en el botón principal
- **Antes → después:** botón JUGAR estático → brillo mate que recorre el botón
  dorado principal en home y en la hoja de jugar, en ciclo lento.
- **Composición:** solo botones primarios dorados; nunca en botones de acción
  en partida (APOSTAR, DUDO, CALZO, PASO quedan como están).
- **Hereda:** botón dorado mate existente.
- **NO cambia:** resto de botones, consola, mesa.
- **Marca:** sin verificar (solo propuesta).

### AN5. Ficha que cae al seleccionar sala/tier
- **Antes → después:** seleccionar tier/sala cambia el color al instante → al
  tocar una tarjeta, una ficha dorada mate cae y se posa sobre la tarjeta
  seleccionada (~0,4 s), y el borde dorado mate se enciende.
- **Composición:** selector de tier (rejilla R10) y tarjetas de sala.
- **Hereda:** rejilla de tiers 3+2, chips neutros, dorado mate.
- **NO cambia:** apuestas, nombres, montos, reglas.
- **Marca:** sin verificar (solo propuesta).

### AN6. Cortina al entrar a una sala
- **Antes → después:** de lobby a mesa se pasa directo → al pulsar PARTIR (o al
  entrar a la sala activa), una cortina dorada mate se cierra y se abre
  (~0,7 s) revelando la mesa. Es transición, no ocurre en turno.
- **Composición:** solo transición lobby→mesa y sala activa→mesa.
- **Hereda:** puerta CU4 intacta (esto es transición, no vasos rivales).
- **NO cambia:** mesa, asientos, reglas, sorteo de inicio.
- **Marca:** sin verificar (solo propuesta).

### AN7. Barajar fichas al crear sala
- **Antes → después:** crear sala confirma al instante → al confirmar, pilas de
  fichas se barajan y se apilan en el centro de la hoja (~0,8 s) antes de
  mostrar el código de sala.
- **Composición:** solo hoja de creación de sala.
- **Hereda:** fichas neutras existentes; sin copy nuevo.
- **NO cambia:** código de sala, apuestas, reglas, servidor.
- **Marca:** sin verificar (solo propuesta).

### AN8. Dado girando al conectar (unirse por código)
- **Antes → después:** la espera de conexión no tiene animación propia → un
  dado de marfil gira suave mientras se conecta a la sala (con el texto de
  espera actual, sin texto nuevo).
- **Composición:** solo espera de conexión a sala.
- **Hereda:** dados marfil Blender existentes.
- **NO cambia:** flujo de unirse, errores, códigos.
- **Marca:** sin verificar (solo propuesta).

### AN9. Asientos que entran con pop en el lobby
- **Antes → después:** un jugador que se une aparece de golpe en su fila →
  su fila entra con un pop escalonado suave (escala 0,9→1 + fundido, ~0,3 s).
  Solo en lobby, nunca en partida (en partida los asientos ya están fijos).
- **Composición:** filas del lobby.
- **Hereda:** filas de lobby existentes; sin señales (no revela nada oculto).
- **NO cambia:** mesa, asientos en partida, mic, DJ.
- **Marca:** sin verificar (solo propuesta).

### AN10. Pulso dorado del banner SALA ACTIVA
- **Antes → después:** banner dorado estático → pulso dorado mate muy lento
  (brillo que sube y baja) mientras haya sala activa.
- **Composición:** solo banner del home.
- **Hereda:** sala activa (decisión 25); dorado mate.
- **NO cambia:** texto, botón "Entrar a la sala activa", rejoin.
- **Marca:** sin verificar (solo propuesta).

### AN11. Rodillo de dígitos para el pozo
- **Antes → después:** el pozo se muestra como número estático en lobby y con
  count-up lineal al ganar → cada dígito rueda como rodillo (estilo visual de
  tragamonedas, SIN azar ni premio: el número final es el pozo real fijado)
  al mostrar el pozo en lobby y al contar el pozo ganado.
- **Composición:** píldora de pozo en lobby y placa del ganador.
- **Hereda:** pozo fijado al partir (potFixed); count-up existente lo reemplaza
  el rodillo, mismo número final.
- **NO cambia:** montos, apuestas, pozo real, reglas, economía.
- **Marca:** sin verificar (solo propuesta).

### AN12. Celebración de victoria ampliada (solo pantalla de victoria)
- **Antes → después:** CoinRain (22 monedas) en el overlay del ganador →
  CoinRain + confeti dorado mate + moneda gigante central con destello,
  todo dentro de la pantalla de victoria, nunca sobre la mesa.
- **Composición:** solo overlay/pantalla de victoria.
- **Hereda:** R26 (celebraciones solo en victoria); CoinRain existente;
  moneda de oro Blender.
- **NO cambia:** mesa, asientos, pozo, reglas.
- **Marca:** sin verificar (solo propuesta).

### AN13. Moneda que cae al rescatar
- **Antes → después:** al rescatar, el saldo cambia al instante → una moneda
  dorada mate cae desde arriba hasta el chip de saldo y el número sube
  con el rescate (+1.000/día).
- **Composición:** solo chip de saldo del home.
- **Hereda:** rescate del día existente; moneda de oro Blender.
- **NO cambia:** montos, frecuencia del rescate, billeteras.
- **Marca:** sin verificar (solo propuesta).

### AN14. Ecualizador animado en la MusicBar
- **Antes → después:** MusicBar estática → barras de ecualizador doradas mates
  que se mueven al ritmo aparente mientras suena el DJ (visual puro: no mide
  audio real, no cambia volumen ni ducking).
- **Composición:** solo MusicBar (sala en línea).
- **Hereda:** DJ existente; barra sobre la mesa intacta.
- **NO cambia:** audio, DJ, cola, votos, mic, ducking.
- **Marca:** sin verificar (solo propuesta).

### AN15. Barrido de luz neutro al cambiar el turno
- **Antes → después:** al cambiar el turno solo cambian aro, barra y píldora →
  un barrido de luz neutro (sin color de turno, idéntico para todos los
  asientos) cruza el paño en el instante del cambio.
- **Composición:** solo instante del cambio de turno; dura ~0,5 s.
- **Hereda:** aro semáforo (decisiones 31–32) intacto.
- **NO cambia:** aro, barra, pitidos, reglas, orden de turnos.
- **Marca:** sin verificar (solo propuesta). **Riesgo declarado:** si el
  tribunal lo lee como señal nueva (D11), cae.

### AN16. Vaso que se posa al entrar a la mesa
- **Antes → después:** la mesa aparece con el vaso ya puesto → al entrar por
  primera vez a la mesa, mi vaso desciende desde arriba y se posa con su
  sombra (~0,6 s). Solo entrada; en turnos y rondas siguientes no se repite.
- **Composición:** solo primera entrada a la mesa.
- **Hereda:** vaso boca abajo existente; puerta CU4 intacta.
- **NO cambia:** vaso, dados, peek, Kamikaze a ciegas, reglas.
- **Marca:** sin verificar (solo propuesta).

### AN17. Interruptor "Animaciones" en ajustes
- **Antes → después:** no hay forma de apagar las animaciones → interruptor
  en ajustes (default activado): apagado, todas las animaciones AN1–AN16 se
  vuelven instantáneas (estado final directo), sin quitar funcionalidad.
- **Composición:** ajustes (engranaje sin micrófono).
- **Hereda:** ajustes existentes; interruptores de música/efectos.
- **NO cambia:** reglas, economía, DJ, mesa, sonidos.
- **Marca:** sin verificar (solo propuesta).

### AN18. Fichas que se retiran al quedar eliminado
- **Antes → después:** al quedar eliminado (incluye abandono AFK) solo aparece
  el aviso → en el overlay de fin, las fichas del eliminado se retiran de la
  mesa hacia un lado (~0,6 s). Nunca durante la partida ni sobre asientos
  en turno.
- **Composición:** solo overlay de fin / aviso de eliminación.
- **Hereda:** abandono AFK (decisión 24); overlay de fin existente.
- **NO cambia:** reglas de eliminación, apuesta perdida, pozo.
- **Marca:** sin verificar (solo propuesta).

## Fuera de alcance (no se propone)

- Animaciones sobre la mesa en turno, flotantes sobre asientos, reacciones,
  emojis, chat en partida, señales de ningún tipo (B20, R26, D11).
- Animaciones con azar real, premios, cofres, bundles, multi-moneda, SALE,
  gemas (G.3, F.5).
- Copiar arte, logo, colores, personajes o estilo de 8BP, Parchisi o Monopoly
  (H19, F.5, G.3).
- Cambios de servidor, APK, despliegue (necesita su sí por separado).
- Cambiar reglas, economía, montos, bandas de tienda o apuestas.
