import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../state/yt_player.dart';

/// Anfitrión del reproductor de YouTube NATIVO (solo APK): el
/// WebView tiene que existir en el árbol de widgets para sonar.
/// Vive chiquito e invisible en una esquina de la mesa, igual que
/// el reproductor fantasma de la web (6×6, casi transparente):
/// lo único que importa es el audio.
class NativeYtHost extends StatefulWidget {
  const NativeYtHost({super.key});

  @override
  State<NativeYtHost> createState() => _NativeYtHostState();
}

class _NativeYtHostState extends State<NativeYtHost> {
  Timer? _watch;
  YoutubePlayerController? _shown;

  @override
  void initState() {
    super.initState();
    // El controlador nace cuando la sala tiene música (MusicService
    // crea el reproductor y llama init): se vigila hasta que
    // aparezca y ahí se monta el WebView una sola vez.
    _watch = Timer.periodic(const Duration(milliseconds: 700), (_) {
      final ctrl = YtPlayer.instance?.controller;
      if (ctrl != null && ctrl != _shown && mounted) {
        setState(() => _shown = ctrl);
        YtPlayer.instance?.markHostMounted();
        _watch?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _shown;
    if (ctrl == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: 0.05,
        child: SizedBox(
          width: 8,
          height: 8,
          child: YoutubePlayer(controller: ctrl),
        ),
      ),
    );
  }
}
