Actúa como un ingeniero senior especializado en auditoría de código, refactorización y rendimiento.

REPOSITORIO A ANALIZAR
https://github.com/exe2027/cacho-dev
Proyecto: un juego de mesa.

MODO DE TRABAJO: SOLO ANÁLISIS. NO MODIFIQUES NADA EN ESTA FASE.
No edites, reescribas, borres ni muevas nada de lo escrito. No cambies ninguna funcionalidad existente, ni diseño, ni textos, ni reglas del juego, ni comportamiento, ni interfaz. No despliegues nada.
Tu trabajo es analizar y entregar un plan de refactorización listo para aplicar después, no aplicar los cambios ahora.

PRIMER PASO: INVESTIGA EL PROYECTO EN EL PROPIO REPOSITORIO
Sin asumir nada que no esté en el código, determina y presenta al inicio, en pocas palabras:
1. Stack real: lenguaje(s), framework(s), estructura de carpetas, entry points, dependencias, scripts y cómo se ejecuta el proyecto.
2. Qué hace el juego: objetivo, jugadores, turnos, reglas principales y condición de victoria.
Si algo no está documentado o no se puede determinar desde el repositorio, escríbelo como "no determinado", no lo inventes.

SEGUNDO PASO: AUDITORÍA PARA REDUCIR LA CARGA Y HACERLO MÁS EFICAZ
Busca con evidencia concreta (archivo y línea, o archivo y función) dónde se puede mejorar, sin modificar nada:
1. Redundancias: funciones, componentes, validaciones, lógica de turnos, reglas, renders y estilos duplicados o casi duplicados que se puedan unificar.
2. Código muerto o innecesario: funciones, archivos, imports, variables, assets y dependencias sin uso real, verificando referencias en todo el proyecto antes de afirmarlo.
3. Carga y rendimiento: archivos y módulos más pesados, dependencias grandes usadas para poco, imports de librerías completas, trabajo repetido en cada turno o render, cálculos que se podrían cachear, renders innecesarios, assets sin optimizar y todo lo que se carga al inicio y podría cargarse bajo demanda.
4. Eficiencia del código: funciones demasiado largas, lógica mezclada, bucles y validaciones innecesarias, manejo de estado mejorable y oportunidades de simplificación sin cambiar el resultado.
5. Mantenibilidad: qué partes son más difíciles de mantener hoy y cómo una refactorización las dejaría más claras, sin sobre-ingeniería ni abstracciones innecesarias.

TERCER PASO: PLAN DE REFACTORIZACIÓN PROPUESTO (SIN APLICAR)
Entrega un plan por fases, de mayor impacto y menor riesgo a menor impacto y mayor riesgo, con esta tabla por cada propuesta:
| Qué refactorizar | Evidencia (archivo:línea/función) | Problema actual | Refactorización propuesta | Reducción de carga / ganancia esperada | Esfuerzo | Riesgo para funcionalidades existentes | Cómo verificar que nada cambió |

Y al final del informe:
- Top 5 refactorizaciones que más reducirían la carga con menor riesgo.
- Qué NO conviene tocar y por qué, aunque parezca redundante.
- Resumen estimado antes/después: líneas, archivos y dependencias que se podrían eliminar, y peso/carga que se podría reducir, indicando claramente qué es medido y qué es estimado.
- Lista de verificación final para aplicar el plan después sin romper nada: compilar/ejecutar, probar los flujos principales del juego y comparar el comportamiento antes y después.

REGLAS DURAS
- Nada de lo escrito se modifica en este análisis: ni una funcionalidad, ni un texto, ni el diseño.
- No propongas cambiar reglas del juego, flujos ni experiencia para ganar rendimiento, salvo que lo marques explícitamente como opcional y con su riesgo.
- No afirmes que algo no se usa sin haber buscado referencias en todo el repositorio.
- Si falta información en el repositorio para concluir algo, dilo antes de concluir.