MASTER PROMPT: REDISEÑO DE LA MESA Y ANIMACIONES DE CACHO (SOLO WEB)

0. REGLA MAESTRA
Replica EXACTAMENTE lo que se pide aquí y en el spec de Cacho vigente. No inventes reglas, montos, textos ni funciones. Si algo no está especificado, no lo agregues: anótalo como PENDIENTE. Este trabajo es SOLO capa visual: no cambies motor, servidor, protocolo WS, economía ni reglas. Solo web (la APK está congelada). La imagen de referencia adjunta es el bosquejo visual vigente.

1. OBJETIVO
Hoy la mesa tiene paño verde plano, 2 rivales arriba, un solo vaso, mi fila de dados con el avatar al centro y un PANEL LATERAL derecho "Tu apuesta". Debe pasar a la mesa de la referencia, con animaciones y acabado en lobby y diseño.

2. MESA (según la referencia)
a) Escena: fondo de pub oscuro con madera cálida y desenfoque suave. Mesa OVALADA en horizontal (844x390 de referencia), borde de madera con volumen, paño NEGRO/carbón (reemplaza el verde), "CACHO O DUDO" grabado al centro en trazo CaveatBrush tenue.
b) Asientos alrededor del óvalo: avatar circular de 56 px, placa con nombre y saldo, y número de dados en azul claro. Referencia: 2 arriba laterales, 2 a los costados, pozo arriba al centro, yo abajo al centro.
c) UN VASO DE CUERO POR JUGADOR sobre la mesa (rivales incluidos), sobre un posavasos oscuro, orientado hacia su dueño. Mi vaso mantiene su animación propia (boca abajo/mouthDown, tamaños 1,0 y compacto 0,72).
d) Pozo arriba al centro, con su vaso, rótulo "Pozo" y monto REAL (potFixed). Los números de la imagen (132.000, 480.000, etc.) son solo maqueta.
e) Dados sueltos al centro SOLO al revelar. En la imagen aparecen de ejemplo: no deben verse fuera de la revelación.
f) Mi fila de dados: dos grupos con hueco de 104 centrado sobre mi avatar (floor(n/2) izquierda, ceil(n/2) derecha). Medidas: dados mano 44, tiles 48, revelación 44, chips 22; radio de pipa 0,11; As 0,14 rojo.

3. CONSOLA INFERIOR
- Una sola barra con borde redondeado: grupo "APOSTAR" con las 6 pintas 1–6 como tiles, más CALZO verde #0E7A4F, DUDO rojo #B3202A y PASO #14586B, con iconos de dado/pausa sin emojis.
- Las tiles SON los controles: cada toque suma +1 a esa pinta; otra pinta reinicia en 1; tope = total de dados en mesa; legalidad vía raiseError. Atajos +1 y subir pinta, sin mantener presionado.
- Botón APOSTAR dorado mate #C9A24B con texto #2B1810 y etiqueta "Apostar N × Pintas", inerte si la apuesta armada es ilegal. La referencia no lo muestra pero el spec lo exige: ubícalo dentro de la barra sin romper la composición y repórtalo como decisión pendiente de mi aprobación.
- Se abre sola en mi turno (fase playing, sin resolución en pantalla, sin haberla cerrado). Botón X para cerrarla.
- Con un Paso pendiente contra mí: PasoChallengeBar sobre la consola (calzar, dudar o apostar sobre la apuesta anterior).
- Chip de probabilidad de 44 px, APAGADO en Kamikaze a ciegas.
- El panel "Tu apuesta" NO se elimina: se despliega con un icono junto a los dados ordenados del 1 al 6 en la consola. Por defecto plegado; al tocar el icono se despliega, y al tocarlo de nuevo se vuelve a plegar, sin tapar las tiles ni los botones de acción.

4. BARRA SUPERIOR
Saldo a la izquierda, accesos a la derecha. Conserva SOLO lo que ya existe (Salir, saldo, Pozo, ajustes, historial, música/DJ, mic, chat si ya existe). NO implementes lo que la referencia muestra pero el spec prohíbe: segunda moneda "$0", botones "+" de compra, regalo, objetivo, corona, LVL, gemas, bundles, SALE, la palabra PREMIO (siempre POZO).

5. LO QUE NO CAMBIA
- Colores y botones: dorado mate #C9A24B solamente; secundarios cuero #3E2312; presionado 8% más oscuro; deshabilitado 30%/50% sin desaparecer. Cian solo en la mesa Neón.
- Fuentes CaveatBrush (logo), Cinzel, Montserrat. Texto >= 14 px, objetivos táctiles >= 44 px, contraste >= 4,5:1, radios 28/16/12.
- Semáforo del turno: >= 0,5 verde, >= 0,25 ámbar #F2B705, si no rojo casino. En mi turno el círculo ENTERO del avatar toma el color; barra fina con los mismos colores; 3 pitidos (880 Hz) a los 3, 2 y 1 s solo en mi turno.
- Sin narración en partida: solo píldora de turno, tira de desafío de Paso y avisos cortos del servidor.
- Revelación: scrim negro 0,96, tarjeta navyCard 0xFF141B28, auto-cierre 3000 ms, veredicto = consecuencia solamente.
- Kamikaze a ciegas: vaso forzado cerrado, lift 0, sin peek, sin pista.
- Chip ámbar "m:ss para volver" por desconexión; insignia de mic; temas de mesa (El Pub, Casino Dorado defecto, Neón Nocturno): el paño oscuro de la referencia es el de Casino Dorado, los otros conservan su identidad.
- Prohibido copiar arte, marca, avatares o textos de la referencia (JeffEpstein, Wills, qiddy, etc. son solo maqueta): usa los avatares y nombres de bots del spec.

6. ESCALABILIDAD Y RESPONSIVE
- 2 a 12 jugadores: distribuye asientos alrededor del óvalo con el mismo lenguaje, sin que los vasos tapen avatares, nombres ni el centro. Mide solapes en capturas y reporta si no cabe con 7+ jugadores.
- Verifica en horizontal 844x390, escritorio y móvil 390x844. Si en vertical la mesa no cabe, propón la adaptación y repórtala antes de darla por buena.
- Safari iOS: la barra del navegador reduce el alto útil; respeta safe areas.

7. ANIMACIONES Y ACABADO (lobby y diseño primero)
REGLAS DURAS
- Solo fuera de la partida en curso: Home, Lobby, Personalizar, entradas/salidas y resultados. La mesa en turno NO gana animación nueva. Prohibido barrido de turno.
- Todo se apaga con animationsEnabled (Personalizar y ajustes de partida), salvo semáforo, barra de turno y pitidos, que nunca se apagan. Respetar "reducir movimiento" del sistema.
- 60 fps en iPhone con Safari; si baja, simplifica y repórtalo. Duraciones 150–600 ms salvo las ambientales; curvas suaves, sin rebotes exagerados. Sin audio nuevo.

A) LOBBY (prioridad), con el mismo mundo visual de la mesa nueva (pub oscuro, madera, paño negro, dorado mate):
1. Telón de entrada y cortinas al pasar a la mesa (omitidos en rejoin).
2. Pop de lobby: el jugador que se une entra con escala 0,8→1 y destello dorado corto; al salir se desvanece.
3. Pulso suave del aviso de sala activa y del código de sala.
4. Dados girando al conectar.
5. Fichas al elegir apuesta (StakePicker y tarjeta de apuesta).
6. Rodillo de dígitos del pozo, siempre con el potFixed real.
7. Ecualizador en la barra de música cuando suena algo.
8. Vaso que se posa al entrar a la mesa (600 ms, una vez por sesión, nunca en rejoin).
9. Chip "listo" del asiento: transición de color al marcar set_ready, sin textos nuevos.
10. Saldo insuficiente: sacudida corta (una vez) de la tarjeta de apuesta.

B) DISEÑO / AMBIENTE (Home, lobby, Personalizar)
Aprobadas: barrido del logo, shimmer dorado, partículas doradas, moneda de rescate (12 cuadros de giro). Extras permitidos (solo ambiente, no alteran información):
- Luz cálida de lámpara/vela del fondo con parpadeo muy lento y de baja amplitud (Home y lobby, nunca en la mesa).
- Parallax leve del fondo pub en Home (apagable).
- Transición entre pantallas: fundido con leve deslizamiento (200–300 ms).
- Botones: escala 0,97 al presionar; en escritorio, brillo dorado en hover/foco.
- Selector de tema de mesa en Personalizar: la miniatura elegida sube 4 px y gana borde dorado; cambio con fundido cruzado.
- Aparición escalonada (60 ms) de tarjetas del Home y filas del lobby.

C) RESULTADOS
Victoria ampliada: confeti máx 40 piezas, lluvia de monedas, "TE LLEVASTE EL POZO" + coins(). Fichas retiradas al eliminado. La revelación no recibe efectos extra.

D) NO IMPLEMENTAR (solo proponer con boceto y esperar mi aprobación)
Cuenta regresiva 3-2-1 al partir, emotes/reacciones, cualquier animación dentro de la mesa durante una ronda, cosméticos con compra.

8. PLAN DE TRABAJO
1. Lee el código actual de Mesa, consola, lobby y tema; lista los archivos a tocar y el plan por fases.
2. Fases: (a) escena y mesa, (b) asientos y vasos, (c) consola inferior, (d) barra superior, (e) revelación y estados especiales, (f) 7–12 jugadores, (g) animaciones de lobby y diseño.
3. Implementa fase por fase, con captura real al terminar cada una.

9. CRITERIOS DE ACEPTACIÓN
- Motor Dart, tests de app y tests de servidor en verde; analyze limpio; build web fresco.
- Capturas reales (escritorio y móvil 390x844) de: mesa en espera, mi turno con consola, apuesta armada, Paso pendiente, revelación, Kamikaze a ciegas, 6 y 12 jugadores, lobby con unión de jugador, Home. Cada afirmación visual con su captura.
- Comparación lado a lado con la referencia y lista de diferencias deliberadas.
- Tabla de animaciones: animación | pantalla | duración | ¿se apaga con animationsEnabled? | captura o clip.
- Confirmar que semáforo, barra y pitidos siguen activos con animaciones apagadas, y que ninguna animación toca la mesa en turno.
- NO desplegar ni commitear sin mi aprobación expresa.

10. ENTREGA FINAL
Resumen de archivos cambiados, capturas, diferencias respecto a la referencia y lista de PENDIENTES (ubicación del botón APOSTAR, iconos de la barra superior no implementados, adaptación vertical, 7+ jugadores).

11. ENMIENDAS DEL USUARIO 25-oct ~03:54 -03 (mandan sobre lo anterior donde choquen)
a) Panel "Tu apuesta": NO se elimina. Se despliega con un icono junto a los dados ordenados del 1 al 6 en la consola (plegado por defecto, toggle al tocar el icono, sin tapar tiles ni botones).
b) Paño y sala según monto de apuesta: el paño y la sala cambian dependiendo del tier de apuesta (Barrio 100 / Salón 250 / Casino 500 / VIP 1000 / High Roller 2500). Cada tier tiene su variante de sala y paño; el paño negro de la referencia corresponde a Casino Dorado. Las variantes de los demás tiers se proponen con capturas y quedan pendientes de aprobación del usuario (no se dan por definitivas sin su sí). En partida, el tier manda sobre el selector de tema; la interacción con el selector queda como PENDIENTE.
c) Venta de gemas y monedas + cosméticos (alcance nuevo, fuera de esta pasada visual salvo ganchos de diseño): en la aplicación se venderán gemas y monedas. Las gemas son para personalizar el vaso de cacho y los dados. El vaso personalizado SÍ lo ven los contrincantes en la mesa; los dados personalizados NO los ven los contrincantes (solo el dueño ve sus dados personalizados; en dispositivos ajenos los dados se renderizan estándar). Los cosméticos se pagan con monedas y gemas. Precios, packs, proveedor de pago y si la venta es con dinero real o ganable quedan PENDIENTES de decisión del usuario: en esta pasada NO se construye el flujo de compra, solo se dejan los ganchos de diseño (vaso visible por jugador, dados propios personalizables) y se anota la tienda como alcance nuevo.
