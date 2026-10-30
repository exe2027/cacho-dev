import 'package:flutter/material.dart';

/// Pintor para generar dinámicamente el fondo de la mesa.
/// Esto evita problemas de aspecto con imágenes comprimidas.
class MesaBgPainter extends CustomPainter {
  final String theme;

  MesaBgPainter({this.theme = 'casino'});

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo base (marco/brazo de la mesa)
    final bgPaint = Paint()
      ..color = const Color(0xFF1a1a1a);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Paño de mesa con gradiente suave
    final feltPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: _getColors(),
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Dibujar el paño con márgenes
    final margin = 8.0;
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2),
      feltPaint,
    );

    // Marco interior (borde del paño)
    final framePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2),
      framePaint,
    );

    // Brillo sutil en la parte superior
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height * 0.3));
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height * 0.3),
      shinePaint,
    );

    // Detalle central (marca de agua muy sutil)
    _drawWatermark(canvas, size);
  }

  void _drawWatermark(Canvas canvas, Size size) {
    // Marca de agua muy sutil (casi invisible)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CACHO O DUDO',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.03),
          fontSize: size.width * 0.06, // Escalar con el ancho
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2 - size.height * 0.05,
      ),
    );
  }

  List<Color> _getColors() {
    switch (theme) {
      case 'salon':
        // Verde oscuro (billar/salón clásico)
        return [
          const Color(0xFF2d5016),
          const Color(0xFF1a2e0a),
        ];
      case 'vip':
        // Azul oscuro (VIP elegante)
        return [
          const Color(0xFF1a2e4a),
          const Color(0xFF0f1a2e),
        ];
      case 'highroller':
        // Burdeos/Marrón (highroller lujoso)
        return [
          const Color(0xFF3a1a1a),
          const Color(0xFF1a0f0f),
        ];
      case 'casino':
      default:
        // Carbón (casino estándar)
        return [
          const Color(0xFF1a3a1a),
          const Color(0xFF0d1f0d),
        ];
    }
  }

  @override
  bool shouldRepaint(MesaBgPainter oldDelegate) => oldDelegate.theme != theme;

  @override
  bool shouldRebuildSemantics(MesaBgPainter oldDelegate) => false;
}
