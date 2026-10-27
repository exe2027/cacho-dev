# RONDA 3 — corrección Unity/Blender contra el ejemplo (U3a–U3n).
# Trabaja SOLO sobre blender/mesa_cacho_ronda3.blend (copia de ronda 2;
# ronda 2 y etapa 1 NO se tocan). Estado guardado = hero (pantalla completa).
import bpy, math, os
BASE = "/home/hatch/workspace/cacho-unity"
SRC = os.path.join(BASE, "blender/mesa_cacho_ronda3.blend")
bpy.ops.wm.open_mainfile(filepath=SRC)
scene = bpy.context.scene
cam = bpy.data.objects["CamaraHero"]
FONTB = bpy.data.fonts.load("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf")
FONT = bpy.data.fonts.load("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")

def srgb(r, g, b):
    def cv(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (cv(r), cv(g), cv(b), 1.0)

def set_principled(mat, base=None, rough=None, metal=None, emis=None, emis_strength=None):
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            if base is not None: n.inputs['Base Color'].default_value = base
            if rough is not None: n.inputs['Roughness'].default_value = rough
            if metal is not None: n.inputs['Metallic'].default_value = metal
            if emis is not None and 'Emission Color' in n.inputs:
                n.inputs['Emission Color'].default_value = emis
            if emis_strength is not None and 'Emission Strength' in n.inputs:
                n.inputs['Emission Strength'].default_value = emis_strength
            return

def move(name, loc):
    o = bpy.data.objects.get(name)
    if o: o.location = loc
    else: print("FALTA", name)
    return o

def delete(name):
    o = bpy.data.objects.get(name)
    if o:
        bpy.data.objects.remove(o, do_unlink=True); print("BORRADO", name)
    else: print("FALTA-BORRAR", name)

def new_mat(name, base, rough=0.9, metal=0.0, emis=None, emis_strength=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    set_principled(m, base=base, rough=rough, metal=metal, emis=emis, emis_strength=emis_strength)
    return m

MAT_TXT = bpy.data.materials.get("R2_TextoBlanco")
MAT_AGUA = bpy.data.materials.get("R2_MarcaAgua")
MAT_HUDB = bpy.data.materials.get("R2_HudBoton")
MAT_NEGRO = new_mat("R3_TextoNegro", srgb(0.02, 0.02, 0.02), rough=0.9)
MAT_TILE = new_mat("R3_TileBlanco", srgb(0.93, 0.93, 0.90), rough=0.4,
                   emis=srgb(0.93, 0.93, 0.90), emis_strength=0.35)

# ---------- U3a: fuera la hamburguesa (sin destino, cerca P6) ----------
for n in ("R2_Menu0", "R2_Menu1", "R2_Menu2"):
    delete(n)
# ---------- U3i: fuera el filete superviviente ----------
delete("FileteDoradoBorde")

# ---------- U3n: cámara oblicua E (la cenital G entierra la placa TÚ bajo la consola) ----------
cam.location = (0.0, -13.0, 9.0)
cam.rotation_euler = (math.atan2(13.0, 9.0), 0.0, 0.0)  # 0.965 rad
print("CAMARA", tuple(cam.location), tuple(round(v, 4) for v in cam.rotation_euler))

# ---------- U3b: LUZ abajo (~0.35x) + dorado con emisión estable ----------
for name, energy, col in (("Clave", 550.0, (1.0, 0.93, 0.85)),
                          ("Contraluz", 250.0, None),
                          ("Relleno", 120.0, None)):
    L = bpy.data.objects.get(name)
    if L:
        L.data.energy = energy
        if col: L.data.color = col
oro = bpy.data.materials.get("R2_OroMate")
if oro: set_principled(oro, emis_strength=0.45)
dor = bpy.data.materials.get("DoradoMate")
if dor: set_principled(dor, rough=0.85, emis=srgb(0.788, 0.635, 0.294), emis_strength=0.30)

# ---------- U3c: logo al norte + vaso TÚ al sur y sin agrandar ----------
logo = bpy.data.objects["LogoCachoODudo"]
logo.location = (0.0, 0.70, 0.045); logo.scale = (0.50, 0.50, 0.15)
oval = bpy.data.objects["R2_OvaloLogo"]
oval.location = (0.0, 0.70, 0.05); oval.scale = (0.92, 0.60, 1.0)
move("Vaso_TU", (0.0, -2.80, 0.11))
vtu = bpy.data.objects["Vaso_TU"]
move("Posavasos_TU", (0.0, -2.80, 0.075))
# ---------- U3m: pinceladas bajo "DUDO" (geometría, material marca de agua) ----------
ang = 0.23; dx, dy = math.cos(ang), math.sin(ang)
for i, (ln, off, var) in enumerate(((0.85, -0.41, 0.02), (0.55, -0.50, -0.02), (0.35, -0.59, 0.01))):
    cx = 0.0 + (-off) * math.sin(ang)  # centro: logo + R(ang)*(0, off) con off negativo
    cy = 0.70 + off * math.cos(ang)
    # R(ang)*(0,off) = (-off*sin, off*cos); off es negativo -> x positivo
    cx = -off * math.sin(ang); cy = 0.70 + off * math.cos(ang)
    bpy.ops.mesh.primitive_cube_add(location=(cx, cy, 0.055), rotation=(0, 0, ang + var))
    o = bpy.context.active_object; o.name = f"R3_Pincelada_{i+1}"
    o.scale = (ln / 2.0, 0.0225, 0.005)
    o.data.materials.append(MAT_AGUA)
    print("PINCELADA", o.name, round(cx, 3), round(cy, 3), ln)

# ---------- U3d: vaso de El Huaso junto a su avatar ----------
move("Vaso_ElHuaso", (-1.55, 3.45, 0.11))
move("Posavasos_ElHuaso", (-1.55, 3.45, 0.075))
# ---------- U3h: separación placa HU / placa POZO ----------
move("Placa_ElHuaso", (0.0, 3.20, 0.55))
move("R2_TextoPlaca_ElHuaso", (0.0, 3.145, 0.601))
move("PlacaPozo", (0.0, 1.70, 0.55))
move("R2_TextoPozo", (0.0, 1.645, 0.601))
# ---------- U3h: disco TÚ uniforme (0.85 -> 0.73; la perspectiva lo agrandaba ~17%) ----------
for n in ("Avatar_TU", "Aro_TU", "AvatarCentro_TU", "Inicial_TU", "R2_PuntoVerde_TU"):
    o = bpy.data.objects.get(n)
    if o: o.scale = (0.73, 0.73, o.scale.z)
move("R2_PuntoVerde_TU", (0.275, -3.489, 0.605))

# ---------- U3g: placas y pozo más grandes (medir en render) ----------
for n in ("Placa_DonChalo", "Placa_ElGuaton", "Placa_ElHuaso", "Placa_LaCuca",
          "Placa_LaPituca", "Placa_TU"):
    o = bpy.data.objects.get(n)
    if o: o.scale.x = 1.15
for o in bpy.data.objects:
    if o.type == 'FONT' and o.name.startswith("R2_TextoPlaca_"):
        o.data.size = 0.28
bpy.data.objects["R2_TextoPozo"].data.size = 0.36

# ---------- U3e: apuesta actual DE VUELTA en juego normal (placa de mesa, solo hero/pantalla) ----------
pozo = bpy.data.objects["PlacaPozo"]
ap = pozo.copy(); ap.data = pozo.data.copy(); ap.name = "R3_PlacaApuesta"
ap.location = (-2.90, 0.30, 0.55); ap.scale = (1.7, 1.0, 1.0)
scene.collection.objects.link(ap)
tp = bpy.data.objects["R2_TextoPozo"]
at = tp.copy(); at.data = tp.data.copy(); at.name = "R3_TextoApuesta"
at.location = (-2.90, 0.245, 0.601); at.data.body = "APUESTA ACTUAL\n5 QUINTAS · DON CHALO"
at.data.size = 0.30
scene.collection.objects.link(at)
# ---------- U3e+U3g: veredicto con pinta + autor, doble tamaño ----------
tv = bpy.data.objects["R2_TablaVeredicto"]
tv.scale = (2.6, 0.34, 0.015)
tvt = bpy.data.objects["R2_TablaVeredictoTxt"]
tvt.data.body = "DUDO FALLA · 10/5 QUINTAS\nDON CHALO"; tvt.data.size = 0.44

# ---------- U3f/U3g/U3l: consola nueva ----------
CY = -0.7345
cons = bpy.data.objects["R2_Consola"]
cons.location = (0.0, CY, -3.0); cons.scale = (1.71, 0.2155, 0.01)
move("R2_Emotes", (-1.58, CY, -2.98)); move("R2_EmotesTxt", (-1.58, CY, -2.96))
lbl = bpy.data.objects["R2_ApostarLbl"]
lbl.location = (-1.16, -0.565, -2.96); lbl.data.size = 0.11
# VER (U3l): píldora en consola entre emotes y tiles
bpy.ops.mesh.primitive_cube_add(location=(-1.36, CY, -3.0))
o = bpy.context.active_object; o.name = "R3_VerBtn"; o.parent = cam
o.scale = (0.11, 0.1645, 0.01); o.data.materials.append(MAT_HUDB)
bpy.ops.object.text_add(location=(-1.36, CY, -2.96))
o = bpy.context.active_object; o.name = "R3_VerTxt"; o.parent = cam
o.data.body = "VER"; o.data.font = FONTB; o.data.size = 0.11
o.data.align_x = 'CENTER'; o.data.align_y = 'CENTER'
o.data.extrude = 0.0; o.data.bevel_depth = 0.0; o.data.materials.append(MAT_TXT)
# tiles blancos (U3f) + números ≥14 px equiv (U3g)
for i in range(6):
    tx_new = -1.14 + i * 0.21; tx_old = -1.30 + i * 0.21
    tb = bpy.data.objects.get(f"R2_Tile{i+1}")
    if tb:
        tb.location = (tx_new, -0.745, tb.location.z); tb.scale = (0.10, 0.14, 0.01)
        tb.data.materials.clear(); tb.data.materials.append(MAT_TILE)
    num = bpy.data.objects.get(f"R2_Tile{i+1}_num")
    if num:
        num.location = (tx_new, -0.83, num.location.z); num.data.size = 0.14
        num.data.materials.clear(); num.data.materials.append(MAT_NEGRO)
for o in list(bpy.data.objects):
    if o.name.startswith("R2_Tile") and "_pip" in o.name:
        try: idx = int(o.name.split("_")[1][4:])
        except Exception: continue
        tx_old = -1.30 + (idx - 1) * 0.21; tx_new = -1.14 + (idx - 1) * 0.21
        px = o.location.x - tx_old
        o.location = (tx_new + px * 1.111, o.location.y + 0.085, o.location.z)
        o.scale = (1.15, 1.15, 1.0)
        o.data.materials.clear(); o.data.materials.append(MAT_NEGRO)
# botones 17,3%H + iconos (U3f)
for btn, txt, bx in (("R2_BtnCalzo", "R2_BtnCalzoTxt", 0.33),
                     ("R2_BtnDudo", "R2_BtnDudoTxt", 0.89),
                     ("R2_BtnPaso", "R2_BtnPasoTxt", 1.41)):
    b = bpy.data.objects[btn]; b.location = (bx, CY, b.location.z); b.scale = (0.25, 0.1645, 0.01)
    t = bpy.data.objects[txt]
    t.location = (bx + (0.03 if btn != "R2_BtnPaso" else 0.03), CY, t.location.z)
# icono dado en CALZO/DUDO, ‖ en PASO (geometría blanca + pipa negra)
def hud_cube(name, x, y, z, sx, sy, mat):
    bpy.ops.mesh.primitive_cube_add(location=(x, y, z))
    o = bpy.context.active_object; o.name = name; o.parent = cam
    o.scale = (sx, sy, 0.01); o.data.materials.append(mat); return o
for btn, dx in (("Calzo", 0.12), ("Dudo", 0.68)):
    hud_cube(f"R3_IconoDado_{btn}", dx, CY, -2.98, 0.035, 0.035, MAT_TXT)
    hud_cube(f"R3_IconoDadoPip_{btn}", dx, CY, -2.96, 0.012, 0.012, MAT_NEGRO)
hud_cube("R3_PasoBarra_1", 1.20, CY, -2.98, 0.008, 0.075, MAT_TXT)
hud_cube("R3_PasoBarra_2", 1.25, CY, -2.98, 0.008, 0.075, MAT_TXT)

# ---------- U3j: fondo taberna propio (plano de fondo con imagen, nunca arte copiado) ----------
bpy.ops.mesh.primitive_plane_add(location=(0.0, 9.5, 3.2), rotation=(math.pi / 2, 0, 0))
tel = bpy.context.active_object; tel.name = "R3_TelonFoto"; tel.scale = (15.0, 4.0, 1.0)
matf = bpy.data.materials.new("R3_FondoFoto"); matf.use_nodes = True
nt = matf.node_tree; nt.nodes.clear()
img = bpy.data.images.load(os.path.join(BASE, "blender/fondo_taberna_r3.png"))
img.colorspace_settings.name = 'sRGB'
tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = img
emi = nt.nodes.new('ShaderNodeEmission'); emi.inputs['Strength'].default_value = 1.0
out = nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(tex.outputs['Color'], emi.inputs['Color'])
nt.links.new(emi.outputs['Emission'], out.inputs['Surface'])
tel.data.materials.append(matf)
# suelo con textura propia (vetas + pozos de luz, para que las esquinas no sean planas)
suelo = bpy.data.objects.get("Suelo")
if suelo and suelo.data.materials:
    sm = suelo.data.materials[0]; snt = sm.node_tree
    princ = next((n for n in snt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    outp = next((n for n in snt.nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if princ and outp:
        img2 = bpy.data.images.load(os.path.join(BASE, "blender/suelo_taberna_r3.png"))
        img2.colorspace_settings.name = 'sRGB'
        tex2 = snt.nodes.new('ShaderNodeTexImage'); tex2.image = img2
        emi2 = snt.nodes.new('ShaderNodeEmission'); emi2.inputs['Strength'].default_value = 0.6
        mix = snt.nodes.new('ShaderNodeMixShader'); mix.inputs[0].default_value = 0.35
        snt.links.new(tex2.outputs['Color'], princ.inputs['Base Color'])
        snt.links.new(tex2.outputs['Color'], emi2.inputs['Color'])
        snt.links.new(princ.outputs['BSDF'], mix.inputs[1])
        snt.links.new(emi2.outputs['Emission'], mix.inputs[2])
        snt.links.new(mix.outputs['Shader'], outp.inputs['Surface'])
        print("SUELO textura OK")

bpy.ops.wm.save_mainfile()
print("PATCH_R3_OK")
