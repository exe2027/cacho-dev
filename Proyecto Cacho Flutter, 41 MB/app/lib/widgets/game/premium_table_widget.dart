import 'package:flutter/material.dart';
import 'package:cacho_engine/cacho_engine.dart';
import '../../models/room_config.dart';
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
/// Refactorizado: Utiliza el asset fotorrealista 2D de la mesa como base visual
/// y posiciona sobre ella de manera dinámica únicamente los 6 slots de jugadores
/// con sus vasos dentro del paño verde. El centro de la mesa se mantiene 100% limpio
/// sin textos ni información duplicada (la información vive en el TopBar).
class PremiumTableWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fondo fotográfico ambiental de la sala privada
        Positioned.fill(
          child: Image.asset(
            roomConfig.roomBackgroundAssetPath,
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

                    // Priorizamos el asset de mesa configurado para la sala, con fallback a table_2d.png
                    final tableAsset = roomConfig.tableAssetPath.isNotEmpty
                        ? roomConfig.tableAssetPath
                        : 'assets/images/table_2d.png';

                    return Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        // 1. Asset 2D Realista de la Mesa (Fondo del paño con riel, bisel y fieltro)
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

                        // 2. Slots dinámicos de los 6 jugadores (avatares en riel, vasos dentro del paño)
                        for (final slot in slots)
                          if (slot.targetSlotIndex >= 0 &&
                              slot.targetSlotIndex < kPremiumTableSlotCoordinates.length)
                            _buildMountedPlayerSlot(
                              canvasW,
                              canvasH,
                              slot.targetSlotIndex,
                              slot,
                            ),

                        // 3. Contenido overlay flotante (resolución / chat)
                        if (overlayChild != null) overlayChild!,
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
        ),
      ),
    );
  }
}
