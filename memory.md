# MEMORY — PROYECTO CACHO (El Dudo Chileno)

> **Regla de oro del proyecto:** El usuario es el dueño del proyecto y toma las decisiones finales. Nada se despliega a producción ni se commitea en git sin su aprobación explícita. Todo trabajo se verifica con capturas y pruebas reales.

---

## 1. Decisiones Maestras y Arquitectura (Vigentes)

* **Plataforma Unificada:** **100% FLUTTER** para todos los destinos (Web, iOS de Apple y Android). Se descarta la implementación de gameplay/cliente en Unity para evitar incompatibilidades críticas de WebGL en navegadores móviles (Safari/Chrome), problemas de memoria y duplicación innecesaria de código.
* **Aprovechamiento 3D (Blender):** Los modelos 3D creados en Blender (mesa ovalada de madera, cachos de cuero, dados y monedas) se integran en Flutter como renders, sprites y secuencias animadas de alta fidelidad, obteniendo acabado premium 3D con máxima ligereza y rendimiento a 60 fps.
* **Orientación 100% Horizontal:** Toda la aplicación (Menú Principal, Lobby de Mesas, Ajustes y Mesa de Juego) es horizontal fija (844×390 de referencia). En orientación vertical únicamente se muestra la pantalla de bloqueo solicitando girar el dispositivo.
* **Diseño Objetivo:** 
  - **Mesa de juego:** [`img/mockup.jpeg`](file:///c:/Users/2026/Desktop/cacho/img/mockup.jpeg) (mesa ovalada de 6 posiciones, pozo arriba al centro, consola inferior APOSTAR 1–6 + CALZO + DUDO + PASO, botón de chat flotante y doble indicador de fichas).
  - **Lobby y Menú:** Inspirado en el carrusel horizontal de Monopoly Poker ([`WhatsApp Image 2026-10-26 at 8.09.18 PM (3).jpeg`](file:///c:/Users/2026/Desktop/cacho/img/WhatsApp%20Image%202026-10-26%20at%208.09.18%20PM%20(3).jpeg)) y la progresión arcade limpia de Parchisi Star, adaptado a una atmósfera chilena premium de taberna/casino oscuro (madera, cuero, paño carbón y dorado mate `#C9A24B`).

---

## 2. Lo que se Hizo (Historial y Estado Actual)

1. **Motor de Reglas Puro en Dart (`packages/cacho_engine`):**
   - 77/77 tests unitarios en verde.
   - Reglas chilenas estrictas implementadas:
     - Subida clásica (más cantidad con cualquier pinta, o igual cantidad con pinta mayor).
     - Ases: La primera apuesta nunca puede ser ases (`ases_para_partir`). Entrar a ases exige $\lceil N/2 \rceil$; salir exige $2N + 1$. Los ases son comodines en cualquier otra pinta.
     - Paso: Exige 5 dados (todos distintos o Full). Faroleable. Máx 1 por ronda por jugador, nunca primera jugada, nunca 2 seguidos.
     - Calzo estricto: Recuperación de dado solo si $\text{totalActual} \times 2 > \text{totalInicial}$. Calzo perfecto quita 1 dado a los demás vivos, pero queda bloqueado si el total de dados en juego es bajo ($\le 50\%$).
     - Kamikaze: A ciegas (nadie ve dados hasta elegir número 1 al 6). Quien saque ese número pierde dado.
     - Bots con cálculo de probabilidad binomial exacta y farol según dificultad.

2. **Servidor Autoritativo Node.js + WebSockets / Cloudflare Workers:**
   - 37/37 tests de servidor en verde (verificado con `npm test`).
   - Salas privadas con código, autoridad total de dados (privacidad absoluta: ningún cliente recibe dados ajenos antes de la resolución).
   - Control de turnos de 60 s; 3 vencimientos seguidos = eliminación por abandono.
   - Desconexiones con 60 s de gracia cubiertas por bot.
   - Señalización WebRTC para voz P2P y sincronización de música DJ vía YouTube embebido.

3. **Assets y Modelado 3D (Blender):**
   - Mesa ovalada, vasos de cuero, dados y texturas renderizados en Cycles (Etapa 1 de assets completada).
   - Sprites de tiers de casino integrados (`card_barrio_tall.png`, `card_casino_tall.png`, etc.).
   - Monedas 3D giratorias y paños de mesa de alta resolución.

4. **Lobby / Main Menu Horizontal (Monopoly Poker Style) Completado:**
   - Implementado en `app/lib/screens/home_screen.dart` en formato horizontal puro (844×390).
   - Carrusel horizontal interactivo con `PageController` (viewport 0.38) y escalado animado de cartas por nivel.
   - 6 Tiers chilenos definidos: Tier 0 Tutorial/Guiada, Tier 1 La Taberna ($100), Tier 2 El Boliche ($250), Tier 3 El Casino ($500), Tier 4 La Mansión ($1.000) y Tier 5 El Club VIP ($2.500).
   - Barra superior con doble indicador de moneda (Fichas doradas con moneda 3D + saldo + botón `+`; Fichas verdes cash `$0` + botón `+`), botón de regalo/rescate diario de fichas (+1.000), indicador de conectividad en vivo, y accesos rápidos a sonido/reglas.
   - Barra inferior con cápsula de perfil del jugador (avatar dinámico, saludo, preview del vaso de cuero), accesos a "JUGAR CON AMIGOS", "BUSCAR SALAS" y "CÓMO SE JUEGA".
   - 100% compatible con `widget_test.dart` y validaciones de interfaz.

5. **Mesa de Juego (`game_screen.dart` / `panels.dart` / `mockup.jpeg`) Perfeccionada:**
   - Doble píldora de saldo en barra superior horizontal (fichas doradas con moneda 3D + `$0` verde con `+`).
   - Insignia de Pozo central en la mesa con estética de ficha de casino premium (gradiente azul marino profundo `0xFF162544` a `0xFF0C1322`, aro dorado, icono de moneda y monto nítido).
   - Botón flotante circular de Chat / Emotes (`Icons.chat_bubble_rounded`) a la izquierda de la consola inferior.
   - Hoja modal interactiva `_showQuickChatSheet` con emotes (`😂`, `👏`, `👍`, `😮`, `🔥`) y frases típicas chilenas de Cacho ("¡Dudo que tengas eso!", "¡Te calzo al tiro!", "Pasa la mano...", etc.).
   - Preservados todos los invariantes de 0 solapes en 6 asientos de `sketch_layout.dart` y `ronda4_mesa_test.dart`.

6. **Fondos Progresivos Dinámicos por Tier y Despliegue a Cloudflare Pages:**
   - Fondos atmosféricos diferenciados y progresivos para cada sala en el carrusel de apuestas (desde la taberna rústica de madera hasta el club VIP de mármol obsidiana y oro puro).
   - Despliegue exitoso a producción en Cloudflare Pages: [https://cacho.pages.dev](https://cacho.pages.dev) (Deployment hash `https://6ea79c30.cacho.pages.dev`).
   - Creado script de compilación y despliegue rápido `deploy_pages.ps1`.


---

## 3. Lo que se Va a Hacer (Plan de Ejecución)

### Fase 1: Rediseño del Main Menu y Lobby de Mesas (Horizontal) — [COMPLETADO]
- [x] Carrusel Horizontal de Mesas (Tiers chilenos: La Taberna, El Boliche, El Casino, La Mansión, El Club VIP).
- [x] Tarjetas de Mesa con Estética Casino, sprites tall y botón "JUGAR AHORA" / "PRACTICAR".
- [x] Barra Superior con doble saldo, rescate de fichas y estado online.
- [x] Barra Inferior con perfil, tutorial, amigos y salas privadas.

### Fase 2: Perfeccionamiento y Conexión Total de la Mesa de Juego — [EN PROGRESO]
- [x] Mesa con 6 posiciones sin solapes y sello "CACHO O DUDO".
- [x] Mecánica de Dados Ocultos con botón VER y soporte de agitar.
- [x] Secuencia de revelación con conteo individual y veredicto.
- [x] Consola inferior con tiles 1–6, CALZO verde, DUDO rojo y PASO azul.
- [x] Botón flotante de Chat / Emotes y hoja de frases típicas según `mockup.jpeg`.
- [x] Conectar la selección de mesa del carrusel con la inicialización directa de la partida según el tier seleccionado (deducción de buy-in en Wallet, pozo correspondiente ×6, tema de mesa según tier y número de bots ajustado).
- [x] Soporte de creación directa de sala en línea con un toque ("ONLINE") en cada tarjeta de tier del carrusel.
- [x] Acción de rescate directo (+1.000) en el SnackBar de saldo insuficiente al intentar ingresar a una mesa superior.

### Fase 3: Secuencia Posterior (Auth, Billetera y Progresión)
- [ ] Auth con Firebase (Google y correo sin contraseña).
- [ ] Billetera nube unificada por UID en Firestore.
- [ ] Tienda de cosméticos (vasos personalizados y dados).
- [ ] Sistema de ligas, rankings y niveles (tope 300).

---

## 4. Lo que Está por Hacerse de Inmediato (Siguiente Paso Activo)

1. Presentar al usuario la confirmación del flujo consolidado (Lobby Horizontal estilo Monopoly Poker + Mesa 6 Jugadores estilo `mockup.jpeg` con chat y pozo casino).
2. Revisar con el usuario el siguiente paso prioritario: integración de Firebase Auth / persistencia en Firestore o cosméticos y animaciones 3D.


### Refactorización UI Mesa (2D Isométrica Simétrica y Responsive Layout) - Noviembre 2026
- **Problema previo:** Desalineación 3D/2D con vasos/avatares flotando, ruptura de aspect ratio con franjas negras en pantallas alargadas y coordenadas absolutas fijas en píxeles.
- **Arquitectura de 3 Capas implementada:**
  1. TableBackgroundWidget (pp/lib/widgets/game/table_background_widget.dart): AspectRatio 844:390 + FittedBox.contain, escalado proporcional íntegro de la mesa.
  2. PlayerSlotWidget y TableGameplaySlotsWidget (pp/lib/widgets/game/player_slot_widget.dart): 6 slots con coordenadas relativas porcentuales al tamaño de mesa obtenido por LayoutBuilder. Encapsula avatar, vaso/cacho, dados y saldo.
  3. GameHUDWidget (pp/lib/widgets/game/game_hud_widget.dart): Barra superior (pozo, monedas, silencio, salir) y dock inferior (tiles de dados 1-6, botones CALZO, DUDO, PASO, VER/Agitar) sobre SafeArea.
- **Modularización de Salas:**
  - RoomConfig (pp/lib/models/room_config.dart) y pp/lib/config/room_configs.dart para los 6 tiers (Tutorial, La Taberna, El Boliche, El Casino, La Mansión, El Club VIP).
- **Compatibilidad y Verificación:**
  - 62/62 tests en pp pasando.
  - 80/80 tests en packages/cacho_engine pasando.
  - Cero errores en lutter analyze lib/screens/game_screen.dart.


### Mesa 2D Cenital (Top-Down) Simétrica Estilo 8 Ball Pool / Monopoly - Noviembre 2026
- **Problema previo:** Imágenes de fondo con perspectiva 3D (oblicuas) causaban desalineación de avatares y vasos flotando sobre paredes/cortinas.
- **Mesa 2D Top-Down (Table2DLayoutWidget):**
  - Riel exterior de madera con radio amplio (forma estadio / superelipse BorderRadius.circular(railHeight * 0.48)).
  - Bisel dorado y paño de fieltro interior con iluminación cenital radial centrada exactamente en Offset(width/2, height/2).
  - Color y assets adaptados dinámicamente según RoomConfig por tier.
- **Sistema de 6 Slots Fijos en Coordenadas Normalizadas (%):**
  - Slot 0: Jugador Principal (Abajo Centro - 50% X, 85% Y)
  - Slot 1: Bot 1 (Abajo Izquierda - 18% X, 68% Y)
  - Slot 2: Bot 2 (Arriba Izquierda - 18% X, 25% Y)
  - Slot 3: Bot 3 (Arriba Centro - 50% X, 12% Y)
  - Slot 4: Bot 4 (Arriba Derecha - 82% X, 25% Y)
  - Slot 5: Bot 5 (Abajo Derecha - 82% X, 68% Y)
- **Alineación Estricta de Vasos y Avatares (PlayerSlotWidget):**
  - Mitad inferior (Slots 0, 1, 5): Vaso **ARRIBA** del avatar (hacia el interior del paño).
  - Mitad superior (Slots 2, 3, 4): Vaso **ABAJO** del avatar (hacia el interior del paño).
- **Zona Central Limpia:**
  - Pozo central acumulado con insignia dorada.
  - Placa de apuesta actual con dado gráfico, cantidad y nombre de jerga chilena.
- **Validación:**
  - 62/62 tests pasando en pp.
  - 80/80 tests pasando en cacho_engine.
  - lutter build web exitoso y servido en http://localhost:8080.
