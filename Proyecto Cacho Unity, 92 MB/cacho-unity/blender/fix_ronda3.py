# FIX ronda 3 tras preview: disco TU 0.68, separación HU/POZO mayor,
# veredicto mayor, luz -28% extra, moneda a #C9A24B, fondo más visible.
import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda3.blend")
def move(n, loc):
    o = bpy.data.objects.get(n)
    if o: o.location = loc
    else: print("FALTA", n)
# U3h disco TU: 5.4% -> ~5.0% (igual que HU)
for n in ("Avatar_TU", "Aro_TU", "AvatarCentro_TU", "Inicial_TU", "R2_PuntoVerde_TU"):
    o = bpy.data.objects.get(n)
    if o: o.scale = (0.68, 0.68, o.scale.z)
move("R2_PuntoVerde_TU", (0.256, -3.476, 0.605))
# U3h separación HU/POZO: HU placa +0.08, pozo -0.15
move("Placa_ElHuaso", (0.0, 3.28, 0.55)); move("R2_TextoPlaca_ElHuaso", (0.0, 3.225, 0.601))
move("PlacaPozo", (0.0, 1.55, 0.55)); move("R2_TextoPozo", (0.0, 1.495, 0.601))
# U3g veredicto: línea hacia 2,4%H (0.56), tabla acorde
tv = bpy.data.objects["R2_TablaVeredicto"]; tv.scale = (3.1, 0.42, 0.015)
bpy.data.objects["R2_TablaVeredictoTxt"].data.size = 0.56
# U3b luz extra x0.72 + moneda a #C9A24B
for name, e in (("Clave", 400.0), ("Contraluz", 180.0), ("Relleno", 85.0)):
    L = bpy.data.objects.get(name)
    if L: L.data.energy = e
oro = bpy.data.materials.get("R2_OroMate")
if oro:
    for n in oro.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            n.inputs['Emission Strength'].default_value = 0.95
# U3j fondo: telón más cerca/bajo y brillante; suelo con repetición y más emisión
tel = bpy.data.objects.get("R3_TelonFoto")
if tel:
    tel.location = (0.0, 8.0, 2.6); tel.scale = (13.0, 3.4, 1.0)
    for m in tel.data.materials:
        for n in m.node_tree.nodes:
            if n.type == 'EMISSION': n.inputs['Strength'].default_value = 1.2
for img in bpy.data.images:
    if img.name.startswith("fondo_taberna_r3") or img.name.startswith("suelo_taberna_r3"):
        img.reload(); print("RELOAD", img.name)
suelo = bpy.data.objects.get("Suelo")
if suelo and suelo.data.materials:
    sm = suelo.data.materials[0]; nt = sm.node_tree
    tex = next((n for n in nt.nodes if n.type == 'TEX_IMAGE'), None)
    mix = next((n for n in nt.nodes if n.type == 'MIX_SHADER'), None)
    emi = next((n for n in nt.nodes if n.type == 'EMISSION'), None)
    if tex:
        tc = nt.nodes.new('ShaderNodeTexCoord')
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (8.0, 8.0, 1.0)
        nt.links.new(tc.outputs['UV'], mp.inputs['Vector'])
        nt.links.new(mp.outputs['Vector'], tex.inputs['Vector'])
    if mix: mix.inputs[0].default_value = 0.6
    if emi: emi.inputs['Strength'].default_value = 0.9
    print("SUELO fix OK")
bpy.ops.wm.save_mainfile(); print("FIX_R3_OK")
