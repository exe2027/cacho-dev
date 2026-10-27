# Moneda de oro para Cacho (economía de monedas, 22-oct):
#   moneda de oro con borde biselado, anillo y estrella de 5 puntas en
#   relieve en AMBAS caras, material Principled dorado metálico.
#   12 frames de un giro completo sobre el eje vertical (de canto en los
#   frames 3 y 9) -> app/assets/images/coins/coin_00.png ... coin_11.png
# Uso: ~/blender/blender -b --factory-startup -P tools/render_coin.py
import math
import os

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "app", "assets", "images", "coins"))


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


def add_light(kind, pos, energy, color, size=3.0, target=(0, 0, 0)):
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


def gold_mat(name="Gold"):
    """Oro Principled: base dorada, metallic 1.0, roughness 0.25."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb3((255, 219, 132))
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.25
    return mat


# Perfil (radio, z) del cuerpo: caras planas, bisel y canto, simétrico.
PROFILE = [
    (0.001, -0.080), (0.820, -0.080), (0.925, -0.062), (0.985, -0.028),
    (1.000, 0.000),
    (0.985, 0.028), (0.925, 0.062), (0.820, 0.080), (0.001, 0.080),
]

# Rotación que deja la moneda de pie: eje Z (caras) -> eje Y (hacia cámara).
UPRIGHT = Matrix.Rotation(math.radians(90), 4, "X")


def link_mesh(name, mesh, mat):
    mesh.transform(UPRIGHT)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def build_body(mat):
    seg = 96
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
    mesh = bpy.data.meshes.new("CoinBody")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = True
    return link_mesh("Coin", mesh, mat)


def star_outline(r_out=0.52, r_in=0.235):
    pts = []
    for k in range(10):
        a = math.pi / 2 + k * math.pi / 5
        r = r_out if k % 2 == 0 else r_in
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


def build_star(mat):
    """Prisma estrellado en relieve sobre la cara +Z (base ancha, tapa
    levemente menor: los flancos inclinados agarran la luz)."""
    pts = star_outline()
    z0, z1, top_scale = 0.045, 0.118, 0.86
    verts = [(x, y, z0) for x, y in pts] + \
            [(x * top_scale, y * top_scale, z1) for x, y in pts]
    faces = [tuple(reversed(range(10))), tuple(range(10, 20))]
    for k in range(10):
        j = (k + 1) % 10
        faces.append((k, j, 10 + j, 10 + k))
    mesh = bpy.data.meshes.new("CoinStar")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    return link_mesh("Star", mesh, mat)


def build_back_star(mat):
    """La misma estrella en la cara -Z: se copia la malla y se rota 180°
    sobre X (rotación propia: el winding queda consistente)."""
    front = bpy.context.scene.objects["Star"]
    mesh = front.data.copy()
    mesh.transform(Matrix.Rotation(math.pi, 4, "X"))
    mesh.name = "CoinStarBack"
    obj = bpy.data.objects.new("StarBack", mesh)
    bpy.context.collection.objects.link(obj)
    return obj  # ya viene "de pie": NO aplicar UPRIGHT de nuevo


def build_ring(mat, z):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.72, minor_radius=0.028,
        major_segments=72, minor_segments=12, location=(0, 0, 0))
    obj = bpy.context.object
    m = UPRIGHT @ Matrix.Translation(Vector((0, 0, z)))
    obj.data.transform(m)
    obj.location = (0, 0, 0)
    obj.data.materials.append(mat)
    obj.name = "Ring" if z > 0 else "RingBack"
    return obj


def build_coin():
    mat = gold_mat()
    parts = [build_body(mat), build_star(mat), build_back_star(mat),
             build_ring(mat, 0.072), build_ring(mat, -0.072)]
    return parts


def main():
    os.makedirs(OUT, exist_ok=True)
    clean_scene()
    base_render(256, 256)
    # Cámara levemente inclinada (~20° sobre la horizontal), moneda de pie.
    add_camera((0, -3.7, 1.35), (0, 0, 0), lens=50)
    # El metal vive de los reflejos: luces de área grandes y cálidas.
    add_light("AREA", (3.5, -2.5, 5.5), 1100, (1.0, 0.95, 0.88), 4.0)
    add_light("AREA", (0, -0.5, 6.5), 800, (1.0, 0.97, 0.90), 6.0)
    add_light("POINT", (-4.5, 3.0, 3.5), 650, (1.0, 0.72, 0.38))
    add_light("AREA", (-3.0, -3.5, 2.0), 220, (0.85, 0.92, 1.0), 3.0)
    parts = build_coin()
    sc = bpy.context.scene
    for i in range(12):
        ang = math.radians(i * 30)
        for o in parts:
            o.rotation_euler = (0, 0, ang)
        path = os.path.join(OUT, f"coin_{i:02d}.png")
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        print("rendered", path, flush=True)
    print("ALL DONE", flush=True)


if __name__ == "__main__":
    main()
