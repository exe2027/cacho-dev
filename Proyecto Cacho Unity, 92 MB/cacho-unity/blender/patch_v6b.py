# PARCHE v6b — correcciones medidas (sin reconstruir).
# - PlacaPozo: la malla ya mide 1.9 de ancho (el operador horneo la escala);
#   para 3.4 reales: scale.x = 3.4/1.9 = 1.789 (el v6 puso 3.4 -> 6.46).
# - Columna: disco 4.85, placa 3.59 (hueco disco-placa 1.26), POZO queda 2.39
#   (hueco placa-POZO 1.20). Textos POZO/apuesta subidos a 2.55 para que el
#   borde inferior de la placa no tape el texto.
# - Vasos medios a y=-0.70 (+posavasos) para despegarlos de las placas laterales.
# - Fichas: pila a (-1.45,0.95), lejos de la placa y del vaso de Don Chalo.
import bpy, math

bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
TILT = 0.82
NORMAL = (0, -math.sin(TILT), math.cos(TILT))

def move(name, loc):
    o = bpy.data.objects.get(name)
    if o: o.location = loc
    else: print("FALTA", name)

def seat(nombre, x, y):
    move(f"Avatar_{nombre}", (x, y, 0.75))
    move(f"AvatarCentro_{nombre}", (x, y, 0.75))
    move(f"Aro_{nombre}", (x, y, 0.75))
    ini = bpy.data.objects.get(f"Inicial_{nombre}")
    if ini: ini.location = (x + NORMAL[0] * 0.10, y + NORMAL[1] * 0.10, 0.75 + NORMAL[2] * 0.10)

seat("ElHuaso", 0, 4.85)
move("Placa_ElHuaso", (0, 3.59, 0.55))
o = bpy.data.objects.get("TextoPlaca_ElHuaso")
if o: o.location = (0 + NORMAL[0] * 0.07, 3.59 + NORMAL[1] * 0.07, 0.55 + NORMAL[2] * 0.07)
pozo = bpy.data.objects["PlacaPozo"]
pozo.scale.x = 3.4 / 1.9
for txt, x in [("TextoPozo", -0.85), ("TextoApuesta", 1.05)]:
    o = bpy.data.objects.get(txt)
    if o: o.location = (x + NORMAL[0] * 0.07, 2.55 + NORMAL[1] * 0.07, 0.55 + NORMAL[2] * 0.07)
    else: print("FALTA TEXTO", txt)
for i in range(10):
    move(f"FichaPozo_{i}", (-1.45, 0.95, 0.11 + i * 0.072))
move("Vaso_ElGuaton", (-3.19, -0.70, 0.11))
move("Posavasos_ElGuaton", (-3.19, -0.70, 0.075))
move("Vaso_LaCuca", (3.30, -0.70, 0.11))
move("Posavasos_LaCuca", (3.30, -0.70, 0.075))
bpy.ops.wm.save_mainfile()
print("PARCHE_V6B_OK")
