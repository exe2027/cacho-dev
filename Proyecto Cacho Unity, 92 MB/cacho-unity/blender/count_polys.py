# Conteo de poligonos de malla EVALUADA por coleccion (solo lectura, no guarda).
import bpy
bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")
deps = bpy.context.evaluated_depsgraph_get()
total = 0
for coll in ["Mesa", "Vasos", "Dados", "Fichas", "Asientos", "Fondo", "Logo"]:
    c = bpy.data.collections.get(coll)
    n = 0
    if c:
        for o in c.objects:
            if o.type == 'MESH':
                n += len(o.evaluated_get(deps).data.polygons)
    print(f"POLIGONOS {coll}: {n}")
    total += n
print(f"POLIGONOS TOTAL: {total}")
