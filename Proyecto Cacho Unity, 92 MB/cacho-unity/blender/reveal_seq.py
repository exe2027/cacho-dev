# SECUENCIA DE REVELACION LEGIBLE — Cacho Unity etapa 1 (correccion 09:35).
# La revelacion vieja (5 dados pequenos al centro) quedo RECHAZADA por ilegible.
# Ahora: primer plano, dados GRANDES (0.55), separados sin solapes, pipas legibles,
# y los que cuentan destacados UNO A UNO en secuencia.
# Mano de ejemplo (apuesta actual de ejemplo: 5 Quintas; cuentan 5 y 1-comodin):
#   dados: [5, 1, 5, 3, 2] -> cuentan el 1o (5), el 2o (1) y el 3o (5).
# Fotogramas: 1 mano / 2 cuenta el 1o / 3 cuentan 1o+2o / 4 cuentan 1o+2o+3o.
# Cubre cualquier resolucion (B6): Dudo, Calzo, duda de Paso (solo esa mano, P9),
# Kamikaze (dados nuevos). Es una secuencia de REFERENCIA, no una resolucion viva.
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

foco = bpy.data.objects["FocoMesa"]
foco.location = (0, 0.35, 0.2)
bpy.ops.object.camera_add(location=(0, -4.8, 4.2), rotation=(0.911, 0, 0))
cam = bpy.context.active_object
cam.name = "CamaraRevelacion"
cam.data.lens = 40
cam.data.dof.use_dof = True
cam.data.dof.focus_object = foco
cam.data.dof.aperture_fstop = 4.0
scene.camera = cam

OUT = os.path.join(BASE, "renders/revelacion")
os.makedirs(OUT, exist_ok=True)
# En primer plano de conteo los vasos se apartan: el vaso superior-central
# (0,1.00) caeria en pantalla sobre el dado central de la fila superior, y
# ocultar el vaso TÚ dejaria ver mis dados. Los vasos quedan fuera de cuadro
# (la historia del levantamiento ya la cuenta el storyboard F4); los posavasos
# planos se quedan (no tapan ningun dado: el dado, mas cercano, los ocluye).
for v in list(bpy.data.objects):
    if v.name.startswith("Vaso_") or v.name.startswith("DadoMio_"):
        v.hide_render = True
        for ch in v.children: ch.hide_render = True
GLOW = bpy.data.materials.new("BrilloCuentaSeq")
GLOW.use_nodes = True
GLOW.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (1.0, 0.78, 0.30, 1.0)
GLOW.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 8.0
GLOW.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.79, 0.63, 0.29, 1.0)

POS = [(-1.3, 0.7), (0, 0.9), (1.3, 0.7), (-0.65, -0.2), (0.65, -0.2)]
# caras superiores: 5, 1, 5, 3, 2 (rotaciones que llevan esa cara arriba)
ROT = [(-math.pi / 2, 0, 0.3), (0, 0, 1.2), (-math.pi / 2, 0, 2.1),
       (0, -math.pi / 2, 0.7), (math.pi / 2, 0, 1.8)]
SCALE = 0.55 / 0.34
dice = []
for i in range(5):
    d = bpy.data.objects[f"DadoRevelado_{i+1}"]
    d.hide_render = False
    for ch in d.children: ch.hide_render = False
    d.location = (POS[i][0], POS[i][1], 0.28)
    d.rotation_euler = ROT[i]
    d.scale = (SCALE, SCALE, SCALE)
    dice.append(d)

def frame(path, highlighted):
    for g in list(bpy.data.objects):
        if g.name.startswith("DiscoCuenta"):
            bpy.data.objects.remove(g, do_unlink=True)
    for idx in highlighted:
        d = dice[idx]
        # El dado central (idx 1) esta sobre el posavasos negro (tapa z 0.11):
        # su disco debe ir a z 0.12 para verse; los demas, sobre el pano, a 0.03.
        z_disco = 0.12 if idx == 1 else 0.03
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.45, depth=0.02,
                                            location=(d.location.x, d.location.y, z_disco))
        g = bpy.context.active_object
        g.name = f"DiscoCuenta_{idx}"
        g.data.materials.append(GLOW)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("REVEL_OK", path)

frame(os.path.join(BASE, "renders/mesa_revelacion.png"), [])
frame(os.path.join(OUT, "2_cuenta_1.png"), [0])
frame(os.path.join(OUT, "3_cuenta_2.png"), [0, 1])
frame(os.path.join(OUT, "4_cuenta_3.png"), [0, 1, 2])
print("REVEL_FIN")
