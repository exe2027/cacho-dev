# Checklist de Validación Visual - Mesa Única v2.1

**Instrucciones:** Ejecuta estas pruebas ANTES de desplegar a producción.

---

## 🚀 Paso 1: Compilar y Ejecutar Localmente

```bash
cd "Proyecto Cacho Flutter, 41 MB/app"

# Limpiar builds anteriores
flutter clean

# Ejecutar en Chrome
flutter run -d chrome --web-port=5000
```

El navegador abrirá en `http://localhost:5000`. Espera a que cargue completamente.

---

## 📱 Paso 2: Validación a 844×390 (Referencia)

**Instrucciones:**
1. Abre DevTools (F12 → Device Emulation)
2. Selecciona "iPad Pro" o personaliza a 844×390
3. Verifica lo siguiente:

### ✅ Checklist de Mesa

- [ ] Mesa **óvalo horizontal** visible (no cuadrada)
- [ ] Paño **negro carbón** (Casino 500) o **verde barrial** (La Taberna según tier)
- [ ] Borde de madera oscuro alrededor del paño
- [ ] Filete dorado (solo visible en Mansión/Club VIP si aplica)
- [ ] **POZO** arriba al centro:
  - [ ] Etiqueta "POZO" + moneda + monto (e.g., "5.000")
  - [ ] Distancia mínima 20 px desde borde superior de mesa
  - [ ] Centrado horizontalmente

### ✅ Checklist de Componentes (6 Jugadores)

**Posiciones esperadas:**
```
          POZO (arriba centro)
            ↓
   RIVAL    RIVAL    RIVAL
 (izq-arr) (arriba) (der-arr)
     ↓       ↓        ↓
   [MESA ÓVALO]
     ↑       ↑        ↑
 (izq-ab)  (abajo) (der-ab)
   RIVAL    RIVAL    RIVAL
              ↓
        YO (abajo centro)
```

Para cada jugador (rival o yo):

- [ ] **Avatar** (círculo) visible y alineado
  - [ ] Avatar rival: 56×56 px
  - [ ] Mi avatar: 64×64 px
  - [ ] Centro dentro del óvalo o en el perímetro
  
- [ ] **Vaso** (rectángulo con forma) junto/bajo avatar
  - [ ] Vaso rival: 56×64 px
  - [ ] Mi vaso: 64×76 px
  - [ ] **SIN SOLAPAMIENTO** con avatar
  - [ ] **SIN SOLAPAMIENTO** con otros vasos
  - [ ] **SIN SOLAPAMIENTO** con pozo
  
- [ ] **Placa** (nombre en blanco) **SIEMPRE DEBAJO** del avatar
  - [ ] Placa rival: 88×34 px (aprox)
  - [ ] Mi placa: 120×24 px
  - [ ] Texto legible sin truncar
  - [ ] **SIN SOLAPAMIENTO** con vaso
  - [ ] **SIN SOLAPAMIENTO** con otros elementos

### ✅ Alineación Crítica

- [ ] **Los vasos NO salen del óvalo** (máximo tocar el borde)
- [ ] **Las placas NO se cortan abajo** (consola inferior a 72 px de distancia)
- [ ] **El pozo NO se solapa** con avatares/vasos superiores
- [ ] **Mi asiento está CENTRADO** horizontalmente
- [ ] **Todos los rivales en posiciones SIMÉTRICAS** (si hay 4, forman un cuadrado)

---

## 📊 Paso 3: Validación a 667×340 (iPad Mini)

**Instrucciones:**
1. Cambia DevTools a 667×340 (o personalizado)
2. **Espera a que la pantalla se refresque** (puede tardar 1-2 segundos)
3. Repite el checklist anterior

### ⚠️ Puntos Críticos en 667

- [ ] Mesa se escala proporcionalmente (más pequeña)
- [ ] **NO hay solapamientos nuevos** por el cambio de tamaño
- [ ] Texto de placas sigue legible
- [ ] Pozo sigue visible y centrado
- [ ] Avatar y vaso siguen alineados
- [ ] Consola inferior NO corta placas

### 📏 Medida de Seguridad
```
Mínima distancia esperada:
- Avatar a borde de óvalo: ≥ 5 px
- Vaso a otro vaso: ≥ 3 px
- Placa a vaso: ≥ 2 px
- Placa a consola: ≥ 2 px
```

---

## 🎮 Paso 4: Validación de Gameplay Básico

**Instrucciones:**
1. Inicia una partida local (2 jugadores mínimo)
2. Verifica que los elementos dinámicos funcionan:

- [ ] Avatar rival mostrado
- [ ] Mi avatar mostrado y diferenciado
- [ ] Vaso con animación (si aplica)
- [ ] Placa se actualiza cuando alguien pierde un dado
- [ ] Pozo se actualiza cuando cambia la apuesta
- [ ] Consola (APOSTAR 1–6, CALZO, DUDO, PASO) funciona normalmente

---

## 🎨 Paso 5: Validación de Tiers (Opcional, pero Recomendado)

Si quieres verificar que cada tier se ve diferente:

**En Home Screen, crea partidas con diferentes apuestas:**

1. **100 (La Taberna):**
   - [ ] Paño **verde barrial** (`#0B5D3B`)
   - [ ] Borde **madera oscura**
   - [ ] Fondo ambiental: Pub con luces cálidas

2. **250 (El Boliche):**
   - [ ] Paño **azul noche** (`#14324A`)
   - [ ] Borde **madera**
   - [ ] Fondo: Pub atenuada

3. **500 (El Casino):**
   - [ ] Paño **negro carbón** (`#171717`)
   - [ ] Borde **filete dorado fino**
   - [ ] Fondo: Taberna difuminada

4. **1000 (La Mansión):**
   - [ ] Paño **púrpura** (`#2E1B3A`)
   - [ ] Borde **doble filete dorado**
   - [ ] Fondo: Oscuro con viñeta

5. **2500 (Club VIP):**
   - [ ] Paño **bronce** (`#4A3512`)
   - [ ] Borde **doble filete cian/dorado**
   - [ ] Fondo: Casi negra con animación

---

## 📸 Paso 6: Captura de Pantalla Comparativa

**Compara lado a lado con 8 Ball Pool:**

1. En tu navegador, abre dos tabs:
   - Tab 1: `localhost:5000` (tu Cacho)
   - Tab 2: 8 Ball Pool en navegador (busca "8 ball pool online")

2. Captura ambas pantallas a 844×390

3. Guarda ambas imágenes en `audit/comparativas/`

4. Verifica visualmente:
   - [ ] Forma de mesa similar (óvalo)
   - [ ] Distribución de jugadores similar
   - [ ] Pozo en posición similar
   - [ ] Ningún solapamiento visible

---

## 🔴 Problemas Críticos (Si Ves Esto, NO Despliegas)

### ❌ DETENER SI VES:
- Vasos solapándose entre sí
- Avatar sobresaliendo mucho del óvalo
- Placa cortada por consola
- Pozo solapando con avatares
- Texto ilegible por compresión

### ⚠️ REVISAR SI VES:
- Espacios raros entre vasos (≥10 px)
- Placa descentrada respecto a avatar
- Color distinto al esperado (verificar tier)
- Animaciones cortadas (puede ser browser, no código)

---

## ✅ Paso 7: Aprobación Final

**Si pasaste todos los checks:**

```
✅ 844×390        → Sin solapamientos
✅ 667×340        → Sin solapamientos
✅ Tiers visibles → Decoración diferente, misma geometría
✅ Gameplay       → Elementos interactivos funcionan
✅ Comparativa    → Parecido a 8 Ball Pool
```

**APROBADO PARA DESPLIEGUE.** Procede a:

```bash
flutter build web --release
# Copia build/web/* a tu servicio de hosting
```

---

## 📋 Comando Rápido para Generar Reportes

Si quieres un reporte automático:

```bash
# En la carpeta app/
flutter test --exclude-tags skip 2>&1 | tee audit/reporte_test_final.txt
flutter analyze 2>&1 | tee audit/reporte_analisis_final.txt
flutter build web --release 2>&1 | tee audit/reporte_build_final.txt
```

Esto generará tres archivos de log que puedes guardar en `audit/` como referencia.

---

## 🎯 Resumen Mínimo (5 min)

Si no tienes tiempo para todo, verifica esto:

1. Ejecuta `flutter run -d chrome`
2. Abre 844×390 y verifica:
   - [ ] Óvalo visible
   - [ ] 6 jugadores sin solapamientos
   - [ ] Pozo arriba al centro
3. Redimensiona a 667×340
   - [ ] Todo se escala, sin quebrantos
4. Compara con 8 Ball Pool
   - [ ] Parecido sin copiar

Si todo OK → **LISTO PARA DESPLEGAR**

---

## 📞 Si Algo Falla

1. **Recompila:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

2. **Revisa logs:**
   ```bash
   flutter run -d chrome -v 2>&1 | tail -100
   ```

3. **Contacta** con detalles:
   - Resolución donde falla
   - Screenshot
   - Navegador y versión
   - Mensaje de error exacto
