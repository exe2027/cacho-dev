# MASTER PROMPT: CACHO, EL DUDO CHILENO (recibido 2026-10-25 08:12)

> Nota de registro (no parte del prompt original): orden posterior del mismo
> día 08:12 — la imagen adjunta (bosquejo) es el DISEÑO OBJETIVO, no una
> inspiración, es la meta; la pantalla de partida debe quedar visualmente
> idéntica y NO se avanza a nada más hasta lograrlo, en orden: (1) borrar el
> diseño actual de la mesa, (2) reconstruir la mesa copiando la composición
> del mockup, (3) reconstruir la barra inferior igual al mockup, (4)
> reconstruir la barra superior, (5) avatares/nombres/íconos propios, sin
> copiar nombres ni caras del mockup. Reglas de ese orden: comparar lado a
> lado y corregir antes de responder, no mezclar con el diseño anterior, no
> inventar elementos que no estén en el mockup, NO tocar las reglas del
> juego, y al terminar decir qué diferencias quedan. Las reglas del juego
> NO se cambian con este documento: el §2 es un resumen y la orden posterior
> dice explícitamente no tocarlas (las reglas vigentes son las decisiones
> cerradas, p. ej. Calzo con recuperación bloqueada, máximo 8 jugadores).

Eres el desarrollador de mi app móvil "Cacho" (Dudo chileno, 5 dados por jugador). Termina el juego completo siguiendo este documento. Trabaja por etapas y no avances a la siguiente hasta que la anterior funcione.

=== 1. VISIÓN ===
Juego de mentiras y faroleo con estética de taberna/casino oscuro: madera, paño oscuro, cuero y dorado. Debe sentirse como un juego de casino móvil pulido, con progresión (niveles, ligas, cofres), pero con identidad chilena.

=== 2. REGLAS (no cambiar) ===
- Cada jugador tiene 5 dados bajo su cacho (vaso de cuero), que solo él ve.
- Cada turno se sube la apuesta (más cantidad o mayor pinta) o se dice DUDO o CALZO.
- ASES: entrar a ases cuesta la mitad (de 8 cuatros a 4 ases). Salir de ases es el doble +1 (de 4 ases a 9 de otra pinta).
- PASO: decir que tienes 5 dados distintos o un full (3+2). Solo se puede pasar con 5 dados. Los demás pueden dudar o calzar el Paso.
- CALZO: si acierta, recupera un dado; si falla, pierde uno. Solo se puede calzar si queda al menos la mitad de los dados en juego.
- KAMIKAZE: solo la primera vez que a un jugador le queda 1 dado. Elige un número del 1 al 6; todos lanzan, y quien lo saque pierde esos dados. El dado del activador también se lanza. Los 1 no son comodín. Si todos quedan sin dados, pierden todos.
- Quien pierde todos sus dados queda eliminado.

=== 3. MESA (pantalla de partida, horizontal) ===
- Óvalo de madera oscura con paño negro/gris oscuro y fondo de taberna desenfocado. Logo grabado en el paño: "CACHO O DUDO".
- 5 jugadores: uno arriba al centro, dos a la izquierda, dos a la derecha y yo abajo al centro.
- Cada jugador: avatar redondo (aro verde si es su turno), placa con nombre, fichas y nivel, y un vaso de cuero delante.
- Pozo arriba al centro, con su monto.
- Mis dados NO están a la vista: se ven solo al tocar VER (o al agitar el celular). Los dados del centro se muestran solo al revelar un Dudo o Calzo.
- Siempre visible: la apuesta actual y quién la hizo ("4 Sextas, La Cuca").
- Barra superior: fichas y dinero con "+", amigos, regalo, dados, misiones y menú.
- Barra inferior: título APOSTAR y fila de dados 1 al 6, donde cada toque suma 1 a esa cara (4 toques al 6 = 4 Sextas; sin botones − / +). Botones grandes y separados: CALZO (verde), DUDO (rojo), PASO (gris azulado). Botón de chat abajo a la izquierda.
- Los dados 1–6 de la barra son solo botones para apostar, no mis dados reales.

=== 4. MECÁNICA DE LANZAMIENTO ===
- Se presiona un botón de girar o se agita el celular, y caen dados aleatorios bajo mi cacho con animación y sonido.
- Los resultados se generan en el servidor o en un generador seguro, nunca en el cliente de otro jugador.

=== 5. MENÚ Y LOBBY ===
- Menú principal: logo CACHO (fondo transparente), saludo, fichas y botones: Primera partida guiada, Jugar contra la máquina (sin internet, con bots), Jugar con amigos (sala con código y bots), Cómo se juega (4 pantallas cortas y glosario).
- Lobby con carrusel de mesas por apuesta: La Taberna (500), El Boliche (2.000), El Casino (10.000), La Mansión (50.000), El Club VIP (250.000). Cada tarjeta muestra buy-in, pozo máximo y JUGAR AHORA. Las mesas caras aparecen con candado y "NIVEL X". Si no alcanzan las fichas: "FICHAS INSUFICIENTES".
- Avatar con nivel y barra de experiencia, fichas y gemas con "+".

=== 6. PROGRESIÓN ===
Ligas por rango (Bronce, Plata, Oro...) con premio al subir, racha de victorias con multiplicador, cofres con tiempo de apertura, misiones diarias, regalo diario con cuenta regresiva y estadísticas (partidas ganadas, mejor racha, dudos y calzos acertados).

=== 7. MODOS ===
- Contra bots: 3 niveles de dificultad. Los bots deben farolear y dudar de forma creíble, y en la partida guiada son lentos y explican cada jugada.
- Con amigos: sala con código.
- Idea futura: Bluetooth local (no implementar aún).

=== 8. TUTORIAL ===
La jugabilidad actual es confusa para quien no conoce el juego. Haz una partida guiada con 2 bots lentos, con indicaciones paso a paso (qué es apostar, dudar, calzar, pasar) y un glosario accesible desde la mesa.

=== 9. ORIGINALIDAD (OBLIGATORIO) ===
Usa nombres, avatares, íconos, fichas, ilustraciones y textos propios e inventados (personajes chilenos tipo Don Chalo, La Cuca, El Guatón, La Pituca). NO copies nombres, logos, personajes ni íconos de Monopoly Poker, Parchisi Star, 8 Ball Pool ni de ningún otro juego. Las referencias inspiran la estructura, no los assets.

=== 10. CALIDAD ===
- Funciona bien en celular, horizontal y vertical.
- Nada se superpone ni se corta; botones táctiles grandes.
- Animaciones suaves, sonidos de dados y cacho.
- Revisa que ninguna regla de la sección 2 se rompa.

=== ORDEN DE TRABAJO ===
1. Mesa (sección 3) con una partida jugable contra bots y todas las reglas.
2. Tutorial y partida guiada.
3. Menú y lobby.
4. Progresión.
5. Sala con amigos.
Al terminar cada etapa, dime qué quedó hecho y qué falta.
