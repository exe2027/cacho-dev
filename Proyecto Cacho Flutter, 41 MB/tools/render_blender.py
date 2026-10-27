# Renders 3D de Cacho en Blender (headless):
#   ~/blender/blender -b --factory-startup -P tools/render_blender.py
# Produce sprites con fondo transparente en app/assets/images/:
#   cup_cafe.png, cup_negro.png, cup_burdeos.png, cup_petroleo.png
#   die_1.png ... die_6.png
# El vaso es un torneado de cuero (banda dorada, boca oscura); los dados
# son cubos biselados marfil con pipas en relieve (el 1, rojo y grande).
import math
import os

import bpy
from mathutils import Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                   "app", "assets", "images")
OUT = os.path.normpath(OUT)
os.makedirs(OUT, exist_ok=True)


def srgb(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def srgb3(rgb):
    return tuple(srgb(c) for c in rgb) + (1.0,)


def clean_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def setup_render(w, h):
    sc = bpy.context.scene
    # Cycles (CPU): EEVEE exige libEGL, ausente en esta VM.
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 128
    sc.cycles.use_denoising = True
    sc.cycles.device = "CPU"
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.resolution_x = w
    sc.render.resolution_y = h
    sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "Filmic"
    sc.view_settings.look = "Medium High Contrast"
    world = bpy.data.worlds.new("W")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.015, 0.03, 0.02, 1.0)
    bg.inputs[1].default_value = 0.7
    return sc


def add_camera(pos, target, lens=50):
    data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", data)
    bpy.context.collection.objects.link(cam)
    cam.location = pos
    direction = Vector(target) - Vector(pos)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    data.lens = lens
    bpy.context.scene.camera = cam
    return cam


def add_light(kind, pos, energy, color, size=3.0):
    data = bpy.data.lights.new("L", kind)
    data.energy = energy
    data.color = color
    if kind == "AREA":
        data.shape = "DISK"
        data.size = size
    obj = bpy.data.objects.new("L", data)
    bpy.context.collection.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = (Vector((0, 0, 0.8)) - Vector(pos)).to_track_quat(
        "-Z", "Y").to_euler()
    return obj


def principled(name, base_rgb, roughness, metallic=0.0, noise_bump=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb3(base_rgb)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if noise_bump > 0:
        tex = nt.nodes.new("ShaderNodeTexNoise")
        tex.inputs["Scale"].default_value = 7.0
        tex.inputs["Detail"].default_value = 4.0
        tex.inputs["Roughness"].default_value = 0.9
        bump = nt.nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = noise_bump
        bump.inputs["Distance"].default_value = 0.025
        nt.links.new(tex.outputs["Fac"], bump.inputs["Height"])
        nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


# ---------------- el vaso (cacho de cuero) ----------------

def build_cup(leather_rgb):
    profile = [
        (0.001, 0.00), (0.46, 0.00), (0.52, 0.03), (0.55, 0.10),
        (0.60, 0.55), (0.70, 1.20), (0.80, 1.75), (0.85, 1.95),
        (0.87, 2.00), (0.83, 2.04), (0.78, 2.00), (0.74, 1.80),
        (0.70, 1.58),
    ]
    seg = 56
    verts, faces = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        ca, sa = math.cos(a), math.sin(a)
        for r, z in profile:
            verts.append((r * ca, r * sa, z))
    n = len(profile)
    for i in range(seg):
        j = (i + 1) % seg
        for k in range(n - 1):
            faces.append((i * n + k, j * n + k, j * n + k + 1, i * n + k + 1))
    mesh = bpy.data.meshes.new("CupMesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    cup = bpy.data.objects.new("Cup", mesh)
    bpy.context.collection.objects.link(cup)
    for poly in mesh.polygons:
        poly.use_smooth = True
    leather = principled("Leather", leather_rgb, 0.74, noise_bump=0.5)
    mesh.materials.append(leather)

    # Fondo interior oscuro (la boca del vaso)
    bpy.ops.mesh.primitive_circle_add(radius=0.71, vertices=40,
                                      location=(0, 0, 1.62), fill_type="NGON")
    mouth = bpy.context.object
    mouth.data.materials.append(
        principled("Mouth", (13, 8, 4), 1.0))

    # Banda dorada bajo el borde
    bpy.ops.mesh.primitive_torus_add(major_radius=0.862, minor_radius=0.028,
                                     major_segments=56, minor_segments=12,
                                     location=(0, 0, 1.90))
    band = bpy.context.object
    band.data.materials.append(
        principled("Gold", (201, 162, 75), 0.32, metallic=0.9))
    return cup


# Tonos base más oscuros que la paleta: Filmic + las luces aclaran el
# cuero ~1 paso; así el render final cae cerca del color de la app.
CUP_VARIANTS = {
    "cafe": (66, 39, 20),
    "negro": (24, 21, 19),
    "burdeos": (58, 20, 25),
    "petroleo": (12, 41, 49),
}


def render_cups():
    for name, rgb in CUP_VARIANTS.items():
        clean_scene()
        setup_render(512, 640)
        add_camera((2.4, -3.6, 2.5), (0, 0, 0.95), lens=55)
        add_light("AREA", (3.5, -2.5, 5.5), 800, (1.0, 0.95, 0.88), 4.0)
        add_light("POINT", (-4.5, 3.0, 3.5), 500, (1.0, 0.76, 0.42))
        add_light("AREA", (-3.0, -3.5, 2.0), 150, (0.85, 0.92, 1.0), 3.0)
        build_cup(rgb)
        path = os.path.join(OUT, f"cup_{name}.png")
        bpy.context.scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        print("rendered", path)


# ---------------- los dados ----------------

PIP_LAYOUT = {
    1: [(0, 0)],
    2: [(-0.34, -0.34), (0.34, 0.34)],
    3: [(-0.34, -0.34), (0, 0), (0.34, 0.34)],
    4: [(-0.34, -0.34), (0.34, -0.34), (-0.34, 0.34), (0.34, 0.34)],
    5: [(-0.34, -0.34), (0.34, -0.34), (0, 0), (-0.34, 0.34), (0.34, 0.34)],
    6: [(-0.34, -0.34), (0.34, -0.34), (-0.34, 0), (0.34, 0),
        (-0.34, 0.34), (0.34, 0.34)],
}

# (normal, eje u, eje v, valor) de las SEIS caras: opuestos suman 7.
# Todas llevan pipas: al rotar el dado, cualquier cara puede quedar arriba.
FACES = [
    ((0, 0, 1), (1, 0, 0), (0, 1, 0), 1),
    ((0, -1, 0), (1, 0, 0), (0, 0, 1), 2),
    ((1, 0, 0), (0, 1, 0), (0, 0, 1), 3),
    ((-1, 0, 0), (0, -1, 0), (0, 0, 1), 4),
    ((0, 1, 0), (-1, 0, 0), (0, 0, 1), 5),
    ((0, 0, -1), (1, 0, 0), (0, -1, 0), 6),
]

TOP_ROTATIONS = {
    1: (0, 0, 0),
    2: (-math.pi / 2, 0, 0),
    3: (0, -math.pi / 2, 0),
    4: (0, math.pi / 2, 0),
    5: (math.pi / 2, 0, 0),
    6: (math.pi, 0, 0),
}


def build_die():
    root = bpy.data.objects.new("Die", None)
    bpy.context.collection.objects.link(root)
    bpy.ops.mesh.primitive_cube_add(size=2.0)
    cube = bpy.context.object
    cube.name = "DieCube"
    bev = cube.modifiers.new("bev", "BEVEL")
    bev.width = 0.16
    bev.segments = 4
    bpy.context.view_layer.objects.active = cube
    bpy.ops.object.modifier_apply(modifier="bev")
    ivory = principled("Ivory", (245, 235, 215), 0.34)
    cube.data.materials.append(ivory)
    cube.parent = root

    pip_dark = principled("Pip", (10, 8, 6), 0.5)
    pip_red = principled("PipRed", (179, 32, 42), 0.45)
    for normal, u, v, value in FACES:
        n = Vector(normal)
        uu, vv = Vector(u), Vector(v)
        for du, dv in PIP_LAYOUT[value]:
            big = value == 1
            bpy.ops.mesh.primitive_cylinder_add(
                radius=0.17 if big else 0.12, depth=0.05, vertices=24)
            pip = bpy.context.object
            center = n * 0.985 + uu * du + vv * dv
            pip.location = center
            pip.rotation_mode = "QUATERNION"
            pip.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(n)
            pip.data.materials.append(pip_red if big else pip_dark)
            pip.parent = root
    return root


def render_dice():
    for value in range(1, 7):
        clean_scene()
        setup_render(448, 420)
        add_camera((3.4, -3.4, 3.1), (0, 0, 0), lens=50)
        add_light("AREA", (3.5, -2.0, 5.5), 1000, (1.0, 0.96, 0.9), 4.0)
        add_light("POINT", (-4.0, 3.0, 3.0), 420, (1.0, 0.78, 0.45))
        add_light("AREA", (-3.0, -3.0, 1.5), 200, (0.85, 0.92, 1.0), 3.0)
        die = build_die()
        die.rotation_euler = TOP_ROTATIONS[value]
        path = os.path.join(OUT, f"die_{value}.png")
        bpy.context.scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        print("rendered", path)


if __name__ == "__main__":
    import sys

    mode = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "all"
    if mode in ("all", "cups"):
        render_cups()
    if mode in ("all", "dice"):
        render_dice()
    print("ALL DONE ->", OUT)
