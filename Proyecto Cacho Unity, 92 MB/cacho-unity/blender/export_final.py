# Re-exporta GLB + FBX desde el blend FINAL (tras parches v6b/v6c).
# No guarda el blend. Los textos ya son mallas, asi que la exportacion es directa.
import bpy, os
BASE = "/home/hatch/workspace/cacho-unity"
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE, "blender/mesa_cacho.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(BASE, "blender/mesa_cacho.glb"),
                          export_format='GLB', export_yup=True)
print("GLB_OK")
bpy.ops.export_scene.fbx(filepath=os.path.join(BASE, "blender/mesa_cacho.fbx"),
                         axis_forward='-Z', axis_up='Y')
print("FBX_OK")
