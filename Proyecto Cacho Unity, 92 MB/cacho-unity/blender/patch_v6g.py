import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
o = bpy.data.objects["TextoApuesta"]
col = bpy.data.collections["Asientos"]
if o.name not in col.objects: col.objects.link(o)
for c in list(o.users_collection):
    if c.name != "Asientos": c.objects.unlink(o)
print("TextoApuesta colecciones:", [c.name for c in o.users_collection])
bpy.ops.wm.save_mainfile()
print("PARCHE_V6G_OK")
