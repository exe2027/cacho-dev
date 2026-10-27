# PROMPT DEL PROYECTO CACHO — para que otra IA entienda qué estamos haciendo

Fecha del prompt: 26 de octubre de 2026. Idioma de trabajo: español (Chile).
Este documento resume el proyecto, su estado real y sus reglas cerradas. Si algo aquí
contradice un documento del proyecto, manda lo que el usuario diga después.

## 1. Qué es Cacho

Cacho es el juego chileno del Dudo (mentir con dados dentro de un vaso de cuero),
en versión web y en versión Unity en paralelo. El usuario es el dueño del proyecto
y toma todas las decisiones finales, muchas veces en una o dos palabras. Nada está
aceptado hasta que él lo dice, y nada se despliega ni se commitea sin su sí explícito.

## 2. Estado real al 26-oct-2026 (no inventar otro)

- **Flutter web (la versión principal):** app Flutter (Dart) + motor puro en Dart +
  servidor Node.js con WebSockets, autoritativo. Producción:
  https://cacho.pages.dev y wss://cacho-server.vikingosfoodspa.workers.dev
  (salud: /health, Durable Object v3). La producción sigue siendo el diseño del
  25-oct ~02:24. Todo lo posterior es local, sin desplegar y sin commitear.
- **Unity (versión paralela):** etapa 1 entregada: mesa en Blender (Cycles) +
  esqueleto de escena en texto, SIN Editor instalado, SIN build y SIN link WebGL.
  Bloqueo duro: falta activar la licencia Personal de Unity (lo hace el usuario
  en su navegador, ~5 min). El link WebGL futuro es solo para mirar el diseño,
  nunca para juzgar rendimiento, y nunca en cacho.pages.dev.
- **APK Android de Flutter: DESCARTADA por orden del usuario.** No se reintenta.
- **Comparación con el ejemplo (en curso, ronda 4):** 10 agentes compararon ambos
  diseños contra la imagen ejemplo del usuario (mesa ovalada, 6 jugadores, pozo
  arriba al centro, consola APOSTAR 1–6 + CALZO + DUDO + PASO). Resultado ronda 3:
  Flutter 8,5/10, Unity 8,0/10. Se parece mucho, no es idéntico. La ronda 4 cierra
  lo cerrable sin decisión del usuario.
- **Tribunal ronda 2 (12:43, solo asesora):** aceptadas la consola y las reglas en
  Flutter; condicionado todo lo demás. La sentencia está en
  audit/tribunal/sentencia_mesa_ronda2.md.

## 3. Stack y archivos

- Flutter 3.47.7, Dart 3.13.6. Motor: packages/cacho_engine/ (tests con dart test).
  Servidor: server/ (tests con npm test, ~3 min). App: app/ (flutter test).
- Documentos del proyecto (van dentro del zip): docs/01 a docs/19.
  - docs/12: master prompt de mesa + animaciones (autoridad visual, solo web).
  - docs/17: master prompt "CACHO, EL DUDO CHILENO" (la imagen ejemplo es el
    DISEÑO OBJETIVO, no una inspiración).
  - docs/18: master prompt casino animado (Unity + Blender, etapas 1–7).
  - docs/19: casos de paridad Flutter–Unity (lista de aceptación A/P/C/K/G/V/N).
- La imagen ejemplo del usuario manda sobre la sentencia del rediseño para la
  mesa. Método obligatorio antes de decir "listo": comparar lado a lado contra
  el ejemplo, corregir, recapturar y listar las diferencias restantes.

## 4. Reglas del juego (cerradas, no se cambian sin su orden)

- Subida clásica: se sube cantidad con cualquier pinta, o igual cantidad con
  pinta mayor. Nunca se baja cantidad ni pinta a igual cantidad.
- Ases: se entra con al menos la mitad redondeada hacia arriba, se sale con el
  doble más uno; dentro de ases solo sube la cantidad; al resolver una apuesta
  de ases solo cuentan los 1 reales; en cualquier otra apuesta los 1 son
  comodines. Se puede desactivar por sala.
- **La primera apuesta de la ronda NUNCA puede ser ases** (error ases_para_partir).
- Quien pierde un dado parte la ronda siguiente; si nadie perdió (Calzo exitoso),
  parte quien calzó; si fue eliminado, el siguiente vivo en sentido horario.
- Toda resolución (Dudo, Calzo, duda de Paso) termina la ronda; todos vuelven
  a tirar.
- Paso: solo lo puede desafiar el jugador siguiente; si este sigue jugando, el
  Paso queda firme para siempre; con dos Pasos seguidos solo se puede desafiar
  el último. Mano de Paso: 5 dados todos distintos (el 1 vale como 1, sin
  comodines) o Full (exactamente 3+2). El Paso puede declararse falso (bluff);
  solo el desafío lo verifica. El Paso exige 5 dados.
- **Límites de Paso (reglas del usuario):** máximo 1 Paso por jugador por ronda;
  prohibido como primera jugada de la ronda; prohibido dos veces seguidas por
  el mismo jugador.
- **Calzo (regla vigente, estricta):** se calza siempre, pero se recupera dado
  solo si totalActual × 2 > totalInicial (estricto, más de la mitad, NO "al
  menos la mitad"). totalInicial = jugadores al inicio × dados por jugador,
  fijo. Ejemplo del usuario: 4 jugadores = 20 iniciales; con 11 se recupera,
  con 10 o menos no. Exacto con total bajo: no se gana ni se pierde, termina la
  ronda y parte quien calzó. Inexacto: siempre se pierde.
- **Calzo perfecto:** calzo exacto con 5 dados → quien calza no gana nada y
  todos los demás vivos pierden 1 dado. Solo apuesta Calzo, no CalzoPaso.
  **Pero bloqueado con total bajo:** si totalActual × 2 ≤ totalInicial, el
  calzo exacto no da ni quita nada y el perfecto NO quita dados a los demás.
- Kamikaze: se ofrece entre rondas la primera vez que un jugador termina una
  resolución con exactamente 1 dado siendo el único en 1 y sin oferta previa.
  Aceptar = ronda especial que reemplaza la normal; rechazar = perdido para
  siempre. Si dos llegan a 1 a la vez, nadie recibe oferta y no se consume.
  **Kamikaze es A CIEGAS:** nadie, ni quien activa, ve ningún dado hasta que
  elige el número; los dados son una tirada nueva al elegir. Todos en 0 a la
  vez = empate.
- Comodines: los 1 cuentan como la pinta apostada salvo en apuestas de ases;
  nunca comodines en Paso ni Kamikaze; desactivables por sala.
- Presets: Clásico = sin Paso, sin Kamikaze, con Calzo, con comodines.
  Cacho completo = todo activado.
- Pintas: 1=As, 2=Pato, 3=Tren, 4=Cuadra, 5=Quinta, 6=Sexta.
- Turno 60 s: si vence, juega un bot; **3 vencimientos seguidos = eliminación
  inmediata** (abandono). Desconexión en partida: aviso a toda la mesa, bot
  cubre, 60 s de gracia para volver; si no vuelve, eliminado.
- Partida 1: sorteo por dado mayor, empates repiten, visible ("Sorteo: parte X").
- **Jugadores: 2 a 6 en ambas versiones, asientos vacíos libres.** En línea, al
  iniciar el anfitrión elige completar con bots o jugar con los presentes.
- **Mis dados: ocultos bajo mi vaso, se ven solo con VER. Agitar el teléfono
  TIRA los dados; VER los mira.** Son funciones distintas.
- **Dados al centro en cualquier resolución** (Dudo, Calzo, duda de Paso,
  Kamikaze). En duda de Paso, solo la mano del jugador del Paso.
- Sin textos narrativos en partida; veredictos en una frase corta (solo la
  consecuencia). Música de casino procedural + efectos; voz WebRTC (micrófono
  apagado por defecto, sin TURN, solo STUN); DJ de YouTube en sala (solo el DJ
  maneja la cola).
- **Chat de texto: FUERA. Reacciones rápidas (emotes) con animación: DENTRO.**
  Micrófono (voz) y música se mantienen, nunca se eliminan.
- Bots: nombres fijos (El Guatón, La Cuca, Don Chalo, La Pituca, El Huaso,
  La Rusa, El Flaco, La Morocha, Don Lucho, El Pije, La Juanita, El Rucio).
  **Ninguna victoria contra bots da premios de cuenta nube: 0 XP, 0 ranking,
  0 racha, 0 monedas nube.** Tampoco en salas en línea con bots de relleno.

## 5. Diseño vigente (visual, no reglas)

- Mesa: óvalo horizontal, madera gruesa, paño oscuro con textura (el de Casino
  500 es carbón definitivo), borde con filete, vaso de cuero por jugador con
  posavasos, el mío más grande y abajo al centro, pozo arriba al centro con
  monto real, logo "CACHO O DUDO" al centro, dados sueltos al centro SOLO al
  revelar. Distribución con 6: 1 arriba al centro, 2 a cada lado, yo abajo.
  Cero solapes medidos. Placas bajo cada avatar, dentro del óvalo.
- Consola inferior única: APOSTAR con tiles 1–6 (tocar para contar) + CALZO
  verde #0E7A4F + DUDO rojo #B3202A + PASO azul #14586B. Dorado mate #C9A24B.
  Textos ≥14 px, objetivos ≥44 px, contraste ≥4,5:1.
- Barra superior: SOLO lo que ya existe y funciona (salir, saldo, pozo,
  ajustes, historial, música/DJ, micrófono). Sin segunda moneda, sin "+" de
  compra, sin regalo, misiones, amigos, corona, LVL, gemas ni SALE como botones
  muertos: eso es decisión pendiente del usuario (P6), no se inventa.
- Menús casino, no café: fondos oscuros + dorado mate. La mesa de madera no cambia.
- Todo el juego en horizontal (844×390 de referencia); en vertical solo un
  aviso de girar el celular, sin layout vertical detrás.
- Avatares: Blobatar para todos en Flutter (determinista por nombre, sin fotos
  generadas). En Unity el arte de avatar está pendiente.
- Animaciones: 70% en web fuera de partida; en partida solo información
  (semáforo, barra, pitidos). La animación AN15 (barrido de turno) está
  RECHAZADA y no se reintroduce. Todo apagable con animationsEnabled, salvo
  semáforo, barra y pitidos.
- **Revelación legible (orden del usuario):** la presentación con todas las
  manos en pequeño al centro está RECHAZADA porque no se alcanzan a leer. Todo
  dado mostrado debe leerse a tamaño real, sin solapes, contando uno a uno.
- Cero números falsos: sin jugadores, saldos, estrellas, niveles ni salas
  inventadas. Los datos del ejemplo (nombres, cifras) son maqueta, nunca se
  copian como datos reales ni como nombres/caras del juego.

## 6. Economía (montos aprobados)

- Cuenta anónima actual: 5.000 monedas al crear el perfil. Apuesta por jugador:
  100 / 250 / 500 / 1.000 / 2.500 (defecto 500), la elige el anfitrión en línea.
  Pozo = apuesta × jugadores, el ganador se lo lleva todo, sin comisión.
  Empate = devolución. Salir a mitad de partida = pierde la apuesta.
  Partida guiada gratis (apuesta 0). Rescate: +1.000 una vez al día si el saldo
  baja de 100. Si a algún humano le falta saldo al iniciar, nadie paga
  (error saldo_insuficiente).
- Tiers (nombres nuevos, montos iguales): La Taberna 100, El Boliche 250,
  El Casino 500, La Mansión 1.000, El Club VIP 2.500. El paño cambia con el
  tier; solo Casino 500 es definitivo, los demás son propuestas.
- Billetera local y billetera en línea son DOS billeteras separadas (ambas
  parten en 5.000) hasta que exista la cuenta nube.

## 7. Auth, tienda, ranking (secuencia, no adelantar)

Orden del usuario: **mesa visual → auth + billetera nube → tienda** (nunca
tienda antes de auth). Después: ranking y niveles. El emparejamiento está
DIFERIDO por su orden, no se construye.
- **Auth obligatoria con Firebase** (proyecto cacho-e4a74, plan Spark gratis):
  "Continuar con Google" primero, enlace de correo sin contraseña después.
  Sesión persistente, apodo editable (máx 16). El correo NUNCA se muestra en
  la mesa ni a otros jugadores; el UID de Firebase NUNCA se envía a otros
  jugadores, solo al servidor. El servidor debe verificar el token en cada
  conexión y la billetera/inventario pasan a clave UID en Firestore.
  Las claves de configuración viven SOLO en app/lib/config.dart y NO se copian
  en este prompt ni en ningún documento.
- **Migración: todos a cero.** Ningún saldo anónimo (local ni en línea) se
  traspasa a la cuenta Firebase. El reseteo aplica EN el momento de la
  migración, no ahora: hoy nada se ha borrado.
- **Cuenta Firebase nueva parte en 0** (0 monedas, 0 gemas). Entradas: partida
  guiada gratis, rescate +1.000, o comprar cuando exista la tienda.
- **Regla futura diferida (NO aplicar ahora):** cuando termine el trabajo
  actual, todo jugador nuevo partirá con 10.000 monedas. Solo con su
  confirmación en ese momento.
- **Tienda (después de auth, sin precios aún):** se venden gemas y monedas. Las
  gemas personalizan el vaso y los dados: el vaso lo ven los rivales en la
  mesa, los dados solo los ve su dueño. Precios, packs, proveedor de pago y si
  es dinero real o ganable están pendientes (P14/P15). No hay flujo de compra.
- **Ranking (dimensiones cerradas, fórmula pendiente):** por monedas actuales,
  partidas ganadas y racha (actual + mejor, con bonus y top de racha).
- **Niveles (marco cerrado, números pendientes):** tope 300, XP sube por
  partida GANADA, existe top de nivel. Solo victorias en línea contra humanos
  dan XP (antifarming, ver arriba).

## 8. Lo que NUNCA se hace sin su orden

- Desplegar, commitear o pushear. Tocar docs/01-arquitectura-y-decisiones.md
  (lo edita otra sesión). Cambiar reglas. Inventar datos, monedas, precios o
  funciones. Copiar arte, marcas, nombres o caras del ejemplo. Reintroducir
  AN15. Construir emparejamiento, tienda antes de auth, o la regla de 10.000
  antes de tiempo. Reintentar la APK Flutter. Presentar algo como listo sin
  compararlo punto por punto contra el ejemplo con capturas reales.

## 9. Decisiones pendientes del usuario (no resolverlas por tu cuenta)

P1 (botón APOSTAR dentro de la barra), P2 (pozo solo al centro o centro+barra),
P3 (tamaño vaso rival), P6 (iconos de barra sin implementar), P8 (control −1),
P9 (texto de 14 px junto a APOSTAR inerte), P10 (contraste CALZO medido),
P11 (saldo rival en placas), P12 (variantes de tier una por una), P13
(tier vs selector de tema), P14/P15 (tienda), P16 (dónde va el saldo de gemas),
P17 (orden de apilado de barras/panel/consola), P18 (docs/01 línea 9),
P19 (chip "listo" vs interruptor), P20 (azul del contador de dados),
P21 (altura útil real en Safari). Más: pipas Blender finas vs dado plano,
placa superior truncada, panel desplegado que corta asientos a 390, altura
mínima con aviso o degradado, swipe del carrusel en iPhone real, licencia
Unity, y la aceptación final de la mesa (ella sola habilita lo siguiente).

## 10. Cómo trabaja el usuario (trátalo así)

- Español, decisiones cortas y finales. No le devuelvas preguntas si te ordenó
  seguir trabajando: trabaja hasta el resultado y reporta.
- Verifica en juego real, no solo leyendo código: una función que el código
  parece tener puede faltar en su partida. Muestra capturas reales antes que
  afirmaciones, y a tamaño legible (la pantalla horizontal exprimida en el
  chat no se entiende).
- Cuando corrige, corrige exactamente lo que marcó, sin reabrir lo que ya
  rechazó y sin justificaciones que suenen a excusas: comparación directa y
  lista de diferencias restantes.
- Su secuencia manda: nunca adelantes trabajo (mesa → auth → tienda →
  ranking/niveles), y cuando dice alto, se para en el mismo turno.
