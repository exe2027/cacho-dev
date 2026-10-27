#!/usr/bin/env python3
"""Sintetiza los sonidos de monedas de Cacho (economía de monedas, 22-oct).

- coins.wav:    cascada de ~16 clinks metálicos en ~1.4 s (densos al
                inicio, espaciándose y bajando de volumen: el pozo que
                cae sobre el ganador).
- coin_one.wav: UN solo clink de 0.25 s (tocar/apostar monedas).

Cada clink es un ping FM (portadora 2-5.5 kHz, moduladora inarmónica con
índice que decae rápido, envolvente exponencial corta): brillo metálico
sin graves, pensado para el parlante de un teléfono. Normalizado a
-3 dB peak, 22050 Hz mono 16-bit como el resto de los assets.
Uso: python3 tools/gen_coins.py  -> escribe en app/assets/sounds/
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "sounds")
PEAK_DB = -3.0
PEAK = 10 ** (PEAK_DB / 20.0)  # ≈ 0.7079


def fm_clink(rng, dur=0.30):
    """Un clink metálico: FM de 2 parciales + tick de ataque."""
    t = np.arange(int(dur * SR)) / SR
    fc = rng.uniform(2000.0, 5500.0)
    fm = fc * rng.uniform(1.32, 3.9)          # relación inarmónica
    tau_m = rng.uniform(0.004, 0.012)         # el índice FM muere rápido
    index = rng.uniform(2.0, 6.0) * np.exp(-t / tau_m)
    tau = rng.uniform(0.030, 0.085)           # anillo corto de la moneda
    y = np.sin(2 * np.pi * fc * t + index * np.sin(2 * np.pi * fm * t))
    y = y * np.exp(-t / tau)
    fc2 = fc * rng.uniform(2.1, 2.9)          # parcial alto, más breve
    y = y + 0.35 * np.sin(2 * np.pi * fc2 * t
                          + 1.5 * index * np.sin(2 * np.pi * fc2 * 1.5 * t)) \
        * np.exp(-t / (tau * 0.6))
    n = int(0.003 * SR)                       # tick de ataque (3 ms)
    y[:n] += rng.uniform(-1, 1, n) * 0.25 * np.linspace(1, 0, n)
    return y


def add(buf, sig, start_s):
    i0 = int(start_s * SR)
    end = min(len(buf), i0 + len(sig))
    if end > i0:
        buf[i0:end] += sig[:end - i0]


def write_wav(path, buf):
    m = np.max(np.abs(buf)) or 1.0
    buf = buf * (PEAK / m)
    frames = (np.clip(buf, -1.0, 1.0) * 32767).astype("<i2").tobytes()
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)
    print("ok", path, f"{len(buf) / SR:.2f}s", f"peak {PEAK_DB:.0f} dB")


def coins_cascade():
    rng = np.random.default_rng(20261022)
    buf = np.zeros(int(1.4 * SR))
    n = 16
    tcur = 0.0
    for i in range(n):
        frac = i / (n - 1)
        # Volumen descendente con jitter (las primeras caen con fuerza).
        gain = 0.95 * (1.0 - frac) ** 0.65 + 0.12
        gain *= rng.uniform(0.75, 1.0)
        add(buf, fm_clink(rng) * gain, tcur)
        # Intervalos que crecen: ~28 ms al inicio, ~140 ms al final.
        tcur += 0.028 + 0.112 * frac ** 2
    write_wav(os.path.join(OUT, "coins.wav"), buf)


def coin_one():
    rng = np.random.default_rng(20261023)
    buf = np.zeros(int(0.25 * SR))
    add(buf, fm_clink(rng, dur=0.25), 0.0)
    write_wav(os.path.join(OUT, "coin_one.wav"), buf)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    coins_cascade()
    coin_one()
