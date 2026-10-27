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
