import 'package:blobatar/flutter.dart' as blobatar;
import '../panels.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/room_config.dart';
import '../../theme.dart';
import '../dice_and_cup.dart';

/// Coordenadas porcentuales relativas para los 6 asientos montados en el carril de la mesa:
/// - Slot 0: Jugador Principal (Abajo Centro - 50% X, 80% Y) -> Vaso ARRIBA del avatar
/// - Slot 1: Bot 1 (Abajo Izquierda - 19% X, 67% Y)         -> Vaso ARRIBA del avatar
/// - Slot 2: Bot 2 (Arriba Izquierda - 19% X, 27% Y)        -> Vaso ABAJO del avatar
/// - Slot 3: Bot 3 (Arriba Centro - 50% X, 17% Y)          -> Vaso ABAJO del avatar
/// - Slot 4: Bot 4 (Arriba Derecha - 81% X, 27% Y)         -> Vaso ABAJO del avatar
/// - Slot 5: Bot 5 (Abajo Derecha - 81% X, 67% Y)          -> Vaso ARRIBA del avatar
class SlotCoordinate {
  final double x;
  final double y;
  final bool isBottomHalf;

  const SlotCoordinate({
    required this.x,
    required this.y,
    required this.isBottomHalf,
  });
}

const List<SlotCoordinate> kTableSlotCoordinates = [
  SlotCoordinate(x: 0.50, y: 0.80, isBottomHalf: true),  // Slot 0: Local
  SlotCoordinate(x: 0.19, y: 0.67, isBottomHalf: true),  // Slot 1: Bot 1
  SlotCoordinate(x: 0.19, y: 0.27, isBottomHalf: false), // Slot 2: Bot 2
  SlotCoordinate(x: 0.50, y: 0.17, isBottomHalf: false), // Slot 3: Bot Don Chalo
  SlotCoordinate(x: 0.81, y: 0.27, isBottomHalf: false), // Slot 4: Bot 4
  SlotCoordinate(x: 0.81, y: 0.67, isBottomHalf: true),  // Slot 5: Bot 5
];

/// Widget integral animado para representar un asiento de jugador estilo Monopoly Poker.
///
/// Animaciones integradas:
/// - Shake del vaso cuando cambia `lastAction` (bot hizo su jugada)
/// - Pulse/glow del avatar cuando `isTurn` se activa
/// - SlideIn animado de la píldora de acción
/// - Entrada escalonada con PopIn sutil
class PlayerSlotWidget extends StatefulWidget {
  final String name;
  final int diceCount;
  final int coins;
  final bool isLocalUser;
  final bool isTurn;
  final bool isEliminated;
  final double? turnProgress; // 0.0 a 1.0
  final List<int> dice;
  final bool isCupOpen;
  final bool isRevealed;
  final String? lastAction;
  final RoomConfig roomConfig;
  final int slotIndex; // 0 a 5
  final VoidCallback? onTapCup;
  final String? activeEmote;

  const PlayerSlotWidget({
    super.key,
    required this.name,
    required this.diceCount,
    this.coins = 0,
    required this.isLocalUser,
    required this.isTurn,
    this.isEliminated = false,
    this.turnProgress,
    this.dice = const [],
    this.isCupOpen = false,
    this.isRevealed = false,
    this.lastAction,
    required this.roomConfig,
    required this.slotIndex,
    this.onTapCup,
    this.activeEmote,
  });

  @override
  State<PlayerSlotWidget> createState() => _PlayerSlotWidgetState();
}

class _PlayerSlotWidgetState extends State<PlayerSlotWidget>
    with TickerProviderStateMixin {
  // Animación de shake del vaso cuando el bot hace una jugada
  late final AnimationController _cupShakeCtrl;
  late final Animation<double> _cupShakeAnim;

  // Animación de pulse/glow cuando es el turno
  late final AnimationController _turnPulseCtrl;

  // Animación de entrada de la píldora de acción
  late final AnimationController _pillCtrl;
  late final Animation<double> _pillScale;
  late final Animation<double> _pillOpacity;

  // Animación física de levantamiento/inclinación del vaso
  late final AnimationController _cupLiftCtrl;
  late final Animation<double> _cupLiftAnim;

  // Animación física de salida y rodadura de dados (Rolling Dice)
  late final AnimationController _diceRollCtrl;

  String? _prevAction;
  bool _prevIsTurn = false;
  bool _prevShowDice = false;

  @override
  void initState() {
    super.initState();

    // Cup shake: 500ms, oscilación sinusoidal amortiguada
    _cupShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cupShakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cupShakeCtrl, curve: Curves.easeOut),
    );

    // Turn pulse: loop infinito suave
    _turnPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isTurn) _turnPulseCtrl.repeat(reverse: true);

    // Pill entrance: bounce in
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pillScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pillCtrl, curve: Curves.elasticOut),
    );
    _pillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pillCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    if (widget.lastAction != null) _pillCtrl.value = 1.0;

    // Cup lift & tilt: elevación suave con rebote elástico (320ms)
    _cupLiftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cupLiftAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cupLiftCtrl, curve: Curves.easeOutBack),
    );

    // Dice roll: rodadura física y caída con rebote elástico (600ms)
    _diceRollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final bool initialShowDice = (widget.isLocalUser && widget.isCupOpen) || widget.isRevealed;
    if (initialShowDice) {
      _cupLiftCtrl.value = 1.0;
      _diceRollCtrl.value = 1.0;
    }

    _prevAction = widget.lastAction;
    _prevIsTurn = widget.isTurn;
    _prevShowDice = initialShowDice;
  }

  @override
  void didUpdateWidget(covariant PlayerSlotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Cuando cambia la acción → shake del vaso + animación de píldora
    if (widget.lastAction != _prevAction && widget.lastAction != null) {
      _cupShakeCtrl.forward(from: 0);
      _pillCtrl.forward(from: 0);
    } else if (widget.lastAction == null && _prevAction != null) {
      _pillCtrl.reverse();
    }
    _prevAction = widget.lastAction;

    // Cuando cambia el turno → iniciar/detener pulse
    if (widget.isTurn && !_prevIsTurn) {
      _turnPulseCtrl.repeat(reverse: true);
    } else if (!widget.isTurn && _prevIsTurn) {
      _turnPulseCtrl.stop();
      _turnPulseCtrl.value = 0;
    }
    _prevIsTurn = widget.isTurn;

    // Cuando se abren o revelan los dados → animar elevación de vaso y rodadura de dados
    final bool showDice = (widget.isLocalUser && widget.isCupOpen) || widget.isRevealed;
    if (showDice && !_prevShowDice) {
      _cupLiftCtrl.forward(from: 0.0);
      _diceRollCtrl.forward(from: 0.0);
    } else if (!showDice && _prevShowDice) {
      _cupLiftCtrl.reverse();
      _diceRollCtrl.reset();
    }
    _prevShowDice = showDice;
  }

  @override
  void dispose() {
    _cupShakeCtrl.dispose();
    _turnPulseCtrl.dispose();
    _pillCtrl.dispose();
    _cupLiftCtrl.dispose();
    _diceRollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEliminated) {
      return _buildEliminatedSlot();
    }

    final bool isLeft = widget.slotIndex == 1 || widget.slotIndex == 2;
    final bool isRight = widget.slotIndex == 4 || widget.slotIndex == 5;
    final bool isTop = widget.slotIndex == 3;
    
    final avatarAndName = _buildAvatarAndName();
    // Vaso con animación física compuesta (inclinación angular + vibración en X e Y)
    final cupAndDice = AnimatedBuilder(
      animation: Listenable.merge([_cupShakeAnim, _cupLiftAnim]),
      builder: (context, child) {
        final shakeVal = _cupShakeAnim.value;
        final decay = 1.0 - shakeVal;
        final angle = math.sin(shakeVal * math.pi * 8) * 0.22 * decay;
        final dx = math.sin(shakeVal * math.pi * 8) * 5.0 * decay;
        final dy = -math.sin(shakeVal * math.pi * 4).abs() * 4.0 * decay;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: angle,
            child: child,
          ),
        );
      },
      child: _buildCupAndDice(),
    );

    // Layout según cuadrante para que los vasos queden SIEMPRE dentro del paño de la mesa
    Widget body;
    if (isLeft) {
      // Lateral Izquierdo: Avatar en el riel exterior izquierdo, vaso hacia la DERECHA (dentro del paño verde)
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatarAndName,
          const SizedBox(width: 14),
          cupAndDice,
        ],
      );
    } else if (isRight) {
      // Lateral Derecho: Vaso a la IZQUIERDA (dentro del paño verde), avatar en el riel exterior derecho
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cupAndDice,
          const SizedBox(width: 14),
          avatarAndName,
        ],
      );
    } else if (isTop) {
      // Arriba Centro (Don Chalo): Avatar en riel superior, vaso hacia ABAJO (dentro del paño verde)
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatarAndName,
          const SizedBox(height: 12),
          cupAndDice,
        ],
      );
    } else {
      // Abajo Centro (Jugador Local): Vaso hacia ARRIBA (dentro del paño verde), avatar en riel inferior
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cupAndDice,
          const SizedBox(height: 6),
          avatarAndName,
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        body,

        // Píldora flotante animada de última jugada/acción (ej: "7 Trenes", "Calzo", "Paso")
        if (widget.lastAction != null && widget.lastAction!.isNotEmpty)
          Positioned(
            top: isTop ? null : -26,
            bottom: isTop ? -26 : null,
            child: AnimatedBuilder(
              animation: _pillCtrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _pillOpacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _pillScale.value.clamp(0.0, 1.2),
                    child: child,
                  ),
                );
              },
              child: _buildActionPill(widget.lastAction!),
            ),
          ),
      ],
    );
  }

  /// Pod integrado del jugador: Avatar circular montado sobre placa con nombre y saldo.
  Widget _buildAvatarAndName() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(height: 1),
            _buildNameAndChips(),
          ],
        ),
        if (widget.activeEmote != null && widget.activeEmote!.isNotEmpty)
          Positioned(
            bottom: 58,
            child: FloatingEmote(
              key: ValueKey(widget.activeEmote),
              glyph: widget.activeEmote!,
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    final avatarAsset = _resolveBotAvatar(widget.name, isLocalUser: widget.isLocalUser);

    return AnimatedBuilder(
      animation: _turnPulseCtrl,
      builder: (context, child) {
        final pulse = widget.isTurn ? _turnPulseCtrl.value : 0.0;
        final glowSpread = widget.isTurn ? (3.0 + pulse * 5.0) : 0.0;
        final glowBlur = widget.isTurn ? (14.0 + pulse * 10.0) : 4.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Indicador de turno: Anillo temporizador con resplandor dorado
            if (widget.isTurn && widget.turnProgress != null)
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: widget.turnProgress,
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.roomConfig.accentColor),
                  backgroundColor: widget.roomConfig.accentColor.withValues(alpha: 0.2),
                ),
              ),

            // Contenedor principal del avatar con bisel metálico 2.5D y pulso de brillo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B140E),
                border: Border.all(
                  color: widget.isTurn ? widget.roomConfig.accentColor : Colors.white30,
                  width: widget.isTurn ? 3.0 : 1.5,
                ),
                boxShadow: widget.isTurn
                    ? [
                        BoxShadow(
                          color: widget.roomConfig.accentColor.withValues(alpha: 0.6 + pulse * 0.35),
                          blurRadius: glowBlur,
                          spreadRadius: glowSpread,
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipOval(
                child: blobatar.Blobatar(
                  name: widget.name,
                  size: 40,
                  options: blobatar.BlobatarOptions(
                    background: blobatar.Backdrop.circle,
                    expression: widget.isEliminated
                        ? blobatar.sad
                        : (widget.isTurn ? blobatar.thinking : blobatar.happy),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFallbackInitial() {
    final initial = widget.name.isNotEmpty ? widget.name.substring(0, 1).toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: widget.isTurn ? widget.roomConfig.accentColor : Colors.white,
        ),
      ),
    );
  }

  /// Placa/Badge del jugador con ancho suficiente (106px) para nombres sin truncado roto ("Bot Don Chalo", etc.).
  Widget _buildNameAndChips() {
    return Container(
      constraints: const BoxConstraints(minWidth: 54, maxWidth: 106),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF120E0A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isTurn ? widget.roomConfig.accentColor : Colors.white24,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              _cleanName(widget.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: widget.isTurn ? FontWeight.w800 : FontWeight.w600,
                color: widget.isTurn ? widget.roomConfig.accentColor : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (widget.coins > 0) ...[
            const SizedBox(width: 3),
            Text(
              _formatCoins(widget.coins),
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: CachoColors.gold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Renderizado del Cacho (vaso) y los dados con físicas de vuelco, rodadura y revelación.
  Widget _buildCupAndDice() {
    final bool showDice = (widget.isLocalUser && widget.isCupOpen) || widget.isRevealed;

    // Vaso con elevación e inclinación física interactiva
    Widget cupVisual = AnimatedBuilder(
      animation: _cupLiftAnim,
      builder: (context, child) {
        final lift = _cupLiftAnim.value;
        // Se eleva 14px y se inclina -18 grados al destapar
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translate(0.0, -14.0 * lift)
            ..rotateZ(-0.25 * lift),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTapCup,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Imagen del vaso de cuero con sombra de profundidad
              Image.asset(
                widget.roomConfig.cupAssetPath,
                width: 30,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.sports_bar,
                    size: 26,
                    color: widget.roomConfig.accentColor,
                  );
                },
              ),

              // Puntos indicadores de dados restantes cuando está cerrado
              if (!showDice && widget.diceCount > 0)
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.roomConfig.accentColor.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.diceCount.clamp(0, 5),
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.roomConfig.accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Cuando los dados están al descubierto (VER abierto o Showdown general):
    // Se presentan en Row horizontal (vaso a un lado y dados al otro) para que NUNCA se tapen entre sí
    if (showDice && widget.dice.isNotEmpty) {
      final diceVisual = AnimatedBuilder(
        animation: _diceRollCtrl,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.dice.length; i++) ...[
                Builder(
                  builder: (ctx) {
                    final start = (i * 0.12).clamp(0.0, 0.6);
                    final end = (start + 0.40).clamp(0.0, 1.0);
                    final curvedProgress = CurvedAnimation(
                      parent: _diceRollCtrl,
                      curve: Interval(start, end, curve: Curves.elasticOut),
                    ).value;

                    final scale = curvedProgress.clamp(0.0, 1.15);
                    final fallDy = -16.0 * (1.0 - curvedProgress).clamp(0.0, 1.0);
                    final rotAngle = (1.0 - curvedProgress) * (i.isEven ? 1.0 : -1.0) * math.pi;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Transform.translate(
                        offset: Offset(0, fallDy),
                        child: Transform.rotate(
                          angle: rotAngle,
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.roomConfig.accentColor.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: DiceFace(
                                value: widget.dice[i],
                                size: widget.isLocalUser ? 18 : 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      );

      final bool isRight = widget.slotIndex == 4 || widget.slotIndex == 5;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isRight
            ? [
                diceVisual,
                const SizedBox(width: 8),
                cupVisual,
              ]
            : [
                cupVisual,
                const SizedBox(width: 8),
                diceVisual,
              ],
      );
    }

    return cupVisual;
  }

  Widget _buildActionPill(String action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1209),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.roomConfig.accentColor,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: widget.roomConfig.accentColor,
        ),
      ),
    );
  }

  Widget _buildEliminatedSlot() {
    return Opacity(
      opacity: 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Colors.black45,
            child: Icon(Icons.close, color: Colors.white60, size: 18),
          ),
          const SizedBox(height: 2),
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.white60,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  static String _cleanName(String raw) {
    final word = raw.trim().split(RegExp(r'\s+')).first;
    return word.length > 12 ? word.substring(0, 12) : word;
  }

  static String? _resolveBotAvatar(String name, {bool isLocalUser = false}) {
    if (isLocalUser) {
      // Foto elegante por defecto para el usuario local
      return 'assets/images/bot_huaso.png';
    }
    final lower = name.toLowerCase();
    if (lower.contains('chalo')) return 'assets/images/bot_chalo.png';
    if (lower.contains('cuca')) return 'assets/images/bot_cuca.png';
    if (lower.contains('guaton') || lower.contains('guatón')) {
      return 'assets/images/bot_guaton.png';
    }
    if (lower.contains('huaso')) return 'assets/images/bot_huaso.png';
    if (lower.contains('pituca')) return 'assets/images/bot_pituca.png';

    // Asignación de fotos a bots aleatorios (pool de 5 retratos fotorrealistas de casino)
    const avatars = [
      'assets/images/bot_chalo.png',
      'assets/images/bot_cuca.png',
      'assets/images/bot_guaton.png',
      'assets/images/bot_huaso.png',
      'assets/images/bot_pituca.png',
    ];
    final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return avatars[hash % avatars.length];
  }

  static String _formatCoins(int amount) {
    if (amount >= 1000) {
      final k = amount / 1000.0;
      return k == k.roundToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$amount';
  }
}

/// Capa de coordinación de slots para compatibilidad.
class TableGameplaySlotsWidget extends StatelessWidget {
  final double tableWidth;
  final double tableHeight;
  final List<PlayerSlotData> slots;

  const TableGameplaySlotsWidget({
    super.key,
    required this.tableWidth,
    required this.tableHeight,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tableWidth,
      height: tableHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final slot in slots)
            if (slot.targetSlotIndex >= 0 && slot.targetSlotIndex < kTableSlotCoordinates.length)
              _buildPositionedSlot(slot.targetSlotIndex, slot),
        ],
      ),
    );
  }

  Widget _buildPositionedSlot(int index, PlayerSlotData data) {
    final coord = kTableSlotCoordinates[index];
    final posX = tableWidth * coord.x;
    final posY = tableHeight * coord.y;

    return Positioned(
      left: posX,
      top: posY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: PlayerSlotWidget(
          name: data.name,
          diceCount: data.diceCount,
          coins: data.coins,
          isLocalUser: data.isLocalUser,
          isTurn: data.isTurn,
          isEliminated: data.isEliminated,
          turnProgress: data.turnProgress,
          dice: data.dice,
          isCupOpen: data.isCupOpen,
          isRevealed: data.isRevealed,
          lastAction: data.lastAction,
          roomConfig: data.roomConfig,
          slotIndex: index,
          onTapCup: data.onTapCup,
        ),
      ),
    );
  }
}

/// Datos estructurados para alimentar cada asiento.
class PlayerSlotData {
  final int targetSlotIndex;
  final String id;
  final String name;
  final int diceCount;
  final int coins;
  final bool isLocalUser;
  final bool isTurn;
  final bool isEliminated;
  final double? turnProgress;
  final List<int> dice;
  final bool isCupOpen;
  final bool isRevealed;
  final String? lastAction;
  final RoomConfig roomConfig;
  final VoidCallback? onTapCup;
  final String? activeEmote;

  const PlayerSlotData({
    required this.targetSlotIndex,
    required this.id,
    required this.name,
    required this.diceCount,
    this.coins = 0,
    required this.isLocalUser,
    required this.isTurn,
    this.isEliminated = false,
    this.turnProgress,
    this.dice = const [],
    this.isCupOpen = false,
    this.isRevealed = false,
    this.lastAction,
    required this.roomConfig,
    this.onTapCup,
    this.activeEmote,
  });
}
