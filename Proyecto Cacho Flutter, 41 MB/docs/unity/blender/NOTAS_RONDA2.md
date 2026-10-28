# RONDA 2 — notas técnicas (corrección Unity/Blender contra el ejemplo)

Trabajo SOLO sobre la copia `blender/mesa_cacho_ronda2.blend` (el blend de la
etapa 1 y sus renders vigentes NO se tocaron: `mesa_cacho.blend` sigue con
fecha 26-oct 15:35, `mesa_hero.png` 13:49, `mesa_revelacion.png` 14:13).
Motor: Cycles CPU (EEVEE no corre en la VM, falta libEGL). Denoiser activo,
muestreo adaptativo (umbral 0,10, mín. 16), rebotes difuso/brillo 3.
Resolución final: 1688×950 en los tres renders.

## Escena ronda 2 (estado guardado = pantalla completa)

- Cámara `CamaraHero`: (0,-11,11), rotación X 0,78, lente 32, DOF apagado
  (el HUD va pegado a cámara y con DOF quedaba borroso). Oblicua desde la
  vertical: 40,1° (antes 46,7°). Mesa ensanchada ×1,12 en X
  (MesaMadera 12,54, Pano 10,98) para llenar el cuadro 16:9.
- Paño `PanoCarbon`: base #1D1717 (lineal 0,012/0,008/0,008), rugosidad 1,0.
  Dorado `DoradoMate`: #C9A24B, rugosidad 0,75, metal 0,25 (mate).
  `FileteDoradoPano` oculto (queda un solo filete, el del borde).
- Logo: `LogoCachoODudo` escala (0,53; 0,53; 0,15), rotación Z 0,23 (13,2°),
  material marca de agua gris (0,32/0,29/0,29 sRGB). `AnilloLogo` oculto;
  `R2_OvaloLogo`: curva Bézier abierta (`use_cyclic_u=False`), escala
  (1,05; 0,72), bevel 0,02, mismo material marca de agua.
- Asientos: discos sin cambio de escala salvo TÚ (0,85×). Placas bajo cada
  disco con solape ~0,12 mundo sobre el borde inferior. Placas nuevas:
  nombre + ×5 (DejaVu Sans Mono, extrude 0, bevel 0). Punto verde
  (esfera r 0,09, emisiva) en el borde inferior-derecho de cada disco.
  `Aro_TU` en gris neutro (semáforo = motor posterior, U10).
- Placa superior: solo Pozo. `PlacaPozo` en (0; 1,95), texto "POZO\n3.000"
  (tamaño 0,32). `TextoApuesta` oculto. Fichas (`FichaPozo_*`,
  `FichaSuelta_*`) ocultas, no borradas. Slot de reacciones viejo
  (`SlotReacciones`, `TextoReacciones`, `AroReacciones`) oculto: la
  consola lleva el slot de emotes.
- Vasos (cuero + posavasos, boca abajo): DonChalo (-3,92; 2,30), LaPituca
  (3,92; 2,30), ElGuaton (-5,32; 0,75), LaCuca (5,32; 0,75), ElHuaso
  (-1,74; 2,75, a un lado de la columna por placa+pozo en medio), TÚ
  (0; -2,35). Los hijos (borde, costura) siguen al padre al moverlo.
- Lámparas-bokeh (`Lampara0..6`) ocultas: se veían como globos blancos.
  Fondo: telón oscuro + suelo + mundo casi negro + luces cálidas.
- HUD (geometría emparentada a `CamaraHero`, distancia local 3,0; NUNCA
  imagen pegada en post): barra (saldo 5.000, MIC, MÚSICA, ajustes, menú),
  consola (emotes ":)", APOSTAR 1–6 con pipas, CALZO verde #0E7A4F,
  DUDO rojo #B3202A, PASO #14586B). Materiales HUD: base negra + emisión
  del color objetivo (lectura independiente de las luces de escena).
  Sin segunda moneda, sin "+" de compra, sin regalo/misiones/amigos.
  Banners HUD de veredicto quedaron ocultos y sustituidos por placas de
  mesa (también geometría).
- Revelación: 30 dados nuevos de 0,64 (cubos blancos + pipas negras
  planas: cilindros r 0,083, 0,01 salientes, solo cara superior), 6 manos
  en 2 columnas × 3 filas (x ±3,25; y 1,85 / -0,45 / -2,75), anillos
  dorados (r 0,39) bajo los dados que cuentan (5 y 1), mini-placas con
  subtotal (HU·3, PI·1, CH·2, CU·0, GU·1, TÚ·3), placa de mesa
  "DUDO FALLA · 10/5" en (0; 0,70). Manos: HU [5,1,5,3,2], PI [3,3,5,2,4],
  CH [5,2,4,6,1], CU [4,4,2,6,6], GU [1,6,6,2,3], TÚ [5,5,1,3,4].
  Total Quintas con Ases: 10 ≥ 5 → el Dudo falla.
- Paso: solo la mano de El Guatón [1,2,3,4,6] en fila central + placa de
  mesa "PASO · EL GUATÓN · 5 DISTINTOS" en (0; 1,30); solo su vaso
  levantado (queda el posavasos), resto de vasos cerrados.
- Estado guardado del blend = hero (dados de revelación/Paso y placas de
  veredicto ocultos; los scripts de render los activan solo en memoria,
  sin guardar).

## Lecciones de esta ronda (para no repetir)

- Blender: con sensor horizontal y aspecto 16:9, el FOV vertical efectivo
  es tan(12/lente)/aspecto; el HUD a distancia 2,2 quedaba fuera de cuadro
  con lente 32–40. HUD a 3,0 + lente 32 + cámara (0,-11,11) rot 0,78 es la
  combinación que encaja barra, mesa y consola sin recortes (medido con
  `world_to_camera_view`, no a ojo).
- No reutilizar el layout de pipas de los tiles (offsets ±0,045) para los
  dados: las pipas se fundían en un solo borrón. Dados 0,64: offsets
  ±0,167, radio 0,083.
- Con DOF activo, el HUD pegado a cámara sale borroso: DOF apagado en
  ronda 2 (el fondo apenas se ve; la mesa llena el cuadro).
- Los textos FONT miden mal con `bound_box` (subestima la altura); la
  legibilidad se verificó a ojo en el render, no solo por bbox.
- Un óvalo en 16:9 no puede cubrir más del 78,5% de su caja: el <10% de
  vacío de U5 es inalcanzable con mesa ovalada + HUD; piso real ~15–20%.

## Scripts

- `blender/patch_ronda2.py`: parche principal (materiales, placas, logo,
  vasos, cámara inicial, HUD, dados v1).
- `blender/verify_ronda2.py`: medición NDC (bbox) de discos, logo, textos,
  dados y HUD sobre el blend guardado.
- Los parches de ajuste (fix2–fix6) y los scripts de render final vivieron
  en /tmp (efímeros); sus efectos están todos dentro del blend guardado
  y documentados arriba. Si hay que re-renderizar: abrir
  `mesa_cacho_ronda2.blend`, activar el estado (hero / revelación / Paso)
  según §"Escena" y renderizar con los ajustes del encabezado.
