# Verificación ronda 2: medidas reales (no afirmadas) sobre el blend guardado
# y los PNG finales. Proyecta esquinas de bounding-box a NDC de cámara.
import bpy, math, os
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda2.blend")
scene = bpy.context.scene
cam = bpy.data.objects["CamaraHero"]
scene.camera = cam
bpy.context.view_layer.update()
W, H = 1688, 950
def ndc(p):
    v = world_to_camera_view(scene, cam, Vector(p))
    return (v.x, v.y)
def bbox_ndc(name):
    o = bpy.data.objects.get(name)
    if o is None: return None
    pts = []
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        pts.append(ndc((w.x, w.y, w.z)))
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    return (min(xs), max(xs), min(ys), max(ys))
def show(name, label=""):
    b = bbox_ndc(name)
    if b is None:
        print(f"{name} FALTA"); return
    print(f"{label or name}: x=[{b[0]:.3f},{b[1]:.3f}] ({(b[1]-b[0])*100:.1f}% ancho) "
          f"y=[{b[2]:.3f},{b[3]:.3f}] alto_px={(b[3]-b[2])*H:.0f} equiv390={(b[3]-b[2])*H*390/H:.0f}")
print("CAMARA", tuple(round(v, 2) for v in cam.location), tuple(round(v, 2) for v in cam.rotation_euler), "lens", cam.data.lens)
for n in ("Avatar_TU", "Avatar_ElHuaso", "LogoCachoODudo", "R2_OvaloLogo",
          "R2_Saldo", "R2_BtnCalzoTxt", "R2_BtnDudoTxt", "R2_BtnPasoTxt",
          "R2_TextoPlaca_DonChalo", "R2_TextoPozo", "R2_Etiq_HU",
          "R2_Barra", "R2_Consola", "Vaso_TU", "Vaso_ElGuaton"):
    show(n)
# dados de revelación: ancho de un dado
show("R2_Dado_HU_1", "DadoRevelacion_HU1")
show("R2_Dado_HU_1_pip", "PipRevelacion")
for p in ("renders/ronda2/pantalla_completa.png", "renders/ronda2/revelacion.png", "renders/ronda2/paso.png"):
    fp = os.path.join("/home/hatch/workspace/cacho-unity", p)
    print(p, os.path.getsize(fp) if os.path.exists(fp) else "FALTA")
from PIL import Image
for p in ("renders/ronda2/pantalla_completa.png", "renders/ronda2/revelacion.png", "renders/ronda2/paso.png"):
    fp = os.path.join("/home/hatch/workspace/cacho-unity", p)
    if os.path.exists(fp):
        im = Image.open(fp); print(p, im.size, im.mode)
print("VERIFY_OK")
