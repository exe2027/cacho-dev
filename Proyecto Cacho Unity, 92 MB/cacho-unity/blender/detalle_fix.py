# DETALLE CORREGIDO — vaso de TÚ alzado A UN LADO (no encima) + camara picada.
# v1 del detalle fallaba: camara baja (0,-5.4,3.4) y vaso justo sobre los dados;
# el disco de TÚ y el vaso tapaban los 5 dados. Ahora: vaso en (1.1,-2.3,1.30)
# inclinado, camara en (0,-4.6,4.6) mirando a los dados (0,-2.6,0.2).
import bpy, math, os

BASE = "/home/hatch/workspace/cacho-unity"
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE, "blender/mesa_cacho.blend"))
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.use_denoising = True
scene.cycles.samples = 48
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = 0.10
scene.cycles.adaptive_min_samples = 16
scene.cycles.diffuse_bounces = 3
scene.cycles.glossy_bounces = 3
scene.cycles.transmission_bounces = 0
scene.cycles.transparent_max_bounces = 2
scene.cycles.caustics_reflective = False
scene.cycles.caustics_refractive = False
scene.render.resolution_x = 1688
scene.render.resolution_y = 950
scene.render.image_settings.file_format = 'PNG'

# Sin dados de revelacion en el detalle
for i in range(1, 6):
    d = bpy.data.objects[f"DadoRevelado_{i}"]
    d.hide_render = True
    for ch in d.children: ch.hide_render = True

vaso = bpy.data.objects["Vaso_TU"]
vaso.location = (1.1, -2.3, 1.30)
vaso.rotation_euler = (0.15, 0.0, 0.40)

# Caras variadas en mis dados (en v1 del detalle los 5 mostraban el As arriba
# porque solo tenian giro yaw; una mano de 5 ases es imposible y confundiria).
for name, rot in [("DadoMio_1", (0, 0, 0.4)), ("DadoMio_2", (math.pi / 2, 0, 1.1)),
                  ("DadoMio_3", (-math.pi / 2, 0, 2.0)), ("DadoMio_4", (0, -math.pi / 2, 2.6)),
                  ("DadoMio_5", (math.pi, 0, 0.9))]:
    bpy.data.objects[name].rotation_euler = rot

foco = bpy.data.objects["FocoMesa"]
foco.location = (0, -2.6, 0.3)
bpy.ops.object.camera_add(location=(0, -4.6, 4.6), rotation=(0.427, 0, 0))
cam = bpy.context.active_object
cam.name = "CamaraDetalle2"
cam.data.lens = 50
cam.data.dof.use_dof = True
cam.data.dof.focus_object = foco
cam.data.dof.aperture_fstop = 4.0
scene.camera = cam
scene.render.filepath = os.path.join(BASE, "renders/detalle_vaso_dados.png")
bpy.ops.render.render(write_still=True)
print("DETALLE_OK")
