import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda3.blend")
def srgb(r, g, b):
    def cv(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (cv(r), cv(g), cv(b), 1.0)
# U3b dorado: base negra (sin difuso que levanta G/B) + emisión compensada para filmic
oro = bpy.data.materials.get("R2_OroMate")
if oro:
    for n in oro.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            n.inputs['Base Color'].default_value = (0.0, 0.0, 0.0, 1.0)
            n.inputs['Emission Color'].default_value = srgb(0.69, 0.50, 0.21)
            n.inputs['Emission Strength'].default_value = 1.35
bpy.ops.wm.save_mainfile(); print("FIX3_R3_OK")
