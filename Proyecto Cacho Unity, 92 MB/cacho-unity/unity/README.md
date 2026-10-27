# CACHO Unity — esqueleto de proyecto (ETAPA 1: solo mesa + assets)

> **Qué es esto y qué NO es.** Esto es el esqueleto del proyecto Unity
> paralelo a la app Flutter existente, en su ETAPA 1 según el orden de
> trabajo de `~/workspace/cacho/docs/18-master-prompt-casino-animado.md`
> §10 (assets 3D en Blender y la mesa en Unity, idéntica al mockup).
> NO es un build, NO es una APK, NO tiene gameplay, reglas, bots,
> animaciones de juego, audio, menú, lobby ni red. Todo eso son etapas
> 2–7 y requieren, primero, la aprobación de esta etapa 1 por el usuario
> y, para el motor, las decisiones de paridad de
> `~/workspace/cacho-unity/PARIDAD.md`.
>
> **NO se modificó `~/workspace/cacho/`** (repo Flutter): ese árbol solo se
> leyó para extraer la referencia de paridad. Nada aquí se desplegó ni
> se commiteó en el repo del juego.

## 1. Referencia visual (la que manda en esta etapa)

- Mockup objetivo:
  `~/workspace/user/media_library/image/dd/dd43f464f00d352c526b47a8dc7316bb236103e093c25085cdaff6d786e605e7.jpg`
  (mesa horizontal, óvalo de madera oscura con borde grueso, paño oscuro,
  taberna cálida desenfocada, logo grabado "CACHO O DUDO" en dos líneas
  al centro, pozo arriba al centro, consola inferior APOSTAR 1–6 +
  CALZO / DUDO / PASO).
- Especificación: `~/workspace/cacho/docs/18-master-prompt-casino-animado.md`
  (§1, §2, §8, §9, §10 sobre todo).
- Decisiones de paridad vigentes:
  `~/workspace/cacho/docs/19-casos-paridad-flutter-unity.md`
  (26-oct-2026 ~07:32, manda sobre docs/18 y sobre el estado Flutter
  anterior donde lo contradice). Ver `../PARIDAD.md`.
- Identidad: casino oscuro + dorado mate `#C9A24B`, sin café dominante
  en menús; mesa de madera con paño por tier (Casino 500 = paño carbón
  definitivo; Barrio 100 verde, Salón 250 azul, VIP 1000 morado,
  High Roller 2500 bronce — tiers Flutter vigentes; los montos de lobby
  de docs/18 §7 siguen ABIERTOS, ver `../PARIDAD.md`).
- Nombres, avatares, íconos y textos: PROPIOS e inventados
  (docs/18 §8: Don Chalo, La Cuca, El Guatón, La Pituca). NO se copian
  nombres, caras, logos ni arte del mockup ni de ningún otro juego.

## 2. Cómo abrir el esqueleto en Unity Editor

### 2.1 Versión recomendada

- **Unity 2022.3 LTS** (versión estable de largo soporte; la escena y el
  script de esta etapa usan solo `UnityEngine` y `UnityEngine.UI`, sin
  paquetes de versión reciente, para que abran también en 6000 LTS).
- Módulos a instalar con el Editor (Unity Hub → Installs → Add Modules):
  - **Android Build Support** (imprescindible para la APK Android),
  - **Android SDK & NDK Tools** y **OpenJDK** (o apuntar a los ya
    instalados, ver §2.2),
  - iOS Build Support solo si se apunta a TestFlight (requiere Mac y
    cuenta de desarrollador de Apple; ver §4, pendiente de decisión).

### 2.2 Android SDK / JDK que ya existen en esta máquina

La vía Flutter ya dejó instalado un SDK utilizable; Unity puede
reutilizarlo en vez de descargar otro:

- SDK: `~/android/sdk` (platforms 34 y 36, build-tools 34 y 36,
  platform-tools, NDK, licencias).
- En Unity: Edit → Preferences → External Tools → Android → apuntar
  SDK a `~/android/sdk` (y JDK/NDK a los de esa instalación si Unity no
  los resuelve solos). Si Unity instala su propio SDK/NDK/JDK, también
  vale; lo importante es no mezclar dos SDK a medias en un mismo build.

### 2.3 Abrir el proyecto

1. Copiar esta carpeta `unity/` a la máquina con Unity Editor instalado
   (esta VM NO tiene Editor; ver §3).
2. Unity Hub → Add → seleccionar la carpeta del proyecto → abrir con
   2022.3 LTS.
3. Abrir la escena definida en `Assets/Scenes/Mesa.unity.txt`
   (ver nota en §5: es una **definición de escena en texto**, no una
   escena binaria `.unity` válida; hay que recrearla en el Editor
   siguiendo ese documento).
4. Asignar en el inspector de `TableLayout` (GameObject `TableRoot`):
   `canvas`, `tableArea`, `topBar`, `bottomConsole`, `pasoChallengeBar`
   y los prefabs de asiento / vaso / dado (ver `ASSETS_NEEDED.md`).
   Sin asignar, el script no rompe nada: registra un aviso y no
   posiciona ese elemento (todos los campos se comprueban por null).
5. Poner el juego en horizontal 16:9 (Game View 1920×1080 o 844×390
   como referencia Flutter) y pulsar Play: se ve la mesa estática con
   los 5 asientos como máximo, el pozo, la consola y el grupo de dados
   del centro OCULTO (solo aparece en estado de revelación, que en esta
   etapa no existe como lógica).

## 3. Qué falta exactamente para compilar — BLOQUEO HONESTO

- **Unity Editor NO está instalado en esta VM.** No se entrega build,
  APK ni captura de Unity, y ninguna se finge.
- **Licencia Personal de Unity, activada por el usuario.** La activación
  exige un paso con cuenta de Unity en navegador: OAuth del Hub CLI
  (con espera de ~5 minutos) o flujo manual con archivos `.alf` / `.ulf`.
  Ese paso NO se puede completar desde este entorno y NO se piden
  credenciales para ello. Sin Editor licenciado no hay compilación
  posible, ni siquiera en headless.
- En cuanto el usuario active su licencia Personal en una máquina con
  Editor, este esqueleto está listo para abrirse y completarse con los
  assets de `ASSETS_NEEDED.md`; la compilación Android es entonces
  File → Build Settings → Android → Build (con el SDK de §2.2).

## 4. Pregunta de prueba pendiente (docs/18, nota final)

Docs/18 exige preguntar ANTES de empezar cómo se probará cada avance:
hoy se prueba en web (`cacho.pages.dev`); con Unity se pasa a app
nativa — **APK en Android o TestFlight en iPhone** (esto último pide
Mac y cuenta de desarrollador de Apple). Esa decisión sigue pendiente
del usuario y condiciona el módulo iOS de §2.1. No se asume ninguna
de las dos vías.

## 5. Archivos de esta etapa

| Archivo | Contenido |
|---|---|
| `Assets/Scripts/TableLayout.cs` | Posiciona la mesa 16:9 desde las posiciones % del mockup; paleta y tiers como constantes; sin lógica de juego. |
| `Assets/Scenes/Mesa.unity.txt` | **Definición de escena en texto claro** (NO es una escena binaria `.unity` válida): cámara, luces horneadas, jerarquía, posiciones, materiales. Recrearla en el Editor. |
| `ASSETS_NEEDED.md` | Qué glTF de Blender va en cada slot, y qué marcador temporal ocupa su lugar hasta entonces. |
| `../PARIDAD.md` | Brechas docs/18 vs Flutter: qué quedó DECIDIDO el 26-oct 07:32 y qué sigue ABIERTO. Nada resuelto por cuenta propia. |

## 6. Qué NO está (a propósito)

- Build, APK, captura de Unity (ver §3).
- Gameplay, reglas, motor, bots, servidor/red, animaciones de juego,
  audio, háptica, menú, lobby, progresión, cuentas, tienda.
- Lógica del botón VER: en esta etapa VER es solo un marcador visual
  (decisión V1: mis dados ocultos bajo mi vaso, solo se ven con VER).
  El agitado del celular como forma de ver los dados sigue ABIERTO
  (docs/18 §2 lo permite; la decisión 07:32 dice "solo con VER").
- Relleno de puestos vacíos: los asientos sin jugador quedan LIBRES
  (decisión N2); si en línea se rellenan con bots o quedan libres hasta
  que entre gente sigue ABIERTO.
- Alineación Flutter 8→5: motor, servidor, lobby, selector de bots y
  tests de Flutter quedan ENCOLADOS para el pase posterior al frente
  horizontal; NO son trabajo de esta etapa ni de este esqueleto.
