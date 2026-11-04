import 'package:flutter/material.dart';
import '../../models/room_config.dart';

/// Capa 1: Mesa 2D Cenital (Top-Down) simétrica montada sobre el fondo de la sala.
class TableBackgroundWidget extends StatelessWidget {
  final RoomConfig roomConfig;
  final Widget? child;

  const TableBackgroundWidget({
    super.key,
    required this.roomConfig,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF070503),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: 844,
            height: 390,
            child: AspectRatio(
              aspectRatio: 844 / 390,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  // 1. Fondo fotográfico ambientado de la Sala
                  Positioned.fill(
                    child: Image.asset(
                      roomConfig.roomBackgroundAssetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D0906)),
                    ),
                  ),

                  // 2. Viñeta ambiental oscura de sala
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.95,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Mesa 2D Cenital Master
                  Center(
                    child: Container(
                      width: 734,
                      height: 262,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.85),
                            blurRadius: 28,
                            spreadRadius: 6,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        roomConfig.tableAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 4. Marca de agua del logo DUDO en el centro del paño
                  Center(
                    child: Opacity(
                      opacity: 0.14,
                      child: Image.asset(
                        'assets/images/logo_emblem.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // 5. Contenido hijo (Gameplay Slots / fichas / dados)
                  if (child != null) child!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
