import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Voz en vivo entre jugadores de una sala (WebRTC en malla).
///
/// - El audio viaja DIRECTO entre los teléfonos (P2P); el servidor
///   solo releva la señalización (ofertas/respuestas/ICE) por el
///   WebSocket de la sala. Sin servidor de medios ni costo extra.
/// - El micrófono parte APAGADO: cada jugador lo activa tocando el
///   icono sobre su foto. Al activarlo se pide el permiso del sistema.
/// - Sin TURN en el MVP: con STUN público la gran mayoría de las
///   redes domésticas/móviles conecta; algunas redes con NAT
///   simétrica podrían no escucharse (limitación conocida).
class VoiceService {
  VoiceService({
    required this.myId,
    required this.sendSignal,
    required this.onError,
  });

  final String myId;
  final void Function(String to, Map<String, dynamic> data) sendSignal;
  final void Function(String message) onError;

  static const _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  MediaStream? _local;
  final _pcs = <String, RTCPeerConnection>{};
  final _pendingIce = <String, List<RTCIceCandidate>>{};
  final _renderers = <String, RTCVideoRenderer>{};
  bool micOn = false;
  bool _disposed = false;

  bool _isInitiator(String peerId) => myId.compareTo(peerId) < 0;

  Future<void> _ensureLocal() async {
    if (_local != null) return;
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    for (final t in _local!.getAudioTracks()) {
      t.enabled = micOn;
    }
  }

  Future<RTCPeerConnection> _pcFor(String peerId) async {
    final existing = _pcs[peerId];
    if (existing != null) return existing;
    final pc = await createPeerConnection(_config);
    if (_disposed) {
      await pc.close();
      return pc;
    }
    _pcs[peerId] = pc;
    pc.onIceCandidate = (cand) {
      sendSignal(peerId, {
        'kind': 'ice',
        'candidate': cand.candidate,
        'sdpMid': cand.sdpMid,
        'sdpMLineIndex': cand.sdpMLineIndex,
      });
    };
    pc.onTrack = (event) {
      if (event.streams.isEmpty) return;
      // Un renderer por par: en web es lo que hace sonar el audio
      // remoto; en nativo además enruta la pista.
      () async {
        final r = _renderers[peerId] ?? RTCVideoRenderer();
        await r.initialize();
        r.srcObject = event.streams[0];
        _renderers[peerId] = r;
      }();
    };
    if (_local != null) {
      for (final track in _local!.getAudioTracks()) {
        await pc.addTrack(track, _local!);
      }
    }
    return pc;
  }

  Future<void> _offerTo(String peerId) async {
    final pc = await _pcFor(peerId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    sendSignal(peerId, {'kind': 'offer', 'sdp': offer.sdp, 'type': offer.type});
  }

  /// Conecta con un jugador humano de la sala (idempotente). La
  /// oferta la crea siempre el mismo lado (el id menor): sin choques.
  Future<void> connectTo(String peerId) async {
    if (_disposed || peerId == myId || _pcs.containsKey(peerId)) return;
    await _pcFor(peerId);
    if (_isInitiator(peerId)) await _offerTo(peerId);
  }

  Future<void> _flushIce(String peerId, RTCPeerConnection pc) async {
    final pending = _pendingIce.remove(peerId) ?? [];
    for (final cand in pending) {
      try {
        await pc.addCandidate(cand);
      } catch (_) {}
    }
  }

  Future<void> handleSignal(String from, Map<String, dynamic> data) async {
    if (_disposed) return;
    try {
      switch (data['kind']) {
        case 'ice':
          final cand = RTCIceCandidate(
            data['candidate'] as String?,
            data['sdpMid'] as String?,
            (data['sdpMLineIndex'] as num?)?.toInt(),
          );
          final pc = _pcs[from];
          if (pc == null) {
            (_pendingIce[from] ??= []).add(cand);
          } else {
            await pc.addCandidate(cand);
          }
        case 'offer':
          final pc = await _pcFor(from);
          await pc.setRemoteDescription(RTCSessionDescription(
              data['sdp'] as String?, data['type'] as String?));
          await _flushIce(from, pc);
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          sendSignal(
              from, {'kind': 'answer', 'sdp': answer.sdp, 'type': answer.type});
        case 'answer':
          final pc = await _pcFor(from);
          await pc.setRemoteDescription(RTCSessionDescription(
              data['sdp'] as String?, data['type'] as String?));
          await _flushIce(from, pc);
        case 'renegotiate':
          // El par agregó su micrófono: si soy el iniciador, re-oferto.
          if (_isInitiator(from)) await _offerTo(from);
      }
    } catch (e) {
      debugPrint('voz: señal de $from falló: $e');
    }
  }

  /// Activa o apaga MI micrófono. Devuelve false si el permiso fue
  /// denegado (el controlador avisa al jugador).
  Future<bool> setMic(bool on) async {
    if (on) {
      try {
        await _ensureLocal();
      } catch (_) {
        onError('No se pudo usar el micrófono: permiso denegado.');
        return false;
      }
      // Sumar mi pista a las conexiones que aún no la tienen y
      // renegociar (oferta si soy iniciador; si no, la pido).
      for (final peerId in _pcs.keys.toList()) {
        final pc = _pcs[peerId]!;
        final senders = await pc.getSenders();
        final hasAudio = senders.any((s) => s.track?.kind == 'audio');
        if (!hasAudio) {
          for (final track in _local!.getAudioTracks()) {
            await pc.addTrack(track, _local!);
          }
          if (_isInitiator(peerId)) {
            await _offerTo(peerId);
          } else {
            sendSignal(peerId, {'kind': 'renegotiate'});
          }
        }
      }
    }
    micOn = on;
    if (_local != null) {
      for (final t in _local!.getAudioTracks()) {
        t.enabled = on;
      }
    }
    return true;
  }

  void dropPeer(String peerId) {
    _pcs.remove(peerId)?.close();
    _pendingIce.remove(peerId);
    final r = _renderers.remove(peerId);
    if (r != null) {
      r.srcObject = null;
      r.dispose();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final id in _pcs.keys.toList()) {
      dropPeer(id);
    }
    try {
      await _local?.dispose();
    } catch (_) {}
    _local = null;
  }
}
