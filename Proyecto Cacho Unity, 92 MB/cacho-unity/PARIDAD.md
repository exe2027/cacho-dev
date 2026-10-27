# PARIDAD docs/18 vs Flutter — BORRADOR ETAPA 1 (Unity)

> Borrador para que el coordinador lo integre al informe final.
> **Ninguna brecha se resuelve aquí por cuenta propia.** Cada fila dice
> qué dice cada lado, dónde se ve en la etapa 1 (si afecta lo visual)
> y si quedó DECIDIDO o ABIERTO. Lo DECIDIDO viene de
> `~/workspace/cacho/docs/19-casos-paridad-flutter-unity.md`
> (decisiones del usuario, 26-oct-2026 ~07:32, que mandan sobre lo
> anterior). Lo ABIERTO queda pendiente de decisión del usuario.
>
> Alcance de esta etapa: SOLO definición visual (mesa + assets).
> Los casos de reglas (A, P, C, K, G) se anotan como lista que AMBAS
> versiones tienen que pasar; **no se implementan ni se verifican en
> Unity en esta etapa** (no hay motor Unity todavía). El estado
> Flutter de esos casos está implementado en motor Dart + servidor,
> pero la verificación caso por caso es trabajo del pase de paridad
> posterior, no se da por hecha (docs/19 lo dice explícitamente).
>
> Fuentes leídas (solo lectura; `~/workspace/cacho/` NO se modificó):
> docs/18 íntegro (§1, §2, §8, §9, §10 en especial), docs/19 íntegro,
> `app/lib/widgets/sketch_layout.dart`, `app/lib/table_themes.dart`,
> `app/lib/screens/game_screen.dart` (barra superior),
> `app/lib/state/match_controller.dart`, `server/src/engine.js`
> (Calzo/Kamikaze), y el mockup objetivo
> `~/workspace/user/media_library/image/dd/dd43f464f00d352c526b47a8dc7316bb236103e093c25085cdaff6d786e605e7.jpg`.

## Resumen de estado (una línea por brecha)

| # | Brecha | Estado 26-oct 07:32 | Afecta etapa 1 visual |
|---|---|---|---|
| a | Jugadores: 5 vs 8 | **DECIDIDO: máximo 5 (2–5, N1/N2)** | SÍ — 5 asientos, resto libres |
| b | Mis dados: ocultos+VER vs visibles | **DECIDIDO: ocultos, solo VER (V1–V3)** | SÍ — dados ocultos, VER marcador |
| c | Asiento arriba al centro vs pozo arriba | **ABIERTO en texto** (etapa 1 sigue el mockup: pozo arriba) | SÍ — pozo arriba, sin asiento central superior |
| d | Tiers/montos de lobby | **ABIERTO** | Parcial — etapa 1 usa tiers Flutter |
| e | Barra superior (+, amigos, regalo, dados, misiones) | **ABIERTO** | SÍ — barra solo con datos reales |
| f | Botón de chat | **DECIDIDO (C9): chat de texto FUERA; emotes dentro** | SÍ — slot de emotes, sin chat |
| g | Placas: nombre+fichas+nivel vs nombre+dados | **ABIERTO** (nivel/fichas en placa) | SÍ — placa nombre + dados |
| h | Calzo | **DECIDIDO: casos C1–C10 para ambas** (motor Unity pendiente) | NO — bloquea gameplay, no la mesa |
| i | Kamikaze | **DECIDIDO: casos K1–K9 para ambas** (motor Unity pendiente) | NO — bloquea gameplay, no la mesa |
| j | Ases y Paso | **DECIDIDO: casos A1–A9, P1–P14 para ambas** (motor Unity pendiente) | Parcial — banda de desafío de Paso como marcador |
| k | Generales de ronda (G1–G5) | **DECIDIDO: casos G1–G5 para ambas** (motor Unity pendiente) | NO |
| l | Avatares: IA original vs Blobatar | **ABIERTO** | SÍ — slot sin arte final |
| m | Agitar el celular para ver dados | **ABIERTO** | SÍ — solo VER como marcador |
| n | Revelación en duda de Paso y en Kamikaze | **ABIERTO** | SÍ — centro oculto salvo Dudo/Calzo |
| o | Puestos vacíos en línea (¿bots o libres?) | **ABIERTO** | SÍ — libres por defecto (N2) |
| p | Impacto 8→5 en Flutter | Trabajo ENCOLADO, no decisión de diseño | NO en Unity; SÍ en Flutter posterior |
| q | Tienda / gemas / progresión | Secuencia propia tras auth, no se adelanta | NO |

## a) Jugadores — DECIDIDO

- **docs/18 §2:** "Exactamente 5 jugadores: 1 arriba al centro, 2 a la
  izquierda, 2 a la derecha, y yo abajo al centro."
  (Nota: esa enumeración lista 1+2+2+1 posiciones; el número "5" y la
  lista no cuadran aritméticamente — punto que queda anotado, no
  resuelto, junto a la brecha c.)
- **Flutter antes de 07:32:** máximo 8 vigente (orden 25-oct 07:44;
  sketch_layout con distribución de referencia hasta 6 rivales y arco
  igual desde 7; a 8 jugadores hay solapes medidos: 2415 px² a 390).
- **DECIDIDO 07:32 (N1, N2):** partidas de **2 a 5 jugadores en ambas
  versiones**; los puestos vacíos quedan **libres**, no se rellenan
  por defecto en la mesa.
- **Etapa 1:** `TableLayout.cs` tiene 5 asientos como máximo
  (`seatCount` limitado a 2–5); los inactivos muestran el marcador de
  puesto libre, sin avatar ni vaso. El problema de solapes a 8
  jugadores deja de aplicar a la mesa Unity (y a Flutter cuando se
  aplique el pase 8→5).
- **Pendiente (no es decisión de diseño):** alinear Flutter — motor,
  servidor, lobby, selector de bots, tests — en el pase posterior al
  frente horizontal. Encolado, no es trabajo de esta etapa.

## b) Mis dados — DECIDIDO

- **docs/18 §2:** mis dados ocultos bajo el vaso; solo se ven al tocar
  VER o al agitar el celular.
- **Flutter antes de 07:32:** dados visibles y legibles junto al vaso
  (banda inferior con hueco central, decisión 30; peek que levanta el
  vaso sin revelar en Kamikaze a ciegas).
- **DECIDIDO 07:32 (V1, V2, V3):** mis dados **ocultos bajo mi vaso y
  solo se ven con VER**; los dados del centro se muestran **solo al
  revelar Dudo o Calzo**; cada jugador ve solo su vista.
- **Etapa 1:** `MyDiceHidden` nace inactivo bajo mi vaso (vaso
  levantable como objeto, sin animación); `CenterDiceGroup` nace
  inactivo; `VerButton` es marcador visual SIN lógica. Esto reemplaza
  el estado Flutter anterior (dados visibles).
- **Abierto dentro de lo decidido:** agitar el celular (ver m) y la
  revelación en duda de Paso / Kamikaze (ver n).

## c) Asiento arriba al centro vs pozo arriba al centro — ABIERTO en texto

- **docs/18 §2:** "1 arriba al centro" como jugador, y a la vez "Pozo
  arriba al centro, con su monto". Ambas cosas no caben en el mismo
  centro superior: en Flutter, un asiento a 270° solapa el pozo en
  3520 px² medidos (sketch_layout).
- **Mockup y Flutter:** el pozo ocupa el centro superior (placa 50/6,
  vaso 51/21); los 5 asientos son superior-izquierda, superior-derecha,
  medio-izquierda, medio-derecha y yo abajo al centro.
- **Etapa 1:** se sigue el mockup — pozo arriba al centro, sin asiento
  superior-central. La decisión 07:32 de 5 asientos + mockup apunta en
  esa dirección, pero **no hay una decisión explícita registrada que
  diga "no existe asiento arriba al centro"**, así que el texto de
  docs/18 §2 sigue sin reconciliarse y queda ABIERTO para confirmación
  del usuario. No se elige aquí.

## d) Tiers / montos de lobby — ABIERTO

- **docs/18 §7:** La Taberna 500, El Boliche 2.000, El Casino 10.000, La
  Mansión 50.000, El Club VIP 250.000 (con caras con candado y "NIVEL X").
- **Flutter vigente:** Barrio 100, Salón 250, Casino 500, VIP 1000,
  High Roller 2500 (table_themes: Casino 500 = paño carbón definitivo;
  el resto, propuestas con captura, no definitivas sin su sí).
- **Estado 07:32:** SIN DECISIÓN (docs/19, diferencias abiertas).
- **Etapa 1:** se usan los tiers Flutter (paños: carbón, verde, azul,
  morado, bronce) porque son la referencia visual existente y la tier
  del mockup es Casino 500. No se modela ninguna mesa para los montos
  de docs/18 §7. La paridad de montos/nombres de lobby queda pendiente.

## e) Barra superior — ABIERTA

- **docs/18 §2:** fichas y dinero con "+", y amigos, regalo, dados,
  misiones y menú.
- **Flutter hoy:** SOLO datos reales existentes (Salir, saldo, Pozo,
  píldora de turno/apuesta vigente, música plegada, historial,
  ajustes). Sin segunda moneda, sin "+" de compra, sin
  regalo/objetivo/corona/LVL/gemas/bundles/SALE/PREMIO, sin amigos, sin
  misiones (game_screen: "esos huecos del mockup NO se dibujan y quedan
  como preguntas para el usuario"). El Pozo aparece ADEMÁS en la barra
  (duplicado centro+barra), también anotado como pregunta.
- **Estado 07:32:** SIN DECISIÓN (varias de esas funciones no existen
  en Flutter y antes estaban vetadas sin dato real).
- **Etapa 1:** `TopBar` solo con datos reales; los huecos del mockup
  (+, amigos, regalo, dados, misiones) NO se dibujan como si existieran.
  El duplicado pozo centro+barra tampoco se resuelve aquí.

## f) Botón de chat — CERRADO (C9, ronda 2: definición alineada a emotes)

- **docs/18 §2:** botón de chat en la barra inferior (mockup: abajo a
  la izquierda, centro X ≈ 8 %).
- **Flutter hoy:** sin chat (vetado antes, sin función construida).
- **DECIDIDO (C9):** chat de TEXTO fuera; en su lugar van reacciones
  rápidas (emotes). La mención anterior de esta fila como "ABIERTO"
  quedó desactualizada: el chat no está pendiente, está cerrado.
- **Ronda 2 Unity:** el slot del mockup (≈8 %) es slot de emotes
  (":)"), en la consola inferior; no se construye ni se finge chat
  de texto. El slot ":)" suelto sobre la mesa de la etapa 1 se
  retira porque la consola ya lo lleva.

## g) Placas — ABIERTO (nivel y fichas en placa)

- **docs/18 §2:** placa debajo del avatar con nombre, fichas y nivel.
- **Flutter hoy:** placa debajo del avatar con nombre y conteo de
  dados (sin nivel visible; "×5 · El Huaso" como formato).
- **Estado 07:32:** sin decisión específica sobre placas en docs/19
  (no figura en diferencias abiertas ni en decisiones cerradas, así
  que NO se da por decidido en ningún sentido).
- **Etapa 1:** placa con nombre + conteo de dados (paridad Flutter).
  No se inventa un nivel ni un saldo en la placa.

## h) Calzo — DECIDIDO (regla); motor Unity PENDIENTE

- **docs/18 §5:** "si acierta, recupera un dado; si falla, pierde uno.
  Solo si queda al menos la mitad de los dados en juego."
- **Flutter vigente:** "se calza siempre" (umbral eliminado 24-oct) +
  fórmula estricta + Calzo perfecto (decisión 23): gana solo si
  `totalActual × 2 > totalInicial`; exacto con 5 dados → demás vivos
  pierden un dado; exacto sin recuperación → marca `recoveryBlocked`.
- **DECIDIDO 07:32:** los casos **C1–C10** los tienen que pasar AMBAS
  versiones (ver lista abajo). La regla queda fijada por esa lista;
  la implementación en Unity y la verificación caso por caso quedan
  PENDIENTES para la etapa de motor (esta etapa 1 no implementa nada).
- **Etapa 1 visual:** NO afecta la mesa (sin animación de Calzo aquí).
  La resolución con dados del centro visibles es V2 (centro solo al
  revelar Dudo o Calzo).

## i) Kamikaze — DECIDIDO (regla); motor Unity PENDIENTE

- **docs/18 §5:** solo la primera vez que a un jugador le queda 1 dado;
  elige un número del 1 al 6, todos lanzan, quien lo saque pierde esos
  dados; el dado del activador también se lanza; los 1 no son comodín;
  si todos quedan sin dados, pierden todos.
- **Flutter vigente:** ofrecimiento ENTRE RONDAS, solo si es el ÚNICO
  con 1 dado y sin haber sido ofrecido antes; a ciegas (nadie ve sus
  dados hasta que el activador elige el número; dados frescos al
  elegir, tirada nueva dentro de la elección).
- **DECIDIDO 07:32:** los casos **K1–K9** los tienen que pasar AMBAS
  versiones (ver lista abajo). Motor Unity y verificación caso por
  caso, PENDIENTES.
- **Etapa 1 visual:** NO afecta la mesa. La banda de Kamikaze y la
  revelación en Kamikaze quedan para cuando la regla esté en motor; la
  forma de mostrar las manos en Kamikaze sigue ABIERTA (ver n).

## j) Ases y Paso — DECIDIDOS (regla); motor Unity PENDIENTE

- **Ases — docs/18 §5:** entrar a ases cuesta la mitad (de 8 Cuatros a
  4 Ases); salir de ases es el doble +1 (de 4 Ases a 9 de otra pinta).
- **Ases — Flutter vigente:** idéntica estructura (error
  `ases_para_partir` al abrir con ases; `ases_mitad`;
  `salida_ases_doble_mas_uno`; al resolver ases solo cuentan los 1
  reales; en otras apuestas los 1 son comodines; interruptor de ases).
- **Paso — docs/18 §5:** decir que tienes 5 dados distintos o un full
  (3+2); solo se puede pasar con 5 dados; los demás pueden dudar o
  calzar el Paso.
- **Paso — Flutter vigente:** tras un Paso, el siguiente puede calzar,
  dudar o apostar sobre la apuesta del jugador anterior (regla del
  usuario, 24-oct); banda de desafío sobre la consola.
- **DECIDIDO 07:32:** los casos **A1–A9** y **P1–P14** los tienen que
  pasar AMBAS versiones (ver lista abajo). Motor Unity y verificación
  caso por caso, PENDIENTES.
- **Etapa 1 visual:** `PasoChallengeBar` existe como marcador inactivo
  sobre la consola (sin lógica, sin texto de desafío real). La
  revelación en duda de Paso sigue ABIERTA (ver n): hoy Flutter revela
  solo la mano del jugador del Paso (P9), pero docs/19 no precisa cómo
  se muestra eso bajo la regla V2 (centro solo Dudo/Calzo).

## k) Generales de ronda — DECIDIDOS (regla); motor Unity PENDIENTE

- **DECIDIDO 07:32:** los casos **G1–G5** los tienen que pasar AMBAS
  versiones (ver lista abajo). Incluyen quién parte la ronda siguiente,
  sorteo visible por dado mayor, 60 s de turno con bot al vencer y
  eliminación por 3 vencimientos seguidos, desconexión con bot y 60 s
  de gracia, y eliminación al quedar sin dados / salir a mitad.
- **Etapa 1 visual:** NO afecta la mesa (el semáforo de turno y los
  pitidos son lógica/animación de etapa 2+; aquí solo el aro base).

## l) Avatares — ABIERTO

- **docs/18 §1/§8:** arte 2D generado con IA y limpiado, siempre
  original; personajes chilenos tipo Don Chalo, La Cuca, El Guatón, La
  Pituca; NO copiar caras del mockup.
- **Flutter hoy:** Blobatar para TODOS en mesa (hue 45 dorado, semilla
  estable); los retratos generados estilo sepia fueron rechazados y no
  se usan; los PNG de bots (`bot_chalo.png`, `bot_cuca.png`,
  `bot_guaton.png`, `bot_huaso.png`, `bot_pituca.png`) existen como
  assets de bots.
- **Estado 07:32:** sin decisión en docs/19.
- **Etapa 1:** slot de avatar SIN arte final. Unity no copia Blobatar
  ni caras del mockup; el arte queda pendiente de decisión.

## m) Agitar el celular para ver dados — ABIERTO

- **docs/18 §2:** mis dados se ven al tocar VER **o al agitar el
  celular**.
- **Decisión 07:32 (V1):** "solo se ven con VER".
- **Estado 07:32:** docs/19 lo lista en diferencias abiertas — "sin
  decisión sobre si el agitado queda o no". La frase "solo con VER"
  y el permiso de docs/18 §2 no quedaron reconciliados.
- **Etapa 1:** solo VER como marcador visual; ningún sensor de
  agitado, ningún gesto alternativo.

## n) Revelación en duda de Paso y en Kamikaze — ABIERTA

- **Decisión 07:32 (V2):** dados del centro solo al revelar Dudo o
  Calzo.
- **Duda de Paso:** P9 dice que en la duda solo se revela la mano del
  jugador del Paso (no las demás manos) — pero V2 habla de "centro",
  y la mano del Paso no es el centro. Cómo se muestra esa mano única
  bajo V2 queda por precisar (docs/19, diferencias abiertas).
- **Kamikaze:** K4 dice que nadie ve ningún dado hasta que el activador
  elige el número y que los dados son una tirada nueva revelada solo
  en la resolución — pero la forma visual de esa revelación (¿centro?
  ¿manos?) no está precisada y V2 no la cubre.
- **Etapa 1:** `CenterDiceGroup` inactivo en reposo; no se define
  ninguna revelación de Paso ni de Kamikaze.

## o) Puestos vacíos en línea — ABIERTO

- **Decisión 07:32 (N2):** los puestos vacíos quedan libres; no se
  rellenan por defecto en la mesa.
- **Pregunta sin respuesta (docs/19):** en salas EN LÍNEA, ¿se rellenan
  con bots o quedan libres hasta que entre gente? SIN DECISIÓN.
- **Etapa 1:** libres por defecto (marcador de puesto libre). La
  decisión en línea no se anticipa.

## p) Impacto del cambio 8→5 en Flutter — trabajo ENCOLADO

- No es una decisión de diseño: es trabajo pendiente del pase
  posterior al frente horizontal (motor, servidor, lobby, selector de
  bots, tests de Flutter). No se hace en esta etapa ni se da por hecho
  en Unity: Unity ya nace con 5; Flutter llega a 5 en su pase.

## q) Tienda / gemas / progresión — secuencia propia, no se adelanta

- docs/19: siguen su secuencia propia (después de auth); no se
  adelantan por paridad. En etapa 1 no hay tienda, gemas, cofres,
  misiones, ligas ni progresión en la escena (la barra superior
  tampoco los dibuja, ver e).

## Otras divergencias encontradas leyendo docs/18 y el código Flutter

- **Forma de la mesa:** docs/18 §2 pide óvalo; el código Flutter define
  la mesa como rectángulo (sketch_layout: rect `mesa`, esquinas
  redondeadas 28) y el aspecto estadio lo da la imagen `mesa_fondo.jpg`.
  En Unity el óvalo debe ser geometría real (glTF `mesa_ovalo.gltf`),
  no un rectángulo con foto, para que la paridad sea de forma y no
  solo de imagen. No es una brecha de regla; es una nota de
  implementación de etapa 1.
- **Mi vaso más grande:** docs/18 §2 y Flutter coinciden (mi vaso
  64×76 frente a 56×64 rivales). Sin brecha; se mantiene en Unity
  (misma malla, mayor escala).
- **Apuesta actual y quién la hizo, siempre visibles (docs/18 §2):**
  Flutter lo cubre con la píldora de turno/apuesta en barra + pozo.
  Sin brecha; en Unity es texto de etapa 2 (aquí, marcador).
- **Tiles 1–6 solo botones, no mis dados reales (docs/18 §2):**
  Flutter coincide (tiles de consola separados de mis dados). Sin
  brecha; en Unity los tiles son botones de apuesta.
- **"Nada se superpone ni se sale del óvalo" (docs/18 §2):** con 5
  asientos y las posiciones del mockup no hay solapes estructurales
  (los solapes medidos en Flutter eran a 8 jugadores). Sin brecha
  vigente a 5; si el usuario reabriera 8, volvería el problema.

## Listas de casos que AMBAS versiones tienen que pasar (docs/19)

> Solo el enunciado corto de cada caso. El texto completo y vigente
> está en `~/workspace/cacho/docs/19-casos-paridad-flutter-unity.md`.
> Estado Unity: PENDIENTE (sin motor). Estado Flutter: implementado en
> motor Dart + servidor (suites Dart 77/77, servidor 31/31 según
> docs/19); la verificación caso por caso es trabajo del pase de
> paridad, no se da por hecha aquí.

### A. Apuestas y Ases (A1–A9)

- A1 Subida clásica (más cantidad cualquier pinta, o igual cantidad
  con pinta mayor; nunca bajar).
- A2 Primera apuesta nunca ases (`ases_para_partir`; As atenuado al abrir).
- A3 Entrar a ases, ejemplo: de 8 Cuatros a 4 Ases (la mitad).
- A4 Entrar a ases, mínimo general: al menos `ceil(N/2)`.
- A5 Salir de ases, ejemplo: de 4 Ases a 9 de otra pinta (doble +1).
- A6 Dentro de ases solo sube la cantidad.
- A7 Resolver apuesta de ases: solo cuentan los 1 reales.
- A8 Resolver otra apuesta: los 1 son comodines.
- A9 Ases desactivados por sala: el As es una pinta más, sin conversión
  ni comodines.

### B. Paso (P1–P14)

- P1 Mano de Paso, distintos: 5 dados todos distintos (el 1 cuenta
  como 1, sin comodines).
- P2 Mano de Paso, Full: exactamente 3+2.
- P3 Paso solo con 5 dados.
- P4 Solo el siguiente puede dudar un Paso.
- P5 Si el siguiente juega, el Paso queda firme para siempre.
- P6 Dos Pasos seguidos: solo el último se puede desafiar.
- P7 Dudar un Paso verdadero: el que duda pierde el dado.
- P8 Dudar un Paso falso: el jugador del Paso pierde el dado.
- P9 En la duda solo se revela la mano del jugador del Paso.
- P10 Tras un Paso se puede calzar, dudar o apostar sobre la apuesta anterior.
- P11 Máximo 1 Paso por jugador por ronda.
- P12 Paso prohibido como primera jugada de la ronda.
- P13 Paso prohibido dos veces seguidas por el mismo jugador.
- P14 Paso declarado falso (farol): se puede declarar; solo el desafío
  lo verifica.

### C. Calzo (C1–C10)

- C1 Calzar siempre se puede intentar.
- C2 Recuperar solo si queda más de la mitad, estricto:
  `totalActual × 2 > totalInicial` (totales antes de aplicar
  ganancia/pérdida; `totalInicial` = jugadores al inicio × dados por
  jugador, fijo aunque haya eliminados).
- C3 Ejemplo: 4 jugadores = 20 iniciales; con 11 en juego se recupera,
  con 10 o menos NO.
- C4 Exacto pero sin recuperación: sin ganancia ni pérdida, la ronda
  termina, el calzador parte la siguiente, marca `recoveryBlocked`.
- C5 Calzo inexacto: el calzador siempre pierde un dado.
- C6 Calzo perfecto: exacto con los 5 dados → el calzador no gana nada
  y cada otro jugador vivo pierde 1 dado.
- C7 Perfecto solo con Calzo, no con calzoPaso.
- C8 CalzoPaso usa la misma regla de recuperación.
- C9 Calzo logrado: quien calza con éxito parte la ronda siguiente.
- C10 Toda resolución desafiada termina la ronda: tras Dudo, Calzo o
  duda/calzo de Paso, todos vuelven a lanzar.

### D. Kamikaze (K1–K9)

- K1 Ofrecimiento entre rondas: solo la primera vez que un jugador
  termina una resolución con exactamente 1 dado, siendo el ÚNICO con
  1 dado, y sin haber sido ofrecido antes.
- K2 Llegadas simultáneas a 1 dado: a nadie se le ofrece y la
  oportunidad NO se consume.
- K3 Rechazar es para siempre.
- K4 Kamikaze a ciegas: nadie ve ningún dado hasta que el activador
  elige el número; tirada NUEVA dentro de la elección, revelada solo
  en la resolución.
- K5 El activador puede morir por su propio número.
- K6 Los 1 no son comodín en Kamikaze.
- K7 Todos sin dados a la vez = empate (pierden todos).
- K8 Tras el Kamikaze parte el activador si sigue vivo, si no el
  siguiente vivo en sentido horario.
- K9 Kamikaze con todos eliminados, ejemplo: empate (K7 aplicado).

### E. Generales de ronda (G1–G5)

- G1 Quién parte la ronda siguiente: quien perdió un dado; si nadie
  perdió (Calzo exitoso), el calzador; si está eliminado, el siguiente
  vivo en sentido horario. Siempre anunciado con el motivo.
- G2 Primera ronda, sorteo visible: se parte por dado mayor, empates
  vuelven a lanzar; visible como "Sorteo: parte X".
- G3 Tiempo de turno 60 s: al vencer, juega un bot ese turno; 3
  vencimientos seguidos → eliminación por abandono.
- G4 Desconexión en partida: un bot cubre mientras tanto, aviso a toda
  la mesa, 60 s de gracia para volver; al volver se cancela, al vencer
  se elimina.
- G5 Eliminación: quien queda sin dados queda eliminado; salir a mitad
  de partida pierde la apuesta.

### F. Dados ocultos / VER (V1–V3) — ya aplicados en etapa 1 visual

- V1 Mis dados ocultos bajo mi vaso: solo se ven con VER.
- V2 Dados del centro solo al revelar Dudo o Calzo.
- V3 Vista propia: cada jugador ve solo su vista.

### G. Jugadores (N1–N2) — ya aplicados en etapa 1 visual

- N1 Partidas de 2 a 5 jugadores en ambas versiones.
- N2 Puestos vacíos quedan libres (no se rellenan por defecto).

---

## NOTA DEL COORDINADOR — Decisiones finales del usuario 07:40 (docs/19 actualizado)

Esta nota se suma a la tabla anterior sin reescribirla. Lo que la decisión 07:40
RESUELVE (manda sobre lo anterior):

- **A1 Calzo estricto:** MÁS de la mitad (`totalActual × 2 > totalInicial`; 11 de 20
  sí, 10 no). docs/18 §5 "al menos la mitad" está equivocado.
- **A2 Sin marca de pendiente:** P11, P12, P13, C6 (y C7: perfecto solo Calzo).
- **B5 Agitar y VER, ambos:** agitar LANZA los dados; VER los mira.
- **B6 Revelación en cualquier resolución** (Dudo, Calzo, duda de Paso, Kamikaze);
  duda de Paso solo la mano del jugador del Paso (P9); Kamikaze todos los dados
  nuevos al resolver. V2 actualizada en consecuencia.
- **C7 Tiers con nombres nuevos (mismos montos):** La Taberna 100, El Boliche 250,
  El Casino 500, La Mansión 1.000, El Club VIP 2.500.
- **C8 Barra superior por ahora:** solo fichas, ajustes y menú; sin botones muertos.
- **C9 Chat fuera por ahora;** reacciones rápidas (emotes) con animación.
- **C10 Puestos en línea libres;** el anfitrión elige al iniciar: bots o presentes.
- **D11 Flutter 8 → 5** en el pase posterior al horizontal (no es de esta etapa).
- **D12 Etapa 1 sigue como está, con 5 asientos.**

Sigue ABIERTO tras 07:40 (de la sección final de docs/19 + brechas de esta etapa):
Calzo perfecto con total bajo; ruta de prueba de los builds Unity; APK paralela
Flutter (intento detenido 07:29); despliegue a producción; aceptación de la mesa;
detalles P1–P21; auth/tienda/ranking/niveles en su secuencia; regla futura 10.000;
capturas vivas pendientes; limpieza de 9 JSON; avatares IA original vs Blobatar;
nivel en placas; enumeración §2 (1+2+2+1 = 6) frente a "exactamente 5".

---

## NOTA DEL COORDINADOR — Decisiones 07:43 (se suman a las 07:40)

- **C11 Calzo perfecto con total bajo — DECIDIDO:** misma regla de la mitad; con la
  mitad o menos, el exacto no da ni quita nada y el perfecto TAMPOCO hace perder
  dados a los demás. Caso de prueba en ambas versiones; en Flutter exige ajuste del
  motor en el pase de alineación. (Ya está en docs/19; no se editó docs/19 desde aquí.)
- **Build de prueba Unity — DECIDIDO: WebGL CON LINK para iPhone, NO TestFlight.**
  Ojo honesto: WebGL no soporta oficialmente móviles; el build va optimizado
  (memoria chica, assets contenidos) y el link es de PREVISUALIZACIÓN, nunca
  cacho.pages.dev. El build sigue bloqueado por la licencia Unity.
- **APK de Flutter — DESCARTADA, no se reintenta.**
- **Sin despliegue a producción** hasta mesa aceptada + pedido explícito.
- **Mesa NO aceptada;** informe final con capturas después, cuando la etapa 1 y el
  frente horizontal entreguen; tribunal ronda 2 y P1–P21 para entonces.
- **Staleness de docs/19:** su sección final aún lista como "sin decisión" el
  perfecto con total bajo, la ruta de prueba y la APK paralela; las decisiones 07:43
  ya los resolvieron (ver arriba). No se editó docs/19 desde esta etapa.

---

## NOTA DEL COORDINADOR — Corrección del usuario 09:35 ("me equivoqué eran 6")

- **SEIS JUGADORES MÁXIMO (de 2 a 6 por partida, N1 corregido).** Distribución del
  mockup: 1 arriba al centro, 2 a la izquierda, 2 a la derecha, yo abajo al centro,
  con CERO solapes. Resuelve la brecha del asiento superior-central y la nota
  aritmética (1+2+2+1 = 6, no 5). docs/19 N1 (2 a 5) quedó desactualizado por esta
  corrección; su actualización queda en manos de la coordinación (docs/19 NO se
  editó desde esta etapa). La alineación Flutter pasa de 8→5 a 8→6 (D11).
- **REVELACIÓN LEGIBLE (nueva regla de paridad visual):** ningún dado mostrado puede
  ser pequeño e ilegible; todo dado visible se lee a tamaño real, sin solapes, con
  los que cuentan destacados uno a uno. NUNCA una revelación con todas las manos en
  pequeño al centro (rechazada por ilegible). Aplica a renders y storyboard de la
  etapa 1 y a la futura UI de revelación Unity.
- **MICRÓFONO (voz) Y MÚSICA SE MANTIENEN** (no se diseñan fuera; llegan en etapas
  posteriores). Chat de TEXTO sigue fuera (C9); emotes se quedan.
