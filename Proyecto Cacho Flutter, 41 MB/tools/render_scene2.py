# Ronda 2 de Blender para Cacho (dirección de arte del usuario, 22-oct):
#   vaso de cuero CON COSTURAS crema (borde, base y costura lateral),
#   sin banda dorada, en los 4 colores -> cup_{cafe,negro,burdeos,petroleo}.png
#   plato de fondo: bar oscuro con bokeh cálido y mesa de madera en
#   perspectiva con luz cenital -> bg_pub.png (720x1280)
# Uso: ~/blender/blender -b --factory-startup -P tools/render_scene2.py [-- cups|plate|all]
import math
import os

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "app", "assets", "images"))
WOOD = os.path.join(OUT, "wood.png")
BOKEH = os.path.join(HERE, "bokeh.png")


def srgb(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def srgb3(rgb):
    return tuple(srgb(c) for c in rgb) + (1.0,)


def clean_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def base_render(w, h, world_rgb=(0.012, 0.008, 0.006), world_str=0.55):
    sc = bpy.context.scene
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
    bg.inputs[0].default_value = world_rgb + (1.0,)
    bg.inputs[1].default_value = world_str
    return sc


def add_camera(pos, target, lens=50):
    data = bpy.data.cameras.new("Cam")
    cam = bpy.data.objects.new("Cam", data)
    bpy.context.collection.objects.link(cam)
    cam.location = pos
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat(
        "-Z", "Y").to_euler()
    data.lens = lens
    bpy.context.scene.camera = cam
    return cam


def add_light(kind, pos, energy, color, size=3.0, target=(0, 0, 0.8)):
    data = bpy.data.lights.new("L", kind)
    data.energy = energy
    data.color = color
    if kind == "AREA":
        data.shape = "DISK"
        data.size = size
    obj = bpy.data.objects.new("L", data)
    bpy.context.collection.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat(
        "-Z", "Y").to_euler()
    return obj


def leather_mat(name, base_rgb):
    """Cuero con variación de color y rugosidad por ruido (más real)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 6.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.85
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    dark = tuple(max(0.0, c * 0.62) for c in srgb3(base_rgb)[:3]) + (1.0,)
    ramp.color_ramp.elements[0].position = 0.32
    ramp.color_ramp.elements[0].color = dark
    ramp.color_ramp.elements[1].position = 0.72
    ramp.color_ramp.elements[1].color = srgb3(base_rgb)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.55
    bump.inputs["Distance"].default_value = 0.03
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    rough = nt.nodes.new("ShaderNodeMapRange")
    rough.inputs["From Min"].default_value = 0.0
    rough.inputs["From Max"].default_value = 1.0
    rough.inputs["To Min"].default_value = 0.58
    rough.inputs["To Max"].default_value = 0.86
    nt.links.new(noise.outputs["Fac"], rough.inputs["Value"])
    nt.links.new(rough.outputs["Result"], bsdf.inputs["Roughness"])
    return mat


def plain_mat(name, rgb, roughness):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb3(rgb)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


PROFILE = [
    (0.001, 0.00), (0.50, 0.00), (0.56, 0.04), (0.60, 0.10),
    (0.64, 0.55), (0.72, 1.20), (0.82, 1.75), (0.88, 1.94),
    (0.90, 2.00), (0.86, 2.05), (0.80, 2.00), (0.76, 1.82),
    (0.72, 1.60),
]


def radius_at(z):
    pts = PROFILE
    for i in range(len(pts) - 1):
        (r0, z0), (r1, z1) = pts[i], pts[i + 1]
        if z0 <= z <= z1 and z1 > z0:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return pts[-1][0]


def build_cup(leather_rgb):
    seg = 56
    verts, faces = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        ca, sa = math.cos(a), math.sin(a)
        for r, z in PROFILE:
            verts.append((r * ca, r * sa, z))
    n = len(PROFILE)
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
    mesh.materials.append(leather_mat("Leather", leather_rgb))

    bpy.ops.mesh.primitive_circle_add(radius=0.73, vertices=40,
                                      location=(0, 0, 1.62), fill_type="NGON")
    bpy.context.object.data.materials.append(plain_mat("Mouth", (12, 7, 4), 1.0))

    # ---- Costuras crema (cajas pequeñas tangenciales) ----
    stitch_mat = plain_mat("Stitch", (232, 216, 180), 0.9)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    proto = bpy.context.object
    proto.name = "StitchProto"
    proto.scale = (0.062, 0.018, 0.010)
    bpy.ops.object.transform_apply(scale=True)
    proto.data.materials.append(stitch_mat)
    proto.hide_render = True

    def stitch_ring(radius, z, count, tilt=0.0):
        for i in range(count):
            a = 2 * math.pi * i / count
            o = bpy.data.objects.new("st", proto.data)
            bpy.context.collection.objects.link(o)
            o.location = (radius * math.cos(a), radius * math.sin(a), z)
            o.rotation_euler = (tilt, 0, a + math.pi / 2)

    stitch_ring(0.878, 1.90, 46, tilt=0.5)   # borde superior
    stitch_ring(0.585, 0.17, 40, tilt=0.2)   # base
    # Costura vertical lateral (lado visible a la cámara)
    seam_a = -0.55
    for i in range(15):
        z = 0.28 + i * 0.098
        r = radius_at(z) + 0.004
        o = bpy.data.objects.new("st", proto.data)
        bpy.context.collection.objects.link(o)
        o.location = (r * math.cos(seam_a), r * math.sin(seam_a), z)
        o.rotation_euler = (0, 0.10, seam_a)
    return cup


CUP_VARIANTS = {
    "cafe": (96, 56, 28),
    "negro": (30, 26, 23),
    "burdeos": (74, 26, 32),
    "petroleo": (16, 52, 62),
}


def render_cups():
    for name, rgb in CUP_VARIANTS.items():
        clean_scene()
        base_render(640, 760)
        add_camera((2.4, -3.6, 2.5), (0, 0, 0.95), lens=55)
        add_light("AREA", (3.5, -2.5, 5.5), 800, (1.0, 0.95, 0.88), 4.0)
        add_light("POINT", (-4.5, 3.0, 3.5), 500, (1.0, 0.76, 0.42))
        add_light("AREA", (-3.0, -3.5, 2.0), 150, (0.85, 0.92, 1.0), 3.0)
        build_cup(rgb)
        path = os.path.join(OUT, f"cup_{name}.png")
        bpy.context.scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        print("rendered", path, flush=True)


def render_plate():
    clean_scene()
    sc = base_render(720, 1280, world_str=0.25)
    sc.render.film_transparent = False
    add_camera((0, -5.4, 3.1), (0, 0.6, 0.35), lens=42)
    # Mesa de madera
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    table = bpy.context.object
    tmat = bpy.data.materials.new("TableWood")
    tmat.use_nodes = True
    nt = tmat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.42
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(WOOD)
    tex.extension = "REPEAT"
    coord = nt.nodes.new("ShaderNodeTexCoord")
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (3.0, 3.0, 3.0)
    nt.links.new(coord.outputs["UV"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.25
    bump.inputs["Distance"].default_value = 0.05
    nt.links.new(tex.outputs["Color"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    table.data.materials.append(tmat)
    # Telón con bokeh cálido
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 7.5, 6))
    back = bpy.context.object
    back.rotation_euler = (math.radians(90), 0, 0)
    bmat = bpy.data.materials.new("Backdrop")
    bmat.use_nodes = True
    bnt = bmat.node_tree
    btex = bnt.nodes.new("ShaderNodeTexImage")
    btex.image = bpy.data.images.load(BOKEH)
    emit = bnt.nodes.new("ShaderNodeEmission")
    emit.inputs["Strength"].default_value = 0.85
    bnt.links.new(btex.outputs["Color"], emit.inputs["Color"])
    out = bnt.nodes["Material Output"]
    bnt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    back.data.materials.append(bmat)
    # Luces: cenital cálida sobre la mesa + relleno suave
    add_light("AREA", (0, -1.5, 7.5), 950, (1.0, 0.88, 0.70), 5.0,
              target=(0, 0.3, 0))
    add_light("POINT", (-4.5, -2.0, 3.0), 260, (1.0, 0.72, 0.42),
              target=(0, 0, 0))
    add_light("AREA", (3.5, -3.0, 2.0), 120, (0.8, 0.88, 1.0), 3.0,
              target=(0, 0, 0))
    path = os.path.join(OUT, "bg_pub_raw.png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("rendered", path, flush=True)


if __name__ == "__main__":
    import sys

    mode = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "all"
    if mode in ("all", "cups"):
        render_cups()
    if mode in ("all", "plate"):
        render_plate()
    print("ALL DONE", flush=True)
