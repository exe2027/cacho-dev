#!/usr/bin/env python3
"""Salas horizontales PIL para el prototipo (Etapa 4, D15).

Genera la sala que vive FUERA del rectangulo-mesa en horizontal:
madera oscura en perspectiva suave, bokeh calido SOLO fuera de la
zona calma central, vineta profunda. El centro queda plano y oscuro
para que dados, avatares, nombres, pipas y aros lean sin ruido.
Neon: casi negro, SIN cian (el cian vive solo dentro del
rectangulo-mesa). Determinista (semilla fija). No es arte de otro
juego: madera oscura + rectangulo de pano, sin bolsillos ni mesa
ovalada brillante, para no confundirse con 8 Ball Pool.

Salida: app/assets/images/room_dorado.png y room_neon.png.
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

W, H = 1266, 585
OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "images"
rng = random.Random(7)


def vignette(img, strength=150):
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([-W * 0.25, -H * 0.55, W * 1.25, H * 1.55], fill=strength)
    mask = mask.filter(ImageFilter.GaussianBlur(90))
    dark = Image.new("RGB", (W, H), (0, 0, 0))
    return Image.composite(img, dark, mask)


def bokeh_layer(warm=True):
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = W / 2, H / 2
    # Zona calma central: sin bokeh dentro del 62% x 68% central.
    for _ in range(46):
        x = rng.uniform(0, W)
        y = rng.uniform(0, H)
        if abs(x - cx) < W * 0.31 and abs(y - cy) < H * 0.34:
            continue
        r = rng.uniform(14, 62)
        if warm:
            col = rng.choice([(201, 162, 75), (255, 183, 77), (255, 138, 61)])
            a = rng.randint(16, 42)
        else:
            col = (40, 60, 110)
            a = rng.randint(8, 18)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (a,))
    return layer.filter(ImageFilter.GaussianBlur(16))


def wood_grain(img):
    d = ImageDraw.Draw(img, "RGBA")
    # Vetas horizontales suaves, mas densas hacia abajo (perspectiva).
    for y in range(0, H, 7):
        depth = 0.35 + 0.65 * (y / H)
        a = int(10 + 22 * depth * rng.random())
        d.line([(0, y + rng.uniform(-2, 2)), (W, y + rng.uniform(-2, 2))],
               fill=(60, 38, 20, a), width=2)
    return img


def dorado():
    img = Image.new("RGB", (W, H), (18, 12, 7))
    # Degradado vertical: mas calido arriba (tras la barra superior).
    top = Image.new("RGB", (W, H), (38, 24, 13))
    grad = Image.linear_gradient("L").rotate(90).resize((W, H))
    img = Image.composite(top, img, grad.point(lambda v: int(v * 0.45)))
    img = wood_grain(img)
    img = Image.alpha_composite(img.convert("RGBA"), bokeh_layer(True))
    # Luz cenital eliptica muy suave, solo en la franja superior.
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W * 0.2, -H * 0.55, W * 0.8, H * 0.35],
               fill=(255, 200, 120, 18))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(60)))
    img = vignette(img.convert("RGB")).convert("RGB")
    return img


def neon():
    img = Image.new("RGB", (W, H), (5, 7, 12))
    top = Image.new("RGB", (W, H), (9, 13, 22))
    grad = Image.linear_gradient("L").rotate(90).resize((W, H))
    img = Image.composite(top, img, grad.point(lambda v: int(v * 0.5)))
    return vignette(img, strength=170)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in (("room_dorado.png", dorado), ("room_neon.png", neon)):
        p = OUT / name
        fn().save(p, optimize=True)
        print(name, p.stat().st_size, "bytes")
