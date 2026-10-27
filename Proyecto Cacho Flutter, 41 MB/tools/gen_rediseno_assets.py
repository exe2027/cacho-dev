#!/usr/bin/env python3
"""Activos propios del rediseño completo (R49 iconos PWA + R40 textura
Neón). Sin logos, sin marcas, sin arte de terceros: fondo oscuro +
texto DUDO dorado (fuente DejaVu Serif Bold del sistema) y textura
Neón casi negra con grano + viñeta, sin cian, sin animación."""
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent / "app"
WEB = ROOT / "web" / "icons"
WEB.mkdir(parents=True, exist_ok=True)
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
GOLD = (201, 162, 75)
BG = (18, 12, 9)


def dudo_icon(size: int, maskable: bool) -> Image.Image:
    img = Image.new("RGB", (size, size), BG)
    d = ImageDraw.Draw(img)
    # Filete dorado interior (mate, 2 px a 512, escalado).
    w = max(2, size // 256)
    pad = size // 16 if maskable else size // 32
    d.rounded_rectangle([pad, pad, size - pad - 1, size - pad - 1],
                        radius=size // 12, outline=GOLD, width=w)
    # Texto DUDO centrado; en maskable se deja zona segura del 20 %.
    font_size = int(size * 0.30) if not maskable else int(size * 0.22)
    font = ImageFont.truetype(SERIF, font_size)
    text = "DUDO"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - tw) / 2 - bbox[0], (size - th) / 2 - bbox[1]),
           text, font=font, fill=GOLD)
    return img


for size in (192, 512):
    dudo_icon(size, False).save(WEB / f"Icon-{size}.png")
    dudo_icon(size, True).save(WEB / f"Icon-maskable-{size}.png")

# Textura Neón oscura (R40): casi negra, grano + viñeta, sin cian.
random.seed(20261025)
w, h = 1266, 585
base = Image.new("RGB", (w, h), (7, 8, 10))
px = base.load()
for y in range(h):
    for x in range(w):
        # Viñeta: oscurece hacia los bordes (máx. -30 % en esquinas).
        dx, dy = (x / w - 0.5) * 2, (y / h - 0.5) * 2
        v = 1.0 - 0.30 * (dx * dx + dy * dy) / 2
        n = random.randint(-6, 6)
        r, g, b = base.getpixel((x, y))
        px[x, y] = (max(0, min(255, int(r * v) + n)),
                    max(0, min(255, int(g * v) + n)),
                    max(0, min(255, int(b * v) + n)))
base.save(ROOT / "assets" / "images" / "room_neon_dark.png")
print("OK iconos + room_neon_dark.png")
