# PARCHE v6d — dos fallos visibles del hero v6c.
# 1) Textos POZO/apuesta DETRAS de la placa: la "subida" en Y mundo (+0.10/+0.16)
#    los metio 0.047 bajo el plano de la placa (la placa los ocluia; solo asomaba
#    un filete por encima). Correccion: origen = centro placa + desplazamiento
#    A LO LARGO DEL PLANO + NORMAL*0.07 (delante de la cara), centrado vertical.
#    Plano: Y_plano=(0,0.682,0.731), normal=(0,-0.731,0.682). POZO (0.30, 2 lineas):
#    origen local +0.12; apuesta (0.18, 2 lineas): origen local +0.07.
# 2) Disco El Huaso tapado por la lampara central (centro del disco dentro de la
#    esfera de la lampara): la lampara central retrocede de y=5.0 a y=6.5.
import bpy, math

bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
TILT = 0.82
PY = (0, math.cos(TILT), math.sin(TILT))
NO = (0, -math.sin(TILT), math.cos(TILT))
PC = (0.10, 2.39, 0.55)

def place(name, x, local_y):
    o = bpy.data.objects[name]
    o.location = (x + NO[0] * 0.07,
                  PC[1] + local_y * PY[1] + NO[1] * 0.07,
                  PC[2] + local_y * PY[2] + NO[2] * 0.07)
    print(name, "->", tuple(round(v, 3) for v in o.location))

place("TextoPozo", -0.85, 0.12)
place("TextoApuesta", 1.05, 0.07)
for o in bpy.data.objects:
    if o.name.startswith("Lampara") and abs(o.location.x) < 0.01 and abs(o.location.y - 5.0) < 0.01:
        o.location.y = 6.5
        print("lampara central movida:", o.name, tuple(round(v, 3) for v in o.location))
bpy.ops.wm.save_mainfile()
print("PARCHE_V6D_OK")
