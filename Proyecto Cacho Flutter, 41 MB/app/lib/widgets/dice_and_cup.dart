import 'package:cacho_engine/cacho_engine.dart';
import 'dart:async';
import 'dart:math';

import 'package:blobatar/flutter.dart' as blobatar;
import 'package:flutter/material.dart';

import '../theme.dart';
import '../state/wallet.dart';

/// Dado marfil con puntos; el 1 lleva su punto rojo (comodín visible) y,
/// opcionalmente, una insignia con el número (accesibilidad: la pinta no
/// se distingue solo por color).
class DiceFace extends StatelessWidget {
  final int value;
  final double size;
  final bool highlighted;
  final bool alert;
  final bool dimmed;
  final bool showBadge;

  const DiceFace({
    super.key,
    required this.value,
    this.size = 40,
    this.highlighted = false,
    this.alert = false,
    this.dimmed = false,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final face = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dimmed ? const Color(0xFFDED8CE) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: alert
            ? Border.all(color: CachoColors.casinoRed, width: 2.8)
            : highlighted
                ? Border.all(color: CachoColors.gold, width: 2.5)
                : Border.all(
                    color: dimmed
                        ? const Color(0xFFB5ADA0)
                        : const Color(0xFFC7BCA9),
                    width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dimmed ? 0.25 : 0.45),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: CustomPaint(painter: _PipsPainter(value, dimmed: dimmed)),
    );
    final withBadge = showBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              face,
              Positioned(
                right: -4,
                top: -4,
                child: CircleAvatar(
                  radius: size * 0.16,
                  backgroundColor: CachoColors.gold,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          )
        : face;
    return withBadge;
  }
}

class _PipsPainter extends CustomPainter {
  final int value;
  final bool dimmed;
  _PipsPainter(this.value, {this.dimmed = false});

  static const _spots = <int, List<List<double>>>{
    1: [
      [0.5, 0.5]
    ],
    2: [
      [0.28, 0.28],
      [0.72, 0.72]
    ],
    3: [
      [0.25, 0.25],
      [0.5, 0.5],
      [0.75, 0.75]
    ],
    4: [
      [0.28, 0.28],
      [0.72, 0.28],
      [0.28, 0.72],
      [0.72, 0.72]
    ],
    5: [
      [0.25, 0.25],
      [0.75, 0.25],
      [0.5, 0.5],
      [0.25, 0.75],
      [0.75, 0.75]
    ],
    6: [
      [0.28, 0.22],
      [0.28, 0.5],
      [0.28, 0.78],
      [0.72, 0.22],
      [0.72, 0.5],
      [0.72, 0.78]
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = value == 1
          ? (dimmed ? const Color(0xFFC0392B) : CachoColors.casinoRed)
          : (dimmed ? const Color(0xFF38332B) : const Color(0xFF141210))
      ..style = PaintingStyle.fill;
    final r = size.width * (value == 1 ? 0.16 : 0.12);
    for (final s in _spots[value] ?? const []) {
      canvas.drawCircle(Offset(s[0] * size.width, s[1] * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_PipsPainter old) =>
      old.value != value || old.dimmed != dimmed;
}

/// El cacho de cuero: cuerpo cónico con grano (degradado), boca con banda
/// dorada, costuras y las iniciales grabadas.
/// Sprite 3D (Blender) según el color de cuero elegido; si el color no
/// es uno de los cuatro renders, se cae al pintor vectorial.
String? cupAssetFor(Color leather) {
  switch (leather.toARGB32()) {
    case 0xFF6B3F22:
      return 'assets/images/cup_cafe.png';
    case 0xFF26221F:
      return 'assets/images/cup_negro.png';
    case 0xFF5E2129:
      return 'assets/images/cup_burdeos.png';
    case 0xFF14424E:
      return 'assets/images/cup_petroleo.png';
  }
  return null;
}

/// Vaso propio / del pozo / de celebración: el sprite ya es
/// cup_cafe.png cuando el cuero es leatherLight (0xFF6B3F22, el
/// color que pasan mi vaso y los rivales), así que la selección
/// de asset no cambia. Lo nuevo es el posavasos: el sprite
/// coaster.png (240×80, óvalo oscuro) dibujado DENTRO de este
/// widget, debajo del vaso, para que ningún llamador cambie.
/// Geometría: el posavasos mide 1,28× el ancho del vaso (un poco
/// más ancho que la boca, como en el mockup) y asoma un 30% de
/// su alto por debajo del cuerpo del vaso; el resto queda
/// detrás del vaso y solo se ve en los laterales. La huella
/// total es (coasterWidthFor × height + coasterPeekFor): el
/// posavasos NO baja del borde donde antes terminaba el vaso
/// (el cuerpo sube `peek`, el posavasos ocupa esa franja), así
/// que no tapa nada nuevo por debajo; a los lados sobresale
/// 0,14× el ancho por lado, dentro del hueco libre que ya
/// rodea al vaso (mi vaso: hueco central 104, vaso 64 →
/// 20 px libres por lado frente a 9 px de lóbulo). El
/// posavasos NO se voltea con mouthDown (es simétrico) y NO
/// revela nada en Kamikaze a ciegas ni en peek: en peek sube
/// con el vaso porque el llamador envuelve este widget entero
/// en el Transform (ver hueco abajo: separarlo del Transform
/// es un ajuste pendiente del llamador, no de este archivo).
class CachoCup extends StatelessWidget {
  final double width;
  final double height;
  final Color leather;
  final String? initials;
  final bool dimmed;

  /// Boca abajo, como queda el vaso en la mesa tapando los dados
  /// (orden del usuario, 22-oct: "el vaso tiene que estar al revés,
  /// simulando que deja los dados en la mesa"). Voltea el sprite y
  /// deja las iniciales en el cuerpo que queda a la vista.
  final bool mouthDown;

  /// Sin posavasos (lo usa RivalCup, que dibuja el mismo sprite
  /// en su huella congelada 70×72 para no mover el cuerpo del
  /// vaso rival ni un px: si este widget creciera dentro de
  /// RivalCup, el cuerpo rival subiría 8 px y rompería el
  /// layout de 0 solapes medido en sketch_layout_test).
  final bool showCoaster;

  /// Ancho del posavasos para un vaso de [cupWidth].
  // RONDA 2 (F3): posavasos ~1,3× la base del vaso (era 1,28×),
  // oscuro distinguible del paño (coaster.png #120C08 frente a
  // paño mate #1D1A19) y boca abajo siempre (mouthDown en todos
  // los llamadores de mesa; ver _sketchTable y RivalCup).
  static double coasterWidthFor(double cupWidth) => cupWidth * 1.30;

  /// Cuánto asoma el posavasos por debajo del cuerpo del vaso.
  static double coasterPeekFor(double cupWidth) =>
      coasterWidthFor(cupWidth) / 3.0 * 0.30;

  const CachoCup({
    super.key,
    this.width = 120,
    this.height = 140,
    this.leather = CachoColors.leatherLight,
    this.initials,
    this.dimmed = false,
    this.mouthDown = false,
    this.showCoaster = true,
  });

  @override
  Widget build(BuildContext context) {
    final sprite = cupAssetFor(leather) != null
        ? Image.asset(
            cupAssetFor(leather)!,
            width: width,
            height: height,
            fit: BoxFit.contain,
          )
        : CustomPaint(
            size: Size(width, height),
            painter: _CupPainter(leather, flipped: mouthDown),
          );
    final cup = Stack(
      alignment: Alignment.center,
      children: [
        if (mouthDown) Transform.flip(flipY: true, child: sprite) else sprite,
        if (initials != null)
          Positioned(
            bottom: mouthDown ? null : height * 0.16,
            top: mouthDown ? height * 0.30 : null,
            child: Text(
              initials!,
              style: TextStyle(
                fontFamily: CachoFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: width * 0.16,
                color: CachoColors.gold.withValues(alpha: 0.85),
                letterSpacing: 2,
              ),
            ),
          ),
      ],
    );
    if (!showCoaster) {
      return Opacity(
        opacity: dimmed ? 0.4 : 1,
        child: cup,
      );
    }
    final coasterW = coasterWidthFor(width);
    final coasterH = coasterW / 3.0;
    final peek = coasterPeekFor(width);
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: SizedBox(
        width: coasterW,
        height: height + peek,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              child: Image.asset(
                'assets/images/coaster.png',
                width: coasterW,
                height: coasterH,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: peek,
              child: SizedBox(width: width, height: height, child: cup),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vaso rival en la mesa bosquejo (CU4 REVERTIDA por el master
/// prompt 25-oct): mismo sprite Blender por color que el vaso
/// propio, a ~0,5 de su tamaño en mesa (50×59 frente a 101×118 en
/// el diseño anterior; en el bosquejo el vaso propio usa el tamaño
/// compacto 0,72, 73×85), boca abajo sobre un posavasos oscuro,
/// NUNCA interactivo (sin gestos, sin levantar, sin animar por
/// turno, sin tocar nombre, pipas, aro, consola, escenario ni mi
/// fila). La única animación es la agitación compartida de inicio
/// de ronda (CU2): el padre le pasa el ángulo de UNA sola animación
/// para todos los vasos, sin parámetros por jugador. Restaurado del
/// commit 4cf5393 (código guardado tras la puerta CU4).
/// Vaso de un rival sobre la mesa (bosquejo/master prompt 2c +
/// sentencia F2): un vaso de cuero por jugador, sobre posavasos
/// oscuro, orientado a su dueño, boca abajo, LISO (corrección
/// 25-oct: el bosquejo no lleva iniciales doradas). Tamaño
/// 56×64 (huella con posavasos 70×72) — ver sketch_layout_test).
/// [skinId] es el gancho cosmético 11c/F2-C (piel visible para
/// todos): hoy no cambia el dibujo (misma caja, misma colocación);
/// una piel futura que cambie caja o colocación es rechazo.
class RivalCup extends StatelessWidget {
  final Color leather;
  final double shakeAngle;
  final double scale;
  final double? cupW;
  final double? cupH;
  final String? skinId;

  const RivalCup({
    super.key,
    required this.leather,
    this.shakeAngle = 0,
    this.scale = 1,
    this.cupW,
    this.cupH,
    this.skinId,
  });

  @override
  Widget build(BuildContext context) {
    final w = cupW ?? 50 * scale;
    final h = cupH ?? 59 * scale;
    // RONDA 2 (F3): posavasos 1,3× la base (era w+14: 1,25× a 56).
    // El cuerpo NO se mueve ni un px (centrado abajo, bottom:4):
    // solo crecen los lóbulos laterales ~1,5 px por lado, así que
    // el rect del layout sigue valiendo y el test de 0 solapes
    // no se toca. El posavasos es el mismo sprite coaster.png
    // que CachoCup, detrás del vaso: asoma 4 px por debajo y los
    // lóbulos laterales. CachoCup va con showCoaster:false para
    // no duplicarlo: un solo coaster.png por vaso rival.
    final coasterW = (w * 1.3).roundToDouble();
    return IgnorePointer(
      child: SizedBox(
        width: coasterW,
        height: h + 8,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Posavasos sprite (master prompt 2c).
            Positioned(
              bottom: 0,
              child: Image.asset(
                'assets/images/coaster.png',
                width: coasterW,
                height: coasterW / 3.0,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 4,
              child: Transform.rotate(
                angle: shakeAngle,
                // Bosquejo: vaso LISO, sin iniciales doradas.
                child: CachoCup(
                  width: w,
                  height: h,
                  leather: leather,
                  mouthDown: true,
                  showCoaster: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupPainter extends CustomPainter {
  final Color leather;
  final bool flipped;
  _CupPainter(this.leather, {this.flipped = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (flipped) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }
    final w = size.width;
    final h = size.height;
    final light = Color.lerp(leather, Colors.white, 0.16)!;
    final dark = Color.lerp(leather, Colors.black, 0.38)!;

    // Sombra sobre el paño
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.97), width: w * 0.72, height: h * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Cuerpo cónico
    final body = Path()
      ..moveTo(w * 0.10, h * 0.22)
      ..quadraticBezierTo(w * 0.16, h * 0.62, w * 0.31, h * 0.94)
      ..quadraticBezierTo(w * 0.5, h * 0.99, w * 0.69, h * 0.94)
      ..quadraticBezierTo(w * 0.84, h * 0.62, w * 0.90, h * 0.22)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, leather, dark],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Grano del cuero: punteo fino con semilla fija (mismo patrón en
    // cada repintado) y una luz suave en el borde izquierdo.
    canvas.save();
    canvas.clipPath(body);
    final grain = Random(7);
    final dotPaint = Paint();
    for (var i = 0; i < 130; i++) {
      final gx = w * (0.14 + grain.nextDouble() * 0.72);
      final gy = h * (0.26 + grain.nextDouble() * 0.66);
      dotPaint.color = (grain.nextBool() ? Colors.black : Colors.white)
          .withValues(alpha: 0.05 + grain.nextDouble() * 0.05);
      canvas.drawCircle(Offset(gx, gy), 0.8 + grain.nextDouble() * 1.1, dotPaint);
    }
    canvas.drawRect(
      Rect.fromLTWH(w * 0.16, h * 0.24, w * 0.10, h * 0.66),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();

    // Costuras laterales (punteadas)
    final stitch = Paint()
      ..color = CachoColors.gold.withValues(alpha: 0.55)
      ..strokeWidth = 1.6;
    for (final x in [0.30, 0.70]) {
      var y = h * 0.40;
      while (y < h * 0.84) {
        canvas.drawLine(Offset(w * x, y), Offset(w * x, y + h * 0.035), stitch);
        y += h * 0.07;
      }
    }

    // Boca: borde reforzado + banda dorada
    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.10, w * 0.90, h * 0.17),
      const Radius.circular(9),
    );
    canvas.drawRRect(rim, Paint()..color = dark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.225, w * 0.90, h * 0.045),
        const Radius.circular(4),
      ),
      Paint()..color = CachoColors.gold.withValues(alpha: 0.9),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.13, h * 0.115, w * 0.74, h * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_CupPainter old) =>
      old.leather != leather || old.flipped != flipped;
}

/// Asiento de un jugador en la mesa: avatar con aro dorado (el aro es el
/// temporizador del turno y se va vaciando), apodo, mini dados con los
/// que le quedan y un globo con su última jugada (master prompt §6).
/// Insignia de micrófono sobre la foto de perfil: encendido
/// (dorado) o apagado (tenue). En el asiento propio es el botón
/// que activa/desactiva la voz.
class MicBadge extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  const MicBadge({super.key, required this.on, this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? const Color(0xFF14532D) : const Color(0xFF141B28),
        border: Border.all(
          color: on ? const Color(0xFF35D461) : Colors.white24,
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 4),
        ],
      ),
      child: Icon(
        on ? Icons.mic : Icons.mic_off,
        size: 12.5,
        color: on ? const Color(0xFF7DFF9A) : Colors.white38,
      ),
    );
    if (onTap == null) return badge;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: badge,
      ),
    );
  }
}

/// Lado de la placa bosquejo respecto al avatar.
enum SketchPlateSide { below, left, right }

class PlayerSeat extends StatelessWidget {
  final String nickname;

  /// Semilla estable para el avatar Blobatar (ID de jugador, no el
  /// apodo: el apodo se puede cambiar en la sala y el avatar no
  /// debe cambiar con él). Si es null se usa el apodo.
  final String? seed;
  final int diceCount;
  final bool isTurn;
  final bool eliminated;
  final bool isBot;
  final bool connected;
  final bool hasPendingPaso;
  final bool compact;

  /// Sin burbuja de última jugada (asientos laterales en modo
  /// compacto: el espacio vertical no alcanza para todos).
  final bool hideBubble;

  /// Color del aro que identifica al jugador (el mío es el dorado).
  final Color ringColor;

  /// Fracción de tiempo que queda en su turno (0..1). Null = sin aro.
  final double? ringFraction;

  /// Última jugada, para el globo ("3 Cuadras", "Paso", "¡Dudo!").
  final String? bubbleText;

  /// Si la última jugada fue una apuesta, el globo además muestra el
  /// dado de la pinta (la apuesta siempre va con dado + número + nombre).
  final Bid? bubbleBid;

  /// Motivo en una línea (bots en la partida guiada).
  final String? bubbleReason;

  /// Estado del micrófono de voz (solo en línea, humanos).
  /// null = sin insignia (local o bot).
  final bool? micOn;

  /// Cuenta regresiva de reconexión (epoch ms): si está
  /// desconectado, el asiento muestra cuánto le queda para
  /// volver antes de quedar eliminado (regla del usuario, 24-oct).
  final int? dcDeadlineMs;

  /// Toque en la insignia (solo el asiento propio: activa la voz).
  final VoidCallback? onMicTap;

  /// B10 (sentencia v2.0): en mi asiento, el número de dados que me
  /// quedan en grande junto a las pipas, dentro de la misma fila
  /// (sin fila nueva y sin invadir el hueco 104 de la sentencia v53).
  final bool showDiceNumber;

  /// Saldo de monedas (bosquejo/master prompt 2b + sentencia F6):
  /// se muestra solo cuando viene un dato real (en línea, si el
  /// estado lo trae); en local es null y NO se dibuja ningún número
  /// (cero cifras falsas). Regla única F6: bot siempre sin cifra;
  /// humano local sin cifra rival; humano en línea solo si el
  /// estado trae el saldo real; mi asiento nunca lleva saldo (mi
  /// saldo real vive solo en la barra). Si a ≥14 px no cabe sin
  /// truncar, la cifra se OMITE (nunca se trunca ni redondea).
  final int? balance;

  /// Placa del bosquejo (sentencia F1/F6): avatar + nombre en una
  /// línea + segunda línea (saldo si lo hay + nº de dados en azul
  /// claro), sin pipas (el número ES el conteo). Sin esta flag, el
  /// asiento conserva su diseño anterior (pipas + estado).
  final bool sketchPlate;

  /// Lado de la placa bosquejo (geometría de sketch_layout):
  /// debajo (costados y resto), a la izquierda (240) o a la
  /// derecha (300 y mi asiento en fila) del avatar.
  final SketchPlateSide plateSide;

  /// Placa de una línea (asientos inferiores 60/120): el conteo
  /// va PRIMERO ("×N · nombre") para que el nº nunca se trunque;
  /// el nombre puede elipsarse (fallback F6).
  final bool singleLinePlate;

  /// Solo avatar (la placa la dibuja el llamador en su rect
  /// exacto de sketch_layout).
  final bool showPlate;

  /// Radio del círculo del avatar (27 = 56 px en referencia;
  /// 23 = 46 px en arco igual para 7+ rivales, donde 56 no da
  /// el paso diagonal — ver sketch_layout.dart).
  final double avatarRadius;

  /// Solo placa (el avatar lo dibuja el llamador en su rect
  /// exacto de sketch_layout).
  final bool plateOnly;

  /// Ancho de la placa bosquejo (88 por defecto; 80 en arco
  /// igual para 7+ rivales, donde 88 no da el paso).
  final double plateWidth;

  /// Variante horizontal (sentencia mesa horizontal): asiento compacto
  /// para la mesa de 334 px: sin burbuja, sin línea de estado, sin
  /// pastilla EN TURNO (el turno lo dan el aro semáforo y la barra
  /// superior), nombre a 88 px en 1 línea y gaps de 2 px. El avatar
  /// sigue en 56 y las pipas en 9: no se achican para que quepa.
  final bool landscape;

  /// Fila horizontal (solo fila superior en landscape): avatar a la
  /// izquierda y nombre + pipas a su derecha, en vez de apilados.
  /// Sin ella, el vaso levantado de mi turno tapa las pipas del
  /// asiento central superior (la mesa de 334 no da para vaso de
  /// 118 + subida de 58 + asiento apilado de 104 en la misma
  /// columna). La fila mide 150 px de ancho y 64 de alto.
  final bool rowLayout;

  const PlayerSeat({
    super.key,
    required this.nickname,
    this.seed,
    required this.diceCount,
    this.showDiceNumber = false,
    this.balance,
    this.sketchPlate = false,
    this.plateSide = SketchPlateSide.below,
    this.singleLinePlate = false,
    this.showPlate = true,
    this.plateOnly = false,
    this.plateWidth = 88,
    this.avatarRadius = 27,
    this.isTurn = false,
    this.eliminated = false,
    this.isBot = false,
    this.connected = true,
    this.hasPendingPaso = false,
    this.compact = false,
    this.hideBubble = false,
    this.ringColor = CachoColors.gold,
    this.ringFraction,
    this.landscape = false,
    this.rowLayout = false,
    this.bubbleText,
    this.bubbleBid,
    this.bubbleReason,
    this.micOn,
    this.onMicTap,
    this.dcDeadlineMs,
  });

  @override
  Widget build(BuildContext context) {
    // Orden del usuario 15:51 (25-oct): TODOS los avatares son
    // Blobatar, el repositorio que ya se usa en la app (hue 45
    // dorado, círculo). Sin retratos, sin iniciales, sin fotos
    // generadas. La semilla es el ID estable, no el apodo.
    final radius = avatarRadius;
    final ringW = isTurn ? 3.5 : 3.0;
    // En su turno el círculo entero toma el semáforo del tiempo.
    final circleColor = seatRingColor(
        identity: ringColor, isTurn: isTurn, fraction: ringFraction);
    final avatar = SizedBox(
      width: (radius + 5) * 2,
      height: (radius + 5) * 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (ringFraction != null && isTurn)
            CustomPaint(
              size: Size((radius + 5) * 2, (radius + 5) * 2),
              painter: _RingPainter(ringFraction!),
            ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: circleColor, width: ringW),
              boxShadow: isTurn
                  ? [
                      BoxShadow(
                        color: circleColor.withValues(alpha: 0.65),
                        blurRadius: 14,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: radius * 2,
                height: radius * 2,
                child: blobatar.Blobatar(
                  name: seed ?? nickname,
                  size: radius * 2,
                  options: const blobatar.BlobatarOptions(
                    hue: 45.0,
                    background: blobatar.Backdrop.circle,
                  ),
                  semanticLabel: nickname,
                ),
              ),
            ),
          ),
          // Punto de presencia (verde = en la mesa)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected && !eliminated
                    ? const Color(0xFF35D461)
                    : const Color(0xFF8A8F98),
                border: Border.all(color: const Color(0xFF14100C), width: 2),
              ),
            ),
          ),
          if (micOn != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(child: MicBadge(on: micOn!, onTap: onMicTap)),
            ),
          if (hasPendingPaso)
            Positioned(
              right: -12,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: CachoColors.pasoBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('PASO',
                    style: TextStyle(
                        fontSize: landscape ? 14 : 9,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
    final status = eliminated
        ? ('Quedó fuera', Colors.white54)
        : !connected
            ? ('Sin conexión', Colors.white54)
            : isTurn
                ? ('En turno', ringColor)
                : ('En espera', const Color(0xFFCFC8BB));
    // Claridad de turno (reporte 23-oct: "cuesta saber de quién es
    // el turno"): el asiento activo CRECE y brilla, los demás se
    // atenúan un poco — el ojo cae solo en quien juega.
    // Y todo cambio de tamaño (al abrirse la consola de apuestas
    // el asiento se compacta) se desliza con AnimatedSize en vez
    // de saltar: los perfiles "se acomodan", no se desordenan.
    // En horizontal NO crece: el presupuesto vertical (93 + 140 +
    // 93 = 326 ≤ 334) no admite el ×1,1, que recortaba mis pipas
    // abajo al ser mi turno; el turno lo dan el aro semáforo y la
    // pastilla de la barra superior.
    final nameWidget = Container(
      constraints: BoxConstraints(
          maxWidth: rowLayout ? 80 : (landscape ? 88 : 104)),
      child: Text(
        nickname,
        maxLines: (rowLayout || landscape) ? 1 : 2,
        textAlign: rowLayout ? TextAlign.left : TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          // D2 (Etapa 4): en horizontal todos los textos de asiento
          // van a ≥14; el vertical congelado queda en 13.
          fontSize: landscape ? 14 : 13,
          fontWeight: FontWeight.w700,
          height: 1.1,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 5),
          ],
        ),
      ),
    );
    // Pipas de dados: llenas = dados que le quedan (máx 5).
    // Orden del usuario, 27-oct: el conteo de dados vuelve a
    // ser SOLO estos 5 círculos — cada dado perdido se apaga
    // (círculo tenue) —, sin el texto "×N". Por eso pipsRow ya
    // no añade el número aunque showDiceNumber sea true: ese
    // flag queda sin efecto en las placas, para no romper a los
    // llamadores que todavía lo pasan.
    final dicePips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 1.6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < diceCount
                  ? (isTurn ? ringColor : CachoColors.ivory)
                  : Colors.white.withValues(alpha: 0.35),
              border: Border.all(
                color: i < diceCount
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
          ),
      ],
    );
    final pipsRow = dicePips;
    // Línea media: pastilla EN TURNO, cuenta de desconexión o
    // estado. En landscape no hay pastilla ni estado (los suprime
    // la sentencia); solo sobrevive la cuenta de desconexión.
    Widget? midWidget;
    if (isTurn && !eliminated && connected && !landscape) {
      midWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
        decoration: BoxDecoration(
          color: ringColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: ringColor.withValues(alpha: 0.5), blurRadius: 7),
          ],
        ),
        child: const Text(
          'EN TURNO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: Color(0xFF221A08),
          ),
        ),
      );
    } else if (!connected && !eliminated && dcDeadlineMs != null) {
      midWidget =
          _DcCountdown(deadlineMs: dcDeadlineMs!, landscape: landscape);
    } else if (!compact && !landscape) {
      midWidget = Text(
        status.$1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: status.$2,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
        ),
      );
    }
    // Placa del bosquejo (sentencia F1/F6): avatar + nombre en
    // una línea + segunda línea [saldo real si lo hay + las 5
    // pipas de dados], sin texto "×N" (27-oct: el conteo vuelve
    // a ser solo círculos, que se apagan al perder dados), sin
    // pastilla EN TURNO en horizontal (el turno lo dan el aro
    // semáforo y la barra). La cifra de saldo nunca se trunca:
    // si no cabe junto a las pipas, se omite.
    if (sketchPlate) {
      if (!showPlate) {
        return Opacity(
          opacity: eliminated ? 0.45 : (isTurn ? 1 : 0.86),
          child: avatar,
        );
      }
      final balanceText =
          balance != null ? coinsText(balance!) : null;
      // Medición honesta de cabida: un TextPainter a 14 px negrita
      // mide la cifra de saldo; solo se muestra si cabe junto a
      // las pipas (5 círculos ≈ 61 px + gap 4). La cifra nunca se
      // trunca ni redondea.
      final tp = TextPainter(
        text: TextSpan(
          text: balanceText ?? '',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final showBalance =
          balanceText != null && tp.width + 65 <= plateWidth;
      const nameStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.1,
        shadows: [
          Shadow(color: Colors.black87, blurRadius: 5),
        ],
      );
      const balanceStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFFE9A8),
        height: 1.1,
        shadows: [
          Shadow(color: Colors.black87, blurRadius: 5),
        ],
      );
      // RONDA 2 (F6): Tooltip con el nombre completo: un apodo
      // largo en línea puede elipsarse en la placa y el dato
      // completo debe recuperarse sin truncar en silencio.
      final nameWidget = SizedBox(
        width: plateWidth,
        child: Tooltip(
          message: nickname,
          child: Text(
            nickname,
            maxLines: 1,
            textAlign: plateSide == SketchPlateSide.below
                ? TextAlign.center
                : TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
      );
      // Promoción explícita: showBalance implica balanceText no
      // nulo, pero Dart no lo infiere a través del booleano.
      final shownBalance = showBalance ? balanceText : null;
      // Segunda línea: saldo (si cabe) + las 5 pipas de dados,
      // sin texto "×N": los círculos apagados son los dados
      // perdidos (orden del usuario, 27-oct).
      final line2Widget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shownBalance != null) ...[
            Text(shownBalance, style: balanceStyle),
            const SizedBox(width: 4),
          ],
          dicePips,
        ],
      );
      final dcWidget = !connected && !eliminated && dcDeadlineMs != null
          ? _DcCountdown(deadlineMs: dcDeadlineMs!, landscape: true)
          : null;
      Widget plateCol;
      if (singleLinePlate) {
        // Una línea de alto: las 5 pipas primero y el nombre
        // después (27-oct: sin "×N"). El ancho 132 se mantiene
        // (RONDA 2 F4/F6) y el Tooltip devuelve el nombre
        // completo + el conteo si un apodo largo lo supera.
        // El Positioned del llamador (_sketchRivalSeat) ya
        // ensancha a 132, así que la restricción no comprime
        // al hijo.
        plateCol = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 132,
              child: Tooltip(
                message: '$nickname · $diceCount dados',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    dicePips,
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        nickname,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (dcWidget != null) ...[
              const SizedBox(height: 2),
              dcWidget,
            ],
          ],
        );
      } else {
        plateCol = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: plateSide == SketchPlateSide.below
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            nameWidget,
            const SizedBox(height: 1),
            line2Widget,
            if (dcWidget != null) ...[
              const SizedBox(height: 2),
              dcWidget,
            ],
          ],
        );
      }
      // Placa cápsula oscura estilizada según mockup.jpeg:
      plateCol = Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF141F36), Color(0xFF0C1322)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: plateCol,
      );
      if (plateOnly) {
        return Opacity(
          opacity: eliminated ? 0.45 : (isTurn ? 1 : 0.86),
          child: plateCol,
        );
      }
      Widget body;
      if (plateSide == SketchPlateSide.left) {
        body = Row(
          mainAxisSize: MainAxisSize.min,
          children: [plateCol, const SizedBox(width: 6), avatar],
        );
      } else if (plateSide == SketchPlateSide.right) {
        body = Row(
          mainAxisSize: MainAxisSize.min,
          children: [avatar, const SizedBox(width: 6), plateCol],
        );
      } else {
        // RONDA 3 (F3d): la placa SOLAPA el borde inferior del
        // avatar como las rivales (solape ~4 px medido en
        // captura). Con −8 quedaba un hueco de ~5,5 px entre el
        // borde visible del círculo y la placa (el círculo
        // visible es menor que la caja 64 del avatar: el fondo
        // Blobatar no llena la caja); con −18 el solape medido
        // queda en ~4,5 px. Solo la usa el asiento propio (los
        // rivales pintan su placa en un Positioned aparte con
        // −8 sobre un hueco de 2, o sea, solape ~4).
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            Transform.translate(
              offset: const Offset(0, -18),
              child: plateCol,
            ),
          ],
        );
      }
      return Opacity(
        opacity: eliminated ? 0.45 : (isTurn ? 1 : 0.86),
        child: body,
      );
    }
    return Opacity(
      opacity: eliminated ? 0.45 : (isTurn ? 1 : 0.86),
      child: AnimatedScale(
        scale: isTurn && !eliminated && !landscape ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: rowLayout
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    avatar,
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        nameWidget,
                        const SizedBox(height: 2),
                        pipsRow,
                        if (midWidget != null) ...[
                          const SizedBox(height: 2),
                          midWidget,
                        ],
                      ],
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    avatar,
                    SizedBox(height: landscape ? 2 : 3),
                    nameWidget,
                    const SizedBox(height: 1),
          // "EN TURNO" como pastilla llena: se lee de un vistazo
          // incluso en modo compacto (antes era un texto de 12px
          // que se perdía con la consola abierta). En landscape no
          // se muestra (la quita la sentencia); midWidget ya viene
          // resuelto arriba.
          if (midWidget != null) midWidget,
          SizedBox(height: landscape ? 2 : 3),
          pipsRow,
          if (bubbleText != null && !hideBubble && !landscape) ...[
            const SizedBox(height: 5),
            Container(
              constraints: const BoxConstraints(maxWidth: 112),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2434).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: bubbleBid != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DiceFace(value: bubbleBid!.face, size: 22),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            bubbleText!,
                            style: const TextStyle(
                              color: CachoColors.ivory,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      bubbleText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CachoColors.ivory,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            if (bubbleReason != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 118),
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  bubbleReason!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CachoColors.ivory.withValues(alpha: 0.85),
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    height: 1.15,
                  ),
                ),
              ),
          ],
        ],
          ),
        ),
      ),
    );
  }
}


/// Color semáforo del aro-temporizador según la fracción de tiempo que
/// queda en el turno (1 = recién empezado, 0 = vencido): verde mientras
/// queda la mitad o más, amarillo entre la mitad y el último cuarto, y
/// rojo en el último cuarto (con turnos de 60 s: verde 60–30 s, amarillo
/// 30–15 s, rojo los últimos 15 s). Orden del usuario, 24-oct.
Color ringTimeColor(double fraction) {
  if (fraction >= 0.5) return CachoColors.calzoGreen;
  if (fraction >= 0.25) return CachoColors.timeAmber;
  return CachoColors.casinoRed;
}

/// Segundos en los que suena el pitido de apuro en mi turno: los últimos
/// tres segundos (ya en rojo), un pitido por segundo.
bool isBeepSecond(int secondsLeft) => secondsLeft >= 1 && secondsLeft <= 3;

/// Color del círculo del avatar: en su turno, el semáforo del tiempo
/// (el círculo entero —borde y brillo— toma el color, para que el estado
/// se lea de un vistazo y no se confunda con el color de identidad);
/// fuera de turno, el color de identidad del jugador. Corrección del
/// usuario, 24-oct: el arco fino solo se perdía pegado al borde dorado.
Color seatRingColor({
  required Color identity,
  required bool isTurn,
  required double? fraction,
}) {
  if (isTurn && fraction != null) return ringTimeColor(fraction);
  return identity;
}

class _RingPainter extends CustomPainter {
  final double fraction;
  _RingPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..color = CachoColors.gold.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawArc(rect.deflate(2), 0, 6.2832, false, bg);
    final fg = Paint()
      ..color = ringTimeColor(fraction)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect.deflate(2), -1.5708, 6.2832 * fraction.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

/// Dado como cubo isométrico (para el momento 3D del vaso: los dados
/// que quedan sobre la mesa al levantarlo). Cara superior marfil clara
/// con las pipas, laterales sombreados para dar volumen.
class DiceCube extends StatelessWidget {
  final int value;
  final double size;
  const DiceCube({super.key, required this.value, this.size = 30});

  @override
  Widget build(BuildContext context) {
    // Cara plana y grande: los cubos isométricos no se leían en la
    // mesa (corrección del usuario, 22-oct). La cara plana de marfil
    // con pipas grandes se lee a cualquier tamaño.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: DiceFace(value: value, size: size),
    );
  }
}


/// Dado marfil Blender (sprites verificados 22-oct: die_1..6,
/// pipas en las 6 caras, 1 rojo grande). Corrección 25-oct: los
/// dados de MI mano y de la revelación usan estos sprites, no
/// tiles planos (DiceCube/DiceFace quedan para la consola, que
/// son controles, y para el vertical congelado).
class BlenderDie extends StatelessWidget {
  final int value;
  final double size;
  const BlenderDie({super.key, required this.value, this.size = 36});
  @override
  Widget build(BuildContext context) {
    return DiceFace(value: value, size: size);
  }
}

/// Retrato ilustrado de cada bot conocido (lámina duotono recortada).
/// LEGADO, ya no se usa en PlayerSeat: orden del usuario 15:51
/// (25-oct), todos los avatares son Blobatar. Se conserva por si
/// otra vista lo necesita, sin tocar la mesa.
String? botPortraitAsset(String nickname) {
  if (nickname.contains('Guatón')) return 'assets/images/bot_guaton.png';
  if (nickname.contains('Cuca')) return 'assets/images/bot_cuca.png';
  if (nickname.contains('Chalo')) return 'assets/images/bot_chalo.png';
  if (nickname.contains('Pituca')) return 'assets/images/bot_pituca.png';
  if (nickname.contains('Huaso')) return 'assets/images/bot_huaso.png';
  return null;
}

/// Cuenta regresiva de reconexión bajo el nombre del asiento:
/// "⏳ 0:37 para volver", bajando cada segundo hasta que el
/// servidor resuelve (el jugador vuelve o queda eliminado y el
/// estado del asiento cambia solo).
class _DcCountdown extends StatefulWidget {
  final int deadlineMs;

  /// En horizontal (D2) va a 14 px con la hora corta: la frase
  /// completa no cabe en el asiento de 88 px sin tapar vecinos.
  final bool landscape;
  const _DcCountdown({required this.deadlineMs, this.landscape = false});

  @override
  State<_DcCountdown> createState() => _DcCountdownState();
}

class _DcCountdownState extends State<_DcCountdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftMs =
        widget.deadlineMs - DateTime.now().millisecondsSinceEpoch;
    final s = (leftMs / 1000).ceil().clamp(0, 3600);
    final clock = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return Text(
      widget.landscape ? '⏳ $clock' : '⏳ $clock para volver',
      style: TextStyle(
        fontSize: widget.landscape ? 14 : 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFFB74D),
        shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
      ),
    );
  }
}
