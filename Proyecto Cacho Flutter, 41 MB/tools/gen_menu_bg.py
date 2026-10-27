#!/usr/bin/env python3
"""R31/R5: fondo de MENÚ propio — madera oscura #120C09 + foto del
pub SOLO arriba, atenuada 55 % (visible al 45 %), con fundido
vertical hacia la madera y viñeta progresiva en los bordes.
Vertical 780×1688 (los menús son verticales por dirección)."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "app"
W, H = 780, 1688
WOOD = (18, 12, 9)
img = Image.new("RGB", (W, H), WOOD)
pub = Image.open(ROOT / "assets" / "images" / "bg_pub.png").convert("RGB")
# Foto arriba: ocupa el 45 % superior. La foto es muy oscura en su
# parte alta (techo, brillo ~17), así que la franja usa la banda
# central de la foto (la barra misma, brillo ~36) para que el pub
# se lea arriba sin subir la atenuación del 55 %.
top_h = int(H * 0.45)
pw, ph = pub.size
band = pub.crop((0, int(ph * 0.30), pw, int(ph * 0.75)))
cover = band.resize((W, int(band.height * W / band.width)))
if cover.height < top_h:
    cover = cover.resize((W, top_h))
cover = cover.crop((0, 0, W, top_h))
# Atenuación 55 % + fundido vertical (45 % arriba → 0 % abajo).
fade = Image.new("L", (W, top_h))
for y in range(top_h):
    # Atenuación base 45 % que cae a 0 en el último 30 % de la franja.
    a = 0.45
    if y > top_h * 0.70:
        a *= max(0.0, 1.0 - (y - top_h * 0.70) / (top_h * 0.30))
    for x in range(W):
        fade.putpixel((x, y), int(a * 255))
img.paste(cover, (0, 0), fade)
# Viñeta progresiva: oscurece hasta 35 % en las esquinas.
px = img.load()
for y in range(H):
    for x in range(W):
        dx, dy = (x / W - 0.5) * 2, (y / H - 0.5) * 2
        v = 1.0 - 0.35 * (dx * dx + dy * dy) / 2
        r, g, b = px[x, y]
        px[x, y] = (int(r * v), int(g * v), int(b * v))
img.save(ROOT / "assets" / "images" / "menu_bg.png")
print("OK menu_bg.png", img.size)
