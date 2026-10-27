# RONDA 2 — corrección Unity/Blender contra el ejemplo (93daf9d6…).
# Trabaja SOLO sobre la copia blender/mesa_cacho_ronda2.blend (el blend y los
# renders vigentes de la etapa 1 NO se tocan). Estado final guardado = estado
# HERO (pantalla completa); revelación y Paso se activan solo en memoria en
# sus scripts de render (sin guardar).
# Geometría HUD: barra + consola + banners son MALLAS/TEXTOS de la escena
# emparentados a la cámara (nunca una imagen 2D pegada en post). Sus
# materiales son emisivos suaves para que lean como UI de pantalla.
import bpy, math, os
from mathutils import Vector

BASE = "/home/hatch/workspace/cacho-unity"
SRC = os.path.join(BASE, "blender/mesa_cacho_ronda2.blend")
bpy.ops.wm.open_mainfile(filepath=SRC)
scene = bpy.context.scene
TILT = 0.82
PY = (0, math.cos(TILT), math.sin(TILT))   # eje local Y de un plano inclinado
NO = (0, -math.sin(TILT), math.cos(TILT))  # normal del plano inclinado

def srgb(r, g, b):
    def cv(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (cv(r), cv(g), cv(b), 1.0)

def set_principled(mat, base=None, rough=None, metal=None, emis=None, emis_strength=None):
    bsdf = None
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            bsdf = n; break
    if bsdf is None: return
    if base is not None: bsdf.inputs['Base Color'].default_value = base
    if rough is not None: bsdf.inputs['Roughness'].default_value = rough
    if metal is not None: bsdf.inputs['Metallic'].default_value = metal
    if emis is not None and 'Emission Color' in bsdf.inputs:
        bsdf.inputs['Emission Color'].default_value = emis
    if emis_strength is not None and 'Emission Strength' in bsdf.inputs:
        bsdf.inputs['Emission Strength'].default_value = emis_strength

def new_mat(name, base, rough=0.9, metal=0.0, emis=None, emis_strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    set_principled(m, base=base, rough=rough, metal=metal, emis=emis, emis_strength=emis_strength)
    return m

def assign(obj, mat):
    if obj.data and hasattr(obj.data, 'materials'):
        if len(obj.data.materials) == 0: obj.data.materials.append(mat)
        else: obj.data.materials[0] = mat

# ---------- materiales nuevos ----------
MAT_AGUA  = new_mat("R2_MarcaAgua", srgb(0.32, 0.29, 0.29), rough=1.0)
MAT_HUD   = new_mat("R2_HudOscuro", srgb(0.09, 0.08, 0.07), rough=0.9,
                    emis=srgb(0.09, 0.08, 0.07), emis_strength=0.55)
MAT_HUDB  = new_mat("R2_HudBoton", srgb(0.13, 0.12, 0.11), rough=0.9,
                    emis=srgb(0.13, 0.12, 0.11), emis_strength=0.55)
MAT_CALZO = new_mat("R2_Calzo", srgb(0.055, 0.478, 0.310), rough=0.7,
                    emis=srgb(0.055, 0.478, 0.310), emis_strength=0.5)
MAT_DUDO  = new_mat("R2_Dudo", srgb(0.702, 0.125, 0.165), rough=0.7,
                    emis=srgb(0.702, 0.125, 0.165), emis_strength=0.5)
MAT_PASO  = new_mat("R2_Paso", srgb(0.078, 0.345, 0.420), rough=0.7,
                    emis=srgb(0.078, 0.345, 0.420), emis_strength=0.5)
MAT_ORO   = new_mat("R2_OroMate", srgb(0.788, 0.635, 0.294), rough=0.75, metal=0.25,
                    emis=srgb(0.788, 0.635, 0.294), emis_strength=0.15)
MAT_TXT   = new_mat("R2_TextoBlanco", srgb(0.97, 0.96, 0.93), rough=0.6,
                    emis=srgb(0.97, 0.96, 0.93), emis_strength=0.7)
MAT_TXTG  = new_mat("R2_TextoOro", srgb(0.788, 0.635, 0.294), rough=0.6,
                    emis=srgb(0.788, 0.635, 0.294), emis_strength=0.7)
MAT_PIPA  = new_mat("R2_PipaNegra", (0.01, 0.01, 0.01, 1.0), rough=0.6)
MAT_DADO  = new_mat("R2_DadoBlanco", srgb(0.96, 0.96, 0.94), rough=0.35)
MAT_VERDE = new_mat("R2_PuntoVerde", srgb(0.13, 0.85, 0.30), rough=0.5,
                    emis=srgb(0.13, 0.85, 0.30), emis_strength=1.2)
MAT_GRIS  = new_mat("R2_GrisNeutro", srgb(0.45, 0.45, 0.47), rough=0.85)
MAT_BANNER= new_mat("R2_Banner", srgb(0.10, 0.09, 0.08), rough=0.9,
                    emis=srgb(0.10, 0.09, 0.08), emis_strength=0.55)

# ---------- U2: paño, dorado, fondo ----------
pano = bpy.data.materials.get("PanoCarbon")
if pano: set_principled(pano, base=srgb(0.114, 0.090, 0.090), rough=1.0, metal=0.0)
dor = bpy.data.materials.get("DoradoMate")
if dor: set_principled(dor, base=srgb(0.788, 0.635, 0.294), rough=0.75, metal=0.25)
lamp = bpy.data.materials.get("LamparaCalida")
if lamp: set_principled(lamp, base=srgb(1.0, 0.50, 0.20), rough=0.5,
                        emis=srgb(1.0, 0.50, 0.20), emis_strength=2.2)
w = bpy.data.worlds['World']
if 'Background' in w.node_tree.nodes:
    w.node_tree.nodes['Background'].inputs['Color'].default_value = (0.008, 0.006, 0.005, 1.0)

# ---------- ocultar: fichas, doble filete, slot reacciones viejo, dados viejos ----------
for o in list(bpy.data.objects):
    if o.name.startswith(("FichaPozo_", "FichaSuelta_")):
        o.hide_render = True
    if o.name in ("FileteDoradoPano", "SlotReacciones", "TextoReacciones",
                  "AroReacciones", "TextoApuesta"):
        o.hide_render = True
    if o.name.startswith(("DadoMio_", "DadoRevelado_", "DiscoCuenta")):
        o.hide_render = True
    if o.name.startswith("DadoRevelado_") or "_pip" in o.name:
        o.hide_render = True

# ---------- U3: placas solapando borde inferior del avatar ----------
# Discos sin cambio de escala (la cámara casi cenital ya los iguala ~6%);
# placas centradas bajo cada disco con solape vertical ~0.12 mundo.
SEATS = {  # nombre: (disco_x, disco_y, placa_x, placa_y, nombre_placa, dados)
    "ElHuaso":   (0.0, 4.85, 0.0, 4.18, "El Huaso", 5),
    "DonChalo":  (-4.7, 2.3, -5.0, 1.63, "Don Chalo", 5),
    "LaPituca":  (4.7, 2.3, 5.0, 1.63, "La Pituca", 5),
    "ElGuaton":  (-5.15, -0.55, -5.35, -1.22, "El Guatón", 5),
    "LaCuca":    (5.15, -0.55, 5.35, -1.22, "La Cuca", 5),
    "TU":        (0.0, -3.70, 0.0, -4.37, "TÚ", 5),
}
FONT = bpy.data.fonts.load("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")
FONTB = bpy.data.fonts.load("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf")

def move(name, loc):
    o = bpy.data.objects.get(name)
    if o: o.location = loc
    else: print("FALTA", name)

def flat_text(name, body, loc, rot, size, mat, font=FONT, align_x='CENTER'):
    bpy.ops.object.text_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.data.body = body
    o.data.font = font
    o.data.size = size
    o.data.align_x = align_x
    o.data.align_y = 'CENTER'
    o.data.extrude = 0.0
    o.data.bevel_depth = 0.0
    o.data.materials.append(mat)
    return o

for key, (dx, dy, px, py, nombre, nd) in SEATS.items():
    for prefix in ("Avatar_", "AvatarCentro_", "Aro_"):
        move(prefix + key, (dx, dy, 0.75))
    ini = bpy.data.objects.get("Inicial_" + key)
    if ini:
        ox = ini.location.x - {"ElHuaso": 0.0, "DonChalo": -4.7, "LaPituca": 4.7,
                               "ElGuaton": -5.15, "LaCuca": 5.15, "TU": 0.0}[key]
        oy = ini.location.y - {"ElHuaso": 4.85, "DonChalo": 2.3, "LaPituca": 2.3,
                               "ElGuaton": -0.55, "LaCuca": -0.55, "TU": -3.70}[key]
        ini.location = (dx + ox, dy + oy, 0.82)
    move("Placa_" + key, (px, py, 0.55))
    old = bpy.data.objects.get("TextoPlaca_" + key)
    if old: old.hide_render = True
    # texto nuevo: nombre + ×N real (todos parten con 5), tipografía recta sin bisel
    flat_text("R2_TextoPlaca_" + key, f"{nombre}\n×{nd}",
              (px + NO[0] * 0.075, py + NO[1] * 0.075, 0.55 + NO[2] * 0.075),
              (TILT, 0, 0), 0.24, MAT_TXT)
    # punto verde en el borde inferior-derecho del disco (U3)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.09,
        location=(dx + 0.38, dy - 0.256, 0.75 - 0.171))
    dot = bpy.context.active_object
    dot.name = "R2_PuntoVerde_" + key
    dot.data.materials.append(MAT_VERDE)

# Aro de TÚ en estado neutro (U10): gris, sin color de semáforo
aro_tu = bpy.data.objects.get("Aro_TU")
if aro_tu: assign(aro_tu, MAT_GRIS)

# ---------- U3: placa superior = SOLO Pozo ----------
pozo = bpy.data.objects["PlacaPozo"]
pozo.location = (0.0, 2.05, 0.55)
pozo.scale.x = 3.4 / 1.9
old_pozo = bpy.data.objects.get("TextoPozo")
if old_pozo: old_pozo.hide_render = True
flat_text("R2_TextoPozo", "POZO\n3.000",
          (0.0 + NO[0] * 0.075, 2.05 + NO[1] * 0.075, 0.55 + NO[2] * 0.075),
          (TILT, 0, 0), 0.32, MAT_TXT)

# ---------- U2: logo marca de agua plana, 2 líneas, inclinado, óvalo fino abierto ----------
logo = bpy.data.objects["LogoCachoODudo"]
logo.location = (0.0, -0.8, 0.045)
logo.rotation_euler = (0, 0, 0.23)
logo.scale = (0.75, 0.75, 0.15)
assign(logo, MAT_AGUA)
anillo = bpy.data.objects.get("AnilloLogo")
if anillo: anillo.hide_render = True
bpy.ops.curve.primitive_bezier_circle_add(location=(0.0, -0.8, 0.05), rotation=(0, 0, 0.23))
oval = bpy.context.active_object
oval.name = "R2_OvaloLogo"
oval.scale = (1.45, 0.95, 1.0)
oval.data.bevel_depth = 0.02
oval.data.bevel_resolution = 2
oval.data.splines[0].use_cyclic_u = False  # óvalo ABIERTO
oval.data.materials.append(MAT_AGUA)

# ---------- U4: vasos SOBRE el anillo junto a su avatar (los hijos siguen al padre) ----------
CUPS = {
    "DonChalo": (-3.5, 2.3), "LaPituca": (3.5, 2.3),
    "ElGuaton": (-5.2, 0.15), "LaCuca": (5.2, 0.15),
    "ElHuaso": (0.0, 2.95), "TU": (0.0, -2.5),
}
for key, (cx, cy) in CUPS.items():
    v = bpy.data.objects.get("Vaso_" + key)
    if v:
        before = {c.name: tuple(round(x, 3) for x in c.matrix_world.translation)
                  for c in v.children}
        v.location = (cx, cy, 0.11)
        bpy.context.view_layer.update()
        after = {c.name: tuple(round(x, 3) for x in c.matrix_world.translation)
                 for c in v.children}
        print("VASO", key, "hijos_antes", before, "hijos_despues", after)
    move("Posavasos_" + key, (cx, cy, 0.075))

# ---------- U5: cámara casi cenital + DOF off (el HUD va pegado a cámara) ----------
cam = bpy.data.objects["CamaraHero"]
cam.location = (0.0, -5.2, 13.2)
cam.rotation_euler = (0.38, 0, 0)
cam.data.lens = 40
cam.data.dof.use_dof = False
scene.camera = cam

# ---------- colección ronda 2 ----------
coll = bpy.data.collections.new("Ronda2")
scene.collection.children.link(coll)
def link(obj):
    for c in list(obj.users_collection):
        if c.name != "Ronda2":
            try: c.objects.unlink(obj)
            except Exception: pass
    if obj.name not in coll.objects: coll.objects.link(obj)

# ---------- U9/U1: HUD como geometría emparentada a cámara ----------
def hud_box(name, lx, ly, sx, sy, mat):
    bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0))
    o = bpy.context.active_object
    o.name = name
    o.parent = cam
    o.location = (lx, ly, -2.2)
    o.rotation_euler = (0, 0, 0)
    o.scale = (sx, sy, 0.01)
    o.data.materials.append(mat)
    link(o)
    return o

def hud_cyl(name, lx, ly, r, mat, z=-2.18):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r, depth=0.02, location=(0, 0, 0))
    o = bpy.context.active_object
    o.name = name
    o.parent = cam
    o.location = (lx, ly, z)
    o.rotation_euler = (0, 0, 0)
    o.data.materials.append(mat)
    link(o)
    return o

def hud_text(name, body, lx, ly, size, mat, font=FONT, align_x='CENTER', z=-2.17):
    bpy.ops.object.text_add(location=(0, 0, 0))
    o = bpy.context.active_object
    o.name = name
    o.parent = cam
    o.location = (lx, ly, z)
    o.rotation_euler = (0, 0, 0)
    o.data.body = body
    o.data.font = font
    o.data.size = size
    o.data.align_x = align_x
    o.data.align_y = 'CENTER'
    o.data.extrude = 0.0
    o.data.bevel_depth = 0.0
    o.data.materials.append(mat)
    link(o)
    return o

# Barra superior: saldo real de paridad, MIC, MÚSICA, ajustes, menú.
# NO segunda moneda $0, NO "+" de compra, NO regalo/misiones/amigos.
hud_box("R2_Barra", 0, 0.86, 1.71, 0.12, MAT_HUD)
hud_cyl("R2_ChipSaldo", -1.55, 0.86, 0.07, MAT_ORO)
hud_text("R2_Saldo", "5.000", -1.42, 0.86, 0.11, MAT_TXT, font=FONTB, align_x='LEFT')
hud_text("R2_Mic", "MIC", -0.35, 0.86, 0.08, MAT_TXT)
hud_text("R2_Musica", "MÚSICA", 0.30, 0.86, 0.08, MAT_TXT)
hud_cyl("R2_Ajustes", 1.20, 0.86, 0.07, MAT_HUDB)
for i, yy in enumerate((0.91, 0.86, 0.81)):
    hud_box(f"R2_Menu{i}", 1.52, yy, 0.08, 0.01, MAT_TXT)

# Consola inferior: emotes + APOSTAR 1–6 + CALZO + DUDO + PASO
hud_box("R2_Consola", 0, -0.79, 1.71, 0.19, MAT_HUD)
hud_cyl("R2_Emotes", -1.58, -0.79, 0.09, MAT_HUDB)
hud_text("R2_EmotesTxt", ":)", -1.58, -0.79, 0.09, MAT_TXT)
hud_text("R2_ApostarLbl", "APOSTAR", -1.38, -0.66, 0.07, MAT_TXTG, font=FONTB, align_x='LEFT')
PIP_LAYOUT = {1: [(0, 0)], 2: [(-.045, .045), (.045, -.045)],
              3: [(-.045, .045), (0, 0), (.045, -.045)],
              4: [(-.045, .045), (.045, .045), (-.045, -.045), (.045, -.045)],
              5: [(-.045, .045), (.045, .045), (0, 0), (-.045, -.045), (.045, -.045)],
              6: [(-.045, .045), (.045, .045), (-.045, 0), (.045, 0), (-.045, -.045), (.045, -.045)]}
for i in range(6):
    tx = -1.30 + i * 0.21
    hud_box(f"R2_Tile{i+1}", tx, -0.83, 0.09, 0.12, MAT_HUDB)
    for (px, py) in PIP_LAYOUT[i + 1]:
        hud_cyl(f"R2_Tile{i+1}_pip", tx + px, -0.77 + py, 0.02, MAT_TXT)
    hud_text(f"R2_Tile{i+1}_num", str(i + 1), tx, -0.90, 0.055, MAT_TXT)
hud_box("R2_BtnCalzo", 0.10, -0.83, 0.26, 0.12, MAT_CALZO)
hud_text("R2_BtnCalzoTxt", "CALZO", 0.10, -0.83, 0.08, MAT_TXT, font=FONTB)
hud_box("R2_BtnDudo", 0.70, -0.83, 0.26, 0.12, MAT_DUDO)
hud_text("R2_BtnDudoTxt", "DUDO", 0.70, -0.83, 0.08, MAT_TXT, font=FONTB)
hud_box("R2_BtnPaso", 1.28, -0.83, 0.24, 0.12, MAT_PASO)
hud_text("R2_BtnPasoTxt", "PASO", 1.28, -0.83, 0.08, MAT_TXT, font=FONTB)

# Banners de veredicto (solo se muestran en su render; no se guardan visibles)
hud_box("R2_BannerRev", 0, 0.60, 1.30, 0.10, MAT_BANNER)
hud_text("R2_BannerRevTxt", "DUDO FALLA · 10 / 5 Quintas", 0, 0.60, 0.10, MAT_TXT, font=FONTB)
hud_box("R2_BannerPaso", 0, 0.60, 1.30, 0.10, MAT_BANNER)
hud_text("R2_BannerPasoTxt", "PASO · EL GUATÓN · 5 DISTINTOS", 0, 0.60, 0.10, MAT_TXT, font=FONTB)
for n in ("R2_BannerRev", "R2_BannerRevTxt", "R2_BannerPaso", "R2_BannerPasoTxt"):
    bpy.data.objects[n].hide_render = True

# ---------- U6: dados nuevos, pipas negras PLANAS, solo cara superior ----------
def die(name, cx, cy, value, rz, size=0.85):
    bpy.ops.mesh.primitive_cube_add(location=(cx, cy, size / 2 + 0.02))
    d = bpy.context.active_object
    d.name = name
    d.scale = (size / 2, size / 2, size / 2)
    d.rotation_euler = (0, 0, rz)
    d.data.materials.append(MAT_DADO)
    link(d)
    c, s = math.cos(rz), math.sin(rz)
    for (ox, oy) in PIP_LAYOUT[value]:
        rx = ox * c - oy * s
        ry = ox * s + oy * c
        bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.11, depth=0.02,
                                            location=(cx + rx, cy + ry, size + 0.02))
        p = bpy.context.active_object
        p.name = name + "_pip"
        p.rotation_euler = (0, 0, rz)
        p.data.materials.append(MAT_PIPA)
        link(p)
    return d

def gold_ring(name, cx, cy):
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.52, depth=0.02,
                                        location=(cx, cy, 0.015))
    g = bpy.context.active_object
    g.name = name
    g.data.materials.append(MAT_ORO)
    link(g)
    return g

# Revelación: 6 manos en 2 columnas × 3 filas; centro libre para logo y pozo.
HANDS = [  # (etiqueta, x, y, mano, subtotal)
    ("HU", -3.25, 1.62, [5, 1, 5, 3, 2], 3),
    ("PI", 3.25, 1.62, [3, 3, 5, 2, 4], 1),
    ("CH", -3.25, -0.20, [5, 2, 4, 6, 1], 2),
    ("CU", 3.25, -0.20, [4, 4, 2, 6, 6], 0),
    ("GU", -3.25, -2.02, [1, 6, 6, 2, 3], 1),
    ("TÚ", 3.25, -2.02, [5, 5, 1, 3, 4], 3),
]
OFFS = [(-0.95, 0.55), (0, 0.55), (0.95, 0.55), (-0.48, -0.55), (0.48, -0.55)]
for (et, gx, gy, hand, sub) in HANDS:
    flat_text(f"R2_Etiq_{et}", f"{et} · {sub}", (gx, gy + 1.18, 0.05),
              (0, 0, 0), 0.20, MAT_TXT)
    for i, v in enumerate(hand):
        ox, oy = OFFS[i]
        rz = ((i * 7 + len(et)) % 10 - 5) * 0.06
        die(f"R2_Dado_{et}_{i+1}", gx + ox, gy + oy, v, rz)
        if v in (5, 1):  # cuentan para 5 Quintas (5 reales + 1 comodín)
            gold_ring(f"R2_Anillo_{et}_{i+1}", gx + ox, gy + oy)
    for n in list(bpy.data.objects):
        if n.name.startswith(f"R2_Dado_{et}_") or n.name.startswith(f"R2_Anillo_{et}_") \
           or n.name == f"R2_Etiq_{et}":
            n.hide_render = True

# Paso: solo la mano del jugador del Paso (El Guatón, 5 distintos)
for i, v in enumerate([1, 2, 3, 4, 6]):
    die(f"R2_PasoDado_{i+1}", -2.2 + i * 1.1, -0.2, v, (i % 3 - 1) * 0.15)
for n in list(bpy.data.objects):
    if n.name.startswith("R2_PasoDado_"):
        n.hide_render = True

# ---------- render: ajustes + preview ----------
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.use_denoising = True
scene.cycles.samples = 64
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
bpy.ops.wm.save_mainfile()
print("PARCHE_RONDA2_OK")
