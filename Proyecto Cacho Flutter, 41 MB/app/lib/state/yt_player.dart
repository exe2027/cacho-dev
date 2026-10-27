/// Reproductor de YouTube de la sala, por plataforma:
/// - Web: el puente JS con el IFrame Player API (web/yt_bridge.js).
/// - Android/iOS (dart:io): el mismo IFrame dentro de un WebView
///   (youtube_player_iframe) — la APK quedó muda hasta tenerlo
///   (reporte del usuario, 23-oct).
/// - Otro: un reproductor vacío.
export 'yt_player_stub.dart'
    if (dart.library.js_interop) 'yt_player_web.dart'
    if (dart.library.io) 'yt_player_native.dart';
