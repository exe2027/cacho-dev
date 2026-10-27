#!/usr/bin/env python3
"""Genera la música de casino (loop) y efectos nuevos de Cacho.

Todo sintetizado, sin muestras externas. La música es un loop de salón
(8 compases, swing, progresión Dm7-G7-Cmaj7-A7) con los acordes y la
melodía en frecuencias medias: en el parlante de un teléfono los graves
profundos no se escuchan (lección registrada del proyecto).
Uso: python3 tools/gen_audio2.py  -> escribe en app/assets/sounds/
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "sounds")


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def add_tone(buf, start, dur, freq, gain, decay=4.0, harmonics=(1.0, 0.35, 0.12)):
    i0 = int(start * SR)
    n = int(dur * SR)
    for i in range(n):
        idx = i0 + i
        if idx >= len(buf):
            break
        t = i / SR
        env = math.exp(-decay * t)
        v = 0.0
        for k, h in enumerate(harmonics, start=1):
            v += h * math.sin(2 * math.pi * freq * k * t)
        buf[idx] += gain * env * v


def add_noise(buf, start, dur, gain, decay=30.0, seed=7):
    rnd = random.Random(seed)
    i0 = int(start * SR)
    n = int(dur * SR)
    prev = 0.0
    for i in range(n):
        idx = i0 + i
        if idx >= len(buf):
            break
        t = i / SR
        w = rnd.uniform(-1, 1)
        hp = w - prev * 0.92  # paso alto casero: solo el "tick"
        prev = w
        buf[idx] += gain * math.exp(-decay * t) * hp


def write_wav(path, buf, peak=0.85):
    m = max(abs(x) for x in buf) or 1.0
    scale = peak / m
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, x * scale)) * 32767)) for x in buf
    )
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)
    print("ok", path, f"{len(buf)/SR:.2f}s")


def music_loop():
    bpm = 112.0
    spb = 60.0 / bpm          # segundos por negra
    bars = 8
    total = bars * 4 * spb
    buf = [0.0] * int(total * SR)
    # Progresión por compás: (acorde en midis medios, bajo raíz midi)
    chords = [
        ([62, 65, 69, 72], 50),   # Dm7  (D F A C)  bajo D3
        ([59, 62, 65, 67], 55),   # G7   (B D F G)  bajo G2/G3
        ([60, 64, 67, 71], 48),   # Cmaj7           bajo C3
        ([60, 64, 67, 71], 48),   # Cmaj7
        ([62, 65, 69, 72], 50),   # Dm7
        ([59, 62, 65, 67], 55),   # G7
        ([60, 64, 67, 71], 48),   # Cmaj7
        ([61, 64, 67, 69], 57),   # A7   (C# E G A) bajo A2
    ]
    swing = 0.16 * spb  # desplazamiento de las corcheas impares
    for bar, (notes, bass_root) in enumerate(chords):
        t0 = bar * 4 * spb
        # Piano eléctrico: golpes en 1, en la corchea de 2 y en 4.
        for beat, when in ((0, 0.0), (1, 1.5 * spb + swing), (3, 3.0 * spb)):
            for mnote in notes:
                add_tone(buf, t0 + when, 1.4, midi(mnote), 0.16,
                         decay=2.6, harmonics=(1.0, 0.28, 0.05))
        # Bajo caminante: negra por tiempo (raíz, quinta, tercera, cromatismo).
        walk = [0, 7, 4, 10 if bar % 2 == 0 else 9]
        for i, st in enumerate(walk):
            f = midi(bass_root + 12 + st)  # una octava arriba: audible en móvil
            add_tone(buf, t0 + i * spb, spb * 0.95, f, 0.20,
                     decay=3.2, harmonics=(1.0, 0.45, 0.15))
        # Sombrerito: corcheas con swing, muy suave.
        for e in range(8):
            tt = t0 + e * (spb / 2) + (swing if e % 2 == 1 else 0.0)
            add_noise(buf, tt, 0.05, 0.05 if e % 2 == 0 else 0.032,
                      decay=46.0, seed=bar * 8 + e)
    # Melodía escasa (compases 2, 4 y 6): pentatónica, con silencios.
    melody = {
        2: [(0.0, 74), (1.0, 72), (2.0, 69)],
        4: [(0.5, 72), (1.5, 74), (3.0, 77)],
        6: [(0.0, 76), (1.0, 74), (2.0, 71), (3.0, 72)],
    }
    for bar, seq in melody.items():
        t0 = bar * 4 * spb
        for when, mnote in seq:
            add_tone(buf, t0 + when * spb, 1.0, midi(mnote), 0.13,
                     decay=3.4, harmonics=(1.0, 0.3, 0.08))
    # Costura del bucle: fundido cruzado de la cola sobre la cabeza.
    x = int(0.09 * SR)
    for i in range(x):
        wgt = i / x
        buf[i] = buf[i] * wgt + buf[len(buf) - x + i] * (1 - wgt)
    del buf[len(buf) - x:]
    write_wav(os.path.join(OUT, "music_loop.wav"), buf, peak=0.8)


def turn_pop():
    n = int(0.10 * SR)
    buf = [0.0] * n
    for i in range(n):
        t = i / SR
        f = 620 + 300 * (t / 0.10)
        buf[i] = math.sin(2 * math.pi * f * t) * math.exp(-26 * t)
    write_wav(os.path.join(OUT, "turn_pop.wav"), buf, peak=0.7)


def win_fanfare():
    buf = [0.0] * int(1.1 * SR)
    for k, mnote in enumerate([72, 76, 79, 84]):
        add_tone(buf, k * 0.13, 0.8, midi(mnote), 0.30,
                 decay=3.0, harmonics=(1.0, 0.4, 0.18))
    add_tone(buf, 0.52, 0.6, midi(79), 0.18, decay=3.0,
             harmonics=(1.0, 0.4, 0.18))
    write_wav(os.path.join(OUT, "win_fanfare.wav"), buf, peak=0.85)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    music_loop()
    turn_pop()
    win_fanfare()
