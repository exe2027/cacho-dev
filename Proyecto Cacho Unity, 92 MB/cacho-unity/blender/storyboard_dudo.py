# STORYBOARD DUDO v2 — Cacho Unity etapa 1. DEFINICION, NO secuencia jugable.
# Correccion 09:35: los dados NUNCA se muestran pequenos e ilegibles.
# F1-F3: plano general hero (sin dados visibles: vasos cerrados).
# F4-F6: PRIMER PLANO de revelacion (dados grandes 0.55, sin solapes, 1688x950).
# F1 pausa / F2 primer vaso que se levanta / F3 tres vasos arriba /
# F4 dados cayendo (primer plano, en el aire) /
# F5 primer dado que cuenta destacado (primer plano) /
# F6 veredicto (primer plano: los 3 que cuentan destacados + dado perdedor aparte).
# Mano de ejemplo: [5, 1, 5, 3, 2] para la apuesta de ejemplo "5 Quintas"
# (cuentan 5 y 1-comodin). El vuelo de fichas al ganador se define en NOTAS.md,
# no se pinta en el primer plano.
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

OUT = os.path.join(BASE, "renders/storyboard_dudo")
os.makedirs(OUT, exist_ok=True)
cam_hero = bpy.data.objects["CamaraHero"]
foco = bpy.data.objects["FocoMesa"]

vasos = {n: bpy.data.objects[f"Vaso_{n}"] for n in
         ["DonChalo", "LaPituca", "ElGuaton", "LaCuca", "ElHuaso", "TU"]}
base = {n: (o.location.copy(), o.rotation_euler.copy()) for n, o in vasos.items()}
revel = [bpy.data.objects[f"DadoRevelado_{i}"] for i in range(1, 6)]
revel_base = [(d.location.copy(), d.rotation_euler.copy(), d.scale.copy()) for d in revel]
POS = [(-1.3, 0.7), (0, 0.9), (1.3, 0.7), (-0.65, -0.2), (0.65, -0.2)]
ROT = [(-math.pi / 2, 0, 0.3), (0, 0, 1.2), (-math.pi / 2, 0, 2.1),
       (0, -math.pi / 2, 0.7), (math.pi / 2, 0, 1.8)]
SCALE = 0.55 / 0.34

def reset():
    for n, o in vasos.items():
        o.location, o.rotation_euler = base[n][0].copy(), base[n][1].copy()
    for d, (loc, rot, sc) in zip(revel, revel_base):
        d.location, d.rotation_euler, d.scale = loc.copy(), rot.copy(), sc.copy()
        d.hide_render = True
        for ch in d.children: ch.hide_render = True
    for g in list(bpy.data.objects):
        if g.name.startswith("DiscoCuenta"):
            bpy.data.objects.remove(g, do_unlink=True)

def lift(names, z=1.35):
    for n in names:
        vasos[n].location.z += z
        vasos[n].rotation_euler = (0.22, 0.0, 0.30)

def hide_cups():
    # En primer plano de conteo los vasos se apartan (ver nota en reveal_seq.py):
    # el vaso superior-central taparia el dado central. Los posavasos se quedan.
    for n, o in vasos.items():
        o.hide_render = True
        for ch in o.children: ch.hide_render = True
    for d in bpy.data.objects:
        if d.name.startswith("DadoMio_"):
            d.hide_render = True
            for ch in d.children: ch.hide_render = True

def show_big(z_off=0.0):
    for d, p, r in zip(revel, POS, ROT):
        d.hide_render = False
        for ch in d.children: ch.hide_render = False
        d.location = (p[0], p[1], 0.28 + z_off)
        d.rotation_euler = r
        d.scale = (SCALE, SCALE, SCALE)

GLOW = bpy.data.materials.new("BrilloCuentaSB")
GLOW.use_nodes = True
GLOW.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (1.0, 0.78, 0.30, 1.0)
GLOW.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 8.0
GLOW.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.79, 0.63, 0.29, 1.0)

def discs(idxs):
    for idx in idxs:
        d = revel[idx]
        # Igual que en reveal_seq.py: el dado central esta sobre el posavasos.
        z_disco = 0.12 if idx == 1 else 0.03
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.45, depth=0.02,
                                            location=(d.location.x, d.location.y, z_disco))
        g = bpy.context.active_object
        g.name = f"DiscoCuenta_{idx}"
        g.data.materials.append(GLOW)

def frame(path, setup, cam, w, h):
    reset()
    setup()
    scene.camera = cam
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("STORY_OK", path)

# Camara de primer plano de revelacion (se crea una vez, se reutiliza)
bpy.ops.object.camera_add(location=(0, -4.8, 4.2), rotation=(0.911, 0, 0))
cam_close = bpy.context.active_object
cam_close.name = "CamaraRevelacionSB"
cam_close.data.lens = 40
cam_close.data.dof.use_dof = True
cam_close.data.dof.focus_object = foco
cam_close.data.dof.aperture_fstop = 4.0

frame(os.path.join(OUT, "1_pausa.png"), lambda: None, cam_hero, 960, 540)
frame(os.path.join(OUT, "2_primer_vaso.png"), lambda: lift(["LaCuca"]), cam_hero, 960, 540)
frame(os.path.join(OUT, "3_vasos_levantados.png"),
      lambda: lift(["LaCuca", "DonChalo", "ElGuaton"]), cam_hero, 960, 540)

def f4():
    # Correccion verificada: el vaso TÚ levantado tapaba la fila inferior y el
    # superior-central tapaba el pozo. TÚ apartado (pose detalle); ElHuaso +3.0
    # (casi fuera de cuadro); laterales +1.35 como antes.
    lift(["DonChalo", "LaPituca", "ElGuaton", "LaCuca"])
    vasos["ElHuaso"].location.z += 3.0
    vasos["ElHuaso"].rotation_euler = (0.22, 0.0, 0.30)
    vasos["TU"].location = (1.1, -2.3, 1.30)
    vasos["TU"].rotation_euler = (0.15, 0.0, 0.40)
    show_big(z_off=0.65)
    foco.location = (0, 0.35, 0.2)
frame(os.path.join(OUT, "4_dados_cayendo.png"), f4, cam_close, 1688, 950)

def f5():
    show_big()
    hide_cups()
    discs([0])
    foco.location = (0, 0.35, 0.2)
frame(os.path.join(OUT, "5_dados_que_cuentan.png"), f5, cam_close, 1688, 950)

def f6():
    show_big()
    hide_cups()
    discs([0, 1, 2])
    revel[4].location = (1.9, -0.6, 0.28)
    revel[4].rotation_euler = (0.5, 0.0, 0.8)
    foco.location = (0, 0.35, 0.2)
frame(os.path.join(OUT, "6_veredicto.png"), f6, cam_close, 1688, 950)
print("STORY_FIN")
