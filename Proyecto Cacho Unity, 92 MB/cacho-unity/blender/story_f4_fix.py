# Re-render SOLO del F4 del storyboard (dados cayendo), con la correccion:
# el vaso TÚ levantado tapaba la fila inferior de dados (es el mas cercano a
# camara) y el superior-central tapaba el texto del pozo. Ahora: TÚ apartado
# a un lado (pose del detalle), superior-central levantado +3.0 (casi fuera
# de cuadro, sin tapar el pozo), laterales levantados +1.35 como antes.
# Autocontenido.
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
    d.location = (p[0], p[1], 0.28 + 0.65)
    d.rotation_euler = r
    d.scale = (SCALE, SCALE, SCALE)

vasos = {n: bpy.data.objects[f"Vaso_{n}"] for n in
         ["DonChalo", "LaPituca", "ElGuaton", "LaCuca", "ElHuaso", "TU"]}
for n in ["DonChalo", "LaPituca", "ElGuaton", "LaCuca"]:
    vasos[n].location.z += 1.35
    vasos[n].rotation_euler = (0.22, 0.0, 0.30)
vasos["ElHuaso"].location.z += 3.0
vasos["ElHuaso"].rotation_euler = (0.22, 0.0, 0.30)
vasos["TU"].location = (1.1, -2.3, 1.30)
vasos["TU"].rotation_euler = (0.15, 0.0, 0.40)

scene.render.filepath = os.path.join(BASE, "renders/storyboard_dudo/4_dados_cayendo.png")
bpy.ops.render.render(write_still=True)
print("STORYF4FIX_OK")
