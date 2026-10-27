# Renders RONDA 4 (1688x950, Cycles). Se abre el blend GUARDADO y SOLO se
# tocan visibilidades: NINGUN desplazamiento en memoria (la tabla de
# revelación ya está en y=-1,15 dentro del blend). Uso: el mismo script
# sirve para la entrega y para la demostración de reproducibilidad
# (reabrir en fresco y re-renderizar debe dar el mismo revelacion.png).
import bpy, time, sys
SRC = "/home/hatch/workspace/cacho-unity/blender/mesa_cacho_ronda4.blend"
OUT = "/home/hatch/workspace/cacho-unity/renders/ronda4/"
MODE = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "all"
RES = (1688, 950)

def setup(samples):
    bpy.ops.wm.open_mainfile(filepath=SRC)
    s = bpy.context.scene
    s.camera = bpy.data.objects["CamaraHero"]
    s.render.resolution_x, s.render.resolution_y = RES
    s.cycles.samples = samples
    return s

def hide(names, val=True):
    for o in bpy.data.objects:
        if any(o.name.startswith(p) for p in names):
            o.hide_render = val

def show(names):
    hide(names, val=False)

def render(path, samples):
    s = setup(samples)
    t = time.time()
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("RENDER_OK", path, f"{time.time()-t:.0f}s", flush=True)

if MODE in ("all", "pantalla"):
    render(OUT + "pantalla_completa.png", 64)
if MODE in ("all", "revelacion"):
    s = setup(48)
    for v in list(bpy.data.objects):
        if v.name.startswith("Vaso_"):
            v.hide_render = True
            for ch in v.children:
                ch.hide_render = True
    hide(["R3_PlacaApuesta", "R3_TextoApuesta"])
    show(["R2_Dado_HU_", "R2_Dado_PI_", "R2_Dado_CH_", "R2_Dado_CU_",
          "R2_Dado_GU_", "R2_Dado_TÚ_",
          "R2_Anillo_HU_", "R2_Anillo_PI_", "R2_Anillo_CH_", "R2_Anillo_CU_",
          "R2_Anillo_GU_", "R2_Anillo_TÚ_",
          "R2_Etiq_", "R2_TablaVeredicto"])
    t = time.time()
    s.render.filepath = OUT + "revelacion.png"
    bpy.ops.render.render(write_still=True)
    print("RENDER_OK", OUT + "revelacion.png", f"{time.time()-t:.0f}s", flush=True)
if MODE in ("all", "paso"):
    s = setup(48)
    v = bpy.data.objects["Vaso_ElGuaton"]
    v.hide_render = True
    for ch in v.children:
        ch.hide_render = True
    hide(["R3_PlacaApuesta", "R3_TextoApuesta"])
    show(["R2_PasoDado_", "R2_TablaPaso"])
    t = time.time()
    s.render.filepath = OUT + "paso.png"
    bpy.ops.render.render(write_still=True)
    print("RENDER_OK", OUT + "paso.png", f"{time.time()-t:.0f}s", flush=True)
print("RENDERS_R4_OK", flush=True)
