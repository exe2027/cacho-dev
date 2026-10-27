// R44/R48: accessor del puente window.CachoViewport (web/app_bridge.js).
// En web lee visualViewport + safe-area-inset + fullscreen real; fuera
// de web es un stub sin efectos (la app usa MediaQuery/SafeArea).
export 'app_viewport_stub.dart'
    if (dart.library.js_interop) 'app_viewport_web.dart';
