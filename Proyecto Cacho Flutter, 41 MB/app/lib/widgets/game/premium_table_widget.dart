import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cacho_engine/cacho_engine.dart';
import '../../models/room_config.dart';
import '../../texts.dart';
import '../../theme.dart';
import '../dice_and_cup.dart';
import 'player_slot_widget.dart';

/// Coordenadas porcentuales para los 6 asientos sobre la mesa 2D Cenital:
/// - Slot 0: Jugador Principal (Abajo Centro - 50% X, 80% Y) -> Avatar en riel inferior, vaso hacia el paño
/// - Slot 1: Bot 1 (Abajo Izquierda - 18% X, 65% Y)        -> Avatar en riel izquierdo, vaso hacia el paño derecho
/// - Slot 2: Bot 2 (Arriba Izquierda - 18% X, 28% Y)       -> Avatar en riel izquierdo, vaso hacia el paño derecho
/// - Slot 3: Bot 3 (Arriba Centro - 50% X, 14% Y)          -> Avatar en riel superior, vaso hacia el paño inferior
/// - Slot 4: Bot 4 (Arriba Derecha - 82% X, 28% Y)         -> Avatar en riel derecho, vaso hacia el paño izquierdo
/// - Slot 5: Bot 5 (Abajo Derecha - 82% X, 65% Y)          -> Avatar en riel derecho, vaso hacia el paño izquierdo
class PremiumTableSlotCoordinate {
  final double x;
  final double y;
  final bool isBottomHalf;

  const PremiumTableSlotCoordinate({
    required this.x,
    required this.y,
    required this.isBottomHalf,
  });
}

const List<PremiumTableSlotCoordinate> kPremiumTableSlotCoordinates = [
  PremiumTableSlotCoordinate(x: 0.50, y: 0.77, isBottomHalf: true),  // Slot 0: Jugador Principal
  PremiumTableSlotCoordinate(x: 0.18, y: 0.65, isBottomHalf: true),  // Slot 1: Bot 1
  PremiumTableSlotCoordinate(x: 0.18, y: 0.28, isBottomHalf: false), // Slot 2: Bot 2
  PremiumTableSlotCoordinate(x: 0.50, y: 0.17, isBottomHalf: false), // Slot 3: Bot Don Chalo
  PremiumTableSlotCoordinate(x: 0.82, y: 0.28, isBottomHalf: false), // Slot 4: Bot 4
  PremiumTableSlotCoordinate(x: 0.82, y: 0.65, isBottomHalf: true),  // Slot 5: Bot 5
];

/// Widget Premium de Mesa 2D Cenital (Top-Down) estilo 8 Ball Pool / WSOP Poker.
///
/// - Logo del juego como marca de agua en el centro del paño.
/// - Apuesta activa: anuncio animado que aparece al centro, dura 4 segundos y
///   se desvanece automáticamente con fade-out suave.
class PremiumTableWidget extends StatefulWidget {
  final RoomConfig roomConfig;
  final List<PlayerSlotData> slots;
  final int pot;
  final Bid? currentBid;
  final String? lastBidderName;
  final Widget? overlayChild;

  const PremiumTableWidget({
    super.key,
    required this.roomConfig,
    required this.slots,
    this.pot = 0,
    this.currentBid,
    this.lastBidderName,
    this.overlayChild,
  });

  @override
  State<PremiumTableWidget> createState() => _PremiumTableWidgetState();
}

class _PremiumTableWidgetState extends State<PremiumTableWidget>
    with SingleTickerProviderStateMixin {
  /// Controlador único para toda la animación del chip (entrada + salida).
  late final AnimationController _bidAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  /// Entrada: escala elástica
  late final Animation<double> _bidScale = CurvedAnimation(
    parent: _bidAnim,
    curve: Curves.elasticOut,
    reverseCurve: Curves.easeInCubic,
  );

  /// Entrada + salida: opacidad
  late final Animation<double> _bidOpacity = CurvedAnimation(
    parent: _bidAnim,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeInCubic,
  );

  /// Timer que dispara el fade-out 4 segundos después de aparecer el chip.
  Timer? _dismissTimer;

  /// Última apuesta procesada (para detectar cambios).
  Bid? _prevBid;

  @override
  void initState() {
    super.initState();
    if (widget.currentBid != null) {
      _bidAnim.value = 1.0;
      _scheduleDismiss();
    }
  }

  @override
  void didUpdateWidget(PremiumTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newBid = widget.currentBid;
    if (newBid != _prevBid) {
      _prevBid = newBid;
      if (newBid != null) {
        // Nueva apuesta: cancelar timer anterior, animar entrada y programar salida
        _dismissTimer?.cancel();
        _bidAnim.forward(from: 0.0);
        _scheduleDismiss();
      } else {
        // Sin apuesta: fade-out inmediato
        _dismissTimer?.cancel();
        _bidAnim.reverse();
      }
    }
  }

  /// Programa el fade-out automático a los 4 segundos.
  void _scheduleDismiss() {
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _bidAnim.animateBack(
          0.0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _bidAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fondo fotográfico ambiental de la sala privada
        Positioned.fill(
          child: Image.asset(
            widget.roomConfig.roomBackgroundAssetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF070503)),
          ),
        ),

        // 2. Viñeta ambiental oscura para concentrar la iluminación sobre la mesa
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.15,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
        ),

        // 3. Lienzo Maestro (844 x 390): Mesa 2D y UI dinámica con área segura vertical
        Padding(
          padding: const EdgeInsets.only(top: 42.0, bottom: 64.0),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: 844,
                height: 390,
                child: AspectRatio(
                  aspectRatio: 844 / 390,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasW = constraints.maxWidth;
                      final canvasH = constraints.maxHeight;

                      final tableAsset = widget.roomConfig.tableAssetPath.isNotEmpty
                          ? widget.roomConfig.tableAssetPath
                          : 'assets/images/table_2d.png';

                      return Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          // 1. Asset 2D Realista de la Mesa (paño con riel, bisel y fieltro)
                          Center(
                            child: Image.asset(
                              tableAsset,
                              width: 680.0,
                              height: 376.0,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/table_2d.png',
                                width: 680.0,
                                height: 376.0,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // 2. Marca de agua: Logo "DUDO / CACHO" en el centro del paño
                          Center(
                            child: Opacity(
                              opacity: 0.11,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const DudoLogo(fontSize: 34),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'CACHO · EL DUDO CHILENO',
                                    style: TextStyle(
                                      fontFamily: CachoFonts.display,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 3. Anuncio de apuesta activa: aparece animado y desaparece a los 4s
                          Center(
                            child: AnimatedBuilder(
                              animation: _bidAnim,
                              builder: (context, _) {
                                if (_bidAnim.value == 0.0) {
                                  return const SizedBox.shrink();
                                }
                                return Opacity(
                                  opacity: _bidOpacity.value,
                                  child: Transform.scale(
                                    scale: _bidScale.value.clamp(0.0, 1.05),
                                    child: widget.currentBid != null
                                        ? _BidAnnouncementChip(
                                            bid: widget.currentBid!,
                                            bidderName: widget.lastBidderName,
                                            accentColor: widget.roomConfig.accentColor,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 4. Slots dinámicos de los 6 jugadores
                          for (final slot in widget.slots)
                            if (slot.targetSlotIndex >= 0 &&
                                slot.targetSlotIndex < kPremiumTableSlotCoordinates.length)
                              _buildMountedPlayerSlot(
                                canvasW,
                                canvasH,
                                slot.targetSlotIndex,
                                slot,
                              ),

                          // 5. Overlay flotante (resolución / chat)
                          if (widget.overlayChild != null) widget.overlayChild!,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Posicionamiento exacto de cada slot montado sobre el borde de la mesa 2D.
  Widget _buildMountedPlayerSlot(
    double width,
    double height,
    int index,
    PlayerSlotData data,
  ) {
    final coord = kPremiumTableSlotCoordinates[index];
    final posX = width * coord.x;
    final posY = height * coord.y;

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
          activeEmote: data.activeEmote,
          micOn: data.micOn,
          onToggleMic: data.onToggleMic,
        ),
      ),
    );
  }
}

/// Chip semi-transparente de la apuesta activa en el centro del paño.
/// Fondo translúcido para que la mesa se vea a través del anuncio.
class _BidAnnouncementChip extends StatelessWidget {
  final Bid bid;
  final String? bidderName;
  final Color accentColor;

  const _BidAnnouncementChip({
    required this.bid,
    required this.bidderName,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final name = bidderName ?? 'Jugada';
    final face = bid.face;
    final qty = bid.quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        // Fondo muy translúcido para que se vea la mesa detrás
        color: const Color(0xFF05080F).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre del apostador
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.70),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          // Fila principal: cantidad × dado (nombre de cara)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$qty',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '×',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              DiceFace(value: face, size: 28),
              const SizedBox(width: 8),
              Text(
                facePlural(face),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
