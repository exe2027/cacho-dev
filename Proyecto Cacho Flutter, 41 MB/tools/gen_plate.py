#!/usr/bin/env python3
"""Plato de fondo del bar, compuesto en PIL (iteración rápida):
arriba el bokeh cálido desenfocado; abajo una mesa de madera con
perspectiva (deformación trapezoidal), luz cenital sobre el centro
(donde va el vaso) y viñeta. Salida: app/assets/images/bg_pub.png"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.normpath(os.path.join(HERE, "..", "app", "assets", "images"))
W, H = 720, 1280
HORIZON = 400


def find_coeffs(target, source):
    import numpy as np

    matrix = []
    for p1, p2 in zip(source, target):
        matrix.append([p1[0], p1[1], 1, 0, 0, 0, -p2[0] * p1[0], -p2[0] * p1[1]])
        matrix.append([0, 0, 0, p1[0], p1[1], 1, -p2[1] * p1[0], -p2[1] * p1[1]])
    A = np.matrix(matrix, dtype=float)
    B = np.array(target).reshape(8)
    res = np.linalg.solve(A, B)
    return np.array(res).reshape(8)


def main():
    # ---------- fondo: bokeh cálido arriba ----------
    bokeh = Image.open(os.path.join(HERE, "bokeh.png")).convert("RGB")
    bokeh = bokeh.resize((W, 560), Image.LANCZOS)
    plate = Image.new("RGB", (W, H), (13, 9, 6))
    plate.paste(bokeh, (0, 0))
    # degradado que funde el bokeh hacia la mesa
    fade = Image.new("L", (1, H), 0)
    for y in range(H):
        fade.putpixel((0, y), 255 if y < 300 else max(0, 255 - (y - 300) * 2))
    fade = fade.resize((W, H))
    plate = Image.composite(plate, Image.new("RGB", (W, H), (13, 9, 6)), fade)

    # ---------- mesa de madera en perspectiva ----------
    wood = Image.open(os.path.join(IMG, "wood.png")).convert("RGB")
    canvas = wood.resize((1024, 1024), Image.LANCZOS)
    # oscurecer y calentar la madera
    canvas = ImageChops.multiply(canvas, Image.new("RGB", canvas.size, (196, 158, 128)))
    table_h = H - HORIZON + 60
    OUT_W = W + 280
    # destino: trapecio (el borde lejano muestrea la textura comprimida)
    target = [(-40, table_h), (OUT_W + 40, table_h),
              (OUT_W - 120, 0), (120, 0)]
    source = [(0, 1024), (1024, 1024), (1024, 0), (0, 0)]
    coeffs = find_coeffs(target, source)
    table = canvas.transform((OUT_W, table_h), Image.PERSPECTIVE, coeffs,
                             Image.BICUBIC)
    # luz cenital: oscurecer según la distancia al centro de la mesa
    shade = Image.new("L", (OUT_W, table_h), 0)
    dr = ImageDraw.Draw(shade)
    dr.ellipse([-OUT_W * 0.30, -table_h * 0.30, OUT_W * 1.30, table_h * 0.95], fill=235)
    shade = shade.filter(ImageFilter.GaussianBlur(90))
    dark_table = ImageChops.multiply(table, Image.new("RGB", table.size, (88, 74, 66)))
    table = Image.composite(table, dark_table, shade)
    # el borde lejano de la mesa se pierde en la penumbra
    top_fade = Image.new("L", (1, table_h), 0)
    for y in range(table_h):
        top_fade.putpixel((0, y), min(255, y * 9))
    top_fade = top_fade.resize((OUT_W, table_h))
    table_dark = ImageChops.multiply(table, Image.new("RGB", table.size, (40, 34, 30)))
    table = Image.composite(table, table_dark, top_fade)
    plate.paste(table, (-140, HORIZON - 60))

    # ---------- luz cálida sobre el centro (donde va el vaso) ----------
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    dr = ImageDraw.Draw(glow)
    dr.ellipse([W * 0.16, H * 0.40, W * 0.84, H * 0.72], fill=(64, 40, 16))
    glow = glow.filter(ImageFilter.GaussianBlur(70))
    plate = ImageChops.add(plate, glow)

    # ---------- viñeta general ----------
    vig = Image.new("L", (W, H), 0)
    dr = ImageDraw.Draw(vig)
    dr.ellipse([-W * 0.28, -H * 0.16, W * 1.28, H * 1.02], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(130))
    plate = Image.composite(plate, ImageChops.multiply(plate, Image.new("RGB", (W, H), (92, 84, 80))), vig)

    plate.save(os.path.join(IMG, "bg_pub.png"), optimize=True)
    print("bg_pub PIL ok", plate.size)


if __name__ == "__main__":
    main()
