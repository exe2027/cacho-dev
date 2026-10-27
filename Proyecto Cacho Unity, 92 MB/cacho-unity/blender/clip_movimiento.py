# CLIP DE MOVIMIENTO A NIVEL DE ASSET — Cacho Unity etapa 1.
# 2 s a 12 fps (24 fotogramas), 960x540, muestras bajas + denoiser.
# Movimiento: parpadeo de lampara calida, respiracion sutil de avatares,
# pulso del aro del turno (TÚ) y leve push-in de camara. NO es gameplay.
import bpy, math, os

BASE = "/home/hatch/workspace/cacho-unity"
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE, "blender/mesa_cacho.blend"))
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.use_denoising = True
scene.cycles.samples = 32
scene.cycles.use_adaptive_sampling = True
scene.cycles.adaptive_threshold = 0.15
scene.cycles.adaptive_min_samples = 8
scene.render.resolution_x = 960
scene.render.resolution_y = 540
scene.render.image_settings.file_format = 'PNG'
cam = bpy.data.objects["CamaraHero"]
scene.camera = cam

OUT = os.path.join(BASE, "renders/movimiento")
os.makedirs(OUT, exist_ok=True)
lampara = bpy.data.objects["Lampara2"]
contraluz = bpy.data.objects["Contraluz"]
av_tu = bpy.data.objects["Avatar_TU"]
av_ch = bpy.data.objects["Avatar_DonChalo"]
aro_tu = bpy.data.objects["Aro_TU"]
cam0 = (0, -11.0, 9.9); cam1 = (0, -10.6, 9.6)

N = 24
for f in range(N):
    t = f / 12.0
    # vela/lampara: parpadeo (3 Hz + 7 Hz) en escala y en la luz calida
    flick = 1.0 + 0.06 * math.sin(2 * math.pi * 3 * t) + 0.04 * math.sin(2 * math.pi * 7 * t + 1.3)
    lampara.scale = (flick, flick, flick)
    contraluz.data.energy = 700 * (1.0 + 0.12 * math.sin(2 * math.pi * 7 * t) + 0.08 * math.sin(2 * math.pi * 13 * t))
    # respiracion sutil (0.5 Hz, +-1.5 %)
    br = 1.0 + 0.015 * math.sin(2 * math.pi * 0.5 * t)
    av_tu.scale = (br, br, br)
    av_ch.scale = (1.0 + 0.015 * math.sin(2 * math.pi * 0.5 * t + 1.0),) * 3
    # pulso del aro del turno (1 Hz, +-6 %)
    pu = 1.0 + 0.06 * math.sin(2 * math.pi * 1.0 * t)
    aro_tu.scale = (pu, pu, pu)
    # push-in leve
    k = f / (N - 1)
    cam.location = tuple(cam0[i] + (cam1[i] - cam0[i]) * k for i in range(3))
    cam.rotation_euler = (0.815, 0, 0)
    scene.render.filepath = os.path.join(OUT, f"frame_{f+1:04d}.png")
    bpy.ops.render.render(write_still=True)
    print("CLIP_FRAME", f + 1, "/", N)
print("CLIP_FIN")
