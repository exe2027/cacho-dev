import 'dart:async';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Reproductor de YouTube NATIVO (APK Android): el mismo IFrame
/// Player API que usa la web, pero dentro de un WebView
/// (youtube_player_iframe). La versión web nació primero y la APK
/// quedó con el reproductor vacío (stub): por eso en la APK la
/// música de la sala no sonaba — reporte del usuario, 23-oct.
///
/// El puente del paquete espera a que el reproductor esté listo
/// antes de ejecutar las órdenes, así que cargar/dar play "antes de
/// tiempo" no se pierde. El widget que muestra el WebView vive en
/// la pantalla de partida (NativeYtHost) y usa [controller].
class YtPlayer {
  /// La instancia viva (la crea MusicService): el widget anfitrión
  /// la busca aquí para montar el WebView con su controlador.
  static YtPlayer? instance;

  YtPlayer() {
    instance = this;
  }

  YoutubePlayerController? _ctrl;
  StreamSubscription<YoutubeVideoState>? _posSub;
  StreamSubscription<YoutubePlayerValue>? _stateSub;
  int _state = -1; // códigos del IFrame API (1 play, 2 pausa, ...)
  double _time = -1;
  int _volume = -1;
  bool _ended = false;
  bool _mounted = false;
  DateTime? _mountedAt;

  YoutubePlayerController? get controller => _ctrl;

  /// El widget anfitrión avisa que el WebView ya está en pantalla.
  void markHostMounted() {
    _mounted = true;
    _mountedAt ??= DateTime.now();
  }

  void init() {
    if (_ctrl != null) return;
    final ctrl = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        showVideoAnnotations: false,
        enableCaption: false,
        playsInline: true,
      ),
    );
    _ctrl = ctrl;
    _stateSub = ctrl.stream.listen((value) {
      final code = value.playerState.code;
      _state = code == -2 ? -1 : code; // unknown -> sin empezar
      if (value.playerState == PlayerState.ended) _ended = true;
    });
    _posSub = ctrl.videoStateStream.listen((s) {
      _time = s.position.inMilliseconds / 1000.0;
    });
  }

  /// Listo cuando el WebView está montado y el reproductor ya
  /// reportó algún estado — o pasaron 3 s del montaje (el puente
  /// encola las órdenes hasta el ready real, no se pierde nada).
  bool get isReady {
    if (_ctrl == null || !_mounted) return false;
    if (_state != -1) return true;
    final at = _mountedAt;
    return at != null &&
        DateTime.now().difference(at) > const Duration(seconds: 3);
  }

  void load(String videoId, double startSec) {
    _ctrl?.loadVideoById(videoId: videoId, startSeconds: startSec);
  }

  void play() => _ctrl?.playVideo();

  void pause() => _ctrl?.pauseVideo();

  void seekTo(double sec) =>
      _ctrl?.seekTo(seconds: sec, allowSeekAhead: true);

  void setVolume(int v) {
    _volume = v;
    _ctrl?.setVolume(v);
  }

  int get volume => _volume;

  double get currentTime => _time;

  int get state => _state;

  bool consumeEnded() {
    final e = _ended;
    _ended = false;
    return e;
  }

  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    if (instance == this) instance = null;
  }
}
