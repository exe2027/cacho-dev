import 'dart:math' as math;

import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/match_controller.dart';
import '../state/settings.dart';
import '../texts.dart';
import '../theme.dart';
import 'dice_and_cup.dart';

export 'resolution_overlay.dart';

/// Paleta casino de MENU (sin cafe, 25-oct): fondos oscuros de la
/// familia del buscar_bg (azul noche -> casi negro -> purpura
/// profundo) con dorado mate #C9A24B (CachoColors.gold) como acento.
/// Constantes LOCALES de este archivo: theme.dart la redefine otro
/// agente y no se toca ni se redefine aqui.
const _menuCasinoDialog = Color(0xFF120A24);

String nameOf(MatchController c, String? id) => nameOr(c, id);


/// Placa dorada central con la apuesta vigente (master prompt §6):
/// número enorme, dado de la pinta y de quién es.
class BidPlaque extends StatelessWidget {
  final Bid? bid;
  final String? bidderName;
  const BidPlaque({super.key, required this.bid, required this.bidderName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A6D2F), CachoColors.gold, Color(0xFF8A6D2F)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: bid == null
          ? const Text(
              'Sin apuesta todavía',
              style: TextStyle(
                color: Color(0xFF2B1810),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${bid!.quantity} ×',
                  style: const TextStyle(
                    color: Color(0xFF2B1810),
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(width: 8),
                DiceFace(value: bid!.face, size: 38),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      facePlural(bid!.face),
                      style: const TextStyle(
                        color: Color(0xFF2B1810),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'de ${bidderName ?? ''}',
                      style: TextStyle(
                        color: const Color(0xFF2B1810).withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Cajón con el historial completo, agrupado por ronda.
void showHistorySheet(BuildContext context, MatchController c) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: CachoColors.wood,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) {
      final rounds = c.historyByRound.keys.toList()..sort();
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('HISTORIAL DE LA PARTIDA',
                style: titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            if (rounds.isEmpty)
              const Text('Todavía no hay jugadas.',
                  textAlign: TextAlign.center),
            for (final r in rounds.reversed) ...[
              Text('Ronda $r',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CachoColors.gold,
                      fontSize: 14)),
              for (final e in c.historyByRound[r]!)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 2),
                  child: Row(
                    children: [
                      Text('${nameOf(c, e.playerId)}: ',
                          style: const TextStyle(fontSize: 14)),
                      if (e.bid != null) ...[
                        DiceFace(value: e.bid!.face, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Text(eventLabel(e), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              if (c.resolutionByRound[r] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 3),
                  child: Text(
                    verdictText(c, c.resolutionByRound[r]!),
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: CachoColors.ivory.withValues(alpha: 0.85)),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      );
    },
  );
}

/// "Ver qué cambia": explicación del preset generada desde la config real.
void showPresetInfo(BuildContext context, String presetName, GameConfig cfg) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _menuCasinoDialog,
      title: Text('QUÉ INCLUYE: ${presetName.toUpperCase()}',
          style: titleStyle.copyWith(fontSize: 15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in cfg.describe())
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: CachoColors.gold),
                  const SizedBox(width: 7),
                  Expanded(
                      child: Text(line, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ENTENDIDO',
              style: TextStyle(color: CachoColors.gold)),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Barra de acciones: SIEMPRE visible (master prompt §7). Botones grandes
// con subtítulo; el deshabilitado dice por qué.
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: enabled ? color : const Color(0xFF1B2434),
          borderRadius: BorderRadius.circular(24),
          elevation: enabled ? 3 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: 0.4,
                      color: enabled
                          ? CachoColors.ivory
                          : CachoColors.ivory.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.1,
                      color: enabled
                          ? CachoColors.ivory.withValues(alpha: 0.85)
                          : CachoColors.ivory.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banda azul "X dijo PASO": dudar o calzar el Paso pendiente.
/// Vive en la barra de acciones y también sobre la consola de
/// apuestas (desde que la consola puede abrirse con un Paso
/// pendiente, el desafío tiene que seguir a la vista). En
/// horizontal bosquejo es una FILA sobre la consola (sentencia
/// F4): texto a 14 px, botones de 44 px, colores sólidos sin alfa
/// (CALZO #0E7A4F). La tercera acción —apostar sobre la apuesta
/// anterior— es la propia consola inferior, que sigue habilitada
/// (tiles + APOSTAR) mientras el Paso está pendiente; los botones
/// DUDO/CALZO normales quedan deshabilitados porque resuelven la
/// apuesta anterior y revelarían todas las manos.
class PasoChallengeBar extends StatelessWidget {
  final MatchController controller;
  const PasoChallengeBar({super.key, required this.controller});

  Widget _btn(String label, Color color, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color : color.withValues(alpha: 0.30),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        highlightColor: Colors.black.withValues(alpha: 0.08),
        splashColor: Colors.black.withValues(alpha: 0.08),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: color.withValues(alpha: enabled ? 0.8 : 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  // Tracking 0: con 0,5 "CALZO" medía >54 px y se
                  // partía en dos líneas en la captura 12b.
                  letterSpacing: 0,
                  color: enabled
                      ? CachoColors.ivory
                      : Colors.white.withValues(alpha: 0.5))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: CachoColors.pasoBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CachoColors.pasoBlue),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${nameOf(c, c.pendingPasoId)} dijo PASO. Desafíalo ahora o '
              'sigue jugando y queda firme:',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          _btn('DUDAR PASO', CachoColors.casinoRed, c.doDudoPaso),
          const SizedBox(width: 6),
          _btn('CALZAR PASO', CachoColors.calzoGreen,
              c.canCalzo ? c.doCalzoPaso : null),
        ],
      ),
    );
  }
}

/// Tira VER + reacciones, mesa bosquejo horizontal (paridad
/// docs/19 V1/C9). Vive en la Column de la mesa, JUSTO ENCIMA de
/// la consola (o del borde inferior cuando no hay consola): por
/// construcción no tapa dados, vaso, consola ni barra superior, y
/// la mesa se achica 44 px en vez de quedar tapada. VER (44 px de
/// alto, etiqueta VER + ojo) es el ÚNICO mecanismo de revelación
/// en horizontal; las 5 reacciones son botones de 44 px. En línea
/// las reacciones están deshabilitadas (relay del servidor
/// pendiente; enviar provocaría `mensaje_invalido`): el tooltip lo
/// dice, no se finge que los demás las ven.
class VerEmoteStrip extends StatelessWidget {
  final MatchController controller;
  final bool verOpen;
  final VoidCallback onVerTap;
  const VerEmoteStrip({
    super.key,
    required this.controller,
    required this.verOpen,
    required this.onVerTap,
  });

  static const _labels = {
    '😂': '¡Qué risa!',
    '👏': '¡Bravo!',
    '👍': 'Bien jugado',
    '😮': '¡No puede ser!',
    '🔥': '¡En llamas!',
  };

  @override
  Widget build(BuildContext context) {
    final c = controller;
    // RONDA 2 corrección 2 (F4, medida en captura): fondo
    // TRANSPARENTE (era barra opaca 0xFF14100C de ancho
    // completo). La tira pinta DESPUÉS de la mesa en la Column
    // y su fondo opaco tapaba mi placa, que cuelga bajo mi
    // avatar sobre esta fila (zona central vacía: VER a la
    // izquierda, emotes a la derecha). La píldora VER y los
    // emotes conservan su propio fondo; solo el centro pasa a
    // dejar ver la placa (píldora negra 0,72 sobre fondo oscuro
    // de sala, legible). Sin cambio de alto (44) ni de layout.
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Semantics(
            label: verOpen ? 'Ocultar tus dados' : 'Ver tus dados',
            button: true,
            child: Material(
              color: verOpen ? CachoColors.gold : const Color(0xFF1B2434),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onVerTap,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verOpen
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: verOpen
                            ? const Color(0xFF221A08)
                            : CachoColors.ivory,
                      ),
                      const SizedBox(width: 6),
                      Text('VER',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: verOpen
                                  ? const Color(0xFF221A08)
                                  : CachoColors.ivory)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final glyph in MatchController.emotes)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Tooltip(
                        message: _labels[glyph] ?? glyph,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => c.sendEmote(glyph),
                            child: Center(
                              child: Text(glyph,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reacción flotando sobre un avatar (docs/19 C9). Con el gate de
/// animaciones apagado (interruptor AN17 o reduce-motion del
/// sistema) se dibuja estática, sin subir ni desvanecerse; con el
/// gate encendido sube 28 px y se desvanece en 1,8 s. La retirada
/// la programa la pantalla (`clearEmote`); este widget solo dibuja.
class FloatingEmote extends StatelessWidget {
  final String glyph;
  const FloatingEmote({super.key, required this.glyph});

  @override
  Widget build(BuildContext context) {
    final animOn = Settings.instance.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);

    final isSingleEmoji = glyph.runes.length <= 2 && !glyph.contains(' ');

    final bubble = Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 220, minWidth: 36),
            padding: EdgeInsets.symmetric(
              horizontal: isSingleEmoji ? 10 : 12,
              vertical: isSingleEmoji ? 5 : 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xF2121C2C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CachoColors.gold,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x33D4AF37),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              glyph,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSingleEmoji ? 24 : 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: _BubbleTailPainter(
              color: const Color(0xF2121C2C),
              borderColor: CachoColors.gold,
            ),
          ),
        ],
      ),
    );

    if (!animOn) return bubble;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2400),
      builder: (_, t, child) {
        final scale = (t < 0.15 ? (0.6 + 0.4 * (t / 0.15)) : 1.0).clamp(0.0, 1.1);
        final opacity = (t < 0.75 ? 1.0 : (1.0 - (t - 0.75) / 0.25)).clamp(0.0, 1.0);
        final translateY = -8.0 * t;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: bubble,
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  const _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()..color = color..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

class ActionBar extends StatelessWidget {
  final MatchController controller;
  final VoidCallback onBidTap;
  const ActionBar(
      {super.key, required this.controller, required this.onBidTap});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final myTurn = c.isMyTurn;
    final hasBid = c.currentBid != null;
    final pasoPendingForMe =
        c.pendingPasoId != null && c.pendingPasoId != c.myId && myTurn;

    // ---- motivos / subtítulos ----
    final subirSub = !myTurn
        ? 'Espera tu turno'
        : (hasBid ? 'Arma tu apuesta' : 'Parte la ronda');
    final dudoSub = !hasBid
        ? 'Sin apuesta que dudar'
        : !myTurn
            ? 'Solo en tu turno'
            : 'No te creo';
    final String calzoSub;
    final bool calzoOk;
    if (!hasBid) {
      calzoSub = 'Sin apuesta que calzar';
      calzoOk = false;
    } else if (!c.canCalzo) {
      // Sin umbral de dados desde el 24-oct: lo único que bloquea
      // el Calzo es que la sala lo tenga desactivado.
      calzoSub = 'Calzo desactivado en esta sala';
      calzoOk = false;
    } else if (!myTurn) {
      calzoSub = 'Solo en tu turno';
      calzoOk = false;
    } else if ((c.me?.diceCount ?? 0) >= 5) {
      calzoSub = 'Es exacto: todos los demás pierden 1';
      calzoOk = true;
    } else {
      calzoSub = 'Es exacto';
      calzoOk = true;
    }
    final myPasoUsed =
        c.events.any((e) => e.playerId == c.myId && e.type == 'paso');
    final String pasoSub;
    final bool pasoOk;
    if (!c.uiConfig.pasoEnabled) {
      pasoSub = '';
      pasoOk = false;
    } else if ((c.me?.diceCount ?? 0) != 5) {
      pasoSub = 'Solo con 5 dados';
      pasoOk = false;
    } else if (c.events.isEmpty) {
      pasoSub = 'No como primera jugada';
      pasoOk = false;
    } else if (myPasoUsed) {
      pasoSub = 'Ya pasaste esta ronda';
      pasoOk = false;
    } else if (!myTurn) {
      pasoSub = 'Solo en tu turno';
      pasoOk = false;
    } else {
      pasoSub = 'Mano especial';
      pasoOk = true;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pasoPendingForMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: PasoChallengeBar(controller: c),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionButton(
              label: 'APOSTAR',
              subtitle: subirSub,
              color: const Color(0xFF8A6D2F),
              onTap: myTurn && c.phase == 'playing' ? onBidTap : null,
            ),
            _ActionButton(
              label: 'DUDO',
              subtitle: dudoSub,
              color: CachoColors.casinoRed,
              onTap: myTurn && hasBid ? c.doDudo : null,
            ),
            _ActionButton(
              label: 'CALZO',
              subtitle: calzoSub,
              color: CachoColors.calzoGreen,
              onTap: calzoOk ? c.doCalzo : null,
            ),
            if (c.uiConfig.pasoEnabled)
              _ActionButton(
                label: 'PASO',
                subtitle: pasoSub,
                color: CachoColors.pasoBlue,
                onTap: pasoOk ? c.doPaso : null,
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Panel de apuesta INTEGRADO en la mesa (dirección del usuario, 22-oct):
// nada de ventanas aparte. Al ser mi turno aparece sobre la barra de
// acciones, la mesa sigue visible y mis dados se comparan en vivo con
// la pinta elegida: los que cuentan se encienden en dorado.
// ---------------------------------------------------------------------------

class BidDock extends StatefulWidget {
  final MatchController controller;
  final VoidCallback onClose;

  /// El vaso está levantado (mis dados a la vista) y su conmutador.
  final bool peeked;
  final VoidCallback? onPeek;

  /// Avisa la pinta que se está armando (para encender mis dados
  /// que cuentan sobre la mesa) o null si no hay ninguna.
  final ValueChanged<int?>? onArmedFaceChanged;

  const BidDock({
    super.key,
    required this.controller,
    required this.onClose,
    this.peeked = false,
    this.onPeek,
    this.onArmedFaceChanged,
  });

  @override
  State<BidDock> createState() => _BidDockState();
}

/// Consola de apuesta (solución del usuario, 22-oct): la apuesta se
/// ARMA tocando los dados de pintas — cada toque suma 1 a esa cara y
/// tocar otra cara reinicia la cuenta en 1. Sin botones − / +.
class _BidDockState extends State<BidDock> with SingleTickerProviderStateMixin {
  int? _face;
  int _count = 0;
  late final AnimationController _pulse;

  MatchController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Bid? get _armed => _face == null ? null : Bid(_count, _face!);

  bool _isLegal(Bid b) =>
      GameEngine.raiseError(c.currentBid, b, c.totalDice,
          acesRuleEnabled: c.uiConfig.acesRuleEnabled) ==
      null;

  String? get _armedError {
    final a = _armed;
    if (a == null) return null;
    return GameEngine.raiseError(c.currentBid, a, c.totalDice,
        acesRuleEnabled: c.uiConfig.acesRuleEnabled);
  }

  bool get _legal => _armed != null && _armedError == null;

  bool _counts(int die) =>
      _face != null &&
      (die == _face ||
          (_face != 1 && c.uiConfig.wildcardsEffective && die == 1));

  int get _myCount => _face == null ? 0 : c.myHand.where(_counts).length;

  /// Menor cantidad legal para una pinta (con la regla de los ases).
  int? _minQtyFor(int face) {
    for (var q = 1; q <= c.totalDice; q++) {
      if (_isLegal(Bid(q, face))) return q;
    }
    return null;
  }

  /// La subida mínima posible desde la apuesta actual (sin cara
  /// elegida todavía): para la ficha informativa.
  Bid? get _minRaiseAny {
    final cur = c.currentBid;
    if (cur == null) return null;
    for (var f = cur.face + 1; f <= 6; f++) {
      final b = Bid(cur.quantity, f);
      if (_isLegal(b)) return b;
    }
    if (cur.face != 1) {
      final b = Bid((cur.quantity / 2).ceil(), 1);
      if (_isLegal(b)) return b;
    }
    for (var q = cur.quantity + 1; q <= c.totalDice; q++) {
      for (var f = 1; f <= 6; f++) {
        final b = Bid(q, f);
        if (_isLegal(b)) return b;
      }
    }
    return null;
  }

  void _tapFace(int face) {
    if (_face == face) {
      if (_count >= c.totalDice) {
        // Tope: vibra y no suma más.
        HapticFeedback.heavyImpact();
        return;
      }
      setState(() => _count++);
    } else {
      setState(() {
        _face = face;
        _count = 1;
      });
    }
    HapticFeedback.lightImpact();
    _pulse.forward(from: 0);
    widget.onArmedFaceChanged?.call(_face);
  }

  void _clear() {
    if (_face == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _face = null;
      _count = 0;
    });
    widget.onArmedFaceChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final cur = c.currentBid;
    final opening = cur == null;
    final minForFace = _face == null ? null : _minQtyFor(_face!);
    final Bid? minShown = _face != null
        ? (minForFace == null ? null : Bid(minForFace, _face!))
        : _minRaiseAny;
    final missing = (_face != null && minForFace != null && _count < minForFace)
        ? minForFace - _count
        : 0;
    // B12 (sentencia v2.0): el chip de probabilidad se APAGA en
    // Kamikaze a ciegas (un % derivado de dados no vistos filtra
    // la mano) y solo informa de la apuesta armada, nunca
    // recomienda jugada.
    final blind = c.phase == 'kamikazeOffer' || c.phase == 'kamikazeChoice';
    final prob = Settings.instance.beginnerHelp && _legal && !blind
        ? c.estimateFor(_armed!)
        : null;
    // B11 (sentencia v2.0): atajos dentro de la consola, sin subir
    // su altura: +1 cantidad (misma pinta) y pinta mayor (misma
    // cantidad). Solo se muestran cuando la subida es legal.
    final plusOneLegal = _armed != null &&
        _count < c.totalDice &&
        _isLegal(Bid(_count + 1, _face!));
    int? nextFaceSameCount;
    if (_armed != null) {
      for (var f = _face! + 1; f <= 6; f++) {
        if (_isLegal(Bid(_count, f))) {
          nextFaceSameCount = f;
          break;
        }
      }
    }
    final myPasoUsed =
        c.events.any((e) => e.playerId == c.myId && e.type == 'paso');
    final pasoOk = c.uiConfig.pasoEnabled &&
        (c.me?.diceCount ?? 0) == 5 &&
        c.events.isNotEmpty &&
        !myPasoUsed;
    final calzoOk = cur != null && c.canCalzo;
    final pulseScale = 1 + 0.09 * math.sin(_pulse.value * math.pi);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: navyCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Tu apuesta',
                  style: TextStyle(
                      fontFamily: CachoFonts.hand,
                      fontSize: 24,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.white70,
                onPressed: widget.onClose,
              ),
            ],
          ),
          // Ficha en una línea: apuesta actual con autor | mínimo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: cur == null
                      ? const Text('Partes tú: sin apuesta previa',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600))
                      : Row(
                          children: [
                            DiceFace(value: cur.face, size: 22),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${cur.quantity} ${facePlural(cur.face)} · de ${c.lastBidderId == null ? '—' : shortNameOf(c, c.lastBidderId!)}',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                if (minShown != null) ...[
                  Text('mín.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55))),
                  const SizedBox(width: 5),
                  DiceFace(value: minShown.face, size: 22),
                  const SizedBox(width: 5),
                  Text('${minShown.quantity} ${facePlural(minShown.face)}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 9),
          // Las seis pintas: cada toque suma 1 a esa cara
          Row(
            children: [
              for (var f = 1; f <= 6; f++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tapFace(f),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _face == f
                                  ? CachoColors.gold
                                  : Colors.transparent,
                              width: 2.4,
                            ),
                            boxShadow: _face == f
                                ? [
                                    BoxShadow(
                                      color: CachoColors.gold
                                          .withValues(alpha: 0.45),
                                      blurRadius: 10,
                                    )
                                  ]
                                : null,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Opacity(
                                opacity: (f == 1 && opening) ? 0.4 : 1,
                                child: DiceFace(value: f, size: 48),
                              ),
                              if (_face == f)
                                Positioned(
                                  top: -7,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CachoColors.gold,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text('tienes $_myCount',
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF141B28))),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(faceName(f),
                            style: TextStyle(
                                fontSize: 9.5,
                                color: _face == f
                                    ? CachoColors.gold
                                    : Colors.white60,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          // La apuesta que se está armando, en grande + Borrar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => Transform.scale(
                      scale: pulseScale,
                      alignment: Alignment.centerLeft,
                      child: _armed == null
                          ? const Text('Toca un dado para armar tu apuesta',
                              style: TextStyle(
                                  fontSize: 13.5, color: Colors.white54))
                          : Row(
                              children: [
                                Text('$_count × ',
                                    style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800)),
                                DiceFace(value: _face!, size: 27),
                                const SizedBox(width: 7),
                                Text(facePlural(_face!),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                ),
                if (plusOneLegal)
                  _AtajoChip(
                    label: '+1',
                    tip: 'Subir una cantidad en la misma pinta',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _count++);
                      _pulse.forward(from: 0);
                    },
                  ),
                if (nextFaceSameCount != null)
                  _AtajoChip(
                    label: '▲',
                    tip: 'Misma cantidad, pinta mayor',
                    onTap: () {
                      final f = nextFaceSameCount!;
                      HapticFeedback.lightImpact();
                      setState(() => _face = f);
                      _pulse.forward(from: 0);
                      widget.onArmedFaceChanged?.call(f);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.undo, size: 21),
                  color: _armed == null ? Colors.white24 : Colors.white,
                  tooltip: 'Borrar',
                  onPressed: _armed == null ? null : _clear,
                ),
              ],
            ),
          ),
          // Línea de ayuda: error en rojo o chip de probabilidad
          // (B12: chip de 44 px, texto ≥14 px, dorado con texto
          // oscuro para contraste ≥4.5:1, explicación en línea).
          if (prob != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Center(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: CachoColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      'Prob. de verdad ≈ ${(prob * 100).round()}% con tus dados',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF221A08)),
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 20,
              child: Center(
                child: _armedError != null && missing == 0
                    ? Text(_armedError!,
                        // R34: motivo del bloqueo a 14 px (antes 11,5).
                        style: const TextStyle(
                            color: Color(0xFFFF8A7A), fontSize: 14))
                    : const SizedBox.shrink(),
              ),
            ),
          // Trillizos del mismo tamaño: DUDO / CALZO / PASO
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (cur != null) ...[
                  Expanded(
                    child: _MiniAction(
                      label: 'DUDO',
                      color: const Color(0xFFB3202A),
                      onTap: c.doDudo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniAction(
                      label: 'CALZO',
                      color: CachoColors.calzoGreen,
                      onTap: calzoOk ? c.doCalzo : null,
                    ),
                  ),
                ],
                if (cur != null && c.uiConfig.pasoEnabled)
                  const SizedBox(width: 8),
                if (c.uiConfig.pasoEnabled)
                  Expanded(
                    child: _MiniAction(
                      label: 'PASO',
                      color: CachoColors.pasoBlue,
                      onTap: pasoOk ? c.doPaso : null,
                    ),
                  ),
              ],
            ),
          ),
          // Confirmación: VER | APOSTAR
          Row(
            children: [
              _SideAction(
                icon: widget.peeked
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                label: 'VER',
                subtitle: 'tus dados',
                onTap: widget.onPeek,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  // R33 (3.er sitio): APOSTAR dorado mate con texto
                  // oscuro, también en la consola vertical congelada
                  // (solo color; geometría H17 intacta).
                  color: _legal
                      ? CachoColors.gold
                      : CachoColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(22),
                  elevation: _legal ? 5 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    highlightColor: Colors.black.withValues(alpha: 0.08),
                    splashColor: Colors.black.withValues(alpha: 0.08),
                    onTap: _legal
                        ? () {
                            widget.onClose();
                            c.doBid(_armed!);
                          }
                        : null,
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _armed == null
                                ? 'APOSTAR'
                                : 'Apostar $_count × ${facePlural(_face!)}',
                            style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: _legal
                                    ? CachoColors.wood
                                    : Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 0.4),
                          ),
                          if (missing > 0)
                            // R34: el motivo del bloqueo se lee a 14 px
                            // (antes 10,5 px; único cambio en vertical
                            // además del color R33).
                            Text(
                              'Faltan $missing para llegar a $minForFace ${facePlural(_face!)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Consola inferior de la mesa bosquejo (sentencia F4): UNA sola
/// barra de 72 px (64 en compacto) con sprites reales.
/// Tiles 52×64 (tile_1..6.png, 104×128 nativos) con el NÚMERO
/// puesto por el código en la zona inferior libre del sprite;
/// CALZO/DUDO/PASO 127×48 (btn_*.png, 254×96 nativos; variante
/// _off.png cuando están deshabilitados) con icono-widget
/// encima del sprite (icon_dado.png en CALZO/DUDO,
/// icon_pausa.png en PASO) y TEXTO a 14 px puesto por el código,
/// nunca quemado en la imagen. Orden de fidelidad: tiles 1–6,
/// CALZO, DUDO, PASO, ▲, APOSTAR, X. Las tiles SON los controles
/// (toque +1, otra pinta reinicia en 1, tope = dados totales,
/// legalidad vía raiseError). Con Paso pendiente, DUDO/CALZO
/// normales quedan deshabilitados y tiles + APOSTAR habilitados
/// (apostar = seguir, el Paso queda firme). La armada vive en
/// GameScreen (una sola fuente); plegar con X nunca la borra.
/// MEDIDA A 390 PX (25-oct, verificado, NO CABE en una fila):
/// padding 16 + tiles 312 + gaps 20 + gap 8 + botones 381 +
/// gaps 12 + gap 8 + ▲ 44 + gap 6 + APOSTAR ~180 (peor caso
/// "Apostar 60 × Sextas" a 14 px) + gap 8 + X 44 = 1039 px;
/// desborde 649 px (sin ▲: 995 px, desborde 605 px; con APOSTAR
/// a ancho 0 seguiría sobrando 469 px). Nunca se baja de 44 px
/// de alto ni de 14 px de texto y nunca se solapa nada: la fila
/// es desplazable en horizontal hasta que el usuario decida
/// (PREGUNTA ABIERTA: ¿dos filas, desplazamiento, o recorte de
/// tamaños? Recortar solo botones 127→62 ahorra 195 px y no
/// basta; haría falta recortar ~605 px en total).
class BottomBidBar extends StatelessWidget {
  final MatchController controller;
  final Bid? armed;
  final ValueChanged<Bid?> onArmedChanged;
  final VoidCallback onFold;
  final bool compact;
  const BottomBidBar({
    super.key,
    required this.controller,
    required this.armed,
    required this.onArmedChanged,
    required this.onFold,
    this.compact = false,
  });

  MatchController get c => controller;

  bool _isLegal(Bid b) =>
      GameEngine.raiseError(c.currentBid, b, c.totalDice,
          acesRuleEnabled: c.uiConfig.acesRuleEnabled) ==
      null;

  String? get _armedError {
    final a = armed;
    if (a == null) return null;
    return GameEngine.raiseError(c.currentBid, a, c.totalDice,
        acesRuleEnabled: c.uiConfig.acesRuleEnabled);
  }

  bool get _legal => armed != null && _armedError == null;

  void _tapFace(int face) {
    final a = armed;
    if (a != null && a.face == face) {
      if (a.quantity >= c.totalDice) {
        HapticFeedback.heavyImpact();
        return;
      }
      HapticFeedback.lightImpact();
      onArmedChanged(Bid(a.quantity + 1, face));
    } else {
      HapticFeedback.lightImpact();
      onArmedChanged(Bid(1, face));
    }
  }

  // Botón de acción con sprite real 127×48 como fondo, el icono
  // va como widget encima del sprite y el TEXTO lo pone el código
  // a 14 px (nunca quemado en la imagen). CORRECCIÓN 26-oct: caja
  // 96×48 (antes 127): el sprite se comprime en horizontal (es un
  // fondo degradado sin texto, no se deforma información) para que
  // la fila completa quepa en 844 sin scroll. Icono 18 + gap 4 +
  // "CALZO" ~40 = ~62 px < 96, cabe en una línea sin partirse.
  // RONDA 2 (F7): EN TODOS LOS ESTADOS el botón lleva el mismo
  // sprite a color (CALZO #0E7A4F, DUDO #B3202A, PASO #14586B
  // vigentes, regenerados) con cara e icono: deshabilitado ya NO
  // cambia a la variante _off oscura (que perdía el relleno), sino
  // que el mismo sprite se vela con negro al 45 % y el texto baja
  // al 75 %: se lee, se distingue como deshabilitado y nada se
  // mueve al cambiar de estado. Los sprites _off quedan sin uso
  // en esta consola (se conservan regenerados por si otra vista
  // los pide).
  Widget _action(String label, String assetOn, String iconAsset,
      VoidCallback? onTap) {
    final enabled = onTap != null;
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 96,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    assetOn,
                    fit: BoxFit.fill,
                  ),
                ),
                if (!enabled)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Distintivo del icono (pulido área 4): círculo
                    // oscuro sutil detrás del icono, mismo tamaño
                    // en habilitado y deshabilitado para que nada
                    // se mueva al cambiar de estado. Sube el
                    // contraste del icono blanco (dado/pausa) sobre
                    // el sprite de color sin tocar el sprite ni el
                    // texto: fondo negro al 28% sobre el rojo de
                    // DUDO pasa el icono de ~4,1:1 a ~6,4:1, y sobre
                    // el verde de CALZO de ~3,2:1 a ~5,3:1 (medido
                    // sobre los RGB medios de los sprites, icono
                    // blanco medio 218; PASO ~4,5:1 a ~6,8:1).
                    // RONDA 2: deshabilitado baja al 80 % (no al
                    // 55 %): el velo negro sobre el sprite ya
                    // marca el estado y el icono debe seguir
                    // leyéndose.
                    Opacity(
                      opacity: enabled ? 1 : 0.8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black
                              .withValues(alpha: enabled ? 0.28 : 0.20),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: enabled ? 0.25 : 0.15),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(iconAsset, width: 18, height: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Tope 60 px con elipsis: "CALZO" a 14 px mide
                    // ~50 con Montserrat; el tope solo actúa si la
                    // fuente de respaldo (más ancha) lo supera, y
                    // así la fila de 96 nunca desborda 4 px por la
                    // fuente (visto en test de widget).
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                              color: enabled
                                  ? CachoColors.ivory
                                  : Colors.white.withValues(alpha: 0.75))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = c.currentBid;
    final a = armed;
    final myPasoUsed =
        c.events.any((e) => e.playerId == c.myId && e.type == 'paso');
    final pasoOk = c.uiConfig.pasoEnabled &&
        (c.me?.diceCount ?? 0) == 5 &&
        c.events.isNotEmpty &&
        !myPasoUsed;
    final pasoPendingForMe =
        c.pendingPasoId != null && c.pendingPasoId != c.myId && c.isMyTurn;
    final calzoOk = cur != null && c.canCalzo && !pasoPendingForMe;
    final dudoOk = cur != null && !pasoPendingForMe;
    int? nextFaceSameCount;
    if (a != null) {
      for (var f = a.face + 1; f <= 6; f++) {
        if (_isLegal(Bid(a.quantity, f))) {
          nextFaceSameCount = f;
          break;
        }
      }
    }
    // RONDA 2 (F7/F12): CONTENEDOR ÚNICO REDONDEADO (esquinas
    // superiores 16 px, filete dorado superior sutil) con tiles
    // 1–6 + CALZO + DUDO + PASO (+ ▲, APOSTAR y Cerrar, que
    // quedan aparte como hoy: APOSTAR NO se mueve a la barra,
    // P1 pendiente). Alto 58 en ambos modos (era 64/72):
    // padding vertical 4 + contenido 50 = 58 exactos, sin fila
    // cortada por el borde inferior. Con la tira VER (44) la
    // zona inferior totaliza 102 px = 26,2 % de 390 (era
    // 116 px = 29,7 %) y la mesa sube a 232 px = 59,5 % (F12).
    // RONDA 3 (F3b): el grupo tiles + acciones + ▲ queda
    // CENTRADO en el espacio que dejan APOSTAR + Cerrar, sin
    // mover APOSTAR (P1 pendiente: APOSTAR sigue en la consola,
    // no sube a la barra; su inicio queda en x 636, como antes).
    // La fila completa mide 844 px exactos (padding 10 + 8,
    // tiles 6×44 + gaps 3 = 279, +6, acciones 3×96 + gaps 4 =
    // 296, +6, ▲ 36, +3, APOSTAR 150, +6, Cerrar 44): tiles
    // 10..289 (1,2 %..34,2 %), acciones 295..591 (35,0 %..70,0 %),
    // APOSTAR 636..786, Cerrar 792..836. El ejemplo (tiles
    // ~13 %, acciones 51–93 %) NO se alcanza: el grupo ya ocupa
    // 623 de los 628 px libres (98 %), así que centrarlo solo
    // mueve +2 px; llegar al ejemplo exigiría recortar APOSTAR
    // en ≥ 98 px o moverlo (P1), no autorizado aquí. El scroll
    // horizontal se conserva como red de seguridad (pantallas
    // más angostas), no como vía de acceso.
    // Precisión medida en test: el filete superior de 0,5 px
    // vive DENTRO del alto 58, así que el contenido real es
    // 49,5 (no 50): las tiles pintan 44×49,5, blanco táctil
    // intacto (≥ 44) y la zona inferior sigue en 102 px.
    return Container(
      height: 58,
      padding:
          const EdgeInsets.only(left: 10, right: 8, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF14100C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: CachoColors.gold, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var f = 1; f <= 6; f++) ...[
                  if (f > 1) const SizedBox(width: 3),
                  // Semántica con nombre de pinta: las tiles son
                  // DiceFace (CustomPaint, sin texto) y sin esto no
                  // tienen nombre accesible ni clic por etiqueta.
                  // Tile con sprite real 52×64: la pinta la trae el
                  // sprite y el NÚMERO lo pone el código en la zona
                  // inferior libre (fondo negro del sprite, texto
                  // marfil a 14 px, nunca quemado en la imagen).
                  Semantics(
                    label: faceName(f),
                    button: true,
                    child: GestureDetector(
                      onTap: () => _tapFace(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        // RONDA 2 (F7/F12): tile 44×50 (era 40×50):
                        // 44 px de blanco táctil en ambos ejes
                        // (50 de alto) y la fila sigue cabiendo
                        // en 844 (843 px medidos, ver cabecera).
                        // El número sigue a 14 px y el sprite se
                        // comprime (fondo sin texto quemado).
                        width: 44,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: a?.face == f
                                ? CachoColors.gold
                                : Colors.transparent,
                            width: 2.4,
                          ),
                          boxShadow: a?.face == f
                              ? [
                                  BoxShadow(
                                    color: CachoColors.gold
                                        .withValues(alpha: 0.55),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: CachoColors.gold
                                        .withValues(alpha: 0.25),
                                    blurRadius: 18,
                                  ),
                                ]
                              : null,
                        ),
                        // Pulido tiles (área 5): el sprite queda
                        // recortado al radio del borde (antes sus
                        // esquinas cuadradas sobresalían del borde
                        // redondeado). RONDA 2 (F7): la cara del
                        // tile se mantiene EN TODOS los estados:
                        // el As sin apuesta vigente solo baja a
                        // 0,8 (era 0,4, casi invisible) y el número
                        // queda siempre a opacidad plena, para que
                        // el tile no desaparezca y el 1 siga
                        // legible; el número lleva pastilla negra
                        // sutil + sombra para que se lea a 390 px
                        // sin confundirse con las pintas del dado
                        // (14 px w800, sin tocar el sprite).
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: (f == 1 && cur == null) ? 0.8 : 1,
                                  child: Image.asset(
                                    'assets/images/tile_$f.png',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: a?.face == f
                                            ? CachoColors.gold
                                                .withValues(alpha: 0.7)
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text('$f',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: CachoColors.ivory,
                                            shadows: [
                                              Shadow(
                                                  color: Colors.black,
                                                  offset: Offset(0, 1),
                                                  blurRadius: 3),
                                              Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 6),
                                            ])),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 6),
            _action(
                'CALZO',
                'assets/images/btn_calzo.png',
                'assets/images/icon_dado.png',
                calzoOk ? c.doCalzo : null),
            const SizedBox(width: 4),
            _action(
                'DUDO',
                'assets/images/btn_dudo.png',
                'assets/images/icon_dado.png',
                dudoOk ? c.doDudo : null),
            const SizedBox(width: 4),
            _action(
                'PASO',
                'assets/images/btn_paso.png',
                'assets/images/icon_pausa.png',
                pasoOk ? c.doPaso : null),
            const SizedBox(width: 6),
            if (nextFaceSameCount != null)
              Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onArmedChanged(Bid(a!.quantity, nextFaceSameCount!));
                  },
                  child: const SizedBox(
                    width: 36,
                    height: 48,
                    child: Center(
                      child: Text('▲',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: CachoColors.ivory)),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 36),
            // RONDA 3 (F3b): 3 (era 4) para que APOSTAR siga
            // empezando en x 636 con el padding izquierdo en 10.
            const SizedBox(width: 3),
            // Ancho fijo (no Expanded: dentro del scroll horizontal
            // no hay ancho acotado): 150 px cubren el peor caso con
            // máx 6 jugadores ("Apostar 30 × Sextas" a 14 px; el 60
            // del comentario viejo era para 12 jugadores); el texto
            // elide si un caso mayor apareciera, sin bajar de 14 px
            // ni de 48 px.
            SizedBox(
              width: 150,
              child: Material(
                color: _legal
                    ? CachoColors.gold
                    : CachoColors.gold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(22),
                elevation: _legal ? 5 : 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  highlightColor: Colors.black.withValues(alpha: 0.08),
                  splashColor: Colors.black.withValues(alpha: 0.08),
                  onTap: _legal ? () => c.doBid(a!) : null,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(
                      a == null
                          ? 'APOSTAR'
                          : 'Apostar ${a.quantity} × ${facePlural(a.face)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _legal
                              ? CachoColors.wood
                              : Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: const Icon(Icons.close, size: 22),
                color: Colors.white70,
                tooltip: 'Cerrar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onFold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel "Tu apuesta" (sentencia F4, enmienda 11a; ÁREA 9):
/// ESPEJO de la armada/vigente, nunca segunda armada ni overlay:
/// vive como fila JUSTO ENCIMA de la consola (después de la mesa,
/// antes de BottomBidBar, hermana de PasoChallengeBar), plegado por
/// defecto, toggle dorado 44×44 junto a la consola. Su [armed] ES
/// la misma _consoleArmed que alimenta a BottomBidBar: un solo
/// estado, sin duplicar. No añade mano, probabilidad, saldo ni
/// cifras; no borra ni resetea al plegar/desplegar. Altura ~38
/// (≤50) para que el óvalo resultante no caiga bajo el compacto
/// medido (212) a 390: 390 − 56 barra − 38 panel − 72 consola =
/// 224 de mesa. El llamador deja 56 px a la izquierda cuando está
/// desplegado para que el toggle (left 8 + 44) no tape su texto.
class TuApuestaStrip extends StatelessWidget {
  final MatchController controller;
  final Bid? armed;
  const TuApuestaStrip(
      {super.key, required this.controller, required this.armed});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cur = c.currentBid;
    final a = armed;
    String? armedError;
    int missing = 0;
    if (a != null) {
      armedError = GameEngine.raiseError(c.currentBid, a, c.totalDice,
          acesRuleEnabled: c.uiConfig.acesRuleEnabled);
      int? minQty;
      for (var q = 1; q <= c.totalDice; q++) {
        if (GameEngine.raiseError(c.currentBid, Bid(q, a.face), c.totalDice,
                acesRuleEnabled: c.uiConfig.acesRuleEnabled) ==
            null) {
          minQty = q;
          break;
        }
      }
      if (minQty != null && a.quantity < minQty) {
        missing = minQty - a.quantity;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1209),
        border: Border(
          top: BorderSide(color: CachoColors.gold, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text('Tu apuesta',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CachoColors.gold)),
          const SizedBox(width: 10),
          if (cur == null)
            const Text('Partes tú: sin apuesta previa',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DiceFace(value: cur.face, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${cur.quantity} ${facePlural(cur.face)} · de ${c.lastBidderId == null ? '—' : shortNameOf(c, c.lastBidderId!)}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const Spacer(),
          if (a == null)
            const Text('sin armar',
                style: TextStyle(fontSize: 14, color: Colors.white54))
          else if (armedError != null)
            // Nunca el código crudo del motor ('apuesta_no_supera',
            // captura 12_panel): la misma información en frase.
            const Flexible(
              child: Text('No supera la apuesta vigente',
                  style: TextStyle(fontSize: 14, color: Color(0xFFFF8A7A)),
                  overflow: TextOverflow.ellipsis),
            )
          else if (missing > 0)
            Text('Faltan $missing para llegar',
                style: const TextStyle(fontSize: 14, color: Colors.white70))
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${a.quantity} × ',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                DiceFace(value: a.face, size: 22),
                const SizedBox(width: 4),
                Text(facePlural(a.face),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chip de probabilidad de 44 px (sentencia F4): solo si ayuda de
/// principiante, apuesta armada legal y NO Kamikaze a ciegas. Vive
/// como fila propia sobre la consola (nunca dentro del presupuesto
/// de 810 de la barra).
class ProbChip extends StatelessWidget {
  final double prob;
  const ProbChip({super.key, required this.prob});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CachoColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          'Prob. de verdad ≈ ${(prob * 100).round()}% con tus dados',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF221A08)),
        ),
      ),
    );
  }
}

/// Barra mínima plegada de la mesa horizontal (H9/O4, prototipo
/// local): 44 px abajo, DUDO/CALZO/PASO/APOSTAR en ese orden, la
/// apuesta armada siempre visible junto a APOSTAR y botón de
/// desplegar separado de APOSTAR. Plegar/desplegar nunca cancela,
/// cobra ni modifica la armada (vive en GameScreen).
class FoldedActionBar extends StatelessWidget {
  final MatchController controller;
  final Bid? armed;
  final VoidCallback onUnfold;

  const FoldedActionBar({
    super.key,
    required this.controller,
    required this.armed,
    required this.onUnfold,
  });

  MatchController get c => controller;

  @override
  Widget build(BuildContext context) {
    final cur = c.currentBid;
    final a = armed;
    final legal = a != null &&
        GameEngine.raiseError(c.currentBid, a, c.totalDice,
                acesRuleEnabled: c.uiConfig.acesRuleEnabled) ==
            null;
    final myPasoUsed =
        c.events.any((e) => e.playerId == c.myId && e.type == 'paso');
    final pasoOk = c.uiConfig.pasoEnabled &&
        (c.me?.diceCount ?? 0) == 5 &&
        c.events.isNotEmpty &&
        !myPasoUsed;
    final calzoOk = cur != null && c.canCalzo;
    // R33/R34: igual sistema que _MiniAction (color pleno + marfil;
    // deshabilitado 30 % + texto 50 %; presionado 8 % más oscuro).
    Widget mini(String label, Color color, VoidCallback? onTap) {
      final enabled = onTap != null;
      return Material(
        color: enabled ? color : color.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          highlightColor: Colors.black.withValues(alpha: 0.08),
          splashColor: Colors.black.withValues(alpha: 0.08),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: color.withValues(alpha: enabled ? 0.8 : 0.3)),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: enabled
                        ? CachoColors.ivory
                        : Colors.white.withValues(alpha: 0.5))),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF14100C),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            color: Colors.white70,
            tooltip: 'Desplegar consola',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onUnfold,
          ),
          const SizedBox(width: 6),
          if (cur != null) ...[
            mini('DUDO', const Color(0xFFB3202A), c.doDudo),
            const SizedBox(width: 6),
            mini('CALZO', CachoColors.calzoGreen, calzoOk ? c.doCalzo : null),
            const SizedBox(width: 6),
          ],
          if (c.uiConfig.pasoEnabled) ...[
            mini('PASO', CachoColors.pasoBlue, pasoOk ? c.doPaso : null),
            const SizedBox(width: 6),
          ],
          if (a != null) ...[
            DiceFace(value: a.face, size: 22),
            const SizedBox(width: 4),
            Text('${a.quantity} × ${facePlural(a.face)}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Material(
              // R33 (3.er sitio): APOSTAR dorado mate con texto oscuro.
              color: legal
                  ? CachoColors.gold
                  : CachoColors.gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                highlightColor: Colors.black.withValues(alpha: 0.08),
                splashColor: Colors.black.withValues(alpha: 0.08),
                onTap: legal ? () => c.doBid(a) : null,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(
                    a == null
                        ? 'APOSTAR'
                        : 'Apostar ${a.quantity} × ${facePlural(a.face)}',
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: legal
                            ? CachoColors.wood
                            : Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de atajo de la consola (B11): 44 × 44, dorado translúcido,
/// dentro de la fila de la apuesta armada (sin subir la consola).
class _AtajoChip extends StatelessWidget {
  final String label;
  final String tip;
  final VoidCallback onTap;
  const _AtajoChip({
    required this.label,
    required this.tip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tip,
        child: Material(
          color: CachoColors.gold.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 46,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: CachoColors.gold.withValues(alpha: 0.55)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CachoColors.gold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción secundaria compacta de la consola (DUDO / CALZO / PASO).
/// R33/R34 (rediseño completo): normal = color pleno con texto
/// marfil; presionado = 8 % más oscuro (overlay InkWell, sin cambio
/// de tamaño); deshabilitado = color al 30 % + texto al 50 %, sin
/// desaparecer ni moverse (exento del 4,5:1 solo porque el motivo
/// del bloqueo se lee a 14 px en otro elemento: la caja de mensaje
/// de la consola). PASO usa petróleo, no dorado (R33: el dorado
/// queda solo para APOSTAR).
class _MiniAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MiniAction({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color : color.withValues(alpha: 0.30),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        highlightColor: Colors.black.withValues(alpha: 0.08),
        splashColor: Colors.black.withValues(alpha: 0.08),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: enabled ? 0.8 : 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: enabled
                      ? CachoColors.ivory
                      : Colors.white.withValues(alpha: 0.5))),
        ),
      ),
    );
  }
}

/// Botón lateral de la fila de confirmación (VER / DUDO).
class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  const _SideAction(
      {required this.icon,
      required this.label,
      required this.subtitle,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: const Color(0xFF1B2434).withValues(alpha: enabled ? 1 : 0.55),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SizedBox(
          width: 84,
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 19, color: enabled ? Colors.white : Colors.white38),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: enabled ? Colors.white : Colors.white38)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 9,
                      color: enabled ? Colors.white54 : Colors.white24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kamikaze: oferta entre rondas y rueda de números (master prompt §2.9)
// ---------------------------------------------------------------------------

class KamikazeBar extends StatelessWidget {
  final MatchController controller;
  const KamikazeBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.phase == 'kamikazeOffer') {
      final mine = c.kamikazeOfferId == c.myId;
      return _KamikazeShell(
        child: mine
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¡TU MOMENTO KAMIKAZE!',
                      style: TextStyle(
                          fontFamily: CachoFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xFFFF8A8A),
                          letterSpacing: 1.4)),
                  const SizedBox(height: 4),
                  const Text(
                    'Te quedó 1 dado y eres el único. Si aceptas, eliges un '
                    'número y TODOS pierden los dados con ese número. '
                    'Es tu única oportunidad de la partida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BronzeButton(
                        label: '¡KAMIKAZE!',
                        color: CachoColors.casinoRed,
                        onPressed: () => c.respondKamikaze(true),
                      ),
                      const SizedBox(width: 10),
                      BronzeButton(
                        label: 'PASAR (nunca más)',
                        color: CachoColors.burgundy,
                        onPressed: () => c.respondKamikaze(false),
                      ),
                    ],
                  ),
                ],
              )
            : Text(
                '${nameOf(c, c.kamikazeOfferId)} está decidiendo su Kamikaze…',
                style: const TextStyle(fontSize: 14),
              ),
      );
    }
    if (c.phase == 'kamikazeChoice') {
      final mine = c.kamikazeActivatorId == c.myId;
      return _KamikazeShell(
        child: mine
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ELIGE EL NÚMERO QUE CAE',
                      style: TextStyle(
                          fontFamily: CachoFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFFFF8A8A),
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var f = 1; f <= 6; f++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () => c.chooseKamikazeFace(f),
                            child:
                                DiceFace(value: f, size: 44, showBadge: true),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // RONDA 2 (F8): texto secundario Kamikaze a 14 px
                  // (era 12,5): la barra crece ~2 px y la mesa
                  // (Expanded) lo absorbe sin romper nada.
                  const Text(
                    'Todos lanzan de nuevo, tú también. Sin comodines. '
                    'Nadie ve sus dados hasta que elijas.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              )
            : Text(
                '¡KAMIKAZE! ${nameOf(c, c.kamikazeActivatorId)} está '
                'eligiendo el número… Nadie puede ver sus dados todavía.',
                style: const TextStyle(fontSize: 14),
              ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _KamikazeShell extends StatelessWidget {
  final Widget child;
  const _KamikazeShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0508).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CachoColors.casinoRed, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: CachoColors.casinoRed.withValues(alpha: 0.35),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
