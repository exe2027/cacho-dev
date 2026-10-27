# RONDA 4 — corrección Unity/Blender contra el ejemplo.
# Trabaja SOLO sobre blender/mesa_cacho_ronda4.blend (copia de ronda 3;
# ronda 3, ronda 2 y etapa 1 NO se tocan). Estado guardado = hero
# (pantalla completa); revelación y Paso se activan SOLO por visibilidad
# en blender/render_ronda4.py, SIN mover nada (el desplazamiento de la
# tabla de revelación a y=-1,15 queda GUARDADO en este blend).
import bpy, math, os
BASE = "/home/hatch/workspace/cacho-unity"
SRC = os.path.join(BASE, "blender/mesa_cacho_ronda4.blend")
bpy.ops.wm.open_mainfile(filepath=SRC)
scene = bpy.context.scene
cam = bpy.data.objects["CamaraHero"]

def srgb(r, g, b):
    def cv(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (cv(r), cv(g), cv(b), 1.0)

def princ(mat):
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            return n
    return None

def set_emis(mat, color, strength=None):
    n = princ(mat)
    if len(color) == 3:
        color = (color[0], color[1], color[2], 1.0)
    if n:
        if 'Emission Color' in n.inputs:
            n.inputs['Emission Color'].default_value = color
        if strength is not None and 'Emission Strength' in n.inputs:
            n.inputs['Emission Strength'].default_value = strength

def move(name, loc):
    o = bpy.data.objects.get(name)
    if o:
        o.location = loc
    else:
        print("FALTA", name)
    return o

def hud_cube(name, x, y, z, sx, sy, mat, rot_z=0.0):
    bpy.ops.mesh.primitive_cube_add(location=(x, y, z), rotation=(0, 0, rot_z))
    o = bpy.context.active_object
    o.name = name
    o.parent = cam
    o.scale = (sx, sy, 0.01)
    o.data.materials.append(mat)
    return o

def hud_text(name, body, x, y, z, size, mat, font):
    bpy.ops.object.text_add(location=(x, y, z))
    o = bpy.context.active_object
    o.name = name
    o.parent = cam
    o.data.body = body
    o.data.font = font
    o.data.font_bold = font
    o.data.font_italic = font
    o.data.font_bold_italic = font
    o.data.size = size
    o.data.align_x = 'CENTER'
    o.data.align_y = 'CENTER'
    o.data.extrude = 0.0
    o.data.bevel_depth = 0.0
    o.data.materials.append(mat)
    return o

def hud_disc_copy(name, x, y, z, scale):
    src = bpy.data.objects["R2_Ajustes"]
    o = src.copy()
    o.data = src.data.copy()
    o.name = name
    scene.collection.objects.link(o)
    o.parent = cam
    o.location = (x, y, z)
    o.scale = (scale, scale, 1.0)
    return o

def hud_cyl(name, x, y, z, sx, sy, mat):
    bpy.ops.mesh.primitive_cylinder_add(location=(x, y, z), vertices=32)
    o = bpy.context.active_object
    o.name = name
    o.parent = cam
    o.scale = (sx, sy, 0.005)
    o.data.materials.append(mat)
    return o

MAT_TXT = bpy.data.materials.get("R2_TextoBlanco")
MAT_NEGRO = bpy.data.materials.get("R3_TextoNegro")
MAT_HUD = bpy.data.materials.get("R2_HudBoton")
MAT_ORO = bpy.data.materials.get("R2_OroMate")

# ---------- 9. DUCTUS: UNA sola fuente para todo el texto de escena ----------
FONT = bpy.data.fonts.load("/usr/share/fonts/truetype/noto/NotoSans-CondensedBold.ttf")
for o in bpy.data.objects:
    if o.type == 'FONT':
        o.data.font = FONT
        o.data.font_bold = FONT
        o.data.font_italic = FONT
        o.data.font_bold_italic = FONT
        o.data.extrude = 0.0
        o.data.bevel_depth = 0.0
for f in list(bpy.data.fonts):
    if f != FONT:
        fname = f.name
        try:
            bpy.data.fonts.remove(f)
            print("FUENTE-ELIMINADA", fname)
        except Exception as e:
            print("FUENTE-NO-ELIMINADA", fname, e)
print("FUENTES-RESTANTES", [f.name for f in bpy.data.fonts])

# ---------- 5. CÁMARA más cenital (misma distancia ~15,9; sin tocar HUD) ----------
cam.location = (0.0, -11.5, 11.0)
cam.rotation_euler = (math.atan2(11.5, 11.0), 0.0, 0.0)  # 0,807 rad
print("CAMARA", tuple(cam.location), tuple(round(v, 4) for v in cam.rotation_euler))

# ---------- 1. CONSOLA: acciones re-centradas, huecos uniformes ----------
# Antes: centros 0,33/0,89/1,41 (espaciado 0,56/0,52), ancho 0,50 ->
# huecos 0,06/0,02 (30/9 px) y PASO a 99,3%. Ahora: ancho 0,47,
# centros 0,28/0,81/1,34 (espaciado 0,53/0,53), huecos 0,06/0,06,
# PASO derecha 1,575 (inset 0,135 frente a consola 1,71).
CY = -0.7345
for btn, txt, bx in (("R2_BtnCalzo", "R2_BtnCalzoTxt", 0.28),
                     ("R2_BtnDudo", "R2_BtnDudoTxt", 0.81),
                     ("R2_BtnPaso", "R2_BtnPasoTxt", 1.34)):
    b = bpy.data.objects[btn]
    b.location = (bx, CY, b.location.z)
    b.scale = (0.235, 0.1645, 0.01)
    t = bpy.data.objects[txt]
    t.location = (bx + 0.03, CY, t.location.z)
move("R3_IconoDado_Calzo", (0.07, CY, -2.98))
move("R3_IconoDadoPip_Calzo", (0.07, CY, -2.96))
move("R3_IconoDado_Dudo", (0.60, CY, -2.98))
move("R3_IconoDadoPip_Dudo", (0.60, CY, -2.96))
move("R3_PasoBarra_1", (1.13, CY, -2.98))
move("R3_PasoBarra_2", (1.18, CY, -2.98))

# ---------- 2. BARRA COMPLETA (geometría de escena, nunca imagen 2D) ----------
# Orden de la definición: Salir, saldo, Pozo, turno, apuesta, mic,
# música, historial, ajustes. Se mueven los existentes y se crean los
# que faltaban; se borran los rótulos sueltos MIC/MÚSICA.
move("R2_ChipSaldo", (-1.35, 0.79, -2.98))
saldo = bpy.data.objects["R2_Saldo"]
saldo.location = (-1.26, 0.79, -2.96)
saldo.data.size = 0.115
for n in ("R2_Mic", "R2_Musica"):
    o = bpy.data.objects.get(n)
    if o:
        bpy.data.objects.remove(o, do_unlink=True)
        print("BORRADO-ROTULO", n)
# Salir: píldora + X geométrica + texto
hud_cube("R4_SalirPill", -1.56, 0.79, -2.98, 0.14, 0.07, MAT_HUD)
hud_cube("R4_SalirX1", -1.66, 0.79, -2.96, 0.03, 0.008, MAT_TXT, rot_z=0.785)
hud_cube("R4_SalirX2", -1.66, 0.79, -2.96, 0.03, 0.008, MAT_TXT, rot_z=-0.785)
hud_text("R4_SalirTxt", "SALIR", -1.51, 0.79, -2.96, 0.085, MAT_TXT, FONT)
# Pozo / turno / apuesta: píldoras + texto
hud_cube("R4_PozoPill", -0.71, 0.79, -2.98, 0.22, 0.07, MAT_HUD)
hud_text("R4_PozoTxt", "POZO 3.000", -0.71, 0.79, -2.96, 0.085, MAT_TXT, FONT)
hud_cube("R4_TurnoPill", -0.16, 0.79, -2.98, 0.30, 0.07, MAT_HUD)
hud_text("R4_TurnoTxt", "TURNO · EL HUASO", -0.16, 0.79, -2.96, 0.082, MAT_TXT, FONT)
hud_cube("R4_ApuestaPill", 0.53, 0.79, -2.98, 0.35, 0.07, MAT_HUD)
hud_text("R4_ApuestaTxt", "5 QUINTAS · DON CHALO", 0.53, 0.79, -2.96, 0.082, MAT_TXT, FONT)
# Mic: disco + micrófono geométrico (cápsula + U + pie)
hud_disc_copy("R4_MicDisc", 1.01, 0.79, -2.98, 1.285)
hud_cube("R4_MicCapsula", 1.01, 0.80, -2.96, 0.015, 0.032, MAT_TXT)
hud_cube("R4_MicU1", 0.975, 0.76, -2.96, 0.005, 0.025, MAT_TXT)
hud_cube("R4_MicU2", 1.045, 0.76, -2.96, 0.005, 0.025, MAT_TXT)
hud_cube("R4_MicUBase", 1.01, 0.735, -2.96, 0.04, 0.005, MAT_TXT)
hud_cube("R4_MicPie", 1.01, 0.715, -2.96, 0.005, 0.015, MAT_TXT)
# Música: disco + nota geométrica dorada (cabeza + plica + corchete)
hud_disc_copy("R4_MusicaDisc", 1.21, 0.79, -2.98, 1.285)
hud_cyl("R4_NotaCabeza", 1.195, 0.755, -2.96, 0.025, 0.018, MAT_ORO)
hud_cube("R4_NotaPlica", 1.225, 0.79, -2.96, 0.004, 0.038, MAT_ORO)
hud_cube("R4_NotaCorchete", 1.232, 0.815, -2.96, 0.012, 0.004, MAT_ORO, rot_z=-0.4)
# Historial: disco + reloj geométrico (esfera blanca + agujas negras)
hud_disc_copy("R4_HistDisc", 1.41, 0.79, -2.98, 1.285)
hud_cyl("R4_RelojEsfera", 1.41, 0.79, -2.96, 0.05, 0.05, MAT_TXT)
hud_cube("R4_RelojAguja1", 1.41, 0.805, -2.94, 0.003, 0.02, MAT_NEGRO)
hud_cube("R4_RelojAguja2", 1.42, 0.79, -2.94, 0.003, 0.015, MAT_NEGRO, rot_z=1.2)
# Ajustes: disco existente agrandado a Ø0,18 + dientes de engranaje + centro
aj = bpy.data.objects["R2_Ajustes"]
aj.location = (1.61, 0.79, -2.98)
aj.scale = (1.285, 1.285, 1.0)
for i in range(8):
    ang = i * math.pi / 4.0
    hud_cube(f"R4_GearDiente_{i}", 1.61 + 0.095 * math.cos(ang),
             0.79 + 0.095 * math.sin(ang), -2.96, 0.012, 0.02, MAT_TXT, rot_z=ang)
hud_cyl("R4_GearCentro", 1.61, 0.79, -2.96, 0.028, 0.028, MAT_TXT)

# ---------- 3. PLACAS / POZO: tinta mayor (medir en PNG; piso si no llega) ----------
for o in bpy.data.objects:
    if o.type == 'FONT' and o.name.startswith("R2_TextoPlaca_"):
        o.data.size = 0.34
bpy.data.objects["R2_TextoPozo"].data.size = 0.42
bpy.data.objects["R3_TextoApuesta"].data.size = 0.36
for n in ("Placa_DonChalo", "Placa_ElGuaton", "Placa_ElHuaso",
          "Placa_LaCuca", "Placa_LaPituca", "Placa_TU"):
    o = bpy.data.objects.get(n)
    if o:
        o.scale.x = 1.30

# ---------- 7. VEREDICTO con etiqueta de perdedor (3 líneas) ----------
# Escenario de paridad: El Huaso dudó la apuesta de Don Chalo en su
# turno (coherente con la píldora de turno de la barra); el Dudo falla
# -> pierde 1 dado.
tvt = bpy.data.objects["R2_TablaVeredictoTxt"]
tvt.data.body = "DUDO FALLA · 10/5\nQUINTAS · DON CHALO\nPIERDE 1 DADO · EL HUASO"
tv = bpy.data.objects["R2_TablaVeredicto"]
tv.scale = (3.2, 0.66, 0.015)

# ---------- 8. TABLITA PASO legible ----------
bpy.data.objects["R2_TablaPasoTxt"].data.size = 0.30
bpy.data.objects["R2_TablaPaso"].scale = (2.1, 0.28, 0.015)

# ---------- 6. ANILLOS DE CONTEO distinguibles uno a uno ----------
# Antes: toro Ø0,78 frente a dado 0,64 (diagonal 0,905): el dado tapaba
# el anillo y solo asomaban 2 medias lunas. Ahora: ×1,45 (Ø1,13, mayor
# que la diagonal) y z 0,025 para que el anillo rodee al dado.
for o in bpy.data.objects:
    if o.name.startswith("R2_Anillo_"):
        o.scale = (1.45, 1.45, 1.0)
        o.location = (o.location.x, o.location.y, 0.025)

# ---------- 10. REPRODUCIBILIDAD: desplazamiento de revelación GUARDADO ----------
# La tabla y su texto quedan en y=-1,15 EN EL BLEND (ocultos en hero,
# visibles solo en revelación). El render de revelación ya NO mueve nada.
for _n in ("R2_TablaVeredicto", "R2_TablaVeredictoTxt"):
    _o = bpy.data.objects[_n]
    _o.location = (_o.location.x, -1.15, _o.location.z)
print("VEREDICTO-GUARDADO", tuple(bpy.data.objects["R2_TablaVeredicto"].location),
      tuple(bpy.data.objects["R2_TablaVeredictoTxt"].location))

# ---------- 4. LUZ ESTABILIZADA: dorado único + botones al hex ----------
# Dorado único: TODAS las piezas doradas visibles usan R2_OroMate
# (el anillo TÚ usaba R2_GrisNeutro difuso: esa era la divergencia).
aro = bpy.data.objects.get("Aro_TU")
if aro:
    aro.data.materials.clear()
    aro.data.materials.append(MAT_ORO)
logo_ring = bpy.data.objects.get("AnilloLogo")
if logo_ring:
    logo_ring.data.materials.clear()
    logo_ring.data.materials.append(MAT_ORO)
# Calibración iteración 1 (fílmico Medium Contrast; medir en previa y
# corregir con la pendiente local display/lineal antes del render final).
set_emis(MAT_ORO, srgb(0.788, 0.635, 0.294), strength=1.65)
set_emis(bpy.data.materials["R2_Calzo"], (0.003, 0.300, 0.125), strength=1.0)
set_emis(bpy.data.materials["R2_Dudo"], (0.570, 0.020, 0.032), strength=1.0)
set_emis(bpy.data.materials["R2_Paso"], (0.006, 0.166, 0.230), strength=1.0)
# Luces sin cambio (400/180/85: el paño ya estaba cerrado en ronda 3;
# botones y dorado son emisión y no dependen de ellas).

bpy.ops.wm.save_mainfile()
print("PATCH_R4_OK")
