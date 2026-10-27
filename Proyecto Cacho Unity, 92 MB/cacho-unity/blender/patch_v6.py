# PARCHE v6 — Cacho Unity etapa 1 (correccion 09:35, pila sin solapes).
# Mueve objetos en el blend (sin reconstruir la escena) y guarda. Luego se mide
# con measure_overlaps.py. Cambios:
# - Columna superior: disco (0,4.70), placa (0,3.44), placa POZO+APUESTA (0.10,2.39),
#   vaso (0,1.60). Huecos disco-placa 1.26 y placa-POZO 1.05 (medidos).
# - POZO y APUESTA en UNA placa centrada (3.4 de ancho): entre los vasos laterales
#   no caben dos placas separadas sin tocarse (POZO 1.9 + apuesta 2.0 = 3.9 + hueco
#   > hueco libre entre vasos 4.54 con la columna centrada); la placa combinada
#   mantiene el indicador de apuesta actual junto al pozo y legible.
# - Placas laterales con hueco 1.26 bajo su disco; ML/MR bajan a -0.55.
# - TÚ: disco -3.70, placa -4.75; mi vaso -2.50. Camara atras (0,-11.0,9.9).
# - Fichas a (-1.05,1.95) + sueltas, lejos del vaso de Don Chalo.
import bpy, math, os

BASE = "/home/hatch/workspace/cacho-unity"
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE, "blender/mesa_cacho.blend"))
TILT = 0.82
NORMAL = (0, -math.sin(TILT), math.cos(TILT))

def move(name, loc):
    o = bpy.data.objects.get(name)
    if o: o.location = loc
    else: print("FALTA", name)

def seat(nombre, x, y):
    # Cada asiento son 4 objetos: disco exterior, centro, aro e iniciales.
    move(f"Avatar_{nombre}", (x, y, 0.75))
    move(f"AvatarCentro_{nombre}", (x, y, 0.75))
    move(f"Aro_{nombre}", (x, y, 0.75))
    ini = bpy.data.objects.get(f"Inicial_{nombre}")
    if ini: ini.location = (x + NORMAL[0] * 0.10, y + NORMAL[1] * 0.10, 0.75 + NORMAL[2] * 0.10)

seat("ElHuaso", 0, 4.70)
move("Placa_ElHuaso", (0, 3.44, 0.55))
move("Placa_DonChalo", (-4.70, 1.04, 0.55))
move("Placa_LaPituca", (4.70, 1.04, 0.55))
seat("ElGuaton", -5.15, -0.55)
move("Placa_ElGuaton", (-5.15, -1.81, 0.55))
seat("LaCuca", 5.15, -0.55)
move("Placa_LaCuca", (5.15, -1.81, 0.55))
seat("TU", 0, -3.70)
move("Placa_TU", (0, -4.75, 0.55))
move("Vaso_ElHuaso", (0, 1.60, 0.11))
move("Posavasos_ElHuaso", (0, 1.60, 0.075))
move("Vaso_TU", (0, -2.50, 0.11))
move("Posavasos_TU", (0, -2.50, 0.075))
# Textos de placa superior: siguen a sus placas (los textos son mallas sueltas)
for txt, (x, y, z) in [("TextoPlaca_ElHuaso", (0, 3.44, 0.55)),
                        ("TextoPlaca_DonChalo", (-4.70, 1.04, 0.55)),
                        ("TextoPlaca_LaPituca", (4.70, 1.04, 0.55)),
                        ("TextoPlaca_ElGuaton", (-5.15, -1.81, 0.55)),
                        ("TextoPlaca_LaCuca", (5.15, -1.81, 0.55)),
                        ("TextoPlaca_TU", (0, -4.75, 0.55))]:
    o = bpy.data.objects.get(txt)
    if o: o.location = (x + NORMAL[0] * 0.07, y + NORMAL[1] * 0.07, z + NORMAL[2] * 0.07)
# Placa POZO+APUESTA combinada
pozo = bpy.data.objects["PlacaPozo"]
pozo.location = (0.10, 2.39, 0.55)
pozo.scale.x = 3.4
tp = bpy.data.objects["TextoPozo"]
tp.location = (-0.85 + NORMAL[0] * 0.07, 2.49 + NORMAL[1] * 0.07, 0.55 + NORMAL[2] * 0.07)
for n in ["PlacaApuesta", "TextoApuesta"]:
    o = bpy.data.objects.get(n)
    if o: bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.text_add(location=(1.05 + NORMAL[0] * 0.07, 2.49 + NORMAL[1] * 0.07, 0.55 + NORMAL[2] * 0.07),
                        rotation=(TILT, 0, 0))
nt = bpy.context.active_object
nt.name = "TextoApuesta"
nt.data.body = "APUESTA ACTUAL\n5 Quintas\n(EJEMPLO)"
nt.data.size = 0.24
nt.data.align_x = 'CENTER'
nt.data.align_y = 'CENTER'
nt.data.extrude = 0.03
nt.data.bevel_depth = 0.008
nt.data.materials.append(bpy.data.materials["TextoDorado"])
bpy.context.view_layer.objects.active = nt
bpy.ops.object.convert(target='MESH')
# Fichas
for i in range(10):
    move(f"FichaPozo_{i}", (-1.05, 1.95, 0.11 + i * 0.072))
for (x, y), i in zip([(-1.75, 1.50), (-1.30, 1.05), (-1.85, 1.00)], range(3)):
    move(f"FichaSuelta_{i}", (x, y, 0.075))
# Camara atras para dar aire arriba y abajo
cam = bpy.data.objects["CamaraHero"]
cam.location = (0, -11.0, 9.9)
cam.rotation_euler = (0.815, 0, 0)
bpy.ops.wm.save_mainfile()
print("PARCHE_OK")
