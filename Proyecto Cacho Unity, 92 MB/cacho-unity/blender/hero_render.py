import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
scene = bpy.context.scene
scene.camera = bpy.data.objects["CamaraHero"]
scene.render.resolution_x = 1688
scene.render.resolution_y = 950
scene.render.filepath = "/home/hatch/workspace/cacho-unity/renders/mesa_hero.png"
bpy.ops.render.render(write_still=True)
print("HERO_RENDER_OK")
