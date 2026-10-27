# Casos de paridad Flutter–Unity — Cacho

Decisiones del usuario (26-oct-2026 ~07:32, mandan sobre lo anterior) + lista de casos que AMBAS versiones tienen que pasar. Nada de este documento cambia reglas por sí solo: registra lo que él decidió y lo que queda abierto.

## Decisiones finales 07:40 (aplicadas en este documento)

- **A1 Calzo:** se recupera solo si queda MÁS de la mitad (`totalActual × 2 > totalInicial`, estricto). C2 y C3 quedan como están. Cualquier prompt anterior que diga "al menos la mitad" (incluido docs/18 §5) está equivocado: vale esta regla.
- **A2 Reglas confirmadas del usuario, vigentes en Flutter y Unity, sin marca de pendiente:** P11 (máximo 1 Paso por jugador por ronda), P12 (Paso prohibido como primera jugada), P13 (Paso prohibido dos veces seguidas por el mismo jugador), C6 (Calzo perfecto, solo Calzo, no calzoPaso — C7).
- **A3 Resto de reglas:** todas las demás reglas del documento se mantienen; ambas versiones pasan todos los casos.
- **B4 Jugadores y dados:** 2 a 5 jugadores, puestos libres, mis dados ocultos y solo con VER.
- **B5 Agitar y VER, ambos quedan, con funciones distintas:** agitar el celular LANZA los dados; VER los mira.
- **B6 Revelación:** el centro muestra dados en CUALQUIER resolución (Dudo, Calzo, duda de Paso, Kamikaze). En duda de Paso, solo la mano del jugador del Paso (P9). En Kamikaze, todos los dados nuevos al resolver. V2 queda actualizada en consecuencia.
- **C7 Tiers:** se conservan los de Flutter (100/250/500/1.000/2.500) con los nombres nuevos, en orden: La Taberna 100, El Boliche 250, El Casino 500, La Mansión 1.000, El Club VIP 2.500 (porque el saldo inicial es 5.000).
- **C8 Barra superior:** por ahora solo fichas, ajustes y menú. Regalo, misiones y amigos se agregan cuando existan sus funciones, sin botones que no hagan nada.
- **C9 Chat fuera por ahora; se agregan reacciones rápidas (emotes) con animación.**
- **C10 Puestos vacíos en línea:** quedan libres, y al iniciar la sala el anfitrión elige entre completar con bots o jugar con los presentes.
- **D11 Flutter 8 → 5:** se aplica en el pase posterior al frente horizontal, como estaba previsto, sin romper el trabajo en marcha.
- **D12 Unity etapa 1:** sigue como está, con 5 asientos; cualquier diferencia nueva se anota sin resolver.
- **Corrección 09:35 (manda sobre 5 jugadores y sobre la revelación):** 6 jugadores máximo (eran 6, no 5), distribución del mockup con cero solapes; revelación legible (V5, layout anterior rechazado); micrófono (voz) y música/DJ se mantienen y deben estar visibles y funcionales en mesa — el chat de TEXTO sigue fuera, los emotes se quedan.

## Decisiones cerradas 07:32

1. **Jugadores: 5 como máximo, como el mockup (de 2 a 5 según la partida; los puestos vacíos quedan libres).** Reemplaza el máximo 8 vigente en Flutter (orden 25-oct 07:44). Alineación Flutter (motor, servidor, lobby, selector de bots, tests) queda ENCOLADA para el pase posterior al frente horizontal, para no romper el trabajo en marcha. Unity etapa 1 ya va con 5 asientos.
2. **Mis dados ocultos bajo mi vaso y solo se ven con VER. Los dados del centro se muestran solo al revelar Dudo o Calzo.** Reemplaza el estado Flutter actual (dados visibles y legibles junto al vaso). El manejo de la revelación en duda de Paso y en Kamikaze NO está resuelto aquí: queda en diferencias abiertas, no se asume.
3. **Reglas idénticas (ases, Paso, Kamikaze, Calzo).** La lista de abajo es la que ambas versiones tienen que pasar, caso por caso. Estado Flutter: implementado en motor Dart + servidor (suites actuales Dart 77/77, servidor 31/31); la verificación caso por caso de esta lista es trabajo del pase de paridad, no se da por hecha aquí. Estado Unity: pendiente, sin motor todavía.
4. **Cualquier otra diferencia que se encuentre, se anota y NO se resuelve por cuenta propia.** Sección final de este documento.

## A. Apuestas y Ases

- **A1 — Subida clásica:** subir cantidad con cualquier pinta, o misma cantidad con pinta mayor. Nunca bajar cantidad, nunca bajar pinta a igual cantidad.
- **A2 — Primera apuesta nunca ases:** la primera apuesta de la ronda no puede ser ases (error `ases_para_partir`); la UI atenúa el As al abrir.
- **A3 — Entrar a ases, ejemplo suyo:** de 8 Cuatros se pasa a 4 Ases (la mitad).
- **A4 — Entrar a ases, mínimo general:** entrar a ases exige al menos `ceil(N/2)` (N = cantidad de la apuesta vigente). Ejemplo: de 9 Quintas, entrar a ases exige al menos 5 Ases.
- **A5 — Salir de ases, ejemplo suyo:** de 4 Ases se sale a 9 de otra pinta (el doble + 1).
- **A6 — Dentro de ases solo sube la cantidad:** de 4 Ases vale 5 Ases; no vale volver a 4 Cuatros ni bajar.
- **A7 — Resolver apuesta de ases cuenta solo los 1 reales:** al resolver una apuesta de ases, solo cuentan los 1 de verdad.
- **A8 — Resolver otra apuesta, los 1 son comodines:** al resolver cualquier otra apuesta, los 1 cuentan como la pinta apostada.
- **A9 — Ases desactivados por sala:** con la regla apagada, el As es una pinta más, sin conversión ni comodines.

## B. Paso

- **P1 — Mano de Paso, distintos:** 5 dados todos distintos (el 1 cuenta como 1, sin comodines).
- **P2 — Mano de Paso, Full:** exactamente 3 + 2.
- **P3 — Paso solo con 5 dados:** no se puede pasar con menos de 5 dados.
- **P4 — Solo el siguiente puede dudar un Paso:** únicamente el jugador inmediatamente siguiente puede desafiarlo.
- **P5 — Si el siguiente juega, el Paso queda firme para siempre:** si el siguiente apuesta en vez de desafiar, el Paso ya no se puede cuestionar.
- **P6 — Dos Pasos seguidos, solo el último se puede desafiar:** con dos Pasos en fila, solo el último es desafiable.
- **P7 — Dudar un Paso verdadero:** si la mano SÍ es Paso, el que duda pierde el dado.
- **P8 — Dudar un Paso falso:** si la mano NO es Paso, el jugador del Paso pierde el dado.
- **P9 — En la duda solo se revela la mano del jugador del Paso:** no se revelan las demás manos.
- **P10 — Tras un Paso se puede calzar, dudar o apostar sobre la apuesta anterior:** el siguiente puede calzar, dudar el Paso o apostar sobre la apuesta del jugador anterior al Paso.
- **P11 — Máximo 1 Paso por jugador por ronda.**
- **P12 — Paso prohibido como primera jugada de la ronda.**
- **P13 — Paso prohibido dos veces seguidas por el mismo jugador.**
- **P14 — Paso declarado falso (farol):** se puede declarar un Paso falso; solo el desafío lo verifica.

## C. Calzo

- **C1 — Calzar siempre se puede intentar:** el intento de Calzo siempre está permitido.
- **C2 — Recuperar solo si queda más de la mitad, estricto:** se gana solo si `totalActual × 2 > totalInicial` (totales medidos antes de aplicar ganancia/pérdida; `totalInicial` = jugadores al inicio × dados por jugador, fijo aunque haya eliminados).
- **C3 — Calzar con la mitad, ejemplo suyo:** 4 jugadores = 20 iniciales; con 11 en juego se recupera, con 10 o menos NO se recupera.
- **C4 — Exacto pero sin recuperación:** exacto con total en la mitad o menos → sin ganancia ni pérdida, la ronda termina, el calzador parte la siguiente, y la resolución lleva la marca `recoveryBlocked` (veredicto "exacto pero sin recuperación").
- **C5 — Calzo inexacto:** el calzador siempre pierde un dado.
- **C6 — Calzo perfecto:** calzo exacto con los 5 dados → el calzador no gana nada y cada otro jugador vivo pierde 1 dado.
- **C7 — Perfecto solo con Calzo, no con calzoPaso:** el perfecto aplica a la apuesta Calzo, no al calzo de un Paso.
- **C8 — CalzoPaso usa la misma regla de recuperación:** misma fórmula estricta que el Calzo.
- **C9 — Calzo logrado:** quien calza con éxito parte la ronda siguiente (gane o no el dado, si nadie perdió: el calzador parte).
- **C10 — Toda resolución desafiada termina la ronda:** tras Dudo, Calzo o duda/calzo de Paso, todos vuelven a lanzar.
- **C11 — Calzo perfecto con total bajo, decisión final 07:43:** se aplica la misma regla de la mitad. Con la mitad de los dados o menos (`totalActual × 2 ≤ totalInicial`), un Calzo exacto no da ni quita nada, y el perfecto TAMPOCO hace perder dados a los demás (nadie gana ni pierde; la ronda termina y el calzador parte). Esto reemplaza la postura anterior ("el perfecto se mantiene aunque el total sea bajo", sin cierre): ahora el perfecto queda bloqueado con total bajo. Caso de prueba en ambas versiones; en Flutter exige ajuste del motor (Dart + servidor) en el pase de alineación.

## D. Kamikaze

- **K1 — Ofrecimiento entre rondas:** solo la primera vez que un jugador termina una resolución con exactamente 1 dado, siendo el ÚNICO jugador con 1 dado, y sin haber sido ofrecido antes.
- **K2 — Llegadas simultáneas a 1 dado:** si dos llegan a 1 a la vez, a nadie se le ofrece y la oportunidad NO se consume.
- **K3 — Rechazar es para siempre:** si declina, no se le vuelve a ofrecer.
- **K4 — Kamikaze a ciegas:** nadie —incluido el activador— ve ningún dado hasta que el activador elige el número; los dados son una tirada NUEVA dentro de la elección, revelada solo en la resolución.
- **K5 — El activador puede morir por su propio número:** el dado del activador también se lanza y puede matarlo.
- **K6 — Los 1 no son comodín en Kamikaze.**
- **K7 — Todos sin dados a la vez = empate:** si todos quedan sin dados a la vez, pierden todos (empate).
- **K8 — Tras el Kamikaze parte el activador si sigue vivo, si no el siguiente vivo en sentido horario.**
- **K9 — Kamikaze con todos eliminados, ejemplo suyo:** si el resultado deja a todos sin dados, es empate (caso K7 aplicado).

## E. Generales de ronda (paridad de motor)

- **G1 — Quién parte la ronda siguiente:** quien perdió un dado; si nadie perdió (Calzo exitoso), el calzador; si está eliminado, el siguiente vivo en sentido horario. Siempre anunciado con el motivo.
- **G2 — Primera ronda, sorteo visible:** se parte por dado mayor, empates vuelven a lanzar; visible como "Sorteo: parte X".
- **G3 — Tiempo de turno 60 s:** al vencer, juega un bot ese turno; 3 vencimientos seguidos → eliminación por abandono.
- **G4 — Desconexión en partida:** un bot cubre mientras tanto, aviso a toda la mesa, 60 s de gracia para volver; al volver se cancela, al vencer se elimina.
- **G5 — Eliminación:** quien queda sin dados queda eliminado; salir a mitad de partida pierde la apuesta.

## F. Dados ocultos / VER (paridad visual, decisión 2)

- **V1 — Mis dados ocultos bajo mi vaso:** solo se ven con VER.
- **V4 — Agitar y VER, ambos quedan:** agitar el celular LANZA los dados; VER los mira.
- **V2 — Dados del centro en cualquier resolución:** Dudo, Calzo, duda de Paso y Kamikaze. En duda de Paso, solo la mano del jugador del Paso (P9). En Kamikaze, todos los dados nuevos al resolver.
- **V5 — Revelación legible (corrección 09:35):** la presentación con todas las manos en pequeño al centro queda RECHAZADA porque no se alcanzan a leer. Todo dado que se muestre en una revelación debe leerse a tamaño real, sin solapes; los dados que cuentan se iluminan uno a uno.
- **V3 — Vista propia:** cada jugador ve solo su vista; nadie ve mis dados hasta la revelación.

## G. Jugadores (decisión 1)

- **N1 — Partidas de 2 a 6 jugadores en ambas versiones (corrección 09:35: eran 6, no 5; reemplaza la decisión 07:32 de 2–5).**
- **N2 — Puestos vacíos quedan libres:** los asientos sin jugador quedan libres, no se rellenan por defecto en la mesa.
- **N3 — En línea, el anfitrión elige al iniciar:** completar con bots o jugar con los presentes.
- **N4 — Distribución con 6 (corrección 09:35):** 1 arriba al centro, 2 a la izquierda, 2 a la derecha y yo abajo al centro (la del mockup), con CERO solapes medidos.

## Diferencias abiertas — ANOTADAS, NO RESUELTAS (decisión 4 + D12)

Resueltas por las decisiones finales 07:40 y 07:43 y ya NO abiertas: tiers (C7), barra superior (C8), chat/emotes (C9), puestos vacíos en línea (C10), agitar vs VER (B5), revelación en duda de Paso y Kamikaze (B6), Calzo "al menos la mitad" corregido a MÁS de la mitad (A1), P11/P12/P13/C6 confirmados como reglas del usuario (A2), perfecto con total bajo bloqueado por la misma regla de la mitad (C11, 07:43), ruta de prueba Unity = WebGL con link para iPhone, sin TestFlight todavía (07:43), APK Flutter descartada por su orden (07:43, no se reintenta), despliegue bloqueado hasta aceptación de mesa + pedido explícito (07:43), 9 JSON borrados 07:43 tras grep sin referencias (confirmación de build pendiente del próximo build verificado).

Siguen abiertas:

- **Aceptación de la mesa:** ni la etapa 1 Unity ni la mesa Flutter están aceptadas bajo el estándar de comparación con el bosquejo. Informe final con capturas + tribunal ronda 2 quedan encolados para cuando entreguen el frente horizontal y la etapa 1 Unity; la mesa NO se da por aceptada.
- **Detalles de mesa P1–P21:** APOSTAR, pozo centro o centro+barra, tamaño del vaso rival, y resto de pendientes del tribunal. Se resuelven en el informe final, no antes.
- **Auth Firebase + billetera nube, tienda de gemas/monedas, ranking y niveles:** siguen su secuencia propia (auth después de la mesa; tienda después de auth; fórmulas de ranking/niveles pendientes de sus decisiones). Emparejamiento sigue diferido por su orden.
- **Regla futura diferida:** todo jugador empieza con 10.000, solo después de terminar esto y con su confirmación.
- **Capturas vivas pendientes:** calzo bloqueado, Kamikaze a ciegas, AN6/AN12/AN13/AN14/AN18 en producción.
- **Confirmación de build tras el borrado de los 9 JSON:** CONFIRMADA por el build de la alineación (08:46 -03, cero *.json en build/web/assets/assets/images/).
- **Corrección 09:35 COMPLETADA 10:51 (informe audit/correccion_6jugadores_reveal.md, 20 capturas; verificada en disco: informes, capturas, maxPlayers 6 en ambos motores, NativeYtHost 726/999, HEAD intacto, build 10:25):** 6 jugadores máximo, distribución del mockup con cero solapes, revelación legible rediseñada, micrófono y música verificados (pérdida real restaurada: música nativa en horizontal), APOSTAR usable, Cerrar dentro, VER/panel sin solape. Pendiente su juicio en el informe final. Honesto: veredicto final Dudo con Seguir NO se alcanzó en la corrida (la foto es conteo 8/11); hoja DJ abierta NO capturada; voz real y sonido nativo horizontal NO probados; placa superior trunca nombres largos; panel desplegado a 390 corta asientos inferiores; pipas Blender finas a 56 (alternativa nítida DiceFace, necesita su sí).
- **Etapa 1 Unity ENTREGADA 12:39 (verificada en disco: INFORME_ETAPA1.md, blend 19,5 MB, glb 11 MB, fbx 6,8 MB, hero, revelación, detalle, clip 2 s, esqueleto Unity; HEAD cacho intacto):** mesa Blender 6 asientos + esqueleto Unity sin Editor ni build ni link (bloqueo: licencia Personal sin activar por el usuario). Desvíos honestos: avatares abstractos, sin barra/consola en renders, placas laterales fuera del óvalo, paño gris medio no carbón, fondo bokeh no taberna, vaso superior 0.75× y logo como decisiones propias del modelador, riesgo WebGL (160k tris, diezmo pendiente).
- **Tribunal ronda 2 ENTREGADO 12:43 (sentencia audit/tribunal/sentencia_mesa_ronda2.md, 480 líneas, verificada en disco; solo asesora, mesa NO aceptada):** ACEPTADAS consola y reglas Flutter; CONDICIONADAS mesa 6 Flutter, revelación, mic/música/emotes, menús/carrusel/gate, alturas 178/179, assets/esqueleto/reglas/WebGL Unity. Hallazgo nuevo: emotes vistos como cajas vacías en línea (discrepancia con el relay afirmado). P1–P21: pendientes P1, P2, P6, P8, P9, P10, P11, P13–P16, P18–P21; cerrados por supersesión P4 y P5. Decisión final del usuario pendiente (aceptación de la mesa + 20 preguntas en la sentencia).

## Lista de revisión para el informe final con capturas (usuario 07:46)

Todo quedó bien aplicado y por ahora no hay nada que decidir; solo queda esperar el informe final con capturas. Cuando lleguen las capturas, se le mandan y él las compara con el mockup. Dos fijaciones suyas:

- **El link Unity WebGL es solo para mirar:** sirve para revisar diseño y animaciones, NO para decidir si el rendimiento es bueno (WebGL en iPhone puede ir lento o fallar por memoria). El rendimiento se mide después con un build nativo.
- **Borrado de los 9 JSON sin comprobar hasta el build verificado:** producción no cambió, así que no hay riesgo, pero la mesa NO se acepta hasta confirmar que el build pasa.

Lo que él mirará en las capturas:

1. Cinco jugadores, uno arriba al centro, dos a cada lado y yo abajo con el vaso grande.
2. Mis dados ocultos y sin dados sueltos en el centro, fuera de una revelación.
3. Pozo arriba al centro y apuesta actual siempre visible.
4. Madera gruesa y paño con textura, sin degradado plano.
5. Placas pegadas bajo cada avatar, sin tapar la barra superior ni salirse del óvalo.
6. Que se mueva: vela, avatares y aro del turno, y que el Dudo tenga su secuencia.
