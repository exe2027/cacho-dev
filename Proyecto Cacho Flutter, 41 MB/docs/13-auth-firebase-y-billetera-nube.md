# Auth Firebase y billetera en la nube (decisión del usuario 25-oct ~04:00 -03)

## Decisión
- Para ingresar al juego HAY QUE REGISTRARSE. Sin cuenta no se juega (ni local ni en línea).
- Registro con Firebase Authentication: Google (Gmail) + correo. Diseño a cargo de GOD con el criterio "lo más cómodo posible".
- Motivo: a partir de ahora se guardan por cuenta las monedas que se ganan y se pierden en las partidas Y las compras dentro del juego (gemas, monedas, cosméticos).
- Esto REVIERTE la regla anterior "sin cuentas obligatorias" y el plan de Supabase como único guardado para la tienda: Firebase manda para identidad y guardado en Cacho (Supabase queda en pausa salvo que el usuario ordene un híbrido).

## Diseño cómodo (propuesto por GOD, pendiente de aprobación del usuario)
1. Botón principal "Continuar con Google": un toque, selector de cuenta Gmail, sin contraseña que recordar. En Safari iOS usar redirect con fallback a popup (los popups se bloquean en iOS).
2. Botón secundario "Continuar con correo": enlace mágico por email (sin contraseña) como vía principal de correo; email + contraseña solo como respaldo si el enlace falla.
3. Sesión persistente: al volver, entra directo sin volver a registrarse (Firebase Auth persiste en el navegador).
4. Apodo: se pre-rellena con el nombre de Google, editable, máximo 16 caracteres, como hoy. El correo NUNCA se muestra en la mesa ni a otros jugadores (solo apodo + avatar). El UID de Firebase NUNCA se envía a otros jugadores, solo al servidor.
5. Puerta de entrada: la pantalla de registro es la puerta para jugar. Cómo se juega puede seguir visible sin cuenta (a confirmar por el usuario; no se asume como hecho).

## Cambios técnicos que exige (NO parte de la pasada visual de la mesa)
- App: firebase_auth + proveedor Google + enlace por email (solo web; APK congelada).
- Servidor: ya NO confía en walletToken anónimo. Debe verificar el ID token de Firebase en cada conexión/reconexión (verificación JWT con las claves públicas de Google, sin clave privada en el Worker) y pasar la billetera/inventario a clave UID.
- Billetera única en la nube por UID (fin de las dos billeteras separadas local/en línea): monedas ganadas/perdidas en partidas y compras se guardan por UID y se restauran en cualquier dispositivo tras iniciar sesión.
- Inventario de cosméticos por UID (vaso visible para rivales, dados solo para el dueño, según docs/12 sección 11).
- Compras: ledger idempotente por UID + recibo, para no acreditar dos veces y para restaurar compras.

## PENDIENTES del usuario (bloquean construir auth, no la mesa visual)
1. Crear el proyecto Firebase "Cacho" y habilitar Authentication con proveedores Google y Correo (enlace por email), y entregar la configuración web (apiKey, authDomain, projectId, appId). NO se pide ninguna clave privada de cuenta de servicio.
2. Migración DECIDIDA 25-oct ~04:04 -03: dejar a TODOS EN CERO. No se arrastra ningún saldo anónimo (ni local ni en línea) a la cuenta Firebase. El cero se aplica EN EL MOMENTO de la migración, NO antes: no se borra nada de producción hasta que auth exista, porque borrar sin cuentas dejaría saldos en 0 sin vía de recuperación. DECIDIDO 25-oct ~04:07 -03 (opción tocada): la cuenta nueva con Firebase PARTE EN 0 monedas (y 0 gemas), NO en 5.000. La regla de 5.000 inicial queda superada para cuentas Firebase, vigente solo desde el lanzamiento de auth. Consecuencia: un jugador nuevo no puede apostar 100 de inmediato; entra por la partida guiada GRATIS (apuesta 0), por el rescate +1.000 (saldo < 100, una vez al día) o por compra de monedas cuando exista la tienda. Nada cambia en producción anónima hasta la migración.

## Regla futura diferida (25-oct ~04:10 -03, NO aplicar ahora)
Luego que terminemos el trabajo actual, todo jugador empieza con 10.000 monedas (gemas iniciales siguen en 0 salvo otra orden). Secuencia: producción anónima 5.000 → lanzamiento Firebase con cuentas nuevas en 0 → después, regla inicial 10.000 para jugadores nuevos. No se aplica el 10.000 ahora ni en la migración; cuando llegue ese punto se confirma antes de cambiarlo.
3. Confirmar si Cómo se juega queda visible sin cuenta o si todo, incluido Cómo se juega, exige registro.

## Secuencia
1. Mesa visual según docs/12 + enmiendas (en curso, no se detiene por auth).
2. Auth Firebase + billetera en la nube + migración (cuando llegue la configuración y la decisión de migración).
3. Tienda de gemas/monedas + cosméticos (después de auth, nunca antes: sin cuenta no hay dónde guardar una compra).
4. Sin desplegar ni commitear sin su sí.
