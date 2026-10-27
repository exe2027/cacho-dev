#!/usr/bin/env python3
"""Fondo de bar desenfocado (luces cálidas, bokeh) para el plato 3D y
como textura del telón en Blender. Uso: python3 tools/gen_bokeh.py"""
import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "bokeh.png")
W, H = 1024, 640
rnd = random.Random(4242)
img = Image.new("RGB", (W, H), (16, 10, 7))
glow = Image.new("RGB", (W, H), (0, 0, 0))
dr = ImageDraw.Draw(glow)
for _ in range(170):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.85)
    r = rnd.uniform(5, 24)
    warm = rnd.choice([(255, 176, 92), (255, 205, 130), (214, 132, 64),
                       (255, 226, 170)])
    a = rnd.uniform(0.07, 0.30)
    col = tuple(int(c * a) for c in warm)
    dr.ellipse([x - r, y - r, x + r, y + r], fill=col)
glow = glow.filter(ImageFilter.GaussianBlur(9))
# segunda capa: destellos chicos, apenas más nítidos
dr2 = ImageDraw.Draw(glow)
for _ in range(46):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.8)
    r = rnd.uniform(2, 6)
    warm = rnd.choice([(255, 190, 105), (255, 214, 150), (230, 150, 80)])
    a = rnd.uniform(0.15, 0.4)
    col = tuple(int(c * a) for c in warm)
    dr2.ellipse([x - r, y - r, x + r, y + r], fill=col)
glow = glow.filter(ImageFilter.GaussianBlur(3))
img = Image.blend(img, Image.new("RGB", (W, H), (0, 0, 0)), 0)
from PIL import ImageChops
img = ImageChops.add(img, glow)
img = img.filter(ImageFilter.GaussianBlur(2))
img.save(OUT)
print("bokeh ok ->", OUT)
