#!/usr/bin/env python3
"""Post-proceso del plato de fondo: viñeta suave + oscurecer el tercio
superior (donde va el logo) y los bordes, para que la UI respire.
Entrada: app/assets/images/bg_pub_raw.png -> bg_pub.png"""
import os

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.normpath(os.path.join(HERE, "..", "app", "assets", "images"))
src = Image.open(os.path.join(IMG, "bg_pub_raw.png")).convert("RGB")
W, H = src.size

# Viñeta radial: centro luminoso sobre la mesa, bordes caen a 45%.
vig = Image.new("L", (W, H), 0)
dr = ImageDraw.Draw(vig)
dr.ellipse([-W * 0.25, -H * 0.18, W * 1.25, H * 1.05], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(120))
dark = Image.new("RGB", (W, H), (0, 0, 0))
src = Image.composite(src, Image.blend(src, dark, 0.55), vig)

# Oscurecer la franja superior (logo y asientos de arriba).
top = Image.new("L", (W, H), 0)
dr = ImageDraw.Draw(top)
dr.rectangle([0, 0, W, int(H * 0.20)], fill=110)
top = top.filter(ImageFilter.GaussianBlur(60))
src = Image.composite(Image.blend(src, dark, 0.5), src, top)

src.save(os.path.join(IMG, "bg_pub.png"), optimize=True)
print("bg_pub ok", src.size)
