# FIX 2 ronda 4: (a) separación en Z del HUD — la consola (frente -2,99)
# tapaba la mitad inferior de los botones porque ambas caras eran
# coplanares a z=-3,0 y el desempate variaba con la cámara (demostrado:
# sin consola los botones miden 380-462; con ella, 380-431).
# Nuevo apilado (mayor z = más cerca de cámara): consola -3,00;
# botones/tiles/píldora VER -2,98 (frente -2,97); iconos/barras/pips
# de tile -2,96 (frente -2,95); pips de icono -2,94; textos -2,96
# (planos, delante del frente -2,97 de su botón). (b) Color iteración 3
# (pendientes R3->iter2; objetivos oro #C9A24B, CALZO #0E7A4F,
# DUDO #B3202A, PASO #14586B).
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

def move_z(name, z):
    o = bpy.data.objects.get(name)
    if o:
        o.location = (o.location.x, o.location.y, z)
    else:
        print("FALTA", name)

for n in ("R2_BtnCalzo", "R2_BtnDudo", "R2_BtnPaso", "R3_VerBtn"):
    move_z(n, -2.98)
for n in ("R3_IconoDado_Calzo", "R3_IconoDado_Dudo",
          "R3_PasoBarra_1", "R3_PasoBarra_2"):
    move_z(n, -2.96)
for n in ("R3_IconoDadoPip_Calzo", "R3_IconoDadoPip_Dudo"):
    move_z(n, -2.94)
for i in range(1, 7):
    move_z(f"R2_Tile{i}", -2.98)
for o in bpy.data.objects:
    if o.name.startswith("R2_Tile") and "_pip" in o.name:
        o.location = (o.location.x, o.location.y, -2.96)

set_emis(bpy.data.materials["R2_OroMate"], (0.708, 0.320, 0.0516))
set_emis(bpy.data.materials["R2_Calzo"], (0.0035, 0.225, 0.0883))
set_emis(bpy.data.materials["R2_Dudo"], (0.579, 0.0157, 0.0259))
set_emis(bpy.data.materials["R2_Paso"], (0.006, 0.113, 0.171))

bpy.ops.wm.save_mainfile()
print("FIX2_R4_OK")
