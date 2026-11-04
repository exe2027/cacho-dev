import 'dart:math';
import 'package:flutter/material.dart';

/// Badge de Estrella de Nivel que se superpone en la esquina inferior derecha
/// del avatar del jugador mostrando dinámicamente su número de Nivel actual.
class StarLevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const StarLevelBadge({
    super.key,
    required this.level,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFFDF00), // Oro brillante
            Color(0xFFD4AF37), // Oro metálico
            Color(0xFF8A6508), // Sombra bronce
          ],
          stops: [0.3, 0.7, 1.0],
        ),
        border: Border.all(
          color: Colors.white,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
          BoxShadow(
            color: Color(0x66FFD700),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size * 0.88, size * 0.88),
            painter: _StarPainter(color: const Color(0x66FFFFFF)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$level',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: size * 0.58,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B1104),
                shadows: const [
                  Shadow(color: Colors.white70, blurRadius: 1, offset: Offset(0, 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerR = size.width / 2;
    final double innerR = outerR * 0.5;

    for (int i = 0; i < 5; i++) {
      final double outerAngle = -pi / 2 + (i * 2 * pi / 5);
      final double innerAngle = outerAngle + (pi / 5);

      final double x1 = cx + outerR * cos(outerAngle);
      final double y1 = cy + outerR * sin(outerAngle);
      final double x2 = cx + innerR * cos(innerAngle);
      final double y2 = cy + innerR * sin(innerAngle);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => oldDelegate.color != color;
}

