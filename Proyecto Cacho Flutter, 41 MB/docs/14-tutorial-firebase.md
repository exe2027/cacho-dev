# Tutorial Firebase para Cacho (login con Google + correo, plan gratis)

Tiempo: ~10 minutos. Costo: $0 (plan Spark, sin tarjeta). Mejor desde un computador; en iPhone también se puede, pero es más incómodo.

## Paso 1: Entra a Firebase
1. Abre https://console.firebase.google.com
2. Entra con tu Gmail (la misma cuenta con la que quieres administrar Cacho).

## Paso 2: Crea el proyecto
1. Pulsa **Add project** (Agregar proyecto).
2. Nombre: **Cacho**.
3. Si te ofrece usar tu proyecto existente de Google Cloud "Cacho" (el de YouTube), úsalo. Si no ves esa opción, crea uno nuevo llamado Cacho: no pasa nada, solo tendrás dos proyectos con el mismo nombre y el de Firebase será el que usemos para login.
4. Cuando pregunte por Google Analytics: **desactívalo** (así es más simple; se puede activar después).
5. Pulsa **Create project** y espera a que termine. Luego **Continue**.

## Paso 3: Activa Authentication
1. En el menú izquierdo: **Build > Authentication**.
2. Pulsa **Get started**.

## Paso 4: Activa Google (Gmail)
1. Ve a la pestaña **Sign-in method** (Método de acceso).
2. En la lista, pulsa **Google**.
3. Activa el interruptor **Enable**.
4. En **Project support email**, elige tu Gmail.
5. Pulsa **Save**.
6. Opcional (solo si al probar te dice que solo usuarios de prueba pueden entrar): ve a Google Cloud > APIs & Services > OAuth consent screen > **Test users** y agrega tu Gmail. Por ahora basta con eso; publicar la app para todos lo hacemos juntos cuando lancemos.

## Paso 5: Activa correo con enlace (sin contraseña)
1. En **Sign-in method**, pulsa **Email/Password** (Correo electrónico/Contraseña).
2. Activa **Enable**.
3. Dentro de ese mismo proveedor, activa también **Email link (passwordless sign-in)** (Enlace de correo, acceso sin contraseña).
4. Pulsa **Save**.
5. No necesitas configurar SMTP ahora: los correos de enlace llegan desde Firebase por defecto.

## Paso 6: Autoriza el dominio de Cacho (paso crítico, no lo saltes)
1. En Authentication, ve a **Settings > Authorized domains** (Dominios autorizados).
2. Pulsa **Add domain** y agrega exactamente: `cacho.pages.dev`
3. Guarda.
4. Sin este paso, el login desde cacho.pages.dev fallará con `auth/unauthorized-domain`. `localhost` ya viene autorizado por defecto para pruebas.

## Paso 7: Registra la app web y copia la configuración
1. Ve a **Project Overview** (o el engranaje > Project settings).
2. En "Your apps", pulsa el icono **Web** (`</>`).
3. Apodo de la app: **Cacho web**.
4. NO marques Firebase Hosting: Cacho se publica en Cloudflare Pages, no en Firebase Hosting.
5. Pulsa **Register app**.
6. Firebase te mostrará un objeto `firebaseConfig` parecido a este (valores de ejemplo, los tuyos serán distintos):
   - `apiKey`
   - `authDomain`
   - `projectId`
   - `storageBucket`
   - `messagingSenderId`
   - `appId`
7. Cópialo completo y mándamelo.

## Qué NO hacer
- NO actives facturación ni pases a Blaze: quédate en Spark (gratis).
- NO actives Phone (teléfono/SMS): eso sí se paga después del límite diario.
- NO crees ni descargues ninguna cuenta de servicio (service account) ni su JSON: para login NO la necesitamos.
- NO crees la base Firestore todavía: eso va en la fase de billetera, con reglas seguras, no ahora.

## Qué mandarme cuando termines
1. El objeto `firebaseConfig` completo.
2. Confirmación de que Google está en Enable y que Email link está activado.
3. Confirmación de que `cacho.pages.dev` está en Authorized domains.

Con eso construyo: pantalla de registro ("Continuar con Google" principal, "Continuar con correo" por enlace, sesión persistente, apodo pre-rellenado), verificación del token en el servidor y billetera en la nube por cuenta.

## Si algo falla
- `auth/unauthorized-domain` → falta el Paso 6 (agrega `cacho.pages.dev`).
- `auth/operation-not-allowed` → el proveedor (Google o correo) no quedó en Enable: vuelve al Paso 4 o 5.
- Al entrar con Google te dice que la app no está verificada o que solo entran usuarios de prueba → agrega tu Gmail en Test users (Paso 4, punto 6).
- En Safari de iPhone el popup se bloquea → no es error de consola: la app usará redirección en vez de popup.
