# MEDICION DE SOLAPES — Cacho Unity etapa 1 (correccion 09:35).
# Proyecta las cajas envolventes reales de cada objeto a la camara hero y mide
# solapes 2D en el cuadro (0..1). Si las cajas AABB no se solapan, los objetos
# no se solapan en el render (la AABB es conservadora: un solape AABB pequeno
# puede ser falso positivo por la caja, y se informa como tal).
# Salida: stdout + blender/medicion_solapes.txt
import bpy, os
from bpy_extras.object_utils import world_to_camera_view

BASE = "/home/hatch/workspace/cacho-unity"
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE, "blender/mesa_cacho.blend"))
scene = bpy.context.scene
cam = bpy.data.objects["CamaraHero"]
W, H = scene.render.resolution_x, scene.render.resolution_y

def aabb(name):
    o = bpy.data.objects.get(name)
    if o is None:
        return None
    xs, ys = [], []
    for c in o.bound_box:
        w = o.matrix_world @ __import__('mathutils').Vector(c)
        v = world_to_camera_view(scene, cam, w)
        xs.append(v.x); ys.append(v.y)
    return (min(xs), min(ys), max(xs), max(ys))

def union(names):
    boxes = [aabb(n) for n in names if aabb(n)]
    return (min(b[0] for b in boxes), min(b[1] for b in boxes),
            max(b[2] for b in boxes), max(b[3] for b in boxes))

MON = []
for s in ["ElHuaso", "DonChalo", "LaPituca", "ElGuaton", "LaCuca", "TU"]:
    MON.append(f"Avatar_{s}")
    MON.append(f"Placa_{s}")
    MON.append(f"Vaso_{s}")
MON += ["PlacaPozo", "PlacaApuesta", "SlotReacciones"]
boxes = {}
for n in MON:
    boxes[n] = aabb(n)
boxes["PilaFichas"] = union([f"FichaPozo_{i}" for i in range(10)] +
                            [f"FichaSuelta_{i}" for i in range(3)])
boxes["Logo"] = aabb("LogoCachoODudo")

lines = []
lines.append(f"Cuadro: {W}x{H}, camara {cam.name}")
lines.append("")
lines.append("== Contencion en cuadro (0..1) ==")
clipped = []
for n, b in boxes.items():
    if b is None:
        lines.append(f"{n}: NO ENCONTRADO"); continue
    out = []
    if b[0] < 0: out.append(f"izq {-b[0]*W:.0f}px")
    if b[1] < 0: out.append(f"abajo {-b[1]*H:.0f}px")
    if b[2] > 1: out.append(f"der {(b[2]-1)*W:.0f}px")
    if b[3] > 1: out.append(f"arriba {(b[3]-1)*H:.0f}px")
    if out:
        clipped.append(n)
        lines.append(f"{n}: FUERA DEL CUADRO: {', '.join(out)}")
lines.append("Sin recortes." if not clipped else f"Recortados: {len(clipped)}")
lines.append("")
lines.append("== Solapes 2D entre tokens (sin Logo) ==")
names = [n for n in boxes if n != "Logo"]
overlaps = []
for i in range(len(names)):
    for j in range(i + 1, len(names)):
        a, b = boxes[names[i]], boxes[names[j]]
        if a is None or b is None: continue
        ix = min(a[2], b[2]) - max(a[0], b[0])
        iy = min(a[3], b[3]) - max(a[1], b[1])
        if ix > 0 and iy > 0:
            area_px = ix * W * iy * H
            overlaps.append((names[i], names[j], ix * W, iy * H, area_px))
if not overlaps:
    lines.append("CERO SOLAPES entre avatares, placas, vasos, pozo, apuesta, fichas y reacciones.")
else:
    for n1, n2, wpx, hpx, apx in sorted(overlaps, key=lambda t: -t[4]):
        lines.append(f"SOLAPE {n1} x {n2}: {wpx:.0f}x{hpx:.0f} px ({apx:.0f} px2)")
lines.append("")
lines.append("== Info: Logo vs vaso superior-central (oclusion 3D normal, no token-token) ==")
a, b = boxes["Logo"], boxes["Vaso_ElHuaso"]
ix = min(a[2], b[2]) - max(a[0], b[0]); iy = min(a[3], b[3]) - max(a[1], b[1])
if ix > 0 and iy > 0:
    lines.append(f"Logo x Vaso_ElHuaso: AABB se cruzan {ix*W:.0f}x{iy*H:.0f} px (el vaso tapa un arco del anillo; ver NOTAS.md)")
else:
    lines.append("Logo x Vaso_ElHuaso: sin cruce AABB.")
out = "\n".join(lines)
print(out)
with open(os.path.join(BASE, "blender/medicion_solapes.txt"), "w") as f:
    f.write(out + "\n")
print("MEDICION_OK")
