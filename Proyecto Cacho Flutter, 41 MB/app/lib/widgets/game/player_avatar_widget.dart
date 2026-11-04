import 'package:flutter/material.dart';
import 'package:blobatar/flutter.dart' as blobatar;
import '../../models/avatar_frame_model.dart';
import 'animated_skin_effects.dart';
import 'star_level_badge.dart';

/// Widget reutilizable para mostrar el avatar de un jugador con su marco cosmético (AvatarFrame)
/// y el StarLevelBadge superpuesto en la esquina inferior derecha.
class PlayerAvatarWidget extends StatefulWidget {
  final String name;
  final double size;
  final int level;
  final AvatarFrameModel frame;
  final bool isTurn;
  final bool isEliminated;
  final Color? accentColor;
  final VoidCallback? onTap;

  const PlayerAvatarWidget({
    super.key,
    required this.name,
    this.size = 40.0,
    this.level = 1,
    this.frame = AvatarFrameModel.none,
    this.isTurn = false,
    this.isEliminated = false,
    this.accentColor,
    this.onTap,
  });

  @override
  State<PlayerAvatarWidget> createState() => _PlayerAvatarWidgetState();
}

class _PlayerAvatarWidgetState extends State<PlayerAvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frame;
    final accent = widget.accentColor ?? const Color(0xFFD4AF37);
    final size = widget.size;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size + 10,
        height: size + 10,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Marco animado con efecto de alto impacto
            AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                return SizedBox(
                  width: size + 14,
                  height: size + 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Renderizado de aura/fuego/neón/oro con partículas vivas
                      if (frame.effectType != 'none')
                        Positioned.fill(
                          child: CustomPaint(
                            painter: AnimatedFramePainter(
                              frame: frame,
                              animationValue: _animCtrl.value,
                            ),
                          ),
                        ),
                      // Contenedor principal del avatar
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: frame.effectType == 'none'
                                ? (widget.isTurn ? accent : Colors.white30)
                                : Colors.transparent,
                            width: widget.isTurn ? 2.5 : 1.5,
                          ),
                          boxShadow: widget.isTurn
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: ClipOval(
                          child: blobatar.Blobatar(
                            name: widget.name,
                            size: size,
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
                  ),
                );
              },
            ),

            // Badge de Estrella de Nivel (Star Level Badge) superpuesto en la esquina inferior derecha
            Positioned(
              right: -3,
              bottom: -3,
              child: StarLevelBadge(
                level: widget.level,
                size: (size * 0.44).clamp(16.0, 22.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

