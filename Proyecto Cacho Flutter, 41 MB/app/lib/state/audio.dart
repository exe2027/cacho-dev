import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

/// Sonidos y háptica de la mesa. Los archivos viven en assets/sounds/
/// (sintetizados: dados en cuero, golpe de cacho, tintineo, zumbido,
/// redoble, fichas, soplo de Paso y murmullo de casino en bucle).
/// Los volúmenes de efectos y de ambiente son separados y el silencio
/// general manda (Settings.soundEffects / Settings.murmur).
class AudioService {
  static final AudioService instance = AudioService._();

  /// Cuando la música de la sala (DJ de YouTube) está sonando, la
  /// música de casino se calla: no se mezclan dos músicas.
  static bool djTakeover = false;
  AudioService._();

  AudioPlayer? _player;
  AudioPlayer? _murmurPlayer;
  AudioPlayer? _musicPlayer;
  bool _murmurOn = false;
  bool _musicOn = false;
  bool _unlocked = false;

  /// Interruptor rápido de la barra de la partida (refleja Settings).
  bool get enabled => Settings.instance.soundEffects;
  set enabled(bool v) {
    Settings.instance.soundEffects = v;
    Settings.instance.save();
    if (!v) {
      stopMurmur();
      stopMusic();
    }
  }

  Future<void> _play(String file, {double volume = 0.9}) async {
    if (!Settings.instance.soundEffects) return;
    debugPlayListener?.call(file);
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // Sin audio (web sin gesto previo, tests, etc.): la partida sigue.
    }
  }

  /// Desbloqueo de audio (iOS/web): el navegador mantiene el
  /// contexto suspendido hasta un gesto del usuario; sin esto los
  /// sonidos existen pero no se oyen. Se llama en el primer toque.
  Future<void> unlock() async {
    if (_unlocked) return;
    _unlocked = true;
    try {
      final player = _player ??= AudioPlayer();
      await player.resume();
      await _musicPlayer?.resume();
      await _murmurPlayer?.resume();
      if (Settings.instance.soundEffects) {
        await player.setVolume(0.0);
        await player.play(AssetSource('sounds/silent.wav'));
      }
    } catch (_) {
      // Si el gesto no alcanzó, el próximo play lo reintenta solo.
    }
    syncAmbience();
  }

  void diceRoll() => _play('dice_roll.wav');
  void cupThud() => _play('cup_thud.wav');
  void chime() => _play('chime.wav');
  void buzz() => _play('buzz.wav');
  void drumroll() => _play('drumroll.wav');
  void chips() => _play('chips.wav', volume: 0.7);
  void paso() => _play('paso.wav', volume: 0.8);
  void turnPop() => _play('turn_pop.wav', volume: 0.55);

  /// Mi turno: campana de dos tonos, imposible de pasar por alto.
  void turnAlert() => _play('turn_chime.wav', volume: 0.85);

  /// Turno de otro jugador: clic suave de aviso.
  void tick() => _play('tick.wav', volume: 0.16);

  /// Gancho solo de diagnóstico/tests: se llama cada vez que _play
  /// realmente intenta sonar (después del guard de efectos), con el
  /// archivo. En producción nadie lo asigna; no afecta al audio.
  static void Function(String file)? debugPlayListener;

  /// Pool de reproductores solo para ticks de ruleta. Causa raíz
  /// de que el tack no se oyera: _play() usa UN solo reproductor y
  /// hace stop() antes de cada sonido, y la ráfaga de ruleta NO
  /// espera a _play. Con tick.wav de 50 ms e intervalos de 42 ms,
  /// el tick siguiente cortaba al anterior antes de terminar, y
  /// en iPhone/Safari esa carrera stop/play dejaba el sonido en
  /// silencio. Con 4 reproductores en rotación, un tick nunca
  /// corta al anterior (el mismo reproductor se reutiliza cada
  /// ~4 ticks, más de los 50 ms que dura el sonido) y NO se hace
  /// stop() antes de sonar.
  final List<AudioPlayer> _tickPlayers = [];
  int _tickPlayerIndex = 0;

  Future<void> _playTick(String file, {double volume = 0.45}) async {
    if (!Settings.instance.soundEffects) return;
    debugPlayListener?.call(file);
    try {
      // El pool crece de uno en uno, nunca de golpe: crear un
      // AudioPlayer dispara una inicialización asíncrona cuyo
      // error solo queda capturado si alguien espera su creación
      // antes de que complete. Crear 4 de golpe dejaba 3
      // creatingCompleter sin listener y su error se reportaba
      // como no capturado (en tests, como fallo). Aquí, cada
      // reproductor nuevo se usa (setVolume) en la misma llamada
      // que lo crea, así que su error queda dentro de este try.
      final AudioPlayer player;
      if (_tickPlayers.length < 4) {
        player = AudioPlayer();
        _tickPlayers.add(player);
      } else {
        player = _tickPlayers[_tickPlayerIndex];
        _tickPlayerIndex = (_tickPlayerIndex + 1) % _tickPlayers.length;
      }
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // Sin audio (web sin gesto previo, tests, etc.): sigue.
    }
  }

  /// Intervalos (ms) entre los ticks de la ruleta: desaceleran como
  /// la bola al asentarse. 6 ticks, ~342 ms audibles en total
  /// (292 ms de intervalos + el último tick de ~50 ms). El carrusel
  /// desliza rápido (120 ms por paso) y la ruleta se dispara al
  /// inicio del deslizamiento, así que el "tack" se oye durante el
  /// movimiento y termina justo después, sin tapar la música.
  static const List<int> rouletteIntervalsMs = [42, 48, 56, 66, 80];

  /// Contador para cortar una ráfaga de ruleta anterior cuando
  /// llega otra selección o un tack de fling: barrer rápido el
  /// carrusel no apila ráfagas. Ojo: el contador solo cancela los
  /// ticks PENDIENTES de la ráfaga; un tack ya sonado nunca se
  /// corta, porque _playTick no hace stop() y usa el pool.
  int _rouletteSeq = 0;

  /// Un solo tack claro al pasar por una sala durante un fling
  /// multi-sala: no es una ráfaga, es un tick único, más fuerte
  /// que el tick viejo (0.45 frente a 0.22) para que se oiga sobre
  /// la música de casino (0.30). Cancela cualquier ráfaga de
  /// ruleta pendiente, pero el tack en sí nunca se cancela.
  void tack() {
    _rouletteSeq++;
    _playTick('tick.wav', volume: 0.45);
  }

  /// Sonido de ruleta al cambiar de sala seleccionada (cambio
  /// lento, una sola sala): ráfaga de ticks de tick.wav (asset ya
  /// existente, sintetizado, sin licencia externa) con intervalos
  /// crecientes, por _playTick (pool, sin stop previo) para que
  /// ningún tick corte al anterior. Respeta el interruptor de
  /// efectos (Settings.soundEffects) y NO depende del interruptor
  /// de música: con música apagada y efectos encendidos, la ruleta
  /// sigue sonando como los demás SFX.
  Future<void> roulette() async {
    if (!Settings.instance.soundEffects) return;
    final seq = ++_rouletteSeq;
    for (var i = 0; i <= rouletteIntervalsMs.length; i++) {
      if (seq != _rouletteSeq || !Settings.instance.soundEffects) return;
      _playTick('tick.wav',
          volume: i == rouletteIntervalsMs.length ? 0.45 : 0.35);
      if (i < rouletteIntervalsMs.length) {
        await Future.delayed(Duration(milliseconds: rouletteIntervalsMs[i]));
      }
    }
  }

  /// Pitido de apuro: últimos segundos de mi turno (aro en rojo).
  void beep() => _play('beep.wav', volume: 0.9);
  void winFanfare() => _play('win_fanfare.wav', volume: 0.85);

  /// Cascada de monedas al ganar el pozo.
  void coins() => _play('coins.wav', volume: 0.9);

  /// Un solo clink de moneda (toques de interfaz con monedas).
  void coinOne() => _play('coin_one.wav', volume: 0.6);

  /// Canción de casino en bucle (salón con swing, volumen bajo).
  Future<void> startMusic() async {
    if (_musicOn ||
        !Settings.instance.music ||
        !Settings.instance.soundEffects) {
      return;
    }
    _musicOn = true;
    try {
      final player = _musicPlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.30);
      await player.play(AssetSource('sounds/music_loop.wav'));
    } catch (_) {
      _musicOn = false;
    }
  }

  Future<void> stopMusic() async {
    _musicOn = false;
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  /// Deja sonando (o en silencio) el ambiente según los interruptores.
  void syncAmbience() {
    if (!Settings.instance.soundEffects) {
      stopMurmur();
      stopMusic();
      return;
    }
    if (Settings.instance.music && !djTakeover) {
      startMusic();
    } else {
      stopMusic();
    }
    if (Settings.instance.murmur) {
      startMurmur();
    } else {
      stopMurmur();
    }
  }

  /// Murmullo de fondo de la mesa (bucle). Volumen propio y bajo.
  Future<void> startMurmur() async {
    if (_murmurOn || !Settings.instance.murmur || !Settings.instance.soundEffects) {
      return;
    }
    _murmurOn = true;
    try {
      final player = _murmurPlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.16);
      await player.play(AssetSource('sounds/murmur.wav'));
    } catch (_) {
      _murmurOn = false;
    }
  }

  Future<void> stopMurmur() async {
    _murmurOn = false;
    try {
      await _murmurPlayer?.stop();
    } catch (_) {}
  }

  void hapticLight() {
    try {
      HapticFeedback.lightImpact().catchError((_) {});
    } catch (_) {
      // Sin háptica disponible (tests, escritorio): la partida sigue.
    }
  }

  void hapticHeavy() {
    try {
      HapticFeedback.heavyImpact().catchError((_) {});
    } catch (_) {
      // Sin háptica disponible (tests, escritorio): la partida sigue.
    }
  }
}
