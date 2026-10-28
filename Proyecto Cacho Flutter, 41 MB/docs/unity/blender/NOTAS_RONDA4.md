# RONDA 4 — Parámetros guardados en `mesa_cacho_ronda4.blend`

Blend sucesor de `mesa_cacho_ronda3.blend` (ronda 3 intacta).
Scripts: `patch_ronda4.py`, `fix_ronda4.py`, `fix2_ronda4.py`,
`fix3_ronda4.py`, `fix4_ronda4.py`, `fix5_ronda4.py`, `fix6_ronda4.py`,
`fix7_ronda4.py`, `fix7b_ronda4.py`, `fix8_ronda4.py`,
`render_ronda4.py` (entrega), `preview_ronda4.py` (844×475),
`proyectar_ronda4.py`, `proyectar_mesa.py`, `measure_ronda4.py`,
`count_rings.py`. Renders en `renders/ronda4/` (1688×950).

## Cámara y luces
- Cámara `CamaraHero`: (0, −12.85, 9.2), rot X 0.9494 rad, lens 32.
  0.888 enterraba la línea «×5» de la placa TÚ bajo la consola;
  0.9336 dejaba el borde inferior de la placa 4 px bajo la consola
  (placa 670–738, consola desde 734); 0.9494 es el punto más cenital
  con la placa íntegramente libre (placa 663–731, consola 734).
  Más cenital que ronda 3 (0.965) en 0.016 rad.
- Luces sin cambio respecto a ronda 3: Clave AREA 400, Contraluz
  POINT 180, Relleno POINT 85. Paño `PanoCarbon` #1D1717.
  Mesa (madera) 85.0 %W en pantalla (ronda 3: 85.1 %W); paño 72.0 %W.
- View transform Filmic, Medium Contrast, exposición 0, gamma 1,
  sin nodos de compositor. Sin denoiser.

## Colores guardados (emisión sobre base negra, fuerza 1.0)
- Oro `R2_OroMate`: (0.708, 0.320, 0.0516). Medido en PNG final:
  moneda (193,157,71) Δ (−8,−5,−4) vs #C9A24B; anillo TÚ
  (184,148,70) Δ (−17,−14,−5) vs objetivo, (−9,−9,−1) vs moneda.
- CALZO (0.0035, 0.182, 0.0724) → PNG (13,129,85) Δ (−1,+7,+6)
  vs #0E7A4F. DUDO (0.579, 0.0157, 0.0259) → (184,35,48)
  Δ (+5,+3,+6) vs #B3202A. PASO (0.006, 0.0912, 0.140) →
  (19,95,115) Δ (−1,+7,+8) vs #14586B.

## Consola (HUD, padre CamaraHero; z: consola −3.00, botones/tiles
## −2.98, iconos/pips −2.96, pips de icono −2.94)
- Botones: ancho 0.47 (escala x 0.235), centros 0.28/0.81/1.34;
  textos +0.03; iconos dado 0.07/0.60; barras PASO 1.13/1.18.
  Medido en PNG: CALZO 867–1103, hueco 28 px, DUDO 1132–1372,
  hueco 26 px, PASO 1399–1638 = borde derecho 97.0 %W
  (ronda 3: huecos 30/9 px, PASO 99.3 %). Consola 22.9 %H (piso).
- Tiles 1–6 iguales a ronda 3 (tinta 35–38 px en 950).

## Barra (geometría de escena, padre CamaraHero, y local 0.79)
- Banda `R2_Barra` (1.71, 0.11). Orden: Salir → saldo → POZO →
  turno → apuesta → mic → música → historial → ajustes.
- Salir píldora (−1.52, 0.79) 0.25×0.14, X en −1.62, texto −1.47
  tamaño 0.085; moneda Ø0.14 en −1.35; saldo LEFT en −1.26
  tamaño 0.13 → tinta 34 nativos = 14.0 equiv.
- POZO píldora (−0.69) 0.44×0.14, texto 0.085 → 23 nativos
  (9.4 equiv). TURNO píldora (−0.16) 0.60×0.14, texto 0.082 →
  21 nativos (8.6 equiv). APUESTA píldora (0.53) 0.70×0.14,
  texto 0.082 → 26 nativos (10.7 equiv). Hueco Pozo→Turno ≈ 6 px.
- Discos Ø0.17 en MIC 0.98, MÚSICA 1.18, HISTORIAL 1.38,
  AJUSTES 1.56 (dientes radio 0.08, borde derecho medido 1684/1688,
  margen 3 px, dentro).
  Iconos medidos: mic 44×66 px, nota 46×48 px, esfera reloj
  Ø53 px, engranaje Ø86 px. Píldoras: Salir 127×71, Pozo 223×71,
  Turno 304×71, Apuesta 355×71 (px en 1688×950).

## Placas y pozo (tinta real en PNG, no escala)
- Textos de placa 0.34, pozo 0.42, apuesta 0.36; placas laterales
  escala x 1.30. Medido: HU 13 nativos = 5.3 equiv (ronda 3: 12);
  TÚ 20/21 nativos = 8.2/8.6 equiv; POZO 18/18 = 7.4 equiv
  (ronda 3: 17); APUESTA 17/19 = 7.0/7.8 equiv.
  Piso: 14 equiv en placas necesitaría ~34 nativos; 18 equiv en
  pozo ~44 nativos. No se alcanza sin rediseño de placas.
- Veredicto: tabla escala (3.2, 0.66) en (0, −0.80, 0.03) — ¡OJO!
  −0.80, NO −1.15: con 3 líneas, −1.15 mete la línea del perdedor
  bajo el disco TÚ. Texto tamaño 0.56, 3 líneas:
  «DUDO FALLA · 10/5 / QUINTAS · DON CHALO / PIERDE 1 DADO ·
  EL HUASO». El Huaso es el dudador (coherente con la píldora
  «TURNO · EL HUASO»): dudó la apuesta de Don Chalo y, al fallar
  el Dudo (10 ≥ 5), pierde 1 dado. Tinta por línea 15/20/18 px
  (método estricto) = 1.6/2.1/1.9 %H; piso 2.4 %H no alcanzado
  (ronda 3: 2.0–2.1 %H).
- Tablita Paso: texto 0.56 (era 0.30 → 9 px; ahora 16–17 px),
  tira escala (2.8, 0.325) en (0, 1.3, 0.03); dados del paso en
  y −0.6 (eran −0.2; solo visibles en el render paso). Dados
  [1,2,3,4,6] de El Guatón; pips sin padre: sus offsets se
  preservan desplazando −0.4 (fix7b restauró un aplastamiento
  previo de fix7 que los puso todos en y −0.6).

## Anillos de conteo (revelación)
- `R2_Anillo_*` escala 1.9 (Ø 1.482 mundo), z 0.03. Lista (10):
  CH_1, CH_5, GU_1, HU_1, HU_2, HU_3, PI_3, TÚ_1, TÚ_2, TÚ_3.
- Conteo medido en revelacion.png final (línea central del toro,
  radios por fila): distinguibles 7/10 — HU_1 (arco O+SO 72°),
  HU_3 (arco NO 38°), PI_3 (arco E 68°), GU_1 (arco SO+O 84°),
  TÚ_1 (arco S 94°), TÚ_2 (arco SO+O 42°), TÚ_3 (arco E 64°).
  Sin arco distinguible: HU_2 (solo un resto de 4°; dado central:
  sus arcos laterales los tapan los dados vecinos y el arco sur
  queda justo en el borde inferior de su propio dado), CH_1 y
  CH_5 (sin oro en su elipse; fila CH en 2 hileras + tabla de
  veredicto + dados vecinos tapan sus arcos).
- Causa raíz medida: la silueta del dado (~95 px de alto) supera
  el diámetro vertical del anillo (~56–64 px a Ø 1.13); a Ø 1.48
  asoman los arcos sur/laterales libres, pero no los tapados por
  otros dados o por la tabla. Más Ø fusionaría los arcos sur en
  una banda continua sin distinguir dados. Un arreglo completo
  (anillo elevado, desplazado al sur o HUD) cambia la composición
  de la revelación y queda como decisión pendiente, no aplicada
  unilateralmente.

## Ductus
- Una sola fuente: `Noto Sans Condensed Bold`
  (`/usr/share/fonts/truetype/noto/NotoSans-CondensedBold.ttf`),
  un solo datablock; todos los textos con extrude 0 y bevel 0,
  estilo recto. Resto de datablocks de fuente borrados del blend.

## Tiempos de render (Cycles CPU, 1688×950)
- Tanda entrega fix7 (todo en uno): pantalla 474 s (64 muestras),
  revelación 415 s (48), paso 396 s (48); total 1285 s.
- Re-renders sueltos de revelación (48 muestras): 236 s, 308 s
  (variación por carga de la VM, no por la escena).
- Ronda 3, como referencia: 335 / 259 / 204 s.

## Reproducibilidad (punto 10)
- `render_ronda4.py` abre el blend guardado en fresco y SOLO toca
  visibilidades en revelación/paso (ningún desplazamiento en
  memoria). La tabla de veredicto está guardada en y −0.80.
- Demostración ejecutada: reabrir en fresco y re-renderizar la
  revelación con el mismo script, dos veces. Resultado: filas del
  veredicto idénticas [(477,491),(509,528),(543,560)], rangos de
  arco de los 10 anillos idénticos, y píxeles que difieren
  0/1.603.600 (0,0 %). El SHA del PNG difiere entre corridas
  SOLO por metadatos tEXt (Date, RenderTime, total_time,
  render_time, synchronization_time); la imagen es byte a byte
  idéntica en píxeles. Reproducción exacta, demostrada, no
  afirmada.
