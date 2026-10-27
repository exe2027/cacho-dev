import bpy, math
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
TILT = 0.82
PY = (0, math.cos(TILT), math.sin(TILT))
o = bpy.data.objects["TextoPozo"]
o.location = (o.location.x, o.location.y - 0.12 * PY[1], o.location.z - 0.12 * PY[2])
a = bpy.data.objects["TextoApuesta"]
a.scale = (0.75, 0.75, 0.75)
bpy.ops.wm.save_mainfile()
print("PARCHE_V6E_OK")
