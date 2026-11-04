import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/room_config.dart';
import '../../state/wallet.dart';
import '../../texts.dart';
import '../coin_widgets.dart';
import '../dice_and_cup.dart';

/// Capa 3: HUD y Controles de Juego.
///
/// Debe colocarse sobre un [SafeArea] para proteger la visibilidad en dispositivos con notch.
/// - Top Bar: Monedas doradas, Cash $, Pozo central acumulado (POZO 1.500), audio y salida.
/// - Bottom Dock: Ficha de dados (1 al 6), botones CALZO, DUDO, PASO y botón interactivo VER / Agitar.
class GameHUDWidget extends StatelessWidget {
  final RoomConfig roomConfig;
  final int pot;
  final int goldCoins;
  final int cash;
  final bool isAudioMuted;
  final VoidCallback onToggleAudio;
  final VoidCallback onExit;
  final String? roomSubtitle; // ej: "SALA 1234 · R1 · 24 dados"
  final bool showPotInTopBar;

  // Estado del turno y apuestas
  final bool isMyTurn;
  final String? activeTurnName;
  final Bid? currentBid;
  final String? bidderName;
  final Bid? armedBid;
  final bool isBidLegal;
  final String? bidError;
  final ValueChanged<int> onSelectFace;
  final ValueChanged<int> onAdjustQuantity;
  final VoidCallback? onPlaceBid;

  // Botones de acción
  final bool canCalzo;
  final VoidCallback? onCalzo;
  final bool canDudo;
  final VoidCallback? onDudo;
  final bool canPaso;
  final VoidCallback? onPaso;

  // Vaso interactivo (VER / Agitar)
  final bool isCupOpen;
  final VoidCallback? onToggleCup;
  final VoidCallback? onOpenMusic;

  // Banners adicionales opcionales (Kamikaze, Paso)
  final Widget? bannerNotification;

  const GameHUDWidget({
    super.key,
    required this.roomConfig,
    required this.pot,
    this.goldCoins = 0,
    this.cash = 0,
    required this.isAudioMuted,
    required this.onToggleAudio,
    required this.onExit,
    this.roomSubtitle,
    this.showPotInTopBar = false,
    required this.isMyTurn,
    this.activeTurnName,
    this.currentBid,
    this.bidderName,
    this.armedBid,
    this.isBidLegal = false,
    this.bidError,
    required this.onSelectFace,
    required this.onAdjustQuantity,
    this.onPlaceBid,
    this.canCalzo = false,
    this.onCalzo,
    this.canDudo = false,
    this.onDudo,
    this.canPaso = false,
    this.onPaso,
    this.isCupOpen = false,
    this.onToggleCup,
    this.onOpenMusic,
    this.bannerNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. TOP BAR
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBar(context),
            if (bannerNotification != null) bannerNotification!,
          ],
        ),

        // 2. BOTTOM DOCK (Consola y acciones)
        _buildBottomDock(context),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 38.0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090E17).withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: roomConfig.accentColor.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Extremo Izquierdo: Salir + Audio
          _buildTopIconButton(
            icon: Icons.arrow_back_ios_new,
            label: 'SALIR',
            onTap: onExit,
          ),
          const SizedBox(width: 5),
          _buildTopIconButton(
            icon: isAudioMuted ? Icons.volume_off : Icons.volume_up,
            onTap: onToggleAudio,
          ),
          if (onOpenMusic != null) ...[
            const SizedBox(width: 5),
            _buildTopIconButton(
              icon: Icons.music_note,
              label: 'ROCOLA',
              onTap: onOpenMusic!,
            ),
          ],

          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: Colors.white12),
          const SizedBox(width: 8),

          // 2. Centro Continuo: Todo en UNA sola fila horizontal compacta
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Placa POZO
                  const CoinIcon(size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'POZO ${coinsText(pot)}',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: roomConfig.accentColor,
                      letterSpacing: 0.4,
                    ),
                  ),

                  // Separador
                  if (roomSubtitle != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '\u2022',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      roomSubtitle!,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],

                  // Indicador claro de Turno
                  const SizedBox(width: 8),
                  Text(
                    '\u2022',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isMyTurn ? const Color(0xFF13381B) : Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isMyTurn ? const Color(0xFF4CAF50) : roomConfig.accentColor.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMyTurn ? Icons.flash_on : Icons.hourglass_top_rounded,
                          size: 10,
                          color: isMyTurn ? const Color(0xFF4CAF50) : roomConfig.accentColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isMyTurn
                              ? '¡ES TU TURNO!'
                              : 'Turno: ${activeTurnName ?? "Esperando..."}',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isMyTurn ? const Color(0xFF69F0AE) : Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Apuesta Activa si existe
                  if (currentBid != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '\u2022',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${bidderName ?? "Jugada"}: ',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${currentBid!.quantity} \u00d7 ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: roomConfig.accentColor,
                      ),
                    ),
                    DiceFace(
                      value: currentBid!.face,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${facePlural(currentBid!.face)})',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: Colors.white12),
          const SizedBox(width: 8),

          // 3. Extremo Derecho: Monedas y Cash
          _buildCurrencyPill(
            icon: const CoinIcon(size: 13),
            amount: coinsText(goldCoins),
            color: roomConfig.accentColor,
          ),
          const SizedBox(width: 5),
          _buildCurrencyPill(
            icon: const Text(
              '\$',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4CAF50),
              ),
            ),
            amount: '\$$cash',
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1B2434).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCurrencyPill({
    required Widget icon,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF120A24).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1322).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTurn ? roomConfig.accentColor : Colors.white12,
          width: isMyTurn ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Botón interactivo VER / Agitar
          _buildVerAgitarButton(),

          // 2. Selector de dados (1 al 6) con Stepper de cantidad
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int face = 1; face <= 6; face++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: _buildDiceTile(face),
                ),
              const SizedBox(width: 6),
              _buildStepperBtn(
                icon: Icons.remove,
                onTap: (armedBid != null && armedBid!.quantity > 1)
                    ? () => onAdjustQuantity(armedBid!.quantity - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  armedBid != null ? '${armedBid!.quantity}' : '1',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: (armedBid != null && isBidLegal)
                        ? roomConfig.accentColor
                        : (armedBid != null ? Colors.redAccent : Colors.white38),
                  ),
                ),
              ),
              _buildStepperBtn(
                icon: Icons.add,
                onTap: armedBid != null
                    ? () => onAdjustQuantity(armedBid!.quantity + 1)
                    : null,
              ),
            ],
          ),

          // 3. Botones de Acción (CALZO, DUDO, PASO, APOSTAR)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                label: 'CALZO',
                color: const Color(0xFF2E7D32),
                enabled: canCalzo,
                onTap: onCalzo,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                label: 'DUDO',
                color: const Color(0xFFC62828),
                enabled: canDudo,
                onTap: onDudo,
              ),
              if (canPaso) ...[
                const SizedBox(width: 4),
                _buildActionButton(
                  label: 'PASO',
                  color: const Color(0xFF1565C0),
                  enabled: canPaso,
                  onTap: onPaso,
                ),
              ],
              const SizedBox(width: 4),
              _buildActionButton(
                label: 'APOSTAR',
                color: roomConfig.accentColor,
                textColor: Colors.black,
                enabled: armedBid != null && isBidLegal,
                onTap: (armedBid != null && isBidLegal) ? onPlaceBid : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerAgitarButton() {
    return Material(
      color: isCupOpen ? const Color(0xFF263238) : const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onToggleCup,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCupOpen ? Icons.visibility_off : Icons.visibility,
                size: 14,
                color: roomConfig.accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                isCupOpen ? 'OCULTAR' : 'VER / AGITAR',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: roomConfig.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiceTile(int face) {
    final bool isSelected = armedBid?.face == face;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelectFace(face);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? roomConfig.accentColor.withValues(alpha: 0.25)
              : Colors.black26,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? roomConfig.accentColor : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: DiceFace(
            value: face,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: enabled ? Colors.white12 : Colors.white.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: enabled ? color : color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled
            ? () {
                HapticFeedback.heavyImpact();
                onTap!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: enabled ? textColor : textColor.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

