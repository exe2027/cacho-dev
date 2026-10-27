import bpy, math
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
TILT = 0.82
PY = (0, math.cos(TILT), math.sin(TILT))
a = bpy.data.objects["TextoApuesta"]
a.location = (a.location.x - 0.10, a.location.y - 0.05 * PY[1], a.location.z - 0.05 * PY[2])
bpy.ops.wm.save_mainfile()
print("PARCHE_V6F_OK")
