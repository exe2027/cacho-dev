# PARCHE v6c — despejar texto del POZO y logo del vaso superior-central.
# Diagnostico medido: la caja del vaso (143 px de alto) no cabe entre la placa
# (borde inf. 0.716) y el logo (borde sup. 0.650): hueco 63 px. Ademas, mover el
# vaso en Y apenas mueve su borde superior en pantalla (perspectiva).
# Solucion: logo completo (texto + anillo) a y=-0.80, y vaso superior-central a
# 0.75x en (0,1.00): en perspectiva se ve casi igual que los vasos rivales 1.0x
# (mas lejos), y su caja cabe entre placa y logo. Columna intacta.
import bpy

bpy.ops.wm.open_mainfile(filepath="/home/hatch/workspace/cacho-unity/blender/mesa_cacho.blend")

def move(name, loc):
    o = bpy.data.objects.get(name)
    if o: o.location = loc
    else: print("FALTA", name)

logo = bpy.data.objects["LogoCachoODudo"]
logo.location = (0, -0.80, 0.06)
anillo = bpy.data.objects["AnilloLogo"]
anillo.location = (0, -0.80, 0.05)
vaso = bpy.data.objects["Vaso_ElHuaso"]
vaso.location = (0, 1.00, 0.11)
vaso.scale = (0.75, 0.75, 0.75)
posa = bpy.data.objects["Posavasos_ElHuaso"]
posa.location = (0, 1.00, 0.075)
posa.scale = (0.75, 0.75, 1.0)
bpy.ops.wm.save_mainfile()
print("PARCHE_V6C_OK")
