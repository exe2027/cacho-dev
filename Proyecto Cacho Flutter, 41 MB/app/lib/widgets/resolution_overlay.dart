import 'dart:async';
import 'dart:math' as math;
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';

import '../state/match_controller.dart';
import '../state/wallet.dart';
import '../texts.dart';
import '../theme.dart';
import 'dice_and_cup.dart';
import 'casino_anims.dart';

/// Presupuesto de la revelación rediseñada (corrección 26-oct):
/// dados Blender a 56 en rejilla de 2 columnas (hasta 3 filas),
/// nombres a 14, banda superior 30, encabezado 18, gaps 6/8,
/// celda con padding vertical 8 (4+4) y fila veredicto 48 típica.
/// El widget usa estas mismas constantes; el test de corrección
/// afirma que el contenido total cabe en 390 − 12 de padding.
const double revealDieSize = 56;
const double revealCellPadV = 8;
const double revealRowGap = 8;
// Línea de nombre MEDIDA (14 px + pastilla ±1 dado con padding):
// 20, no 17 (la altura de fuente sola subestima la fila).
const double revealNameH = 20;
// Banda superior MEDIDA (título 24 + contador + pastilla POZO):
// 36, no 34.
const double revealBandH = 36; // título 24 + contador en una línea
const double revealHeaderH = 18;
const double revealGap = 6;
const double revealVerdictRowH = 48; // veredicto 1 línea + botón

/// RONDA 4 (mesa visible en revelación, SOLO compacto): el
/// overlay ya no es negro casi pleno. Con 0,45 en conteo y 0,38
/// en veredicto, el óvalo y el paño de la mesa que vive debajo
/// se ven detrás y alrededor de la rejilla 2×3 (que NO cambia:
/// mismas tarjetas, mismos dados, misma rejilla). La legibilidad
/// no depende del overlay: tarjetas, veredicto y dados van sobre
/// fondos opacos (navyCard / marfil); solo título, contador y
/// encabezado pintan directos sobre el fondo, y esos llevan
/// sombra negra en compacto para seguir leyéndose sobre la mesa.
/// La rama vertical (compact false) conserva 0,96 / 0,82.
const double revealOverlayAlphaCount = 0.45;
const double revealOverlayAlphaVerdict = 0.38;

/// Alto del contenido de la revelación (sin el padding del
/// overlay) para [hands] manos. En el paso 2 el encabezado ya no
/// se pinta (lo sustituye la fila veredicto); la etiqueta
/// "comodín" va superpuesta al dado y no suma altura.
/// [compact] = marco horizontal de 334 px (390 − 56 de barra).
/// RONDA 3 (F3a): dado compacto 36 (era 44), celda 2+2, gaps
/// 4/4, veredicto con botón ~42: el caso típico a 6 manos, paso 2,
/// es 286 + padding 4 = 290, y el PEOR caso (veredicto a 2 líneas
/// + "Queda eliminado", que el modelo ronda 2 no contemplaba y
/// que cortaba veredicto + Seguir por el borde inferior) es 317
/// + padding 4 = 321 ≤ 334 (13 px de aire total, ~6 abajo, nunca
/// a 3 px ni cortado). Sin compactar, el caso típico sigue en
/// 376 + 12 = 388 ≤ 390 (como antes de la ronda 2, con la barra
/// tapada); el peor caso vertical no se modela (rama vertical
/// congelada por órdenes previas).
/// CORRECCIÓN 2b: el dado es una caja CUADRADA (BlenderDie:
/// width = height = size, BoxFit.contain), no size×420/448:
/// el modelo anterior subestimaba ~8 px por fila y el veredicto
/// compacto con dado 52 seguía cortando la fila veredicto
/// (captura ronda 2, pasada 3: rejilla 99..379, sin Seguir).
double revealContentHeight(int hands,
    {required bool step2,
    bool compact = false,
    int verdictLines = 1,
    bool eliminated = false}) {
  final rows = (hands + 1) ~/ 2;
  final dieSize = compact ? 36.0 : revealDieSize;
  final dieH = dieSize; // caja cuadrada BlenderDie, no 420/448
  final cellPadV = compact ? 4.0 : revealCellPadV;
  final rowGap = compact ? 4.0 : revealRowGap;
  final gap = compact ? 4.0 : revealGap;
  // Fila veredicto = máx(botón Seguir, caja): compacto botón ~42,
  // caja = padding 12 + líneas × 19 + eliminado 23; sin compactar
  // se conserva el modelo anterior (48) para el caso típico.
  final double verdictH;
  if (compact) {
    final boxH = 12.0 +
        19.0 * verdictLines +
        (eliminated ? 23.0 : 0.0);
    verdictH = boxH > 42.0 ? boxH : 42.0;
  } else {
    final boxH = 20.0 +
        21.0 * verdictLines +
        (eliminated ? 23.0 : 0.0);
    verdictH = boxH > revealVerdictRowH ? boxH : revealVerdictRowH;
  }
  final grid =
      rows * (revealNameH + 4 + dieH + cellPadV) + (rows - 1) * rowGap;
  if (!step2) {
    return revealBandH + gap + revealHeaderH + gap + grid;
  }
  return revealBandH + gap + grid + gap + verdictH;
}


// Revelación en 3 pasos (master prompt §7): encabezado, dados que se
// iluminan con contador animado y veredicto en una oración.
// ---------------------------------------------------------------------------

class ResolutionOverlay extends StatefulWidget {
  final MatchController controller;

  /// Modo compacto (solo la rama horizontal, que vive en un marco
  /// de 334 px bajo la barra: 390 − 56): dados, gaps y paddings
  /// recortados para que la rejilla 2×3 + fila veredicto quepan
  /// SIN scroll. La rama vertical (pantalla completa) no lo usa.
  final bool compact;
  const ResolutionOverlay(
      {super.key, required this.controller, this.compact = false});

  @override
  State<ResolutionOverlay> createState() => _ResolutionOverlayState();
}

class _ResolutionOverlayState extends State<ResolutionOverlay> {
  int _step = 0; // 0 encabezado, 1 conteo, 2 veredicto
  int _counted = 0; // dados ya contados (apuestas de pinta)
  Timer? _timer;
  Timer? _autoTimer;

  // Ritmo fijo y lento: al contar despacio se entiende solo, sin
  // selector de velocidad ni textos largos (orden del usuario).
  static const _headerMs = 1200;
  static const _tickMs = 170;
  static const _settleMs = 750;
  static const _pasoMs = 1500;

  /// Tras el veredicto, la revelación se quita sola a los 3 s:
  /// la ronda siguiente ya partió y nadie debe perder su turno
  /// buscando el botón Seguir (orden del usuario, 22-oct).
  static const _autoDismissMs = 3000;

  MatchController get c => widget.controller;
  UiResolution get r => c.uiResolution!;

  // RONDA 3 (F3a): medidas compactas solo para el marco
  // horizontal de 334 px. Dado 36 (era 44), celda 2+2, gaps 4/4,
  // veredicto padding 6: el caso típico (6 manos, paso 2) baja
  // a 286 + padding 4 = 290, y el peor caso (veredicto a 2 líneas
  // + eliminado) queda en 317 + 4 = 321 ≤ 334 con aire abajo
  // (~6 px, nunca a 3 px ni cortado). El dado 44 no bastaba en
  // el peor caso (veredicto + Seguir cortados por el borde
  // inferior en revelacion.png de ronda 2).
  double get _dieSize => widget.compact ? 44.0 : revealDieSize;
  double get _gap => widget.compact ? 4.0 : revealGap;
  double get _rowGap => widget.compact ? 4.0 : revealRowGap;
  double get _cellPadVHalf => widget.compact ? 2.0 : 4.0;
  double get _verdictPad => widget.compact ? 6.0 : 10.0;
  double get _verdictBtnSize => widget.compact ? 14.0 : 16.0;

  bool get _isBidResolution => r.type == 'dudo' || r.type == 'calzo';

  int get _totalDiceToCount =>
      r.revealed.values.fold<int>(0, (a, h) => a + h.length);

  @override
  void initState() {
    super.initState();
    _scheduleStep1();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoTimer?.cancel();
    super.dispose();
  }

  void _scheduleStep1() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: _headerMs), () {
      if (!mounted) return;
      setState(() => _step = 1);
      if (_isBidResolution) {
        _scheduleCount();
      } else {
        _timer = Timer(const Duration(milliseconds: _pasoMs), _toVerdict);
      }
    });
  }

  void _scheduleCount() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_counted >= _totalDiceToCount) {
        t.cancel();
        _timer = Timer(const Duration(milliseconds: _settleMs), _toVerdict);
        return;
      }
      setState(() => _counted++);
    });
  }

  void _toVerdict() {
    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _step = 2;
      _counted = _totalDiceToCount;
    });
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(milliseconds: _autoDismissMs), () {
      if (mounted) c.clearResolution();
    });
  }

  void _skip() {
    if (_step < 2) _toVerdict();
  }

  BidEvaluation? get _eval => _isBidResolution && r.bid != null
      ? GameEngine.evaluateBid(
          r.revealed, r.bid!, c.uiConfig.wildcardsEffective)
      : null;

  /// Cuántos exactos/comodines van contados con [_counted] dados vistos.
  (int, int) _partialCounts() {
    final ev = _eval;
    if (ev == null) return (0, 0);
    var seen = 0;
    var exact = 0;
    var wild = 0;
    for (final entry in r.revealed.entries) {
      final marks = ev.marks[entry.key] ?? const [];
      for (var i = 0; i < entry.value.length; i++) {
        if (seen >= _counted) return (exact, wild);
        seen++;
        if (marks[i] == DieMark.exact) exact++;
        if (marks[i] == DieMark.wild) wild++;
      }
    }
    return (exact, wild);
  }

  /// Manos visibles: en duda/calzo de Paso SOLO la mano del jugador
  /// del Paso (el motor ya la entrega así; el filtro es defensa si
  /// el motor cambiara). En Kamikaze, TODAS las manos nuevas.
  List<MapEntry<String, List<int>>> get _visibleEntries {
    if ((r.type == 'dudoPaso' || r.type == 'calzoPaso') &&
        r.pasoPlayerId != null) {
      final hand = r.revealed[r.pasoPlayerId];
      if (hand != null) return [MapEntry(r.pasoPlayerId!, hand)];
    }
    return r.revealed.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final ev = _eval;
    final (pExact, pWild) = _partialCounts();
    final loserPlayer = r.loserId != null ? c.playerById(r.loserId!) : null;
    final entries = _visibleEntries;
    // Celda: 2 columnas a 844 (406 px); en angosto mínimo 312 (la
    // fila de 5 dados a 56 + gaps + padding) y una columna con el
    // scroll de seguridad, como antes (sin regresión en portrait).
    final viewW = MediaQuery.sizeOf(context).width;
    final cellW = math.max((viewW - 24 - 8) / 2, 312).toDouble();

    // RONDA 2 (F11): en el veredicto (paso 2) el fondo baja a
    // 0,82 para que la mesa se vea tenuemente detrás (prueba
    // de mesa visible tras el veredicto); en conteo sigue a
    // 0,96. RONDA 4: en compacto baja a 0,45 / 0,38 (ver las
    // constantes de arriba): la mesa ya no es tenue, es
    // visible; el texto del veredicto sigue sobre navyCard
    // opaca (contraste intacto) y título/contador/encabezado
    // llevan sombra negra en compacto.
    // Destello de veredicto (§3f): verde si el perdedor no soy
    // yo, rojo si soy yo; solo el borde, nunca sobre el texto.
    return VerdictFlash(
      win: r.loserId != null && r.loserId != c.myId,
      active: _step >= 2 && r.loserId != null,
      enabled: CasinoAnims.enabledIn(context),
      child: Container(
      color: Colors.black.withValues(
          alpha: widget.compact
              ? (_step >= 2
                  ? revealOverlayAlphaVerdict
                  : revealOverlayAlphaCount)
              : (_step >= 2 ? 0.82 : 0.96)),
      padding: EdgeInsets.symmetric(
          horizontal: 12, vertical: widget.compact ? 2 : 6),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banda superior: título + contador en UNA línea +
              // Saltar mientras se cuenta. El contador parcial
              // (paso 1) y final (paso 2) viven aquí, no debajo de
              // los dados: así la rejilla cabe sin scroll a 390.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      revealTitle(r),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // RONDA 4: sombra solo en compacto (el
                      // overlay ya no es negro pleno y el título
                      // pinta directo sobre la mesa).
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: widget.compact
                            ? const [
                                Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(0, 1)),
                                Shadow(
                                    color: Colors.black,
                                    blurRadius: 8),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  if (_isBidResolution && ev != null)
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${_step == 1 ? pExact + pWild : ev.total}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: CachoColors.gold,
                                shadows: widget.compact
                                    ? const [
                                        Shadow(
                                            color: Colors.black,
                                            blurRadius: 4,
                                            offset: Offset(0, 1)),
                                      ]
                                    : null,
                              ),
                            ),
                            TextSpan(
                              text: ' de ${r.bid!.quantity} '
                                  '${facePlural(r.bid!.face)} · '
                                  'exactos ${_step == 1 ? pExact : ev.exact} · '
                                  'comodines ${_step == 1 ? pWild : ev.wild}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  shadows: widget.compact
                                      ? const [
                                          Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                              offset: Offset(0, 1)),
                                        ]
                                      : null),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  // RONDA 2 (F8): aire de 8 px antes de Saltar:
                  // el contador ("…comodines 4") y "Saltar »" se
                  // pegaban y se leían como "4Saltar »".
                  if (_step < 2) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Saltar »',
                          style: TextStyle(
                              color: CachoColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                  // RONDA 2 (F5): pozo LEGIBLE durante el
                  // veredicto (paso 2, en el hueco que deja
                  // Saltar): pastilla POZO + monto real, sin
                  // vaso, a 14 px. La duplicación centro+barra
                  // es P2 pendiente: NO se quita ninguna sede,
                  // esta pastilla es la sede del overlay y solo
                  // vive durante el veredicto.
                  if (_step >= 2 &&
                      c.stake > 0 &&
                      c.displayPot > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: CachoColors.gold.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        'POZO ${coinsText(c.displayPot)}',
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CachoColors.gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Encabezado mientras se cuenta. En el veredicto lo
              // sustituye la fila veredicto + Seguir (título y
              // contador siguen visibles, así que no se pierde
              // contexto) y así la rejilla sigue cabiendo a 390.
              if (_step < 2) ...[
                SizedBox(height: _gap),
                Text(
                  revealHeader(c, r),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      shadows: widget.compact
                          ? const [
                              Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1)),
                            ]
                          : null),
                ),
                if ((r.type == 'dudoPaso' || r.type == 'calzoPaso') &&
                    _step == 1)
                  Text(
                    _pasoAnalysis(),
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        shadows: widget.compact
                            ? const [
                                Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(0, 1)),
                              ]
                            : null),
                  ),
              ],
              // Rejilla de manos (corrección 26-oct, reemplaza la
              // columna centrada de 372 con dados a 40, RECHAZADA):
              // 2 columnas × 3 filas a 844, dados Blender a 56,
              // nombres a 14 con el ancho de la celda. El orden es
              // el de `revealed.entries`: el conteo uno a uno
              // (_counted) ilumina en ese mismo orden, fila a fila.
              if (_step >= 1) ...[
                SizedBox(height: _gap),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: _rowGap,
                  children: [
                    // Entrada elevada escalonada (§3d): la
                    // revelación "levanta todos los vasos a la
                    // vez mostrando los dados" en el lenguaje
                    // del overlay — la rejilla ya muestra todas
                    // las manos; cada celda sube con pequeño
                    // bounce, 80 ms entre celdas, sin tocar
                    // tamaños ni el conteo.
                    for (final e in entries.asMap().entries)
                      RevealCellAnim(
                        index: e.key,
                        enabled: CasinoAnims.enabledIn(context),
                        child: _revealCell(
                            e.value.key, e.value.value, ev, cellW),
                      ),
                  ],
                ),
              ],
              // Veredicto + Seguir en una fila (antes apilados):
              // así el paso 2 también cabe a 390 sin scroll.
              if (_step >= 2) ...[
                SizedBox(height: _gap),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(_verdictPad),
                        decoration: BoxDecoration(
                          color: navyCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: CachoColors.gold.withValues(alpha: 0.55)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (r.type == 'dudoPaso' || r.type == 'calzoPaso')
                                  ? '${_pasoAnalysis()} ${verdictText(c, r)}'
                                  : verdictText(c, r),
                              textAlign: TextAlign.center,
                              // RONDA 3 (F3a): altura 1,25 en
                              // compacto (era 1,35) para el peor
                              // caso a 2 líneas; fontSize 15
                              // intacto (F3k: no se inflan
                              // fuentes, tampoco se bajan para
                              // ahorrar: solo el interlineado).
                              style: TextStyle(
                                  fontSize: 15,
                                  height: widget.compact ? 1.25 : 1.35),
                            ),
                            if (loserPlayer != null && loserPlayer.eliminated)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Queda eliminado de la partida.',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF9A9A)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    BronzeButton(
                      label:
                          c.phase == 'finished' ? 'Ver el resultado' : 'Seguir',
                      fontSize: _verdictBtnSize,
                      onPressed: c.clearResolution,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Dado de revelación: sprite Blender marfil a 56 (corrección
  /// 26-oct, antes 40) con los estados de la resolución (dorado
  /// destacado, rojo alerta, atenuado a 0,45). La etiqueta
  /// "comodín" va como píldora oscura sobre el borde inferior del
  /// dado (la cara frontal baja está en blanco): no suma altura
  /// ni mueve la rejilla al aparecer.
  Widget _revealDie(int value,
      {bool alert = false,
      bool highlighted = false,
      bool dimmed = false,
      bool wildTag = false}) {
    final die = Opacity(
      opacity: dimmed ? 0.70 : 1.0,
      child: DiceFace(
        value: value,
        size: _dieSize,
        alert: alert,
        highlighted: highlighted,
        dimmed: dimmed,
      ),
    );
    if (!wildTag) return die;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        die,
        // RONDA 2 corrección 2c (F8) + RONDA 3 (F3a): la píldora
        // sobresale 12 px por lado del dado en normal (80) y 16 px
        // en compacto (68: dado 36 + 32), con padding 4 y softWrap
        // false: "comodín" a 14 px (~56 px) cabe en UNA línea
        // (contenido 60 en compacto) sin partirse en "como/dín"
        // ni perder la "n" (con ±8 el área era 52 y el
        // TextOverflow.clip la cortaba, captura pasada 5; con
        // dado 36 y ±12 el contenido sería 52 y se cortaría de
        // nuevo). RONDA 4: esa afirmación era falsa en la
        // práctica (paso 58 < fondo ~64: los fondos SE solapaban
        // 6 px y los textos quedaban a 2 px, "comodíncomodín");
        // ahora en compacto el paso es 72 (ver _revealCell):
        // fondos a 8 px y textos a 16 px de aire.
        // RONDA 3 (F3a): en compacto la píldora sobresale ±16
        // (era ±12): con dado 36 la píldora de ±12 medía 60 y su
        // contenido (60 − padding 8 = 52) cortaba "comodín"
        // (~56); con ±16 mide 68 y el contenido 60 ≥ 56.
        Positioned(
          left: widget.compact ? -16.0 : -12.0,
          right: widget.compact ? -16.0 : -12.0,
          bottom: 2,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('comodín',
                  softWrap: false,
                  style: TextStyle(
                      fontSize: 14,
                      color: CachoColors.gold,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  // RONDA 2 (F8): etiquetas de veredicto ("−1 dado", "+1 dado")
  // a 14 px (eran 10 px); caben en la celda de 406 px.
  Widget _deltaTag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      );

  String _pasoAnalysis() {
    final hand = r.revealed[r.pasoPlayerId] ?? const <int>[];
    if (hand.length != 5) return '';
    if (GameEngine.isPasoHand(hand)) return 'El Paso era verdadero.';
    return 'El Paso era falso.';
  }

  /// Una mano en la rejilla de revelación (corrección 26-oct):
  /// nombre a 14 px con el ancho de la celda (antes 12,5 px en 88)
  /// + dados Blender a 56 en fila. El borde rojo/dorado del paso 2
  /// marca perdedor/ganador; el delta va en la misma línea del
  /// nombre para no mover la rejilla al aparecer.
  Widget _revealCell(
      String playerId, List<int> hand, BidEvaluation? ev, double cellW) {
    final marks = ev?.marks[playerId];
    var globalBase = 0;
    for (final e in _visibleEntries) {
      if (e.key == playerId) break;
      globalBase += e.value.length;
    }
    final isLoser = playerId == r.loserId || r.massLoserIds.contains(playerId);
    final isGainer = playerId == r.gainerId;
    return Container(
      width: cellW,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: _cellPadVHalf),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _step >= 2 && isLoser
              ? const Color(0xFFB3202A)
              : _step >= 2 && isGainer
                  ? CachoColors.gold
                  : Colors.white.withValues(alpha: 0.10),
          width: _step >= 2 && (isLoser || isGainer) ? 1.6 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shortNameOf(c, playerId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              if (_step >= 2 && isLoser) ...[
                const SizedBox(width: 6),
                _deltaTag('−1 dado', const Color(0xFFB3202A)),
              ],
              if (_step >= 2 && isGainer) ...[
                const SizedBox(width: 6),
                _deltaTag('+1 dado', CachoColors.calzoGreen),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var idx = 0; idx < hand.length; idx++)
                // RONDA 4 (aire entre "comodín"): el paso 58 de
                // ronda 3 NO daba aire real — la píldora mide
                // ~64 px de fondo (texto ~56 + padding 8) y el
                // texto ~56, así que con paso 58 el fondo se
                // solapaba 6 px y entre textos quedaban solo
                // 2 px: en captura se leía "comodíncomodín".
                // Ahora en compacto padding 18 × 2 = paso 72:
                // fondo 64 → aire 8 px entre píldoras, texto 56
                // → aire 16 px entre textos. La fila de 5 dados
                // mide 360 px y cabe en la celda de 406.
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: widget.compact ? 6 : 4),
                  child: Builder(builder: (_) {
                    final counted = !_isBidResolution ||
                        _step >= 2 ||
                        (globalBase + idx) < _counted;
                    // Corrección 26-oct: dados Blender marfil a 56 en
                    // rejilla (antes 40 en columna, rechazado).
                    // Borde dorado = destacado, rojo = alerta,
                    // opacidad = atenuado; "comodín" va superpuesto
                    // al dado (ver _revealDie), sin altura extra.
                    if (r.type == 'kamikaze') {
                      final falls = hand[idx] == r.kamikazeFace;
                      return _revealDie(hand[idx],
                          alert: falls, dimmed: !falls);
                    }
                    if (marks != null) {
                      final m = marks[idx];
                      return _revealDie(hand[idx],
                          highlighted: counted && m != DieMark.miss,
                          dimmed: counted && m == DieMark.miss,
                          wildTag: counted && m == DieMark.wild);
                    }
                    return _revealDie(hand[idx]);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Destello verde/rojo con el resultado de Dudo/Calzo
/// (layout-sin-solapes, §3f): un borde pulsante alrededor del
/// overlay, dos pulsos en ~1,4 s, que se apaga solo. Verde si el
/// perdedor no es el jugador local, rojo si lo es. Es SOLO un
/// borde (`IgnorePointer`, sin fondo): nunca tapa el texto, los
/// dados ni el botón, y no cambia el veredicto ni el layout.
/// Con [active] false (sin veredicto aún o sin perdedor) o
/// [enabled] false (animaciones apagadas) pinta el hijo directo.
/// El controlador se libera en [dispose].
class VerdictFlash extends StatefulWidget {
  final Widget child;
  final bool win;
  final bool active;
  final bool enabled;
  const VerdictFlash({
    super.key,
    required this.child,
    required this.win,
    required this.active,
    this.enabled = true,
  });
  @override
  State<VerdictFlash> createState() => _VerdictFlashState();
}

class _VerdictFlashState extends State<VerdictFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || !widget.enabled) return widget.child;
    final color =
        widget.win ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value;
                final opacity =
                    (1 - t) * (0.65 + 0.35 * math.sin(t * math.pi * 4).abs());
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: opacity),
                      width: 4,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Entrada elevada de una celda de revelación (§3d): sube 12 px
/// con pequeño bounce (easeOutBack) y fundido en 500 ms, con
/// 80 ms de escalonado por [index]. Con [enabled] false pinta el
/// hijo directo. El controlador y el temporizador de arranque se
/// liberan en [dispose]; la animación no cambia tamaños.
class RevealCellAnim extends StatefulWidget {
  final int index;
  final Widget child;
  final bool enabled;
  const RevealCellAnim({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
  });
  @override
  State<RevealCellAnim> createState() => _RevealCellAnimState();
}

class _RevealCellAnimState extends State<RevealCellAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startTimer = Timer(
      Duration(milliseconds: widget.index * 80),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final dy = 12 * (1 - Curves.easeOutBack.transform(t));
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: widget.child,
    );
  }
}
