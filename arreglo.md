# PROMPT — Corregir y mejorar el layout de la mesa de Cacho o Dudo

Necesito que revises y corrijas la interfaz de mi juego web **Cacho o Dudo Chileno**, tomando como referencia principal la imagen del mockup que adjunté. Las demás capturas son referencias secundarias para la calidad visual, los avatares, los elementos de interfaz y el acabado de un juego multijugador.

## 1. Problema actual

La implementación actual tiene errores importantes de composición y posicionamiento:

- Todos los jugadores aparecen agrupados en el centro de la mesa, en lugar de distribuirse alrededor de ella.
- Los vasos están colocados de manera incorrecta y no corresponden visualmente a la posición de cada jugador.
- Algunos avatares, vasos y etiquetas de nombres se superponen o están demasiado cerca unos de otros.
- Los jugadores de la parte superior e inferior quedan mal alineados con la mesa; el jugador inferior incluso aparece parcialmente cortado.
- Hay mensajes de desbordamiento visibles, como `BOTTOM OVERFLOWED BY 5.0 PIXELS`, que indican que hay elementos que no caben correctamente en su contenedor.
- La mesa ocupa gran parte de la pantalla, pero el espacio de juego no se está aprovechando correctamente.

**No quiero simplemente reducir el tamaño de los jugadores ni moverlos todos unos píxeles. Necesito corregir la lógica de distribución de los asientos y sus elementos asociados.**

## 2. Usar el mockup como referencia principal

Revisa el primer mockup adjunto y reproduce su composición:

- Una mesa ovalada de madera, vista en perspectiva, con una superficie de juego oscura.
- Los jugadores distribuidos alrededor del contorno de la mesa.
- Un vaso de cacho individual asociado a cada jugador.
- Avatares, nombres, indicadores de turno y fichas o puntuaciones ubicados de manera ordenada.
- Una zona central despejada para los dados y los elementos de la partida.
- Una estética de juego multijugador pulida, con buena profundidad, sombras, iluminación y jerarquía visual.

Respeta los elementos gráficos y la identidad visual existentes del proyecto siempre que sea posible. Usa las capturas adicionales como inspiración para mejorar los detalles, pero no copies sus interfaces de otros juegos ni cambies la identidad de Cacho o Dudo.

## 3. Distribución correcta de los jugadores

La mesa debe tener posiciones de asiento definidas alrededor de su perímetro. Para una partida de seis jugadores, utiliza una distribución de referencia como esta:

- **Asiento 1:** centro superior de la mesa.
- **Asiento 2:** sector superior izquierdo.
- **Asiento 3:** sector superior derecho.
- **Asiento 4:** sector inferior derecho.
- **Asiento 5:** centro inferior de la mesa.
- **Asiento 6:** sector inferior izquierdo.

Estas posiciones deben adaptarse a la forma ovalada de la mesa y al espacio real de juego. No se deben distribuir en una cuadrícula ni concentrarse alrededor del centro.

Cada jugador debe mantener una posición estable durante la partida. Cuando cambie la cantidad de jugadores, distribuye los asientos disponibles uniformemente alrededor del perímetro, conservando la simetría y evitando huecos visuales innecesarios.

Si el proyecto permite diferentes cantidades de participantes, comprueba que el diseño funcione con todas las cantidades que realmente admite el juego.

## 4. Los vasos deben corresponder a cada jugador

Este es uno de los puntos más importantes.

Cada asiento debe tener su propio vaso, colocado en la posición que corresponda a ese jugador según el mockup.

- El vaso debe estar visualmente asociado al avatar y al nombre del jugador.
- Los vasos deben seguir el perímetro de la mesa y mantener una separación consistente.
- Los jugadores de la izquierda deben tener sus vasos orientados hacia el interior de la mesa desde su lado.
- Los jugadores de la derecha deben seguir la composición equivalente, sin superponerse a los avatares ni a las etiquetas.
- El jugador superior debe tener su vaso en el sector superior correspondiente.
- El jugador inferior debe tener su vaso en el sector inferior correspondiente, sin quedar cortado por el borde de la pantalla.
- Los vasos no deben aparecer flotando en posiciones arbitrarias ni quedar separados visualmente de sus jugadores.

**Trata el jugador, su avatar, su nombre y su vaso como un conjunto visual asociado a un mismo asiento.** Define las posiciones relativas entre esos elementos para que se muevan juntos y no terminen desalineados.

## 5. Corregir la lógica de posicionamiento

Antes de modificar los estilos, inspecciona el código existente y encuentra la causa real de los errores.

Revisa especialmente:

- El componente que renderiza la mesa.
- El componente o sistema que posiciona a los jugadores.
- La ubicación de los vasos y los avatares.
- Los contenedores, sus dimensiones y sus límites.
- El sistema de coordenadas utilizado para posicionar los elementos.
- Las reglas CSS de `position`, `transform`, `overflow`, `z-index`, anchura y altura.
- Los cálculos que ubican los asientos en función del número de jugadores.
- Cualquier dimensión fija o desplazamiento que provoque errores en otras resoluciones.

Utiliza un sistema de posicionamiento coherente basado en el área real de la mesa, no en coordenadas absolutas arbitrarias de la pantalla.

Puedes utilizar posiciones relativas normalizadas, anclajes calculados o una distribución elíptica de asientos, según la arquitectura del proyecto. Lo importante es que todas las posiciones se calculen de manera consistente.

El vaso debe posicionarse en relación con el asiento correspondiente, no mediante coordenadas independientes que puedan romper la asociación entre jugador y vaso.

No introduzcas una segunda lógica de posicionamiento que entre en conflicto con la actual. Reutiliza y refactoriza los componentes existentes cuando sea conveniente.

## 6. Mejorar la proporción y la composición visual

Ajusta la escala y las distancias para que la mesa se vea equilibrada:

- Aprovecha el área de juego disponible sin cortar sus bordes.
- Mantén los asientos cerca del perímetro interior de la mesa.
- Utiliza avatares suficientemente grandes para reconocer a los participantes.
- Haz que los nombres y las puntuaciones sean legibles, sin competir visualmente con los avatares.
- Evita que los elementos superiores choquen con el indicador del pozo, el turno o la información de la partida.
- Mantén despejado el centro de la mesa.
- Organiza los elementos en capas correctas: superficie de juego, vasos y sombras, avatares, etiquetas e indicadores, según su profundidad visual.
- Evita tamaños excesivos, márgenes innecesarios y elementos desalineados.

El resultado debe parecer una mesa de juego real, coherente y envolvente, no un conjunto de elementos colocados encima de un fondo.

## 7. Corregir los desbordamientos y la adaptación a pantalla

Elimina por completo los errores de desbordamiento visibles.

Comprueba específicamente:

- Que el jugador inferior y su etiqueta se vean completos.
- Que el jugador superior no choque con la cabecera de información.
- Que los vasos no queden fuera de los límites visibles de la mesa.
- Que las etiquetas no se corten ni se superpongan.
- Que los elementos importantes sigan siendo visibles cuando cambie el tamaño de la ventana.
- Que la interfaz se adapte a distintas resoluciones y relaciones de aspecto sin perder la distribución de los asientos.

No resuelvas el problema ocultando los desbordamientos sin corregir la causa. Ajusta las dimensiones y el posicionamiento para que la composición sea válida.

## 8. No romper el juego existente

Esta tarea es principalmente una corrección de interfaz y layout.

Conserva el funcionamiento actual de:

- La lógica de turnos.
- La mecánica de Cacho o Dudo.
- El estado de los jugadores y sus avatares.
- El pozo, las apuestas y las puntuaciones.
- La comunicación multijugador y la sincronización del estado.
- Los indicadores de jugador activo, bot y demás estados de la partida.

No reemplaces información dinámica por textos fijos ni uses jugadores de ejemplo para simular una solución visual.

No reconstruyas toda la aplicación desde cero si es posible corregir los componentes actuales de forma segura.

## 9. Proceso de implementación

1. Inspecciona el proyecto y localiza los componentes responsables de la mesa, los asientos, los vasos y los avatares.
2. Identifica por qué los jugadores se agrupan en el centro y por qué aparecen los errores de desbordamiento.
3. Corrige la distribución de los asientos y vincula correctamente cada vaso con su jugador.
4. Ajusta tamaños, capas, márgenes y escalado para aproximar la composición del mockup.
5. Ejecuta la aplicación y comprueba visualmente el resultado en el navegador.
6. Prueba distintas cantidades de jugadores y diferentes dimensiones de pantalla.
7. Corrige cualquier solapamiento, recorte o desalineación que siga presente.

No te limites a proponer cambios o a entregarme fragmentos de código: implementa las correcciones en los archivos reales del proyecto y verifica el resultado.

## 10. Criterios de aceptación

La tarea se considerará terminada cuando:

- Los jugadores estén distribuidos alrededor de toda la mesa como en el mockup.
- Cada jugador tenga su vaso en el lugar correcto y claramente asociado a su asiento.
- Ningún jugador, vaso o etiqueta se encuentre agrupado accidentalmente en el centro.
- El centro de la mesa permanezca despejado.
- Todos los elementos importantes se vean completos y correctamente alineados.
- No haya mensajes de desbordamiento ni elementos cortados.
- El layout se adapte a diferentes tamaños de pantalla y cantidades de participantes.
- La partida siga funcionando con su lógica y sus datos reales.

**Prioridad absoluta:** primero corregir la distribución espacial y la correspondencia entre jugadores y vasos; después pulir los detalles estéticos. El resultado debe acercarse al mockup original, no ser una versión ligeramente retocada de la distribución defectuosa actual.