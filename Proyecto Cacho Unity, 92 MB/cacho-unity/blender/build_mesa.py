# CACHO Unity — Etapa 1 (solo visual). Escena Blender 4.2.3, Cycles CPU.
# Mesa ovalada casino oscuro + dorado mate, 6 asientos, 6 vasos, dados.
# 6 JUGADORES (correccion 09:35, manda sobre 5): 1 arriba al centro (El Huaso),
# 2 a la izquierda, 2 a la derecha, yo abajo al centro. Pila superior sin solapes:
# avatar superior-central, su placa, placa del POZO y vaso superior-central.
# Estado NORMAL (hero): vasos cerrados, SIN dados al centro (V2).
# Revelacion: NO se renderiza aqui; la hace reveal_seq.py en secuencia legible
# (dados grandes, sin solapes, destacados uno a uno). Detalle: detalle_fix.py.
# Nombres propios chilenos, originales. Cifras: saldo 5.000, pozo 3.000
# (El Casino 500 x 6 jugadores).
# Nombres propios chilenos, originales. Cifras: saldo 5.000, pozo 2.500 (Casino 500 x 5).
# Sin gameplay, sin codigo Unity, sin tocar ~/workspace/cacho/.

import bpy, math, os

BASE = "/home/hatch/workspace/cacho-unity"
BLEND = os.path.join(BASE, "blender/mesa_cacho.blend")
REND = os.path.join(BASE, "renders")
os.makedirs(os.path.join(BASE, "blender"), exist_ok=True)
os.makedirs(REND, exist_ok=True)

# ---------- limpieza ----------
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for coll in list(bpy.data.collections):
    bpy.data.collections.remove(coll)

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.use_denoising = True
scene.cycles.samples = 64
# Rendimiento WebGL/iPhone (build de prueba 07:43) y VM de 2 CPU: muestreo adaptativo,
# rebotes recortados y sin causticas; el denoisier compensa las muestras bajas.
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = 0.10
scene.cycles.adaptive_min_samples = 16
scene.cycles.diffuse_bounces = 3
scene.cycles.glossy_bounces = 3
scene.cycles.transmission_bounces = 0
scene.cycles.transparent_max_bounces = 2
scene.cycles.caustics_reflective = False
scene.cycles.caustics_refractive = False
scene.render.threads_mode = 'AUTO'
scene.view_settings.view_transform = 'Filmic'
scene.view_settings.look = 'Medium Contrast'
scene.render.resolution_x = 1688
scene.render.resolution_y = 950
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGB'

world = bpy.data.worlds['World']
world.use_nodes = True
bg = world.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (0.01, 0.006, 0.003, 1.0)
bg.inputs['Strength'].default_value = 0.25

COLLS = {}
for name in ["Mesa", "Vasos", "Dados", "Fichas", "Asientos", "Fondo", "Logo"]:
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    COLLS[name] = c

def link(obj, coll):
    bpy.context.scene.collection.objects.unlink(obj)
    COLLS[coll].objects.link(obj)
    return obj

def srgb(r, g, b):
    # sRGB (0-1, como los hex del encargo) -> lineal (lo que Blender espera).
    # Sin esto, 0xFF5A3A1E se renderiza como roble claro en vez de nogal oscuro.
    def cv(c):
        return ((c + 0.055) / 1.055) ** 2.4 if c > 0.04045 else c / 12.92
    return (cv(r), cv(g), cv(b))

def mat(name, color, rough=0.8, metallic=0.0, bump_scale=0.0, bump_strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metallic
    if bump_scale > 0:
        nt = m.node_tree.nodes.new('ShaderNodeTexNoise')
        nt.inputs['Scale'].default_value = bump_scale
        nt.inputs['Detail'].default_value = 6.0
        bump = m.node_tree.nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = bump_strength
        m.node_tree.links.new(nt.outputs['Fac'], bump.inputs['Height'])
        m.node_tree.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
        # Variacion de color (veta/fibra visible, nunca color plano): el mismo ruido
        # mezcla el color base con una variante apenas mas clara (factor atenuado
        # a 0.4 para no lavar el color: el error del primer hero fue mezclar a 1.0).
        mix = m.node_tree.nodes.new('ShaderNodeMixRGB')
        mix.blend_type = 'MIX'
        mix.inputs['Color1'].default_value = (*color, 1.0)
        mix.inputs['Color2'].default_value = (*(min(1.0, c * 1.3 + 0.02) for c in color), 1.0)
        att = m.node_tree.nodes.new('ShaderNodeMath')
        att.operation = 'MULTIPLY'
        att.inputs[1].default_value = 0.4
        m.node_tree.links.new(nt.outputs['Fac'], att.inputs[0])
        m.node_tree.links.new(att.outputs['Value'], mix.inputs['Fac'])
        m.node_tree.links.new(mix.outputs['Color'], bsdf.inputs['Base Color'])
    return m

WOOD   = mat("MaderaNogal", srgb(0.29, 0.18, 0.09), 0.55, 0.05, 8.0, 0.35)
FELT   = mat("PanoCarbon", srgb(0.20, 0.20, 0.21), 0.95, 0.0, 40.0, 0.25)
GOLD   = mat("DoradoMate", srgb(0.79, 0.63, 0.29), 0.35, 0.75)
LEATHER= mat("Cuero", srgb(0.43, 0.27, 0.15), 0.75, 0.0, 16.0, 0.12)
DARK   = mat("PosavasosOscuro", srgb(0.10, 0.10, 0.11), 0.9)
DICEW  = mat("DadoBlanco", (0.93, 0.93, 0.90), 0.35)
PIPB   = mat("PipaNegra", (0.05, 0.05, 0.05), 0.4)
PIPR   = mat("PipaRoja", (0.75, 0.05, 0.05), 0.4)
PLATE  = mat("PlacaOscura", srgb(0.13, 0.13, 0.14), 0.6, 0.2)
TEXTG  = mat("TextoDorado", (0.96, 0.90, 0.75), 0.5, 0.3)
TEXTW  = mat("TextoBlanco", (0.97, 0.96, 0.93), 0.6)
FLOOR  = mat("SueloTaberna", srgb(0.16, 0.11, 0.07), 0.95)
BACK   = mat("FondoTaberna", srgb(0.20, 0.12, 0.06), 1.0, 0.0, 4.0, 0.2)
LAMP   = bpy.data.materials.new("LamparaCalida")
LAMP.use_nodes = True
LAMP.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (1.0, 0.65, 0.30, 1.0)
LAMP.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 6.0
LAMP.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (1.0, 0.65, 0.30, 1.0)

def cyl(name, coll, radius, depth, loc, rot=(0, 0, 0), scale=(1, 1, 1), material=None, verts=64):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth,
                                        location=loc, rotation=rot, scale=scale)
    o = bpy.context.active_object
    o.name = name
    if material: o.data.materials.append(material)
    return link(o, coll)

def box(name, coll, loc, rot, scale, material=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot, scale=scale)
    o = bpy.context.active_object
    o.name = name
    if material: o.data.materials.append(material)
    return link(o, coll)

def torus(name, coll, major, minor, loc, rot=(0, 0, 0), scale=(1, 1, 1), material=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                     major_segments=96, minor_segments=12,
                                     location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = scale
    o.name = name
    if material: o.data.materials.append(material)
    return link(o, coll)

def sphere(name, coll, radius, loc, material=None):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=32, ring_count=16)
    o = bpy.context.active_object
    o.name = name
    if material: o.data.materials.append(material)
    return link(o, coll)

def text(name, coll, body, loc, rot, size, material):
    bpy.ops.object.text_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.data.body = body
    o.data.size = size
    o.data.align_x = 'CENTER'
    o.data.align_y = 'CENTER'
    o.data.extrude = 0.03
    o.data.bevel_depth = 0.008
    o.data.materials.append(material)
    return link(o, coll)

TILT = 0.82  # ~47 deg: discos/placas mirando a camara
NORMAL = (0, -math.sin(TILT), math.cos(TILT))

# ---------- MESA ----------
cyl("MesaMadera", "Mesa", 5.6, 0.55, (0, 0, -0.275), scale=(1, 0.59, 1), material=WOOD, verts=96)
cyl("Pano", "Mesa", 4.9, 0.08, (0, 0, 0.0), scale=(1, 0.56, 1), material=FELT, verts=96)
torus("FileteDoradoPano", "Mesa", 4.95, 0.05, (0, 0, 0.05), scale=(1, 0.56, 1), material=GOLD)
torus("FileteDoradoBorde", "Mesa", 5.55, 0.045, (0, 0, 0.01), scale=(1, 0.59, 1), material=GOLD)
cyl("Suelo", "Fondo", 30, 0.1, (0, 0, -0.50), material=FLOOR, verts=48)

# ---------- FONDO taberna calida desenfocada ----------
bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 10.5, 4.0), scale=(42, 15, 1))
o = bpy.context.active_object; o.name = "TelonTaberna"; o.data.materials.append(BACK); link(o, "Fondo")
# Lamparas BAJAS tras el borde lejano. Rayo superior real: camara a 46.5° bajo
# horizontal menos medio FOV vertical (18.9°) = 27.6°; a y=5 la caida es 7.9 m,
# asi que solo se ve z<=1.3. Lamparas a y=5, z 0.5-1.0: entran enteras en cuadro
# y el DOF f/4 las deja como bokeh calido (v3 las puso a z 0.9-1.8 en y=6 y
# salieron cortadas y quemadas arriba del cuadro).
for i, (x, z, r) in enumerate([(-5.0, 0.6, 0.7), (-2.5, 0.9, 0.5), (0, 1.0, 0.8), (2.5, 0.8, 0.5), (5.0, 0.6, 0.7), (-3.5, 0.5, 0.4), (3.5, 0.5, 0.4)]):
    sphere(f"Lampara{i}", "Fondo", r, (x, 5.0, z), material=LAMP)
# Sin siluetas de mesas de fondo: en el primer hero salian como cajas cortadas
# arriba del cuadro y distraian; el telon + lamparas bastan para la taberna.

# ---------- LOGO grabado al centro ----------
text("LogoCachoODudo", "Logo", "CACHO\nO DUDO", (0, 0.75, 0.06), (0, 0, 0), 0.72,
     bpy.data.materials.new("LogoGris") if False else mat("LogoGrabado", srgb(0.72, 0.69, 0.63), 0.7))
torus("AnilloLogo", "Logo", 1.85, 0.03, (0, 0.75, 0.05), scale=(1, 0.72, 1), material=GOLD)

# ---------- VASOS + posavasos ----------
import bmesh
def vaso(name, loc, scale_f):
    r_bot, r_top, h = 0.56 * scale_f, 0.40 * scale_f, 0.85 * scale_f
    cyl(f"Posavasos_{name}", "Vasos", 0.70 * scale_f, 0.07, (loc[0], loc[1], 0.075), material=DARK)
    # Tronco de cono real (boca ancha abajo, angosto arriba) + tapas, via bmesh.
    mesh = bpy.data.meshes.new(f"Vaso_{name}_mesh")
    bm = bmesh.new()
    seg = 48
    vb, vt = [], []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        vb.append(bm.verts.new((math.cos(a) * r_bot, math.sin(a) * r_bot, 0.0)))
        vt.append(bm.verts.new((math.cos(a) * r_top, math.sin(a) * r_top, h)))
    bm.verts.ensure_lookup_table()
    cb = bm.verts.new((0, 0, 0)); ct = bm.verts.new((0, 0, h))
    bm.faces.new(vb)  # tapa inferior (boca, apoyada en la mesa)
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((vb[i], vb[j], vt[j], vt[i]))
    bm.faces.new(vt)
    bm.to_mesh(mesh); bm.free()
    o = bpy.data.objects.new(f"Vaso_{name}", mesh)
    o.location = (loc[0], loc[1], 0.11)
    o.data.materials.append(LEATHER)
    bpy.context.scene.collection.objects.link(o)
    link(o, "Vasos")
    borde = torus(f"Borde_{name}", "Vasos", r_bot, 0.045 * scale_f, (loc[0], loc[1], 0.13), material=LEATHER)
    costura = torus(f"Costura_{name}", "Vasos", r_top + 0.02, 0.015 * scale_f, (loc[0], loc[1], 0.11 + h - 0.06), material=DARK)
    bpy.context.view_layer.update()
    for ch in (borde, costura):
        ch.parent = o
        ch.matrix_parent_inverse = o.matrix_world.inverted()
    return o

vaso("DonChalo", (-2.83, 2.21), 1.0)
vaso("LaPituca", (2.83, 2.21), 1.0)
vaso("ElGuaton", (-3.19, -0.26), 1.0)
vaso("LaCuca", (3.30, -0.26), 1.0)
vaso("ElHuaso", (0, 1.95), 1.0)
vaso_TU = vaso("TU", (0, -2.60), 1.25)

# ---------- DADOS ----------
PIPS = {
    1: [(0, 0)],
    2: [(-1, 1), (1, -1)],
    3: [(-1, 1), (0, 0), (1, -1)],
    4: [(-1, 1), (1, 1), (-1, -1), (1, -1)],
    5: [(-1, 1), (1, 1), (0, 0), (-1, -1), (1, -1)],
    6: [(-1, 1), (1, 1), (-1, 0), (1, 0), (-1, -1), (1, -1)],
}
# cara: (valor, eje, signo). +Z=1, -Z=6, +X=3, -X=4, +Y=2, -Y=5
FACES = [(1, 'Z', 1), (6, 'Z', -1), (3, 'X', 1), (4, 'X', -1), (2, 'Y', 1), (5, 'Y', -1)]

def dado(name, coll, size, loc, rot):
    half = size / 2.0
    bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, 0))
    body = bpy.context.active_object
    body.name = name
    body.data.materials.append(DICEW)
    bev = body.modifiers.new("Bisel", 'BEVEL')
    bev.width = size * 0.12; bev.segments = 2
    a = half * 0.52
    pr, ph = size * 0.16, size * 0.06
    for value, axis, sign in FACES:
        for (gx, gy) in PIPS[value]:
            px, py = gx * a, gy * a
            if axis == 'Z':
                ploc, prot = (px, py, sign * (half + 0.001)), (0, 0, 0)
            elif axis == 'X':
                ploc, prot = (sign * (half + 0.001), py, px), (0, math.pi / 2, 0)
            else:
                ploc, prot = (px, sign * (half + 0.001), py), (math.pi / 2, 0, 0)
            bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=pr, depth=ph,
                                                location=ploc, rotation=prot)
            p = bpy.context.active_object
            p.name = f"{name}_pip{value}_{gx}_{gy}"
            p.data.materials.append(PIPR if value == 1 else PIPB)
            p.parent = body
            link(p, coll)
    link(body, coll)
    body.location = loc
    body.rotation_euler = rot
    return body

# Mis dados ocultos bajo mi vaso (V1): invisibles en hero porque el vaso los cubre.
for i, (dx, dy, yaw) in enumerate([(-0.30, 0.20, 0.4), (0.30, 0.20, 1.1), (-0.30, -0.25, 2.0), (0.30, -0.25, 2.6), (0.0, 0.0, 0.9)]):
    dado(f"DadoMio_{i+1}", "Dados", 0.30, (dx, -2.60 + dy, 0.16), (0, 0, yaw))

# Dados de revelacion al centro (V2): ocultos en hero, visibles en render revelacion.
REVEL = []
tops = [(0, 0, 0.3), (math.pi / 2, 0, 1.2), (-math.pi / 2, 0, 2.1), (0, -math.pi / 2, 0.7), (math.pi, 0, 1.8)]
for i, ((dx, dy), rot) in enumerate(zip([(-0.85, 0.55), (0.0, 0.75), (0.85, 0.55), (-0.45, -0.15), (0.55, -0.15)], tops)):
    d = dado(f"DadoRevelado_{i+1}", "Dados", 0.34, (dx, 0.35 + dy, 0.18), rot)
    d.hide_render = True
    REVEL.append(d)
    for ch in d.children:
        ch.hide_render = True

# ---------- FICHAS + POZO ----------
CHIPCOLS = [mat(f"Ficha{i}", c, 0.5, 0.1) for i, c in enumerate([srgb(0.79, 0.63, 0.29), srgb(0.65, 0.10, 0.10), srgb(0.12, 0.12, 0.14)])]
for i in range(10):
    cyl(f"FichaPozo_{i}", "Fichas", 0.34, 0.07, (-1.40, 1.80, 0.11 + i * 0.072),
        material=CHIPCOLS[i % 3])
for i, (x, y) in enumerate([(-2.10, 1.45), (-1.45, 1.05), (-2.00, 1.00)]):
    cyl(f"FichaSuelta_{i}", "Fichas", 0.30, 0.07, (x, y, 0.075), material=CHIPCOLS[(i + 1) % 3])
# Pila superior (correccion 09:35): avatar superior-central, SU placa (la pone el
# bucle de JUGADORES en y=3.50), placa del POZO y vaso superior-central, en pila
# vertical. La placa de apuesta actual va a la derecha del POZO.
box("PlacaPozo", "Asientos", (0, 2.75, 0.70), (TILT, 0, 0), (1.9, 0.70, 0.08), material=PLATE)
text("TextoPozo", "Asientos", "POZO\n3.000", (0, 0, 0), (TILT, 0, 0), 0.34, TEXTG)
_tp = bpy.data.objects["TextoPozo"]
_tp.location = (0 + NORMAL[0] * 0.07, 2.75 + NORMAL[1] * 0.07, 0.70 + NORMAL[2] * 0.07)
# Placa de APUESTA ACTUAL junto al pozo (checklist 07:46 pto 3): apuesta de EJEMPLO,
# marcada como tal; NO es un dato vivo de partida (no hay partida en esta etapa).
box("PlacaApuesta", "Asientos", (1.70, 2.75, 0.70), (TILT, 0, 0), (2.0, 0.70, 0.08), material=PLATE)
text("TextoApuesta", "Asientos", "APUESTA ACTUAL\n5 Quintas\n(EJEMPLO)", (0, 0, 0), (TILT, 0, 0), 0.24, TEXTG)
_ta = bpy.data.objects["TextoApuesta"]
_ta.location = (1.70 + NORMAL[0] * 0.07, 2.75 + NORMAL[1] * 0.07, 0.70 + NORMAL[2] * 0.07)

# ---------- ASIENTOS ----------
JUGADORES = [
    ("ElHuaso", "HU", (0, 4.35), (0.80, 0.33, 0.10), (0.40, 0.18, 0.06)),
    ("DonChalo", "CH", (-4.70, 2.30), (0.75, 0.18, 0.18), (0.45, 0.16, 0.14)),
    ("LaPituca", "PI", (4.70, 2.30), (0.16, 0.50, 0.72), (0.13, 0.27, 0.36)),
    ("ElGuaton", "GU", (-5.15, -0.05), (0.56, 0.27, 0.68), (0.29, 0.16, 0.36)),
    ("LaCuca", "CU", (5.15, -0.05), (0.10, 0.74, 0.61), (0.12, 0.36, 0.30)),
    ("TU", "T\u00da", (0, -3.55), srgb(0.79, 0.63, 0.29), (0.42, 0.35, 0.14)),
]
for nombre, ini, (x, y), ring_col, inner_col in JUGADORES:
    z = 0.75
    cyl(f"Avatar_{nombre}", "Asientos", 0.52, 0.10, (x, y, z), rot=(TILT, 0, 0),
        material=mat(f"Anillo_{nombre}", ring_col, 0.5, 0.3))
    cyl(f"AvatarCentro_{nombre}", "Asientos", 0.42, 0.12, (x, y, z), rot=(TILT, 0, 0),
        material=mat(f"Centro_{nombre}", inner_col, 0.7))
    torus(f"Aro_{nombre}", "Asientos", 0.52, 0.06, (x, y, z), rot=(TILT, 0, 0),
          material=mat(f"AroMat_{nombre}", ring_col, 0.4, 0.5))
    text(f"Inicial_{nombre}", "Asientos", ini,
         (x + NORMAL[0] * 0.10, y + NORMAL[1] * 0.10, z + NORMAL[2] * 0.10),
         (TILT, 0, 0), 0.42, TEXTW)
    py = y - 0.85
    pz = 0.55
    box(f"Placa_{nombre}", "Asientos", (x, py, pz), (TILT, 0, 0), (1.5, 0.55, 0.08), material=PLATE)
    titulo = {"DonChalo": "Don Chalo", "LaPituca": "La Pituca", "ElGuaton": "El Guat\u00f3n",
              "LaCuca": "La Cuca", "ElHuaso": "El Huaso", "TU": "T\u00da"}[nombre]
    text(f"TextoPlaca_{nombre}", "Asientos", f"{titulo}\n5.000  NV 1",
         (x + NORMAL[0] * 0.07, py + NORMAL[1] * 0.07, pz + NORMAL[2] * 0.07),
         (TILT, 0, 0), 0.25, TEXTW)

# ---------- SLOT REACCIONES (C9 07:40: chat FUERA; el slot del mockup queda
# como reacciones/emotes, sin animacion en esta etapa) ----------
cyl("SlotReacciones", "Asientos", 0.35, 0.08, (-4.96, -3.23, 0.55), rot=(TILT, 0, 0), material=PLATE)
torus("AroReacciones", "Asientos", 0.35, 0.045, (-4.96, -3.23, 0.55), rot=(TILT, 0, 0), material=GOLD)
text("TextoReacciones", "Asientos", ":)",
     (-4.96 + NORMAL[0] * 0.08, -3.23 + NORMAL[1] * 0.08, 0.55 + NORMAL[2] * 0.08),
     (TILT, 0, 0), 0.30, TEXTG)

# ---------- LUCES ----------
def light(name, ltype, loc, energy, color, size=0):
    bpy.ops.object.light_add(type=ltype, location=loc)
    o = bpy.context.active_object; o.name = name
    o.data.energy = energy; o.data.color = color
    if ltype == 'AREA': o.data.size = size
    return o
light("Clave", 'AREA', (0, -5, 9), 1600, (1.0, 0.85, 0.62), size=5)
light("Relleno", 'POINT', (-7, -6, 4), 350, (1.0, 0.91, 0.78))
light("Contraluz", 'POINT', (0, 7, 5), 700, (1.0, 0.60, 0.24))

# ---------- CAMARAS ----------
bpy.ops.object.empty_add(location=(0, 0, 0.2)); foco = bpy.context.active_object; foco.name = "FocoMesa"
bpy.ops.object.camera_add(location=(0, -10.6, 9.55), rotation=(0.822, 0, 0))
cam = bpy.context.active_object; cam.name = "CamaraHero"; cam.data.lens = 35
cam.data.dof.use_dof = True; cam.data.dof.focus_object = foco; cam.data.dof.aperture_fstop = 4.0
scene.camera = cam
bpy.ops.object.camera_add(location=(0, -5.4, 3.4), rotation=(0.749, 0, 0))
cam2 = bpy.context.active_object; cam2.name = "CamaraDetalle"; cam2.data.lens = 50
cam2.data.dof.use_dof = True; cam2.data.dof.focus_object = foco; cam2.data.dof.aperture_fstop = 2.8

bpy.ops.wm.save_as_mainfile(filepath=BLEND)
print("BLEND_GUARDADO", BLEND)

def render(path, cam_obj):
    scene.camera = cam_obj
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("RENDER_OK", path)

# HERO: estado normal, vasos cerrados, sin dados al centro
render(os.path.join(REND, "mesa_hero.png"), cam)

# REVELACION y DETALLE ya NO se renderizan aqui (correccion 09:35: la revelacion
# vieja en pequeno es ilegible y quedo rechazada):
# - reveal_seq.py: secuencia legible en primer plano (dados grandes, sin solapes,
#   destacados uno a uno) -> renders/mesa_revelacion.png + renders/revelacion/.
# - detalle_fix.py: vaso de TU alzado a un lado, camara picada.
# Aqui solo hero + conteos + exportaciones, con los dados de revelacion ocultos.

# ---------- conteo de poligonos (malla evaluada) ----------
deps = bpy.context.evaluated_depsgraph_get()
tot = {}
for coll_name, coll in COLLS.items():
    n = 0
    for o in coll.objects:
        if o.type == 'MESH':
            try:
                n += len(o.evaluated_get(deps).data.polygons)
            except Exception:
                n += len(o.data.polygons)
    tot[coll_name] = n
print("POLIGONOS", tot, "TOTAL", sum(tot.values()))

# ---------- textos a malla + exportaciones ----------
bpy.ops.object.select_all(action='DESELECT')
for o in list(bpy.data.objects):
    if o.type == 'FONT':
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.convert(target='MESH')
        o.select_set(False)
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
print("BLEND_FINAL", BLEND)
bpy.ops.export_scene.gltf(filepath=os.path.join(BASE, "blender/mesa_cacho.glb"),
                          export_format='GLB', export_apply=True, export_yup=True)
print("GLB_OK")
try:
    bpy.ops.export_scene.fbx(filepath=os.path.join(BASE, "blender/mesa_cacho.fbx"),
                             apply_unit_scale=True, bake_space_transform=False)
    print("FBX_OK")
except Exception as e:
    print("FBX_FALLO", e)
print("FIN")
