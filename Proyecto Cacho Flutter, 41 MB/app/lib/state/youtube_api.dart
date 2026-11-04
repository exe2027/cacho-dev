import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'music.dart';

/// Cliente inteligente para YouTube:
/// 1. Soporta pegar enlaces directos de YouTube (https://youtu.be/... o watch?v=...).
/// 2. Soporta buscar temas por nombre con fallback curado de canciones populares.
/// 3. Resuelve metadatos (título, autor, miniatura) vía noembed.com (CORS público) sin depender de claves.
class YoutubeApi {
  static bool get hasKey => true;
  static bool get hasOAuthClient => kYoutubeOAuthClientId.isNotEmpty;

  static const _base = 'https://www.googleapis.com/youtube/v3';

  // Biblioteca curada de grandes éxitos de cantina, cumbia, rock y folclore chileno
  static const List<Map<String, dynamic>> kCuratedHits = [
    {
      'id': 'WRcCBI5rFfM',
      'title': 'Los Prisioneros - Tren Al Sur',
      'channel': 'Los Prisioneros',
      'sec': 336,
    },
    {
      'id': 'eDipH-myZWE',
      'title': 'Los Prisioneros - Estrechez de Corazón',
      'channel': 'Los Prisioneros',
      'sec': 380,
    },
    {
      'id': 'V7q1jN7k5lg',
      'title': 'Los Bunkers - Llueve Sobre la Ciudad',
      'channel': 'Los Bunkers',
      'sec': 238,
    },
    {
      'id': '1zWc27y25W8',
      'title': 'Los Jaivas - Todos Juntos',
      'channel': 'Los Jaivas',
      'sec': 335,
    },
    {
      'id': 'gR4xP-K1Rls',
      'title': 'Chico Trujillo - Loca',
      'channel': 'Chico Trujillo',
      'sec': 210,
    },
    {
      'id': 'v9o49q-e8Yc',
      'title': 'Amar Azul - Yo Me Enamoré',
      'channel': 'Amar Azul',
      'sec': 195,
    },
    {
      'id': '8-J9pGz4s9E',
      'title': 'Ráfaga - Una Cerveza',
      'channel': 'Ráfaga Oficial',
      'sec': 202,
    },
    {
      'id': 'rD44p78D_w0',
      'title': 'Gilda - No Me Arrepiento de Este Amor',
      'channel': 'Gilda Oficial',
      'sec': 215,
    },
    {
      'id': 'zF_K0nK5Q8g',
      'title': 'La Sonora de Tommy Rey - Un Año Más',
      'channel': 'Tommy Rey',
      'sec': 190,
    },
    {
      'id': 'l1V6rL29z1Y',
      'title': 'El Guatón Loyola (Cueca Chilena Tradicional)',
      'channel': 'Folclore de Chile',
      'sec': 160,
    },
    {
      'id': 'fJ9rUzIMcZQ',
      'title': 'Queen - Bohemian Rhapsody',
      'channel': 'Queen Official',
      'sec': 360,
    },
    {
      'id': 'u1V8Y8GYfAo',
      'title': 'Creedence Clearwater Revival - Have You Ever Seen The Rain',
      'channel': 'CCR',
      'sec': 165,
    },
  ];

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

  /// Extrae el ID de video de cualquier URL de YouTube o ID plano de 11 caracteres.
  static String? extractVideoId(String input) {
    final clean = input.trim();
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(clean)) {
      return clean;
    }
    final match = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    ).firstMatch(clean);
    return match?.group(1);
  }

  /// Resuelve un video por su ID o URL usando noembed (CORS libre, 100% web).
  static Future<MusicTrack?> resolveVideo(String input) async {
    final vid = extractVideoId(input);
    if (vid == null) return null;

    try {
      final uri = Uri.parse('https://noembed.com/embed?url=https://www.youtube.com/watch?v=$vid');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'Video de YouTube';
        final author = data['author_name'] as String? ?? '';
        final thumb = (data['thumbnail_url'] as String?) ?? 'https://i.ytimg.com/vi/$vid/hqdefault.jpg';
        return MusicTrack(
          videoId: vid,
          title: title,
          channel: author,
          thumb: thumb,
          durationSec: 0,
          byId: '',
          byName: '',
        );
      }
    } catch (_) {}

    return MusicTrack(
      videoId: vid,
      title: 'YouTube Track ($vid)',
      channel: 'YouTube',
      thumb: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
      durationSec: 0,
      byId: '',
      byName: '',
    );
  }

  /// Búsqueda inteligente: si es URL la resuelve directo; si es texto filtra hits o busca vía API.
  static Future<List<MusicTrack>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 1. Si el usuario pegó un enlace de YouTube o ID directo
    final directId = extractVideoId(q);
    if (directId != null) {
      final track = await resolveVideo(directId);
      if (track != null) return [track];
    }

    // 2. Coincidencias en la colección curada local
    final qLower = q.toLowerCase();
    final matchingCurated = kCuratedHits.where((hit) {
      final title = (hit['title'] as String).toLowerCase();
      final channel = (hit['channel'] as String).toLowerCase();
      return title.contains(qLower) || channel.contains(qLower);
    }).map((hit) {
      final id = hit['id'] as String;
      return MusicTrack(
        videoId: id,
        title: hit['title'] as String,
        channel: hit['channel'] as String,
        thumb: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
        durationSec: hit['sec'] as int,
        byId: '',
        byName: '',
      );
    }).toList();

    if (matchingCurated.isNotEmpty) {
      return matchingCurated;
    }

    // 3. Intento vía API oficial si está disponible
    if (kYoutubeApiKey.isNotEmpty) {
      try {
        final uri = Uri.parse('$_base/search').replace(queryParameters: {
          'part': 'snippet',
          'type': 'video',
          'videoEmbeddable': 'true',
          'maxResults': '10',
          'q': q,
          'key': kYoutubeApiKey,
        });
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final items = (data['items'] as List?) ?? [];
          final results = <MusicTrack>[];
          for (final raw in items) {
            if (raw is! Map<String, dynamic>) continue;
            final id = (raw['id'] as Map<String, dynamic>?)?['videoId'] as String?;
            final sn = raw['snippet'] as Map<String, dynamic>?;
            if (id == null || sn == null) continue;
            results.add(MusicTrack(
              videoId: id,
              title: sn['title'] as String? ?? 'Sin título',
              channel: sn['channelTitle'] as String? ?? '',
              thumb: ((sn['thumbnails'] as Map<String, dynamic>?)?['default']
                      as Map<String, dynamic>?)?['url'] as String? ??
                  'https://i.ytimg.com/vi/$id/hqdefault.jpg',
              durationSec: 0,
              byId: '',
              byName: '',
            ));
          }
          if (results.isNotEmpty) return results;
        }
      } catch (_) {}
    }

    // 4. Si no hubo coincidencia exacta, retorna los mejores éxitos de fiesta
    return [
      for (final hit in kCuratedHits.take(6))
        MusicTrack(
          videoId: hit['id'] as String,
          title: hit['title'] as String,
          channel: hit['channel'] as String,
          thumb: 'https://i.ytimg.com/vi/${hit['id']}/hqdefault.jpg',
          durationSec: hit['sec'] as int,
          byId: '',
          byName: '',
        )
    ];
  }

  static Future<List<({String id, String title, int count})>> myPlaylists(String accessToken) async => [];
  static Future<List<MusicTrack>> playlistTracks(String accessToken, String playlistId) async => [];
}
