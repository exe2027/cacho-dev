import '../state/yt_player.dart';
import 'dart:async';
import 'dart:math';

import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../state/app_viewport.dart';
import '../state/audio.dart';
import '../state/match_controller.dart';
import '../state/settings.dart';
import '../table_geometry.dart';
import '../table_themes.dart';
import '../texts.dart';
import '../theme.dart';
import '../widgets/dice_and_cup.dart';
import '../widgets/sketch_layout.dart';
import '../widgets/panels.dart';
import '../widgets/casino_anims.dart';
import '../widgets/coin_widgets.dart';
import '../widgets/music_sheet.dart';
import '../widgets/yt_host.dart';
import '../config/room_configs.dart';
import '../services/user_service.dart';
import '../widgets/game/star_level_badge.dart';
import '../widgets/game/table_2d_layout_widget.dart';
import '../widgets/game/premium_table_widget.dart';
import '../widgets/game/player_slot_widget.dart';
import '../widgets/game/game_hud_widget.dart';
import '../state/wallet.dart';
import 'how_to_play_screen.dart';

/// Mesa según la referencia visual del usuario (22-oct): bar oscuro
/// con mesa de madera (plato 3D), jugadores alrededor con aro de color,
/// nombre, estado ("En turno" / "En espera") y pipas de dados; mi vaso
/// gigante renderizado en Blender al centro, con su secuencia: se AGITA
/// en el aire, CAE a la mesa (sombra, rebote, golpe) y SE LEVANTA
/// inclinado dejando ver mis dados-cubo 3D. Abajo, la tarjeta de
/// estado o, en mi turno, la consola de apuesta.
class GameScreen extends StatefulWidget {
  final MatchController controller;
  final Color leather;
  // AN6: cortina de apertura al entrar desde el lobby.
  final bool curtainEntry;
  // AN16: vaso que se posa (false al reincorporarse a partida en curso).
  final bool cupEntry;
  final RoomConfig? roomConfig;
  const GameScreen({
    super.key,
    required this.controller,
    required this.leather,
    this.curtainEntry = false,
    this.cupEntry = true,
    this.roomConfig,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final AnimationController _liftCtrl;
  late final CurvedAnimation _liftCurve;
  late final AnimationController _squashCtrl;
  // AN6: cortina de apertura (solo desde el lobby).
  bool _showEntryCurtain = false;
  bool _localMicOn = false;
  // AN16: vaso que se posa, una sola vez por sesión.
  static bool _cupEntryPlayed = false;
  late final AnimationController _entryCtrl;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _ringTicker;
  final Stream<int> _elapsedTicks =
      Stream.periodic(const Duration(seconds: 1), (i) => i);
  // Pitidos de apuro: en qué turno se pitaron ya qué segundos (3, 2, 1),
  // para pitar cada uno una sola vez por turno.
  DateTime? _beepTurnEndsAt;
  final _beepedSeconds = <int>{};
  Timer? _thudTimer;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  int _seenRound = -1;
  int? _armedFace;
  String? _lastActorId;
  String? _heldNotice;
  // Paridad docs/19 V1/B5: el vaso arranca CERRADO y mis dados
  // quedan ocultos bajo él. `_open` solo lo cambia VER
  // (`_toggleEye`); ya NO hay auto-apertura al inicio de la ronda
  // ni al llegar mi turno, así que no hace falta recordar si el
  // jugador "lo bajó a propósito" durante su turno.
  bool _open = false; // VER está mostrando mis dados
  bool _wasMyTurn = false;
  // Emote visible: secuencia del controlador ya mostrada (para
  // programar su retirada sin tocar el controlador en cada frame).
  int _shownEmoteSeq = 0;
  Timer? _emoteTimer;
  bool _wasBlind = false; // ya entré a la ceguera del Kamikaze
  int _dockDismissedAtEvents = -1;
  Map<String, dynamic>? _matchLevelUpResult;

  // Mesa horizontal (sentencia mesa horizontal, prototipo local):
  // consola lateral plegable + apuesta armada compartida con la barra
  // O4. La etapa 1 aún no tiene consola: `_sideFolded` no se usa
  // hasta la etapa 2.
  bool _sideFolded = false;
  String? _lastActorForFold;
  Bid? _consoleArmed;
  int? _consoleArmedFace;
  // Panel "Tu apuesta" plegado por defecto (F4): NO persiste
  // expandido entre auto-aperturas de la consola.
  bool _tuApuestaExpanded = false;

  /// La consola se muestra por nivel: es mi turno y no la cerré en
  /// este momento de la partida. Derivarla (en vez de abrirla en un
  /// aviso puntual) hace imposible que mi turno parta sin consola.
  // OJO: sin filtro por Paso pendiente. Ese filtro impedía abrir
  // la consola cuando alguien decía Paso y el jugador quedaba
  // atrapado entre dudar/calzar el Paso, sin poder apostar sobre
  // la apuesta anterior — contra la regla (reporte 24-oct).
  bool get _dockOpen =>
      c.isMyTurn &&
      c.phase == 'playing' &&
      c.uiResolution == null &&
      c.events.length != _dockDismissedAtEvents;
  String _lastBidKey = '';
  String _prevPhase = '';
  String? _shownNotice;
  String? _shownError;

  // Partida guiada
  bool _sawResolution = false;
  bool _coachFinished = false;

  MatchController get c => widget.controller;
  Settings get _s => Settings.instance;
  late RoomConfig _roomConfig;

  @override
  void initState() {
    super.initState();
    _roomConfig = widget.roomConfig ?? getRoomConfigByStake(widget.controller.stake);
    WakelockPlus.enable();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _liftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _liftCurve = CurvedAnimation(parent: _liftCtrl, curve: Curves.easeOut);
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _showEntryCurtain = widget.curtainEntry && CasinoAnims.enabled;
    if (widget.cupEntry && !_cupEntryPlayed && CasinoAnims.enabled) {
      _cupEntryPlayed = true;
      _entryCtrl.forward();
    } else {
      _entryCtrl.value = 1;
    }
    _accelSub = accelerometerEventStream().listen((e) {
      final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (mag > 30 &&
          DateTime.now().difference(_lastShake).inMilliseconds > 1200) {
        _lastShake = DateTime.now();
        _onPhysicalShake();
      }
    });
    AudioService.instance.syncAmbience();
    c.addListener(_onChange);
    // R44: sondeo del puente JS (visualViewport + safe-area) solo
    // mientras la partida está montada; un cambio de barras de
    // Safari dispara notifyListeners → reconstrucción.
    appViewport.addListener(_onViewport);
    appViewport.startWatching();
    // Si la partida ya estaba corriendo al entrar, lanzar la
    // secuencia con el vaso CERRADO (paridad V1: nada de
    // auto-apertura, ni siquiera en mi turno).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _seenRound == -1 && c.phase == 'playing') {
        _seenRound = c.round;
        _playRollClosed();
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _accelSub?.cancel();
    _ringTicker?.cancel();
    _thudTimer?.cancel();
    _emoteTimer?.cancel();
    _shakeCtrl.dispose();
    _liftCtrl.dispose();
    _squashCtrl.dispose();
    _entryCtrl.dispose();
    AudioService.instance.stopMurmur();
    AudioService.instance.stopMusic();
    c.removeListener(_onChange);
    appViewport.removeListener(_onViewport);
    appViewport.stopWatching();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roomConfig != null) {
      _roomConfig = widget.roomConfig!;
    } else if (widget.controller.stake != oldWidget.controller.stake) {
      _roomConfig = getRoomConfigByStake(widget.controller.stake);
    }
  }

  // ---------- Secuencia 3D del vaso ----------

  void _setOpen(bool open, {bool fast = false}) {
    _open = open;
    if (_s.reducedEffects) {
      _liftCtrl.value = open ? 1 : 0;
      return;
    }
    _liftCtrl.animateTo(
      open ? 1 : 0,
      duration: Duration(milliseconds: fast ? 200 : 380),
      curve: Curves.easeOut,
    );
  }

  /// Agita el vaso en el aire y lo deja caer a la mesa (golpe +
  /// rebote), SIEMPRE con el vaso cerrado (paridad V1/B5): lanzar
  /// no es mirar. Mostrar los dados es solo trabajo de VER.
  Future<void> _playRollClosed() async {
    if (_s.reducedEffects) return;
    AudioService.instance.diceRoll();
    HapticFeedback.mediumImpact();
    _thudTimer?.cancel();
    _thudTimer = Timer(const Duration(milliseconds: 500), () {
      AudioService.instance.cupThud();
      if (mounted) _squashCtrl.forward(from: 0);
    });
    try {
      await _shakeCtrl.forward(from: 0);
    } on TickerCanceled {
      return;
    }
  }

  /// Agitar (toque en el vaso o sensor físico): reproduce la
  /// animación de lanzamiento con el vaso CERRADO, sin cambiar mi
  /// mano (ya está decidida por el motor) y sin revelar los dados.
  /// No es un re-lanzamiento: no se toca el motor ni `_open`.
  void _shakeOnly() {
    if (_s.reducedEffects) {
      // Sin animación visual, queda el feedback sonoro del lanzamiento.
      AudioService.instance.diceRoll();
      AudioService.instance.cupThud();
      return;
    }
    _playRollClosed();
  }

  /// Durante la oferta y la elección del Kamikaze NADIE puede ver
  /// sus dados (regla del usuario, 22-oct): el vaso no se abre.
  bool get _kamikazeBlind =>
      c.phase == 'kamikazeOffer' || c.phase == 'kamikazeChoice';

  /// Toque en el vaso: SOLO meneo (lanzamiento cerrado). Ya NO
  /// revela ni oculta: el único mecanismo de revelación es VER.
  /// Si VER está mostrando los dados, el toque no los tapa ni los
  /// vuelve a mostrar; solo menea el vaso cerrado en su sitio
  /// (la inclinación de VER se conserva: `_open` no se toca).
  void _tapCup() {
    if (_kamikazeBlind) return;
    if (_shakeCtrl.isAnimating) return;
    _toggleEye();
  }

  /// VER: ÚNICO mecanismo de revelación (toggle mostrar/ocultar).
  /// En fases Kamikaze a ciegas no hay VER: el vaso se cierra a la
  /// fuerza (ver `_onChange`) y este método no hace nada.
  void _toggleEye() {
    if (_kamikazeBlind) return;
    if (_shakeCtrl.isAnimating) return;
    if (_open || _liftCtrl.value > 0.5) {
      _setOpen(false, fast: true);
    } else {
      _setOpen(true, fast: true);
    }
  }

  /// Agitar el celular: LANZA, no mira (B5). Meneo + sonido de
  /// dados + golpe, vaso cerrado, mano intacta, dados sin mostrar.
  /// En Kamikaze a ciegas tampoco agita: nada debe sugerir una
  /// tirada nueva antes de elegir el número.
  void _onPhysicalShake() {
    if (_kamikazeBlind) return;
    if (_shakeCtrl.isAnimating) return;
    _shakeOnly();
  }

  // ---------- Cambios del controlador ----------

  /// R44: el puente JS avisa (visualViewport / safe-area); la
  /// reconstrucción re-mide la fila con LayoutBuilder.
  void _onViewport() {
    if (mounted) setState(() {});
  }

  void _onChange() {
    if (!mounted) return;
    // Al entrar a la oferta/elección del Kamikaze el vaso se CIERRA
    // a la fuerza: no basta con bloquear el toque, porque si el vaso
    // venía levantado de la ronda anterior, el dado del activador
    // quedaba a la vista justo cuando debe elegir a ciegas (fuga
    // reportada por el usuario el 22-oct en la noche).
    if (_kamikazeBlind && !_wasBlind) {
      _open = false;
      _liftCtrl.value = 0;
    }
    _wasBlind = _kamikazeBlind;
    if (c.round != _seenRound) {
      _seenRound = c.round;
      _open = false;
      _liftCtrl.value = 0;
      // Mesa horizontal: la armada lateral se borra al cambiar de
      // ronda, igual que el BidDock vertical se recrea por evento.
      _consoleArmed = null;
      _consoleArmedFace = null;
      _tuApuestaExpanded = false;
      if (c.phase == 'playing') _playRollClosed();
    }
    // Mesa horizontal (H9/C8): al cambiar el actor, la armada
    // lateral se borra; al empezar mi turno la consola se
    // despliega (nunca plegada al iniciar mi turno; el pliegue
    // manual durante mi turno se respeta hasta el cambio de actor).
    if (c.actorId != _lastActorForFold) {
      _lastActorForFold = c.actorId;
      _consoleArmed = null;
      _consoleArmedFace = null;
      if (c.actorId == c.myId) {
        _sideFolded = false;
        _tuApuestaExpanded = false;
      }
    }
    // Fuera de partida no hay armada lateral.
    if (c.phase != 'playing' && _consoleArmed != null) {
      _consoleArmed = null;
      _consoleArmedFace = null;
      _tuApuestaExpanded = false;
    }
    // Apuesta nueva (de quien sea): suenan las fichas.
    final bidNow = c.currentBid;
    final bidKey = bidNow == null
        ? ''
        : '${c.round}|${c.lastBidderId}|${bidNow.quantity}x${bidNow.face}';
    if (bidKey.isNotEmpty && bidKey != _lastBidKey) {
      AudioService.instance.chips();
    }
    _lastBidKey = bidKey;
    // Fin de partida: fanfarria si gané yo.
    if (c.phase == 'finished' && _prevPhase != 'finished') {
      if (c.guided) {
        _s.markGuidedDone();
      }
      final bool iWon = !c.isDraw && c.winnerId == c.myId;
      if (iWon) {
        AudioService.instance.winFanfare();
        if (c.pot > 0 && !c.isDraw) AudioService.instance.coins();
      }
      _matchLevelUpResult = UserService.instance.addMatchResult(won: iWon, stake: c.stake);
    }
    _prevPhase = c.phase;
    // Mi turno llega a mitad de ronda: suena la campana, pero el
    // vaso NO se levanta solo (paridad V1: solo VER lo muestra).
    if (c.isMyTurn && !_wasMyTurn) {
      if (c.phase == 'playing') {
        AudioService.instance.turnAlert();
        AudioService.instance.hapticLight();
      }
    }
    _wasMyTurn = c.isMyTurn;
    // Cambio de turno a otro jugador: tick suave (mi turno ya tiene
    // su campana; el primer actor de la partida no suena).
    if (c.actorId != _lastActorId) {
      final first = _lastActorId == null;
      _lastActorId = c.actorId;
      if (!first &&
          !c.isMyTurn &&
          c.phase == 'playing' &&
          c.uiResolution == null) {
        AudioService.instance.tick();
      }
    }

    if (c.guided) {
      if (c.uiResolution != null) _sawResolution = true;
      if (_sawResolution && c.uiResolution == null && !_coachFinished) {
        _coachFinished = true;
        _s.markGuidedDone();
      }
    }
    // Aro-temporizador: refrescar mientras haya un deadline corriendo.
    if (c.turnEndsAt != null && c.phase == 'playing') {
      _ringTicker ??= Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        if (c.turnEndsAt == null || c.turnEndsAt!.isBefore(DateTime.now())) {
          _ringTicker?.cancel();
          _ringTicker = null;
        }
        // Pitidos de apuro (orden del usuario, 24-oct): solo en MI turno,
        // en los últimos 3 segundos (ya en rojo), un pitido por segundo.
        // Cada valor se pita una sola vez por turno; al cambiar de turno
        // (o al no ser el mío) la marca se limpia.
        if (c.isMyTurn && c.turnEndsAt != null) {
          if (c.turnEndsAt != _beepTurnEndsAt) {
            _beepTurnEndsAt = c.turnEndsAt;
            _beepedSeconds.clear();
          }
          final leftMs =
              c.turnEndsAt!.difference(DateTime.now()).inMilliseconds;
          final secs = (leftMs / 1000).ceil();
          if (isBeepSecond(secs) && _beepedSeconds.add(secs)) {
            AudioService.instance.beep();
          }
        } else {
          _beepedSeconds.clear();
        }
        setState(() {});
      });
    } else {
      _ringTicker?.cancel();
      _ringTicker = null;
    }
    final notice = c.lastNotice;
    if (notice != null && notice != _shownNotice) {
      // Con una revelación abierta el aviso espera su turno:
      // jamás se muestra encima de un conteo.
      if (c.uiResolution != null) {
        _heldNotice = notice;
        c.lastNotice = null;
      } else {
        _showCenterNotice(notice);
        c.lastNotice = null;
      }
    }
    if (c.uiResolution == null && _heldNotice != null) {
      final held = _heldNotice!;
      _heldNotice = null;
      _showCenterNotice(held);
    }
    // Reacción nueva: se retira sola a los ~2,2 s. Si llega otra
    // antes, el temporizador anterior se cancela y manda la nueva
    // (clearEmote solo borra su propia secuencia).
    if (c.emoteSeq != _shownEmoteSeq) {
      _shownEmoteSeq = c.emoteSeq;
      _emoteTimer?.cancel();
      if (c.emoteGlyph != null) {
        final seq = c.emoteSeq;
        _emoteTimer = Timer(const Duration(milliseconds: 2200), () {
          if (mounted) c.clearEmote(seq);
        });
      }
    }
    final err = c.errorMessage;
    if (err != null && err != _shownError) {
      _shownError = err;
      _showCenterNotice(err, isError: true);
      c.clearError();
      _shownError = null;
    }
    setState(() {});
  }

  String? _centerNotice;
  bool _centerNoticeIsError = false;
  Timer? _centerNoticeTimer;

  void _showCenterNotice(String text, {bool isError = false}) {
    if (!mounted) return;
    _centerNoticeTimer?.cancel();
    setState(() {
      _centerNotice = text;
      _centerNoticeIsError = isError;
    });
    _centerNoticeTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _centerNotice = null);
    });
  }

  Widget _buildCenterNoticeWidget() {
    if (_centerNotice == null) return const SizedBox.shrink();
    final isErr = _centerNoticeIsError;
    return Positioned.fill(
      child: IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 250),
          builder: (_, val, child) => Opacity(
            opacity: val,
            child: Transform.scale(
              scale: 0.85 + 0.15 * val,
              child: child,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xF20F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isErr ? const Color(0xFFEF4444) : CachoColors.gold,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isErr ? const Color(0x66EF4444) : const Color(0x66D4AF37)),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black87,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isErr ? Icons.error_outline : Icons.notifications_active_outlined,
                  color: isErr ? const Color(0xFFEF4444) : CachoColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _centerNotice!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _exit() {
    c.pauseMusic();
    YtPlayer.stopAll();
    AudioService.djTakeover = false;
    AudioService.instance.stopMusic();
    if (!c.isGameOver) {
      c.pauseTimers();
      MatchController.activeSession = c;
    } else {
      c.dispose();
      MatchController.activeSession = null;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  double? _ringFractionFor(String playerId) {
    if (c.turnEndsAt == null || c.actorId != playerId) return null;
    final total = c.uiConfig.turnTimerSeconds;
    if (total <= 0) return null;
    final left = c.turnEndsAt!.difference(DateTime.now()).inMilliseconds;
    return (left / (total * 1000)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final others = c.players.where((p) => p.id != c.myId).toList();
    // Solo la mesa va en horizontal (H16); los menús quedan en
    // vertical. Si el viewport no es apaisado, el camino vertical de
    // siempre queda intacto (fallback H17, congelado).
    final _size = MediaQuery.sizeOf(context);
    if (_size.width > _size.height) {
      return _buildLandscape(context, others);
    }
    return Scaffold(
      body: DecoratedBox(
        decoration: tableThemeDecoration(c.tableTheme),
        child: SafeArea(
          child: Stack(
            children: [
              // Marco neón (Fase A v2.0): el neón vive SOLO dentro
              // del rectángulo-mesa, nunca en el resto de la UI.
              if (c.tableTheme == tableThemeNeon)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        // Fondo oscuro propio (sin él, el brillo del
                        // marco teñía toda la mesa de cian).
                        color: Color(0xFF05070C),
                        border: Border.fromBorderSide(
                          BorderSide(color: neonFrameColor, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                children: [
                  // Barra superior: salir, logo y utilidades.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color:
                              const Color(0xFF1B2434).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _exit,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chevron_left,
                                      size: 19, color: Colors.white),
                                  Text('Salir',
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const DudoLogo(fontSize: 26),
                              Text(
                                '${c.roomCode != null ? 'SALA ${c.roomCode}' : (c.guided ? 'GUIADA' : 'LOCAL')} · R${c.round} · ${c.totalDice} dados',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFD8D2C4),
                                  shadows: [
                                    Shadow(
                                        color: Colors.black87, blurRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // B13 (sentencia v2.0): un solo engranaje en
                        // partida; la hoja agrupa SOLO historial,
                        // glosario y sonido. El micrófono queda
                        // fuera: sigue solo sobre la foto (regla 21).
                        _roundChip(
                            Icons.settings, 'Ajustes', _showGameSettingsSheet),
                      ],
                    ),
                  ),
                  KamikazeBar(controller: c),
                  // Pastilla de turno: de quién es el turno, SIEMPRE
                  // visible durante la partida (reporte 23-oct:
                  // "cuesta saber cuándo es el turno de quién").
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: (c.phase == 'playing' &&
                            c.uiResolution == null &&
                            c.actorId != null)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // B8 (sentencia v2.0): píldora de pozo
                                // en la MISMA fila del turno, sin fila
                                // nueva y sin solapar nada. El pozo
                                // es el fijado al partir (displayPot).
                                if (c.stake > 0 && c.displayPot > 0) ...[
                                  _potChip(),
                                  const SizedBox(width: 8),
                                ],
                                _turnPill(),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // La sala: jugadores alrededor de la mesa y mi vaso
                  // gigante al centro (referencia del usuario, 22-oct).
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, cons) {
                        final compact = cons.maxHeight < 470;
                        return Stack(
                          children: [
                            for (var i = 0; i < others.length; i++)
                              AnimatedAlign(
                                alignment: _slotFor(others.length, i),
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeInOut,
                                child: _seatFor(others[i],
                                    compact: compact,
                                    deep: (others.length >= 6 && i >= 4) ||
                                        (others.length == 4 && i >= 2) ||
                                        (others.length >= 5 && i >= 3) ||
                                        // La de arriba al centro: su
                                        // burbuja queda bajo el vaso.
                                        ((others.length == 3 ||
                                                others.length >= 5) &&
                                            i == 1)),
                              ),
                            AnimatedAlign(
                              // Con la consola abierta la mesa se
                              // achica y el vaso tapaba el nombre del
                              // rival central: con el dock abierto el
                              // escenario baja un poco (animado).
                              alignment: Alignment(
                                  0,
                                  compact
                                      ? (_dockOpen ? 0.66 : 0.38)
                                      : (_dockOpen ? 0.44 : 0.34)),
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeInOut,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: compact ? 0.72 : 1.0,
                                child: _myStage(compact: compact),
                              ),
                            ),
                            // Mi avatar AL CENTRO, bajo mi vaso
                            // (orden del usuario, 24-oct; antes iba
                            // en la esquina inferior izquierda).
                            Align(
                              alignment: const Alignment(0, 1),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _mySeat(compact: compact),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Mi temporizador como barra fina sobre las acciones
                  if (c.isMyTurn && c.turnEndsAt != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _ringFractionFor(c.myId) ?? 0,
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          color: ringTimeColor(_ringFractionFor(c.myId) ?? 1),
                        ),
                      ),
                    ),
                  if (c.online) MusicBar(controller: c),
                  if (!_dockOpen &&
                      c.phase == 'playing' &&
                      c.uiResolution == null)
                    _statusCard(),
                  // Paso pendiente contra mí CON la consola abierta:
                  // la banda de desafío va sobre la consola, para
                  // poder dudar/calzar el Paso sin cerrar nada (y
                  // apostar sigue a la mano en la consola misma).
                  if (_dockOpen &&
                      c.pendingPasoId != null &&
                      c.pendingPasoId != c.myId)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: PasoChallengeBar(controller: c),
                    ),
                  if (_dockOpen)
                    BidDock(
                      key: ValueKey('dock-${c.round}-${c.events.length}'),
                      controller: c,
                      peeked: _open,
                      onPeek: _toggleEye,
                      onArmedFaceChanged: (f) => setState(() => _armedFace = f),
                      onClose: () => setState(
                          () => _dockDismissedAtEvents = c.events.length),
                    ),
                  // Barra de acciones: con la consola abierta se
                  // oculta (la consola ya trae DUDO/CALZO/PASO y su
                  // APOSTAR; mostrarla sería duplicar, como señaló
                  // el usuario el 22-oct).
                  if (!_dockOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                      child: ActionBar(
                        controller: c,
                        onBidTap: () =>
                            setState(() => _dockDismissedAtEvents = -1),
                      ),
                    ),
                ],
              ),
              // Reproductor de YouTube nativo (APK): su WebView
              // vive invisible en una esquina de la mesa. En web
              // no se monta (allá manda el puente JS).
              if (c.online && !kIsWeb)
                const Positioned(
                  left: 0,
                  bottom: 0,
                  child: NativeYtHost(),
                ),
              if (c.uiResolution != null)
                ResolutionOverlay(
                  key: ValueKey(c.resolutionSeq),
                  controller: c,
                ),
              if (c.phase == 'finished' && c.uiResolution == null)
                _winnerOverlay(),
              // AN6: cortina de apertura al entrar desde el lobby.
              if (_showEntryCurtain)
                Positioned.fill(
                  child: EntryCurtain(
                    opening: true,
                    onDone: () {
                      if (mounted) setState(() => _showEntryCurtain = false);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// La pastilla de turno: dorada y gritona cuando me toca a mí;
  /// sobria con el nombre cuando le toca a otro.
  /// Píldora de pozo (B8): fichas + pozo fijado al partir.
  // ============ MESA HORIZONTAL (prototipo local) ============
  // Geometría medida (ver PROGRESS.md): mesa 544×334 con consola
  // abierta (844×390 total − 56 de barra − 300 de consola) o 844×334
  // plegada. Asientos compactos de ~93 px, escenario de 140 px:
  // 93 + 140 + 93 = 326 ≤ 334, con ~4 px de aire arriba y abajo.

  /// La consola lateral está abierta (H7): es mi turno en partida,
  /// sin resolución, y no está plegada. C8: al iniciar mi turno se
  /// despliega siempre (nunca plegada por defecto); el pliegue
  /// manual durante mi turno se respeta hasta el cambio de actor
  /// (ver _onChange).
  bool get _landscapeConsoleOpen =>
      c.isMyTurn &&
      c.phase == 'playing' &&
      c.uiResolution == null &&
      !_sideFolded;

  /// La barra mínima plegada (H9/O4): solo en mi turno en partida,
  /// sin resolución, con la consola plegada a mano.
  bool get _landscapeFoldedBarVisible =>
      c.isMyTurn &&
      c.phase == 'playing' &&
      c.uiResolution == null &&
      _sideFolded;

  /// Presupuesto vertical bosquejo (sentencia F1/F7): barra 56 +
  /// óvalo 262 + consola 72 = 390 exactos. Compacto (340 ≤ H <
  /// 390): consola 64, óvalo 212. H < 340: fuera de presupuesto
  /// (la mesa se sigue mostrando comprimida, pero esa viewport NO
  /// se entrega como buena; la vía primaria es el aviso de giro).
  /// Los umbrales viejos 327/281 medían la consola lateral
  /// muerta y NO se trasladan.
  static const double _sketchBarH = 56;

  Widget _buildLandscape(BuildContext context, List<PlayerView> others) {
    final kamikaze = c.phase == 'kamikazeOffer' || c.phase == 'kamikazeChoice';
    final pasoPendingForMe =
        c.pendingPasoId != null && c.pendingPasoId != c.myId && c.isMyTurn;

    final roomConfig = widget.roomConfig ?? _roomConfig;
    final slotsData = _buildTableSlotsData(others, roomConfig);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0906),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // =========================================================
          // CAPA 1 y 2: PremiumTableWidget (Mesa 2.5D Casino + Slots Encajados)
          // =========================================================
          Positioned.fill(
            child: PremiumTableWidget(
              roomConfig: roomConfig,
              slots: slotsData,
              pot: c.displayPot,
              currentBid: c.currentBid,
              lastBidderName: c.currentBid != null && c.lastBidderId != null
                  ? nameOf(c, c.lastBidderId)
                  : null,
            ),
          ),

          // =========================================================
          // CAPA 2.5: Notificaciones y Anuncios Rápidos al Medio de la Mesa
          // =========================================================
          _buildCenterNoticeWidget(),

          // =========================================================
          // CAPA 3: GameHUDWidget (SafeArea Overlay: Top Bar & Bottom Dock)
          // =========================================================
          Positioned.fill(
            child: SafeArea(
              child: GameHUDWidget(
                roomConfig: roomConfig,
                pot: c.displayPot,
                goldCoins: (c.online ? c.serverBalance : Wallet.instance.balance) ?? 0,
                cash: 0,
                isAudioMuted: !AudioService.instance.enabled,
                onToggleAudio: () {
                  setState(() => AudioService.instance.enabled = !AudioService.instance.enabled);
                  AudioService.instance.syncAmbience();
                },
                onOpenMusic: () => showMusicSheet(context, c),
                onExit: _exit,
                roomSubtitle:
                    '${c.roomCode != null ? 'SALA ${c.roomCode}' : (c.guided ? 'GUIADA' : 'LOCAL')} · R${c.round} · ${c.totalDice} dados',
                isMyTurn: c.isMyTurn,
                activeTurnName: c.actorId != null ? nameOf(c, c.actorId) : null,
                currentBid: c.currentBid,
                bidderName: c.currentBid != null && c.lastBidderId != null
                    ? nameOf(c, c.lastBidderId)
                    : null,
                armedBid: _consoleArmed,
                isBidLegal: _isBidLegal(_consoleArmed),
                bidError: _getBidError(_consoleArmed),
                onSelectFace: _handleSelectFace,
                onAdjustQuantity: _handleAdjustQuantity,
                onPlaceBid: _handlePlaceBid,
                canCalzo: c.canCalzoUi,
                onCalzo: c.canCalzoUi ? _handleCalzo : null,
                canDudo: c.isMyTurn && c.currentBid != null,
                onDudo: (c.isMyTurn && c.currentBid != null) ? _handleDudo : null,
                canPaso: c.canPasoUi,
                onPaso: c.canPasoUi ? _handlePaso : null,
                isCupOpen: _open,
                onToggleCup: () => setState(_toggleEye),
                bannerNotification: kamikaze
                    ? KamikazeBar(controller: c)
                    : (pasoPendingForMe ? PasoChallengeBar(controller: c) : null),
              ),
            ),
          ),

          // Botón flotante de Chat / Emotes
          if (c.phase == 'playing' && c.uiResolution == null && !kamikaze)
            Positioned(
              left: 14,
              bottom: 74,
              child: _buildChatFloatingButton(context, roomConfig),
            ),

          // Overlays de resolución y fin de partida
          if (c.uiResolution != null)
            Positioned.fill(
              child: SafeArea(
                child: ResolutionOverlay(
                  key: ValueKey(c.resolutionSeq),
                  controller: c,
                  compact: true,
                ),
              ),
            ),
          if (c.phase == 'finished' && c.uiResolution == null)
            _winnerOverlay(),

          // AN6: cortina de apertura al entrar desde el lobby
          if (_showEntryCurtain)
            Positioned.fill(
              child: EntryCurtain(
                opening: true,
                onDone: () {
                  if (mounted) {
                    setState(() => _showEntryCurtain = false);
                  }
                },
              ),
            ),

          // P1: Música nativa en segundo plano
          if (c.online && !kIsWeb)
            const Positioned(
              left: 0,
              bottom: 0,
              child: NativeYtHost(),
            ),
        ],
      ),
    );
  }

  Widget _buildChatFloatingButton(
      BuildContext context, RoomConfig roomConfig) {
    return Material(
      color: const Color(0xFF162544).withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showQuickChatSheet(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: roomConfig.accentColor.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 18,
              color: CachoColors.ivory,
            ),
          ),
        ),
      ),
    );
  }

  bool _isBidLegal(Bid? b) {
    if (b == null) return false;
    return GameEngine.raiseError(c.currentBid, b, c.totalDice,
            acesRuleEnabled: c.uiConfig.acesRuleEnabled) ==
        null;
  }

  String? _getBidError(Bid? b) {
    if (b == null) return null;
    return GameEngine.raiseError(c.currentBid, b, c.totalDice,
        acesRuleEnabled: c.uiConfig.acesRuleEnabled);
  }

  void _handleSelectFace(int face) {
    setState(() {
      final cur = _consoleArmed;
      if (cur != null && cur.face == face) {
        if (cur.quantity >= c.totalDice) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.lightImpact();
          _consoleArmed = Bid(cur.quantity + 1, face);
        }
      } else {
        HapticFeedback.lightImpact();
        final minQty = _calculateMinQuantityForFace(face);
        _consoleArmed = Bid(minQty, face);
      }
    });
  }

  int _calculateMinQuantityForFace(int face) {
    final cur = c.currentBid;
    if (cur == null) return 1;
    for (int q = 1; q <= c.totalDice; q++) {
      final candidate = Bid(q, face);
      if (GameEngine.raiseError(cur, candidate, c.totalDice,
              acesRuleEnabled: c.uiConfig.acesRuleEnabled) ==
          null) {
        return q;
      }
    }
    return cur.quantity;
  }

  void _handleAdjustQuantity(int newQty) {
    if (_consoleArmed == null) return;
    if (newQty < 1 || newQty > c.totalDice) return;
    setState(() {
      _consoleArmed = Bid(newQty, _consoleArmed!.face);
    });
  }

  void _handlePlaceBid() {
    if (_consoleArmed == null || !_isBidLegal(_consoleArmed)) return;
    c.doBid(_consoleArmed!);
    setState(() {
      _consoleArmed = null;
    });
  }

  void _handleCalzo() {
    if (c.pendingPasoId != null) {
      c.doCalzoPaso();
    } else {
      c.doCalzo();
    }
  }

  void _handleDudo() {
    if (c.pendingPasoId != null) {
      c.doDudoPaso();
    } else {
      c.doDudo();
    }
  }

  void _handlePaso() {
    c.doPaso();
  }

  List<PlayerSlotData> _buildTableSlotsData(
      List<PlayerView> others, RoomConfig roomConfig) {
    final List<PlayerSlotData> list = [];

    // Slot 0: Usuario local (Abajo Centro - 0.50, 0.82)
    final myLast = c.lastActionBy[c.myId];
    list.add(
      PlayerSlotData(
        targetSlotIndex: 0,
        id: c.myId,
        name: c.myNickname.isNotEmpty ? c.myNickname : 'Tú',
        diceCount: c.myHand.length,
        coins: (c.online ? c.serverBalance : Wallet.instance.balance) ?? 0,
        isLocalUser: true,
        isTurn: c.isMyTurn,
        isEliminated: c.myHand.isEmpty,
        turnProgress: _ringFractionFor(c.myId),
        dice: c.myHand,
        isCupOpen: _open,
        isRevealed: false,
        lastAction: myLast != null ? eventLabel(myLast) : null,
        roomConfig: roomConfig,
        onTapCup: () => setState(_toggleEye),
        activeEmote: c.emotePlayerId == c.myId ? c.emoteGlyph : null,
      ),
    );

    // Asignación simétrica para los asientos de rivales (1..5)
    final count = others.length;
    final List<int> targetSlots;
    if (count == 1) {
      targetSlots = [3]; // Arriba Centro
    } else if (count == 2) {
      targetSlots = [2, 4]; // Arriba Izq, Arriba Der
    } else if (count == 3) {
      targetSlots = [1, 3, 5]; // Abajo Izq, Arriba Centro, Abajo Der
    } else if (count == 4) {
      targetSlots = [1, 2, 4, 5];
    } else {
      targetSlots = [1, 2, 3, 4, 5];
    }

    for (int i = 0; i < others.length && i < targetSlots.length; i++) {
      final p = others[i];
      final isTurn = c.actorId == p.id;
      final isElim = p.diceCount <= 0;
      final isRevealed = c.phase == 'resolution' || c.uiResolution != null;
      final revealedHand = const <int>[];
      final lastAction = c.lastActionBy[p.id];

      list.add(
        PlayerSlotData(
          targetSlotIndex: targetSlots[i],
          id: p.id,
          name: p.nickname,
          diceCount: p.diceCount,
          coins: 0,
          isLocalUser: false,
          isTurn: isTurn,
          isEliminated: isElim,
          turnProgress: isTurn ? _ringFractionFor(p.id) : null,
          dice: revealedHand,
          isCupOpen: false,
          isRevealed: isRevealed,
          lastAction: lastAction != null ? eventLabel(lastAction) : null,
          roomConfig: roomConfig,
          onTapCup: null,
          activeEmote: c.emotePlayerId == p.id ? c.emoteGlyph : null,
        ),
      );
    }

    return list;
  }


  /// Barra superior bosquejo de 56 px (sentencia F5): SOLO lo
  /// existente (Salir, saldo, píldora de turno + apuesta vigente,
  /// música plegada, ajustes). El Pozo va en la barra ADEMÁS de
  /// en la mesa (pozo real displayPot en ambos sitios): que esté
  /// duplicado es pregunta para el usuario, NO decisión de este
  /// código (pozo centro-solo vs centro+barra, lista final del
  /// día). Sin segunda moneda, sin "+" de compra, sin
  /// regalo/objetivo/corona/LVL/gemas/bundles/SALE/PREMIO, sin
  /// chat, sin amigos, sin misiones: esos huecos del mockup NO
  /// se dibujan y quedan como preguntas para el usuario.
  /// Barra superior, composición del mockup (SOLO composición, sin
  /// marca, nombres ni caras de ningún otro juego): izquierda Salir
  /// + saldo real; centro Pozo real (displayPot = potFixed fijado
  /// al partir, nunca recalculado) + píldora de turno / apuesta
  /// vigente; derecha iconos reales (música/DJ solo en línea,
  /// historial, ajustes). El historial también sigue dentro de la
  /// hoja de ajustes y el micrófono sigue solo sobre la foto
  /// (regla 21: NO se duplica en la barra). SIN segunda moneda,
  /// sin "+" de compra, sin regalo/misiones/amigos/niveles/chat:
  /// esos huecos del mockup NO se dibujan y quedan como preguntas
  /// para el usuario (ver reporte de la tarea). Texto mínimo 14 px.
  /// Dos modos por ancho (LayoutBuilder): ancho (>= 640) una fila
  /// de 52 px; angosto (< 640) dos filas (fila 1: Salir + saldo +
  /// iconos, 28 px; fila 2: Pozo + turno/apuesta, 24 px, píldoras
  /// con padding vertical 2) + barra de progreso 4 px: alto
  /// total 56 px en AMBOS modos (el angosto recuperó sus 4 px
  /// extra sin bajar de 14 px de texto ni tocar los iconos de
  /// 44/28 px: la fila 2 solo lleva píldoras informativas, no
  /// botones). Medido a 390 px con Montserrat (fuente del tema):
  /// fila 1 online con saldo 100.000 = 265 px fijos de 374
  /// disponibles (sobran 109); fila 2 típica real (pozo 2.000,
  /// turno La Morocha, apuesta 5 Cuadras de La Juanita) =
  /// 485 px intrínsecos, déficit 111: la apuesta lleva flex 2
  /// y el turno flex 1 para que cantidad + pinta + apostador
  /// (el dato que el master exige siempre visible) se recorte
  /// lo menos posible: visible típico sin ser mi turno, turno
  /// "Turno de…" (actor solo por el aro + Tooltip) y apuesta
  /// "5 Cuadras · La Ju…" (prefijo único del apostador entre
  /// los bots); con flex 1/1 la apuesta perdía al apostador
  /// entero ("5 Cuadras · …"). En mi turno la píldora dorada
  /// va intrínseca para no recortarse nunca y la apuesta
  /// muestra "5 Cuadras · La…". La apuesta angosta
  /// escribe "5 Cuadras · La Juanita" (sin "de ", −22 px) y
  /// tanto turno como apuesta llevan Tooltip con el texto
  /// completo (el turno, además, se recupera por el aro del
  /// asiento). Peor caso (apodo en línea de 20 caracteres,
  /// pozo 20.000): NO cabe entero, se recorta con elipsis
  /// (ver reporte: cantidad + pinta intactas, nombre parcial +
  /// Tooltip). La barra vive en una Column SOBRE la mesa,
  /// nunca encima de ella: por construcción no solapa la placa
  /// del asiento superior ni el pozo de la mesa.
  Widget _sketchTopBar() {
    final cur = c.currentBid;
    final myBalance = c.online ? c.serverBalance : Wallet.instance.balance;
    final myTurn = c.isMyTurn;
    final frac = _ringFractionFor(c.myId);
    final musicCur = c.musicCurrent;
    final needsTap = musicCur != null && (c.musicService?.needsTap ?? false);
    final showPot = c.stake > 0 && c.displayPot > 0;
    final playing =
        c.phase == 'playing' && c.uiResolution == null && c.actorId != null;

    Widget exitPill() {
      return SizedBox(
        height: 28,
        child: Material(
          color: const Color(0xFF1B2434).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _exit,
            child: const Padding(
              // RONDA 3 (F3c): 10 → 8, aire para la apuesta.
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 18, color: Colors.white),
                  Text('Salir',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // RONDA 2 (F9): saldo PRIMERO (tras Salir) y GRANDE: 16 px
    // w800 con moneda 18 (era 14/16). Es el primer dato de la
    // barra y el más grande de sus textos informativos.
    Widget balancePill() {
      if (myBalance == null) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2434).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: CachoColors.gold.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 18),
                const SizedBox(width: 5),
                Text(
                  coinsText(myBalance),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CachoColors.ivory),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: CachoColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.add, size: 12, color: CachoColors.menuMid),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2434).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: const Color(0xFF34C759).withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments, size: 16, color: Color(0xFF34C759)),
                const SizedBox(width: 4),
                const Text(
                  '\$0',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF34C759)),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 12, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    /// tight: solo la fila angosta (padding vertical 2 para que
    /// la píldora, 21 px, quepa en la fila 2 de 24 px; en ancho
    /// sigue el padding 4 de siempre). Sombra suave igual que
    /// la _turnPill: profundidad del mockup sin cambiar tamaño.
    Widget potPill({bool tight = false}) {
      return Container(
        // RONDA 3 (F3c): 10 → 8, aire para la apuesta.
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: tight ? 2 : 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2434).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CachoColors.gold.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'POZO',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CachoColors.gold),
            ),
            const SizedBox(width: 6),
            Text(
              coinsText(c.displayPot),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CachoColors.ivory),
            ),
          ],
        ),
      );
    }

    Widget roomInfo() {
      return Text(
        '${c.roomCode != null ? 'SALA ${c.roomCode}' : (c.guided ? 'GUIADA' : 'LOCAL')} · R${c.round} · ${c.totalDice} dados',
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFD8D2C4),
        ),
      );
    }

    Widget roundInfo() {
      if (!c.gameStarted || c.gameStartTime == null) {
        return const SizedBox.shrink();
      }
      final roomName =
          c.guided ? tableThemeName(c.tableTheme) : stakeTierName(c.stake);
      return StreamBuilder<int>(
        stream: _elapsedTicks,
        builder: (context, _) {
          final elapsed = DateTime.now().difference(c.gameStartTime!);
          final seconds = max(0, elapsed.inSeconds);
          final clock =
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
          final label = 'R${max(1, c.round)} · $roomName · $clock';
          return Tooltip(
            message: label,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CachoColors.ivory,
              ),
            ),
          );
        },
      );
    }

    /// Píldora de turno compacta para la fila angosta (la _turnPill
    /// de 18 px de padding lateral no cabe junto a pozo + apuesta
    /// a 390 px; mismo dato, mismo texto, padding lateral 10).
    Widget turnPillCompact() {
      final mine = c.isMyTurn;
      final name = shortNameOf(c, c.actorId);
      // Tooltip con el texto completo: a 390 px la píldora se
      // recorta con elipsis y el actor se recupera aquí y por
      // el aro del asiento (decisión 32).
      return Tooltip(
        message: mine ? '¡TU TURNO!' : 'Turno de $name',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: mine
                ? CachoColors.gold
                : const Color(0xFF1B2434).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: mine
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            mine ? '¡TU TURNO!' : 'Turno de $name',
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: mine ? const Color(0xFF221A08) : CachoColors.ivory,
            ),
          ),
        ),
      );
    }

    /// Apuesta vigente compacta (la _currentBidChip de 34 px no
    /// cabe en la fila angosta de 28 px; mismo dato, mismo texto).
    Widget bidChipCompact() {
      final name =
          c.lastBidderId == null ? '—' : shortNameOf(c, c.lastBidderId!);
      // Texto sin "de " (−22 px a 14 px): cantidad + pinta +
      // apostador intactos como datos; el Tooltip devuelve la
      // frase completa ("X apostó N Pintas") si se recorta.
      return Tooltip(
        message: '$name apostó ${cur!.quantity} ${facePlural(cur.face)}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2434).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiceFace(value: cur.face, size: 16),
              const SizedBox(width: 4),
              Text(
                '${cur.quantity} ${facePlural(cur.face)} · $name',
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CachoColors.ivory),
              ),
            ],
          ),
        ),
      );
    }

    Widget barIcon(double size, IconData icon, String tip, VoidCallback onTap) {
      return SizedBox(
        width: size,
        height: size,
        child: Material(
          color: const Color(0xFF1B2434).withValues(alpha: 0.88),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Tooltip(
              message: tip,
              child:
                  Icon(icon, size: size >= 44 ? 20 : 17, color: Colors.white),
            ),
          ),
        ),
      );
    }

    /// Micrófono en la barra (RONDA 2, F9): círculo 44 px en la
    /// fila derecha, en local Y en línea. En línea alterna la voz
    /// (toggleMic); en local NO hay canal de voz (la voz es WebRTC
    /// en malla solo en línea, regla 21), así que el toque avisa
    /// eso en vez de encender un estado falso. La insignia sobre
    /// el avatar sigue siendo el indicador de estado (solo en
    /// línea), no un segundo control.
    Widget micButton(double size) {
      final on = c.online ? c.myMicOn : _localMicOn;
      return SizedBox(
        width: size,
        height: size,
        child: Material(
          color: on
              ? const Color(0xFF2E7D32).withValues(alpha: 0.90)
              : const Color(0xFF1B2434).withValues(alpha: 0.88),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (c.online) {
                c.toggleMic();
              } else {
                setState(() => _localMicOn = !_localMicOn);
                _showCenterNotice(_localMicOn ? 'Micrófono activado' : 'Micrófono silenciado');
              }
            },
            child: Tooltip(
              message: on ? 'Silenciar micrófono' : 'Activar micrófono',
              child: Icon(
                on ? Icons.mic : Icons.mic_off,
                size: size >= 44 ? 20 : 17,
                color: on ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      );
    }

    /// Música plegada en la barra (F5/F8): abre la hoja DJ;
    /// mini-ecualizador cuando suena, punto dorado si falta el
    /// toque Activar. RONDA 2 (F9): presente en local Y en línea
    /// (era solo en línea). En local no hay DJ: el botón alterna
    /// el sonido de la sala (el mismo interruptor de la hoja de
    /// ajustes), con el icono dorado cuando suena.
    Widget musicButton(double size) {
      if (!c.online) {
        final on = AudioService.instance.enabled;
        return SizedBox(
          width: size,
          height: size,
          child: Material(
            color: const Color(0xFF1B2434).withValues(alpha: 0.88),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() => AudioService.instance.enabled = !on);
                AudioService.instance.syncAmbience();
              },
              child: Tooltip(
                message: 'Sonido',
                child: Icon(
                  Icons.music_note,
                  size: size >= 44 ? 22 : 17,
                  color: on ? CachoColors.gold : Colors.white54,
                ),
              ),
            ),
          ),
        );
      }
      final iconSize = size >= 44 ? 22.0 : 17.0;
      final eqW = size >= 44 ? 22.0 : 16.0;
      final eqH = size >= 44 ? 10.0 : 8.0;
      final dot = size >= 44 ? 10.0 : 8.0;
      // RONDA 4 (música en línea): MISMA estructura que la rama
      // local y que micButton — Material con CircleBorder de
      // size×size —, en vez del IconButton suelto anterior, que
      // dejaba la nota dorada 10×16 sin círculo oscuro en línea
      // (refutación agente 07 ronda 3; en local sí había
      // círculo). El ecualizador y el punto dorado se conservan
      // dentro del círculo, en las mismas posiciones.
      return SizedBox(
        width: size,
        height: size,
        child: Material(
          color: const Color(0xFF1B2434).withValues(alpha: 0.88),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => showMusicSheet(context, c),
            child: Tooltip(
              message: 'Música de la sala',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.music_note,
                      size: iconSize, color: CachoColors.gold),
                  if (musicCur != null && !musicCur.paused)
                    Positioned(
                      bottom: size >= 44 ? 4 : 2,
                      child: SizedBox(
                        width: eqW,
                        height: eqH,
                        child: const EqualizerBars(playing: true),
                      ),
                    ),
                  if (needsTap)
                    Positioned(
                      right: size >= 44 ? 4 : 2,
                      top: size >= 44 ? 4 : 2,
                      child: Container(
                        width: dot,
                        height: dot,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CachoColors.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget progress() {
      if (myTurn && c.turnEndsAt != null && frac != null) {
        return LinearProgressIndicator(
          value: frac,
          minHeight: 4,
          backgroundColor: Colors.white12,
          color: ringTimeColor(frac),
        );
      }
      return const SizedBox(height: 4);
    }

    return LayoutBuilder(
      builder: (context, cons) {
        if (cons.maxWidth >= 1000) {
          // Una fila solo cuando cabe ronda + saldo + turno + apuesta + controles.
          return SizedBox(
            height: _sketchBarH,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    // RONDA 3 (F3c): 8 → 6, aire para la apuesta.
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        exitPill(),
                        const SizedBox(width: 6),
                        balancePill(),
                        if (c.gameStarted) ...[
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 210),
                            child: roundInfo(),
                          ),
                        ],
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // RONDA 3 (F3c): el turno va INTRÍNSECO
                              // (sin Flexible) y la apuesta con
                              // Flexible: con turno flex 1 frente a
                              // apuesta flex 2 el turno se elipsaba
                              // ("Turno d…", "¡TU TUR…"). Ahora el
                              // turno nunca se recorta (toma lo que
                              // necesita) y la apuesta cede: su
                              // texto elipsa por la COLA (el nombre;
                              // cantidad + pinta van primero y no
                              // se truncan) con Tooltip completo.
                              // Medido en captura ronda 3 (mesa6):
                              // turno 149 + apuesta 195 (texto 151
                              // para "8 Quintas · La Pituca") +
                              // pozo 110 + gaps = 470 > ~443 libres,
                              // y la apuesta elipsaba el nombre en
                              // 27 px ("La Pi…"). Segundo ajuste:
                              // recortes de 2 px en la barra ancha
                              // (padding exterior 8→6, Salir/saldo/
                              // pozo 10→8, turno compacto 12→10,
                              // gaps 8→6, chip 8→6, gaps de iconos
                              // 4→2: +34 px para el texto) para que
                              // el peor caso con bots (9 caracteres)
                              // quepa entero; con apodos de 16
                              // caracteres la apuesta puede elipsar
                              // el nombre (piso: cantidad + pinta
                              // intactos + Tooltip).
                              if (playing)
                                _turnPill(shortName: true, compact: true)
                              else
                                Flexible(child: roomInfo()),
                              if (cur != null) ...[
                                const SizedBox(width: 6),
                                // RONDA 4 (apuesta en resolución):
                                // fuera de turno la apuesta ya NO
                                // comparte la fila a partes
                                // iguales con la etiqueta de sala:
                                // en revelación (p. ej.
                                // revelacion_paso.png ronda 3) la
                                // etiqueta "LOCAL · R3 · 28 dados"
                                // con flex 1 frente a flex 1 dejaba
                                // la píldora en "7 Quintas ·
                                // El Hu…" cortada. Ahora la
                                // apuesta lleva flex 3 frente a
                                // flex 1 de la sala (centro ~347
                                // px: sala ~87, apuesta ~260):
                                // cantidad + pinta + autor salen
                                // completos con nombres de 8
                                // caracteres (píldora ~186 px) y
                                // es la etiqueta de sala la que
                                // cede y elipsa si falta sitio.
                                // En mi turno no cambia nada
                                // (turno intrínseco + apuesta
                                // Flexible, piso ronda 3).
                                Flexible(flex: 3, child: _currentBidChip()),
                              ],
                            ],
                          ),
                        ),
                        // RONDA 2 (F9): mic + música 44 px en la
                        // fila derecha, en local Y en línea, con
                        // historial y ajustes (44 px también: el
                        // _roundChip de 48 se sustituye por
                        // barIcon 44 para que la fila sea uniforme).
                        micButton(44),
                        // RONDA 3 (F3c): gaps 4 → 2, aire apuesta.
                        const SizedBox(width: 2),
                        musicButton(44),
                        const SizedBox(width: 2),
                        barIcon(44, Icons.history, 'Historial',
                            () => showHistorySheet(context, c)),
                        const SizedBox(width: 2),
                        barIcon(44, Icons.settings, 'Ajustes',
                            _showGameSettingsSheet),
                      ],
                    ),
                  ),
                ),
                progress(),
              ],
            ),
          );
        }
        // Angosto (< 1000): dos filas para que ronda y apuesta
        // quepa a 14 px sin solapes (la fila 2 se recorta con
        // elipsis en el peor caso: ver comentario de _sketchTopBar).
        return SizedBox(
          height: 56,
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      exitPill(),
                      const SizedBox(width: 6),
                      balancePill(),
                      const Spacer(),
                      // RONDA 2 (F9): mic + música también en
                      // angosto (28 px: la fila mide 28 y un
                      // círculo 44 no cabe; piso documentado).
                      micButton(28),
                      const SizedBox(width: 4),
                      musicButton(28),
                      const SizedBox(width: 4),
                      barIcon(28, Icons.history, 'Historial',
                          () => showHistorySheet(context, c)),
                      const SizedBox(width: 4),
                      barIcon(28, Icons.settings, 'Ajustes',
                          _showGameSettingsSheet),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (showPot) potPill(tight: true),
                      if (showPot && (c.gameStarted || playing || cur != null))
                        const SizedBox(width: 6),
                      if (c.gameStarted) ...[
                        Flexible(flex: 2, child: roundInfo()),
                        if (playing || cur != null) const SizedBox(width: 4),
                      ],
                      if (playing)
                        // Prioridad fila 2 (ver comentario): la
                        // apuesta lleva flex 2 y el turno flex 1;
                        // en mi turno la píldora dorada va
                        // intrínseca para no recortarse nunca.
                        myTurn
                            ? turnPillCompact()
                            : Flexible(flex: 1, child: turnPillCompact())
                      else if (!c.gameStarted)
                        Flexible(child: roomInfo()),
                      if (cur != null) ...[
                        const SizedBox(width: 6),
                        Flexible(flex: myTurn ? 1 : 2, child: bidChipCompact()),
                      ],
                    ],
                  ),
                ),
              ),
              progress(),
            ],
          ),
        );
      },
    );
  }

  /// Ficha de la apuesta vigente (barra superior horizontal).
  /// RONDA 2 (F6): sin "de " (−22 px, como la compacta) y con
  /// Tooltip con la frase completa: la apuesta SE MANTIENE
  /// (dato necesario aunque el ejemplo no la muestre) y debe
  /// leerse entera; si un apodo en línea muy largo la supera,
  /// cantidad + pinta van primero y nunca se truncan, el nombre
  /// se elipsa y se recupera en el Tooltip (piso documentado).
  Widget _currentBidChip() {
    final cur = c.currentBid!;
    final name = c.lastBidderId == null ? '—' : shortNameOf(c, c.lastBidderId!);
    return Tooltip(
      message: '$name apostó ${cur.quantity} ${facePlural(cur.face)}',
      child: Container(
        // RONDA 3 (F3c): horizontal 6 (era 10, luego 8), aire texto.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2434).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DiceFace(value: cur.face, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${cur.quantity} ${facePlural(cur.face)} · $name',
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CachoColors.ivory),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fotos de las salas por apuesta; coinciden con los nombres del tier.
  String _mesaFondoAsset(int stake) {
    return switch (stake) {
      100 => 'assets/images/mesa_mockup_clean.jpg',
      250 => 'assets/images/mesa_salon_3d.jpg',
      500 => 'assets/images/mesa_casino_3d.jpg',
      1000 => 'assets/images/mesa_vip_3d.jpg',
      2500 => 'assets/images/mesa_highroller_3d.jpg',
      _ => 'assets/images/mesa_mockup_clean.jpg',
    };
  }

  /// Asientos, vasos y pozo comparten la geometría de TableGeometry.
  Widget _sketchTable(List<PlayerView> others, double tableH, bool compact) {
    final screenW = MediaQuery.sizeOf(context).width;
    
    // Generar geometría de la mesa con TableGeometryGenerator
    final geometry = TableGeometryGenerator.generate(
      screenWidth: screenW,
      screenHeight: 56 + tableH + 72,
      barTop: 56,
      consoleHeight: 72,
      playerCount: 1 + others.length,
    );
    
    // Mantener compatibilidad: usar sketchLayout solo para obtener compact
    final layout = sketchLayout(
      screenW: screenW,
      screenH: 56 + tableH + 72,
      rivals: others.length,
      myDiceCount: c.myHand.length,
      consoleH: 72,
    );
    final layoutCompact = layout.compact;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Pozo arriba al centro (bosquejo): UNA fila —
        // etiqueta POZO + vaso pequeño 30×36 + monto REAL
        // potFixed. Corrección 25-oct: el vaso ya NO es enorme
        // al centro ni tapa "CACHO O DUDO". El vaso propio
        // levantado queda en top ~112 (compacto) / ~116
        // (completo), por debajo del pozo (58..94).
        // Pulido ÁREA 7 (25-oct, sin cambiar el tipo): el rect
        // del layout sigue siendo 140×36, pero el widget usa
        // 180×40 centrado en el mismo cx: el contenido máximo
        // real (apuesta 2.500 × 8 = "20.000") mide ~150-160 px
        // y en 140 se arriesgaba a truncar/desbordar; en 180
        // cabe sin truncar y sin tocar nada (medido SIN SOLAPE
        // a 5 y a 8 jugadores, a 390 y a 350, contra asientos,
        // placas, vasos y mi vaso). Alto 40 = la altura real
        // de la pastilla (vaso 36 + padding 4): antes el rect
        // de 36 la desbordaba 2 px por arriba y por abajo.
        // RONDA 2 (F5): la pastilla ocupa y 2..34 relativa a la
        // mesa (alto 32: vaso 28 + padding 4): su borde inferior
        // (y 34 relativa = 90 en pantalla) TOCA sin cruzar el
        // avatar superior (empieza en 90); antes (alto 40, hasta
        // 98) el avatar la cruzaba 8 px. El vaso de la pastilla
        // baja a 24×28 para que la pastilla no lo cruce: vaso
        // DENTRO de la pastilla, nunca cruzándola. Monto a 14 px,
        // softWrap false: nunca se parte en dos líneas ni se
        // trunca. NO es la pila vertical del mockup: ese cambio
        // queda para la decisión del final del día (ver reporte:
        // a 8 choca con un vaso rival y en ambos casos tapa el
        // watermark).
        Positioned(
          left: geometry.potRect.left - 20,
          top: geometry.potRect.top,
          width: geometry.potRect.width + 40,
          height: 36,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF162544), Color(0xFF0C1322)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: CachoColors.gold,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: CachoColors.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'POZO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CachoColors.gold,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 5),
                      ],
                    ),
                    softWrap: false,
                  ),
                  const SizedBox(width: 6),
                  const CoinIcon(size: 16),
                  const SizedBox(width: 5),
                  Text(
                    coinsText(c.displayPot),
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CachoColors.ivory,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Asientos rivales: avatar + placa + vaso desde geometry.
        // Se adaptan las coordenadas de TableGeometry a SketchSeat
        // para mantener compatibilidad con _sketchRivalSeat.
        for (var i = 0; i < others.length && i < geometry.seats.length; i++)
          ..._sketchRivalSeat(
              others[i],
              _seatGeometryToSketchSeat(geometry.seats[i]),
              others.length >= 7,
              screenW),
        // Mi escenario (vaso + dados con hueco 104).
        Positioned(
          left: layout.myCup.cx - 165,
          top: layout.myCup.top - 56 + (layoutCompact ? 52 : 76) - 140 + 7,
          child: _myStageSketch(compact: layoutCompact),
        ),
        // Mi asiento (RONDA 2, F4): placa CENTRADA BAJO mi avatar
        // (antes en fila a su derecha, descentrada). El widget
        // mide 120 de ancho (la placa) centrado en la pantalla:
        // avatar 390..454 sobre la placa 362..482, ambos
        // centrados en mi vaso (422) y en el hueco de dados.
        // La placa cuelga bajo la mesa sobre la tira VER (su
        // zona central está vacía: VER a la izquierda, emotes
        // a la derecha) y termina antes de la consola.
        Positioned(
          left: screenW / 2 - 60,
          top: layout.myAvatar.top - 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _mySeatSketch(),
              if (c.emotePlayerId == c.myId && c.emoteGlyph != null)
                Positioned(
                  top: -40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingEmote(
                      key: ValueKey(c.emoteSeq),
                      glyph: c.emoteGlyph!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Un asiento rival bosquejo: avatar (56 + aro), placa bosquejo
  /// y vaso 56×64 liso (huella 70×72 con posavasos), cada uno en
  /// su rect del layout. ÁREA 2 (mockup): la placa va SIEMPRE
  /// debajo del avatar; los inferiores (60/120) llevan placa
  /// de una línea; en arco igual (7+) la placa es de 84.
  List<Widget> _sketchRivalSeat(PlayerView p, SketchSeat geom,
      [bool small = false, double screenW = 844]) {
    final angle = geom.angleDeg;
    const plateSide = SketchPlateSide.below;
    final balance = p.isBot ? null : (c.online ? p.balance : null);
    // F6: nombre corto real sin prefijo "Bot " (el motor local
    // nombra "Bot El Guatón"; la placa y las iniciales usan el corto).
    final shortNick = shortNameOf(c, p.id);
    // El rect del layout es 58/48 (círculo+aro); el widget es
    // 64/56 (con sombra): se recentra 3 px para que el círculo
    // quede sobre el centro del layout. En arco igual (7+)
    // avatar 46 y vaso 40×46 (ver sketch_layout.dart).
    // CORRECCIÓN 26-oct: el asiento superior del mockup-6 tiene
    // rect 48 con vaso NORMAL (small=false): widget 56 (radio 23)
    // recentrado 4 px (no 3), para que el círculo quede centrado.
    final avatarIs48 = geom.avatar.width == 48;
    final avatarWidget = small || avatarIs48 ? 56 : 64;
    final avatarOff = small ? 3 : (avatarIs48 ? 4 : 3);
    final avatar = Positioned(
      left: geom.avatar.left - avatarOff,
      top: geom.avatar.top - 56 - avatarOff,
      width: avatarWidget.toDouble(),
      height: avatarWidget.toDouble(),
      child: _seatShadow(PlayerSeat(
        nickname: shortNick,
        avatarRadius: avatarWidget == 56 ? 23 : 27,
        seed: p.id,
        diceCount: p.diceCount,
        isTurn: c.actorId == p.id,
        eliminated: p.eliminated,
        isBot: p.isBot,
        connected: p.connected,
        hasPendingPaso: c.pendingPasoId == p.id,
        landscape: true,
        sketchPlate: true,
        showPlate: false,
        ringColor: _ringColorFor(p.id),
        ringFraction: _ringFractionFor(p.id),
        micOn: (c.online && !p.isBot) ? p.micOn : null,
        dcDeadlineMs: p.dcDeadlineMs,
      )),
    );
    // RONDA 2 (F4): la placa SOLAPA el borde inferior del avatar
    // 6 px (antes quedaba 2 px separada): −8 en top. Roce de
    // esquina placa~vaso ≤ ~150 px² en laterales (solo padding
    // de la placa, el texto va centrado) y ~205 px² en 60/120;
    // el vaso pinta después y cubre ese rincón, no el texto.
    // RONDA 2 corrección 2 (F6, medida en captura): el
    // Positioned TENÍA el ancho del rect del layout (88 en la
    // superior del mockup-6) y esa restricción, no el clip del
    // Stack, era la que truncaba "×5 · El Huaso" a "El Hu…"
    // pese a la caja de texto de 132: el ancho del Positioned
    // manda sobre el del hijo. Se ensancha a 132 con la MISMA
    // izquierda del layout (la superior corrida queda en
    // 222..354, sin tocar mi vaso) y con tope al borde derecho
    // de la pantalla para las placas de la derecha.
    final plateW = max(geom.plate.width, 132.0);
    final plateLeft = max(0.0, min(geom.plate.left, screenW - plateW));
    final plate = Positioned(
      left: plateLeft,
      top: geom.plate.top - 56 - 8,
      width: plateW,
      child: PlayerSeat(
        nickname: shortNick,
        seed: p.id,
        diceCount: p.diceCount,
        isTurn: c.actorId == p.id,
        eliminated: p.eliminated,
        isBot: p.isBot,
        connected: p.connected,
        hasPendingPaso: c.pendingPasoId == p.id,
        landscape: true,
        sketchPlate: true,
        plateOnly: true,
        plateSide: plateSide,
        plateWidth: plateW,
        singleLinePlate: geom.singleLinePlate || angle == 60 || angle == 120,
        balance: balance,
        ringColor: _ringColorFor(p.id),
        ringFraction: _ringFractionFor(p.id),
        micOn: null,
        dcDeadlineMs: p.dcDeadlineMs,
      ),
    );
    // Huella con posavasos 1,3× (73×72; 52×54 en arco igual):
    // el rect del layout es solo el vaso (56×64 / 40×46); el
    // posavasos sobresale ~8 px por lado (6 en arco igual) y
    // 4 abajo. Bosquejo: vaso LISO, sin iniciales doradas,
    // boca abajo siempre (RivalCup: mouthDown true).
    final cup = Positioned(
      left: geom.cup.left - (small ? 6 : 8),
      top: geom.cup.top - 56 - 4,
      width: small ? 52 : 73,
      height: small ? 54 : 72,
      child: RivalCup(
        leather: CachoColors.leatherLight,
        cupW: small ? 40 : 56,
        cupH: small ? 46 : 64,
        skinId: p.cupSkinId,
      ),
    );
    // Reacción del rival (relay en línea pendiente: hoy solo puede
    // llegar por el caso 'emote' del controlador cuando el servidor
    // lo difunda; en local nunca hay reacciones rivales). Flota
    // sobre su avatar, igual que la mía sobre el mío.
    final emoteBubble = c.emotePlayerId == p.id && c.emoteGlyph != null
        ? Positioned(
            left: geom.avatar.left - avatarOff,
            top: geom.avatar.top - 56 - avatarOff - 40,
            width: avatarWidget.toDouble(),
            height: 40,
            child: Center(
              child: FloatingEmote(
                key: ValueKey(c.emoteSeq),
                glyph: c.emoteGlyph!,
              ),
            ),
          )
        : null;
    return [avatar, plate, cup, if (emoteBubble != null) emoteBubble];
  }

  Widget _mySeatSketch() {
    final me = c.me;
    return PlayerSeat(
      nickname: c.myNickname,
      seed: c.myId,
      diceCount: me?.diceCount ?? 0,
      showDiceNumber: true,
      isTurn: c.actorId == c.myId,
      eliminated: me?.eliminated ?? false,
      isBot: false,
      connected: true,
      hasPendingPaso: c.pendingPasoId == c.myId,
      landscape: true,
      sketchPlate: true,
      // RONDA 2 (F4): placa debajo y centrada (120 de ancho para
      // que un apodo largo no se corte; sin saldo: mi saldo real
      // vive solo en la barra). La placa solapa el borde inferior
      // del avatar 6 px (rama below de PlayerSeat).
      plateSide: SketchPlateSide.below,
      plateWidth: 120,
      ringColor: CachoColors.gold,
      ringFraction: _ringFractionFor(c.myId),
      micOn: c.online ? c.myMicOn : null,
      onMicTap: c.online ? () => c.toggleMic() : null,
    );
  }

  /// Mi escenario bosquejo (mesa viva): ceguera Kamikaze y
  /// animación AN16, en caja 330×140. Paridad V1: SIN long-press
  /// peek (violaría el "solo VER") y SIN revelación por toque:
  /// el toque solo menea el vaso cerrado (`_tapCup`).
  /// Los dados Blender van a 36 px (28 en compacto) en banda
  /// inferior con hueco 104 centrado sobre mi avatar (ancla
  /// 113 − L). El vaso va a 64×76 (44×52 en compacto), liso,
  /// sin iniciales: el vaso enorme era lo que el usuario leyó
  /// como "vaso del pozo" tapando el centro.
  Widget _myStageSketch({bool compact = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleEye,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            _setOpen(true, fast: true);
          } else if (details.primaryVelocity! > 100) {
            _setOpen(false, fast: true);
          }
        }
      },
      child: SizedBox(
        width: 330,
        height: 140,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_shakeCtrl, _liftCtrl, _squashCtrl, _entryCtrl]),
          builder: (context, _) {
            final sv = _shakeCtrl.value;
            final lift = _kamikazeBlind ? 0.0 : _liftCurve.value;
            final env = _shakeCtrl.isAnimating ? (1 - sv) : 0.0;
            final rotY = sin(sv * pi * 6) * env * 0.5 + 0.12 * lift;
            final rotX = cos(sv * pi * 5) * env * 0.22 - 0.17 * lift;
            double hopY = 0;
            if (_shakeCtrl.isAnimating) {
              if (sv < 0.7) {
                hopY = -14 * sin((sv / 0.7) * pi);
              } else {
                hopY = -14 *
                    (1 -
                        Curves.bounceOut
                            .transform(((sv - 0.7) / 0.3).clamp(0, 1)));
              }
            }
            // El vaso viaja en vertical al levantarse (62 px hacia arriba),
            // dejando el posavasos estático sobre la mesa y revelando
            // los dados debajo.
            final liftDy = 62.0 * lift;
            final dy = hopY - liftDy;
            final entryDrop = (1 - _entryCtrl.value) * 80;
            final squash = 1 - 0.07 * sin(_squashCtrl.value * pi);
            final cupW = compact ? 44.0 : 64.0;
            final cupH = compact ? 52.0 : 76.0;
            final cupLeft = (330 - cupW) / 2;
            final coasterW = CachoCup.coasterWidthFor(cupW);
            final coasterH = coasterW / 3.0;
            final shadowW = cupW * 0.9 * (1.0 - 0.25 * lift) + hopY;
            final shadowA =
                ((0.45 - 0.2 * lift) + hopY * 0.006).clamp(0.08, 0.5);
            final nDice = c.myHand.length;
            final dieSize = compact ? 32.0 : 46.0;
            final totalDiceW =
                nDice == 0 ? 0.0 : nDice * dieSize + (nDice - 1) * 4.0;
            final diceLeft = (330 - totalDiceW) / 2;
            return Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // 1. Posavasos ESTÁTICO sobre la mesa: NO se mueve con el vaso.
                Positioned(
                  left: (330 - coasterW) / 2,
                  bottom: compact ? 3 : 5,
                  child: Image.asset(
                    'assets/images/coaster.png',
                    width: coasterW,
                    height: coasterH,
                    fit: BoxFit.contain,
                  ),
                ),
                // 2. Sombra del vaso en la mesa
                Positioned(
                  left: (330 - shadowW) / 2,
                  bottom: compact ? 6 : 9,
                  child: Container(
                    width: shadowW,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: shadowA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // 3. Mis dados agrupados y centrados sobre el posavasos/mesa
                Positioned(
                  bottom: compact ? 8 : 12,
                  left: diceLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < nDice; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        _cubeDie(i, lift, size: dieSize, blender: false),
                      ],
                    ],
                  ),
                ),
                // 4. El vaso: se eleva e inclina sobre los dados
                Positioned(
                  left: cupLeft,
                  bottom: 7 - dy + entryDrop,
                  child: RepaintBoundary(
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0011)
                        ..rotateX(rotX)
                        ..rotateY(rotY)
                        ..scaleByDouble(1, squash, 1, 1),
                      child: CachoCup(
                        width: cupW,
                        height: cupH,
                        leather: widget.leather,
                        dimmed: c.me?.eliminated ?? false,
                        mouthDown: true,
                        showCoaster: false, // NO duplicar posavasos
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// R43: sombra ÚNICA bajo cada asiento (misma luz que la cenital
  /// R39: suave, neutra, idéntica en turno y fuera, detrás del
  /// asiento — nunca tapa el aro semáforo ni las pipas).
  Widget _seatShadow(Widget child) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 2,
          child: Container(
            width: 64,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withValues(alpha: 0.45),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _potChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2434).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CachoColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 14),
          const SizedBox(width: 4),
          Text(
            'Pozo: ${coinsText(c.displayPot)}',
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: CachoColors.ivory),
          ),
        ],
      ),
    );
  }

  /// Hoja de ajustes en partida (B13): solo historial, glosario y
  /// sonido. Sin micrófono (regla 21: solo sobre la foto).
  void _showGameSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CachoColors.leatherDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AJUSTES',
                style: titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.history, color: CachoColors.gold),
              title: const Text('Historial de la partida',
                  style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showHistorySheet(context, c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: CachoColors.gold),
              title: const Text('Glosario', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showGlossaryDialog(context);
              },
            ),
            ListTile(
              leading: Icon(
                AudioService.instance.enabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: CachoColors.gold,
              ),
              title: Text(
                  AudioService.instance.enabled
                      ? 'Sonido: activado'
                      : 'Sonido: silenciado',
                  style: const TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                setState(() => AudioService.instance.enabled =
                    !AudioService.instance.enabled);
                AudioService.instance.syncAmbience();
              },
            ),
            // AN17: interruptor de animaciones (persistido, como en
            // Personalizar; nunca apaga semáforo, barra ni pitidos).
            AnimatedBuilder(
              animation: Settings.instance,
              builder: (_, __) => SwitchListTile(
                title:
                    const Text('Animaciones', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Telón, partículas y efectos de casino',
                    style: TextStyle(fontSize: 14)),
                value: Settings.instance.animationsEnabled,
                onChanged: (v) {
                  Settings.instance.animationsEnabled = v;
                  Settings.instance.save();
                },
                activeColor: CachoColors.gold,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hoja de chat rápido y reacciones (mockup.jpeg)
  void _showQuickChatSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF14100C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        const phrases = [
          ('😂', '¡Qué risa!'),
          ('🔥', '¡En llamas!'),
          ('👏', '¡Buena jugada!'),
          ('😮', '¡No te creo nada!'),
          ('👍', 'Pasa la mano...'),
          ('🔥', '¡Dudo que tengas eso!'),
          ('👏', '¡Te calzo al tiro!'),
          ('😮', '¡Aquí no hay ases!'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CHAT RÁPIDO & REACCIONES',
                      style: TextStyle(
                        fontFamily: CachoFonts.display,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CachoColors.gold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final g in MatchController.emotes)
                      Material(
                        color: const Color(0xFF1E293B),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            c.sendEmote(g);
                            Navigator.of(sheetCtx).pop();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CachoColors.gold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Center(
                              child:
                                  Text(g, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in phrases)
                      ActionChip(
                        avatar:
                            Text(p.$1, style: const TextStyle(fontSize: 15)),
                        label: Text(
                          p.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CachoColors.ivory,
                          ),
                        ),
                        backgroundColor: const Color(0xFF1E293B),
                        side: BorderSide(
                          color: CachoColors.gold.withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          c.sendQuickChat('${p.$1} ${p.$2}');
                          Navigator.of(sheetCtx).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pastilla de turno. En horizontal (D10) usa el nombre corto y
  /// elipsis: con nombres largos la barra desbordaba sobre la
  /// billetera (peek.png: "Turno de Bot La Cuca" + "5 Cuadras · de
  /// El Guatón" + pozo). En horizontal además va compacta (C5,
  /// decidido por el usuario: 26–28 px en vez de ~38). El vertical
  /// no cambia (shortName y compact false por defecto).
  Widget _turnPill({bool shortName = false, bool compact = false}) {
    final mine = c.isMyTurn;
    var name = '';
    if (shortName) {
      name = shortNameOf(c, c.actorId);
    } else {
      for (final p in c.players) {
        if (p.id == c.actorId) name = p.nickname;
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey('turn-${c.actorId}'),
        // B9 (sentencia v2.0): pastilla de turno más grande, dentro
        // de su franja, sin desplazar la mesa ni tapar el aro.
        // C5: en horizontal va compacta (26–28 px de alto; medida
        // real con padding 5: 30 px, por eso baja a 4).
        // RONDA 3 (F3c): horizontal 10 en compacto (era 18, luego
        // 12) para que la apuesta quepa entera; el turno sigue
        // intrínseco y nunca se recorta.
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 18, vertical: compact ? 4 : 8),
        decoration: BoxDecoration(
          color: mine
              ? CachoColors.gold
              : const Color(0xFF1B2434).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: mine
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          mine ? '¡TU TURNO!' : 'Turno de $name',
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w800,
            color: mine ? const Color(0xFF221A08) : CachoColors.ivory,
          ),
        ),
      ),
    );
  }

  /// Mi asiento (abajo a la izquierda): aro dorado, estado y pipas.
  Widget _mySeat({bool compact = false}) {
    final me = c.me;
    final myLast = c.lastActionBy[c.myId];
    return PlayerSeat(
      nickname: c.myNickname,
      seed: c.myId,
      diceCount: me?.diceCount ?? 0,
      showDiceNumber: true,
      isTurn: c.actorId == c.myId,
      eliminated: me?.eliminated ?? false,
      isBot: false,
      connected: true,
      hasPendingPaso: c.pendingPasoId == c.myId,
      compact: compact,
      ringColor: CachoColors.gold,
      ringFraction: _ringFractionFor(c.myId),
      bubbleText: myLast != null ? eventLabel(myLast) : null,
      bubbleBid: myLast?.type == 'bid' ? myLast!.bid : null,
      micOn: c.online ? c.myMicOn : null,
      onMicTap: c.online ? () => c.toggleMic() : null,
    );
  }

  /// Mi vaso gigante al centro de la mesa, con su secuencia: se agita
  /// en el aire, cae (sombra, rebote, golpe) y se levanta inclinado;
  /// debajo quedan mis dados como cubos 3D que salen rodando.
  Widget _myStage({bool compact = false}) {
    final me = c.me;
    return GestureDetector(
      onTap: _tapCup,
      onLongPressStart: (_) {
        if (_kamikazeBlind) return;
        if (!_open) {
          _liftCtrl.animateTo(1, duration: const Duration(milliseconds: 200));
        }
      },
      onLongPressEnd: (_) {
        if (!_open) {
          _liftCtrl.animateTo(0, duration: const Duration(milliseconds: 200));
        }
      },
      child: SizedBox(
        width: 300,
        height: 252,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_shakeCtrl, _liftCtrl, _squashCtrl, _entryCtrl]),
          builder: (context, _) {
            final sv = _shakeCtrl.value;
            // En la ceguera del Kamikaze el vaso se dibuja SIEMPRE
            // abajo, tapando los dados, esté como esté el estado.
            final lift = _kamikazeBlind ? 0.0 : _liftCurve.value;
            final env = _shakeCtrl.isAnimating ? (1 - sv) : 0.0;
            final rotY = sin(sv * pi * 6) * env * 0.5 + 0.12 * lift;
            final rotX = cos(sv * pi * 5) * env * 0.22 - 0.17 * lift;
            double hopY = 0;
            if (_shakeCtrl.isAnimating) {
              if (sv < 0.7) {
                hopY = -14 * sin((sv / 0.7) * pi);
              } else {
                hopY = -14 *
                    (1 -
                        Curves.bounceOut
                            .transform(((sv - 0.7) / 0.3).clamp(0, 1)));
              }
            }
            final dy = hopY - 96 * lift;
            // AN16: el vaso desciende y se posa al entrar.
            final entryDrop = (1 - _entryCtrl.value) * 80;
            final squash = 1 - 0.07 * sin(_squashCtrl.value * pi);
            final shadowW = 150 - 42 * lift + hopY;
            final shadowA =
                (0.45 - 0.17 * lift + hopY * 0.006).clamp(0.08, 0.5);
            // Sentencia v53 (hueco central): la fila de dados se parte
            // en dos grupos con un hueco de 104 sobre mi avatar, que
            // quedó al centro bajo el vaso. El centro del HUECO —no de
            // la fila, que es asimétrica— se ancla al centro de la caja
            // (150): la fila empieza en 150 − 52 − leftW.
            final nDice = c.myHand.length;
            final leftCount = nDice ~/ 2;
            final leftW =
                leftCount == 0 ? 0.0 : leftCount * 44.0 + (leftCount - 1) * 2.0;
            final diceLeft = 98.0 - leftW;
            return Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Halo ambiental cálido bajo el vaso
                Positioned(
                  left: 42,
                  bottom: 9,
                  child: Container(
                    width: 216,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // Sombra del vaso sobre la mesa
                Positioned(
                  left: (300 - shadowW) / 2,
                  bottom: 16,
                  child: Container(
                    width: shadowW,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: shadowA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // Mis dados: cubos que salen rodando al levantarse.
                // Sentencia v53: dos grupos con un hueco central de 104
                // sobre mi avatar, para que ningún dado quede detrás de
                // él. El Stack tiene Clip.none, así que la fila (330)
                // puede sobresalir de la caja (300) sin recortarse.
                Positioned(
                  bottom: 0,
                  left: diceLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < leftCount; i++) ...[
                            if (i > 0) const SizedBox(width: 2),
                            _cubeDie(i, lift),
                          ],
                        ],
                      ),
                      const SizedBox(width: 104),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = leftCount; i < nDice; i++) ...[
                            if (i > leftCount) const SizedBox(width: 2),
                            _cubeDie(i, lift),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_kamikazeBlind &&
                    !_open &&
                    !_dockOpen &&
                    lift < 0.1 &&
                    c.myHand.isNotEmpty)
                  Positioned(
                    left: 0,
                    width: 300,
                    // En modo compacto la mesa se achica y mi asiento
                    // queda pegado bajo el vaso: el texto sube para
                    // no taparse con la insignia del micrófono.
                    bottom: compact ? 16 : 2,
                    child: Text(
                      'toca el vaso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: CachoColors.ivory.withValues(alpha: 0.85),
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                // El vaso, con perspectiva 3D
                Positioned(
                  left: 66,
                  bottom: 12 - dy + entryDrop,
                  child: RepaintBoundary(
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0011)
                        ..rotateX(rotX)
                        ..rotateY(rotY)
                        ..scaleByDouble(1, squash, 1, 1),
                      child: CachoCup(
                        width: 168,
                        height: 196,
                        leather: widget.leather,
                        initials: _initialsOf(c.myNickname),
                        dimmed: me?.eliminated ?? false,
                        // En la mesa el vaso vive boca abajo, tapando
                        // los dados (orden del usuario).
                        mouthDown: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Tarjeta de estado (estilo de la referencia): de quién es el turno
  /// y cuál es la apuesta vigente. Dos líneas, solo información.
  Widget _statusCard() {
    final bid = c.currentBid;
    final title = c.isMyTurn
        ? 'Tu turno'
        : (c.actorId != null
            ? 'Turno de ${nameOf(c, c.actorId)}'
            : 'Ronda ${c.round}');
    final sub = bid == null
        ? 'Sin apuesta todavía'
        : '${nameOf(c, c.lastBidderId)} apostó ${bid.quantity} ${facePlural(bid.face)}';
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: navyCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
            child: Center(child: DiceCube(value: bid?.face ?? 5, size: 28)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                Text(sub,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Botón redondo oscuro de la barra superior.
  Widget _roundChip(IconData icon, String tip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Material(
        color: const Color(0xFF1B2434).withValues(alpha: 0.88),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, size: 19),
          color: Colors.white,
          tooltip: tip,
          onPressed: onTap,
        ),
      ),
    );
  }

  /// Un dado-cubo con su entrada escalonada según el avance del
  /// levantamiento (rueda y crece hasta quedar quieto en la mesa).
  Widget _cubeDie(int i, double lift,
      {double size = 44, bool blender = false}) {
    final t = ((lift - i * 0.06) / 0.8).clamp(0.0, 1.0);
    final v = c.myHand[i];
    // Con la consola abierta, mis dados que cuentan para la pinta
    // armada se encienden con borde dorado sobre la mesa. En
    // landscape la cara armada vive en _consoleArmed (el BidDock
    // vertical no se monta); en vertical, en _armedFace.
    final effFace = _armedFace ?? _consoleArmedFace;
    final counts = _dockOpen &&
        effFace != null &&
        (v == effFace ||
            (effFace != 1 && c.uiConfig.wildcardsEffective && v == 1));
    return Opacity(
      opacity: t,
      child: Transform.rotate(
        angle: (1 - t) * -1.1 + i * 0.05,
        child: Transform.scale(
          scale: 0.4 + 0.6 * t,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.25),
              border: counts
                  ? Border.all(color: CachoColors.gold, width: 2.2)
                  : null,
            ),
            // Mesa bosquejo: dados PLANOS DiceCube (25-oct: los
            // Blender no se leían); el vertical congelado sigue
            // con DiceCube (size 44 por defecto).
            child: blender
                ? BlenderDie(value: v, size: size)
                : DiceCube(value: v, size: size),
          ),
        ),
      ),
    );
  }

  /// Posiciones alrededor de la mesa según cuántos rivales haya:
  /// arriba a los lados y a media altura, como en la referencia.
  Alignment _slotFor(int count, int i) {
    const topLeft = Alignment(-0.96, -1);
    const topCenter = Alignment(0, -1);
    const topRight = Alignment(0.96, -1);
    const midLeft = Alignment(-1, 0.42);
    const midRight = Alignment(1, 0.42);
    // Mesas grandes (salas de hasta 12, orden del usuario 24-oct):
    // fila de arriba de 4, segunda fila de hasta 4, costados y —
    // con 11 rivales— un asiento central sobre el vaso.
    const topMidL = Alignment(-0.33, -1);
    const topMidR = Alignment(0.33, -1);
    const row2L = Alignment(-0.98, -0.36);
    const row2InL = Alignment(-0.64, -0.36);
    const row2MidL = Alignment(-0.33, -0.36);
    const row2C = Alignment(0, -0.36);
    const row2MidR = Alignment(0.33, -0.36);
    const row2InR = Alignment(0.64, -0.36);
    const row2R = Alignment(0.98, -0.36);
    const lowCenter = Alignment(0, 0.08);
    final slots = switch (count) {
      1 => [topCenter],
      2 => [topLeft, topRight],
      // 3 rivales: todos arriba (antes el tercero caía al costado y
      // se montaba sobre el de la esquina, queja del usuario).
      3 => [topLeft, topCenter, topRight],
      4 => [topLeft, topRight, midLeft, midRight],
      5 => [topLeft, topCenter, topRight, midLeft, midRight],
      6 => [topLeft, topMidL, topMidR, topRight, midLeft, midRight],
      7 => [topLeft, topMidL, topMidR, topRight, row2C, midLeft, midRight],
      8 => [
          topLeft,
          topMidL,
          topMidR,
          topRight,
          row2InL,
          row2InR,
          midLeft,
          midRight,
        ],
      9 => [
          topLeft,
          topMidL,
          topMidR,
          topRight,
          row2InL,
          row2C,
          row2InR,
          midLeft,
          midRight,
        ],
      10 => [
          topLeft,
          topMidL,
          topMidR,
          topRight,
          row2L,
          row2MidL,
          row2MidR,
          row2R,
          midLeft,
          midRight,
        ],
      _ => [
          topLeft,
          topMidL,
          topMidR,
          topRight,
          row2L,
          row2MidL,
          row2MidR,
          row2R,
          midLeft,
          midRight,
          lowCenter,
        ],
    };
    return slots[i];
  }

  /// Color de aro estable por rival (el mío es el dorado).
  Color _ringColorFor(String playerId) {
    final rivals = c.players.where((p) => p.id != c.myId).toList();
    final idx = rivals.indexWhere((p) => p.id == playerId);
    return seatRingColors[(idx < 0 ? 0 : idx) % seatRingColors.length];
  }

  Widget _seatFor(PlayerView p, {bool compact = false, bool deep = false}) {
    final last = c.lastActionBy[p.id];
    return PlayerSeat(
      nickname: p.nickname,
      seed: p.id,
      diceCount: p.diceCount,
      isTurn: c.actorId == p.id,
      eliminated: p.eliminated,
      isBot: p.isBot,
      connected: p.connected,
      hasPendingPaso: c.pendingPasoId == p.id,
      compact: compact || c.players.length > 4,
      hideBubble: (compact || c.players.length > 4) && deep,
      ringColor: _ringColorFor(p.id),
      ringFraction: _ringFractionFor(p.id),
      bubbleText: last != null ? eventLabel(last) : null,
      bubbleBid: last?.type == 'bid' ? last!.bid : null,
      bubbleReason: c.guided && p.isBot ? c.botReasonBy[p.id] : null,
      micOn: (c.online && !p.isBot) ? p.micOn : null,
      dcDeadlineMs: p.dcDeadlineMs,
    );
  }

  String _initialsOf(String name) {
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'YO';
    return parts.take(2).map((s) => s[0].toUpperCase()).join();
  }

  Widget _winnerOverlay() {
    if (c.guided) {
      _s.markGuidedDone();
    }
    final iWon = !c.isDraw && c.winnerId == c.myId;
    final title = c.guided
        ? '¡TUTORIAL COMPLETADO!'
        : (c.isDraw
            ? '¡EMPATE!'
            : (iWon ? '¡GANASTE!' : 'GANÓ ${nameOf(c, c.winnerId)}'));
    final sub = c.guided
        ? '¡Excelente! Ya conoces la dinámica del Cacho y estás listo para jugar en las salas reales.'
        : (c.isDraw
            ? (c.stake > 0
                ? 'Se te devolvió tu apuesta de ${coinsText(c.stake)}.'
                : 'Sin ganador.')
            : (c.pot > 0 && !iWon
                ? '${shortNameOf(c, c.winnerId)} se llevó el pozo de ${coinsText(c.pot)}.'
                : ''));
    final myBalance = c.online ? c.serverBalance : Wallet.instance.balance;
    final iEliminated = !iWon && !c.isDraw && (c.me?.eliminated ?? false);
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.72)),
        // AN12: confeti y moneda gigante detrás del contenido
        // (nunca tapan pozo, nombre ni botones).
        if (iWon && c.pot > 0) const Positioned.fill(child: ConfettiLayer()),
        if (iWon && c.pot > 0) const Center(child: CoinIcon(size: 170)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: titleStyle.copyWith(fontSize: 32)),
              const SizedBox(height: 4),
              // RONDA 2 (F8): textos secundarios del overlay final
              // a 14 px (eran 11,5/12/13,5): hay altura de sobra
              // en el overlay y nada se corta por ello.
              Text('¿QUÉ TAN BUENO ERES MINTIENDO?',
                  style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CachoColors.gold.withValues(alpha: 0.85))),
              const SizedBox(height: 10),
              CachoCup(
                width: 110,
                height: 128,
                leather: widget.leather,
                initials: _initialsOf(nameOf(c, c.winnerId ?? c.myId)),
              ),
              const SizedBox(height: 10),
              if (iWon && c.pot > 0) ...[
                const Text('TE LLEVASTE EL POZO',
                    style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70)),
                const SizedBox(height: 2),
                // AN11: rodillo de dígitos (final = pozo real).
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinningCoin(size: 30),
                    const SizedBox(width: 8),
                    DigitRoller(
                      target: c.pot,
                      prefix: '+',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFE9A8)),
                    ),
                  ],
                ),
                if (myBalance != null)
                  Text('Tu saldo: ${coinsText(myBalance)}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 6),
              ],
              if (sub.isNotEmpty)
                Text(sub, style: const TextStyle(fontSize: 14)),
              if (_matchLevelUpResult != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1712),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_matchLevelUpResult!['leveledUp'] == true)
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                      width: 1.2,
                    ),
                    boxShadow: (_matchLevelUpResult!['leveledUp'] == true)
                        ? const [
                            BoxShadow(
                              color: Color(0x66FFD700),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StarLevelBadge(
                            level: _matchLevelUpResult!['newLevel'] as int,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${_matchLevelUpResult!['xpGained']} XP',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                      if (_matchLevelUpResult!['leveledUp'] == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          '¡SUBISTE AL NIVEL ${_matchLevelUpResult!['newLevel']}!',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Color(0xFFFFD700),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Recompensas: +${_matchLevelUpResult!['rewardCash']} Billetes y +${_matchLevelUpResult!['rewardCoins']} Monedas',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Color(0xFF34C759),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              BronzeButton(label: 'VOLVER AL INICIO', onPressed: _exit),
              // B4 (sentencia v2.0): revancha SOLO en local, en un
              // toque: misma mesa, bots, dificultad, apuesta y mesa.
              if (!c.online && !c.guided) ...[
                const SizedBox(height: 12),
                BronzeButton(
                  label: 'OTRA VEZ',
                  icon: Icons.replay,
                  onPressed: () {
                    final next = c.rematchLocal();
                    c.stopLocal();
                    next.startLocal();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                            controller: next, leather: widget.leather),
                      ),
                    );
                  },
                ),
              ],
              // AN18: fichas que se retiran (solo si yo quedé
              // eliminado; la eliminación en vivo no anima la mesa).
              if (iEliminated) ...[
                const SizedBox(height: 14),
                const SizedBox(height: 28, child: WithdrawingChips()),
              ],
            ],
          ),
        ),
        if (iWon && c.pot > 0) const Positioned.fill(child: CoinRain()),
      ],
    );
  }

  /// Convierte SeatGeometry (de la nueva arquitectura) a SketchSeat
  /// (del sistema antiguo) para mantener compatibilidad con _sketchRivalSeat.
  SketchSeat _seatGeometryToSketchSeat(SeatGeometry seat) {
    // Crear rects de SketchRect basados en las coordenadas de SeatGeometry
    // Offset de barTop (56) para convertir a coordenadas relativas a pantalla
    final barTop = 56.0;
    
    final avatar = SketchRect(
      'avatar',
      seat.avatarCenter.dx - seat.avatarSize.width / 2,
      seat.avatarCenter.dy - seat.avatarSize.height / 2 + barTop,
      seat.avatarSize.width,
      seat.avatarSize.height,
    );
    
    final cup = SketchRect(
      'cup',
      seat.cupCenter.dx - seat.cupSize.width / 2,
      seat.cupCenter.dy - seat.cupSize.height / 2 + barTop,
      seat.cupSize.width,
      seat.cupSize.height,
    );
    
    final plate = SketchRect(
      'plate',
      seat.plateCenter.dx - seat.plateSize.width / 2,
      seat.plateCenter.dy - seat.plateSize.height / 2 + barTop,
      seat.plateSize.width,
      seat.plateSize.height,
    );
    
    return SketchSeat(
      seat.angleDeg,
      avatar,
      plate,
      cup,
      singleLinePlate: seat.singleLinePlate,
    );
  }
}
