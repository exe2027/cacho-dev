# Brainstorm frontend v2.0 — Qué le copiamos a 8 Ball Pool (y qué no)

Fecha: 2026-10-24. Estado: BRAINSTORM (nada de esto está construido;
va a tribunal antes de implementarse).
Base: propuesta v2.0 (`05-propuesta-v2-casino.md`, decisiones D1–D6
cerradas) + estudio del frontend público de 8 Ball Pool (Miniclip):
su ayuda oficial, su wiki de salas y guías de juego. No se usó ni
se copió ningún asset, logo, sonido ni imagen de Miniclip: lo que
sigue son descripciones funcionales, reinterpretadas con arte
propio (vaso de cuero y dados de marfil Blender, paño y madera
generativos, Cinzel + Montserrat, dorado envejecido).

## A. Inventario frontend de 8 Ball Pool (lo observado)

### A1. Pantalla de partida (el partido)
- **Arriba, espejo 1v1:** avatar + nombre + nivel + barra de XP
  de cada jugador, a los lados; AL CENTRO, el premio en
  monedas, grande y siempre visible. Debajo de cada avatar:
  qué bolas le quedan (lisas/rayadas) y su racha de victorias.
- **Abajo, la herramienta:** carril de bolas embocadas, bola
  de efecto (botón con una bola blanca y un punto rojo: se
  arrastra el punto para poner efecto — centro, arriba, abajo,
  lados), y el taco visible al costado de la mesa.
- **Controles de tiro:** arrastrar el taco para apuntar con
  línea de trayectoria (solo guía el primer contacto, no
  resuelve el tiro); rueda de puntería (dial circular) para
  ajuste fino; barra de potencia vertical al costado (se tira
  hacia atrás y se suelta); banner "YOUR MOVE" en tu turno;
  marca de cruz si apuntas a una bola que no es tuya; aviso
  de falta y "bola en mano".
- **Ajustes en partida:** engranaje abajo a la izquierda:
  música, sonido, y encima la personalización del avatar.
- **Si falta espacio** (teléfonos chicos), el carril de bolas
  y la barra de potencia se ocultan; las bolas restantes se
  ven bajo el nombre y, en el primer tiro, en un pop-up
  abajo a la derecha.
- **Rendimiento:** corre fluido en teléfonos modestos; mesa
  3D realista, bolas brillantes, texturas detalladas, luz
  cuidada, sonido de rotura y rodado.

### A2. Inicio y salas
- **Arriba:** perfil (avatar, nivel, rating, XP) a la
  izquierda; monedas (con menú de monedas gratis), tacos,
  clasificaciones, tienda, dinero premium (difícil de
  conseguir), mensajes/noticias.
- **Centro, una acción gigante:** "Play 1 vs 1"; al lado,
  "Play With Friends" y torneos (secuencia de 3 partidas).
  También arena de práctica.
- **Abajo:** ajustes, caja de regalos (mandar/recibir
  monedas), tienda.
- **Salas por ciudad (21):** tarjetas grandes con arte de la
  ciudad, cuota de entrada y premio = el doble (el ganador
  se lleva todo). Ejemplos: Londres 50→100, Sídney 100→200,
  Moscú/Lisboa 500→1.000, Tokio 2.500→5.000, Las Vegas
  10.000→20.000, Osaka 100M→200M. Las salas altas se
  desbloquean subiendo de nivel; algunas tienen reglas
  especiales (cantar tronera en la 8, en todos los tiros,
  tiro con banda). Las mesas son personalizables (de pago);
  sin personalizar, cada sala muestra su mesa por defecto.
- **Tacos:** visibles al costado de la mesa en partida;
  tienen atributos (potencia, puntería, efecto, tiempo) y
  variantes en la Pool Shop. La personalización es identidad
  del perfil.

### A3. Tienda, recompensas y social
- **Pool Shop:** tarjetas con arte del objeto, precio y
  estado (comprado/equipado); tacos y mesas temáticas,
  packs, colecciones, tienda de lealtad, Pool Pass (tareas
  → recompensas).
- **Recompensas:** diarias, eventos, tareas del pase,
  minijuegos (caja sorpresa, ruleta, rasca, Lucky Shot);
  pantalla de victoria con animación de monedas, trofeos
  y tacos exclusivos; subir de nivel desbloquea salas.
- **Social actual (versión 56.32, oct-2026):** animar
  ("CHEER") a amigos, ESPECTAR partidas, racha diaria.
  Regalos de monedas entre amigos, mensajes, desafíos.
- **Lenguaje visual:** UI oscura (azul noche) + dorado de
  las monedas + paño verde; botones primarios grandes y
  redondeados; tarjetas de sala como protagonistas; iconos
  circulares para acciones secundarias.

## B. Principios de traducción a Cacho

1. **Jerarquía, no mecánica.** De 8BP se trae cómo se
   ORDENA la pantalla (premio siempre visible, una acción
   primaria gigante, herramientas abajo al alcance del
   pulgar), nunca la mecánica del taco (Cacho no apunta).
2. **La consola YA es nuestra "barra de potencia".** El
   equivalente al tiro es armar la apuesta: tocar pintas
   (+1), atajos y APOSTAR. Todo lo que la haga más
   táctil y legible suma; nada que la complique suma.
3. **12 jugadores ≠ 1v1.** No existe "espejo arriba" en
   Cacho: la mesa es redonda, yo al centro abajo, 11
   rivales alrededor. El premio no va entre dos avatares:
   va en una píldora de pozo arriba al centro, con fichas.
4. **Vertical y una mano, siempre.** 8BP juega en
   horizontal; Cacho es vertical. Nada de lo que pida dos
   manos, giros ni puntería fina entra.
5. **Sin niveles ni dinero real.** 8BP vive de XP, niveles
   y tienda con dinero real. Cacho: sin cuentas, sin
   dinero real, sin XP inventada. Solo contadores reales
   (saldo, racha, victorias) y cosméticos con monedas
   del juego.
6. **Sin copiar.** Nada de arte, logo, bola 8, taco ni
   sonidos de Miniclip; nada de reglas especiales por
   sala (las reglas de Cacho son cerradas y parejas).

## C. Propuestas concretas (para el tribunal)

### Inicio (hoy: logo, 3 tarjetas, sin scroll — NO se rompe)
- **B1. Barra superior con saldo + racha.** Arriba, junto
  a "Hola, Jugador": saldo con icono de moneda (ya existe
  en la tarjeta de apuesta) y, desde Fase C, la llama de
  racha con su número. Referencia: barra superior de 8BP
  (perfil + monedas siempre visibles).
- **B2. Tarjeta diaria "Rescate del día".** El rescate
  +1.000 actual deja de esconderse: tarjeta visible en el
  inicio cuando el saldo no alcanza la mínima, con el
  botón "Rescatar" y, desde Fase C, el contador de racha.
  Referencia: recompensas diarias de 8BP.
- **B3. Botón primario gigante único por tarjeta.** Las 3
  tarjetas actuales ya son grandes; unificar su estilo:
  dorado degradado, 56 px mínimo, etiqueta + icono, como
  el "Play 1 vs 1" de 8BP. Sin cambiar su orden ni su
  texto (mandato: inicio sin scroll).
- **B4. "Revancha" en la pantalla de victoria.** Al
  terminar, además de salir: botón dorado "OTRA VEZ" que
  rearma la misma sala (mismos jugadores/bots, misma
  apuesta) en un toque. Referencia: el bucle rápido de
  8BP (terminar → jugar otra). Local primero; en línea
  requiere que todos acepten (queda como propuesta
  condicionada).

### Lobby y salas
- **B5. Tarjetas de sala con arte + premio.** En el lobby
  (y en la lista de salas si se agrega), cada sala muestra:
  miniatura de su mesa, nombre de tier (Barrio/Salón/
  Casino/VIP/High Roller), apuesta y pozo vivo según
  jugadores actuales (el lobby YA muestra apuesta y pozo;
  se le suma el arte y el nombre). Referencia: tarjetas
  de ciudad de 8BP (arte + cuota + premio).
- **B6. Filtro por tier.** Chips arriba del lobby/lista:
  Todos / Barrio / Salón / Casino / VIP / High Roller.
  Referencia: selección de sala por cuota en 8BP.
- **B7. Selector de mesa en la creación.** Al crear sala
  (y en la hoja local), 3 miniaturas elegibles: El Pub,
  Casino Dorado (por defecto, D1), Neón Nocturno. La mesa
  viaja con la sala y se ve igual para todos.
  (Ya está en Fase A; el brainstorm lo confirma.)

### Mesa de partida (el corazón)
- **B8. Píldora de pozo siempre visible.** Arriba al
  centro, bajo la barra de sala: pila de fichas + "Pozo:
  X" en vivo (apuesta × jugadores). Al ganar, esa pila
  vuela hacia el ganador (animación corta). Referencia:
  el premio al centro de 8BP. Solo visual: montos y
  reparto no cambian.
- **B9. Banner de turno más grande.** El "¡TU TURNO!"
  actual crece a pastilla protagonista (dorada, con el
  aro semáforo ya existente) y el turno ajeno queda
  sobrio con el nombre. Referencia: "YOUR MOVE" de 8BP.
- **B10. Carril de dados restantes.** Bajo cada asiento
  ya hay pipas; se unifica el estilo: mini-dados marfil
  iguales para todos (hoy son puntos) y, en mi asiento,
  el número grande de dados que me quedan. Referencia:
  el carril de bolas de 8BP y su "bolas bajo el nombre".
- **B11. Consola más táctil.** Cada toque en una pinta:
  tick háptico + destello; mantener presionada una pinta
  suma de a uno rápido (como tirar de la barra de
  potencia); los atajos del master prompt (+1 cantidad /
  misma cantidad pinta mayor) se vuelven chips grandes
  visibles, no escondidos. La consola NO cambia de
  contenido ni de reglas, solo de tacto.
- **B12. Chip de probabilidad (ayuda para
  principiantes).** En la consola, un chip "?" que
  muestra la probabilidad binomial de la apuesta armada
  (la ayuda del master prompt, hoy opción): "Tienes ~X%
  con tus dados + mesa". Solo informativa, nunca juega
  por ti. Si no está construida, queda como propuesta
  condicionada a su construcción.
- **B13. Botón de ajustes único en partida.** Los
  botones actuales (historial, glosario, sonido) se
  agrupan bajo un engranaje arriba a la derecha, como
  el de 8BP, con una hoja: música, sonido, efectos,
  micrófono, reglas. Menos botones sueltos en la barra.

### Victoria, derrota y estadísticas
- **B14. Pantalla de victoria con datos reales.**
  Lluvia de monedas actual + pozo contado + una fila de
  datos REALES de la partida: dados quitados, faroles
  (Dudos ganados), calzos acertados. Sin inventar nada:
  si un dato no se guarda aún, no se muestra hasta
  Fase C. Referencia: pantalla de victoria de 8BP
  (monedas + trofeo + stats).
- **B15. Perfil con identidad, sin niveles.** Hoja de
  perfil: apodo, saldo, racha (Fase C), victorias reales,
  vaso y dados equipados, marco. Sin XP, sin nivel, sin
  rating inventado. Referencia: perfil de 8BP menos su
  sistema de niveles.

### Tienda (Fase B, dentro de Personalizar)
- **B16. Tarjetas de tienda estilo Pool Shop.** Cuadrícula
  de tarjetas: render del objeto (vaso/dado/marco/
  celebración), nombre, precio en monedas, estado
  ("Equipado" dorado / "Comprar"). Tocar = vista previa
  en mi vaso/asiento. Referencia directa: Pool Shop.
- **B17. Vista previa en vivo.** Al tocar un vaso o
  dados en la tienda, mi asiento de la mesa de fondo
  (o un vaso de muestra) cambia al instante, antes de
  comprar. Sin comprar a ciegas.

### Torneos, racha y espectador (Fase C)
- **B18. Hoja de torneo: puntos y progreso.** En serie
  de 3 (D3): puntos en vivo (1º 10, 2º 7, 3º 5, resto 2),
  puntos de progreso (●●○) y tabla al terminar cada
  partida. Campeón con marco cosmético (no monedas).
  Referencia: torneos de 3 partidas de 8BP.
- **B19. Espectador con aplauso.** Botón "Mirar" en
  salas en curso: mesa visible, sin manos ajenas, sin
  consola, sin micrófono; botón de aplauso (1 cada
  10 s) y contador real de espectadores. Referencia:
  CHEER + SPECTATE de 8BP (oct-2026).
- **B20. Reacciones rápidas (PROPUESTA POLÉMICA).**
  Tres gestos flotantes sobre el asiento (pulgar,
  risa, sorpresa) para celebrar o picar, con botón de
  silencio por sala. Riesgo: choca con "sin textos
  narrativos" (no son textos, pero son ruido) y con
  "nada de emojis como iconos" (no son iconos de UI,
  pero se parecen). Va al tribunal como la propuesta
  más discutible; si el tribunal la rechaza, cae sin
  tocar nada más.

### Sonido y rendimiento
- **B21. Fanfarria por tier.** Victoria en Barrio:
  tintineo simple; en Casino: fanfarria actual; en
  High Roller: fanfarria larga + lluvia mayor. Mismo
  sistema de sonido, distinta intensidad. Referencia:
  la escalada de recompensas de 8BP.
- **B22. Modo ligero para Neón.** La mesa Neón tiene
  interruptor automático: si el teléfono baja de
  60 fps o está activo "efectos reducidos", se apaga
  el brillo y queda paño oscuro + acento mínimo.
  Referencia: 8BP corriendo en teléfonos modestos.

## D. Lo que NO se copia (lista de rechazo previa)

- Arte, logo, bola 8, taco, colores exactos ni sonidos
  de Miniclip. Nada de "8 Ball" en ningún texto.
- Tienda con dinero real, monedas premium ni cajas
  aleatorias pagadas (las sorpresas de 8BP son azar
  pago; en Cacho todo se compra directo con monedas
  del juego y precio visible).
- Niveles, XP, rating ni salas bloqueadas por nivel
  (las 5 salas de Cacho se abren por saldo, no por
  nivel; el que no puede pagar, rescata, como hoy).
- Reglas especiales por sala (cantar tronera, etc.):
  las reglas de Cacho son unas y parejas para todos.
- Layout 1v1, horizontal, puntería y potencia: Cacho
  es vertical, de hasta 12, y se juega con la consola.
- Textos narrativos en partida, emojis como iconos de
  UI, botones menores de 44 px, contraste bajo 4.5:1.

## E. Priorización sugerida para el tribunal

- **Ya en Fase A, confirmar:** B5, B6, B7, B8.
- **Fase A si el tribunal lo ve barato:** B3, B9, B10.
- **Fase B:** B16, B17 (B1 y B2 si no cuestan).
- **Fase C:** B14, B18, B19 (B12 si falta construir
  la ayuda; B21 es barata en cualquier fase).
- **Discutibles, que el tribunal decida:** B4 (revancha
  en línea), B13 (reagrupar botones), B20 (reacciones),
  B11 (mantener presionado para sumar rápido).
