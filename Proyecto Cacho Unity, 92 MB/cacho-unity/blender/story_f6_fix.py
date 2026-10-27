# Re-render SOLO del F6 del storyboard (veredicto), con las correcciones:
# disco central a z 0.12 (sobre el posavasos) y dado perdedor a (1.9,-0.6)
# (antes 2.3, salia cortado por el borde derecho). Autocontenido.
import bpy, math, os

BASE = "/home/hatch/workspace/cacho-unity"
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE, "blender/mesa_cacho.blend"))
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.use_denoising = True
scene.cycles.samples = 32
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = 0.15
scene.cycles.adaptive_min_samples = 8
scene.render.image_settings.file_format = 'PNG'
scene.render.resolution_x = 1688
scene.render.resolution_y = 950

foco = bpy.data.objects["FocoMesa"]
foco.location = (0, 0.35, 0.2)
bpy.ops.object.camera_add(location=(0, -4.8, 4.2), rotation=(0.911, 0, 0))
cam = bpy.context.active_object
cam.name = "CamaraRevelacionSB"
cam.data.lens = 40
cam.data.dof.use_dof = True
cam.data.dof.focus_object = foco
cam.data.dof.aperture_fstop = 4.0
scene.camera = cam

POS = [(-1.3, 0.7), (0, 0.9), (1.3, 0.7), (-0.65, -0.2), (0.65, -0.2)]
ROT = [(-math.pi / 2, 0, 0.3), (0, 0, 1.2), (-math.pi / 2, 0, 2.1),
       (0, -math.pi / 2, 0.7), (math.pi / 2, 0, 1.8)]
SCALE = 0.55 / 0.34
revel = [bpy.data.objects[f"DadoRevelado_{i}"] for i in range(1, 6)]
for d, p, r in zip(revel, POS, ROT):
    d.hide_render = False
    for ch in d.children: ch.hide_render = False
    d.location = (p[0], p[1], 0.28)
    d.rotation_euler = r
    d.scale = (SCALE, SCALE, SCALE)
for v in list(bpy.data.objects):
    if v.name.startswith("Vaso_") or v.name.startswith("DadoMio_"):
        v.hide_render = True
        for ch in v.children: ch.hide_render = True

GLOW = bpy.data.materials.new("BrilloCuentaSBFix")
GLOW.use_nodes = True
GLOW.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (1.0, 0.78, 0.30, 1.0)
GLOW.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 8.0
GLOW.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.79, 0.63, 0.29, 1.0)
for idx in [0, 1, 2]:
    d = revel[idx]
    z_disco = 0.12 if idx == 1 else 0.03
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.45, depth=0.02,
                                        location=(d.location.x, d.location.y, z_disco))
    g = bpy.context.active_object
    g.name = f"DiscoCuenta_{idx}"
    g.data.materials.append(GLOW)
revel[4].location = (1.9, -0.6, 0.28)
revel[4].rotation_euler = (0.5, 0.0, 0.8)
scene.render.filepath = os.path.join(BASE, "renders/storyboard_dudo/6_veredicto.png")
bpy.ops.render.render(write_still=True)
print("STORYF6FIX_OK")
