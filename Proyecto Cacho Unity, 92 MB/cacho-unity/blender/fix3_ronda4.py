# FIX 3 ronda 4: (a) bordes de barra con el mapeo real medido
# (NDC: local 0 -> 0,5; 1 unidad local = 0,3003 NDC = 507 px a 1688;
# la banda 1,71 excede la pantalla: lo visible llega a local 1,661).
# Salir: píldora 0,25 a -1,52 (10..137 px), X a -1,62 (10..38 px),
# texto a -1,47; iconos Ø0,17 en 0,98/1,18/1,38/1,57 (huecos 0,02-0,03,
# engranaje exterior 1,67 -> 1681 px, dentro). (b) Color iteración 4
# (a medio camino entre iter3 y el objetivo por pendiente local, para
# no perseguir ruido de muestreo; DUDO y oro ya en Δ≤8, sin cambio).
import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda4.blend")

def princ(mat):
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            return n

def set_emis(mat, color):
    n = princ(mat)
    if n:
        n.inputs['Emission Color'].default_value = (color[0], color[1], color[2], 1.0)
        n.inputs['Emission Strength'].default_value = 1.0

def move(name, x, y=None, z=None):
    o = bpy.data.objects.get(name)
    if o:
        o.location = (x, o.location.y if y is None else y,
                      o.location.z if z is None else z)
    else:
        print("FALTA", name)

# Salir
o = bpy.data.objects.get("R4_SalirPill")
o.location = (-1.52, 0.79, -2.98)
o.scale = (0.125, 0.07, 0.01)
move("R4_SalirX1", -1.62)
move("R4_SalirX2", -1.62)
move("R4_SalirTxt", -1.47)
# Iconos: discos Ø0,17 + geometría recentrada
for disc, cx in (("R4_MicDisc", 0.98), ("R4_MusicaDisc", 1.18),
                 ("R4_HistDisc", 1.38)):
    o = bpy.data.objects.get(disc)
    o.location = (cx, 0.79, -2.98)
    o.scale = (1.214, 1.214, 1.0)
move("R4_MicCapsula", 0.98, 0.80)
move("R4_MicU1", 0.945, 0.76)
move("R4_MicU2", 1.015, 0.76)
move("R4_MicUBase", 0.98, 0.735)
move("R4_MicPie", 0.98, 0.715)
move("R4_NotaCabeza", 1.155, 0.755)
move("R4_NotaPlica", 1.195, 0.79)
move("R4_NotaCorchete", 1.202, 0.815)
move("R4_RelojEsfera", 1.38, 0.79)
move("R4_RelojAguja1", 1.38, 0.805)
move("R4_RelojAguja2", 1.39, 0.79)
aj = bpy.data.objects.get("R2_Ajustes")
aj.location = (1.57, 0.79, -2.98)
aj.scale = (1.214, 1.214, 1.0)
gc = bpy.data.objects.get("R4_GearCentro")
gc.location = (1.57, 0.79, -2.96)
import math
for i in range(8):
    o = bpy.data.objects.get(f"R4_GearDiente_{i}")
    ang = i * math.pi / 4.0
    o.location = (1.57 + 0.08 * math.cos(ang), 0.79 + 0.08 * math.sin(ang), -2.96)

# Color iteración 4
set_emis(bpy.data.materials["R2_Calzo"], (0.0035, 0.182, 0.0724))
set_emis(bpy.data.materials["R2_Paso"], (0.006, 0.0912, 0.140))

bpy.ops.wm.save_mainfile()
print("FIX3_R4_OK")
