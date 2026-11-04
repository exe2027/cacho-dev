import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/avatar_frame_model.dart';
import '../../models/cup_skin_model.dart';

/// Widget que renderiza el vaso con formas físicas exclusivas y animaciones vivas
class AnimatedCupVisual extends StatefulWidget {
  final CupSkinModel skin;
  final double width;
  final double height;
  final Widget? child;

  const AnimatedCupVisual({
    super.key,
    required this.skin,
    this.width = 44,
    this.height = 48,
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
      duration: const Duration(milliseconds: 2400),
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

        // Renderizado según la forma física del vaso (CupShapeType)
        switch (skin.shapeType) {
          // 1. CHIFLE DE HUASO (Cuerno curvado de toro con virola de plata)
          case CupShapeType.chifle:
            return SizedBox(
              width: w + 12,
              height: h + 10,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w + 6,
                    height: h + 4,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCBD5E1).withValues(alpha: 0.35 + 0.2 * math.sin(t * 2 * math.pi)),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _ChiflePainter(animationValue: t),
                  ),
                ],
              ),
            );

          // 2. BARRIL DE TABERNA (Barril abombado con zunchos de hierro y runas)
          case CupShapeType.barrel:
            return SizedBox(
              width: w + 10,
              height: h + 8,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w + 4,
                    height: h + 4,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45 + 0.3 * math.sin(t * 2 * math.pi)),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _BarrelPainter(animationValue: t),
                  ),
                ],
              ),
            );

          // 3. CÁLIZ IMPERIAL 24K (Cáliz acampanado con gemas y pie torneado)
          case CupShapeType.goblet:
            return SizedBox(
              width: w + 14,
              height: h + 12,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w + 8,
                    height: h + 6,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6 + 0.35 * math.sin(t * 2 * math.pi)),
                          blurRadius: 16,
                          spreadRadius: 2.5,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _GobletPainter(animationValue: t),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GoldSparklesPainter(animationValue: t),
                    ),
                  ),
                ],
              ),
            );

          // 4. CALAVERA DEL INFRAMUNDO (Cráneo gótico con ojos de fuego ardiente)
          case CupShapeType.skull:
            return SizedBox(
              width: w + 16,
              height: h + 18,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w + 10,
                    height: h + 10,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2200).withValues(alpha: 0.7 + 0.3 * math.sin(t * 2 * math.pi)),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF8800).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FireFlamesPainter(animationValue: t),
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _SkullPainter(animationValue: t),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FireSparksPainter(animationValue: t),
                    ),
                  ),
                ],
              ),
            );

          // 5. HEXACACHO CYBERPUNK (Prisma hexagonal con circuitos de neón)
          case CupShapeType.cyberPrism:
            return SizedBox(
              width: w + 12,
              height: h + 10,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w + 6,
                    height: h + 6,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.6 + 0.3 * math.sin(t * 2 * math.pi)),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF0077).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _CyberPrismPainter(animationValue: t),
                  ),
                ],
              ),
            );

          // 6. CACHO GLACIAR ÁRTICO (Facetado en cristal de hielo de la Patagonia)
          case CupShapeType.crystalFrost:
            return SizedBox(
              width: w + 12,
              height: h + 10,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: w + 6,
                    height: h + 6,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF80D8FF).withValues(alpha: 0.55 + 0.3 * math.sin(t * 2 * math.pi)),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _GlacierPainter(animationValue: t),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FrostSnowflakesPainter(animationValue: t),
                    ),
                  ),
                ],
              ),
            );

          // 7. CACHO DE CUERO CLÁSICO (Cono tradicional)
          case CupShapeType.leather:
            return SizedBox(
              width: w,
              height: h,
              child: Image.asset(
                skin.assetPath,
                width: w,
                height: h,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_bar,
                  size: 32,
                  color: Color(0xFFD4AF37),
                ),
              ),
            );
        }
      },
    );
  }
}

// ==========================================
// PAINTERS DE FORMAS FÍSICAS DE VASOS
// ==========================================

/// 1. Painter para Chifle de Huaso (Cuerno de toro curvado con virola de plata)
class _ChiflePainter extends CustomPainter {
  final double animationValue;
  _ChiflePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cuerpo curvado del cuerno
    final hornPath = Path();
    hornPath.moveTo(w * 0.22, h * 0.12);
    hornPath.cubicTo(w * 0.10, h * 0.45, w * 0.25, h * 0.85, w * 0.72, h * 0.94);
    hornPath.quadraticBezierTo(w * 0.85, h * 0.90, w * 0.82, h * 0.82);
    hornPath.cubicTo(w * 0.48, h * 0.75, w * 0.38, h * 0.45, w * 0.80, h * 0.12);
    hornPath.close();

    final hornShader = LinearGradient(
      colors: const [
        Color(0xFFE2E8F0),
        Color(0xFF4A5568),
        Color(0xFF1A202C),
        Color(0xFF0F172A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(hornPath, Paint()..shader = hornShader);

    // Borde de la boca del cuerno en plata reluciente
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.51, h * 0.12),
      width: w * 0.58,
      height: h * 0.10,
    );
    final silverPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawOval(rimRect, silverPaint);

    final silverShine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawOval(rimRect, silverShine);

    // Anillo plateado de remate en la punta
    canvas.drawCircle(Offset(w * 0.76, h * 0.88), 3.0, silverPaint);
  }

  @override
  bool shouldRepaint(covariant _ChiflePainter oldDelegate) => false;
}

/// 2. Painter para Barril de Taberna (Barril abombado con zunchos)
class _BarrelPainter extends CustomPainter {
  final double animationValue;
  _BarrelPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Silueta abombada del barril
    final barrelPath = Path();
    barrelPath.moveTo(w * 0.22, h * 0.10);
    barrelPath.quadraticBezierTo(w * 0.08, h * 0.50, w * 0.22, h * 0.90);
    barrelPath.lineTo(w * 0.78, h * 0.90);
    barrelPath.quadraticBezierTo(w * 0.92, h * 0.50, w * 0.78, h * 0.10);
    barrelPath.close();

    final woodShader = LinearGradient(
      colors: const [
        Color(0xFF2C1810),
        Color(0xFF5D3A1A),
        Color(0xFF8B5A2B),
        Color(0xFF381F0E),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(barrelPath, Paint()..shader = woodShader);

    // Duelas verticales de madera
    final linePaint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.38, h * 0.10), Offset(w * 0.38, h * 0.90), linePaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.10), Offset(w * 0.62, h * 0.90), linePaint);

    // Zunchos de hierro negro remachados (arriba, medio y abajo)
    final ironPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawLine(Offset(w * 0.17, h * 0.25), Offset(w * 0.83, h * 0.25), ironPaint);
    canvas.drawLine(Offset(w * 0.12, h * 0.50), Offset(w * 0.88, h * 0.50), ironPaint);
    canvas.drawLine(Offset(w * 0.17, h * 0.75), Offset(w * 0.83, h * 0.75), ironPaint);

    // Runa mágica azul cian pulsante en el centro
    final pulse = 0.5 + 0.5 * math.sin(animationValue * 2 * math.pi);
    final runePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7 + pulse * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), 4.5, runePaint);
  }

  @override
  bool shouldRepaint(covariant _BarrelPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// 3. Painter para Cáliz Imperial 24K (Cáliz con pie torneado y rubíes)
class _GobletPainter extends CustomPainter {
  final double animationValue;
  _GobletPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final goldShader = LinearGradient(
      colors: const [
        Color(0xFFFFDF00),
        Color(0xFFFFB300),
        Color(0xFFD4AF37),
        Color(0xFFFFF176),
        Color(0xFFAA7C11),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final goldPaint = Paint()..shader = goldShader;

    // Copa superior acampanada
    final cupPath = Path();
    cupPath.moveTo(w * 0.15, h * 0.10);
    cupPath.quadraticBezierTo(w * 0.18, h * 0.45, w * 0.45, h * 0.55);
    cupPath.lineTo(w * 0.55, h * 0.55);
    cupPath.quadraticBezierTo(w * 0.82, h * 0.45, w * 0.85, h * 0.10);
    cupPath.close();
    canvas.drawPath(cupPath, goldPaint);

    // Tallo / pie torneado
    final stemPath = Path();
    stemPath.moveTo(w * 0.44, h * 0.55);
    stemPath.lineTo(w * 0.45, h * 0.78);
    stemPath.lineTo(w * 0.30, h * 0.90);
    stemPath.lineTo(w * 0.70, h * 0.90);
    stemPath.lineTo(w * 0.55, h * 0.78);
    stemPath.lineTo(w * 0.56, h * 0.55);
    stemPath.close();
    canvas.drawPath(stemPath, goldPaint);

    // Gema de Rubí imperial en el centro de la copa
    final rubyPaint = Paint()..color = const Color(0xFFE11D48);
    canvas.drawCircle(Offset(w * 0.50, h * 0.32), 3.5, rubyPaint);

    // Destello blanco en el rubí
    canvas.drawCircle(Offset(w * 0.48, h * 0.30), 1.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GobletPainter oldDelegate) => false;
}

/// 4. Painter para Calavera del Inframundo (Cráneo gótico con ojos ardientes)
class _SkullPainter extends CustomPainter {
  final double animationValue;
  _SkullPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Silueta de calavera gótica
    final skullPath = Path();
    skullPath.moveTo(w * 0.20, h * 0.20);
    skullPath.cubicTo(w * 0.15, h * 0.05, w * 0.85, h * 0.05, w * 0.80, h * 0.20);
    skullPath.cubicTo(w * 0.90, h * 0.45, w * 0.78, h * 0.65, w * 0.70, h * 0.72);
    skullPath.lineTo(w * 0.68, h * 0.88);
    skullPath.lineTo(w * 0.32, h * 0.88);
    skullPath.lineTo(w * 0.30, h * 0.72);
    skullPath.cubicTo(w * 0.22, h * 0.65, w * 0.10, h * 0.45, w * 0.20, h * 0.20);
    skullPath.close();

    final obsidianShader = LinearGradient(
      colors: const [
        Color(0xFF262626),
        Color(0xFF0F0F0F),
        Color(0xFF171717),
        Color(0xFF000000),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(skullPath, Paint()..shader = obsidianShader);

    // Borde de la calavera en rojo magma
    canvas.drawPath(
      skullPath,
      Paint()
        ..color = const Color(0xFFFF4500)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Ojos ardientes con fuego vivo dentro
    final pulse = 0.5 + 0.5 * math.sin(animationValue * 4 * math.pi);
    final eyePaint = Paint()
      ..color = Color.lerp(const Color(0xFFFF2200), const Color(0xFFFFDD00), pulse)!
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.38, w * 0.14, h * 0.18), eyePaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.54, h * 0.38, w * 0.14, h * 0.18), eyePaint);

    // Cavidad nasal triangular
    final nosePath = Path()
      ..moveTo(w * 0.50, h * 0.55)
      ..lineTo(w * 0.46, h * 0.62)
      ..lineTo(w * 0.54, h * 0.62)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = Colors.black);

    // Dientes / mandíbula
    final toothPaint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.40, h * 0.78), Offset(w * 0.40, h * 0.88), toothPaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.78), Offset(w * 0.50, h * 0.88), toothPaint);
    canvas.drawLine(Offset(w * 0.60, h * 0.78), Offset(w * 0.60, h * 0.88), toothPaint);
  }

  @override
  bool shouldRepaint(covariant _SkullPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// 5. Painter para Hexacacho Cyberpunk (Prisma hexagonal futurista)
class _CyberPrismPainter extends CustomPainter {
  final double animationValue;
  _CyberPrismPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Prisma hexagonal estilizado
    final hexPath = Path();
    hexPath.moveTo(w * 0.30, h * 0.10);
    hexPath.lineTo(w * 0.70, h * 0.10);
    hexPath.lineTo(w * 0.90, h * 0.40);
    hexPath.lineTo(w * 0.75, h * 0.90);
    hexPath.lineTo(w * 0.25, h * 0.90);
    hexPath.lineTo(w * 0.10, h * 0.40);
    hexPath.close();

    final techShader = LinearGradient(
      colors: const [
        Color(0xFF0F172A),
        Color(0xFF1E293B),
        Color(0xFF020617),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(hexPath, Paint()..shader = techShader);

    // Borde láser cian neón
    final neonStroke = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(hexPath, neonStroke);

    // Circuitos luminiscentes diagonales
    final circuitPaint = Paint()
      ..color = const Color(0xFFFF0077)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.25, h * 0.35), Offset(w * 0.50, h * 0.55), circuitPaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.55), Offset(w * 0.50, h * 0.80), circuitPaint);
    canvas.drawLine(Offset(w * 0.75, h * 0.35), Offset(w * 0.50, h * 0.55), circuitPaint);

    // Nodo central de pulso
    final pulse = 0.5 + 0.5 * math.sin(animationValue * 4 * math.pi);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.55),
      2.5 + pulse * 1.5,
      Paint()..color = const Color(0xFF00F0FF),
    );
  }

  @override
  bool shouldRepaint(covariant _CyberPrismPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// 6. Painter para Cacho Glaciar Ártico (Cristal de hielo patagónico)
class _GlacierPainter extends CustomPainter {
  final double animationValue;
  _GlacierPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Forma facetada de diamante / cristal de hielo
    final icePath = Path();
    icePath.moveTo(w * 0.20, h * 0.12);
    icePath.lineTo(w * 0.80, h * 0.12);
    icePath.lineTo(w * 0.88, h * 0.45);
    icePath.lineTo(w * 0.65, h * 0.90);
    icePath.lineTo(w * 0.35, h * 0.90);
    icePath.lineTo(w * 0.12, h * 0.45);
    icePath.close();

    final iceShader = LinearGradient(
      colors: const [
        Color(0xCCB3E5FC),
        Color(0x994FC3F7),
        Color(0xEE0288D1),
        Color(0xCC01579B),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(icePath, Paint()..shader = iceShader);

    // Facetas y aristas cristalinas
    final facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(icePath, facetPaint);

    canvas.drawLine(Offset(w * 0.50, h * 0.12), Offset(w * 0.50, h * 0.90), facetPaint);
    canvas.drawLine(Offset(w * 0.12, h * 0.45), Offset(w * 0.50, h * 0.55), facetPaint);
    canvas.drawLine(Offset(w * 0.88, h * 0.45), Offset(w * 0.50, h * 0.55), facetPaint);
  }

  @override
  bool shouldRepaint(covariant _GlacierPainter oldDelegate) => false;
}

// ==========================================
// PAINTERS DE PARTÍCULAS Y ANIMACIONES
// ==========================================

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

    final paintRed = Paint()..color = const Color(0xCCFF2200)..style = PaintingStyle.fill;
    final paintOrange = Paint()..color = const Color(0xEEFF7700)..style = PaintingStyle.fill;
    final paintYellow = Paint()..color = const Color(0xFFFFDD00)..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final offsetX = cx - (w * 0.35) + (i * (w * 0.7) / 4);
      final phase = animationValue * 2 * math.pi + (i * 1.2);
      final flameH = 7.0 + 5.0 * math.sin(phase);

      final path = Path()
        ..moveTo(offsetX - 4, cy - h * 0.2)
        ..quadraticBezierTo(offsetX, cy - h * 0.45 - flameH, offsetX + 4, cy - h * 0.2)
        ..close();
      canvas.drawPath(path, paintRed);

      final pathOrange = Path()
        ..moveTo(offsetX - 2.5, cy - h * 0.2)
        ..quadraticBezierTo(offsetX, cy - h * 0.42 - flameH * 0.8, offsetX + 2.5, cy - h * 0.2)
        ..close();
      canvas.drawPath(pathOrange, paintOrange);

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

    for (int i = 0; i < 8; i++) {
      final prog = (animationValue + (i / 8.0)) % 1.0;
      final angle = (i * math.pi / 4) + (animationValue * math.pi * 0.5);
      final radius = 12.0 + (prog * 14.0);
      final px = cx + radius * math.cos(angle);
      final py = cy - (prog * 20.0) + 4;

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
    final paint = Paint()..color = color..style = PaintingStyle.fill;
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

/// Painter de copos de nieve y escarcha flotante para Cacho Glaciar
class _FrostSnowflakesPainter extends CustomPainter {
  final double animationValue;
  _FrostSnowflakesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final snowPaint = Paint()..color = const Color(0xFFE0F7FA)..style = PaintingStyle.stroke..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final prog = (animationValue + (i / 5.0)) % 1.0;
      final angle = (i * 2 * math.pi / 5) + (animationValue * math.pi);
      final radius = 10.0 + (prog * 12.0);
      final px = cx + radius * math.cos(angle);
      final py = cy + radius * math.sin(angle);

      // Pequeña cruz de nieve
      canvas.drawLine(Offset(px - 2.5, py), Offset(px + 2.5, py), snowPaint);
      canvas.drawLine(Offset(px, py - 2.5), Offset(px, py + 2.5), snowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrostSnowflakesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ==========================================
// PAINTERS DE MARCOS DE AVATAR (FRAMES)
// ==========================================

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

    // 1. AURA DE FUEGO INFERNAL
    if (frame.effectType == 'fire') {
      final firePaint = Paint()..style = PaintingStyle.fill;
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

    // 2. NEÓN CYBERPUNK
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

      final glowPaint = Paint()
        ..shader = neonShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius, glowPaint);

      final strokePaint = Paint()
        ..shader = neonShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8;
      canvas.drawCircle(center, radius, strokePaint);

      for (int i = 0; i < 4; i++) {
        final a = (i * math.pi / 2) + (animationValue * 2 * math.pi);
        final markX = center.dx + radius * math.cos(a);
        final markY = center.dy + radius * math.sin(a);
        canvas.drawCircle(Offset(markX, markY), 2.5, Paint()..color = Colors.white);
      }
      return;
    }

    // 3. MARCO DE ORO IMPERIAL
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

      final glowPaint = Paint()
        ..shader = goldShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(center, radius, glowPaint);

      final strokePaint = Paint()
        ..shader = goldShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius, strokePaint);

      for (int i = 0; i < 4; i++) {
        final a = (i * math.pi / 2) + (animationValue * math.pi);
        final px = center.dx + (radius + 2) * math.cos(a);
        final py = center.dy + (radius + 2) * math.sin(a);
        final pulse = (math.sin(animationValue * 4 * math.pi + i) + 1.0) / 2.0;

        _drawDiamond(canvas, Offset(px, py), 2.2 + pulse * 1.5, const Color(0xFFFFFFFF));
      }
      return;
    }

    // 4. ESCARCHA GLACIAR (Hielo ártico y copos de nieve)
    if (frame.effectType == 'frost') {
      final frostShader = SweepGradient(
        colors: const [
          Color(0xFFE0F7FA),
          Color(0xFF80D8FF),
          Color(0xFF00B0FF),
          Color(0xFFE0F7FA),
        ],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = frostShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Copos de nieve orbitando
      for (int i = 0; i < 6; i++) {
        final a = (i * math.pi / 3) + (animationValue * math.pi * 0.8);
        final px = center.dx + (radius + 3) * math.cos(a);
        final py = center.dy + (radius + 3) * math.sin(a);
        canvas.drawCircle(Offset(px, py), 1.8, Paint()..color = Colors.white);
      }
      return;
    }

    // 5. VACÍO CÓSMICO (Vórtice interestelar violeta y polvo galáctico)
    if (frame.effectType == 'galaxy') {
      final galaxyShader = SweepGradient(
        colors: const [
          Color(0xFFE0AAFF),
          Color(0xFF9D4EDD),
          Color(0xFF5A189A),
          Color(0xFF240046),
          Color(0xFFE0AAFF),
        ],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = galaxyShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      for (int i = 0; i < 8; i++) {
        final a = (i * math.pi / 4) + (animationValue * 2 * math.pi);
        final dist = radius + 2 + math.sin(animationValue * 4 * math.pi + i) * 2;
        final px = center.dx + dist * math.cos(a);
        final py = center.dy + dist * math.sin(a);
        canvas.drawCircle(Offset(px, py), 1.4, Paint()..color = const Color(0xFFFFD6FF));
      }
      return;
    }

    // 6. ALAS DE GRAN MAESTRO (Corona dorada y alas de campeón)
    if (frame.effectType == 'valhalla') {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius, ringPaint);

      // Laurel / corona en la parte superior
      final crownPaint = Paint()..color = const Color(0xFFFFE082)..style = PaintingStyle.fill;
      for (int i = -3; i <= 3; i++) {
        final a = -math.pi / 2 + (i * 0.18);
        final px = center.dx + (radius + 3) * math.cos(a);
        final py = center.dy + (radius + 3) * math.sin(a);
        canvas.drawCircle(Offset(px, py), 2.2, crownPaint);
      }
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
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
