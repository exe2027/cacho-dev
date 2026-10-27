import 'package:flutter/material.dart';

import '../state/match_controller.dart';
import '../state/music.dart';
import 'casino_anims.dart';
import '../state/youtube_api.dart';
import '../theme.dart';

/// Barra compacta de música sobre la mesa: qué suena, quién es el DJ
/// y los controles esenciales. Tocar la barra abre la hoja completa.
///
/// R27 (rediseño): casino oscuro + filete dorado, todo el
/// texto a 14 px. R46: forma plegada por altura escasa — fila de
/// 44 px con icono 44×44 + tema real a 14 px, 1 toque a la hoja,
/// sin controles (los controles viven en la hoja, R30).
class MusicBar extends StatelessWidget {
  final MatchController controller;

  /// R46: forma plegada (sin controles, sin fila de altura libre).
  final bool compact;
  const MusicBar({super.key, required this.controller, this.compact = false});

  String _nameOf(String? id) {
    final c = controller;
    if (id == null) return '';
    if (id == c.myId) return c.myNickname;
    for (final p in c.players) {
      if (p.id == id) return p.nickname;
    }
    return 'Jugador';
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cur = c.musicCurrent;
    final themeText = cur == null
        ? (c.musicDjId == null
            ? 'Música de la sala: sin DJ'
            : 'Música de la sala: sin tema')
        : '${cur.title} · DJ ${_nameOf(c.musicDjId)}';
    final needsTap = cur != null && (c.musicService?.needsTap ?? false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Container(
        // Sin-café menú: casino oscuro + filete dorado 1 px.
        // (Antes leatherDark 0xFF3E2312; solo cambia el fondo de
        // la barra — ni mesa, ni reglas, ni audio.)
        decoration: BoxDecoration(
          color: CachoColors.menuTop.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: CachoColors.gold.withValues(alpha: 0.55)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showMusicSheet(context, c),
            child: compact
                ? _compactRow(themeText, needsTap, c)
                : _fullRow(cur, themeText, needsTap, c),
          ),
        ),
      ),
    );
  }

  /// R46: fila plegada de 44 px — icono 44×44 + tema real a 14 px
  /// (+ Activar si el autoplay está pendiente). Sin controles.
  Widget _compactRow(String themeText, bool needsTap, MatchController c) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.music_note,
                size: 22, color: CachoColors.gold),
          ),
          Expanded(
            child: Text(
              themeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          if (needsTap)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: CachoColors.gold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => c.musicService?.userGesturePlay(),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Activar',
                    style: TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fullRow(MusicTrack? cur, String themeText, bool needsTap,
      MatchController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // AN14: ecualizador vivo solo mientras el DJ suena
          // de verdad (en pausa, barras planas; nunca mide audio).
          if (cur == null)
            const Icon(Icons.music_note, size: 18, color: Colors.white38)
          else
            EqualizerBars(playing: !cur.paused),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              themeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          if (cur != null && c.iAmDj)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: Colors.white,
              icon: Icon(cur.paused ? Icons.play_arrow : Icons.pause),
              onPressed: () => cur.paused ? c.djPlay() : c.djPause(),
            ),
          if (cur != null && c.iAmDj)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: Colors.white,
              icon: const Icon(Icons.skip_next),
              onPressed: () => c.djNext(),
            ),
          if (cur != null && !c.iAmDj)
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44)),
              onPressed: () => c.voteSkipMusic(),
              child: Text(
                'Saltar ${c.musicSkipVotes}/${c.musicSkipNeeded}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          // El navegador frenó el autoplay en ESTE equipo: el
          // tema suena para los demás menos para mí. Un toque
          // lo destraba (así el DJ siempre puede oír lo suyo).
          if (needsTap)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: CachoColors.gold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 44),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => c.musicService?.userGesturePlay(),
                icon: const Icon(Icons.play_arrow, size: 16),
                label:
                    const Text('Activar', style: TextStyle(fontSize: 14)),
              ),
            ),
          Stack(
            children: [
              const Icon(Icons.queue_music, size: 20, color: Colors.white70),
              if (c.musicQueue.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                        minWidth: 22, minHeight: 22),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: CachoColors.casinoRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${c.musicQueue.length}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void showMusicSheet(BuildContext context, MatchController c) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // Fondo hoja música: casino (orden sin-café 25-oct 22:20; antes 0xFF1B1410 marrón oscuro).
    backgroundColor: CachoColors.menuBottom,
    // R42: panel 16.
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => MusicSheet(controller: c),
  );
}

/// La hoja de música: Cola / Buscar / Mi YouTube.
class MusicSheet extends StatefulWidget {
  final MatchController controller;
  const MusicSheet({super.key, required this.controller});

  @override
  State<MusicSheet> createState() => _MusicSheetState();
}

class _MusicSheetState extends State<MusicSheet> {
  final _searchCtrl = TextEditingController();
  List<MusicTrack> _results = [];
  bool _searching = false;
  String? _searchMsg;

  MatchController get c => widget.controller;

  String _nameOf(String? id) {
    if (id == null) return '';
    if (id == c.myId) return '${c.myNickname} (tú)';
    for (final p in c.players) {
      if (p.id == id) return p.nickname;
    }
    return 'Jugador';
  }

  Future<void> _doSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _searchMsg = null;
    });
    try {
      final r = await YoutubeApi.search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searching = false;
        _searchMsg = r.isEmpty ? 'Sin resultados para esa búsqueda.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchMsg = 'No se pudo buscar ahora. Prueba de nuevo.';
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = c.musicService;
    final listenables = <Listenable>[c, if (svc != null) svc];
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        return DefaultTabController(
          length: 3,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MÚSICA DE LA SALA',
                    style: TextStyle(
                      fontFamily: CachoFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: CachoColors.gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const TabBar(
                    indicatorColor: CachoColors.gold,
                    labelColor: CachoColors.gold,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: 'Cola'),
                      Tab(text: 'Buscar'),
                      Tab(text: 'Mi YouTube'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _queueTab(),
                        _searchTab(),
                        _accountTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Cola ----------

  Widget _queueTab() {
    final svc = c.musicService;
    final cur = c.musicCurrent;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // DJ
        Row(
          children: [
            const Icon(Icons.album, size: 18, color: CachoColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.musicDjId == null
                    ? 'Nadie es el DJ todavía'
                    : 'DJ: ${_nameOf(c.musicDjId)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (c.musicDjId == null)
              FilledButton(
                onPressed: () => c.claimDj(),
                child: const Text('Ser el DJ'),
              ),
            if (c.iAmDj)
              TextButton(
                onPressed: () => c.releaseDj(),
                child: const Text('Dejar el rol'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'El DJ controla play, pausa y siguiente. Cualquiera puede '
          'agregar temas a la cola y votar para saltar el que suena.',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const Divider(color: Colors.white12, height: 22),
        // Sonando
        if (cur == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No suena nada. Busca un tema y ponlo: parte solo.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          )
        else ...[
          _trackRow(cur, isCurrent: true),
          const SizedBox(height: 6),
          Row(
            children: [
              if (c.iAmDj) ...[
                IconButton(
                  icon: Icon(cur.paused ? Icons.play_arrow : Icons.pause),
                  color: Colors.white,
                  onPressed: () => cur.paused ? c.djPlay() : c.djPause(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  color: Colors.white,
                  onPressed: () => c.djNext(),
                ),
              ],
              TextButton.icon(
                onPressed: () => c.voteSkipMusic(),
                icon: const Icon(Icons.fast_forward, size: 17),
                label: Text(
                    'Saltar (${c.musicSkipVotes}/${c.musicSkipNeeded})'),
              ),
              const Spacer(),
              Text(
                'lo puso ${_nameOf(cur.byId)}',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ],
        if (svc != null && svc.needsTap) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => svc.userGesturePlay(),
            icon: const Icon(Icons.volume_up),
            label: const Text('Activar la música en mi equipo'),
          ),
          const Text(
            'El navegador exige un toque para dejar sonar la música.',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
        // Cola
        if (c.musicQueue.isNotEmpty) ...[
          const Divider(color: Colors.white12, height: 22),
          const Text(
            'VIENE AHORA',
            style: TextStyle(
                color: CachoColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < c.musicQueue.length; i++)
            _trackRow(
              c.musicQueue[i],
              trailing: (c.iAmDj || c.musicQueue[i].byId == c.myId)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Solo el DJ: este tema suena ahora, la cola espera.
                        if (c.iAmDj)
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill,
                                size: 20, color: CachoColors.gold),
                            tooltip: 'Tocar ahora',
                            onPressed: () =>
                                c.djPlayNowQueued(c.musicQueue[i].videoId),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.white54,
                          onPressed: () => c.removeMusic(i),
                        ),
                      ],
                    )
                  : null,
              subtitle: 'lo puso ${_nameOf(c.musicQueue[i].byId)}',
            ),
        ],
        // Mi volumen
        if (svc != null) ...[
          const Divider(color: Colors.white12, height: 26),
          Row(
            children: [
              const Icon(Icons.volume_down, size: 18, color: Colors.white54),
              Expanded(
                child: Slider(
                  value: svc.myVolume.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  activeColor: CachoColors.gold,
                  onChanged: (v) => svc.setMyVolume(v.round()),
                ),
              ),
              const Icon(Icons.volume_up, size: 18, color: Colors.white54),
              const SizedBox(width: 6),
              Text('${svc.myVolume}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Silenciar la música en mi equipo',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Switch(
                value: svc.silenced,
                activeThumbColor: CachoColors.gold,
                onChanged: (v) => svc.setSilenced(v),
              ),
            ],
          ),
          const Text(
            'La música siempre suena bajo las voces: baja sola a un '
            'susurro mientras cualquier micrófono esté abierto.',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _trackRow(MusicTrack t,
      {bool isCurrent = false, Widget? trailing, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: t.thumb.isEmpty
                ? Container(
                    width: 56,
                    height: 42,
                    color: Colors.white10,
                    child: const Icon(Icons.music_note, color: Colors.white38),
                  )
                : Image.network(
                    t.thumb,
                    width: 56,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 42,
                      color: Colors.white10,
                      child:
                          const Icon(Icons.music_note, color: Colors.white38),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? CachoColors.gold : Colors.white,
                    fontSize: 14,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                Text(
                  [
                    if (t.channel.isNotEmpty) t.channel,
                    if (t.durationSec > 0)
                      YoutubeApi.durationLabel(t.durationSec),
                    if (subtitle != null) subtitle,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ---------- Buscar ----------

  Widget _searchTab() {
    if (!YoutubeApi.hasKey) {
      return const _NotConnected(
        icon: Icons.search_off,
        text: 'El buscador se enciende cuando el proyecto de Google de '
            'la app quede conectado (un paso breve del dueño). La cola, '
            'el DJ y la sincronía ya están funcionando.',
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Busca un tema o un artista…',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: CachoColors.gold),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _doSearch(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searching ? null : _doSearch,
                child: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buscar'),
              ),
            ],
          ),
        ),
        if (_searchMsg != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_searchMsg!,
                style: const TextStyle(color: Colors.white54)),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              for (final t in _results)
                _trackRow(
                  t,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Solo el DJ: tocar AHORA, saltándose la cola.
                      if (c.iAmDj)
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill,
                              color: CachoColors.gold),
                          tooltip: 'Tocar ahora',
                          onPressed: () {
                            c.djPlayNow(t);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sonando ahora: ${t.title}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: CachoColors.gold),
                        tooltip: 'A la cola',
                        onPressed: () {
                          c.addMusic(t);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(c.musicCurrent == null
                                  ? 'Sonando: ${t.title}'
                                  : 'A la cola: ${t.title}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Mi YouTube ----------

  Widget _accountTab() {
    if (!YoutubeApi.hasOAuthClient) {
      return const _NotConnected(
        icon: Icons.account_circle_outlined,
        text: 'Conectar tu cuenta se enciende con el mismo proyecto de '
            'Google. Cuando esté, aquí verás tus playlists — incluidas '
            'las que armas en YouTube Music, que viven en la misma '
            'biblioteca — para ponerlas en la sala con un toque.',
      );
    }
    return const _NotConnected(
      icon: Icons.account_circle_outlined,
      text: 'La conexión de cuentas se activa en el siguiente paso.',
    );
  }
}

class _NotConnected extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NotConnected({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.white24),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
