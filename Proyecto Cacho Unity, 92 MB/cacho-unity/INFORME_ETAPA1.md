# CACHO UNITY — INFORME ETAPA 1 (mesa + assets)

**Alcance:** SOLO etapa 1 del orden de trabajo §10 de `docs/18-master-prompt-casino-animado.md`
(assets 3D en Blender y mesa en Unity, idéntica al mockup). NO se avanzó a la etapa 2
(animaciones de juego, reglas, bots) ni a ninguna otra etapa. NO se tocó `~/workspace/cacho/`
(repo Flutter), NO se desplegó nada a Pages, NO se hizo commit en el repo del juego.

**Requisito nuevo del usuario (26-oct 07:31, manda sobre la etapa 1):** las versiones
paralelas deben estar LO MÁS PARECIDAS POSIBLE entre sí. La versión Unity debe parecerse
al máximo a la Flutter existente: misma identidad casino (oscuro + dorado mate `#C9A24B`),
misma composición de mesa del mockup, misma disposición de asientos, mismas placas,
mismo pozo, misma consola. Donde `docs/18` diverge de Flutter hoy, NO se eligió un lado:
cada divergencia está anotada abajo como brecha de paridad pendiente de decisión del usuario.

## 1. Referencia: el mockup, medido

Imagen objetivo: `~/workspace/user/media_library/image/dd/dd43f464…e605e7.jpg`
(mesa horizontal, óvalo de madera oscura con borde grueso, paño oscuro, taberna cálida
desenfocada, logo grabado "CACHO O DUDO" en dos líneas al centro, 5 vasos de cuero boca
abajo con posavasos, 5 dados sueltos al centro, pozo arriba al centro, barra superior con
fichas/dinero y barra inferior APOSTAR 1–6 + CALZO/DUDO/PASO + chat).

Posiciones medidas sobre el mockup (centros, % ancho / % alto de pantalla; las mismas
que usa la mesa Flutter actual, para paridad):
- Pozo arriba al centro: placa 50/6, vaso 51/21.
- Jugadores (5): superior-izquierda 13/16 (vaso 26/24), superior-derecha 87/16 (vaso 74/24),
  medio-izquierda 17/49 (vaso 23/53), medio-derecha 87/49 (vaso 78/53), yo abajo al centro
  50/60 (vaso delante, más grande).
- Consola inferior: y ≈ 88; CALZO ≈ 61%, DUDO ≈ 77%, PASO ≈ 90%, tile 1 ≈ 18%,
  tile 6 ≈ 48%, chat ≈ 8%.

Nombres: PROPIOS e inventados (Don Chalo, La Cuca, El Guatón, La Pituca, "TÚ").
NO se copiaron nombres, caras, logos ni arte del mockup ni de Monopoly Poker,
Parchisi Star u 8 Ball Pool. Cifras de la escena: saldo 5.000 y pozo El Casino 500 × 5 = 2.500
(datos reales de paridad Flutter, NO las cifras del mockup).

## 2. Factibilidad Unity en esta VM — BLOQUEO HONESTO

- Blender: DISPONIBLE. Blender 4.2.3 LTS en `~/blender/blender`. EEVEE no corre aquí
  (falta libEGL); los renders de esta etapa usan Cycles en CPU.
- Unity Editor: NO INSTALADO. Una instalación headless es técnicamente posible
  (Hub CLI + tarball del Editor), pero la activación de licencia Personal exige un paso
  con cuenta de Unity en navegador (OAuth del Hub CLI, espera ~5 min, o flujo manual
  .alf/.ulf). Ese paso NO se puede completar desde aquí ni se piden credenciales para
  ello. Por tanto: NO hay build Unity, NO hay APK Unity y NO hay captura de Unity en
  esta etapa, y ninguna se finge.
- Lo que SÍ se entrega en esta etapa: assets Blender reales (`.blend` + `.glb`/`.fbx`),
  renders Cycles de la mesa, y el esqueleto del proyecto Unity (definición de escena,
  `TableLayout.cs` con las posiciones % y la paleta, lista de assets por slot), listo
  para abrir en un Editor con licencia. La captura de Unity real queda pendiente de
  un entorno con Unity licenciado.
- Ruta de prueba DECIDIDA 07:43: WebGL CON LINK para verlo desde iPhone, NO TestFlight.
  Con el ojo honesto: Unity no soporta oficialmente WebGL en móviles, así que ese
  build irá optimizado (memoria chica, assets contenidos) y su link será de
  PREVISUALIZACIÓN, nunca cacho.pages.dev. El hosting de esa previsualización se
  define cuando exista el build; no se promete ninguna URL ahora.
- Android: el SDK (`~/android/sdk`) y JDK ya existen por la vía Flutter; el módulo
  Android de Unity seguiría pendiente de instalar junto con el Editor.

## 3. Assets Blender (etapa 1) — COMPLETADO y verificado en disco

Frente Blender COMPLETADO 26-oct ~15:37 y verificado por el coordinador (archivos,
tamaños, renders vistos con sus propios ojos; no solo el informe del modelador).
Motor: Cycles CPU (EEVEE no corre en la VM). Tiempo total de render de la ventana:
≈100 min (hero ≈12 min, revelación 4 fotogramas ≈29 min, storyboard ≈15 min, clip
24 fotogramas ≈21 min, detalle ≈5 min; dos corridas murieron por limpieza de sesiones
del runtime y se relanzaron hasta terminar bien).

- Escena: [blender/mesa_cacho.blend](sandbox://workspace/cacho-unity/blender/mesa_cacho.blend)
  (19.508.232 B; colecciones Mesa, Vasos, Dados, Fichas, Asientos, Fondo, Logo, sin
  objetos huérfanos).
- Exportaciones desde el blend final:
  [blender/mesa_cacho.glb](sandbox://workspace/cacho-unity/blender/mesa_cacho.glb)
  (11.050.076 B) y [blender/mesa_cacho.fbx](sandbox://workspace/cacho-unity/blender/mesa_cacho.fbx)
  (6.808.140 B).
- Notas completas del modelador: [blender/NOTAS.md](sandbox://workspace/cacho-unity/blender/NOTAS.md)
  (306 líneas: qué se modeló, cifras, renders, medición de solapes, legibilidad,
  diferencias, limitaciones).
- Hero estado NORMAL (6 vasos cerrados, sin dados al centro):
  [renders/mesa_hero.png](sandbox://workspace/cacho-unity/renders/mesa_hero.png) (1688×950).
- Revelación legible en primer plano:
  [renders/mesa_revelacion.png](sandbox://workspace/cacho-unity/renders/mesa_revelacion.png)
  + secuencia de conteo uno a uno (mano [5,1,5,3,2]; cuentan 1º, 2º y 3º con disco
  dorado): [renders/revelacion/2_cuenta_1.png](sandbox://workspace/cacho-unity/renders/revelacion/2_cuenta_1.png),
  [renders/revelacion/3_cuenta_2.png](sandbox://workspace/cacho-unity/renders/revelacion/3_cuenta_2.png),
  [renders/revelacion/4_cuenta_3.png](sandbox://workspace/cacho-unity/renders/revelacion/4_cuenta_3.png).
- Storyboard Dudo (definición, NO jugable): 6 fotogramas en
  [renders/storyboard_dudo/](sandbox://workspace/cacho-unity/renders/storyboard_dudo/1_pausa.png)
  (1_pausa, 2_primer_vaso, 3_vasos_levantados, 4_dados_cayendo, 5_dados_que_cuentan,
  6_veredicto).
- Clip de movimiento a nivel de asset:
  [renders/movimiento_assets.mp4](sandbox://workspace/cacho-unity/renders/movimiento_assets.mp4)
  (960×540, 12 fps, 2,0 s, H.264, 139.566 B; parpadeo de lámpara, respiración de
  avatares, pulso del aro del turno, push-in) + 24 fotogramas en
  [renders/movimiento/](sandbox://workspace/cacho-unity/renders/movimiento/frame_0001.png).
- Detalle: [renders/detalle_vaso_dados.png](sandbox://workspace/cacho-unity/renders/detalle_vaso_dados.png)
  (mi vaso alzado a un lado + 5 dados [1,2,5,3,6]).

La escena (6 asientos, corrección 09:35): Don Chalo (CH), La Pituca (PI), El Guatón
(GU), La Cuca (CU), El Huaso (HU, el sexto, arriba al centro) y TÚ abajo con vaso
GRANDE 1.25×; vaso superior-central 0.75× (en perspectiva iguala a los rivales).
Placa combinada POZO+APUESTA: "POZO 3.000" + "APUESTA ACTUAL 5 Quintas (EJEMPLO)" —
la apuesta es ejemplo marcado, no dato vivo. Saldo 5.000, pozo 3.000 = El Casino
500 × 6. "NV 1" es marcador, no dato real. Logo "CACHO O DUDO" bajado a y=-0.80
(decisión propia del modelador, medida, NO orden del usuario — queda a validar).
Micrófono y música NO se eliminaron (llegan en etapas posteriores); chat de texto
fuera; emotes en slot ":)" sin animación; sin barra superior modelada (ver §5).

Conteos (malla evaluada, blend final): Mesa 2.500, Vasos 14.520, Dados 5.160,
Fichas 858, Asientos 123.475, Fondo 3.635, Logo 10.145 — total 160.293. Lectura
honesta: ~124.000 son textos e iniciales convertidos a malla (estáticos); los props
3D reales son ≈36.000. Los textos son candidatos a diezmar en la importación Unity;
no se tocaron para no arriesgar la legibilidad. RIESGO PARA EL BUILD WEBGL DE
PREVISUALIZACIÓN: 11 MB de glb + 160 k tris + textos sin diezmar es un presupuesto
alto para iPhone WebGL (memoria chica exigida); el diezmo de textos queda como tarea
al importar en Unity, antes de cualquier link de previsualización.

Medición de solapes (AABB a cámara hero, medida, no afirmada): CERO solapes reales
entre tokens de asientos DISTINTOS (discos, placas, vasos), cero vaso-POZO,
placa-POZO y logo-vaso. Residuos informados tal cual: (1) Avatar_TÚ × Vaso_TÚ
148×75 px — capa intencionada (token sobre su propio vaso); (2) Vaso_DonChalo ×
PilaFichas 9×35 px de caja-unión pero 0 px real ficha por ficha (verificado una por
una); (3) anillo del logo parcialmente tapado por el vaso superior-central
(oclusión 3D normal; el texto queda legible salvo la D de DUDO que roza el vaso de
TÚ en el hero — verificado a ojo por el coordinador, no "intacto" al 100% como dice
NOTAS.md). No se forzó el cero absoluto: con los tamaños actuales es geométricamente
imposible sin aplastar el logo, y el usuario mandó informar la medida en vez de
comprimir. Historial: el hero v4 (5 asientos) se perdió al sobrescribirse sin
respaldo; se conservan v1, v2, v3, v5 y v6c. NOTA: NOTAS.md menciona "hero v4
aceptado" — eso es jerga interna del modelador (su iteración aceptada por él),
NO aceptación del usuario: la mesa NO está aceptada.

## 4. Escena Unity — esqueleto (etapa 1, verificado en disco)

Frente de escena/paridad COMPLETADO y verificado (5 archivos, 1.178 líneas en total;
el C# usa solo `UnityEngine` + `UnityEngine.UI`; DOTween/Cinemachine solo se mencionan
en comentarios como NO usados en etapa 1):

- [unity/README.md](sandbox://workspace/cacho-unity/unity/README.md): cómo abrir el
  esqueleto en Unity Editor (LTS recomendada 2022.3, módulo Android Build Support,
  SDK existente en `~/android/sdk` reutilizable); falta la activación de licencia
  Personal por el usuario (OAuth del Hub o .alf/.ulf, ~5 min en navegador). No hay
  build, APK ni captura Unity, y no se finge ninguna.
- [unity/Assets/Scripts/TableLayout.cs](sandbox://workspace/cacho-unity/unity/Assets/Scripts/TableLayout.cs):
  `seatCount` con `[Range(2, 5)]` y clamp 2–5 (N1); asientos inactivos = puesto libre
  sin avatar ni vaso (N2); `myDiceHidden` y `centerDiceGroup` nacen inactivos con
  `SetActive(false)` (V1–V2); `verButton` como marcador visual SIN lógica; mi vaso
  cierra sobre los dados. Paleta como constantes: dorado mate `0xC9A24B`,
  CALZO `0x0E7A4F`, DUDO `0xB3202A`, PASO `0x14586B`, paño carbón; tiers Flutter en
  `ApplyTierFelt()`.
- [unity/Assets/Scenes/Mesa.unity.txt](sandbox://workspace/cacho-unity/unity/Assets/Scenes/Mesa.unity.txt):
  definición de escena en texto (NO binario .unity): cámara ortográfica, luz de
  taberna horneada, fondo, `TableRoot` con `TableLayout.cs`, Canvas con TopBar
  (C8: solo fichas, ajustes y menú), TableArea, PotGroup (placa 50/6 + vaso 51/21), 5 Seat
  (13/16, 87/16, 17/49, 87/49, 50/60; vasos 26/24, 74/24, 23/53, 78/53), MyCupGroup
  (vaso mayor, 50/52, con MyDiceHidden), CenterDiceGroup (50/40, oculto), VerButton
  (62/52, marcador), PasoChallengeBar (inactiva), BottomConsole (y≈88: slot
  reacciones/emotes C9 ≈8% en vez de chat, tile 1 ≈18%, tile 6 ≈48%, CALZO ≈61%,
  DUDO ≈77%, PASO ≈90%).
- [unity/ASSETS_NEEDED.md](sandbox://workspace/cacho-unity/unity/ASSETS_NEEDED.md):
  qué glTF de Blender va en cada slot.
- [PARIDAD.md](sandbox://workspace/cacho-unity/PARIDAD.md): tabla de paridad completa
  (decidido vs abierto) que alimenta la sección 6 de este informe.

**Actualización del coordinador — corrección 09:35 (aplicada en el esqueleto, sin
reescribir el trabajo del analista):** `TableLayout.cs` y `Mesa.unity.txt` pasaron de
5 a 6 asientos: `SeatTopCenter (0.50, 0.10)` nuevo, `seatAnchors[6]`, `cupAnchors[5]`,
`seatCount` con `[Range(2, 6)]` y clamp 2–6 (por defecto 6, mesa llena), pila de la
columna superior provisional (`PotPlate 0.50/0.21`, vaso de la columna `0.50/0.29`,
medición mockup original 50/6 y 51/21 conservada en comentarios), `ChatX` renombrado
a `EmotesX` (C9), TopBar con micrófono y música que se mantienen, `CenterDiceGroup`
con revelación en cualquier resolución + regla de legibilidad. Llaves/paréntesis del
C# siguen balanceados tras la edición (verificación del coordinador). La prueba
definitiva de cero solapes es la medición de cajas del render Blender, no estas
constantes provisionales.

Sobre `~/workspace/cacho/`: el analista solo leyó; las modificaciones que muestra
`git status` allí (p. ej. `die_*.png`) son del frente concurrente, no de este trabajo.
Esta etapa no escribió nada fuera de `~/workspace/cacho-unity/`.

## 5. Comparación lado a lado contra el mockup (de la más visible a la menos)

Verificada por el coordinador viendo el hero final y la revelación (no solo el
informe del modelador). Checklist del usuario 07:46, punto por punto:

1. **Seis jugadores, distribución del mockup — CUMPLE en composición.** HU arriba al
   centro, CH/PI arriba a los lados, GU/CU a los lados medios, TÚ abajo con el vaso
   grande (1.25×). Seis vasos cerrados en el hero, sin dados al centro.
2. **Mis dados ocultos, sin dados sueltos fuera de revelación — CUMPLE.** Hero sin
   dados al centro; revelación aparte con dados grandes y legibles (ver punto de
   legibilidad abajo).
3. **Pozo arriba al centro + apuesta actual visible — CUMPLE en placa, FALTA en
   barras.** Placa combinada "POZO 3.000" + "APUESTA ACTUAL 5 Quintas (EJEMPLO)"
   legible arriba al centro. Pero NO hay barra superior ni consola inferior
   modeladas en Blender (UI de otra etapa según el modelador): en el render no se
   puede verificar la barra superior ni la consola del mockup; solo existen en la
   definición de escena Unity (§4).
4. **Madera gruesa y paño con textura, sin degradado plano — CUMPLE EN PARTE.**
   Borde de madera grueso con filete dorado y paño gris con textura visible (ruido).
   Pero: el paño es gris medio, no carbón oscuro como el mockup/El Casino 500; el
   fondo no se lee como taberna cálida desenfocada sino como bokeh de discos blancos
   (lámparas) sobre marrón plano, que se ven como globos blancos. La madera y el
   paño convencen; el fondo no.
5. **Placas pegadas bajo cada avatar, sin tapar la barra ni salirse del óvalo —
   CUMPLE EN PARTE.** HU y TÚ tienen placa debajo del avatar. Pero CH/PI tienen la
   placa al costado (no debajo) y GU/CU tienen la placa fuera del óvalo, sobre el
   fondo (a izquierda y derecha). Sin barra superior modelada, el "sin tapar la
   barra" no se puede verificar en el render (solo en la definición Unity, banda
   56 px). Este es el desvío más visible tras los avatares (ver diferencias).
6. **Que se mueva: vela, avatares, aro, secuencia Dudo — CUMPLE A NIVEL DE ASSET,
   NO COMO GAMEPLAY.** Clip de 2,0 s (960×540, 12 fps): parpadeo de lámpara,
   respiración de avatares, pulso del aro, push-in. Es una prueba de movimiento de
   assets, no una secuencia jugable. Storyboard Dudo en 6 fotogramas (pausa, primer
   vaso, vasos levantados, dados cayendo, dados que cuentan, veredicto) como
   definición, no como juego. La secuencia jugable es etapa 3.

**Revelación legible (corrección 09:35) — CUMPLE en el fotograma visto.** Los 5
dados del primer plano se leen a tamaño real, sin solapes entre sí, pipas grandes
(mano [5,1,5,3,2]); el conteo avanza uno a uno con disco dorado (fotogramas 2–4).
La revelación vieja (5 dados pequeños al centro) quedó sustituida por completo.
Queda la advertencia: la legibilidad se verificó en el fotograma principal; los
fotogramas de conteo se entregan pero no se revisaron uno por uno a ojo por el
coordinador.

**Diferencias visibles contra el mockup (de mayor a menor, coordinador + modelador):**
1. Avatares abstractos con iniciales (CH/PI/GU/CU/HU/TÚ) en vez de fotos.
2. Sin consola inferior ni barra superior en los renders (UI de otra etapa).
3. Placas laterales fuera del óvalo (GU/CU) y al costado en vez de debajo (CH/PI).
4. Perspectiva 3D real frente al mockup 2D; vaso superior-central más pequeño
   (0.75×, decisión propia por legibilidad, a validar).
5. Logo debajo del centro (y=-0.80, decisión propia, a validar) y parcialmente
   tapado por mi vaso en el hero (la D de DUDO roza el vaso).
6. Pozo en placa combinada (POZO+APUESTA) en vez de dos placas; pila de fichas a la
   izquierda del centro (en el mockup no existe).
7. Anillo del logo parcialmente tapado por el vaso superior-central (oclusión 3D).
8. Lámparas como bokeh blanquecino, no taberna; slot ":)" en lugar del chat;
   "NV 1" marcador y cifras Flutter (5.000 / 3.000) en vez de las del mockup.
9. Paño gris medio en vez de carbón oscuro; mi avatar (disco TÚ) tapa la parte
   superior de mi vaso (capa intencionada, 148×75 px).

## 6. Brechas de paridad docs/18 vs Flutter — estado tras las decisiones del usuario (26-oct 07:32)

Fuente: `~/workspace/cacho/docs/19-casos-paridad-flutter-unity.md` (decisiones cerradas +
lista de casos). Lo DECIDIDO manda; lo ABIERTO no se resuelve por cuenta propia.
La paridad es el objetivo; la alineación la decide él.

### DECIDIDO 07:32 (aplica ya al diseño visual de esta etapa)

1. **Jugadores: 5 como máximo en AMBAS versiones (de 2 a 5 según la partida; los
   puestos vacíos quedan libres, N1–N2).** Reemplaza el máximo 8 vigente en Flutter
   (orden 25-oct 07:44). La alineación Flutter (motor, servidor, lobby, selector de
   bots, tests) queda ENCOLADA para el pase posterior al frente horizontal, para no
   romper el trabajo en marcha. La etapa 1 Unity ya va con 5 asientos.
2. **Mis dados ocultos bajo mi vaso y solo se ven con VER (V1); los dados del centro
   se muestran solo al revelar Dudo o Calzo (V2); cada jugador ve solo su vista (V3).**
   Reemplaza el estado Flutter actual (dados visibles y legibles junto al vaso). La
   etapa 1 diseña la mesa así: estado normal con los 5 vasos cerrados y sin dados
   sueltos al centro; estado de revelación aparte, con dados al centro. Mi vaso es un
   objeto levantable (mecanismo VER visual; sin lógica de juego en esta etapa).
3. **Reglas IDÉNTICAS (ases, Paso, Kamikaze, Calzo).** Lista de casos que AMBAS
   versiones tienen que pasar: A1–A9 (apuestas y ases), P1–P14 (Paso), C1–C10 (Calzo),
   K1–K9 (Kamikaze), G1–G5 (generales de ronda), V1–V3 (dados ocultos/VER), N1–N2
   (jugadores). Ejemplos suyos incluidos: de 8 Cuatros se pasa a 4 Ases; calzar con
   11 de 20 iniciales SÍ recupera y con 10 NO; Kamikaze que deja a todos sin dados =
   empate. Estado Flutter: implementado en motor Dart + servidor (suites actuales
   Dart 77/77, servidor 31/31); la verificación caso por caso es trabajo del pase de
   paridad, no se da por hecha. Estado Unity: PENDIENTE, sin motor todavía. **Esta
   lista queda pendiente para la etapa de motor Unity; la etapa 1 sigue siendo solo
   visual y no avanza a gameplay.**

### DECISIONES FINALES 07:40 — resuelto (mandan sobre lo anterior, docs/19 actualizado)

- **A1 Calzo estricto:** se recupera solo si queda MÁS de la mitad
  (`totalActual × 2 > totalInicial`; con 20 iniciales, 11 sí recupera, 10 no).
  Cualquier prompt anterior que diga "al menos la mitad", incluido docs/18 §5,
  está equivocado: vale esta regla. (C2 y C3 quedan como están.)
- **A2 Reglas confirmadas, vigentes en Flutter y Unity, sin marca de pendiente:**
  P11 (máximo 1 Paso por jugador por ronda), P12 (Paso prohibido como primera
  jugada), P13 (Paso prohibido dos veces seguidas por el mismo jugador), C6
  (Calzo perfecto, solo Calzo, no calzoPaso — C7).
- **B5 Agitar y VER, ambos quedan, con funciones distintas:** agitar el celular
  LANZA los dados; VER los mira. (Resuelve la brecha 7 de abajo.)
- **B6 Revelación en cualquier resolución:** el centro muestra dados en Dudo, Calzo,
  duda de Paso y Kamikaze. En duda de Paso, solo la mano del jugador del Paso (P9).
  En Kamikaze, todos los dados nuevos al resolver. V2 queda actualizada en
  consecuencia. (Resuelve la brecha 8 de abajo; el render de revelación de la etapa 1
  cubre cualquier resolución, no solo Dudo/Calzo.)
- **C7 Tiers con nombres nuevos (mismos montos Flutter, en orden):** La Taberna 100,
  El Boliche 250, El Casino 500, La Mansión 1.000, El Club VIP 2.500 (porque el saldo
  inicial es 5.000). La etapa 1 sigue con El Casino 500 (paño carbón, la definitiva).
  (Resuelve la brecha 4 de abajo.)
- **C8 Barra superior, por ahora:** solo fichas, ajustes y menú. Regalo, misiones y
  amigos se agregan cuando existan sus funciones, sin botones que no hagan nada.
  (Resuelve la brecha 5 de abajo para esta etapa.)
- **C9 Chat fuera por ahora; se agregan reacciones rápidas (emotes) con animación.**
  La etapa 1 deja el slot del mockup (chat ≈8%) como slot de reacciones/emotes, sin
  animación (que es de etapa posterior); no se construye chat. (Resuelve la brecha 6
  de abajo para esta etapa.)
- **C10 Puestos vacíos en línea:** quedan libres, y al iniciar la sala el anfitrión
  elige entre completar con bots o jugar con los presentes. (Resuelve la brecha 9.)
- **D11 Flutter 8 → 5:** se aplica en el pase posterior al frente horizontal, como
  estaba previsto. No es trabajo de esta etapa.
- **D12 Unity etapa 1:** sigue como está, con 5 asientos; cualquier diferencia nueva
  se anota sin resolver. La etapa 1 continúa con estas decisiones finales.

### DECISIONES 07:43 — resuelto (se suman a las 07:40; docs/19 ya trae el caso C11)

- **C11 Calzo perfecto con total bajo — DECIDIDO:** se aplica la misma regla de la
  mitad. Con la mitad o menos (`totalActual × 2 ≤ totalInicial`), un Calzo exacto no
  da ni quita nada, y el perfecto TAMPOCO hace perder dados a los demás (nadie gana
  ni pierde; la ronda termina y el calzador parte). Reemplaza la postura anterior
  ("el perfecto se mantiene aunque el total sea bajo", sin cierre). Caso de prueba
  en ambas versiones; en Flutter exige ajuste del motor (Dart + servidor) en el pase
  de alineación. (Resuelve la brecha de perfecto con total bajo; la etapa 1 solo lo
  anota, sin gameplay.)
- **Build de prueba Unity — DECIDIDO: WebGL CON LINK, para verlo desde iPhone. NO
  TestFlight todavía.** Ojo honesto: Unity documenta que WebGL no soporta oficialmente
  móviles (memoria y potencia), así que el build WebGL debe ir optimizado para verse
  en iPhone (memoria chica, assets contenidos) y el link debe ser de PREVISUALIZACIÓN,
  nunca cacho.pages.dev. Consecuencia para la etapa 1: los assets Blender se mantienen
  contenidos (pocos polígonos, texturas modestas) como requisito del build de prueba.
  El link de previsualización se define cuando exista el build (tras el desbloqueo de
  licencia); no se promete ninguna URL ahora.
- **APK de Flutter — DESCARTADA, no se reintenta.** No es frente de esta etapa; se
  anota solo para no mezclarla con el build WebGL.
- **NO despliegue a producción** hasta que el usuario acepte la mesa Y lo pida
  explícitamente: producción queda intacta.
- **Mesa NO aceptada:** el informe final con capturas se entrega después, cuando la
  etapa 1 y el frente horizontal entreguen; tribunal ronda 2 y P1–P21 quedan para
  entonces. Nada se da por aceptado en esta etapa.
- **Nota de vigencia sobre docs/19:** su sección final de abiertas todavía lista como
  "sin decisión" tres puntos que las decisiones 07:43 ya resolvieron (perfecto con
  total bajo, ruta de prueba, APK paralela Flutter). Este informe registra las
  decisiones 07:43 como vigentes; la actualización de esa sección de docs/19 queda en
  manos del usuario/coordinación, no se editó docs/19 desde esta etapa (repo Flutter
  sin tocar).

### CORRECCIÓN DEL USUARIO 09:35 — manda (se suma a todo lo anterior)

- **SEIS JUGADORES MÁXIMO, no 5 ("me equivoqué eran 6").** Distribución del mockup:
  1 arriba al centro, 2 a la izquierda, 2 a la derecha y yo abajo al centro, con CERO
  solapes. La etapa 1 va con 6 asientos. La pila de la columna superior (avatar
  superior-central → su placa → placa del pozo → vaso de la columna) es el punto
  estrecho: sus valores en el esqueleto son provisionales y la prueba es la medición
  de cajas del render Blender (0 solapes o el solape medido, informado con honestidad).
  docs/19 N1 todavía dice 2 a 5: quedó desactualizado por esta corrección; su
  actualización queda en manos de la coordinación (docs/19 NO se editó desde esta
  etapa, repo Flutter sin tocar). La alineación Flutter pasa de 8→5 a 8→6 (D11, en el
  pase posterior al horizontal).
- **REVELACIÓN LEGIBLE (manda para renders y storyboard).** El usuario rechazó dados
  de revelación porque no se alcanzan a leer. Regla: ningún dado mostrado puede ser
  pequeño e ilegible; todo dado visible debe leerse a tamaño real, sin solapes, con
  los que cuentan destacados uno a uno. NO se mantiene una revelación con todas las
  manos en pequeño al centro: si hay que mostrar varias manos, se hace en fotogramas
  secuenciales con dados grandes y legibles. Aplica al render de revelación y al
  storyboard Dudo de la etapa 1, y queda como requisito para la UI de revelación
  Unity futura.
- **MICRÓFONO (voz) Y MÚSICA SE MANTIENEN.** El usuario percibe que se quitaron en
  Flutter; en el alcance visual NO se diseñan fuera (llegan en etapas posteriores,
  pero no quedan eliminadas). TopBar de la etapa 1: fichas, micrófono, música/DJ,
  ajustes y menú. El chat de TEXTO sigue fuera (C9); los emotes se quedan.

1. **Link Unity WebGL = SOLO PARA MIRAR (diseño y animaciones), NO para juzgar
   rendimiento.** WebGL en iPhone puede ir lento o fallar por memoria; el rendimiento
   se mide después con un build nativo.
2. **Mientras no haya un build verificado, el borrado de los 9 JSON queda SIN
   COMPROBAR.** Producción no cambió, así que no hay riesgo, pero la mesa NO se acepta
   hasta que se confirme que el build pasa.

**Los 6 puntos que mirará en las capturas de la etapa 1, y cómo se verifica cada uno:**

| # | Lo que mira | Cómo lo verifica la etapa 1 |
|---|---|---|
| 1 | Cinco jugadores, uno arriba al centro, dos a cada lado y yo abajo con el vaso grande | CORREGIDO 09:35: son SEIS jugadores máximo ("me equivoqué eran 6"), distribución del mockup: 1 arriba al centro, 2 a la izquierda, 2 a la derecha y yo abajo al centro, con CERO solapes. Render hero con 6 asientos + pozo en la columna superior (pila: avatar superior-central → su placa → placa del pozo → vaso de la columna). La prueba de cero solapes es la medición de cajas del render, no la afirmación. La nota aritmética anterior (5 vs 1+2+2+1) queda resuelta por esta corrección: eran 6. |
| 2 | Mis dados ocultos y sin dados sueltos en el centro, fuera de una revelación | Render hero normal: 6 vasos cerrados, sin dados al centro (V1–V2). Render de revelación aparte, marcado como tal (cualquier resolución, B6), CON LA REGLA DE LEGIBILIDAD 09:35: ningún dado pequeño e ilegible; todo dado visible se lee a tamaño real, sin solapes, con los que cuentan destacados uno a uno. NUNCA una revelación con todas las manos en pequeño al centro (eso ya fue rechazado por ilegible). |
| 3 | Pozo arriba al centro y apuesta actual siempre visible | Hero con placa del pozo arriba al centro + indicador de apuesta actual visible (apuesta de EJEMPLO en el render, marcada como ejemplo, no como dato vivo). Pendiente de incorporar como elemento `CurrentBet` al ensamblar la escena en Unity (la definición entregada por el frente de escena no lo incluía). |
| 4 | Madera gruesa y paño con textura, sin degradado plano | Borde de madera grueso con veta + paño con textura procedural visible (ruido/fibra), nunca color plano ni degradado plano. Requisito explícito al modelador; se verifica en el render hero. |
| 5 | Placas pegadas bajo cada avatar, sin tapar la barra superior ni salirse del óvalo | Placas directamente bajo cada avatar, dentro del óvalo, sin tocar la barra superior. Se verifica en el render hero. |
| 6 | Que se mueva: vela, avatares y aro del turno, y que el Dudo tenga su secuencia | CON HONESTIDAD DE ETAPA: la secuencia jugable de Dudo es etapa 3 y no hay Unity Editor aquí, así que la etapa 1 NO entrega gameplay. Entrega: (a) clip corto de movimiento a nivel de asset si el presupuesto CPU lo permite (vela, respiración, pulso del aro) o, en su defecto, tira de fotogramas + costo medido y nota honesta; (b) storyboard de la secuencia Dudo en 5–6 fotogramas (pausa, vasos uno por uno, dados, conteo iluminado, veredicto) marcado como definición, no como secuencia jugable; (c) slots de animación definidos en la escena (vela, respiración, pulso del aro) para las etapas siguientes. |

Nada de esto cambia las decisiones anteriores; solo fija cómo se juzgará la entrega.

### ABIERTO — ANOTADO, NO RESUELTO (tras las decisiones finales 07:40)

4. **Tiers:** RESUELTO por C7 (La Taberna 100 / El Boliche 250 / El Casino 500 /
   La Mansión 1.000 / El Club VIP 2.500). La etapa 1 usa El Casino 500.
5. **Barra superior:** RESUELTO por ahora por C8 (solo fichas, ajustes y menú;
   regalo/misiones/amigos cuando existan sus funciones, sin botones muertos).
6. **Chat:** RESUELTO por ahora por C9 (chat fuera; reacciones rápidas/emotes con
   animación en etapa posterior; la etapa 1 deja el slot como emotes, sin animación).
7. **Agitar el celular:** RESUELTO por B5 (agitar LANZA, VER mira; ambos quedan).
8. **Revelación en duda de Paso y en Kamikaze:** RESUELTO por B6 (centro en cualquier
   resolución; duda de Paso solo la mano del jugador del Paso; Kamikaze todos los
   dados nuevos al resolver).
9. **Puestos vacíos en línea:** RESUELTO por C10 (libres; el anfitrión elige al
   iniciar: completar con bots o jugar con los presentes).
10. **Arriba al centro (residuo visual):** docs/18 §2 dice "1 arriba al centro" como
    jugador; el mockup y Flutter ponen el POZO arriba al centro. Con 5 jugadores
    decididos, la mesa usa: pozo arriba al centro + 5 jugadores (superior-izquierda,
    superior-derecha, medio-izquierda, medio-derecha, yo abajo al centro). La
    redacción de §2 queda anotada como divergencia, no reinterpretada por cuenta propia.
    Agravante detectado por el analista: la enumeración de §2 (1 arriba + 2 a la
    izquierda + 2 a la derecha + yo abajo) suma 6 posiciones, no 5; el texto "exactamente
    5" y su propia enumeración no cuadran entre sí. Sin decisión explícita que elimine
    el asiento superior.
11. **Placas:** docs/18 §2 pide nombre, fichas y nivel; Flutter muestra nombre y
    conteo de dados (sin nivel visible). Sin decisión.
12. **Calzo y Kamikaze (redacción §5 vs lista de casos):** RESUELTO en lo general por
    A1 (estricto MÁS de la mitad; docs/18 §5 "al menos la mitad" está equivocado) y A2
    (P11/P12/P13/C6 vigentes). RESUELTO también el perfecto con total bajo por C11
    (07:43): con la mitad o menos, el perfecto TAMPOCO hace perder dados a los demás.
    Queda pendiente su verificación como caso de prueba en la etapa de motor (y el
    ajuste del motor Flutter en el pase de alineación).
13. **Tienda / gemas / progresión:** siguen su secuencia propia (después de auth);
    no se adelantan por paridad.
14. **Avatares:** docs/18 §1 pide arte 2D generado con IA y limpiado, siempre original;
    Flutter usa Blobatar para TODOS en mesa (hue 45 dorado, semilla estable). La etapa 1
    deja el slot de avatar sin arte final: Unity no copia Blobatar por su cuenta ni
    genera retratos sin decisión. Sin decisión.
15. **Ruta de prueba de los builds Unity:** RESUELTO 07:43 — WebGL CON LINK para
    verlo desde iPhone; NO TestFlight todavía. Con el ojo honesto: Unity no soporta
    oficialmente WebGL en móviles, así que el build va optimizado (memoria chica,
    assets contenidos) y el link es de PREVISUALIZACIÓN, nunca cacho.pages.dev. El
    build en sí sigue bloqueado por la licencia Unity (sección 2).
16. **APK paralela Flutter:** DESCARTADA 07:43, no se reintenta. No es trabajo de
    esta etapa.
17. **Despliegue a producción:** requiere que el usuario acepte la mesa Y lo pida
    explícitamente; producción sigue siendo el diseño del 25-oct 02:24, intacta.
    No es trabajo de esta etapa.
18. **Aceptación de la mesa:** NO aceptada. El informe final con capturas se entrega
    después, cuando la etapa 1 y el frente horizontal entreguen; tribunal ronda 2
    pendiente de ese informe final.
19. **Detalles de mesa P1–P21:** APOSTAR, pozo centro o centro+barra, tamaño del vaso
    rival, y resto de pendientes del tribunal. Sin decisión.
20. **Auth Firebase + billetera nube, tienda de gemas/monedas, ranking y niveles:**
    siguen su secuencia propia (auth después de la mesa; tienda después de auth;
    fórmulas de ranking/niveles pendientes de sus decisiones). Emparejamiento sigue
    diferido por su orden.
21. **Regla futura diferida:** todo jugador empieza con 10.000, solo después de
    terminar esto y con su confirmación.
22. **Capturas vivas pendientes:** calzo bloqueado, Kamikaze a ciegas,
    AN6/AN12/AN13/AN14/AN18 en producción. No son de esta etapa.
23. **Limpieza:** 9 JSON de generación en `app/assets/images/` (bloat del build, sin
    efecto funcional). Borrado pendiente de decisión. No es trabajo de esta etapa.

## 7. Qué NO se hizo en esta etapa (a propósito)

- Nada de gameplay, reglas, bots, animaciones de juego, audio, háptica, menú, lobby,
  progresión, cuentas ni tienda. Todo eso son etapas 2–7 y requieren aprobación de la
  etapa 1 primero, y varias requieren además las decisiones de paridad de la sección 6.
- Nada en `~/workspace/cacho/`, nada desplegado, nada commiteado en el repo del juego.
- Nada de barra superior ni consola inferior en los renders Blender (existen solo en
  la definición de escena Unity, §4): si el usuario exige verlas en la captura, es
  trabajo pendiente, no un olvido silencioso.

## 8. ENTREGA FINAL DE LA ETAPA 1 — estado y qué falta para que se acepte

**Entregado (verificado en disco y a ojo por el coordinador):** escena Blender +
glb/fbx + renders hero (6 asientos, estado normal), revelación legible + conteo uno
a uno, storyboard Dudo (6 fotogramas, definición), clip de movimiento de assets
(2 s), detalle vaso+dados, esqueleto Unity (TableLayout 2–6, definición de escena,
slots de assets, PARIDAD.md). Todo en `~/workspace/cacho-unity/`.

**NO entregado / NO afirmado:** build Unity, APK, link WebGL de previsualización,
captura de Unity (bloqueo de licencia vigente, §2); barra superior y consola en
renders; diezmo de textos para el presupuesto WebGL iPhone; render de puestos vacíos
en línea (C10, abierto); borrado de los 9 JSON sin comprobar (sin build verificado);
tribunal ronda 2 y P1–P21 (para cuando esta etapa y el frente horizontal entreguen).

**Decisiones propias del modelador que el usuario debe validar si quiere (NO son
órdenes suyas):** logo en y=-0.80 y vaso superior-central 0.75×.

**La mesa NO está aceptada.** El informe final con capturas de la etapa 1 es este
documento + los renders listados en §3; la aceptación, el tribunal ronda 2 y
cualquier despliegue o link quedan para su decisión explícita. Producción intacta
(diseño 25-oct 02:24); APK Flutter descartada; WebGL futuro solo de previsualización
(nunca cacho.pages.dev) y solo para mirar, no para juzgar rendimiento.
