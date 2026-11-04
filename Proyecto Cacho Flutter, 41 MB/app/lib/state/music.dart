import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'yt_player.dart';

/// Un tema en la cola o sonando, tal como lo difunde el servidor.
class MusicTrack {
  final String videoId;
  final String title;
  final String channel;
  final String thumb;
  final int durationSec;
  final String byId;
  final String byName;
  final int startedAt; // ms del reloj del servidor
  final int? pausedAt; // ms del servidor, si está en pausa

  const MusicTrack({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumb,
    required this.durationSec,
    required this.byId,
    required this.byName,
    this.startedAt = 0,
    this.pausedAt,
  });

  bool get paused => pausedAt != null;

  factory MusicTrack.fromJson(Map<String, dynamic> j) => MusicTrack(
        videoId: j['videoId'] as String? ?? '',
        title: j['title'] as String? ?? 'Sin título',
        channel: j['channel'] as String? ?? '',
        thumb: j['thumb'] as String? ?? '',
        durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
        byId: j['byId'] as String? ?? '',
        byName: j['byName'] as String? ?? '',
        startedAt: (j['startedAt'] as num?)?.toInt() ?? 0,
        pausedAt: (j['pausedAt'] as num?)?.toInt(),
      );

  Map<String, dynamic> toAddJson() => {
        'videoId': videoId,
        'title': title,
        'channel': channel,
        'thumb': thumb,
        'durationSec': durationSec,
      };
}

/// Posición (ms) en que debería ir el tema según los tiempos del
/// SERVIDOR: al recibir el estado (en [receiptLocalMs], hora local) el
/// tema iba en X; desde ahí corre en tiempo real si no está en pausa.
/// Usar solo horas del servidor para el ancla evita que el desfase de
/// reloj de cada teléfono descuadre la sala.
int anchoredPositionMs({
  required int startedAt,
  required int? pausedAt,
  required int sentAt,
  required int receiptLocalMs,
  required int nowLocalMs,
}) {
  final atSent = (pausedAt ?? sentAt) - startedAt;
  if (pausedAt != null) return atSent;
  return atSent + (nowLocalMs - receiptLocalMs);
}

/// El volumen de la música con la regla del usuario: siempre bajo las
/// voces. Si cualquier micrófono de la mesa está abierto, la música
/// baja a 11 como máximo (ducking); si no, suena al volumen elegido.
int duckedVolume(int base, bool anyMicOn) =>
    anyMicOn ? math.min(base, 11) : base;

/// El reproductor de la sala y su sincronía. El servidor dicta qué
/// suena y desde cuándo; este servicio hace que el reproductor local
/// obedezca: carga el tema, corrige el desfase cada segundo, aplica
/// el volumen con ducking y avisa cuando un tema termina.
class MusicService extends ChangeNotifier {
  final YtPlayer player = YtPlayer();

  String? djId;
  MusicTrack? current;
  List<MusicTrack> queue = [];
  int skipVotes = 0;
  int skipNeeded = 2;

  int _receiptLocalMs = 0;
  int _sentAt = 0;
  String? _loadedId;
  Timer? _timer;
  int _lastAppliedVolume = -1;
  String? _volTrack; // tema al que ya se le aplicó el volumen
  bool _active = false;

  int myVolume = 15; // 0..50, persistido (partía en 30: muy fuerte)
  bool silenced = false;

  /// ¿Hay algún micrófono abierto en la mesa? Lo conecta el
  /// controlador (incluye el propio).
  bool Function() anyMicOn = () => false;

  /// El DJ local avisa que su reproductor llegó al fin del tema.
  void Function()? onEnded;

  /// Cambia cuando la música de la sala pasa a sonar o a callar:
  /// el controlador apaga/repone la música de casino según esto.
  void Function(bool active)? onActiveChanged;

  MusicService() {
    _loadPrefs();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      myVolume = prefs.getInt('music_volume') ?? 15;
    } catch (_) {}
  }

  Future<void> setMyVolume(int v) async {
    myVolume = v.clamp(0, 50);
    _lastAppliedVolume = -1; // fuerza reaplicar en el próximo tick
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('music_volume', myVolume);
    } catch (_) {}
  }

  void setSilenced(bool v) {
    silenced = v;
    _lastAppliedVolume = -1;
    notifyListeners();
  }

  bool get isDjClaimed => djId != null;

  void applyState(Map<String, dynamic> music) {
    djId = music['djId'] as String?;
    final cur = music['current'];
    current =
        cur is Map<String, dynamic> ? MusicTrack.fromJson(cur) : null;
    final q = music['queue'];
    queue = q is List
        ? [
            for (final item in q)
              if (item is Map<String, dynamic>) MusicTrack.fromJson(item),
          ]
        : [];
    skipVotes = (music['skipVotes'] as num?)?.toInt() ?? 0;
    skipNeeded = (music['skipNeeded'] as num?)?.toInt() ?? 2;
    _sentAt = (music['sentAt'] as num?)?.toInt() ?? 0;
    _receiptLocalMs = DateTime.now().millisecondsSinceEpoch;
    player.init();
    _tick();
    notifyListeners();
  }

  double get targetPositionSec {
    final cur = current;
    if (cur == null) return 0;
    final ms = anchoredPositionMs(
      startedAt: cur.startedAt,
      pausedAt: cur.pausedAt,
      sentAt: _sentAt,
      receiptLocalMs: _receiptLocalMs,
      nowLocalMs: DateTime.now().millisecondsSinceEpoch,
    );
    return math.max(0, ms) / 1000.0;
  }

  int get effectiveVolume =>
      silenced ? 0 : duckedVolume(myVolume, anyMicOn());

  /// El navegador dejó el tema cargado pero sin sonar (autoplay con
  /// sonido bloqueado): hace falta un toque del jugador.
  bool get needsTap {
    final cur = current;
    if (cur == null || cur.paused || !player.isReady) return false;
    final st = player.state;
    return st == 2 || st == 5 || st == -1;
  }

  /// Toque del jugador para destrabar el sonido.
  void userGesturePlay() {
    // El volumen se fija ANTES de dar play: al revés, el tema
    // partía un instante a todo volumen (reporte del usuario:
    // "el reproductor suena muy fuerte").
    final eff = effectiveVolume;
    player.setVolume(eff);
    _lastAppliedVolume = eff;
    player.play();
  }

  /// Ceba el reproductor DENTRO del gesto del jugador (toca
  /// "agregar" o "tocar ahora" en la hoja): en iOS el navegador solo
  /// deja sonar con volumen un reproductor que nació de un toque, y
  /// la carga real llega milisegundos después por el servidor. Sin
  /// este cebado, el DJ no escuchaba su propia música (los demás sí).
  void primeWithGesture() {
    player.init();
    userGesturePlay();
  }

  void _tick() {
    final cur = current;
    if (cur == null) {
      if (_loadedId != null) {
        player.pause();
        _loadedId = null;
      }
      _setActive(false);
      return;
    }
    if (!player.isReady) return;

    if (_loadedId != cur.videoId) {
      player.load(cur.videoId, targetPositionSec);
      _loadedId = cur.videoId;
      // Volumen aplicado AL CARGAR: un tema nuevo no puede partir
      // al volumen por defecto del reproductor (100) esperando a
      // que el volumen elegido "cambie" para recién aplicarse.
      final eff0 = effectiveVolume;
      player.setVolume(eff0);
      _lastAppliedVolume = eff0;
      if (cur.paused) {
        // loadVideoById parte sonando: se pausa enseguida.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (current?.videoId == cur.videoId && cur.paused) player.pause();
        });
      }
    } else {
      final st = player.state;
      if (cur.paused) {
        if (st == 1) player.pause();
      } else if (st == 2) {
        // El servidor dice que suene pero el reproductor quedó en
        // pausa (al reanudar el DJ, o un autoplay frenado): se le da
        // play. Si el navegador lo bloquea por falta de un toque, el
        // intento es inocuo y queda la activación manual de la hoja.
        player.play();
      } else if (st == 1) {
        final drift = targetPositionSec - player.currentTime;
        if (drift.abs() > 1.5 && player.currentTime >= 0) {
          player.seekTo(targetPositionSec);
        }
      }
    }

    if (player.consumeEnded()) {
      onEnded?.call();
    }

    final eff = effectiveVolume;
    if (eff != _lastAppliedVolume || _volTrack != _loadedId) {
      // También al primer tick de cada tema: el reproductor puede
      // haber partido con su volumen propio al cargar el video.
      player.setVolume(eff);
      _lastAppliedVolume = eff;
      _volTrack = _loadedId;
    }

    // La música de casino se calla por la INTENCIÓN de la sala (hay
    // un tema que debería estar sonando), no por el estado local del
    // reproductor: si el navegador frenó el autoplay de este equipo,
    // antes el DJ seguía oyendo la música del juego encima y creía
    // que su tema no sonaba (bug reportado el 22-oct). Con la
    // intención basta: casino callado y el botón "Activar" a la
    // vista en la barra hasta que el tema suene de verdad.
    _setActive(!cur.paused);
  }

  void _setActive(bool v) {
    if (_active == v) return;
    _active = v;
    onActiveChanged?.call(v);
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      player.pause();
      player.dispose();
    } catch (_) {}
    _setActive(false);
    super.dispose();
  }
}
