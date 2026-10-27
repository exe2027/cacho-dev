import 'dart:js_interop';

import 'package:youtube_player_iframe/youtube_player_iframe.dart'
    show YoutubePlayerController;

/// Acceso al puente window.CachoYt (web/yt_bridge.js).
@JS('CachoYt')
extension type _CachoYt(JSObject _) implements JSObject {
  external void init();
  external bool isReady();
  external void load(String videoId, double startSec);
  external void play();
  external void pause();
  external void seekTo(double sec);
  external void setVolume(int v);
  external int getVolume();
  external double getCurrentTime();
  external int getState();
  external bool consumeEnded();
}

@JS('CachoYt')
external _CachoYt? get _yt;

class YtPlayer {
  static YtPlayer? instance;

  YtPlayer() {
    instance = this;
  }

  /// En web no hay controlador de WebView: manda el puente JS.
  YoutubePlayerController? get controller => null;

  void markHostMounted() {}

  void dispose() {}

  bool _initTried = false;

  void init() {
    if (_initTried) return;
    _initTried = true;
    try {
      _yt?.init();
    } catch (_) {}
  }

  bool get isReady {
    try {
      return _yt?.isReady() ?? false;
    } catch (_) {
      return false;
    }
  }

  void load(String videoId, double startSec) {
    try {
      _yt?.load(videoId, startSec);
    } catch (_) {}
  }

  void play() {
    try {
      _yt?.play();
    } catch (_) {}
  }

  void pause() {
    try {
      _yt?.pause();
    } catch (_) {}
  }

  void seekTo(double sec) {
    try {
      _yt?.seekTo(sec);
    } catch (_) {}
  }

  void setVolume(int v) {
    try {
      _yt?.setVolume(v);
    } catch (_) {}
  }

  int get volume {
    try {
      return _yt?.getVolume() ?? -1;
    } catch (_) {
      return -1;
    }
  }

  double get currentTime {
    try {
      return _yt?.getCurrentTime() ?? -1;
    } catch (_) {
      return -1;
    }
  }

  /// -1 sin empezar, 0 terminado, 1 sonando, 2 pausado, 3 cargando,
  /// 5 en cola; -99 si el puente no responde.
  int get state {
    try {
      return _yt?.getState() ?? -99;
    } catch (_) {
      return -99;
    }
  }

  bool consumeEnded() {
    try {
      return _yt?.consumeEnded() ?? false;
    } catch (_) {
      return false;
    }
  }
}
