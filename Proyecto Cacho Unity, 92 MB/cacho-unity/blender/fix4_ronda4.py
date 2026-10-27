# FIX 4 ronda 4: (a) veredicto a y=-0,80 GUARDADO (sustituye al -1,15
# de ronda 3: con 3 líneas, el -1,15 dejaba "PIERDE 1 DADO · EL HUASO"
# bajo el disco TÚ en la previa; -0,80 la deja legible sin tocar los
# dados CH, medido en previa). La reproducibilidad se demuestra con
# el valor GUARDADO, sea cual sea: ningún desplazamiento vive ya en
# scripts. (b) Ajustes 1,57 -> 1,56 (margen del diente exterior).
import bpy, math
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda4.blend")
for _n in ("R2_TablaVeredicto", "R2_TablaVeredictoTxt"):
    _o = bpy.data.objects[_n]
    _o.location = (_o.location.x, -0.80, _o.location.z)
print("VEREDICTO-GUARDADO", tuple(bpy.data.objects["R2_TablaVeredicto"].location),
      tuple(bpy.data.objects["R2_TablaVeredictoTxt"].location))
aj = bpy.data.objects.get("R2_Ajustes")
aj.location = (1.56, 0.79, -2.98)
gc = bpy.data.objects.get("R4_GearCentro")
gc.location = (1.56, 0.79, -2.96)
for i in range(8):
    o = bpy.data.objects.get(f"R4_GearDiente_{i}")
    ang = i * math.pi / 4.0
    o.location = (1.56 + 0.08 * math.cos(ang), 0.79 + 0.08 * math.sin(ang), -2.96)
bpy.ops.wm.save_mainfile()
print("FIX4_R4_OK")
