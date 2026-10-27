# ASSETS NECESARIOS — CACHO Unity, ETAPA 1 (mesa + assets)

> Qué glTF de Blender va en cada slot de la escena `Mesa`, y qué
> ocupa su lugar hasta entonces. Etapa 1 = solo mesa + assets
> (docs/18 §10 paso 1). Formato: **glTF** (docs/18 §1: FBX o glTF;
> se elige glTF por ser abierto y portable a Unity/Android/iOS).
> Luces y texturas HORNEADAS en lo posible (docs/18 §1 y §6).
>
> **Originalidad (docs/18 §8, obligatorio):** modelos, avatares,
> íconos, fichas, logos y sonidos PROPIOS e inventados. Nada copiado
> del mockup (nombres, caras, logo) ni de ningún otro juego.
> Los PNG de Flutter listados como "temporal" son solo referencia de
> composición / marcador provisional, no el arte final de Unity.

## 1. Mesa (slot: TableArea / TableMesh3D)

| Slot | glTF necesario | Notas |
|---|---|---|
| `mesa_ovalo.gltf` | Óvalo de madera oscura, borde grueso, paño con textura y logo "CACHO O DUDO" grabado en dos líneas al centro | Madera #2A1A0E; paño por tier (ver §4). Polígonos bajos; textura horneada con sombras suaves. |
| `room_taberna.gltf` o textura | Fondo de taberna cálida desenfocada (plano de fondo) | Si no hay modelo, textura 2D de fondo. Temporal: `room_dorado.png` de Flutter. |

Temporal hasta tener el glTF: `mesa_fondo.jpg` de Flutter
(`~/workspace/cacho/app/assets/images/mesa_fondo.jpg`, madera nogal +
paño carbón) como imagen de fondo de `TableArea`. Es marcador, no
sustituto definitivo: el método de la etapa es modelo 3D, no foto.

## 2. Vasos y posavasos (slots: PotCup, CupTopLeft/Right, CupMidLeft/Right, MyCup)

| Slot | glTF necesario | Notas |
|---|---|---|
| `vaso_cuero.gltf` | Vaso de cuero torneado, boca abajo, con costuras | 1 modelo, 4 colores de cuero (referencia Flutter: café, burdeos, negro, petróleo). Mi vaso: MISMA malla, escala mayor (docs/18 §2: "Mi vaso es más grande"). |
| `posavasos.gltf` | Posavasos oscuro (elipse) bajo cada vaso | Uno por vaso, incluido el del pozo. Temporal: `coaster.png` de Flutter. |
| `vaso_cuero_levantable` | Variante de mi vaso con pivote para levantarse (animación VER, etapa 2) | En etapa 1 solo se define el pivote; la animación NO se implementa. |

Temporal: `cup_cafe.png` (y `cup_burdeos/negro/petroleo.png`) de
Flutter como sprites 2D de vaso. Marcador de composición, no arte final.

## 3. Dados (slots: MyDiceHidden, CenterDiceGroup)

| Slot | glTF necesario | Notas |
|---|---|---|
| `dado.gltf` | Dado marfil, 6 caras con pintas oscuras | 1 modelo instanciado 5 veces (mis dados) + 5 veces (centro, revelación). Pintas AGRANDADAS y legibles a 390 px de ancho (lección Flutter: a 36 px las pintas eran invisibles). |
| — | — | Mis dados: hijos de mi vaso, INACTIVOS en reposo (V1). Centro: INACTIVO en reposo (V2). Sin física de dados en etapa 1 (la física "para caer en la cara ya decidida" es etapa 2+, docs/18 §5). |

Temporal: `tile_1.png` … `tile_6.png` de Flutter (tiles de la consola,
NO mis dados reales — docs/18 §2) solo como referencia de pintas.
Los tiles de la consola Unity usan `tile_*.png` como marcador hasta
tener íconos propios.

## 4. Paños por tier (materiales de `mesa_ovalo.gltf`)

| Tier (Flutter vigente) | Paño centro | Paño borde | Estado |
|---|---|---|---|
| Casino 500 (defecto) | #171717 carbón | #0C0C0C | DEFINITIVO (decisión Flutter; el del mockup) |
| Barrio 100 | #0B5D3B verde | #083020 | Propuesta Flutter, no definitiva sin sí |
| Salón 250 | #14324A azul | #0C2233 | Propuesta Flutter |
| VIP 1000 | #2E1B3A morado | #1D1024 | Propuesta Flutter |
| High Roller 2500 | #4A3512 bronce | #2E2008 | Propuesta Flutter |

Los montos/nombres de lobby de docs/18 §7 (500 / 2.000 / 10.000 /
50.000 / 250.000) siguen ABIERTOS (ver `PARIDAD.md`): NO se modela
ninguna mesa para esos montos en etapa 1.

## 5. Consola inferior (slots: BottomConsole)

| Slot | Asset necesario | Temporal Flutter |
|---|---|---|
| `btn_calzo` | Botón verde CALZO con ícono de dado propio | `btn_calzo.png` (+ `_off.png` para estado atenuado) |
| `btn_dudo` | Botón rojo DUDO con ícono de dado propio | `btn_dudo.png` (+ `_off.png`) |
| `btn_paso` | Botón gris azulado PASO | `btn_paso.png` (+ `_off.png`) |
| Tiles 1–6 | 6 botones de dado (botones de apuesta, no dados reales) | `tile_1.png` … `tile_6.png` |
| Botón chat | Ícono de chat propio | NINGUNO en Flutter (no hay chat). Marcador: círculo oscuro con bocadillo genérico, SIN función, hasta decisión (ver `PARIDAD.md`). |

Colores de respaldo si falta el sprite: CALZO #0E7A4F, DUDO
#B3202A, PASO #14586B (constantes en `TableLayout.cs`).

## 6. Avatares y placas (slots: Seat*)

| Slot | Asset necesario | Notas |
|---|---|---|
| Avatares | Arte 2D ORIGINAL (docs/18 §1: generado con IA y limpiado, siempre original) | **ABIERTO:** docs/18 pide arte IA original; Flutter hoy usa Blobatar procedural para todos en mesa (y PNG de bots: `bot_chalo.png`, `bot_cuca.png`, `bot_guaton.png`, `bot_huaso.png`, `bot_pituca.png`). Unity NO copia ni los Blobatar ni las caras del mockup. Decisión pendiente en `PARIDAD.md`. |
| Placas | Placa debajo del avatar: nombre + conteo de dados (Flutter hoy) | Nivel y fichas en placa (docs/18 §2): ABIERTO. No se inventa nivel ni saldo en la placa. |
| Aro de turno | Aro de color por jugador; semáforo en turno (verde/amarillo/rojo) | El semáforo es lógica de etapa 2 (aquí solo el aro base). |
| Puestos libres | Marcador de puesto libre (silueta vacía) | Decisión N2: sin avatar, sin vaso, sin placa. |

## 7. Pozo (slot: PotGroup)

| Slot | Asset necesario | Notas |
|---|---|---|
| Placa POZO | Texto "POZO" + monto real | En etapa 1, texto marcador "2.500" (Casino 500 × 5, paridad Flutter). Sin lógica de pozo. |
| Vaso del pozo | `vaso_cuero.gltf` pequeño (centro 51 %, 21 %) | Igual modelo que los vasos de jugador, menor escala. |
| Fichas del pozo | Pila de fichas propia (glTF, etapa 1 opcional) | Si no está, el pozo es placa + vaso, como el mockup. Sin monedas del mockup (no se copian). |

## 8. Lo que NO se necesita en etapa 1 (no modelar todavía)

- Velas, vasos de licor, polvo, humo (ambiente, etapa 2+).
- Cofres, ruleta, regalos, tienda, gemas (lobby/progresión, etapas 6-7
  y secuencia tras auth; ver `PARIDAD.md`).
- Menús, lobby, carrusel de mesas (etapa 6).
- Personajes animados con respiración/parpadeo (etapa 2+).
- Cualquier asset con nombre, cara o logo del mockup o de otro juego.

---

## NOTA DEL COORDINADOR — Corrección del usuario 09:35 ("me equivoqué eran 6")

- **SEIS JUGADORES MÁXIMO (de 2 a 6 por partida).** Distribución del mockup: 1 arriba
  al centro, 2 a la izquierda, 2 a la derecha, yo abajo al centro, con CERO solapes.
  Aplicado en `TableLayout.cs` (SeatTopCenter, clamp 2–6, 6 anclas) y en `Mesa.unity.txt`
  (pila de la columna superior provisional; manda la medición Blender). docs/19 N1
  (2 a 5) quedó desactualizado; no se editó docs/19 desde aquí.
- **REVELACIÓN LEGIBLE:** ningún dado mostrado pequeño e ilegible; todo dado visible
  a tamaño real, sin solapes, con los que cuentan destacados uno a uno. NUNCA todas
  las manos en pequeño al centro. Aplica a renders, storyboard y a la futura UI de
  revelación Unity.
- **Slots afectados:** vasos de jugador pasan de 5 a 6 (nuevo: vaso superior-central);
  el vaso de la columna superior ocupa el slot que antes era "vaso del pozo".
- **MICRÓFONO (voz) Y MÚSICA SE MANTIENEN** (no se diseñan fuera; llegan en etapas
  posteriores). Chat de TEXTO sigue fuera; emotes se quedan.
