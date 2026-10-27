# Revisión de repositorios — Diseño final de Cacho

Fecha: 24-oct-2026 (noche). Ronda del diseño final: esto es insumo, no
construcción. No se modificó código, no se desplegó nada, no se clonó
ningún repositorio dentro de `app/`. Regla madre: las referencias son
IDEAS, nunca arte, código, marca ni textos ajenos. Cacho tiene estilo
propio (Cuero y Paño, Casino Dorado, pub chileno).

## A. replica-skill-upstream (11 skills + herramientas Python)

Copia intacta en `~/workspace/replica-skill-upstream/`. Cinco ya están
instaladas adaptadas en `~/workspace/custom-skills/replica-*/` con la
adaptación Cacho al inicio (modo referencia, no clon). Herramientas
verificadas: solo stdlib de Python, sin llamadas de red.

### Instaladas: sirven a esta ronda

| Skill | Veredicto | Uso concreto en el diseño final |
| --- | --- | --- |
| replica-recon | SIRVE | Extraer ideas de las capturas del usuario y páginas públicas. Su `features.csv` es lista de IDEAS CANDIDATAS para el tribunal, no backlog de clon. |
| replica-design | SIRVE | Tokens mapeados a `CachoColors`/`table_themes.dart`; `contrast.py` con piso 4,5:1 (piso del tribunal). |
| replica-diff | SIRVE | Paridad contra LA SENTENCIA (no contra el original); `imgdiff.py` en modo bordes ignora color, así el estilo propio no cuenta en contra. |
| replica-test | SIRVE | Flujos de Cacho (partida local con bots, lobby, consola, Kamikaze a ciegas, desconexión, giro). Ver dados ajenos = S1. |
| replica-brand | SIRVE (modo guardián) | `sweep.py` busca restos de 8BP/Parchisi/Monopoly en el código. NO renombra ni cambia paleta sin orden expresa (Cacho ya tiene marca). |

### No instaladas: veredicto una por una

- **replica-architect — NO instalar.** Sus defaults (Next.js, Supabase,
  Stripe, Vercel) no son el stack de Cacho (Flutter + Workers + billetera
  propia). Lo que SÍ se toma es su método, como lente de planificación:
  vertical slice primero (el bucle central antes que el resto), hard
  constraints primero, y orden must → should → could. El brainstorm del
  diseño final usa esa disciplina; la skill no se instala.
- **replica-build — NO instalar como constructor.** Cacho ya existe y lo
  construye el agente constructor. Lo que SÍ se adopta es su Definition of
  Done por pantalla (todos los estados, 390 px y 1440 px, teclado, cero
  errores de consola, captura para diff) como checklist de entrega del
  diseño final.
- **replica-backend — NO instalar.** Cacho ya tiene servidor, billetera
  por walletToken, sala activa y DJ. La skill es para auth/Stripe/email de
  un clon. Solo se reconoce su checklist de seguridad (validación en
  servidor, segundo usuario invisible), que Cacho ya practica. Nada nuevo.
- **replica-entrepreneur — NO instalar en esta ronda; método adoptado con
  honestidad.** Su valor real sería minería de reseñas públicas de los
  juegos de referencia (100+ reseñas verbales con enlace, 3+ fuentes) para
  saber qué odian sus jugadores. En ESTA ronda no se hizo esa minería
  (exige trabajo de navegador sobre páginas de tiendas, fuera del alcance
  de la revisión) y NO se inventa ningún tema de reseñas. Lo que aporta
  ahora es su lente anti-patrones, que ya coincide con las cercas de
  Cacho: presión pay-to-win, clutter de anuncios, multi-moneda confusa,
  cancelación difícil → Cacho responde con una moneda, sin anuncios, sin
  SALE, apuestas claras. Pase futuro opcional: minería real con evidencia,
  nunca inventada, si el usuario la pide.
- **replica-launch — NO instalar.** Cacho es juego web, sin ficha de
  tienda, sin precios, sin landing. Solo se hereda su regla "no fake
  proof" (que ya es el cero números falsos de Cacho) y la idea de no
  poner claims de ranking. Trivial; no se instala.
- **replica-deploy — NO instalar.** La puerta de despliegue de Cacho es
  manual y exige el "sí" del usuario, que es exactamente la regla de esta
  skill ("nothing goes live without the user's go"). Solo se adopta su
  ritual de preflight (tests, paridad, sweep, build) como checklist a
  correr a mano cuando llegue un despliegue, no como skill instalada.

## B. El propio repo Cacho

Todo sirve; nada se re-juzga salvo conflicto explícito (señalado abajo).

| Documento | Veredicto | Papel en el diseño final |
| --- | --- | --- |
| `docs/01-arquitectura-y-decisiones.md` (decisiones 1–33) | SIRVE | Fuente de verdad de reglas, economía y decisiones. No se toca en esta ronda (tiene cambios sin commitear de otra sesión). |
| `docs/02-guia-de-diseno.md` | SIRVE | Cuero y Paño, paleta, tipografía, mundo pub, Blender (vaso/dados). Base del estilo propio. |
| `docs/05-propuesta-v2-casino.md` | SIRVE | "Noche de casino" A→B→C. Fase A construida; Fase B (tienda) se PRESENTA en el diseño final sin construirse; Fase C queda como está. |
| `docs/06-brainstorm-frontend-8bp.md` | SIRVE | B1–B22 + lista de rechazo previa. Herencia de la Fase A. |
| `docs/07-brainstorm-mesa-horizontal.md` | SIRVE | H/V/P/O/CU + 3 sets de referencias + vasos visibles (H). Base directa del diseño final. |
| `audit/tribunal/sentencia_v2_frontend.md` | SIRVE | Autoridad Fase A: 16 aceptadas, 5 condicionadas, 1 rechazada (B20). |
| `audit/tribunal/sentencia_mesa_horizontal.md` | SIRVE | Autoridad mesa horizontal: camino HORIZONTAL unánime, 20 aceptadas, 17 condicionadas, 1 rechazada (H8). El prototipo en la rama `prototipo-horizontal` es insumo, no rival: la sentencia final lo confirma, ajusta o descarta punto por punto. |
| `app/lib/theme.dart` / `app/lib/table_themes.dart` | SIRVEN | Tokens reales: paño centro `0xFF0B5D3B`, borde `0xFF06402A`, madera `0xFF2B1810`, dorado `0xFFC9A24B`, cueros (café/negro/burdeos/petróleo). Tres mesas: Pub / Dorado / Neón. |
| `app/assets/images/` | SIRVEN | `bg_pub.png` (compuesto PIL, precedente de sala), `felt_bg.png`, vasos Blender (4 colores), dados Blender (6), retratos de bots (5), `wood.png`. NO se toma `bg_pub_raw.png` (plato Blender descartado el 22-oct por plano y lavado). |

### Tensiones que el brainstorm debe resolver (no re-juzgar a ciegas)

1. **Piso de texto 14 px** (sentencia horizontal) contra textos actuales
   de 13/12/10 px (nombre, estado, EN TURNO): el diseño final sube todos
   los textos, no hereda los bajos.
2. **Tarjetas de tier**: P1/P3 (horizontal) y B5/B6 (Fase A) son el mismo
   tema: se consolidan en UNA presentación de tarjetas (fórmula
   "pozo = apuesta × N jugadores", nunca PREMIO, nunca ×N aislado).
3. **Sala PIL**: H14 dice PIL primero y el `bg_pub.png` actual ES el
   precedente PIL que ganó. La sala Dorado sigue esa receta (madera en
   perspectiva + bokeh + luz + viñeta), no inventa un estilo nuevo.
4. **Vertical congelado**: V1–V5 quedan documentadas para un futuro cambio
   de camino; el diseño final NO mejora el vertical en paralelo.
5. **Prototipo en curso**: la rama `prototipo-horizontal` construye el
   alcance de la sentencia horizontal. El diseño final lo toma como punto
   de partida y solo lo ajusta donde la sentencia final diga.

## C. Repositorios externos (búsqueda acotada en GitHub)

Criterio: licencia compatible con mirar ideas (no copiar código), aporte
concreto al diseño final, y qué NO se toma. Si ninguno cambiara el diseño,
se dice.

### Sirven parcialmente (ideas, nunca código)

- **PokerTH** (`github.com/pokerth/pokerth`, AGPL-3.0, C++/Qt, hasta 10
  jugadores, cliente web/PWA desde 2026). SIRVE PARCIAL como referencia de
  composición: mesa grande con muchos asientos, modelo espectador y
  rejoin. Lo que se toma: la lección de mesa grande (10 asientos) y que
  espectador y rejoin ya existen en Cacho (Fase C y sala activa). NO se
  toma: código (C++ no es Flutter y AGPL es viral: copiarlo obligaría a
  licenciar en consecuencia), arte Qt, chat ni ranking.
- **ofc-app** (`whywaita/ofc-app`, MIT, Flutter, póker chino abierto).
  SIRVE como confirmación de arquitectura: dominio puro en Dart +
  aplicación Flutter fina, con tests separados. Cacho ya hace eso
  (`packages/cacho_engine` + `app/`), así que confirma, no añade. NO se
  toma: estilo Material teal, ni el juego OFC (no es Dudo).
- **Flutter Casual Games Toolkit** (plantillas oficiales de Flutter,
  incluida plantilla de juego de cartas). SIRVE PARCIAL como checklist de
  completitud: menú, navegación, ajustes, sonido, temas, hooks
  multijugador. Cacho ya tiene casi todo eso. NO se importa código ni
  plantilla: pelearía con la arquitectura existente.

### Evaluados y rechazados (sin rellenar)

- `measured_card_table` (pub.dev): widgets de alineación para tablas de
  datos, no para una mesa de juego. NO sirve.
- `card_deck_view` (pub.dev): visor de mazo con gestos, no asientos ni
  mesa. NO sirve.
- Gamify UI Kit y PokerKing (CodeCanyon, de pago): plantillas orientadas
  a clon, con estilo ajeno. NO sirven.
- Pixel Cards & Deckbuilder Kit (itch.io, de pago): arte de terceros.
  Cacho usa sus propios renders Blender. NO sirve.

### Conclusión honesta de la fase 0

Ningún repositorio externo cambia el diseño final. Los que sirven
confirman decisiones ya tomadas (arquitectura separada, mesa grande,
checklist de pantallas) o afinan detalles. El insumo mayor del diseño
final siguen siendo las capturas del usuario, las sentencias vigentes y
los assets propios de Cacho. La ronda continúa con ese material, sin
relleno.
