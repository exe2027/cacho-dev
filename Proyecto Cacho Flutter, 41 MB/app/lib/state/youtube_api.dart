import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'music.dart';

/// Cliente de la API de datos de YouTube (v3): buscar temas y leer
/// las listas de la cuenta enlazada. La búsqueda filtra por videos
/// que PERMITEN ser embebidos (si el dueño bloqueó el embed, el tema
/// ni aparece: no se puede poner en la sala).
class YoutubeApi {
  static bool get hasKey => kYoutubeApiKey.isNotEmpty;
  static bool get hasOAuthClient => kYoutubeOAuthClientId.isNotEmpty;

  static const _base = 'https://www.googleapis.com/youtube/v3';

  /// Duración ISO-8601 de YouTube (PT3M25S, PT1H2M3S) a segundos.
  static int parseDuration(String iso) {
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
    if (m == null) return 0;
    int part(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    return part(1) * 3600 + part(2) * 60 + part(3);
  }

  static String _fmtDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
    return '${h > 0 ? '$h:' : ''}$mm:${s.toString().padLeft(2, '0')}';
  }

  static String durationLabel(int sec) => sec > 0 ? _fmtDuration(sec) : '';

  static Future<List<MusicTrack>> search(String query) async {
    if (!hasKey || query.trim().isEmpty) return [];
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'part': 'snippet',
      'type': 'video',
      'videoEmbeddable': 'true',
      'maxResults': '12',
      'q': query.trim(),
      'key': kYoutubeApiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    final ids = <String>[];
    final byId = <String, MusicTrack>{};
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final id = (raw['id'] as Map<String, dynamic>?)?['videoId'] as String?;
      final sn = raw['snippet'] as Map<String, dynamic>?;
      if (id == null || sn == null) continue;
      ids.add(id);
      byId[id] = MusicTrack(
        videoId: id,
        title: sn['title'] as String? ?? 'Sin título',
        channel: sn['channelTitle'] as String? ?? '',
        thumb: ((sn['thumbnails'] as Map<String, dynamic>?)?['default']
                as Map<String, dynamic>?)?['url'] as String? ??
            '',
        durationSec: 0,
        byId: '',
        byName: '',
      );
    }
    if (ids.isEmpty) return [];
    // Duraciones en una sola llamada extra.
    final durUri = Uri.parse('$_base/videos').replace(queryParameters: {
      'part': 'contentDetails',
      'id': ids.join(','),
      'key': kYoutubeApiKey,
    });
    try {
      final durRes = await http.get(durUri);
      if (durRes.statusCode == 200) {
        final dData = jsonDecode(durRes.body) as Map<String, dynamic>;
        for (final raw in (dData['items'] as List?) ?? []) {
          if (raw is! Map<String, dynamic>) continue;
          final id = raw['id'] as String?;
          final iso = (raw['contentDetails']
              as Map<String, dynamic>?)?['duration'] as String?;
          final old = id != null ? byId[id] : null;
          if (old != null && iso != null) {
            byId[id!] = MusicTrack(
              videoId: old.videoId,
              title: old.title,
              channel: old.channel,
              thumb: old.thumb,
              durationSec: parseDuration(iso),
              byId: old.byId,
              byName: old.byName,
            );
          }
        }
      }
    } catch (_) {}
    return [for (final id in ids) byId[id]!];
  }

  /// Listas de reproducción de la cuenta enlazada (token OAuth del
  /// propio jugador; las de YouTube Music viven en la misma
  /// biblioteca de YouTube).
  static Future<List<({String id, String title, int count})>> myPlaylists(
      String accessToken) async {
    final uri = Uri.parse('$_base/playlists').replace(queryParameters: {
      'part': 'snippet,contentDetails',
      'mine': 'true',
      'maxResults': '25',
    });
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $accessToken',
    });
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final out = <({String id, String title, int count})>[];
    for (final raw in (data['items'] as List?) ?? []) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as String?;
      final title =
          (raw['snippet'] as Map<String, dynamic>?)?['title'] as String?;
      final count = ((raw['contentDetails']
              as Map<String, dynamic>?)?['itemCount'] as num?)
          ?.toInt();
      if (id != null && title != null) {
        out.add((id: id, title: title, count: count ?? 0));
      }
    }
    return out;
  }

  static Future<List<MusicTrack>> playlistTracks(
      String accessToken, String playlistId) async {
    final uri = Uri.parse('$_base/playlistItems').replace(queryParameters: {
      'part': 'snippet',
      'playlistId': playlistId,
      'maxResults': '50',
    });
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $accessToken',
    });
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final out = <MusicTrack>[];
    for (final raw in (data['items'] as List?) ?? []) {
      if (raw is! Map<String, dynamic>) continue;
      final sn = raw['snippet'] as Map<String, dynamic>?;
      final vid = (sn?['resourceId']
          as Map<String, dynamic>?)?['videoId'] as String?;
      if (sn == null || vid == null) continue;
      out.add(MusicTrack(
        videoId: vid,
        title: sn['title'] as String? ?? 'Sin título',
        channel: sn['videoOwnerChannelTitle'] as String? ?? '',
        thumb: ((sn['thumbnails'] as Map<String, dynamic>?)?['default']
                as Map<String, dynamic>?)?['url'] as String? ??
            '',
        durationSec: 0,
        byId: '',
        byName: '',
      ));
    }
    return out;
  }
}
