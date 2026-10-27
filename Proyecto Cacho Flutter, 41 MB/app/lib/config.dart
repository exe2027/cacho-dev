/// Configuración interna de la app.
///
/// La dirección del servidor de salas es INTERNA (master prompt §1):
/// nunca se muestra ni se edita en la interfaz. 10.0.2.2 solo servía al
/// emulador Android y está prohibida en producción.
/// Claves de YouTube (proyecto Google del dueño de la app).
/// La clave de API va restringida por dominio (cacho.pages.dev) en la
/// consola de Google: es pública por diseño en una app web.
/// El Client ID de OAuth también es público por diseño.
/// Se rellenan cuando el usuario crea el proyecto de Google; mientras
/// estén vacías, el buscador y la cuenta muestran su estado "sin
/// conectar" y el resto de la música (cola, DJ, sincronía) funciona.
const String kYoutubeApiKey = 'AIzaSyBPvrCshD8hGIlhIxZYRbcsKfUu7mPT92w';
const String kYoutubeOAuthClientId = '';

const String kServerUrl = 'wss://cacho-server.vikingosfoodspa.workers.dev';
const String kServerHealthUrl =
    'https://cacho-server.vikingosfoodspa.workers.dev/health';
