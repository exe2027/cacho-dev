#!/usr/bin/env python3
"""R35: contraste mezclado (WCAG) de TODOS los pares del rediseño
sobre su fondo real. Mezcla alfa sobre fondo opaco y luego ratio.
Piso: 4,5:1. Los deshabilitados (R34) son exentos SOLO porque el
motivo del bloqueo se lee a 14 px en otro elemento; se listan igual
para documentarlos, no para aprobarlos."""
import math

def srgb(c):
    c /= 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

def lum(rgb):
    r, g, b = (srgb(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def blend(fg, alpha, bg):
    return tuple(round(fg[i] * alpha + bg[i] * (1 - alpha)) for i in range(3))

def ratio(fg, bg):
    l1, l2 = lum(fg), lum(bg)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)

def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))

GOLD = hx("C9A24B"); GOLD_DK = hx("2B1810"); WOOD = hx("120C09")
LEATHER = hx("3E2312"); IVORY = hx("F5EBD7"); NAVY = hx("141B28")
RED = hx("B3202A"); GREEN = hx("0E7A4F"); PETRO = hx("14586B")
FELT_C = hx("0B5D3B"); FELT_E = hx("06402A"); WHITE = (255, 255, 255)
DARKTXT = hx("221A08")  # chip de probabilidad (antes del rediseño)

# Fondos derivados reales:
CONSOLE_BG = NAVY  # SideBidDock navyCard 0.97 ≈ navy
PANEL_BG = LEATHER  # panel único home/hojas
MENU_BG = WOOD
# R39 luz cenital: blanco hasta 12 % sobre el paño en el centro.
FELT_LIGHT = blend(WHITE, 0.12, FELT_C)
# R40 viñeta: negro hasta 25 % en los bordes del paño.
FELT_DARK = blend((0, 0, 0), 0.25, FELT_C)
# Botones _MiniAction sobre consola: color pleno (R34 normal).
# Deshabilitado: color 30 % sobre consola, texto 50 % (R34, exento).
PAIRS = [
    ("R1/R31 gold sobre fondo menú", GOLD, MENU_BG),
    ("R1 ivory sobre panel cuero", IVORY, PANEL_BG),
    ("R1 gold sobre panel cuero", GOLD, PANEL_BG),
    ("R1 ivory 70% sobre panel cuero", blend(IVORY, 0.70, PANEL_BG), PANEL_BG),
    ("R1 gold 85% sobre fondo menú (eslogan)", blend(GOLD, 0.85, MENU_BG), MENU_BG),
    ("R4 ivory 70% sobre fondo menú (pie, 14 px)", blend(IVORY, 0.70, MENU_BG), MENU_BG),
    ("R10 seleccionado: oscuro sobre dorado", GOLD_DK, GOLD),
    ("R33 APOSTAR: oscuro sobre dorado mate", GOLD_DK, GOLD),
    ("R33 APOSTAR presionado (dorado 8% más oscuro)", GOLD_DK, blend((0, 0, 0), 0.08, GOLD)),
    ("R33 DUDO: ivory sobre rojo pleno", IVORY, RED),
    ("R33 CALZO: ivory sobre verde pleno", IVORY, GREEN),
    ("R33 PASO: ivory sobre petróleo pleno", IVORY, PETRO),
    ("R34 DUDO presionado (rojo 8% más oscuro)", IVORY, blend((0, 0, 0), 0.08, RED)),
    ("R34 CALZO presionado (verde 8% más oscuro)", IVORY, blend((0, 0, 0), 0.08, GREEN)),
    ("R34 PASO presionado (petróleo 8% más oscuro)", IVORY, blend((0, 0, 0), 0.08, PETRO)),
    ("R33 chip probabilidad: oscuro sobre dorado", DARKTXT, GOLD),
    ("R35 marfil sobre paño centro", IVORY, FELT_C),
    ("R39 marfil sobre paño punto MÁS CLARO (luz 12%)", IVORY, FELT_LIGHT),
    ("R40 marfil sobre paño punto MÁS OSCURO (viñeta 25%)", IVORY, FELT_DARK),
    ("R35 blanco 70% sobre madera (subtítulos hoja)", blend(WHITE, 0.70, WOOD), WOOD),
    ("R35 blanco 54% sobre madera (subtítulo logo home)", blend(WHITE, 0.54, WOOD), WOOD),
    ("R35 blanco 54% sobre cuero (pie home/CÓMO SE JUEGA)", blend(WHITE, 0.54, LEATHER), LEATHER),
    ("R35 blanco 60% sobre madera (etiquetas hoja)", blend(WHITE, 0.60, WOOD), WOOD),
    ("R35 blanco 70% sobre cuero (subtítulos panel)", blend(WHITE, 0.70, LEATHER), LEATHER),
    ("R35 dorado claro #FFE9A8 sobre negro 45% (BalanceChip)", hx("FFE9A8"), blend((0, 0, 0), 0.45, WOOD)),
    ("R35 ivory sobre navy (píldoras barra mesa, fuera de M5)", IVORY, NAVY),
    ("R35 blanco 70% sobre navy (textos barra mesa)", blend(WHITE, 0.70, NAVY), NAVY),
    ("R35 nombre rival marfil sobre paño (asiento)", IVORY, FELT_C),
    ("R35 nombre rival marfil sobre paño oscuro (viñeta)", IVORY, FELT_DARK),
    ("R22/R28 texto DJ 14 px ivory sobre cuero hoja", IVORY, LEATHER),
    ("R24 banda tienda ivory 70% sobre cuero", blend(IVORY, 0.70, LEATHER), LEATHER),
]
EXEMPT = [
    ("R34 EXENTO deshabilitado APOSTAR: dorado 30% + texto oscuro 50%",
     blend(GOLD_DK, 0.50, blend(GOLD, 0.30, CONSOLE_BG)),
     blend(GOLD, 0.30, CONSOLE_BG)),
    ("R34 EXENTO deshabilitado DUDO: rojo 30% + texto 50%",
     blend(WHITE, 0.50, blend(RED, 0.30, CONSOLE_BG)),
     blend(RED, 0.30, CONSOLE_BG)),
    ("R34 EXENTO deshabilitado CALZO: verde 30% + texto 50%",
     blend(WHITE, 0.50, blend(GREEN, 0.30, CONSOLE_BG)),
     blend(GREEN, 0.30, CONSOLE_BG)),
]

fails = 0
for name, fg, bg in PAIRS:
    r = ratio(fg, bg)
    ok = "OK " if r >= 4.5 else "FALLA"
    if r < 4.5:
        fails += 1
    print(f"{ok} {r:5.2f}:1  {name}")
print("--- exentos R34 (motivo del bloqueo legible a 14 px en otro elemento) ---")
for name, fg, bg in EXEMPT:
    print(f"EXENTO {ratio(fg, bg):5.2f}:1  {name}")
print(f"TOTAL: {len(PAIRS)} pares, {fails} bajo 4,5:1")
