# RONDA 5 — Parámetros guardados en `mesa_cacho_ronda5.blend`

Blend sucesor de `mesa_cacho_ronda4.blend` (ronda 4 intacta: mtime sin
cambio). Solo 3 ítems, solo posiciones, sin tocar nada bloqueado.
Scripts: `patch_ronda5.py` (parche, reproducible desde ronda 4),
`render_ronda5.py` (entrega, solo visibilidades),
`preview_ronda5.py` (844×475, calibración). Renders en
`renders/ronda5/` (1688×950).

## Cambios guardados (respecto a ronda 4)

1. SOLAPE MONEDA / "R" DE SALIR: `R4_SalirTxt` x −1.47 → −1.49
   (0.02 mundo, ~10 px a la izquierda). Moneda, píldora, X y saldo
   quietos. (Ronda 4: R 120–132 px, moneda desde 130 px, intrusión
   2–3 px, aire −2 px.)
2. PUNTO VERDE HU: `R2_PuntoVerde_ElHuaso` (0.4256, 3.494, 0.579) →
   (0.4256, 3.644, 0.740): dy +0.15 y dz +0.161, es decir, subida
   SOBRE la cara inclinada del disco (tangente (0,0.682,0.731)),
   no solo en +y — mover solo en +y hunde el punto detrás de la
   cara (componente normal −0.149) y la previa seguía sin punto.
   `Placa_ElHuaso` y `R2_TextoPlaca_ElHuaso` y −0.25 (3.28→3.03 y
   3.225→2.975). (Ronda 4: núcleo 872–884 × 262–276 px, 0 px visible
   bajo la placa que empieza en 258 px; la mota 862–864 × 252–254
   px NO era el punto.)
3. HUECO POZO→TURNO: `R4_PozoPill`/`R4_PozoTxt` x −0.005 y
   `R4_TurnoPill`/`R4_TurnoTxt` x +0.005 (textos con su píldora).
   (Ronda 4: 4 px por color de píldora, 2 px con el umbral estricto
   del agente 07. Ejemplo medido en esta ronda: 9 px crudos entre
   sus dos píldoras superiores en y=50, 324→334, en 1290×595.)

## Todo lo demás

Cámara (0,−12.85,9.2) rot 0.9494, luces, consola, anillos, veredicto,
tablita, ductus: sin cambio respecto a ronda 4 (ver NOTAS_RONDA4.md).
Sin despliegue, sin commit, sin tocar `~/workspace/cacho/` salvo el
informe ronda5, sin tocar `comparacion_ejemplo_10agentes.md`.

## Medidas finales (render final 1688×950, mismo script que ronda 4)

- SALIR: R 110–121 px, moneda 127–200 px, **aire R→moneda 5 px**
  (ronda 4: −2 px); moneda→saldo 7 px (igual); X→S 17 px (27 px).
- PUNTO HU: estricto **186 px, 871–886 × 244–259 (16×16 px)**,
  aire a placa HU 7 px (placa sup. 267 px); resto de puntos
  idénticos a ronda 4 al píxel (CH 48, PI 53, GU 129, CU 155,
  TÚ 184) → **6/6**. Hueco HU/POZO 11 px (21 px).
- HUECO POZO→TURNO: **8 px** (y=50/55), **9 px** (y=100) por color
  de píldora (ronda 4: 4 px); ~6–7 px por umbral estricto del
  agente 07. TURNO→APUESTA 17 px (19 px).
- Fechas (local −03, 26-oct): blend guardado 21:38; pantalla
  21:50; revelación 21:58 (413 s); paso 22:04 (370 s).
  Informe completo en `audit/comparacion_ejemplo/ronda5_unity.md`.
