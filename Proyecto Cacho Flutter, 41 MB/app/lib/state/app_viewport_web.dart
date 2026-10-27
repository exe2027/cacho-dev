import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Acceso al puente window.CachoViewport (web/app_bridge.js).
@JS('CachoViewport')
extension type _CachoViewport(JSObject _) implements JSObject {
  external double safeTop();
  external double safeBottom();
  external double height();
  external bool fullscreenEnabled();
  external bool isIOS();
  external bool isFullscreen();
  external void requestFullscreen();
  external void exitFullscreen();
}

@JS('CachoViewport')
external _CachoViewport? get _vp;

/// R44: altura visible real y safe-area de Safari, por si SafeArea
/// de Flutter web da 0. Se sondea cada 500 ms solo mientras una
/// pantalla de partida está montada (startWatching/stopWatching):
/// un cambio de barras de Safari dispara notifyListeners y la
/// reconstrucción (la decisión compacta/emergencia la toma el
/// LayoutBuilder con la altura real de la fila, no un número
/// inventado). R48: pantalla completa real del documento.
class AppViewport extends ChangeNotifier {
  static final AppViewport instance = AppViewport._();
  AppViewport._();

  double safeTop = 0;
  double safeBottom = 0;
  double jsHeight = 0;
  int _watchers = 0;
  Timer? _timer;

  void startWatching() {
    _watchers++;
    _timer ??= Timer.periodic(
        const Duration(milliseconds: 500), (_) => _refresh());
    _refresh();
  }

  void stopWatching() {
    if (_watchers > 0) _watchers--;
    if (_watchers == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _refresh() {
    try {
      final t = _vp?.safeTop() ?? 0;
      final b = _vp?.safeBottom() ?? 0;
      final h = _vp?.height() ?? 0;
      if (t != safeTop || b != safeBottom || h != jsHeight) {
        safeTop = t;
        safeBottom = b;
        jsHeight = h;
        notifyListeners();
      }
    } catch (_) {}
  }

  bool get fullscreenEnabled {
    try {
      return _vp?.fullscreenEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// R48: iPhone/iPad (todos los navegadores iOS usan WebKit y no
  /// permiten pantalla completa de página).
  bool get isIOS {
    try {
      return _vp?.isIOS() ?? false;
    } catch (_) {
      return false;
    }
  }

  bool get isFullscreen {
    try {
      return _vp?.isFullscreen() ?? false;
    } catch (_) {
      return false;
    }
  }

  void requestFullscreen() {
    try {
      _vp?.requestFullscreen();
    } catch (_) {}
  }

  void exitFullscreen() {
    try {
      _vp?.exitFullscreen();
    } catch (_) {}
  }
}

final appViewport = AppViewport.instance;
