import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/avatar_frame_model.dart';
import '../../models/cup_skin_model.dart';

/// Widget que envuelve la imagen del vaso con animaciones visuales impactantes y llamativas
class AnimatedCupVisual extends StatefulWidget {
  final CupSkinModel skin;
  final double width;
  final double height;
  final Widget? child;

  const AnimatedCupVisual({
    super.key,
    required this.skin,
    this.width = 34,
    this.height = 36,
    this.child,
  });

  @override
  State<AnimatedCupVisual> createState() => _AnimatedCupVisualState();
}

class _AnimatedCupVisualState extends State<AnimatedCupVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final w = widget.width;
    final h = widget.height;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;

        // EFECTO 1: VASO EN LLAMAS (FUEGO VIVO)
        if (skin.id == 'cup_fuego') {
          return SizedBox(
            width: w + 14,
            height: h + 16,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Resplandor ardiente pulsante de fondo
                Container(
                  width: w + 8,
                  height: h + 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3300).withValues(alpha: 0.65 + 0.3 * math.sin(t * 2 * math.pi)),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF9900).withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Llamas animadas detrás del vaso
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FireFlamesPainter(animationValue: t),
                  ),
                ),
                // Vaso centrado
                widget.child ??
                    Image.asset(
                      skin.assetPath,
                      width: w,
                      height: h,
                      fit: BoxFit.contain,
                    ),
                // Chispas ardientes flotando sobre el vaso
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FireSparksPainter(animationValue: t),
                  ),
                ),
              ],
            ),
          );
        }

        // EFECTO 2: VASO DORADO VIP (BRILLO ORO Y DESTELLOS)
        if (skin.id == 'cup_dorado') {
          return SizedBox(
            width: w + 12,
            height: h + 12,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Aura dorada majestuosa
                Container(
                  width: w + 6,
                  height: h + 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.55 + 0.3 * math.sin(t * 2 * math.pi)),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Vaso centrado con máscara de destello diagonal
                widget.child ??
                    Image.asset(
                      skin.assetPath,
                      width: w,
                      height: h,
                      fit: BoxFit.contain,
                    ),
                // Destellos y estrellas doradas orbitantes
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GoldSparklesPainter(animationValue: t),
                  ),
                ),
              ],
            ),
          );
        }

        // EFECTO 3: VASO DE ROBLE (AURA MÍSTICA CYAN/AZUL)
        if (skin.id == 'cup_roble') {
          final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
          return SizedBox(
            width: w + 8,
            height: h + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: w + 4,
                  height: h + 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(const Color(0xFF00E5FF), const Color(0xFF2979FF), pulse)!
                            .withValues(alpha: 0.55),
                        blurRadius: 10 + pulse * 6,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
                widget.child ??
                    Image.asset(
                      skin.assetPath,
                      width: w,
                      height: h,
                      fit: BoxFit.contain,
                    ),
              ],
            ),
          );
        }

        // VASO ESTÁNDAR (Clásico)
        return widget.child ??
            Image.asset(
              skin.assetPath,
              width: w,
              height: h,
              fit: BoxFit.contain,
            );
      },
    );
  }
}

/// Painter de llamas ardientes estilizadas en ascenso
class _FireFlamesPainter extends CustomPainter {
  final double animationValue;
  _FireFlamesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    final paintRed = Paint()
      ..color = const Color(0xCCFF2200)
      ..style = PaintingStyle.fill;
    final paintOrange = Paint()
      ..color = const Color(0xEEFF7700)
      ..style = PaintingStyle.fill;
    final paintYellow = Paint()
      ..color = const Color(0xFFFFDD00)
      ..style = PaintingStyle.fill;

    // 5 lenguas de fuego en la parte superior e inferior
    for (int i = 0; i < 5; i++) {
      final offsetX = cx - (w * 0.35) + (i * (w * 0.7) / 4);
      final phase = animationValue * 2 * math.pi + (i * 1.2);
      final flameH = 7.0 + 5.0 * math.sin(phase);

      // Lengua exterior naranja/roja
      final path = Path()
        ..moveTo(offsetX - 4, cy - h * 0.2)
        ..quadraticBezierTo(offsetX, cy - h * 0.45 - flameH, offsetX + 4, cy - h * 0.2)
        ..close();
      canvas.drawPath(path, paintRed);

      // Lengua media naranja
      final pathOrange = Path()
        ..moveTo(offsetX - 2.5, cy - h * 0.2)
        ..quadraticBezierTo(offsetX, cy - h * 0.42 - flameH * 0.8, offsetX + 2.5, cy - h * 0.2)
        ..close();
      canvas.drawPath(pathOrange, paintOrange);

      // Centro amarillo ardiente
      final pathYellow = Path()
        ..moveTo(offsetX - 1.2, cy - h * 0.2)
        ..quadraticBezierTo(offsetX, cy - h * 0.38 - flameH * 0.5, offsetX + 1.2, cy - h * 0.2)
        ..close();
      canvas.drawPath(pathYellow, paintYellow);
    }
  }

  @override
  bool shouldRepaint(covariant _FireFlamesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// Painter de chispas y partículas que se desprenden del fuego
class _FireSparksPainter extends CustomPainter {
  final double animationValue;
  _FireSparksPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final sparkPaint = Paint()..style = PaintingStyle.fill;

    // Generar 8 chispas orbitales ascendentes
    for (int i = 0; i < 8; i++) {
      final prog = (animationValue + (i / 8.0)) % 1.0;
      final angle = (i * math.pi / 4) + (animationValue * math.pi * 0.5);
      final radius = 12.0 + (prog * 14.0);
      final px = cx + radius * math.cos(angle);
      final py = cy - (prog * 20.0) + 4; // Flotan hacia arriba

      final opacity = (1.0 - prog).clamp(0.0, 1.0);
      sparkPaint.color = (i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFFFF5500))
          .withValues(alpha: opacity);

      canvas.drawCircle(Offset(px, py), 1.2 + (1.0 - prog), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireSparksPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// Painter de destellos y estrellas doradas relucientes
class _GoldSparklesPainter extends CustomPainter {
  final double animationValue;
  _GoldSparklesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 4 estrellas brillantes en las esquinas que giran y titilan
    for (int i = 0; i < 4; i++) {
      final baseAngle = (i * math.pi / 2) + (animationValue * 2 * math.pi);
      final r = size.width * 0.42;
      final px = cx + r * math.cos(baseAngle);
      final py = cy + r * math.sin(baseAngle);

      final pulse = (math.sin(animationValue * 4 * math.pi + i) + 1.0) / 2.0;
      final starSize = 2.5 + pulse * 2.5;

      _drawStar(canvas, Offset(px, py), starSize, const Color(0xFFFFF275));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldSparklesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// Painter para marcos de avatar de alto impacto visual
class AnimatedFramePainter extends CustomPainter {
  final AvatarFrameModel frame;
  final double animationValue;

  AnimatedFramePainter({
    required this.frame,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.effectType == 'none') return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5;

    // 1. AURA DE FUEGO (Llamas y sol ardiente alrededor del avatar)
    if (frame.effectType == 'fire') {
      final firePaint = Paint()..style = PaintingStyle.fill;

      // 14 lenguas de fuego vivas girando y danzando
      const int tongueCount = 14;
      for (int i = 0; i < tongueCount; i++) {
        final angle = (i * 2 * math.pi / tongueCount) + (animationValue * math.pi * 0.4);
        final pulse = math.sin(animationValue * 6 * math.pi + i * 1.5);
        final tongueLen = 4.0 + pulse * 4.0;

        final px = center.dx + (radius + tongueLen) * math.cos(angle);
        final py = center.dy + (radius + tongueLen) * math.sin(angle);

        firePaint.color = (i % 2 == 0 ? const Color(0xFFFF2200) : const Color(0xFFFF9900))
            .withValues(alpha: 0.85);
        canvas.drawCircle(Offset(px, py), 2.8 + pulse.abs() * 1.2, firePaint);
      }

      // Anillo de fuego exterior ardiente
      final ringPaint = Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFFF1100),
            Color(0xFFFF8800),
            Color(0xFFFFEE00),
            Color(0xFFFF3300),
            Color(0xFFFF1100),
          ],
          transform: GradientRotation(animationValue * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      canvas.drawCircle(center, radius, ringPaint);
      return;
    }

    // 2. NEÓN VIP (Luz láser cyberpunk giratoria con destellos)
    if (frame.effectType == 'neon') {
      final neonShader = SweepGradient(
        colors: const [
          Color(0xFF00F0FF),
          Color(0xFF7000FF),
          Color(0xFFFF0077),
          Color(0xFF00F0FF),
        ],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      // Glow exterior
      final glowPaint = Paint()
        ..shader = neonShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius, glowPaint);

      // Anillo láser nítido
      final strokePaint = Paint()
        ..shader = neonShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8;
      canvas.drawCircle(center, radius, strokePaint);

      // 4 marcas de pulso en cruz
      for (int i = 0; i < 4; i++) {
        final a = (i * math.pi / 2) + (animationValue * 2 * math.pi);
        final markX = center.dx + radius * math.cos(a);
        final markY = center.dy + radius * math.sin(a);
        canvas.drawCircle(
          Offset(markX, markY),
          2.5,
          Paint()..color = Colors.white,
        );
      }
      return;
    }

    // 3. MARCO DE ORO (Bisel dorado giratorio con destellos diamantes)
    if (frame.effectType == 'gold') {
      final goldShader = SweepGradient(
        colors: const [
          Color(0xFFFFE57F),
          Color(0xFFFFD700),
          Color(0xFFB8860B),
          Color(0xFFFFE57F),
        ],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      // Resplandor
      final glowPaint = Paint()
        ..shader = goldShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(center, radius, glowPaint);

      // Anillo metálico
      final strokePaint = Paint()
        ..shader = goldShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius, strokePaint);

      // 4 estrellas diamantadas orbitando
      for (int i = 0; i < 4; i++) {
        final a = (i * math.pi / 2) + (animationValue * math.pi);
        final px = center.dx + (radius + 2) * math.cos(a);
        final py = center.dy + (radius + 2) * math.sin(a);
        final pulse = (math.sin(animationValue * 4 * math.pi + i) + 1.0) / 2.0;

        _drawDiamond(canvas, Offset(px, py), 2.2 + pulse * 1.5, const Color(0xFFFFFFFF));
      }
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedFramePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue || oldDelegate.frame.id != frame.id;
}

