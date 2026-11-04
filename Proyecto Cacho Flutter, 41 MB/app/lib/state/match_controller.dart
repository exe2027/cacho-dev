import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../table_themes.dart';
import 'active_room.dart';
import 'audio.dart';
import 'music.dart';
import 'settings.dart';
import 'wallet.dart';
import 'voice.dart';

class PlayerView {
  final String id;
  final String nickname;
  final bool isBot;
  final bool connected;
  final int diceCount;
  final bool eliminated;
  final bool ready;

  /// Saldo de monedas (solo en línea, en el lobby).
  final int? balance;

  /// Micrófono de voz activado (solo en línea, humanos).
  final bool micOn;

  /// Cuenta regresiva de reconexión (epoch ms): si el jugador se
  /// desconectó en partida, tiene hasta ese instante para volver
  /// o queda eliminado (regla del usuario, 24-oct).
  final int? dcDeadlineMs;

  /// GANCHOS cosméticos (enmienda 11c + sentencia F2/C, SOLO
  /// campos, sin compra ni precios): identificador de piel de vaso
  /// (visible para todos los espectadores en la mesa) y de piel de
  /// dados (visible solo para el dueño; en dispositivos ajenos los
  /// dados se renderizan estándar). El servidor hoy NO los envía:
  /// son null hasta que exista el campo compartido en el estado
  /// del servidor, así que la visibilidad rival NO es verificable
  /// en esta pasada (condición C.5 pendiente).
  final String? cupSkinId;
  final String? diceSkinId;
  const PlayerView({
    required this.id,
    required this.nickname,
    required this.isBot,
    required this.connected,
    required this.diceCount,
    required this.eliminated,
    required this.ready,
    this.balance,
    this.micOn = false,
    this.dcDeadlineMs,
    this.cupSkinId,
    this.diceSkinId,
  });

  PlayerView copyWith({bool? micOn}) => PlayerView(
        id: id,
        nickname: nickname,
        isBot: isBot,
        connected: connected,
        diceCount: diceCount,
        eliminated: eliminated,
        ready: ready,
        balance: balance,
        micOn: micOn ?? this.micOn,
        dcDeadlineMs: dcDeadlineMs,
        cupSkinId: cupSkinId,
        diceSkinId: diceSkinId,
      );
}

class UiEvent {
  final String playerId;
  final String type;
  final Bid? bid;
  const UiEvent(this.playerId, this.type, this.bid);
  factory UiEvent.fromEngine(GameEvent e) =>
      UiEvent(e.playerId, e.type.name, e.bid);
  factory UiEvent.fromJson(Map<String, dynamic> j) => UiEvent(
        j['playerId'] as String,
        j['type'] as String,
        j['bid'] == null
            ? null
            : Bid((j['bid'] as Map)['quantity'] as int,
                (j['bid'] as Map)['face'] as int),
      );
}

class UiResolution {
  final String type;
  final String? loserId;
  final String? gainerId;
  final Map<String, List<int>> revealed;
  final int? actualCount;
  final int? kamikazeFace;
  final Map<String, int> kamikazeLosses;

  /// Calzo perfecto con los 5 dados: perdieron un dado todos estos.
  final List<String> massLoserIds;

  /// Calzo/CalzoPaso exacto pero SIN recuperación (regla 25-oct):
  /// el calzador no ganó ni perdió (total en mesa ≤ mitad del
  /// inicial). En ese caso gainerId y loserId son null: ningún
  /// código puede inferir "falló" solo de gainerId == null.
  final bool recoveryBlocked;

  /// Contexto capturado al momento de resolverse (para el veredicto en
  /// una oración): quién desafió, quién había apostado y qué se apostó.
  final String? challengerId;
  final String? bidderId;
  final Bid? bid;
  final String? pasoPlayerId;
  const UiResolution({
    required this.type,
    this.loserId,
    this.gainerId,
    this.revealed = const {},
    this.actualCount,
    this.kamikazeFace,
    this.kamikazeLosses = const {},
    this.massLoserIds = const [],
    this.recoveryBlocked = false,
    this.challengerId,
    this.bidderId,
    this.bid,
    this.pasoPlayerId,
  });

  UiResolution withContext({
    String? challengerId,
    String? bidderId,
    Bid? bid,
    String? pasoPlayerId,
  }) =>
      UiResolution(
        type: type,
        loserId: loserId,
        gainerId: gainerId,
        revealed: revealed,
        actualCount: actualCount,
        kamikazeFace: kamikazeFace,
        kamikazeLosses: kamikazeLosses,
        massLoserIds: massLoserIds,
        recoveryBlocked: recoveryBlocked,
        challengerId: challengerId,
        bidderId: bidderId,
        bid: bid,
        pasoPlayerId: pasoPlayerId,
      );
  factory UiResolution.fromEngine(Resolution r) => UiResolution(
        type: r.type.name,
        loserId: r.loserId,
        gainerId: r.gainerId,
        revealed: r.revealedHands,
        actualCount: r.actualCount,
        kamikazeFace: r.kamikazeFace,
        kamikazeLosses: r.kamikazeLosses,
        massLoserIds: r.massLoserIds,
        recoveryBlocked: r.recoveryBlocked,
      );
  factory UiResolution.fromJson(Map<String, dynamic> j) => UiResolution(
        type: j['type'] as String,
        loserId: j['loserId'] as String?,
        gainerId: j['gainerId'] as String?,
        revealed: ((j['revealedHands'] as Map?) ?? {}).map(
          (k, v) =>
              MapEntry(k.toString(), (v as List).map((e) => e as int).toList()),
        ),
        actualCount: j['actualCount'] as int?,
        kamikazeFace: j['kamikazeFace'] as int?,
        kamikazeLosses: ((j['kamikazeLosses'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), v as int)),
        massLoserIds: ((j['massLoserIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        recoveryBlocked: j['recoveryBlocked'] as bool? ?? false,
      );
}

// Banco de nombres de bots: NICKNAMES Y GAMERTAGS DE JUEGO EN LÍNEA (Sin nombres de personas reales)
const _botNames = [
  'xX_Shadow_Xx',
  'CyberWolf_77',
  'K1ng_Player',
  'x_DarkViper_x',
  'Lobo_21',
  'Pro_Gamer99',
  'NeonRider_26',
  'Sn1p3r_Dice',
  'Ghost_88',
  'Master_007',
  'El_Matad0r',
  'B0tt_Smash3r',
  'PokerFace_99',
  'Dark_K1ng',
  'Zero_Cool_99',
  'TitanDice_404',
  'Th3_B0ss',
  'Viper_Pro',
  'IronDudo_12',
  'V01d_Walk3r',
  'Quantum_42',
  'Alpha_Strike',
  'ShadowFox_09',
  'Dark-Specter',
  'L3g3nd_Dudo',
  'Apex_01',
  'Neo_Matrix_88',
  'xX_Slayer_Xx',
  'GoldHunter777',
  'Phantom_Dice',
  'Cr4zy_D1ce',
  'OmegaDice_88',
  'Steel_Titan',
  'St0rm_R1der',
  'Falcon_99',
  'UltraInstinct',
  'Bl4ck_Lotus',
  'Valkyrie_13',
  'Rogue_77',
  'Pwn3r_99',
  'DragonFury_07',
  'Delta_Force',
];

String cleanSingleWordName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'Jugador';
  final first = trimmed.split(RegExp(r'\s+')).first;
  return first.length > 16 ? first.substring(0, 16) : first;
}

/// Controlador de una partida: la misma pantalla sirve para el modo local
/// contra bots (motor Dart en el propio teléfono) y para salas en línea
/// (el servidor manda; aquí solo se refleja su estado).
class MatchController extends ChangeNotifier {
  static MatchController? activeSession;

  bool get isGameOver => phase == 'finished' || winnerId != null;
  final bool online;
  final GameConfig uiConfig;
  final Duration botDelay;
  final Random _botRng = Random();
  final bool useTurnTimer;

  String myId = '';
  String myNickname = '';
  String? roomCode;
  String? deviceToken;
  String? hostId;
  bool isHost = false;
  bool connected = true;
  bool gameStarted = false;
  DateTime? gameStartTime;

  List<PlayerView> players = [];
  String phase = 'lobby';
  int round = 0;
  Bid? currentBid;
  String? lastBidderId;
  String? currentPlayerId;
  String? pendingPasoId;
  String? kamikazeOfferId;
  String? kamikazeActivatorId;
  bool canCalzo = false;
  int calzoThreshold = 0;
  int totalDice = 0;
  List<int> myHand = [];
  String? winnerId;

  // ----- monedas -----
  /// Apuesta por jugador de esta partida (0 = sin apuesta).
  int stake = 0;

  /// Pozo total (apuesta × jugadores).
  int pot = 0;

  /// Pozo FIJADO al partir (sentencia v2.0, B8): el pozo que se
  /// muestra y se reparte no se recalcula si alguien sale o es
  /// eliminado. En local se fija en startLocal; en línea lo fija
  /// el servidor al partir y viaja en el estado.
  int? potFixed;

  /// Pozo a mostrar: el fijado si existe, si no el vivo.
  int get displayPot => potFixed ?? pot;

  /// Mesa temática de esta partida (Fase A v2.0): viaja con la
  /// sala; en local la elige el jugador, en línea el anfitrión.
  String tableTheme = defaultTableTheme;

  /// Parámetros de la partida local, para la revancha (B4).
  int localBotCount = 0;
  String localDifficultyName = 'media';

  /// Saldo según el servidor (solo en línea).
  int? serverBalance;

  /// Yo gané el pozo (para la celebración con monedas).
  bool potWonByMe = false;
  bool _coinsSettled = false;
  bool isDraw = false;
  List<UiEvent> events = [];
  UiResolution? uiResolution;
  int resolutionSeq = 0;

  /// Reacciones rápidas (docs/19 C9, chat fuera). Conjunto fijo de
  /// 5 glifos; la UI los muestra flotando sobre el avatar del
  /// remitente y los retira a los ~2 s (la pantalla programa la
  /// retirada con `clearEmote`). LOCAL: completo, sin servidor.
  /// EN LÍNEA: el servidor difunde el glifo a la sala (relay
  /// `case 'emote'` en manager.js, 26-oct) y la recepción
  /// (`case 'emote'` abajo) lo muestra; ningún mensaje existente
  /// cambia de forma.
  static const List<String> emotes = ['😂', '👏', '👍', '😮', '🔥'];
  String? emotePlayerId;
  String? emoteGlyph;
  int emoteSeq = 0;

  /// Muestra una reacción o frase rápida (local o recibida del
  /// servidor). No toca mano, turno ni apuesta.
  void showEmote(String playerId, String glyph) {
    final clean = glyph.trim();
    if (clean.isEmpty) return;
    emotePlayerId = playerId;
    emoteGlyph = clean;
    emoteSeq++;
    notifyListeners();
  }

  /// Reacción mía. En línea se muestra en local y se envía al
  /// servidor, que la difunde a la sala (relay 26-oct). No toca
  /// mano, turno ni apuesta.

  void pauseTimers() {
    _botTimer?.cancel();
    _turnTimer?.cancel();
    _music?.player.pause();
    notifyListeners();
  }

  void resumeTimers() {
    if (_disposed || isGameOver) return;
    if (!online && _engine != null) {
      _scheduleLocal();
    }
    notifyListeners();
  }

  void pauseMusic() {
    try {
      _music?.player.pause();
    } catch (_) {}
  }

  bool sendQuickChat(String text) {
    final clean = text.trim();
    if (myId.isEmpty || clean.isEmpty) return false;
    showEmote(myId, clean);
    if (online) _send({'type': 'chat', 'message': clean});
    return true;
  }

  bool sendEmote(String glyph) {
    if (!emotes.contains(glyph)) return false;
    if (myId.isEmpty) return false;
    showEmote(myId, glyph);
    if (online) _send({'type': 'emote', 'emote': glyph});
    return true;
  }

  /// Retira la reacción mostrada, solo si sigue siendo esa
  /// secuencia (evita borrar una reacción más nueva).
  void clearEmote(int seq) {
    if (emoteSeq != seq) return;
    emotePlayerId = null;
    emoteGlyph = null;
    notifyListeners();
  }

  String? errorMessage;
  String? lastNotice;
  bool handHidden = true;

  /// Fin del turno actual (para el aro-temporizador). Null si no corre.
  DateTime? turnEndsAt;

  /// Última jugada de cada jugador (globos de la mesa).
  final Map<String, UiEvent> lastActionBy = {};

  /// Motivo en una línea de la última jugada de cada bot (local/guiada).
  final Map<String, String> botReasonBy = {};

  /// Historial completo agrupado por ronda (cajón de historial).
  final Map<int, List<UiEvent>> historyByRound = {};
  final Map<int, UiResolution> resolutionByRound = {};

  /// Partida guiada (primera vez): bots lentos que explican.
  bool guided = false;

  // Local
  GameEngine? _engine;
  final Map<String, BotBrain> _brains = {};
  Timer? _botTimer;
  Timer? _turnTimer;

  /// Tiempos de turno vencidos seguidos (solo local): al tercero,
  /// eliminado por abandono, igual que en las salas en línea.
  int _myStrikes = 0;
  int _lastRound = 0;

  // Música de la sala (DJ de YouTube; ver music.dart)
  MusicService? _music;
  MusicService? get musicService => _music;
  String? get musicDjId => _music?.djId;
  MusicTrack? get musicCurrent => _music?.current;
  List<MusicTrack> get musicQueue => _music?.queue ?? const [];
  int get musicSkipVotes => _music?.skipVotes ?? 0;
  int get musicSkipNeeded => _music?.skipNeeded ?? 2;
  bool get iAmDj => _music != null && _music!.djId == myId;

  bool get anyMicOpen =>
      myMicOn || _micById.values.any((v) => v) || players.any((p) => p.micOn);

  void _ensureMusic() {
    if (_music != null) return;
    final svc = MusicService();
    svc.anyMicOn = () => anyMicOpen;
    svc.onEnded = () {
      if (online) {
        _send({'type': 'music_ended'});
      } else {
        djNext();
      }
    };
    svc.onActiveChanged = (active) {
      AudioService.djTakeover = active;
      AudioService.instance.syncAmbience();
    };
    // La barra de música (botón "Activar", DJ, tema) se repinta con
    // los cambios del servicio, no solo con los del controlador.
    svc.addListener(() {
      if (!_disposed) notifyListeners();
    });
    _music = svc;
  }

  /// Cambiar mi nombre estando dentro de la sala (pedido del
  /// usuario, 24-oct): el servidor lo valida y lo difunde a toda
  /// la sala; también queda como mi nombre de perfil guardado.
  void renameMe(String name) {
    final clean = name.trim();
    if (clean.isEmpty || !online) return;
    myNickname = clean;
    Settings.instance.nickname = clean;
    Settings.instance.save();
    _send({'type': 'set_nickname', 'nickname': clean});
    notifyListeners();
  }

  void claimDj() {
    _ensureMusic();
    if (online) {
      _send({'type': 'music_claim'});
    } else {
      _applyLocalMusicState(djId: myId);
    }
  }

  void releaseDj() {
    if (online) {
      _send({'type': 'music_release'});
    } else {
      _applyLocalMusicState(djId: null);
    }
  }

  void addMusic(MusicTrack t) {
    _ensureMusic();
    _music?.primeWithGesture();
    if (online) {
      _send({'type': 'music_add', ...t.toAddJson()});
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cur = _music?.current;
      final q = List<MusicTrack>.from(_music?.queue ?? []);
      if (cur == null) {
        final track = MusicTrack(
          videoId: t.videoId,
          title: t.title,
          channel: t.channel,
          thumb: t.thumb,
          durationSec: t.durationSec,
          byId: myId,
          byName: myNickname,
          startedAt: now,
        );
        _applyLocalMusicState(djId: myId, current: track, queue: q);
      } else {
        q.add(MusicTrack(
          videoId: t.videoId,
          title: t.title,
          channel: t.channel,
          thumb: t.thumb,
          durationSec: t.durationSec,
          byId: myId,
          byName: myNickname,
        ));
        _applyLocalMusicState(djId: _music?.djId ?? myId, current: cur, queue: q);
      }
    }
  }

  /// El DJ se salta la cola: este tema suena AHORA (recién buscado).
  void djPlayNow(MusicTrack t) {
    _ensureMusic();
    _music?.primeWithGesture();
    if (online) {
      _send({'type': 'music_play_now', ...t.toAddJson()});
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final track = MusicTrack(
        videoId: t.videoId,
        title: t.title,
        channel: t.channel,
        thumb: t.thumb,
        durationSec: t.durationSec,
        byId: myId,
        byName: myNickname,
        startedAt: now,
      );
      _applyLocalMusicState(djId: myId, current: track, queue: _music?.queue ?? []);
    }
  }

  /// El DJ se salta la cola: suena ahora este tema que ya esperaba.
  void djPlayNowQueued(String videoId) {
    _ensureMusic();
    _music?.primeWithGesture();
    if (online) {
      _send({'type': 'music_play_now', 'videoId': videoId});
    } else {
      final q = List<MusicTrack>.from(_music?.queue ?? []);
      final idx = q.indexWhere((x) => x.videoId == videoId);
      if (idx != -1) {
        final t = q.removeAt(idx);
        final now = DateTime.now().millisecondsSinceEpoch;
        final track = MusicTrack(
          videoId: t.videoId,
          title: t.title,
          channel: t.channel,
          thumb: t.thumb,
          durationSec: t.durationSec,
          byId: t.byId,
          byName: t.byName,
          startedAt: now,
        );
        _applyLocalMusicState(djId: myId, current: track, queue: q);
      }
    }
  }

  void removeMusic(int index) {
    if (online) {
      _send({'type': 'music_remove', 'index': index});
    } else {
      final q = List<MusicTrack>.from(_music?.queue ?? []);
      if (index >= 0 && index < q.length) {
        q.removeAt(index);
        _applyLocalMusicState(djId: _music?.djId ?? myId, current: _music?.current, queue: q);
      }
    }
  }

  void djPlay() {
    if (online) {
      _send({'type': 'music_play'});
    } else {
      final cur = _music?.current;
      if (cur != null && cur.paused) {
        final pausedDuration = cur.pausedAt != null
            ? DateTime.now().millisecondsSinceEpoch - cur.pausedAt!
            : 0;
        final track = MusicTrack(
          videoId: cur.videoId,
          title: cur.title,
          channel: cur.channel,
          thumb: cur.thumb,
          durationSec: cur.durationSec,
          byId: cur.byId,
          byName: cur.byName,
          startedAt: cur.startedAt + pausedDuration,
          pausedAt: null,
        );
        _applyLocalMusicState(djId: _music?.djId ?? myId, current: track, queue: _music?.queue ?? []);
      }
    }
  }

  void djPause() {
    if (online) {
      _send({'type': 'music_pause'});
    } else {
      final cur = _music?.current;
      if (cur != null && !cur.paused) {
        final track = MusicTrack(
          videoId: cur.videoId,
          title: cur.title,
          channel: cur.channel,
          thumb: cur.thumb,
          durationSec: cur.durationSec,
          byId: cur.byId,
          byName: cur.byName,
          startedAt: cur.startedAt,
          pausedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _applyLocalMusicState(djId: _music?.djId ?? myId, current: track, queue: _music?.queue ?? []);
      }
    }
  }

  void djNext() {
    if (online) {
      _send({'type': 'music_next'});
    } else {
      final q = List<MusicTrack>.from(_music?.queue ?? []);
      if (q.isNotEmpty) {
        final nextTrack = q.removeAt(0);
        final now = DateTime.now().millisecondsSinceEpoch;
        final track = MusicTrack(
          videoId: nextTrack.videoId,
          title: nextTrack.title,
          channel: nextTrack.channel,
          thumb: nextTrack.thumb,
          durationSec: nextTrack.durationSec,
          byId: nextTrack.byId,
          byName: nextTrack.byName,
          startedAt: now,
        );
        _applyLocalMusicState(djId: _music?.djId ?? myId, current: track, queue: q);
      } else {
        _applyLocalMusicState(djId: _music?.djId ?? myId, current: null, queue: []);
      }
    }
  }

  void voteSkipMusic() {
    if (online) {
      _send({'type': 'music_vote_skip'});
    } else {
      djNext();
    }
  }

  void _applyLocalMusicState({
    String? djId,
    MusicTrack? current,
    List<MusicTrack>? queue,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _music?.applyState({
      'djId': djId,
      'current': current == null
          ? null
          : {
              'videoId': current.videoId,
              'title': current.title,
              'channel': current.channel,
              'thumb': current.thumb,
              'durationSec': current.durationSec,
              'byId': current.byId,
              'byName': current.byName,
              'startedAt': current.startedAt,
              'pausedAt': current.pausedAt,
            },
      'queue': [
        for (final t in (queue ?? _music?.queue ?? []))
          {
            'videoId': t.videoId,
            'title': t.title,
            'channel': t.channel,
            'thumb': t.thumb,
            'durationSec': t.durationSec,
            'byId': t.byId,
            'byName': t.byName,
          }
      ],
      'skipVotes': 0,
      'skipNeeded': 1,
      'sentAt': now,
    });
    notifyListeners();
  }

  // Voz en línea (WebRTC en malla; ver voice.dart)
  VoiceService? _voice;
  bool myMicOn = false;
  final Map<String, bool> _micById = {};

  // En línea
  final String? _serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _heartbeat;
  bool _disposed = false;
  int _handRound = 0;

  MatchController._({
    required this.online,
    required this.uiConfig,
    this.botDelay = const Duration(milliseconds: 1800),
    this.useTurnTimer = true,
    String? serverUrl,
  }) : _serverUrl = serverUrl;

  // ---------- construcción: local ----------

  factory MatchController.local({
    required String nickname,
    required int botCount,
    required BotDifficulty difficulty,
    required GameConfig config,
    DiceRoller? roller,
    Duration botDelay = const Duration(milliseconds: 1800),
    bool useTurnTimer = true,
    bool guided = false,
    int stake = 0,
    String tableTheme = defaultTableTheme,
    List<String>? customBotNames,
  }) {
    final c = MatchController._(
      online: false,
      uiConfig: config,
      botDelay: guided ? const Duration(milliseconds: 2400) : botDelay,
      useTurnTimer: useTurnTimer,
    );
    c.guided = guided;
    c.stake = guided ? 0 : stake;
    c.tableTheme =
        isValidTableTheme(tableTheme) ? tableTheme : defaultTableTheme;
    c.localBotCount = botCount;
    c.localDifficultyName = difficulty.name;
    final cleanUser = cleanSingleWordName(nickname);
    c.myNickname = cleanUser;
    c.myId = 'yo';
    c.isHost = true;
    final list = <({String id, String name})>[
      (id: 'yo', name: cleanUser),
    ];

    // Emparejar con contrincantes asignados o aleatorios únicos
    final rng = Random();
    final List<String> chosenBots;
    if (customBotNames != null && customBotNames.length >= botCount) {
      chosenBots = customBotNames.take(botCount).toList();
    } else {
      final availableBots = List<String>.from(_botNames)..shuffle(rng);
      availableBots.removeWhere((b) => b.toLowerCase() == cleanUser.toLowerCase());
      chosenBots = availableBots.take(botCount).toList();
    }

    for (var i = 0; i < botCount; i++) {
      final id = 'bot${i + 1}';
      final botName = chosenBots[i];
      list.add((id: id, name: botName));
      final bDiff = (i % 2 == 0)
          ? difficulty
          : (rng.nextBool() ? BotDifficulty.media : difficulty);
      c._brains[id] = BotBrain(bDiff);
    }
    c._engine = GameEngine(
      config: config,
      roller: roller ?? RandomDiceRoller(),
      playerList: list,
    );
    activeSession = c;
    return c;
  }

  void startLocal() {
    // Cobro de la apuesta: si no alcanza (no debería pasar: la hoja
    // de configuración bloquea esos montos), la partida va sin apuesta.
    if (stake > 0 && !Wallet.instance.charge(stake)) stake = 0;
    pot = stake * _engine!.players.length;
    potFixed = pot;
    _engine!.startGame();
    gameStarted = true;
    gameStartTime = DateTime.now();
    _syncLocal();
    notifyListeners();
    _scheduleLocal();
  }

  // ---------- construcción: en línea ----------

  factory MatchController.onlineCreate({
    required String nickname,
    required String preset,
    required GameConfig config,
    int stake = 500,
    String tableTheme = defaultTableTheme,
  }) {
    final c = MatchController._(
        online: true, uiConfig: config, serverUrl: kServerUrl);
    c.myNickname = nickname;
    c.stake = stake;
    c.tableTheme =
        isValidTableTheme(tableTheme) ? tableTheme : defaultTableTheme;
    c._connect();
    c._send({
      'type': 'create_room',
      'nickname': nickname,
      'preset': preset,
      'stake': stake,
      'theme': c.tableTheme,
      'walletToken': Wallet.instance.token,
    });
    return c;
  }

  /// Revancha local (B4, sentencia v2.0): misma mesa, mismos bots,
  /// misma dificultad, misma apuesta y misma mesa temática, en un
  /// toque. La cobra la nueva partida al partir, como siempre.
  MatchController rematchLocal() {
    final c = MatchController.local(
      nickname: myNickname,
      botCount: localBotCount,
      difficulty: BotDifficulty.values.byName(localDifficultyName),
      config: uiConfig,
      stake: stake,
      tableTheme: tableTheme,
      guided: guided,
    );
    return c;
  }

  factory MatchController.onlineJoin({
    required String nickname,
    required String code,
    required GameConfig config,
  }) {
    final c = MatchController._(
        online: true, uiConfig: config, serverUrl: kServerUrl);
    c.myNickname = nickname;
    c._connect();
    c._send({
      'type': 'join_room',
      'nickname': nickname,
      'code': code.toUpperCase(),
      'walletToken': Wallet.instance.token,
    });
    return c;
  }

  /// ¿El servidor de salas responde? (para habilitar "Con amigos").
  static Future<bool> probeServer() async {
    try {
      final ch = WebSocketChannel.connect(Uri.parse(kServerUrl));
      await ch.ready.timeout(const Duration(seconds: 5));
      await ch.sink.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Vuelve a una sala en curso recuperando el asiento con la
  /// identidad persistente del dispositivo (token de billetera):
  /// el jugador que se salió sin querer del navegador ya no tiene
  /// el playerId/deviceToken de su sesión anterior.
  factory MatchController.onlineRejoin({
    required String nickname,
    required String code,
    required GameConfig config,
  }) {
    final c = MatchController._(
        online: true, uiConfig: config, serverUrl: kServerUrl);
    c.myNickname = nickname;
    c._connect();
    c._send({
      'type': 'rejoin',
      'code': code.toUpperCase(),
      'walletToken': Wallet.instance.token,
    });
    return c;
  }

  /// Estado de una sala sin entrar a ella (aviso "Entrar a la sala
  /// activa" del inicio). null = no se pudo preguntar.
  static Future<({bool exists, String phase, bool member})?> probeRoom(
      String code) async {
    try {
      final ch = WebSocketChannel.connect(Uri.parse(kServerUrl));
      await ch.ready.timeout(const Duration(seconds: 5));
      ch.sink.add(jsonEncode({
        'type': 'room_status',
        'code': code.toUpperCase(),
        'walletToken': Wallet.instance.token,
      }));
      final raw = await ch.stream
          .map((d) => jsonDecode(d as String) as Map<String, dynamic>)
          .firstWhere((m) => m['type'] == 'room_status')
          .timeout(const Duration(seconds: 5));
      await ch.sink.close();
      return (
        exists: raw['exists'] == true,
        phase: (raw['phase'] as String?) ?? '',
        member: raw['member'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  void _connect() {
    // Latido cada 25 s: mantiene viva la conexión en el lobby
    // (intermediarios y el propio borde cierran sockets ociosos;
    // el servidor responde 'pong'). Sin esto, una sala en espera
    // podía caerse en silencio pasado un rato.
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      if (connected) _send({'type': 'ping'});
    });
    _channel = WebSocketChannel.connect(Uri.parse(_serverUrl!));
    _sub = _channel!.stream.listen(
      (data) {
        try {
          _onServerMessage(jsonDecode(data as String) as Map<String, dynamic>);
        } catch (_) {}
      },
      onDone: _onSocketClosed,
      onError: (_) => _onSocketClosed(),
    );
  }

  void _onSocketClosed() {
    if (_disposed || !online) return;
    connected = false;
    notifyListeners();
    // Reconexión: a los 2 s se intenta volver con el token del asiento.
    if (deviceToken != null && roomCode != null) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 2), () {
        if (_disposed) return;
        _connect();
        _send({
          'type': 'rejoin',
          'code': roomCode,
          'playerId': myId,
          'deviceToken': deviceToken,
        });
      });
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  void _ensureVoice() {
    if (!online || _voice != null || myId.isEmpty) return;
    _voice = VoiceService(
      myId: myId,
      sendSignal: (to, data) =>
          _send({'type': 'voice_signal', 'to': to, 'data': data}),
      onError: (msg) => lastNotice = msg,
    );
  }

  /// Conecta/desconecta la malla según los humanos presentes.
  void _syncVoicePeers() {
    final v = _voice;
    if (v == null) return;
    final humans = players
        .where((p) => !p.isBot && p.id != myId && p.connected)
        .map((p) => p.id)
        .toSet();
    for (final id in humans) {
      v.connectTo(id);
    }
    // Los que se fueron se detectan por diferencia con la lista
    // anterior de pares: VoiceService no expone sus pares, así que
    // el controlador lleva la cuenta.
    for (final id in _voicePeers.difference(humans)) {
      v.dropPeer(id);
    }
    _voicePeers
      ..clear()
      ..addAll(humans);
  }

  final Set<String> _voicePeers = {};

  /// Mi micrófono: pide permiso la primera vez (en línea); avisa por el
  /// servidor para que el icono se encienda en todas las mesas.
  /// En partidas locales o sin WebRTC alterna el estado local y activa
  /// el ducking de la rocola inmediatamente.
  Future<void> toggleMic() async {
    final v = _voice;
    if (v != null) {
      final next = !myMicOn;
      final ok = await v.setMic(next);
      if (!ok) {
        notifyListeners();
        return;
      }
      myMicOn = next;
      _micById[myId] = next;
      _send({'type': 'mic', 'on': next});
      players = [
        for (final p in players) p.id == myId ? p.copyWith(micOn: next) : p,
      ];
    } else {
      myMicOn = !myMicOn;
      _micById[myId] = myMicOn;
    }
    _music?.syncVolume();
    notifyListeners();
  }

  void setLocalMic(bool on) {
    myMicOn = on;
    _micById[myId] = on;
    _music?.syncVolume();
    notifyListeners();
  }

  void _onServerMessage(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'room_created':
      case 'joined':
        myId = m['playerId'] as String;
        roomCode = m['code'] as String;
        deviceToken = m['deviceToken'] as String;
        isHost = m['type'] == 'room_created';
        connected = true;
        serverBalance = (m['balance'] as num?)?.toInt();
        // Sala activa: si sale sin querer del navegador, al volver
        // la app le ofrece reentrar (ver ActiveRoomStore).
        ActiveRoomStore.save(roomCode!);
      case 'balance':
        serverBalance = (m['balance'] as num?)?.toInt();
      case 'rejoined':
        roomCode = m['code'] as String;
        myId = m['playerId'] as String;
        if (m['deviceToken'] is String) {
          deviceToken = m['deviceToken'] as String;
        }
        connected = true;
        serverBalance = (m['balance'] as num?)?.toInt() ?? serverBalance;
        ActiveRoomStore.save(roomCode!);
      case 'lobby':
        hostId = m['hostId'] as String?;
        isHost = m['hostId'] == myId;
        stake = (m['stake'] as num?)?.toInt() ?? stake;
        pot = stake * ((m['players'] as List?)?.length ?? 0);
        potFixed = null;
        if (isValidTableTheme(m['theme'] as String?)) {
          tableTheme = m['theme'] as String;
        }
        if (m['myBalance'] is num) {
          serverBalance = (m['myBalance'] as num).toInt();
        }
        players = ((m['players'] as List?) ?? []).map((p) {
          final j = p as Map<String, dynamic>;
          return PlayerView(
            id: j['id'] as String,
            nickname: j['nickname'] as String,
            isBot: j['isBot'] as bool,
            connected: j['connected'] as bool,
            diceCount: uiConfig.dicePerPlayer,
            eliminated: false,
            ready: j['ready'] as bool,
            balance: (j['balance'] as num?)?.toInt(),
            micOn:
                _micById[j['id'] as String] ?? (j['micOn'] as bool? ?? false),
          );
        }).toList();
      case 'game_started':
        gameStarted = true;
        gameStartTime ??= DateTime.now();
        phase = 'playing';
      case 'state':
        final s = m['state'] as Map<String, dynamic>;
        phase = s['phase'] as String;
        if (phase == 'playing') {
          gameStarted = true;
          gameStartTime ??=
              DateTime.now(); // También al reingresar a una partida.
        }
        round = s['round'] as int;
        currentBid = s['currentBid'] == null
            ? null
            : Bid((s['currentBid'] as Map)['quantity'] as int,
                (s['currentBid'] as Map)['face'] as int);
        lastBidderId = s['lastBidderId'] as String?;
        currentPlayerId = s['currentPlayerId'] as String?;
        pendingPasoId = s['pendingPasoPlayerId'] as String?;
        kamikazeOfferId = s['kamikazeOfferPlayerId'] as String?;
        kamikazeActivatorId = s['kamikazeActivatorId'] as String?;
        canCalzo = s['canCalzo'] as bool;
        calzoThreshold = s['calzoThresholdDice'] as int;
        totalDice = s['totalDiceInPlay'] as int;
        winnerId = s['winnerId'] as String?;
        isDraw = s['isDraw'] as bool;
        stake = (s['stake'] as num?)?.toInt() ?? stake;
        pot = (s['pot'] as num?)?.toInt() ?? pot;
        if (s['potFixed'] is num) potFixed = (s['potFixed'] as num).toInt();
        if (isValidTableTheme(s['theme'] as String?)) {
          tableTheme = s['theme'] as String;
        }
        players = ((s['players'] as List?) ?? []).map((p) {
          final j = p as Map<String, dynamic>;
          return PlayerView(
            id: j['id'] as String,
            nickname: j['nickname'] as String,
            isBot: j['isBot'] as bool,
            connected: j['connected'] as bool,
            diceCount: j['diceCount'] as int,
            eliminated: j['eliminated'] as bool,
            ready: true,
            micOn:
                _micById[j['id'] as String] ?? (j['micOn'] as bool? ?? false),
            dcDeadlineMs: (j['dcDeadline'] as num?)?.toInt(),
            cupSkinId: j['cupSkinId'] as String?,
            diceSkinId: j['diceSkinId'] as String?,
          );
        }).toList();
        events = ((s['events'] as List?) ?? [])
            .map((e) => UiEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        final endsAt = s['turnEndsAt'] as int?;
        turnEndsAt =
            endsAt == null ? null : DateTime.fromMillisecondsSinceEpoch(endsAt);
        _absorbEvents();
        if (round != _lastRound) {
          handHidden = true;
          _lastRound = round;
        }
      case 'your_hand':
        myHand = ((m['dice'] as List?) ?? []).map((e) => e as int).toList();
        final r = m['round'] as int;
        if (r != _handRound) {
          handHidden = true;
          _handRound = r;
        }
      case 'resolution':
        _showResolution(
            UiResolution.fromJson(m['resolution'] as Map<String, dynamic>));
      case 'game_over':
        phase = 'finished';
        winnerId = m['winnerId'] as String?;
        isDraw = m['isDraw'] as bool;
        pot = (m['pot'] as num?)?.toInt() ?? pot;
        potFixed = pot;
        potWonByMe = winnerId == myId && pot > 0 && !isDraw;
        // La sala cumplió su ciclo: ya no hay "sala activa".
        ActiveRoomStore.clear();
      case 'notice':
        if (m['kind'] == 'turn_timeout' && m['playerId'] == myId) {
          final s = (m['strikes'] as num?)?.toInt();
          lastNotice = s == null
              ? 'Se acabó tu tiempo: un bot jugó ese turno por ti.'
              : 'Se acabó tu tiempo ($s de 3): un bot jugó por ti. '
                  'Al tercer tiempo vencido seguido quedas eliminado.';
        } else if (m['kind'] == 'afk_eliminated') {
          if (m['playerId'] == myId) {
            lastNotice = 'Quedaste eliminado: no jugaste 3 turnos seguidos.';
          } else {
            final pid = m['playerId'];
            final n = (pid is String ? playerById(pid)?.nickname : null) ??
                'Un jugador';
            lastNotice = '$n quedó eliminado por no jugar (3 turnos vencidos).';
          }
        } else if (m['kind'] == 'player_left') {
          // Desconexión en partida (24-oct): aviso a toda la mesa.
          final pid = m['playerId'];
          if (pid != myId) {
            final n = (pid is String ? playerById(pid)?.nickname : null) ??
                'Un jugador';
            final secs = (m['seconds'] as num?)?.toInt() ?? 60;
            lastNotice =
                '$n se desconectó: tiene $secs s para volver o queda eliminado.';
          }
        } else if (m['kind'] == 'player_returned') {
          final pid = m['playerId'];
          if (pid != myId) {
            final n = (pid is String ? playerById(pid)?.nickname : null) ??
                'Un jugador';
            lastNotice = '$n volvió a la mesa.';
          }
        } else if (m['kind'] == 'disconnect_eliminated') {
          if (m['playerId'] == myId) {
            lastNotice =
                'Quedaste eliminado: no volviste a tiempo tras desconectarte.';
          } else {
            final pid = m['playerId'];
            final n = (pid is String ? playerById(pid)?.nickname : null) ??
                'Un jugador';
            lastNotice = '$n quedó eliminado: no volvió tras desconectarse.';
          }
        }
      case 'error':
        errorMessage = m['message'] as String?;
      case 'mic':
        final pid = m['playerId'] as String?;
        if (pid != null) {
          _micById[pid] = m['on'] as bool? ?? false;
          players = [
            for (final p in players)
              p.id == pid ? p.copyWith(micOn: _micById[pid]) : p,
          ];
          _music?.syncVolume();
          notifyListeners();
        }
      case 'voice_signal':
        final from = m['from'] as String?;
        final data = m['data'];
        if (from != null && data is Map<String, dynamic>) {
          _voice?.handleSignal(from, data);
        }
      case 'music_state':
        final music = m['music'];
        if (music is Map<String, dynamic>) {
          _ensureMusic();
          _music?.applyState(music);
        }
      // Recepción de reacciones (relay del servidor, 26-oct):
      // tipo nuevo y opcional; los clientes que no lo conozcan lo
      // ignoran (el switch no tiene default) y ningún mensaje
      // existente cambia de forma.
      case 'emote':
        final pid = m['playerId'] as String?;
        final glyph = m['emote'] as String?;
        if (pid != null && glyph != null) showEmote(pid, glyph);
        break;
      case 'chat':
        final cpid = m['playerId'] as String?;
        final msg = m['message'] as String?;
        if (cpid != null && msg != null) showEmote(cpid, msg);
        break;
    }
    if (myId.isNotEmpty) {
      _ensureVoice();
      _syncVoicePeers();
    }
    notifyListeners();
  }

  /// Registra los eventos de la ronda en los globos e historial.
  void _absorbEvents() {
    for (final e in events) {
      lastActionBy[e.playerId] = e;
    }
    if (round > 0) {
      historyByRound[round] = List.of(events);
    }
  }

  /// Probabilidad estimada de que la apuesta [b] sea verdadera, contando
  /// SOLO mi mano y la probabilidad de los dados que no veo (la misma
  /// matemática de los bots). Para la "Ayuda para principiantes".
  double estimateFor(Bid b) {
    var own = 0;
    for (final d in myHand) {
      if (d == b.face) {
        own++;
      } else if (uiConfig.wildcardsEffective && b.face != 1 && d == 1) {
        own++;
      }
    }
    final unknown = totalDice - myHand.length;
    final p = (b.face == 1 || !uiConfig.wildcardsEffective) ? 1 / 6 : 2 / 6;
    return probabilityAtLeast(unknown, b.quantity - own, p);
  }

  void setReady(bool ready) => _send({'type': 'set_ready', 'ready': ready});

  void startOnline({required int fillBots, required String botDifficulty}) {
    _send({
      'type': 'start_game',
      'fillBots': fillBots,
      'botDifficulty': botDifficulty,
    });
  }

  // ---------- consultas compartidas ----------

  PlayerView? get me => players.where((p) => p.id == myId).firstOrNull;
  PlayerView? playerById(String id) =>
      players.where((p) => p.id == id).firstOrNull;
  bool get isMyTurn => phase == 'playing' && currentPlayerId == myId;
  String? get actorId => switch (phase) {
        'playing' => currentPlayerId,
        'kamikazeOffer' => kamikazeOfferId,
        'kamikazeChoice' => kamikazeActivatorId,
        _ => null,
      };
  bool get canPasoUi =>
      isMyTurn &&
      uiConfig.pasoEnabled &&
      (me?.diceCount ?? 0) == 5 &&
      events.isNotEmpty;
  bool get canCalzoUi => isMyTurn && currentBid != null && canCalzo;

  /// Apuesta legal mínima sugerida (para preseleccionar el selector).
  Bid suggestedBid() {
    if (currentBid == null) {
      var bestFace = 6;
      var best = -1;
      for (var f = 2; f <= 6; f++) {
        final c = myHand
            .where((d) => d == f || (uiConfig.wildcardsEffective && d == 1))
            .length;
        if (c > best) {
          best = c;
          bestFace = f;
        }
      }
      return Bid(1, bestFace);
    }
    final cur = currentBid!;
    final tries = <Bid>[
      Bid(cur.quantity + 1, cur.face),
      if (cur.face < 6) Bid(cur.quantity, cur.face + 1),
      Bid(((cur.quantity + 1) / 2).ceil(), 1),
      Bid(cur.quantity * 2 + 1, 6),
      Bid(cur.quantity + 1, 1),
    ];
    for (final t in tries) {
      if (GameEngine.raiseError(currentBid, t, totalDice,
              acesRuleEnabled: uiConfig.acesRuleEnabled) ==
          null) {
        return t;
      }
    }
    for (var q = 1; q <= totalDice; q++) {
      for (var f = 1; f <= 6; f++) {
        final t = Bid(q, f);
        if (GameEngine.raiseError(currentBid, t, totalDice,
                acesRuleEnabled: uiConfig.acesRuleEnabled) ==
            null) {
          return t;
        }
      }
    }
    return cur;
  }

  // ---------- acciones del jugador ----------

  void doBid(Bid b) {
    AudioService.instance.hapticLight();
    if (online) {
      _send({
        'type': 'action',
        'action': {
          'type': 'bid',
          'bid': {'quantity': b.quantity, 'face': b.face}
        },
      });
    } else {
      _local(() => _engine!.bid(myId, b), null);
    }
  }

  void doPaso() {
    AudioService.instance.hapticLight();
    AudioService.instance.paso();
    if (online) {
      _send({
        'type': 'action',
        'action': {'type': 'paso'}
      });
    } else {
      _local(() => _engine!.paso(myId), null);
    }
  }

  void doDudo() {
    if (online) {
      _send({
        'type': 'action',
        'action': {'type': 'dudo'}
      });
    } else {
      _local(() => null, () => _engine!.dudo(myId));
    }
  }

  void doCalzo() {
    if (online) {
      _send({
        'type': 'action',
        'action': {'type': 'calzo'}
      });
    } else {
      _local(() => null, () => _engine!.calzo(myId));
    }
  }

  void doDudoPaso() {
    if (online) {
      _send({
        'type': 'action',
        'action': {'type': 'dudoPaso'}
      });
    } else {
      _local(() => null, () => _engine!.dudoPaso(myId));
    }
  }

  void doCalzoPaso() {
    if (online) {
      _send({
        'type': 'action',
        'action': {'type': 'calzoPaso'}
      });
    } else {
      _local(() => null, () => _engine!.calzoPaso(myId));
    }
  }

  void respondKamikaze(bool accept) {
    if (accept) {
      AudioService.instance.drumroll();
      AudioService.instance.hapticHeavy();
    }
    if (online) {
      _send({'type': 'kamikaze_response', 'accept': accept});
    } else {
      _local(() => _engine!.respondKamikaze(myId, accept: accept), null);
    }
  }

  void chooseKamikazeFace(int face) {
    AudioService.instance.cupThud();
    AudioService.instance.hapticHeavy();
    if (online) {
      _send({'type': 'kamikaze_face', 'face': face});
    } else {
      _local(() => null, () => _engine!.chooseKamikazeFace(myId, face));
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearResolution() {
    uiResolution = null;
    notifyListeners();
  }

  // ---------- motor local ----------

  void _local(void Function() simple, Resolution? Function()? resolving) {
    _myStrikes = 0; // jugó: la cuenta de abandono vuelve a cero
    try {
      Resolution? res;
      if (resolving != null) {
        res = resolving();
      } else {
        simple();
      }
      if (res != null) _showResolution(UiResolution.fromEngine(res));
    } on IllegalMove catch (e) {
      errorMessage = e.message;
    }
    _syncLocal();
    notifyListeners();
    _scheduleLocal();
  }

  void _syncLocal() {
    final e = _engine;
    if (e == null) return;
    phase = e.phase.name;
    round = e.roundNumber;
    currentBid = e.currentBid;
    lastBidderId = e.lastBidderId;
    currentPlayerId = e.currentPlayerId;
    pendingPasoId = e.pendingPasoPlayerId;
    kamikazeOfferId = e.kamikazeOfferPlayerId;
    kamikazeActivatorId = e.kamikazeActivatorId;
    canCalzo = e.canCalzoNow;
    calzoThreshold = e.calzoThresholdDice;
    totalDice = e.totalDiceInPlay;
    winnerId = e.winnerId;
    isDraw = e.isDraw;
    if (e.phase == GamePhase.finished && !_coinsSettled) {
      _coinsSettled = true;
      if (stake > 0) {
        if (e.isDraw) {
          Wallet.instance.credit(stake); // empate: se devuelve la apuesta
        } else if (e.winnerId == myId) {
          Wallet.instance.credit(pot);
          potWonByMe = true;
        }
      }
    }
    players = [
      for (final p in e.players)
        PlayerView(
          id: p.id,
          nickname: p.name,
          isBot: _brains.containsKey(p.id),
          connected: true,
          diceCount: p.diceCount,
          eliminated: p.eliminated,
          ready: true,
        ),
    ];
    events = [for (final ev in e.roundHistory) UiEvent.fromEngine(ev)];
    _absorbEvents();
    if (e.phase != GamePhase.lobby) myHand = e.handOf(myId);
    if (round != _lastRound) {
      handHidden = true;
      _lastRound = round;
    }
  }

  void _scheduleLocal() {
    _botTimer?.cancel();
    _turnTimer?.cancel();
    turnEndsAt = null;
    final e = _engine;
    if (e == null || phase == 'finished' || phase == 'lobby') return;
    final actor = actorId;
    if (actor == null) return;
    if (_brains.containsKey(actor)) {
      // Los bots "piensan": base + azar hasta la mitad de la base
      // (1.8-2.7 s; guiada 2.4-3.6 s). Antes jugaban a los 900 ms
      // y la mesa volaba (orden del usuario, 22-oct).
      final think = botDelay +
          Duration(
              milliseconds: _botRng.nextInt(botDelay.inMilliseconds ~/ 2 + 1));
      _botTimer = Timer(think, () => _botAct(actor));
    } else if (actor == myId && useTurnTimer) {
      turnEndsAt =
          DateTime.now().add(Duration(seconds: e.config.turnTimerSeconds));
      _turnTimer = Timer(Duration(seconds: e.config.turnTimerSeconds), () {
        // Abandono (misma regla que en línea): al tercer tiempo
        // vencido seguido, eliminado en vez de bot.
        _myStrikes++;
        if (_myStrikes >= 3) {
          _myStrikes = 0;
          lastNotice = 'Quedaste eliminado: no jugaste 3 turnos seguidos.';
          try {
            final res = _engine!.forceEliminate(myId);
            _showResolution(UiResolution.fromEngine(res));
          } catch (_) {}
          _syncLocal();
          notifyListeners();
          _scheduleLocal();
          return;
        }
        lastNotice = 'Se acabó tu tiempo ($_myStrikes de 3): un bot jugó '
            'ese turno por ti. Al tercer tiempo vencido seguido quedas '
            'eliminado.';
        _botAct(myId, asTimeout: true);
      });
    }
    // Aviso DESPUÉS de programar: todos los llamadores notifican ANTES
    // de programar, así que sin este aviso la pantalla nunca ve el
    // turnEndsAt recién puesto y el ticker del aro no se crea (el aro y
    // la barra quedaban congelados en verde hasta vencer el turno).
    if (!_disposed) notifyListeners();
  }

  BotContext _botCtx(String id) {
    final e = _engine!;
    final p = e.playerById(id);
    return BotContext(
      selfId: id,
      ownHand: e.handOf(id),
      currentBid: e.currentBid,
      totalDiceInPlay: e.totalDiceInPlay,
      diceCounts: {for (final pl in e.players) pl.id: pl.diceCount},
      pendingPasoPlayerId: e.pendingPasoPlayerId,
      canCalzo: e.canCalzoNow,
      canPaso: e.config.pasoEnabled &&
          p.diceCount == e.config.dicePerPlayer &&
          p.diceCount == 5 &&
          e.roundHistory.isNotEmpty,
      config: e.config,
    );
  }

  void _botAct(String id, {bool asTimeout = false}) {
    final e = _engine;
    if (e == null) return;
    final brain = _brains[id] ?? BotBrain(BotDifficulty.media);
    Resolution? res;
    try {
      if (e.phase == GamePhase.playing && e.currentPlayerId == id) {
        final action = brain.decide(_botCtx(id));
        if (action.reason != null) botReasonBy[id] = action.reason!;
        if (action.type == BotActionType.paso) AudioService.instance.paso();
        switch (action.type) {
          case BotActionType.bid:
            e.bid(id, action.bid!);
          case BotActionType.paso:
            e.paso(id);
          case BotActionType.dudo:
            res = e.dudo(id);
          case BotActionType.calzo:
            res = e.calzo(id);
          case BotActionType.dudoPaso:
            res = e.dudoPaso(id);
          case BotActionType.calzoPaso:
            res = e.calzoPaso(id);
        }
      } else if (e.phase == GamePhase.kamikazeOffer &&
          e.kamikazeOfferPlayerId == id) {
        final accept =
            asTimeout ? false : brain.shouldAcceptKamikaze(_botCtx(id));
        if (accept) AudioService.instance.drumroll();
        e.respondKamikaze(id, accept: accept);
      } else if (e.phase == GamePhase.kamikazeChoice &&
          e.kamikazeActivatorId == id) {
        res = e.chooseKamikazeFace(id, brain.chooseKamikazeFace());
      }
    } catch (_) {
      try {
        if (e.phase == GamePhase.playing && e.currentPlayerId == id) {
          if (e.currentBid != null) {
            res = e.dudo(id);
          } else {
            e.bid(id, const Bid(1, 2));
          }
        }
      } catch (_) {}
    }
    if (res != null) _showResolution(UiResolution.fromEngine(res));
    _syncLocal();
    notifyListeners();
    _scheduleLocal();
  }

  void _showResolution(UiResolution r) {
    // Contexto para el veredicto: se captura ANTES de que el estado
    // avance a la ronda siguiente (quién desafió, quién apostó, qué).
    uiResolution = r.withContext(
      challengerId: actorId,
      bidderId: lastBidderId,
      bid: currentBid,
      pasoPlayerId: pendingPasoId,
    );
    if (round > 0) resolutionByRound[round] = uiResolution!;
    resolutionSeq++;
    switch (r.type) {
      case 'calzo':
      case 'calzoPaso':
        if (r.gainerId != null) {
          AudioService.instance.chime();
        } else {
          AudioService.instance.buzz();
        }
      case 'kamikaze':
        AudioService.instance.cupThud();
        AudioService.instance.hapticHeavy();
      default:
        AudioService.instance.buzz();
    }
  }

  /// Detiene los temporizadores de la partida local sin desechar el
  /// notifier (la revancha B4 reemplaza la pantalla y la pantalla
  /// vieja aún quita su listener en su dispose).
  void stopLocal() {
    _botTimer?.cancel();
    _turnTimer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    if (activeSession == this) activeSession = null;
    _voice?.dispose();
    _music?.dispose();
    AudioService.djTakeover = false;
    _botTimer?.cancel();
    _turnTimer?.cancel();
    _reconnectTimer?.cancel();
    _heartbeat?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
