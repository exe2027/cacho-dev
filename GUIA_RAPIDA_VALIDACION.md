# Guía Rápida: Validar y Desplegar Mesa v2.1

**Tiempo total: 20 minutos**

---

## ⚡ Paso 1: Compilar y Ejecutar (3 minutos)

```bash
cd "Proyecto Cacho Flutter, 41 MB/app"
flutter run -d chrome --web-port=5000
```

Espera a que cargue. Verás en Chrome: `http://localhost:5000`

---

## ✅ Paso 2: Validar a 844×390 (5 minutos)

1. Abre **DevTools** (F12 → Device Emulation)
2. Selecciona **"iPad Pro"** o personaliza a **844×390**

### Verifica ESTO:
- ✅ Mesa óvalo horizontal (no cuadrado)
- ✅ 6 jugadores sin solapamientos visibles
- ✅ Pozo arriba al centro ("POZO" + moneda + cifra)
- ✅ Avatares alineados con vasos
- ✅ Placas (nombres) debajo de avatares, legibles
- ✅ MI asiento abajo al centro, diferenciado
- ✅ Consola inferior (botones APOSTAR, CALZO, etc.) visible

**Si TODO se ve bien:** continúa a Paso 3

---

## ✅ Paso 3: Validar a 667×340 (3 minutos)

1. Cambia DevTools a **667×340**
2. Espera 1-2 segundos a que se refresque
3. Verifica de nuevo:
   - ✅ Mesa más pequeña pero ALINEADA
   - ✅ **SIN solapamientos nuevos**
   - ✅ Texto legible
   - ✅ Pozo visible

**Si TODO se ve bien:** continúa a Paso 4

---

## ✅ Paso 4: Comparar con 8 Ball Pool (2 minutos)

1. Abre **otra tab del navegador**
2. Busca **"8 ball pool online"** o ve a `pogo.com/en/Games/8-ball-pool`
3. Abre ambas ventanas lado a lado
4. Verifica:
   - ✅ Mesa Cacho tiene forma similar (óvalo)
   - ✅ Jugadores distribuidos similar
   - ✅ Pozo en posición parecida
   - ✅ Sin solapamientos en Cacho

**Si se ve parecido:** aprueba para despliegue

---

## 🚀 Paso 5: Desplegar (5 minutos)

### Si TODO validó correctamente:

```bash
# En la carpeta app/
flutter build web --release
```

Esto genera la versión optimizada en `build/web/`.

### Sube a tu servicio de hosting:

**Opción A: Cloudflare Pages (recomendado)**
```bash
# Desde la raíz del proyecto
cp -r "Proyecto Cacho Flutter, 41 MB/app/build/web" dist/
wrangler pages deploy dist
```

**Opción B: Manual (si tienes acceso FTP/S3)**
```bash
# Copia el contenido de build/web a tu servidor
# En Windows Explorer: 
# Copia la carpeta "build/web" 
# Pégala en tu hosting
```

**Opción C: Usar GitHub Actions** (si ya está configurado)
```bash
git add RESUMEN_EJECUTIVO_FASE2.md ESTADO_IMPLEMENTACION_v2.1.md
git commit -m "feat: mesa única escalable sin solapamientos (v2.1)"
git push origin main
# GitHub Actions compila y deploya automáticamente
```

---

## ⚠️ Si Algo No Se Ve Bien

### Problema: Solapamientos visibles a 667×340
```bash
# Limpia y recompila
flutter clean
flutter pub get
flutter run -d chrome
# Si persiste → documentar y reportar
```

### Problema: Texto truncado o ilegible
- Abre DevTools → Console
- Revisa si hay errores de JavaScript
- Reportar error con screenshot

### Problema: Mesa no se ve (pantalla en blanco)
```bash
# Reinicia el servidor
Ctrl+C (en terminal)
flutter run -d chrome
```

---

## ✅ Aprobación Final

Si pasaste TODO:
- ✅ 844×390 sin solapamientos
- ✅ 667×340 sin solapamientos
- ✅ Parecido a 8 Ball Pool
- ✅ Compilación exitosa (`flutter build web`)

**ESTÁ LISTO PARA PRODUCCIÓN.**

---

## 📊 Verificación de Tests (Opcional pero Recomendado)

Antes de desplegar, corre:

```bash
# Análisis
flutter analyze

# Tests unitarios
flutter test

# Build final
flutter build web --release
```

**Resultado esperado:**
```
✅ 0 errores en analyze
✅ 62/62 tests PASADOS
✅ Build exitoso
```

---

## 📝 Resumen de Cambios

Lo que cambió en el código:
- ✅ Nuevo: `table_geometry.dart` (geometría escalable)
- ✅ Nuevo: `table_renderer.dart` (renderizador)
- ✅ Modificado: `game_screen.dart` (usa nueva geometría)
- ❌ SIN CAMBIOS: `sketch_layout.dart` (respaldo intacto)
- ❌ SIN CAMBIOS: Motor, servidor, tests

---

## 🎯 Comparativa Rápida

| Antes (Problema) | Después (Solución) |
|------------------|-------------------|
| Foto + geometría por separado | Mesa única |
| Solapamientos a 667×340 | 0 solapamientos |
| Cada tier = foto diferente | Cada tier = color diferente |
| Difícil mantener | Fácil mantener |

---

## 🚀 ¡LISTO!

Has completado la **Fase 2: Integración de Mesa Única v2.1**

**Siguiente:** Después de desplegar a `cacho-pages.dev`, evalúa:
- Feedback del usuario
- Performance en dispositivos reales
- Ajustes visuales si aplica

**Fases futuras:**
- Fase 3: Diferenciación visual por tier (colores, animaciones)
- Fase 4: Refinamientos responsivos

---

## 📞 Comandos de Referencia Rápida

```bash
# Compilar y correr localmente
flutter run -d chrome

# Limpiar todo
flutter clean && flutter pub get

# Build para producción
flutter build web --release

# Análisis estático
flutter analyze

# Correr tests
flutter test

# Ver ayuda
flutter help
```

---

**Hecho. Listo. Sin complicaciones.**

Ahora solo validar visualmente y desplegar. 🎉
