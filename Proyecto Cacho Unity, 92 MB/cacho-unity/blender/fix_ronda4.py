# FIX ronda 4 tras previa 1: colores iteración 2 (pendiente local
# display/lineal medida en la previa), cámara intermedia 0,889 rad
# (0,807 enterraba la placa TÚ bajo la consola; 0,965 era ronda 3),
# bordes de barra sin recorte (Salir +0,02, ajustes a 1,58 con
# dientes a radio 0,09).
import bpy, math
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda4.blend")
scene = bpy.context.scene
cam = bpy.data.objects["CamaraHero"]

def princ(mat):
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            return n

def set_emis(mat, color, strength=None):
    n = princ(mat)
    if n:
        n.inputs['Emission Color'].default_value = (color[0], color[1], color[2], 1.0)
        if strength is not None:
            n.inputs['Emission Strength'].default_value = strength

cam.location = (0.0, -12.3, 10.0)
cam.rotation_euler = (math.atan2(12.3, 10.0), 0.0, 0.0)  # 0,889 rad
print("CAMARA", tuple(cam.location), tuple(round(v, 4) for v in cam.rotation_euler))

# Colores iteración 2 (objetivos: oro #C9A24B, CALZO #0E7A4F,
# DUDO #B3202A, PASO #14586B; previa 1: oro (205,185,106),
# CALZO (15,140,97), DUDO (171,36,48), PASO (20,110,125)).
set_emis(bpy.data.materials["R2_OroMate"], (0.690, 0.310, 0.0503), strength=1.0)
set_emis(bpy.data.materials["R2_Calzo"], (0.003, 0.255, 0.101), strength=1.0)
set_emis(bpy.data.materials["R2_Dudo"], (0.596, 0.0173, 0.0286), strength=1.0)
set_emis(bpy.data.materials["R2_Paso"], (0.006, 0.131, 0.195), strength=1.0)

# Barra: Salir +0,02 (la X rozaba el borde izquierdo), ajustes a 1,58
# (los dientes a 1,725 se cortaban; ahora exterior 1,692 < 1,71).
for n, x in (("R4_SalirPill", -1.54), ("R4_SalirX1", -1.64),
             ("R4_SalirX2", -1.64), ("R4_SalirTxt", -1.49)):
    o = bpy.data.objects.get(n)
    if o:
        o.location = (x, o.location.y, o.location.z)
aj = bpy.data.objects.get("R2_Ajustes")
if aj:
    aj.location = (1.58, 0.79, -2.98)
gc = bpy.data.objects.get("R4_GearCentro")
if gc:
    gc.location = (1.58, 0.79, -2.96)
for i in range(8):
    o = bpy.data.objects.get(f"R4_GearDiente_{i}")
    if o:
        ang = i * math.pi / 4.0
        o.location = (1.58 + 0.09 * math.cos(ang), 0.79 + 0.09 * math.sin(ang), -2.96)

bpy.ops.wm.save_mainfile()
print("FIX_R4_OK")
