import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blobatar/flutter.dart' as blobatar;

import '../../models/room_config.dart';
import '../../models/bot_profile_model.dart';
import '../../models/user_model.dart';
import '../../models/avatar_frame_model.dart';
import '../../services/bot_matchmaking_service.dart';
import '../../services/user_service.dart';
import '../../state/audio.dart';
import '../../state/wallet.dart';
import '../coin_widgets.dart';
import 'animated_skin_effects.dart';
import 'star_level_badge.dart';

/// Modal y overlay de emparejamiento interactivo inspirado en el matchmaking de 8 Ball Pool.
/// - Simula la búsqueda en vivo con una ruleta a alta velocidad en los 5 slots.
/// - Congela los 5 slots de manera secuencial (stagger delay).
/// - Duración total: 3 a 4 segundos, seguido de 500ms de confirmación antes de entrar a la sala.
class MatchmakingOverlay extends StatefulWidget {
  final RoomConfig roomConfig;
  final int stake;
  final ValueChanged<List<BotProfile>> onMatched;
  final VoidCallback? onCancel;

  const MatchmakingOverlay({
    super.key,
    required this.roomConfig,
    required this.stake,
    required this.onMatched,
    this.onCancel,
  });

  /// Muestra el modal de Matchmaking a pantalla completa bloqueando interacciones.
  static Future<void> show({
    required BuildContext context,
    required RoomConfig roomConfig,
    required int stake,
    required ValueChanged<List<BotProfile>> onMatched,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => MatchmakingOverlay(
        roomConfig: roomConfig,
        stake: stake,
        onMatched: (opponents) {
          Navigator.of(ctx, rootNavigator: true).pop();
          onMatched(opponents);
        },
        onCancel: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          onCancel?.call();
        },
      ),
    );
  }

  @override
  State<MatchmakingOverlay> createState() => _MatchmakingOverlayState();
}

class _MatchmakingOverlayState extends State<MatchmakingOverlay>
    with TickerProviderStateMixin {
  late final List<BotProfile> _finalBots;
  late final UserModel _currentUser;

  // Estado de bloqueo de cada uno de los 5 slots (false = ruleta activa, true = congelado)
  final List<bool> _isLocked = [false, false, false, false, false];

  // Nombres y niveles temporales que ciclan a alta velocidad durante la ruleta
  final List<String> _currentSpinningNames = List.filled(5, '...');
  final List<int> _currentSpinningLevels = List.filled(5, 1);

  Timer? _rouletteTimer;
  final List<Timer> _staggerTimers = [];
  Timer? _finishTimer;
  final Random _rng = Random();

  bool _allLocked = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  // Controladores de animación de impacto para cada slot al fijarse
  late final List<AnimationController> _slotLockCtrls;

  @override
  void initState() {
    super.initState();
    _currentUser = UserService.instance.user;

    // Generar los 5 perfiles definitivos que se revelarán
    _finalBots = BotMatchmakingService.generateOpponents(
      count: 5,
      roomStake: widget.stake,
      localPlayerName: _currentUser.name,
    );

    // Animación de pulso general del título
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Animación individual de rebote al bloquear cada slot
    _slotLockCtrls = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );

    _startRoulette();
  }

  void _startRoulette() {
    final candidateNames = [
      ...BotMatchmakingService.leetGamerTags,
      ...BotMatchmakingService.wordNumberTags,
      ...BotMatchmakingService.prefixSuffixTags,
    ];

    // 1. Timer de ruleta a alta velocidad (cambia nombres y caras cada 65ms)
    _rouletteTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < 5; i++) {
          if (!_isLocked[i]) {
            _currentSpinningNames[i] =
                candidateNames[_rng.nextInt(candidateNames.length)];
            _currentSpinningLevels[i] = 2 + _rng.nextInt(40);
          }
        }
      });
    });

    // 2. Bloqueo secuencial con stagger delay (3 a 4 segundos en total)
    // Slot 0: 750ms
    // Slot 1: 1350ms
    // Slot 2: 1950ms
    // Slot 3: 2550ms
    // Slot 4: 3150ms
    const staggerIntervalMs = 600;
    const startDelayMs = 750;

    for (int i = 0; i < 5; i++) {
      final delay = startDelayMs + (i * staggerIntervalMs);
      _staggerTimers.add(
        Timer(Duration(milliseconds: delay), () {
          if (!mounted) return;
          _lockSlot(i);
        }),
      );
    }
  }

  void _lockSlot(int index) {
    if (_isLocked[index]) return;

    setState(() {
      _isLocked[index] = true;
      _currentSpinningNames[index] = _finalBots[index].username;
      _currentSpinningLevels[index] = _finalBots[index].level;
    });

    // Feedback háptico y sonido de bloqueo
    HapticFeedback.lightImpact();
    try {
      AudioService.instance.chips();
    } catch (_) {}

    _slotLockCtrls[index].forward(from: 0.0);

    // Verificar si todos quedaron bloqueados
    if (_isLocked.every((locked) => locked)) {
      _onAllOpponentsLocked();
    }
  }

  void _onAllOpponentsLocked() {
    _rouletteTimer?.cancel();
    setState(() {
      _allLocked = true;
    });

    // Vibración de éxito y sonido de confirmación
    HapticFeedback.mediumImpact();
    try {
      AudioService.instance.turnAlert();
    } catch (_) {}

    // Transición final tras 500ms de feedback visual
    _finishTimer = Timer(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      widget.onMatched(_finalBots);
    });
  }

  @override
  void dispose() {
    _rouletteTimer?.cancel();
    _finishTimer?.cancel();
    for (final t in _staggerTimers) {
      t.cancel();
    }
    _staggerTimers.clear();
    _pulseCtrl.dispose();
    for (final ctrl in _slotLockCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.roomConfig;
    final totalPot = widget.stake * 6; // 6 jugadores en la mesa

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 760,
          constraints: const BoxConstraints(maxHeight: 460),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF090E17).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _allLocked
                  ? const Color(0xFF35D461)
                  : room.accentColor.withValues(alpha: 0.65),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _allLocked
                    ? const Color(0xFF35D461).withValues(alpha: 0.35)
                    : room.accentColor.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.86),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Fondo con textura de mesa y sutil gradiente
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          room.primaryColor.withValues(alpha: 0.35),
                          const Color(0xFF05080E).withValues(alpha: 0.98),
                        ],
                      ),
                    ),
                  ),
                ),

                // Contenido principal
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. ENCABEZADO: Título, Sala y Pozo
                      _buildHeader(room, totalPot),

                      const SizedBox(height: 10),

                      // 2. TABLERO DE MATCHMAKING: TÚ vs 5 SLOTS
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Tarjeta del Jugador Local ("TÚ")
                            _buildLocalPlayerCard(room),

                            // Insignia VS Central
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: _buildVsBadge(room),
                            ),

                            // Fila de los 5 Slots de Contrincantes
                            Expanded(
                              child: _buildOpponentsGrid(room),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 3. PIE DE PÁGINA: Barra de progreso y botón cancelar
                      _buildFooter(room),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RoomConfig room, int totalPot) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Etiqueta de la Sala
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: room.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: room.accentColor.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.casino, size: 14, color: room.accentColor),
                  const SizedBox(width: 5),
                  Text(
                    room.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: room.accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Pozo Estimado
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 14),
                const SizedBox(width: 5),
                Text(
                  'POZO: ${coinsText(totalPot)}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Título dinámico con animación de pulso
        ScaleTransition(
          scale: _pulseScale,
          child: Text(
            _allLocked ? '¡OPONENTES ENCONTRADOS!' : 'BUSCANDO OPONENTES...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _allLocked ? const Color(0xFF35D461) : Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: _allLocked
                      ? const Color(0xFF35D461).withValues(alpha: 0.8)
                      : room.accentColor.withValues(alpha: 0.6),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalPlayerCard(RoomConfig room) {
    final frame = AvatarFrameModel.getById(_currentUser.equippedFrameId);
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: room.accentColor.withValues(alpha: 0.7),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: room.accentColor.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar con marco equipado y StarLevelBadge
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Renderizado del marco equipado si tiene
                if (frame.effectType != 'none')
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AnimatedFramePainter(
                        frame: frame,
                        animationValue: _pulseCtrl.value,
                      ),
                    ),
                  ),
                // Avatar principal
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: room.accentColor, width: 2.0),
                  ),
                  child: ClipOval(
                    child: blobatar.Blobatar(
                      name: _currentUser.name,
                      size: 50,
                      options: const blobatar.BlobatarOptions(
                        background: blobatar.Backdrop.circle,
                        expression: blobatar.happy,
                      ),
                    ),
                  ),
                ),
                // Star Level Badge
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: StarLevelBadge(level: _currentUser.level, size: 18),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Nombre de usuario
          Text(
            _currentUser.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Badge "TÚ (LISTO)"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF4CAF50), width: 1.0),
            ),
            child: const Text(
              'TÚ · LISTO',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE8F5E9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsBadge(RoomConfig room) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE5A93C), Color(0xFF8B5A14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
              BoxShadow(
                color: const Color(0xFFE5A93C).withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentsGrid(RoomConfig room) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildOpponentSlot(index, room),
          ),
        );
      }),
    );
  }

  Widget _buildOpponentSlot(int index, RoomConfig room) {
    final locked = _isLocked[index];
    final bot = _finalBots[index];
    final displayName = locked ? bot.username : _currentSpinningNames[index];
    final displayLevel = locked ? bot.level : _currentSpinningLevels[index];
    final lockAnim = _slotLockCtrls[index];

    return AnimatedBuilder(
      animation: lockAnim,
      builder: (context, child) {
        // Efecto de impacto y rebote al bloquearse: 1.0 -> 1.18 -> 1.0
        final bounceScale = lockAnim.isAnimating
            ? (1.0 + sin(lockAnim.value * pi) * 0.18)
            : 1.0;

        return Transform.scale(
          scale: bounceScale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: locked
                  ? const Color(0xFF131B2A)
                  : const Color(0xFF0C121D).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: locked
                    ? const Color(0xFF35D461)
                    : room.accentColor.withValues(alpha: 0.35),
                width: locked ? 1.8 : 1.0,
              ),
              boxShadow: locked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF35D461).withValues(alpha: 0.28),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar con ruleta o bloqueado
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Marco si el bot tiene marco equipado y ya está congelado
                      if (locked && bot.frame.effectType != 'none')
                        Positioned.fill(
                          child: CustomPaint(
                            painter: AnimatedFramePainter(
                              frame: bot.frame,
                              animationValue: _pulseCtrl.value,
                            ),
                          ),
                        ),

                      // Avatar Blobatar (rota a alta velocidad si no está bloqueado)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: locked
                                ? const Color(0xFF35D461)
                                : Colors.white24,
                            width: locked ? 2.0 : 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: blobatar.Blobatar(
                            name: displayName,
                            size: 44,
                            options: blobatar.BlobatarOptions(
                              background: blobatar.Backdrop.circle,
                              expression: locked
                                  ? blobatar.thinking
                                  : blobatar.happy,
                            ),
                          ),
                        ),
                      ),

                      // Badge de Nivel
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: StarLevelBadge(
                          level: displayLevel,
                          size: 16,
                        ),
                      ),

                      // Overlay giratorio de ruleta si aún está buscando
                      if (!locked)
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              room.accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 7),

                // Gamertag
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: locked ? Colors.white : Colors.white60,
                  ),
                ),

                const SizedBox(height: 4),

                // Chip de Estado: BUSCANDO... vs LISTO
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: locked
                        ? const Color(0xFF14532D)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: locked
                          ? const Color(0xFF35D461)
                          : Colors.white12,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    locked ? 'LISTO' : 'BUSCANDO...',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: locked
                          ? const Color(0xFF7DFF9A)
                          : Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(RoomConfig room) {
    final lockedCount = _isLocked.where((l) => l).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Indicador de jugadores encontrados (X / 6)
        Text(
          'Jugadores encontrados: ${lockedCount + 1}/6',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),

        // Botón Cancelar (solo activo mientras no estén todos encontrados)
        if (!_allLocked && widget.onCancel != null)
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.50),
              ),
            ),
          ),
      ],
    );
  }
}
