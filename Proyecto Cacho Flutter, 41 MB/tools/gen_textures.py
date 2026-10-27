#!/usr/bin/env python3
"""Texturas generativas de Cacho (espíritu algorithmic-art: sistemas con
semilla, no dibujo a mano). Materiales honestos para la filosofía
"Cuero y Paño": paño de casino con grano y fibra, madera oscura con veta.
Uso: python3 tools/gen_textures.py -> app/assets/images/
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "images")


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def felt_bg():
    W, H = 720, 1280
    center = (0x0D, 0x6A, 0x42)
    edge = (0x04, 0x2A, 0x1C)
    img = Image.new("RGB", (W, H))
    px = img.load()
    cx, cy = W * 0.5, H * 0.40
    maxd = math.hypot(max(cx, W - cx), max(cy, H - cy))
    rnd = random.Random(20261022)
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - cx, y - cy) / maxd
            base = lerp(center, edge, min(1.0, d ** 1.25))
            n = rnd.randint(-6, 6)
            px[x, y] = tuple(max(0, min(255, c + n)) for c in base)
    # Fibras del paño: trazos cortos, apenas más claros u oscuros.
    dr = ImageDraw.Draw(img, "RGBA")
    for _ in range(5200):
        x, y = rnd.uniform(0, W), rnd.uniform(0, H)
        ang = rnd.uniform(0, math.pi)
        ln = rnd.uniform(4, 13)
        dx, dy = math.cos(ang) * ln, math.sin(ang) * ln
        light = rnd.random() < 0.5
        col = (190, 255, 215, rnd.randint(5, 13)) if light else (0, 20, 10, rnd.randint(5, 13))
        dr.line([x, y, x + dx, y + dy], fill=col, width=1)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img.save(os.path.join(OUT, "felt_bg.png"), optimize=True)
    print("felt_bg ok")


def wood():
    W = H = 512
    base = (0x2B, 0x18, 0x10)
    img = Image.new("RGB", (W, H))
    px = img.load()
    rnd = random.Random(777)
    phase = [rnd.uniform(0, 6.28) for _ in range(4)]
    for y in range(H):
        grain = (
            math.sin(y * 0.11 + phase[0]) * 0.5
            + math.sin(y * 0.031 + phase[1]) * 0.9
            + math.sin(y * 0.55 + phase[2]) * 0.22
        )
        for x in range(W):
            drift = math.sin(x * 0.008 + phase[3]) * 6
            g = grain + math.sin((y + drift) * 0.9) * 0.10
            f = 1.0 + g * 0.10 + rnd.uniform(-0.03, 0.03)
            px[x, y] = tuple(max(0, min(255, int(c * f))) for c in base)
    dr = ImageDraw.Draw(img, "RGBA")
    # Vetas largas y dos nudos discretos.
    for _ in range(46):
        y = rnd.uniform(0, H)
        dark = rnd.random() < 0.6
        col = (0, 0, 0, rnd.randint(14, 34)) if dark else (255, 214, 150, rnd.randint(8, 18))
        dr.line([0, y, W, y + rnd.uniform(-6, 6)], fill=col, width=rnd.randint(1, 2))
    for _ in range(2):
        kx, ky = rnd.uniform(60, W - 60), rnd.uniform(60, H - 60)
        for r in range(16, 2, -3):
            dr.ellipse([kx - r * 1.6, ky - r, kx + r * 1.6, ky + r],
                       outline=(0, 0, 0, 26), width=2)
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    img.save(os.path.join(OUT, "wood.png"), optimize=True)
    print("wood ok")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    felt_bg()
    wood()
