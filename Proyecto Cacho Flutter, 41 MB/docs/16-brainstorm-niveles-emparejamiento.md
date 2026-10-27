# Brainstorm — Niveles, experiencia y emparejamiento de Cacho

Origen: orden del usuario, 25-oct 06:02 -03. Decisiones SUYAS, cerradas como marco (no como números finales):
- Hay niveles, hasta el **300** (tope).
- **Por cada partida ganada sube la experiencia (XP).**
- Al emparejarte, te emparejan con jugadores **de tu nivel**.
- Hay un **top de nivel** (además de los tops de ranking de docs/15).

Estado: BRAINSTORM, no decisión de fórmula ni construcción. Los números de este documento son PROPUESTAS con sus cuentas hechas, para que él elija el ritmo. No se toca código, no se cambia docs/01, no se despliega.

**DEFERIDO por su orden, 25-oct 06:06 -03: la función de emparejamiento se hace MÁS ADELANTE, no ahora y no en la secuencia mesa → auth → tienda. Este documento queda guardado para entonces; niveles/XP/top siguen solo como brainstorm hasta que él ordene su construcción.**

## Principios (heredados)
- Solo victorias liquidadas por el servidor dan XP. Nunca XP escrita por el cliente.
- Sin XP falsa, sin niveles inventados. El nivel se calcula siempre desde XP real acumulada.
- Nivel necesita cuentas (UID de Firebase): sin auth no hay nivel fiable. Se construye después de auth, no antes.
- La partida en vivo sigue igual: nivel y emparejamiento no cambian las reglas del Dudo.

## Fórmula propuesta (estructura, no ritmo cerrado)
- XP por victoria: **100 XP base** (referencia; si cambia la base, cambian los totales en la misma proporción, lo que importa son las victorias necesarias).
- XP por derrota: **0 XP** (fiel a su orden: sube por ganar, no por jugar). Alternativa a elegir: pequeña XP por participar (ejemplo 10 XP) — cambia el sentido del nivel de "ganador" a "jugador habitual".
- XP acumulada para alcanzar el nivel L: **XP(L) = C × L × (L−1)**, con C a elegir (el ritmo).
- XP para subir de L a L+1: **XP_next(L) = 2 × C × L** (crece con el nivel: al principio rápido, al final lento; sin tablas, se calcula con la fórmula).
- Nivel 1 empieza en 0 XP. Tope 300: al llegar, se queda en 300 (propuesta inicial: sin prestigio; prestigio — reiniciar con insignia — queda como alternativa a elegir, no por defecto).

## Ritmos propuestos (A ELEGIR — lo que cambia es C, y con él, las victorias necesarias)
Referencia: victoria = 100 XP. "Días" calculados a 5 victorias/día (jugador habitual); a 10 victorias/día, la mitad.

### Opción A — C = 5 (ritmo medio-largo)
- Total a nivel 300: 448.500 XP = **4.485 victorias** (~897 días a 5/día, ~2,5 años).
- Hitos: nivel 10 = 450 XP (5 victorias); nivel 50 = 12.250 XP (123 victorias, ~25 días); nivel 100 = 49.500 XP (495 victorias, ~99 días); nivel 200 = 199.000 XP (1.990 victorias, ~398 días).
- Subida inicial rápida: 1 victoria ya deja cerca del nivel 5. Sensación de progreso inmediata, pero los primeros niveles pasan muy rápido.

### Opción B — C = 10 (ritmo largo, tope de verdad lejano)
- Total a nivel 300: 897.000 XP = **8.970 victorias** (~1.794 días a 5/día, ~5 años).
- Hitos: nivel 10 = 900 XP (9 victorias); nivel 50 = 24.500 XP (245 victorias, ~49 días); nivel 100 = 99.000 XP (990 victorias, ~198 días); nivel 200 = 398.000 XP (3.980 victorias, ~796 días).
- Subida inicial más gradual: 1 victoria = nivel 3, 2 victorias = nivel 4. Menos "salto" inicial, tope más prestigioso.

### Qué NO se propone como cerrado
- No se propone bonus de XP por racha en este documento (la racha ya tiene su bonus en ranking, docs/15; duplicarlo aquí sería doble premio sin decisión).
- No se propone XP extra por apuesta alta ni por vencer a nivel mayor, salvo que él lo pida: son opciones (ver pendientes), no base.

## Bonus de XP (opciones, A ELEGIR, ninguna por defecto)
- **X1 Sin bonus:** toda victoria = 100 XP, da igual rival y apuesta. Simple y transparente.
- **X2 Bonus por rival mayor:** vencer a un jugador de nivel mayor da XP extra (ejemplo, no cerrado: +10 XP por cada 10 niveles de diferencia, con tope). Premia el riesgo, complica la fórmula.
- **X3 Bonus por apuesta:** victoria en tier alto da más XP que en tier bajo. Riesgo: empuja a apostar alto solo por XP.

## Qué victorias dan XP (integridad, propuesta fuerte)
- **DECIDIDO por su orden (no se puede farmear con bots): solo victorias en línea contra humanos** dan XP. Locales contra bots, guiadas gratis y victorias contra bots de relleno en línea dan **0 XP**. Sin XP reducida contra bots ni tope alternativo: los bots son práctica, no progreso.
- Consecuencia a tener en cuenta al construir (no cambia la regla): al lanzar, con pocos humanos en línea, subir costará más. Eso se resuelve con emparejamiento y con la comunidad, no relajando la regla de bots.

## Emparejamiento por nivel (A ELEGIR — punto crítico con pocos jugadores)
Hoy Cacho NO tiene cola de emparejamiento: se juega por sala con código / anfitrión que crea. Emparejar por nivel es una funcionalidad nueva (cola, espera, búsqueda), no un filtro sobre lo que existe.

- **M1 Suave (recomendada para lanzar):** el sistema PREFIERE tu nivel (±5, luego ±10, luego ±20 según espera), pero nunca bloquea la partida. El nivel se muestra como insignia. No te quedas sin jugar por falta de rivales de tu nivel.
- **M2 Dura con expansión por tiempo:** solo mismo rango al inicio, y la búsqueda se amplía con el tiempo (ejemplo: ±5 los primeros 10 s, ±10 a los 30 s, ±20 a los 60 s). Si sigue sin rival, se rellena con bots de nivel similar (bots sin XP o con XP reducida, a elegir).
- **M3 Por rangos, no por nivel exacto:** rangos amplios en vez de nivel exacto (ejemplos, NO cerrados: 1–50, 51–100, 101–200, 201–300, o con nombres). Más fácil de emparejar, menos preciso.
- Pendiente: ¿emparejamiento solo en línea con cola nueva, o también filtro al unirse a salas por código? A elegir.

## Top de nivel (nuevo top, además de docs/15)
- Orden: nivel descendente, luego XP dentro del nivel, luego victorias como desempate (propuesta).
- Visible: apodo + nivel + (opcional) XP actual dentro del nivel. Nunca correo ni UID.
- Es el cuarto top junto a Monedas, Victorias y Racha (docs/15), o una pestaña más de la misma pantalla Ranking — a elegir presentación, el dato es el mismo.

## Recompensas por subir de nivel (A ELEGIR, propuesta inicial: ninguna económica)
- Propuesta inicial: subir de nivel da solo insignia/título visual, no monedas ni gemas. Evita que el nivel se convierta en farmeo de economía.
- Alternativas: título por rangos (ejemplos, NO cerrados: nombres por tramos), marco cosmético al llegar a hitos (50, 100, 200, 300), o bonus de monedas en hitos (montos a decidir por él, con cuidado económico).

## Datos propuestos en Firestore (técnico, no construido)
- Por UID: xpTotal, level (derivado de xpTotal por fórmula, no guardado a mano), stats de victorias, racha.
- El nivel nunca se escribe directo: se deriva de XP acumulada. Si XP y nivel discrepan, manda XP.
- Actualización solo al liquidar una victoria en el servidor.

## Pendientes de decisión suya (lista, para tribunal + su sí)
1. Ritmo: Opción A (C=5, ~4.485 victorias a 300) u Opción B (C=10, ~8.970 victorias), u otro C.
2. XP por derrota: 0 o pequeña por participar.
3. Bonus de XP: X1, X2, X3 o ninguno.
4. Qué victorias dan XP: solo online, o bots con XP reducida y tope de nivel.
5. Emparejamiento: M1 suave, M2 dura con expansión, o M3 por rangos. Y: ¿cola nueva o filtro en salas?
6. Tope 300: quedarse en 300 o prestigio al llegar.
7. Top de nivel: pestaña aparte o dentro de Ranking.
8. Recompensas por subir: ninguna, título/marco, o monedas en hitos (con montos).
9. Títulos por rangos, si los hay.

## Fuera de alcance
- No se construye nivel, XP, emparejamiento ni top en este documento.
- No se cambian reglas del Dudo, economía ni montos.
- No se adelanta a auth: niveles se construyen después de auth + billetera nube, en la secuencia mesa → auth → tienda, con ranking/niveles como estadísticas de cuenta.
