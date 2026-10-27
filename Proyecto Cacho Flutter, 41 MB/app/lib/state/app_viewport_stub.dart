import 'package:flutter/foundation.dart';

/// Stub fuera de web (R44/R48): sin puente JS, la app usa
/// MediaQuery/SafeArea y no hay botón de pantalla completa.
class AppViewport extends ChangeNotifier {
  static final AppViewport instance = AppViewport._();
  AppViewport._();

  double safeTop = 0;
  double safeBottom = 0;
  double jsHeight = 0;

  void startWatching() {}
  void stopWatching() {}

  bool get fullscreenEnabled => false;
  bool get isIOS => false;
  bool get isFullscreen => false;
  void requestFullscreen() {}
  void exitFullscreen() {}
}

final appViewport = AppViewport.instance;
