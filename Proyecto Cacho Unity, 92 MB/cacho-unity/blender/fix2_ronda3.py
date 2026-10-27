import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda3.blend")
# U3c: vaso TU al norte (-2.55) y 15% más bajo para liberar el disco TÚ sin tocar el logo
v = bpy.data.objects["Vaso_TU"]; v.location = (0.0, -2.55, 0.11); v.scale = (1.0, 1.0, 0.85)
p = bpy.data.objects["Posavasos_TU"]; p.location = (0.0, -2.55, 0.075)
# U3b: dorado a #C9A24B (filmic comprime: 0.95 daba #B6A051, se sube a 1.35)
oro = bpy.data.materials.get("R2_OroMate")
if oro:
    for n in oro.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            n.inputs['Emission Strength'].default_value = 1.35
# U3e: veredicto en 2 líneas cortas para caber entre las manos (pinta + autor)
tv = bpy.data.objects["R2_TablaVeredicto"]; tv.scale = (2.9, 0.46, 0.015)
tvt = bpy.data.objects["R2_TablaVeredictoTxt"]
tvt.data.body = "DUDO FALLA · 10/5\nQUINTAS · DON CHALO"; tvt.data.size = 0.56
bpy.ops.wm.save_mainfile(); print("FIX2_R3_OK")
