# MASTER PROMPT: CACHO, EL DUDO CHILENO (VERSIÓN CASINO ANIMADO)

Texto íntegro entregado por el usuario el 26-oct-2026 ~07:25. Guardado verbatim.

La imagen adjunta es el DISEÑO OBJETIVO de la mesa. El resultado debe verse como ella, con acabado de juego de casino móvil profesional, y en esa mesa casi todo se mueve: el 70-80% de la experiencia es animación, efectos y sonido. Si la pantalla se ve estática, el trabajo no está terminado.

=== 1. HERRAMIENTAS (úsalas) ===
- Motor: Unity (C#), para app móvil iOS y Android. Si propones otro motor, justifícalo antes de empezar.
- Blender: modela y anima los assets 3D (mesa, vasos de cuero, dados, fichas, velas, vasos de licor) y expórtalos en FBX o glTF. Hornea las texturas y las luces en lo posible para que rinda en celular.
- Unity: Animator y Timeline para las secuencias, Cinemachine para las cámaras, Particle System o VFX Graph para efectos, DOTween para la UI, y un shader propio para el brillo del paño y el cuero.
- Arte 2D (avatares, logo, íconos): generado con IA y limpiado, siempre original.
- Audio: efectos y música de taberna de casino, con volumen separado para música y efectos.
- Vibración háptica en los momentos clave.

=== 2. DISEÑO DE LA MESA ===
- Horizontal, como el mockup: óvalo de madera oscura con borde grueso, paño oscuro con textura, taberna cálida desenfocada de fondo y logo grabado "CACHO O DUDO" en dos líneas.
- Exactamente 5 jugadores: 1 arriba al centro, 2 a la izquierda, 2 a la derecha, y yo abajo al centro. Mide las posiciones sobre el mockup, en porcentajes de la pantalla.
- Cada jugador: avatar redondo con aro de color, placa debajo con nombre, fichas y nivel, y un vaso de cuero delante. Mi vaso es más grande.
- Pozo arriba al centro, con su monto. Apuesta actual y quién la hizo, siempre visibles.
- Mis dados están ocultos bajo el vaso y solo se ven al tocar VER o al agitar el celular.
- Barra superior: fichas y dinero con "+", y amigos, regalo, dados, misiones y menú.
- Barra inferior: título APOSTAR, fila de dados 1 al 6 (cada toque suma 1 a esa cara; 4 toques al 6 = 4 Sextas; sin − / +), luego CALZO verde, DUDO rojo y PASO gris azulado, y botón de chat.
- Los dados 1–6 de la barra son solo botones, no mis dados reales.
- Nada se superpone ni se sale del óvalo.

=== 3. CATÁLOGO DE ANIMACIONES (obligatorio) ===
Cada acción del juego tiene su animación, sonido y vibración.

Ambiente (siempre en movimiento)
- Llama de vela que parpadea, polvo flotando en la luz, humo suave, reflejos que se mueven en el paño y el borde de madera.
- Avatares con respiración, parpadeo y reacciones (sonríen, se asustan, se burlan, se enojan).
- Aro del jugador en turno con pulso de luz y una cuenta regresiva visible.

Inicio de ronda
- Los vasos se sacuden con fuerza, los dados rebotan adentro con sonido, y los vasos se posan en la mesa con un golpe.
- Mi vaso se agita en mi mano (o con el movimiento real del celular) y apoya con un golpe seco.

Mis dados
- VER: mi vaso se levanta un poco y la cámara se acerca a mis dados, con luz cálida. Al soltar, el vaso baja y se tapa.

Apuesta
- Al tocar un dado de la barra, rebota, brilla y sube el contador con un "tic" de cuenta.
- Al confirmar, una burbuja con la apuesta ("4 Sextas") vuela hasta el centro de la mesa con un destello.
- Las fichas del jugador vuelan al pozo, y el pozo crece con animación de monedas.

PASO
- Mi vaso se mueve con un gesto de "mira, yo paso", con aviso dramático en pantalla.

CALZO
- Foco verde sobre el jugador, música con tensión y cámara que se acerca.
- Acierto: lluvia de chispas verdes y gana un dado (se suma con animación).
- Fallo: el dado se rompe o se desvanece, con pantalla roja suave.

DUDO (el momento estrella)
- Pausa dramática de un segundo, la música baja y se oye un latido. La cámara hace zoom a la mesa.
- Todos los vasos se levantan uno por uno, en secuencia, con un golpe de cámara lenta y rebote.
- Los dados caen sobre el paño con físicas reales, pero el resultado ya está decidido (ver sección 5). Los dados que cuentan se iluminan uno a uno con un contador, y los que no cuentan se apagan.
- Veredicto con una gran animación: el que perdió pierde un dado, que sale volando y se rompe, con pantalla y sonido de golpe. El que ganó recibe fichas y brilla.

KAMIKAZE
- Secuencia propia y espectacular: pantalla roja, sirena, el jugador elige el número con una ruleta y todos los vasos tiemblan.
- Los dados caen en cámara lenta, y los que coinciden explotan y salen disparados.

Eliminación y fin de partida
- Eliminado: su avatar se apaga, su vaso rueda fuera de la mesa y se oye un silbido de decepción.
- Victoria: lluvia de monedas, confeti, haz de luz sobre el ganador y fichas que vuelan a mi saldo con contador. Muestra experiencia, nivel y cofre ganado.

UI general
- Botones con rebote al apretar, brillo al pasar, contador de números que cuenta hacia arriba, cuenta regresiva con pulso, cambios de pantalla con transiciones fluidas, y todo con efecto de profundidad.

Lobby y menú
- Carrusel de mesas con parallax, tarjetas que respiran y destellos.
- Cofres que se abren con animación y efectos.
- Ruleta o regalo diario animado.
- Subir de nivel o de liga con una celebración.
- Logo CACHO con brillo animado.

=== 4. REGLAS DE LA ANIMACIÓN ===
- Ninguna animación bloquea el juego más de lo necesario: toda secuencia se puede saltar con un toque, y hay ajuste de velocidad (normal / rápido).
- Hay una opción "animaciones reducidas" para celulares lentos o para quien lo prefiera.
- Cada jugador ve su propia vista: nadie ve mis dados hasta la revelación.
- Todas las animaciones respetan la lógica: la animación se adapta al resultado, nunca al revés.

=== 5. LÓGICA Y REGLAS DEL JUEGO (no cambiar) ===
- 5 dados por jugador bajo el cacho, que solo él ve. En cada turno se sube la apuesta o se dice DUDO o CALZO.
- ASES: entrar a ases cuesta la mitad (de 8 cuatros a 4 ases). Salir de ases es el doble +1 (de 4 ases a 9 de otra pinta).
- PASO: decir que tienes 5 dados distintos o un full (3+2). Solo se puede pasar con 5 dados. Los demás pueden dudar o calzar el Paso.
- CALZO: si acierta, recupera un dado; si falla, pierde uno. Solo si queda al menos la mitad de los dados en juego.
- KAMIKAZE: solo la primera vez que a un jugador le queda 1 dado. Elige un número del 1 al 6, todos lanzan y quien lo saque pierde esos dados. El dado del activador también se lanza. Los 1 no son comodín. Si todos quedan sin dados, pierden todos.
- Quien pierde todos sus dados queda eliminado.
- El resultado de los dados lo decide un generador aleatorio seguro (en el servidor en partidas online). Las físicas de los dados en pantalla se animan para que caigan en la cara que ya fue decidida.

=== 6. RENDIMIENTO ===
- 60 fps en celulares de gama media. Si no se logra, reduce partículas y sombras, no el diseño.
- Texturas en atlas, pooling de efectos, modelos con pocos polígonos, luces horneadas, y no dejes efectos activos fuera de pantalla.
- Mide batería y temperatura en una partida de 15 minutos.

=== 7. MENÚ, LOBBY Y PROGRESIÓN (etapa posterior) ===
- Menú: logo CACHO, partida guiada con 2 bots lentos, contra la máquina (sin internet), jugar con amigos (sala con código y bots) y cómo se juega con glosario.
- Lobby con carrusel de mesas: La Taberna 500, El Boliche 2.000, El Casino 10.000, La Mansión 50.000, El Club VIP 250.000. Las caras con candado y "NIVEL X".
- Ligas por rango, racha con multiplicador, cofres, misiones diarias, regalo diario y estadísticas.
- Bots de 3 niveles que farolean y dudan de forma creíble.
- Solo fichas virtuales, sin dinero real ni premios canjeables.

=== 8. ORIGINALIDAD (OBLIGATORIO) ===
Nombres, avatares, íconos, fichas, logos, sonidos y textos propios e inventados (personajes chilenos tipo Don Chalo, La Cuca, El Guatón, La Pituca). NO copies nada de Monopoly Poker, Parchisi Star, 8 Ball Pool ni de ningún otro juego, ni los nombres ni las caras del mockup.

=== 9. VERIFICACIÓN ===
En cada etapa, antes de responder:
1. Compara tu captura con el mockup: proporciones, colores, sombras, posiciones.
2. Graba un video corto con las animaciones y revisa que no haya cortes ni saltos de fps.
3. Dime qué diferencias quedan, de la más visible a la menos.

=== 10. ORDEN DE TRABAJO ===
1. Assets 3D en Blender y la mesa en Unity, idéntica al mockup.
2. Inicio de ronda, mis dados, apuesta y pozo con sus animaciones.
3. DUDO, CALZO, PASO, KAMIKAZE, eliminación y victoria, con todo el espectáculo.
4. Bots y reglas completas.
5. Tutorial y partida guiada.
6. Menú, lobby y progresión.
7. Sala con amigos.
No avances a la siguiente etapa hasta que yo apruebe la anterior.

---
Nota final del mensaje (instrucción para Muse, no parte del prompt numerado):
"Ojo con un cambio importante: hoy pruebas tu juego en cacho.pages.dev, que es web. Con Unity pasas a una app nativa, así que probarás con un APK en Android o con TestFlight en iPhone (esto último pide Mac y cuenta de desarrollador de Apple). Antes de que Muse empiece, pregúntale cómo vas a probar cada avance."

---
NOTA DE REGISTRO (GOD, 26-oct-2026 ~07:25, no parte del prompt del usuario):
- Guardado verbatim como docs/18-master-prompt-casino-animado.md. NO iniciado: pendiente la pregunta de prueba (APK vs TestFlight) que la nota final exige hacer ANTES de empezar, y pendientes de confirmación suya los giros grandes (motor Unity nativo vs Flutter web actual en cacho.pages.dev; exactamente 5 jugadores vs máximo 8 vigente; mis dados ocultos + VER/agitar vs visibles y legibles hoy; barra superior con +/amigos/regalo/misiones; lobby §7 con montos 500/2000/10000/50000/250000 vs tiers cerrados 100/250/500/1000/2500; reglas §5 vs decisiones cerradas implementadas, p. ej. Calzo y Kamikaze). Nada de este prompt reemplaza docs/17 ni las decisiones cerradas hasta que él lo confirme. El frente horizontal Flutter en marcha NO se detuvo por este mensaje; su destino depende de su respuesta sobre Unity vs Flutter.
