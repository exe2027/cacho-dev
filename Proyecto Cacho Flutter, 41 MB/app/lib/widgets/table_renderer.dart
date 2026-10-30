import 'package:flutter/material.dart';
import '../table_geometry.dart';
import '../table_themes.dart';

/// Renderizador de mesa usando la nueva arquitectura de TableGeometry.
/// Pinta la mesa (óvalo + paño + borde) y los componentes (vasos, avatares,
/// placas) usando coordenadas calculadas desde una geometría única.
class TableRenderer extends CustomPaint {
  final TableGeometry geometry;
  final String tierID;
  final BoxDecoration? backgroundDecoration;
  final Widget? child;

  TableRenderer({
    required this.geometry,
    required this.tierID,
    this.backgroundDecoration,
    this.child,
  }) : super(
    painter: _TablePainter(geometry, tierID),
    child: child,
  );
}

/// Pintor que dibuja la mesa y su marco según el tier.
class _TablePainter extends CustomPainter {
  final TableGeometry geometry;
  final String tierID;

  _TablePainter(this.geometry, this.tierID);

  @override
  void paint(Canvas canvas, Size size) {
    final look = tierLookFor(_getTierStakeFromID());
    
    // Marco exterior (borde de madera o cian en neón)
    _paintTableFrame(canvas, look);
    
    // Paño (base de la mesa)
    _paintTableFelt(canvas, look);
    
    // Filete dorado interior
    _paintTableFillet(canvas, look);
    
    // Pozo (arriba al centro)
    _paintPot(canvas, look);
  }

  void _paintTableFrame(Canvas canvas, TierLook look) {
    final paint = Paint()
      ..color = look.rimTop
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final oval = Rect.fromLTWH(
      geometry.tableSize.centerX - geometry.tableSize.radiusX,
      geometry.tableSize.centerY - geometry.tableSize.radiusY,
      geometry.tableSize.ovalWidth,
      geometry.tableSize.ovalHeight,
    );

    canvas.drawOval(oval, paint);
  }

  void _paintTableFelt(Canvas canvas, TierLook look) {
    final paint = Paint()
      ..color = look.feltCenter
      ..style = PaintingStyle.fill;

    final oval = Rect.fromLTWH(
      geometry.tableSize.centerX - geometry.tableSize.radiusX + 8,
      geometry.tableSize.centerY - geometry.tableSize.radiusY + 8,
      geometry.tableSize.ovalWidth - 16,
      geometry.tableSize.ovalHeight - 16,
    );

    canvas.drawOval(oval, paint);
  }

  void _paintTableFillet(Canvas canvas, TierLook look) {
    if (look.filletWidth <= 0) return;

    final paint = Paint()
      ..color = look.rimBottom
      ..style = PaintingStyle.stroke
      ..strokeWidth = look.filletWidth;

    final oval = Rect.fromLTWH(
      geometry.tableSize.centerX - geometry.tableSize.radiusX + 10,
      geometry.tableSize.centerY - geometry.tableSize.radiusY + 10,
      geometry.tableSize.ovalWidth - 20,
      geometry.tableSize.ovalHeight - 20,
    );

    canvas.drawOval(oval, paint);
  }

  void _paintPot(Canvas canvas, TierLook look) {
    final potPaint = Paint()
      ..color = Colors.brown.shade800
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(geometry.potRect, const Radius.circular(4)),
      potPaint,
    );

    // Texto "POZO"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'POZO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        geometry.potRect.center.dx - textPainter.width / 2,
        geometry.potRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  int _getTierStakeFromID() {
    // Mapeo simple de ID de tema a stake (apuesta)
    switch (tierID) {
      case 'pub':
        return 100; // La Taberna
      case 'dorado':
        return 500; // El Casino (defecto)
      case 'neon':
        return 2500; // Club VIP (más extravagante)
      default:
        return 500;
    }
  }

  @override
  bool shouldRepaint(_TablePainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.tierID != tierID;
}

/// Widget que posiciona un componente (avatar, vaso, placa) en la mesa.
class TableComponent extends StatelessWidget {
  final Offset center;
  final Size size;
  final Widget child;

  const TableComponent({
    required this.center,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: child,
      ),
    );
  }
}
