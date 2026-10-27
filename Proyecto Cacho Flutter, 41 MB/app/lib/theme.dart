import 'package:flutter/material.dart';

/// Paleta: casino nocturno. El MENÚ ya no es café/pub (orden del
/// usuario 25-oct 19:32, reiterada 22:20): fondos oscuros de la
/// familia buscar_bg con dorado mate #C9A24B. `wood`, `leatherDark`
/// y `leatherLight` SE CONSERVAN como constantes porque la MESA y
/// el cacho personalizable los usan (game_screen, lobby, setup,
/// widgets, table_themes); lo que cambió es que el menú ya no los
/// usa como superficie (ver menuDecoration y los paneles de menú).
class CachoColors {
  static const feltCenter = Color(0xFF0B5D3B);
  static const feltEdge = Color(0xFF06402A);
  static const wood = Color(0xFF2B1810);
  static const burgundy = Color(0xFF5A1A1A);
  static const gold = Color(0xFFC9A24B);
  static const casinoRed = Color(0xFFB3202A);
  static const ivory = Color(0xFFF5EBD7);
  // Familia casino del menú (la misma de buscar_bg.png):
  // azul noche profundo → casi negro → púrpura profundo.
  static const menuTop = Color(0xFF16203A);
  static const menuMid = Color(0xFF0B0B14);
  static const menuBottom = Color(0xFF120A24);
  static const background = Color(0xFF0B0B14);
  static const leatherLight = Color(0xFF6B3F22);
  static const leatherDark = Color(0xFF3E2312);
  static const pasoBlue = Color(0xFF14586B); // azul petróleo
  static const calzoGreen = Color(0xFF0E7A4F); // verde esmeralda
  static const timeAmber = Color(0xFFF2B705); // amarillo semáforo del aro-temporizador

  /// Azul claro PROVISIONAL del nº de dados de la placa bosquejo
  /// (sentencia F6, P20 PENDIENTE de fijar por el usuario: no es
  /// definitivo y su contraste no se da por cerrado hasta medirlo
  /// sobre cada paño, en su punto más claro y más oscuro).
  static const diceNumberLight = Color(0xFF8FD0FF);

  /// Colores de cuero personalizables del cacho propio.
  static const leatherChoices = <String, Color>{
    'Café': Color(0xFF6B3F22),
    'Negro': Color(0xFF26221F),
    'Burdeos': Color(0xFF5E2129),
    'Petróleo': Color(0xFF14424E),
  };
}

/// RONDA 4 (ductus): UN solo sitio gobierna las familias de
/// fuente. Ningún otro archivo lleva un literal fontFamily: todos
/// usan estas constantes (el valor es el mismo que antes, no hay
/// cambio visual: la familia del cuerpo sigue siendo la vigente
/// más cercana a la sans recta del ejemplo — sans, recta, negrita
/// legible a 14 px — frente a Cinzel (serif déco, solo títulos)
/// y CaveatBrush (manuscrita, solo la marca DUDO). Una sans
/// condensada de verdad exigiría un asset nuevo, que NO es una
/// familia vigente y no se introduce en silencio en esta ronda.
class CachoFonts {
  /// Texto de UI (barra, consola, placas, revelación): Montserrat.
  static const String body = 'Montserrat';

  /// Títulos y botones destacados: Cinzel.
  static const String display = 'Cinzel';

  /// Marca DUDO (logo y títulos manuscritos): CaveatBrush.
  static const String hand = 'CaveatBrush';
}

ThemeData buildCachoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: CachoFonts.body,
    scaffoldBackgroundColor: CachoColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CachoColors.gold,
      brightness: Brightness.dark,
      surface: CachoColors.menuTop,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: CachoColors.ivory,
      displayColor: CachoColors.ivory,
    ),
  );
}

/// Título art déco dorado.
const titleStyle = TextStyle(
  fontFamily: CachoFonts.display,
  fontWeight: FontWeight.w700,
  color: CachoColors.gold,
  letterSpacing: 3,
);

/// Fondo de mesa: paño con textura generativa (grano y fibra con
/// semilla, tools/gen_textures.py) y luz de lámpara horneada.
BoxDecoration get feltDecoration => const BoxDecoration(
      color: CachoColors.feltEdge,
      image: DecorationImage(
        image: AssetImage('assets/images/felt_bg.png'),
        fit: BoxFit.cover,
      ),
    );

/// Fondo del bar (plato 3D de Blender): mesa de madera en perspectiva
/// con luces cálidas desenfocadas. Mundo visual de la referencia que
/// entregó el usuario el 22-oct.
BoxDecoration get pubDecoration => const BoxDecoration(
      color: Color(0xFF0D0906),
      image: DecorationImage(
        image: AssetImage('assets/images/bg_pub.jpg'),
        fit: BoxFit.cover,
      ),
    );

/// Fondo de MENÚ, paleta casino (orden del usuario 25-oct 19:32,
/// reiterada 22:20; reemplaza el fondo pub/marrón anterior).
/// Mismo gradiente vertical que buscar_bg.png, dibujado por código
/// (sin foto del pub, sin cuero marrón): azul
/// noche profundo → casi negro → púrpura profundo, stops 0/0,55/1.
/// Misma API que antes (getter `menuDecoration` → BoxDecoration),
/// así lobby_screen y setup_screens siguen compilando sin tocarlos.
/// Nunca paño verde a pantalla completa en menús (R32). La
/// decoración `pubDecoration` queda solo para el tema de mesa
/// "pub" (table_themes), que esta orden no toca.
BoxDecoration get menuDecoration => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CachoColors.menuTop,
          CachoColors.menuMid,
          CachoColors.menuBottom,
        ],
        stops: [0.0, 0.55, 1.0],
      ),
    );

/// R39: luz cenital radial POR ENCIMA de la textura del paño
/// (overlay, no asset): centro apenas más claro (blanco 12 %),
/// bordes apenas más oscuros (negro 25 %). Intensidad capada por
/// la medición R35: marfil sobre paño 5,02:1 en el punto más claro
/// y 9,23:1 en el más oscuro (tools/contrast_rediseno.py).
BoxDecoration get tableCeilingLight => const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(28)),
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.12),
          Color.fromRGBO(255, 255, 255, 0.0),
          Color.fromRGBO(0, 0, 0, 0.25),
        ],
        stops: [0.0, 0.55, 1.0],
      ),
    );

/// R40: viñeta progresiva de la SALA (overlay sobre la foto de la
/// sala, debajo del contenido): centro limpio, bordes oscurecidos
/// para profundidad sin competir con el paño.
BoxDecoration get roomVignette => const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Color.fromRGBO(0, 0, 0, 0.0),
          Color.fromRGBO(0, 0, 0, 0.35),
        ],
        stops: [0.55, 1.0],
      ),
    );

/// R42: radios coherentes — 28 SOLO la mesa (el mueble), 16 los
/// paneles de juego (consola, barras, hojas de partida), 12 las
/// tarjetas de menú (home, hojas, lobby, tienda).
class CachoRadii {
  static const double table = 28;
  static const double panel = 16;
  static const double card = 12;
}

/// Tarjeta oscura azulada estilo "app social" (tarjeta de estado, panel).
const navyCard = Color(0xFF141B28);

/// Colores de aro por jugador (el mío es siempre el dorado).
const seatRingColors = <Color>[
  Color(0xFF2E9BFF), // azul
  Color(0xFFFF4D6D), // rosado
  Color(0xFF9B5CFF), // morado
  Color(0xFF2ED3B7), // turquesa
  Color(0xFFFF8A3D), // naranjo
];

/// Corona pequeña dibujada (marca de "en turno" y del logo).
class CrownMark extends StatelessWidget {
  final double width;
  final Color color;
  const CrownMark({super.key, this.width = 22, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.52),
      painter: _CrownPainter(color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  _CrownPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.06, h * 0.92)
      ..lineTo(w * 0.02, h * 0.18)
      ..lineTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.70, h * 0.52)
      ..lineTo(w * 0.98, h * 0.18)
      ..lineTo(w * 0.94, h * 0.92)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.075
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}

/// Logo DUDO estilo pincel con corona, como la referencia del usuario.
class DudoLogo extends StatelessWidget {
  final double fontSize;
  const DudoLogo({super.key, this.fontSize = 30});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CrownMark(width: fontSize * 0.62),
        Transform.rotate(
          angle: -0.035,
          child: Text(
            'DUDO',
            style: TextStyle(
              fontFamily: CachoFonts.hand,
              fontSize: fontSize,
              height: 0.95,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Superficie de madera con veta generativa, para tablero y paneles.
const woodImage = DecorationImage(
  image: AssetImage('assets/images/wood.png'),
  fit: BoxFit.cover,
);

/// Botón-placa de bronce/dorado con relieve suave.
class BronzeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final double fontSize;

  /// Familia opcional (R18: JUGAR en Cinzel 18).
  final String? fontFamily;

  /// Padding interno opcional (por defecto 14h, 12v).
  final EdgeInsetsGeometry? padding;

  const BronzeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = CachoColors.gold,
    this.icon,
    this.fontSize = 15,
    this.fontFamily,
    this.padding,
  });

  @override
  State<BronzeButton> createState() => _BronzeButtonState();
}

class _BronzeButtonState extends State<BronzeButton> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = widget.color;
    final bg = enabled ? color : color.withValues(alpha: 0.28);
    final fg = enabled
        ? (color == CachoColors.gold ? CachoColors.menuMid : CachoColors.ivory)
        : CachoColors.ivory.withValues(alpha: 0.5);
    // B3 (sentencia v2.0): botón primario unificado con degradado
    // SOLO entre tonos mates de #C9A24B, nunca dorado brillante.
    final gradientColors = color == CachoColors.gold
        ? <Color>[
            enabled
                ? CachoColors.gold
                : CachoColors.gold.withValues(alpha: 0.28),
            enabled
                ? const Color(0xFFA8873B)
                : const Color(0xFFA8873B).withValues(alpha: 0.28),
          ]
        : <Color>[bg.withValues(alpha: 0.95), bg];
    // F9: escala 0,97 al presionar y brillo dorado en hover/foco
    // solo escritorio (MouseRegion no dispara en táctil). La escala
    // y la sombra no cambian el tamaño del botón.
    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hover = true) : null,
      onExit: enabled ? (_) => setState(() => _hover = false) : null,
      child: Transform.scale(
        scale: _pressed ? 0.97 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hover && enabled
                ? [
                    BoxShadow(
                      color: CachoColors.gold.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            elevation: enabled ? 4 : 0,
            child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // R34: presionado 8 % más oscuro, sin cambio de tamaño.
        highlightColor: Colors.black.withValues(alpha: 0.08),
        splashColor: Colors.black.withValues(alpha: 0.08),
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: Container(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.fontSize + 2, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: widget.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.fontSize,
                  color: fg,
                  letterSpacing: 0.6,
                ),
              ),
            ],
            ),
        ),
      ),
            ),
        ),
      ),
    );
  }
}
