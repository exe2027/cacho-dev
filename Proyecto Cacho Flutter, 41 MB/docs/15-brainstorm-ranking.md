# Brainstorm — Ranking de Cacho

Origen: orden del usuario, 25-oct 05:59 -03. Criterios SUYOS, cerrados como dimensiones (no como fórmula):
1. Por monedas que tiene la persona (saldo actual).
2. Por partidas ganadas.
3. Más un extra de bonus cuando estás en racha, top de racha.

Estado de este documento: BRAINSTORM, no decisión ni construcción. Nada de lo propuesto aquí está aprobado hasta que él lo decida (tribunal mediante, como siempre). No se toca código, no se cambia docs/01, no se despliega.

## Principios (heredados, no se discuten aquí)
- Solo números reales liquidados por el servidor (resultado de partida con pozo real). Nunca una cifra escrita directamente por el cliente.
- En ranking solo apodo + cifras. Nunca correo, nunca UID, nunca saldo de otro jugador fuera del ranking.
- Sin monedas falsas, sin cifras inventadas, sin pay-to-win inventado.
- Ranking necesita cuentas (UID de Firebase): sin auth no hay ranking fiable. Por secuencia, se construye después de auth, no antes.

## Dimensiones (cerradas por él)
- **D1 Monedas:** saldo actual de monedas de la cuenta.
- **D2 Victorias:** partidas ganadas totales (liquidadas por el servidor).
- **D3 Racha:** racha actual de victorias seguidas y racha máxima histórica, con bonus extra por estar en racha.

## Formatos propuestos (A ELEGIR, ninguno decidido)
- **F1 Tres tops separados:** una pantalla Ranking con tres pestañas: Top Monedas, Top Victorias, Top Racha. Ventaja: cada criterio es transparente, sin fórmula que esconder. Desventaja: no hay un "número 1" único.
- **F2 Una tabla única combinada:** un puntaje único por jugador que suma las tres dimensiones. Requiere fórmula, y la fórmula ES decisión suya (ejemplos, NO valores cerrados: puntaje = monedas + victorias × X + racha × Y, con X e Y a elegir; o puntaje solo por victorias con monedas y racha como desempate).
- **F3 Principal + desempates:** ranking principal por monedas, con victorias y racha como desempate e insignias visibles. Ventaja: simple de leer. Desventaja: la racha pesa poco.

## Bonus de racha (propuestas, A ELEGIR)
- **B1 Bonus solo en ranking:** la racha suma puntos de ranking, no monedas. No toca la economía.
- **B2 Bonus en monedas por hitos:** al alcanzar rachas seguidas (ejemplos, NO valores cerrados: 3, 5, 7 victorias seguidas) se otorgan monedas extra. Requiere montos decididos por él, y cuidado: es economía, no solo presentación.
- **B3 Top de racha separado:** tabla aparte de racha máxima histórica y racha actual, sin mezclar con monedas ni victorias.
- **B4 Qué racha cuenta — DECIDIDO por su orden (no se puede farmear con bots):** solo rachas en línea contra humanos. Las partidas locales contra bots, las guiadas gratis y cualquier victoria contra bots (incluido relleno de bots en salas en línea) dan 0 para ranking y racha. Sin tablas separadas para bots: los bots son práctica, no ranking. Detalle de implementación pendiente para la construcción (cómo se reparte el pozo en salas mixtas con bots de relleno, bajo la misma regla: los bots no generan premios).

## Ventana temporal (A ELEGIR)
- **V1 Histórico total:** desde que la cuenta existe. Simple, pero los primeros jugadores quedan inalcanzables.
- **V2 Temporada semanal/mensual + histórico:** un top de la semana/mes que se reinicia y un histórico aparte. Más vivo, más trabajo.
- **V3 Solo histórico por ahora, temporada después:** propuesta mínima para lanzar.

## Empates (A ELEGIR)
- Propuesta: a igual puntaje, primero más victorias, luego mayor racha, luego primero en alcanzar la cifra. Nada cerrado.

## Visibilidad y privacidad (A ELEGIR)
- Propuesta base: visible para todos los jugadores con cuenta, solo apodo + cifras.
- Pendiente: ¿hay opt-out (no aparecer en ranking)? ¿aparecen solo jugadores en línea, o también cuentas inactivas? A elegir por él.

## Recompensas por estar top (A ELEGIR, propuesta inicial: ninguna)
- Propuesta inicial: estar top da solo insignia/título visual, no monedas. Evita farmeo por premio.
- Alternativa: recompensa cosmética (marco, vaso) para el top, nunca monedas inventadas. A elegir por él.

## Datos propuestos en Firestore (técnico, no construido)
- Por UID: saldo monedas, saldo gemas, estadísticas (partidas jugadas, ganadas, perdidas, racha actual, racha máxima), inventario.
- Actualización solo al liquidar una partida en el servidor, nunca desde el cliente.
- El ranking es una consulta ordenada sobre esos campos, no una tabla copiada a mano.

## Pendientes de decisión suya (lista, para tribunal + su sí)
1. Formato: F1 (tres tops), F2 (única combinada) o F3 (principal + desempates).
2. Si F2: fórmula exacta y coeficientes.
3. Bonus de racha: B1 (puntos), B2 (monedas por hitos, con montos), B3 (top separado), o combinación.
4. Hitos de racha, si B2.
5. Ventana: V1, V2 o V3.
6. Local/bots y guiadas: excluidas (B4) o tablas separadas.
7. Recompensas por top: ninguna, cosmética, u otra.
8. Visibilidad: ¿opt-out? ¿inactivos dentro o fuera?
9. Desempate exacto.

## Fuera de alcance
- No se construye ranking en este documento.
- No se cambia la economía (montos de bonus, si los hay, los decide él).
- No se adelanta a auth: ranking se construye después de auth + billetera nube, en la secuencia mesa → auth → tienda, con ranking como parte de las estadísticas de cuenta (no como tienda).
