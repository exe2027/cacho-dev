# RONDA 3 — notas técnicas (corrección Unity/Blender contra el ejemplo)

Trabajo SOLO sobre la copia `blender/mesa_cacho_ronda3.blend` (ronda 2 y
etapa 1 intactos). Motor: Cycles CPU. Resolución final: 1688×950.
Estado guardado = hero (pantalla completa); revelación y Paso se activan
solo en memoria en sus scripts de render (sin guardar).

## Escena ronda 3 (estado guardado)

- Cámara `CamaraHero`: (0,-13,9), rot X 0,965 rad (atan2(13,9)), lente 32.
  Ensayada cenital (0,-10,13,5, rot 0,684): placa TÚ en 0,076 → enterrada
  bajo la consola nueva; descartada.
- Luces: Clave AREA 400 (color 1,0/0,93/0,85), Contraluz POINT 180,
  Relleno POINT 85 (antes 1600/700/350).
- Paño `PanoCarbon` #1D1717 (sin cambio de material; el cambio es de luz).
  Dorado `R2_OroMate`: base negra + emisión sRGB (0,69/0,50/0,21) ×1,35
  (compensa filmic; mediana en render #B99745). `DoradoMate`: rugosidad
  0,85 + emisión 0,30 (solo afecta a objetos ocultos tras borrar el filete).
- Borrados: `R2_Menu0/1/2` (hamburguesa), `FileteDoradoBorde`.
- Logo: `LogoCachoODudo` (0,0,70,0,045), escala (0,50,0,50,0,15), rot Z 0,23.
  `R2_OvaloLogo` mismo centro, escala (0,92,0,60,1,0). Pinceladas
  `R3_Pincelada_1..3` (cubos finos, material marca de agua) bajo "DUDO".
- Vasos: TÚ (0,-2,55,0,11), escala (1,1,0,85); El Huaso (-1,55,3,45,0,11)
  (posavasos siguen al mismo XY). Resto de vasos sin cambio.
- Placas: HU (0,3,28,0,55), Pozo (0,1,55,0,55); textos con offset
  (0,-0,055,0,051). Placas ×1,15 en X (salvo Pozo). Textos placa 0,28,
  pozo 0,36.
- Disco TÚ: `Avatar_TU`, `Aro_TU`, `AvatarCentro_TU`, `Inicial_TU`,
  `R2_PuntoVerde_TU` a escala 0,68 (punto en (0,275,-3,489,0,605)).
- Apuesta actual (solo hero): `R3_PlacaApuesta` (-2,90,0,30,0,55),
  escala (1,7,1,1), duplicada de PlacaPozo; `R3_TextoApuesta`
  "APUESTA ACTUAL\n5 QUINTAS · DON CHALO", tamaño 0,30. Oculta en memoria
  en los renders de revelación y Paso.
- Veredicto: `R2_TablaVeredicto` escala (2,9,0,46,0,015) en (0,0,70,0,03)
  (guardado); texto "DUDO FALLA · 10/5\nQUINTAS · DON CHALO", tamaño 0,56.
  En el render de revelación se desplaza en memoria a y=-1,15 (tabla y
  texto) para no chocar con el disco TÚ ni con las manos.
- Consola (local a cámara, centro Y -0,7345): `R2_Consola` escala
  (1,71,0,2155,0,01) → 22,9%H; botones escala (0,25,0,1645,0,01) → 17,6%H
  en X 0,33/0,89/1,41; textos en +0,03; iconos dado en X 0,12/0,68 (cubo
  blanco + pipa negra) y barras ‖ en X 1,20/1,25; `R3_VerBtn` en -1,36
  (escala 0,11,0,1645) + `R3_VerTxt` "VER" 0,11; emotes en -1,58;
  `R2_ApostarLbl` en (-1,16,-0,565), tamaño 0,11; tiles en X
  -1,14+i·0,21, Y -0,745, escala (0,10,0,14,0,01), material `R3_TileBlanco`
  (marfil + emisión 0,35), pipas y números en `R3_TextoNegro`, números
  tamaño 0,14 en Y -0,83.
- Fondo: `R3_TelonFoto` plano (0,8,0,2,6), rot X 90°, escala (13,3,4,1),
  material `R3_FondoFoto` (emisión 1,2, imagen `fondo_taberna_r3.png`
  procedural propia). Suelo: textura `suelo_taberna_r3.png` con Mapping
  ×8, mezcla Principled/Emisión 0,6, emisión 0,9.

## Scripts

- `blender/patch_ronda3.py`: parche principal (sobre la copia ronda 3).
- `blender/fix_ronda3.py`: disco 0,68, separación HU/Pozo, veredicto 0,56,
  luz ×0,72, moneda 0,95, fondo más visible (tras previa).
- `blender/fix2_ronda3.py`: vaso TÚ -2,55/Z 0,85, moneda 1,35, veredicto
  en 2 líneas cortas (tras recortes).
- `blender/fix3_ronda3.py`: dorado base negra + emisión compensada.
- Renders finales: script en /tmp (final_r3b.py + final_rev_only.py):
  hero tal cual; revelación oculta vasos y apuesta, muestra dados/anillos/
  etiquetas/veredicto y mueve la tabla a y=-1,15 en memoria; Paso oculta
  el vaso de El Guatón y la apuesta y muestra sus dados y su tabla.
