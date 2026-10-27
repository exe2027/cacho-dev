#!/usr/bin/env python3
"""Pitido de apuro de Cacho (últimos segundos del turno, aro en rojo).

Un solo tono puro y corto, en la banda que el parlante del teléfono sí
reproduce (lección del proyecto: nada bajo 300 Hz). Mismo formato que
tools/gen_audio2.py (mono, 16 bits, 22050 Hz).
Uso: python3 tools/gen_beep.py  -> escribe en app/assets/sounds/beep.wav
"""
import math
import os
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "sounds",
                    "beep.wav")

FREQ = 880.0  # La5: agudo, claro, imposible de confundir con el tick
DUR = 0.18

buf = []
for i in range(int(DUR * SR)):
    t = i / SR
    # Ataque instantáneo, caída rápida: suena a "pito", no a nota.
    env = math.exp(-6.0 * t)
    buf.append(0.9 * env * math.sin(2 * math.pi * FREQ * t))

frames = b"".join(
    struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in buf
)
with wave.open(OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(frames)
print("ok", OUT, f"{DUR}s")
