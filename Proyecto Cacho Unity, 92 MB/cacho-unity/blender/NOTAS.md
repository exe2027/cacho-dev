# CACHO UNITY — ETAPA 1 (modelado Blender) — NOTAS

Etapa 1 SOLO visual: mesa + assets. Sin gameplay, sin reglas, sin código Unity,
sin tocar `~/workspace/cacho/`. Todo lo que sigue se verificó con renders reales;
lo que no se pudo verificar se dice como pendiente, no se finge.

## 1. Qué se modeló (escena final, 6 asientos)

- Mesa ovalada: borde grueso de madera nogal oscura (sRGB 0.29,0.18,0.09, ruido
  escala 8, relieve 0.35, pared lateral 0.55 m) + paño carbón (sRGB 0.20,0.20,0.21,
  ruido escala 40, relieve 0.25, NUNCA color plano ni degradado plano) + filetes
  dorados mate #C9A24B (sRGB 0.79,0.63,0.29) en toroides. Fondo: telón + 7 lámparas
  esféricas cálidas que se ven como bokeh (la central se retrocedió a y=6.5 para
  no tapar el disco superior-central).
- Logo "CACHO O DUDO" en dos líneas + anillo dorado, grabado en el paño.
  Posición FINAL (0,-0.80): se bajó desde el centro (0,0.75) por una razón medida
  (ver §5): con el logo centrado, el vaso superior-central tapaba el texto del
  pozo o el del logo; abajo del centro, ambos quedan limpios. Es una decisión
  de diseño propia, no una orden del usuario.
- 6 vasos de cuero boca abajo con posavasos (cuero sRGB 0.43,0.27,0.15):
  Don Chalo, LaPituca, ElGuatón, LaCuca (1.0×), El Huaso superior-central (0.75×:
  en perspectiva se ve casi igual que los rivales 1.0×, que están más lejos)
  y TÚ abajo (1.25×, GRANDE). Mi vaso es un objeto separado levantable
  (mecanismo VER visual, sin lógica). AGITAR es otra mecánica (lanza los dados)
  y NO se modela como "ver": son funciones distintas.
- 6 asientos (tokens abstractos: disco + aro de color + iniciales, sin caras ni
  fotos): Don Chalo (CH, rojo), La Pituca (PI, azul), El Guatón (GU, morado),
  La Cuca (CU, verde azulado), El Huaso (HU, naranja, sexto jugador añadido por
  la corrección 09:35 "me equivoqué eran 6") y TÚ (dorado). NUNCA se usaron
  nombres ni caras del mockup ni de otros juegos.
- Placas bajo cada avatar (nombre + fichas + "NV 1"): "NV 1" es MARCADOR DE
  POSICIÓN, no dato real (el nivel existe en Flutter solo como concepto futuro).
- Placa combinada POZO+APUESTA arriba al centro (3.4×0.70): "POZO 3.000" a la
  izquierda, "APUESTA ACTUAL / 5 Quintas / (EJEMPLO)" a la derecha. La apuesta
  es un EJEMPLO marcado, no un dato vivo de partida. Dos placas separadas no
  cabían sin solapes (ver §5); la combinada sí, con márgenes medidos.
- Pila de 5 fichas + 3 sueltas a la izquierda del centro superior.
- Slot de reacciones ":)" abajo a la izquierda (posición del botón de chat del
  mockup): SIN animación en esta etapa, SIN chat de texto (C9, el chat queda
  fuera; las reacciones rápidas con animación llegan en etapa posterior).
- Mis dados (5, tamaño 0.30) ocultos bajo mi vaso; dados de revelación (5,
  tamaño 0.34 en escena, 0.55 en primer plano) ocultos en el hero.
- Sin barra superior modelada en la escena 3D. Cuando se modele llevará, por C8,
  solo fichas, ajustes y menú, MÁS micrófono (voz) y música/DJ: el usuario
  ordenó (09:35) que micrófono y música SE MANTIENEN, no se diseñan fuera.
  Llegan en etapas posteriores; aquí no se eliminó nada.
- Cámara hero: (0,-11.0,9.9), rotación 0.815, lente 35, DOF f/4, foco (0,0,0.2).

## 2. Cifras de paridad Flutter (reales, no del mockup)

- Saldo inicial en placas: 5.000 para todos. Pozo: 3.000 = El Casino 500 × 6.
- Tier de la escena: El Casino 500 (paño carbón, la definitiva).
- Tiers con nombres nuevos (C7, mismos montos Flutter): La Taberna 100,
  El Boliche 250, El Casino 500, La Mansión 1.000, El Club VIP 2.500.
- Mano de ejemplo de la revelación: dados [5, 1, 5, 3, 2] para la apuesta de
  ejemplo "5 Quintas". Cuentan los 5 y el 1-comodín: dados 1º, 2º y 3º.

## 3. Renders entregados (todos desde el blend final)

- `renders/mesa_hero.png` — estado NORMAL (6 vasos cerrados, SIN dados al
  centro, pozo arriba al centro). 1688×950.
- `renders/mesa_revelacion.png` + `renders/revelacion/2_cuenta_1.png`,
  `3_cuenta_2.png`, `4_cuenta_3.png` — secuencia de revelación legible en
  primer plano (ver §6). 1688×950.
- `renders/storyboard_dudo/` — 1_pausa, 2_primer_vaso, 3_vasos_levantados
  (960×540, plano general) + 4_dados_cayendo, 5_dados_que_cuentan, 6_veredicto
  (1688×950, primer plano). Es un STORYBOARD DE DEFINICIÓN, no una secuencia
  jugable (la secuencia jugable de Dudo es de etapa 3 y aquí no hay Unity
  Editor; no se finge gameplay).
- `renders/movimiento_assets.mp4` — clip de movimiento a nivel de asset: 2 s,
  12 fps, 960×540, H.264 (24 fotogramas en `renders/movimiento/`). Anima:
  parpadeo de lámpara (3 Hz + 7 Hz), respiración sutil de avatares (±1.5%),
  pulso del aro del turno (±6%, 1 Hz) y push-in leve de cámara. NO es gameplay.
- `renders/detalle_vaso_dados.png` — primer plano: mi vaso alzado a un lado +
  mis 5 dados con caras variadas [1, 2, 5, 3, 6] (sin 5 ases). 1688×950.
- Historial conservado: `mesa_hero_v1/v2/v3/v5/v6c.png`. El hero v4 (5 asientos,
  aceptado visualmente antes de la corrección a 6) se perdió al ser sobrescrito
  sin respaldo; no existe `mesa_hero_v4.png`.

## 4. Cómo se renderizó

- Motor: Cycles CPU (EEVEE no corre en esta VM: falta libEGL). Denoiser activo,
  muestreo adaptativo (umbral 0.10 hero/detalle/revelación, 0.15 storyboard/clip;
  mínimo 16 hero/detalle/revelación, 8 storyboard/clip), rebotes difuso 3 /
  brillo 3 / transmisión 0 / transparente 2, sin cáusticas.
- Muestras: hero 64, detalle 48, revelación 48, storyboard 32, clip 32.
  NUNCA dejar las muestras por defecto (4096 → 10+ horas; ese fue el fallo de
  la primera corrida de la etapa).
- Tiempos medidos en pared (VM compartida con otros agentes; la velocidad
  fluctúa): hero final ≈12 min; revelación 4 fotogramas ≈29 min; corrección
  revelación 2 fotogramas ≈11 min; storyboard 6 fotogramas ≈15 min;
  correcciones storyboard F6 ≈4 min y F4 ≈3 min; clip 24 fotogramas ≈21 min;
  detalle ≈5 min. Total de render de esta ventana ≈100 min.
- Materiales procedurales (ruido + relieve + mezcla atenuada a 0.4) con helper
  sRGB→lineal (pasar sRGB directo lavaba la madera en v1/v2). Luces: clave
  área (0,-5,9) 1600 W cálida, relleno punto (-7,-6,4) 350 W, contraluz punto
  (0,7,5) 700 W. El grano procedural fino vive solo en el .blend: el exportador
  glTF no hornea ruido procedural a textura (el GLB lleva color base, rugosidad
  y metalicidad).

## 5. Medición de solapes (proyección AABB a cámara hero, 1688×950)

Columna superior final (mundo): disco El Huaso (0,4.85), su placa (0,3.59),
placa POZO+APUESTA (0.10,2.39), vaso superior-central (0,1.00). Huecos:
disco-placa 1.26, placa-POZO 1.20. Placas laterales 1.26 bajo su disco
(placas y 1.04 sup., y -1.81 medios). TÚ: disco (0,-3.70), placa (0,-4.75),
vaso (0,-2.50).

Resultado FINAL (medido, no afirmado):
- SIN recortes de cuadro.
- CERO solapes reales entre tokens de asientos DISTINTOS (discos, placas y
  vasos): todos los solapes disco-placa, placa-placa, placa-vaso y vaso-placa
  entre asientos quedaron en 0.
- CERO solapes vaso-POZO, placa-POZO y logo-vaso (tras v6c).
- Textos POZO y apuesta DENTRO de la placa con márgenes (POZO 9 px abajo /
  3 px arriba; apuesta 11 px abajo / 7 px arriba / 10 px derecha).
- Residuos que se informan tal cual (no se ocultan):
  1. Avatar_TU × Vaso_TU: 148×75 px. Capa INTENCIONADA: el token de TÚ va
     delante de su propio vaso grande, como en el hero v4 aceptado. No es una
     colisión entre asientos.
  2. Vaso_DonChalo × PilaFichas: 9×35 px de CAJA-UNIÓN, pero 0 px real ficha
     por ficha (verificado una por una: la unión sobreestima porque combina
     fichas separadas). No hay solape real.
  3. El anillo del logo queda parcialmente tapado por el vaso superior-central
     (oclusión 3D normal de un objeto físico sobre un paño impreso, no
     solape token-token; en el hero final el texto "CACHO O DUDO" queda intacto
     y legible).
- Por qué no se forzó el cero absoluto en la pila: con los tamaños actuales,
  una pila con cero solapes + logo centrado intacto + disco dentro del cuadro
  es geométricamente imposible (el vaso alto proyecta muy arriba y el hueco
  necesario placa-POZO-vaso es ~1.65-1.70 mundo). Por mandato del usuario ("si
  la pila no cabe limpia, dilo con la medida en vez de comprimirla"), NO se
  achicó ni aplastó el logo ni se movió abajo solo para forzar el cero. Lo que
  se hizo: vaso superior-central a 0.75× (en perspectiva iguala a los rivales),
  placa combinada de 3.4 (no 6.46: el operador hornea la escala en la malla y
  un `scale.x=3.4` inicial dio una placa doble — detectado y corregido a
  3.4/1.9), logo bajado a y=-0.80 y lámpara central retrocedida a y=6.5.
  Con eso, la pila superior quedó con 0 solapes token-token (salvo el residuo
  TÚ-sobre-su-vaso, que es de otro asiento y es intencionado).

## 6. Regla de legibilidad de la revelación (corrección 09:35)

La revelación vieja (5 dados pequeños al centro) quedó RECHAZADA por ilegible
y se sustituyó por completo. Regla aplicada en revelación y storyboard:
NINGÚN dado mostrado es pequeño ni ilegible: todo dado visible se lee a
tamaño real (0.55 en primer plano), sin solapes entre dados, con los que
cuentan destacados UNO A UNO en secuencia (discos dorados, emisión 8, radio
0.45; el disco del dado central va a z 0.12 porque ese dado cae sobre el
posavasos negro, si no quedaba tapado). Si hay que mostrar varias manos, se
hace en fotogramas secuenciales, nunca en un solo cúmulo pequeño.
- Secuencia: fotograma 1 mano [5,1,5,3,2] sin destacar; 2 cuenta el 1º (5);
  3 cuentan 1º+2º (5+1); 4 cuentan 1º+2º+3º (5+1+5).
- Cobertura B6 (revelación ampliada): el centro muestra dados en CUALQUIER
  resolución (Dudo, Calzo, duda de Paso, Kamikaze); en duda de Paso solo la
  mano del jugador del Paso (P9); en Kamikaze todos los dados nuevos al
  resolver. Esta secuencia es de REFERENCIA para cualquier resolución, no una
  resolución viva.
- En los fotogramas de conteo los vasos se apartan (en el storyboard F4 ya se
  ven levantados): el vaso superior-central caía en pantalla sobre el dado
  central; ocultarlo es lo que deja los 5 dados limpios.

## 7. Verificación de los 6 puntos del usuario (07:46)

1. SEIS JUGADORES (corregido 09:35; el 07:46 decía 5 pero el usuario corrigió
   a 6): composición del mockup, 1 arriba al centro, 2 a cada lado, yo abajo
   con el vaso GRANDE. Verificado en el hero.
2. MIS DADOS OCULTOS y SIN dados sueltos en el centro fuera de una revelación:
   hero normal con vasos cerrados, sin dados al centro; revelación aparte y
   marcada como tal. Verificado.
3. POZO ARRIBA AL CENTRO Y APUESTA ACTUAL SIEMPRE VISIBLE: placa combinada
   legible en el hero ("POZO 3.000" + "APUESTA ACTUAL 5 Quintas (EJEMPLO)").
   La apuesta es EJEMPLO, no dato vivo. Verificado.
4. MADERA GRUESA Y PAÑO CON TEXTURA, SIN DEGRADADO PLANO: borde grueso con
   veta procedural y paño carbón con fibra procedural, visibles en el hero.
   Verificado.
5. PLACAS PEGADAS BAJO CADA AVATAR: todas bajo su disco (hueco 1.26), sin
   recortes de cuadro. La barra superior NO está modelada (llega en otra
   etapa), así que no hay nada que tapar; las placas laterales quedan en el
   borde del óvalo, como en el mockup. Verificado con la medición (§5).
6. QUE SE MUEVA: (a) clip de 2 s entregado (§3); (b) storyboard de 6
   fotogramas entregado, marcado como DEFINICIÓN, no jugable. La secuencia
   jugable de Dudo es de etapa 3 y aquí no hay Unity Editor: no se finge
   gameplay. Verificado.

## 8. Casos docs/19 pendientes para la etapa de motor Unity (NO esta etapa)

La lista A1–A9, P1–P14, C1–C10, K1–K9, G1–G5, V1–V3, N1–N2 queda pendiente
para la etapa de motor Unity, no para esta etapa visual. Incluye, como casos
de prueba anotados:
- Calzo ESTRICTO (A1): se recupera SOLO si queda MÁS de la mitad
  (totalActual×2 > totalInicial; con 20 iniciales, 11 sí, 10 no). Cualquier
  texto anterior que diga "al menos la mitad" (incluido docs/18 §5) está
  equivocado.
- C11 Calzo perfecto con total bajo: con la mitad o menos, un Calzo exacto no
  da ni quita nada, y el perfecto TAMPOCO hace perder dados a los demás
  (nadie gana ni pierde; la ronda termina y el calzador parte). En Flutter
  exigirá ajuste del motor en el pase de alineación.
- P11, P12, P13 y C6 SON reglas vigentes sin marca de pendiente.
- V1/V2/V3: mis dados ocultos bajo mi vaso, solo visibles con VER; centro solo
  en resolución (B6, §6).
- Agitar (lanza los dados) vs VER (los mira): funciones DISTINTAS.
- Puestos en línea (C10): quedan libres; al iniciar, el anfitrión elige
  completar con bots o jugar con los presentes. El render de puestos vacíos
  en línea queda ABIERTO/pendiente (no se entregó en esta etapa).

## 9. WebGL, producción y aceptación (fijado, no ejecutado aquí)

- Build de prueba Unity: WebGL CON LINK, para verlo desde iPhone. NO
  TestFlight todavía. El link será de PREVISUALIZACIÓN, nunca cacho.pages.dev.
- WebGL NO soporta oficialmente móviles (memoria y potencia, según Unity):
  el futuro link es SOLO PARA MIRAR diseño y animaciones, NO para juzgar
  rendimiento (en iPhone puede ir lento o fallar por memoria; el rendimiento
  se mide después con build nativo). Por eso los conteos se mantuvieron
  contenidos (ver §10); las texturas procedurales no viajan al GLB.
- APK de Flutter: DESCARTADA, no se reintenta (no es este frente).
- NO se despliega a producción hasta que el usuario acepte la mesa Y lo pida
  explícitamente; producción queda intacta. La mesa NO está aceptada: el
  informe final con capturas se entrega después, cuando esta etapa 1 y el
  frente horizontal entreguen; tribunal ronda 2 y P1–P21 quedan para entonces.
- Mientras no haya un build verificado, el borrado de los 9 JSON queda sin
  comprobar (producción sin cambios, sin riesgo).

## 10. Conteo de polígonos (malla evaluada, blend final)

| Colección | Polígonos |
|---|---|
| Mesa | 2.500 |
| Vasos | 14.520 |
| Dados | 5.160 |
| Fichas | 858 |
| Asientos | 123.475 |
| Fondo | 3.635 |
| Logo | 10.145 |
| TOTAL | 160.293 |

Lectura honesta: ~124.000 de esos 160.293 son textos e iniciales convertidos
a malla (estáticos, sin animación): las placas (73.435), el texto del pozo
(9.595), el texto de apuesta (20.465), el texto del logo (8.993) y las
iniciales (~9.200). Los props 3D reales (mesa, vasos, dados, fichas, discos,
aros, fondo, anillo) son ≈36.000. Los textos son candidatos a diezmar en la
importación Unity; no se tocaron aquí para no arriesgar la legibilidad de los
renders que se juzgan. (En v5 el conteo era 36.795 porque los textos aún eran
objetos FONT y no contaban como malla; el salto no es geometría nueva, es la
conversión a malla para exportar.)

## 11. Archivos

- `blender/mesa_cacho.blend` (19.508.232 B) — escena completa, colecciones
  Mesa, Vasos, Dados, Fichas, Asientos, Fondo, Logo. Sin objetos huérfanos.
- `blender/mesa_cacho.glb` (11.050.076 B) — glTF binario con materiales.
- `blender/mesa_cacho.fbx` (6.808.140 B).
- `renders/mesa_hero.png`, `renders/mesa_revelacion.png`,
  `renders/revelacion/*.png`, `renders/storyboard_dudo/*.png`,
  `renders/detalle_vaso_dados.png`, `renders/movimiento_assets.mp4` (+
  `renders/movimiento/frame_*.png`).
- Scripts: `blender/build_mesa.py` (construcción; OJO: su cámara y posiciones
  son pre-parche, NO re-ejecutar sin actualizar), `blender/patch_v6.py`,
  `patch_v6b.py`, `patch_v6c.py`, `patch_v6d.py`, `patch_v6e.py`,
  `patch_v6f.py`, `patch_v6g.py` (parches aplicados en orden; no re-ejecutar),
  `blender/reveal_seq.py`, `blender/reveal_fix.py`, `blender/storyboard_dudo.py`,
  `blender/story_f4_fix.py`, `blender/story_f6_fix.py`,
  `blender/clip_movimiento.py`, `blender/detalle_fix.py`,
  `blender/measure_overlaps.py`, `blender/count_polys.py`,
  `blender/export_final.py`, `blender/hero_render.py`.

## 12. Diferencias visibles contra el mockup (de la más visible a la menos)

1. Avatares abstractos con iniciales (disco + aro + letras) en vez de fotos
   de perfil: decisión propia para no copiar nada del mockup.
2. Sin consola inferior de apuesta (APOSTAR 1–6 + CALZO + DUDO + PASO) ni barra
   superior: son UI de otra etapa, no assets 3D. El hero muestra solo la mesa.
3. La mesa 3D se ve con perspectiva real (óvalo en fuga, vasos con volumen)
   frente al mockup 2D cenital; los vasos rivales se ven más pequeños por
   distancia y el mío más grande (1.25×) por cercanía y escala.
4. El logo está debajo del centro (y=-0.80) en vez de centrado, y el vaso
   superior-central es más pequeño (0.75×): obligados por la legibilidad del
   pozo y del logo (§5). En el mockup el logo está centrado y no hay vaso
   superior-central (esa posición la ocupaba el pozo).
5. El pozo es una placa combinada con la apuesta (POZO + APUESTA ACTUAL) en
   vez de dos placas separadas: dos placas no cabían sin solapes.
6. La pila de fichas está a la izquierda del centro superior; en el mockup no
   existe pila de fichas (el pozo era solo una placa).
7. El anillo del logo queda parcialmente tapado por el vaso superior-central
   (oclusión 3D normal); en el mockup el anillo está completo.
8. Las lámparas del fondo se ven como bokeh blanquecino (emisión alta) en vez
   de una taberna detallada: fondo abstracto deliberado, sin personas ni texto
   legible salvo el logo.
9. El slot de reacciones ":)" ocupa el lugar del botón de chat del mockup
   (el chat de texto está fuera por C9).
10. Las placas dicen "NV 1" (marcador) y saldos 5.000 / pozo 3.000 (paridad
    Flutter) en vez de las cifras del mockup.

## 13. Limitaciones honestas (qué NO quedó)

- Sin render de puestos vacíos en línea (C10, abierto).
- Sin animaciones de juego, sin bots, sin reglas, sin audio, sin barra
  superior, sin micrófono/música como objetos (solo la nota de que NO se
  eliminan, §1).
- Sin gameplay ni código Unity (`unity/Assets/` existe pero no es de este
  encargo y no se tocó).
- El clip es movimiento a nivel de asset (2 s), no una secuencia jugable.
- Dos renders murieron a mitad de corrida en esta ventana (revelación v1 a los
  ~7 min y detalle v1 al arrancar) por limpieza de sesiones del runtime; se
  relanzaron como sesiones seguidas y terminaron bien. Los archivos finales
  son los verificados en §3.
- No se tocó `~/workspace/cacho/` en ningún momento.
