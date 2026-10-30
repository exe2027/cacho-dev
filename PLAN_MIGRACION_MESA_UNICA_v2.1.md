# Plan de Migración: Mesa Única y Escalable (v2.1)

**Fecha:** 30 oct 2026  
**Objetivo:** Resolver solapamientos eliminando la dependencia de fotos como referencias geométricas.

---

## 📊 Estado Actual vs. Meta

### Problema
- `prueba.cachos.pages.dev`: vasos y avatares se solapan
- Dos sistemas de coordenadas independientes:
  1. Fotos (`BoxFit.cover`) que se escalan según viewport
  2. Geometría de asientos (`sketch_layout.dart`) independiente
- Cuando cambia la resolución, foto y asientos se desalinean

### Solución Propuesta
Una **mesa geométrica única** que:
- ✅ Se construye matemáticamente (óvalo + asientos en coordenadas)
- ✅ Cambia de **decoración** (colores, texturas) según tier, no de geometría
- ✅ Garantiza cero solapamientos en cualquier resolución
- ✅ Los jugadores siempre en las mismas **posiciones relativas**

---

## 🏗️ Arquitectura

### Capas (de atrás adelante)

```
┌─────────────────────────────────────────────────────┐
│ 1. FONDO AMBIENTAL (room_taverna_blur.jpg, etc.)    │
│    → Sin afectar layout, solo ambiente              │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│ 2. MESA GEOMÉTRICA ÚNICA                            │
│    ├─ Óvalo (378×90 a 844×390, escalable)          │
│    ├─ Paño (color por tier)                         │
│    ├─ Borde (madera/cian según tier)                │
│    └─ Filete dorado (solo en VIP/Mansión)           │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│ 3. COMPONENTES DINÁMICOS (coordenadas derivadas)    │
│    ├─ Vasos (2–6, posiciones fijas)                 │
│    ├─ Avatares (encima/junto a vasos)               │
│    ├─ Placas (nombres, siempre debajo)              │
│    ├─ Pozo (arriba al centro)                       │
│    └─ Mis dados (banda inferior)                    │
└─────────────────────────────────────────────────────┘
```

### Clases Nuevas

#### `table_geometry.dart`
- **`TableSize`**: dimensiones y centro del óvalo
- **`SeatGeometry`**: posición, tamaño y rotación de un asiento
- **`TableGeometry`**: colección de asientos + pozo + verificación de solapes
- **`TableGeometryGenerator`**: fabrica que genera geometría según viewport

#### `table_renderer.dart`
- **`TableRenderer`**: CustomPaint que dibuja la mesa con tier actual
- **`_TablePainter`**: lógica de pintado (marco, paño, filete, pozo)
- **`TableComponent`**: posiciona avatares/vasos/placas usando coordenadas

---

## 🎯 Plan de Implementación (4 Fases)

### Fase 1: Infraestructura (YA HECHO)
✅ Crear `table_geometry.dart`  
✅ Crear `table_renderer.dart`  
✅ Clases base funcionando, sin integración en UI todavía

### Fase 2: Integración en Game Screen
**Lo que hay que hacer:**
1. Modificar `game_screen.dart` para generar `TableGeometry` en lugar de `SketchLayout`
2. Usar `TableRenderer` para pintar la mesa
3. Posicionar avatares/vasos/placas con `TableComponent`
4. Mantener `sketch_layout.dart` sin tocar (tests siguen funcionando)

**Archivos a editar:**
- `app/lib/screens/game_screen.dart` (método `_sketchTable`)

**Resultado:** Mesa nueva, cero solapamientos, misma lógica de juego

### Fase 3: Diferenciación por Tier
**Lo que hay que hacer:**
1. Mapear tiers a `TableGeometry` con paletas de `table_themes.dart`
2. Cada tier hereda la misma geometría, pero cambia:
   - Color del paño (`feltCenter`, `feltEdge`)
   - Color del borde (`rimTop`, `rimBottom`)
   - Anchos de filete (`filletWidth`)
   - Animaciones exclusivas (brillo, parpadeo en Neón)
3. Validar visualmente que cada tier se ve diferente pero mantiene la estructura

**Archivos:**
- `app/lib/table_themes.dart` (leer `tierLookFor`, mapear a stake)
- Posibles assets nuevos para texturas (opcionales)

### Fase 4: Validación y Refinamiento
**Tests a correr:**
1. `flutter analyze` → sin errores
2. `dart test` (en `packages/cacho_engine`) → engine sin cambios
3. `flutter test` en `app/` → tests existentes no rompen
4. Partida real en navegador (844×390 y versiones más pequeñas)
5. Captura visual: comparar mesa nueva vs. 8 Ball Pool

**Criterio de éxito:**
- ✅ Cero solapamientos en 844×390, 667×340, 412×800 (vertical avisada)
- ✅ Cada tier tiene identidad visual clara
- ✅ Jugadores siempre en las mismas posiciones relativas
- ✅ Se ve parecido a 8 Ball Pool (lado a lado)

---

## 📋 Tareas en Detalle

### Tarea 2.1: Editar `game_screen.dart` (método `_sketchTable`)

**Reemplazar:**
```dart
final layout = sketchLayout(
  screenW: screenW,
  screenH: 56 + tableH + 72,
  rivals: others.length,
  myDiceCount: c.myHand.length,
  consoleH: 72,
);
```

**Con:**
```dart
import 'package:cacho/table_geometry.dart';

final geometry = TableGeometryGenerator.generate(
  screenWidth: screenW,
  screenHeight: 56 + tableH + 72,
  barTop: 56,
  consoleHeight: 72,
  playerCount: 1 + others.length,
);
```

**Luego, en lugar de `SketchRect` positions, usar `SeatGeometry` de `geometry.seats`.**

### Tarea 2.2: Pintar la mesa con `TableRenderer`

**En el Stack de `_sketchTable`:**
```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    // Fondo ambiental (seguir igual)
    Positioned.fill(
      child: Container(
        decoration: landscapeRoomDecoration(c.roomTheme),
      ),
    ),
    
    // Mesa nueva (TableRenderer)
    Positioned(
      left: geometry.tableSize.centerX - geometry.tableSize.radiusX,
      top: geometry.tableSize.centerY - geometry.tableSize.radiusY,
      width: geometry.tableSize.ovalWidth,
      height: geometry.tableSize.ovalHeight,
      child: TableRenderer(
        geometry: geometry,
        tierID: c.roomTheme,
      ),
    ),
    
    // Componentes: avatares, vasos, placas (posicionar con TableComponent)
    ...
  ],
)
```

### Tarea 2.3: Posicionar componentes con coordenadas nuevas

**Para cada rival:**
```dart
for (var i = 0; i < others.length; i++) {
  final seatGeo = geometry.seats[i];
  
  // Avatar
  TableComponent(
    center: seatGeo.avatarCenter,
    size: seatGeo.avatarSize,
    child: AvatarWidget(player: others[i]),
  ),
  
  // Vaso
  TableComponent(
    center: seatGeo.cupCenter,
    size: seatGeo.cupSize,
    child: CupWidget(player: others[i]),
  ),
  
  // Placa
  TableComponent(
    center: seatGeo.plateCenter,
    size: seatGeo.plateSize,
    child: PlateWidget(player: others[i]),
  ),
}

// Mi asiento (siempre abajo)
final mySeatGeo = geometry.mySeat;
TableComponent(center: mySeatGeo.avatarCenter, size: mySeatGeo.avatarSize, child: MyAvatar()),
// ... etc
```

---

## 🎨 Diferenciación por Tier (Ejemplos Finales)

| Tier | Paño | Borde | Filete | Ambiente | Anim |
|------|------|-------|--------|----------|------|
| **La Taberna** (100) | Verde barrial `#0B5D3B` | Madera `#8A5A30` | 0 | Pub + halos | Ninguna |
| **El Boliche** (250) | Azul noche `#14324A` | Madera `#7A4E28` | 0 | Pub atenuada | Sombra leve |
| **Casino** (500) | Negro `#171717` | Dorado `#5A3A1E` | 0 | Taberna blur | Ninguna |
| **Mansión** (1000) | Púrpura `#2E1B3A` | Dorado `#5A3A1E` | 2 px dorado | Oscura + viñeta | Brillo cristal |
| **Club VIP** (2500) | Bronce `#4A3512` | Dorado `#5A3A1E` | 2 px dorado | Casi negra | Parpadeo cian |

---

## ✅ Validación Pre-Despliegue

Antes de deployar a producción:

1. **Tests locales:**
   ```bash
   cd app && flutter test
   ```
   Debe pasar sin cambios en los tests existentes.

2. **Análisis:**
   ```bash
   flutter analyze
   ```
   Sin warnings nuevos.

3. **Build web:**
   ```bash
   flutter build web
   ```
   Sin errores.

4. **Prueba visual en múltiples resoluciones:**
   - 844×390 (referencia)
   - 667×340 (iPad mini)
   - 412×915 (Android con consola)
   - Captura lado a lado vs. 8 Ball Pool

5. **Comparación punto a punto con el ejemplo del usuario:**
   - Mesa ovalada ✓
   - 6 jugadores sin solapes ✓
   - Pozo arriba al centro ✓
   - Consola con botones (1–6, CALZO, DUDO, PASO) ✓
   - Ningún elemento fuera del óvalo ✓

---

## 📝 Nota Importante

**`sketch_layout.dart` NO se elimina.** Se mantiene:
- Todos los tests siguen pasando
- La clase `SketchLayout` y funciones auxiliares permanecen
- Es la fuente de verdad del diseño antiguo (respaldo)

La nueva geometría (`TableGeometry`) vive en paralelo. Si algo no funciona, se revierte a `sketchLayout` sin problema.

---

## 🚀 Siguiente Paso (después de Fase 2)

Una vez que la mesa nueva esté renderizando sin solapamientos, se evalúa:
- ¿Auth + billetera nube están listos? → siguiente paso
- ¿Hay ajustes visuales pendientes? → Fase 3 completa
- ¿Necesita refinamiento responsivo? → Fase 4 sin rush

La mesa nueva NO bloquea nada. Es un reemplazo visual puro.
