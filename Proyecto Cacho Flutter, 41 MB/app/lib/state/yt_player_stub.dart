import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Reproductor vacío + el contrato completo de la API entre
/// plataformas (el analizador usa este archivo como superficie:
/// todo lo que el código compartido toca tiene que estar aquí).
class YtPlayer {
  static YtPlayer? instance;

  YtPlayer() {
    instance = this;
  }

  /// Solo la implementación nativa (APK) expone un controlador.
  YoutubePlayerController? get controller => null;

  void markHostMounted() {}

  void init() {}
  bool get isReady => false;
  void load(String videoId, double startSec) {}
  void play() {}
  void pause() {}
  void seekTo(double sec) {}
  void setVolume(int v) {}
  int get volume => -1;
  double get currentTime => -1;
  int get state => -99;
  bool consumeEnded() => false;
  void dispose() {}
}
