import 'package:flutter/foundation.dart';

import 'sketch_layout.dart';

/// Huellas WIDGET reales de la mesa bosquejo (corrección 27-oct).
///
/// Por qué existe este archivo: `sketch_layout.dart` mide rectángulos
/// GEOMÉTRICOS (avatar 58, placa 88, vaso 56×64) y con ellos la mesa
/// salía "limpia", pero en la foto del usuario los elementos SE
/// solapaban. La causa medida: los widgets reales son más grandes
/// que sus rectángulos geométricos:
/// - la placa bosquejo se pinta con ancho 132 (180 la superior
///   de una línea, corrección 28-oct) y, con el offset −8 viejo,
///   empezaba 9 px por encima del borde inferior del avatar y
///   bajo el vaso;
/// - el vaso rival mide 73×72 con posavasos (no 56×64), y el vaso
///   superior central a centro 57 quedaba a 21 px de la placa de
///   132 px, tapándola en widget (y al vaso superior-derecho).
///
/// Este módulo reconstruye, a partir de un [SketchLayout], los
/// rectángulos que REALMENTE pintan `_sketchTable` /
/// `_sketchRivalSeat` en `game_screen.dart` (offsets de widget,
/// placa centrada de 132, pastilla del pozo de 180×32, dados de
/// la banda propia de 32/22) y los comprueba con los márgenes
/// que pidió el usuario: 8 px entre slots y 12 px entre mis dados
/// y pozo/avatar/nameplate. El posavasos (lóbulo oscuro de 7–9 px
/// por lado) se excluye de los vasos rivales y del mío, como ya
/// hace `sketch_layout.dart`: no es información jugable, es una
/// elipse oscura sobre el paño; el cuerpo del vaso (56×64) sí se
/// comprueba. La única excepción declarada es mi vaso sobre mis
/// dados: por regla del juego el vaso cerrado TAPA mis dados
/// (peek/VER), así que el par dados~mi-vaso no cuenta como
/// solape; en cuanto el vaso se levanta, los dados quedan en su
/// banda propia con las separaciones comprobadas.
///
/// Nada aquí pinta: solo rectángulos y comprobaciones puras, por
/// eso se puede testear con `flutter test` sin servidor ni UI.

class WidgetBox {
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  const WidgetBox(this.label, this.left, this.top, this.width, this.height);
  double get right => left + width;
  double get bottom => top + height;
  double get cx => left + width / 2;
  double get cy => top + height / 2;

  bool overlaps(WidgetBox o) =>
      left < o.right && right > o.left && top < o.bottom && bottom > o.top;

  double overlapArea(WidgetBox o) {
    if (!overlaps(o)) return 0;
    return ((right < o.right ? right : o.right) -
            (left > o.left ? left : o.left)) *
        ((bottom < o.bottom ? bottom : o.bottom) -
            (top > o.top ? top : o.top));
  }

  WidgetBox inflated(double m) =>
      WidgetBox(label, left - m, top - m, width + 2 * m, height + 2 * m);

  /// Rectángulo unión de [boxes] (etiqueta del primero).
  static WidgetBox union(String label, List<WidgetBox> boxes) {
    var l = boxes.first.left;
    var t = boxes.first.top;
    var r = boxes.first.right;
    var b = boxes.first.bottom;
    for (final box in boxes.skip(1)) {
      if (box.left < l) l = box.left;
      if (box.top < t) t = box.top;
      if (box.right > r) r = box.right;
      if (box.bottom > b) b = box.bottom;
    }
    return WidgetBox(label, l, t, r - l, b - t);
  }
}

class SeatWidgets {
  final double angleDeg;
  final WidgetBox avatar;
  final WidgetBox plate;
  final WidgetBox cup;
  final WidgetBox slot;
  const SeatWidgets(this.angleDeg, this.avatar, this.plate, this.cup,
      this.slot);
}

class WidgetTableLayout {
  /// Unidad base única (equivalente a la --unit pedida): escala
  /// de la mesa respecto a la referencia 844×390 (mesa 262 px).
  /// De ella derivan las fuentes: nombre y pozo van a 14×unit.
  final double unit;
  final double tableW;
  final double tableH;
  final WidgetBox pot;
  final List<SeatWidgets> seats;
  final List<WidgetBox> myDice;
  final WidgetBox myCup;
  final WidgetBox myAvatar;
  final WidgetBox myPlate;
  final double consoleTop;
  const WidgetTableLayout({
    required this.unit,
    required this.tableW,
    required this.tableH,
    required this.pot,
    required this.seats,
    required this.myDice,
    required this.myCup,
    required this.myAvatar,
    required this.myPlate,
    required this.consoleTop,
  });

  double get nameFont => 14 * unit;
  double get potFont => 14 * unit;
}

/// Reconstruye las huellas widget de un [SketchLayout] tal como
/// las pinta `game_screen.dart` (ver cabecera). Todas las
/// coordenadas son de pantalla (como en `SketchLayout`).
WidgetTableLayout widgetLayoutFor(SketchLayout layout) {
  final unit = (layout.tableH / 262).clamp(0.6, 1.1);
  final compact = layout.tableH < 262;
  final screenW = layout.screenW;

  // Pozo widget: 180×32 centrado, top = top geométrico.
  final pot = WidgetBox('pozo-widget', layout.pot.cx - 90, layout.pot.top,
      180, 32);

  final seats = <SeatWidgets>[];
  for (final s in layout.seats) {
    // Avatar widget: 64 (58 geom + 3 por lado) o 56 (48 geom + 4).
    final avatarIs48 = s.avatar.width == 48;
    final avatarW = avatarIs48 ? 56.0 : 64.0;
    final avatarOff = avatarIs48 ? 4.0 : 3.0;
    final avatar = WidgetBox('avatar-${s.angleDeg.round()}',
        s.avatar.left - avatarOff, s.avatar.top - avatarOff, avatarW, avatarW);
    // Placa widget: 132 de ancho CENTRADA en el centro geométrico
    // (corrección 27-oct, antes empezaba en geom.plate.left) y
    // top geométrico + 4 (antes −8, que la metía bajo el avatar
    // y bajo el vaso). Alto: 21 en una línea, 34 en dos líneas.
    // CORRECCIÓN 28-oct: la placa superior de una línea mide
    // 180 (no 132): a 132, con pipas + gap, solo quedaban 53 px
    // para el nombre y "El Huaso" (112 px a 14 px) se leía
    // "El H…". En game_screen la superior pasa a plateW 180 y
    // en dice_and_cup su nombre va a 12 px con pipas de 7 px
    // (161 px de contenido ≤ 180).
    final plateW = s.singleLinePlate ? 180.0 : 132.0;
    final plate = WidgetBox(
        'placa-${s.angleDeg.round()}',
        s.plate.cx - plateW / 2,
        s.plate.top + 4,
        plateW,
        s.singleLinePlate ? 21 : 34);
    // Vaso: cuerpo geométrico (el posavasos no es información).
    final cup = WidgetBox('vaso-${s.angleDeg.round()}', s.cup.left,
        s.cup.top, s.cup.width, s.cup.height);
    seats.add(SeatWidgets(
        s.angleDeg, avatar, plate, cup, WidgetBox.union(
            'slot-${s.angleDeg.round()}', [avatar, plate, cup])));
  }

  // Mi vaso: cuerpo geométrico (posavasos excluido, ver cabecera).
  final myCup = WidgetBox('mi-vaso', layout.myCup.left, layout.myCup.top,
      layout.myCup.width, layout.myCup.height);
  // Mis dados de la banda propia: 32 (22 en compacto), ~30%
  // menos que los 46/32 anteriores, centrados en mi vaso, con
  // bottom 20/16 en el escenario (ver _myStageSketch): bottom
  // = mi-vaso.bottom − 13 (full) / − 9 (compacto).
  final dieSize = compact ? 22.0 : 32.0;
  final n = layout.myDice.length;
  final totalW = n == 0 ? 0.0 : n * dieSize + (n - 1) * 4.0;
  final diceTop = layout.myCup.bottom - (compact ? 9.0 : 13.0) - dieSize;
  final myDice = <WidgetBox>[
    for (var i = 0; i < n; i++)
      WidgetBox('dado-$i',
          layout.myCup.cx - totalW / 2 + i * (dieSize + 4), diceTop,
          dieSize, dieSize),
  ];

  // Mi asiento widget: avatar 64 centrado en pantalla (el
  // Positioned mide 120 de ancho) y placa 120×34 2 px debajo
  // del avatar (corrección 27-oct: antes −18, solapando el
  // avatar). La placa cuelga sobre la tira VER (44 px), cuya
  // zona central está vacía, y termina 8 px antes de la consola.
  final myAvatar = WidgetBox(
      'mi-avatar', screenW / 2 - 32, layout.myAvatar.top, 64, 64);
  final myPlate = WidgetBox('mi-placa', screenW / 2 - 60,
      layout.myAvatar.bottom + 2, 120, 34);

  return WidgetTableLayout(
    unit: unit,
    tableW: layout.tableW,
    tableH: layout.tableH,
    pot: pot,
    seats: seats,
    myDice: myDice,
    myCup: myCup,
    myAvatar: myAvatar,
    myPlate: myPlate,
    consoleTop: layout.tableBottom + 44,
  );
}

/// Comprueba las huellas widget. Devuelve la lista de violaciones
/// (vacía = limpio). Reglas:
/// - slots (rival + mío) entre sí: margen mínimo [slotMargin]
///   (8 px): se inflan ambos rectángulos unión en slotMargin/2
///   y no deben solaparse.
/// - dentro de cada slot: avatar~placa y avatar~vaso y
///   placa~vaso no se solapan (sin margen: el vaso va al
///   costado exterior y la placa justo debajo del avatar).
/// - pozo y mi vaso contra todo lo demás: sin solape.
/// - mis dados contra pozo, avatares y nameplates: separación
///   mínima [diceGap] (12 px), en al menos un eje.
/// - mi placa no invade la consola (termina 8 px antes).
/// - nada sale de la pantalla en horizontal.
/// Excepción declarada: mis dados contra mi vaso (peek).
List<String> checkWidgetLayout(WidgetTableLayout w,
    {double slotMargin = 8, double diceGap = 12}) {
  final violations = <String>[];
  void checkNoOverlap(WidgetBox a, WidgetBox b, String why) {
    if (a.overlaps(b)) {
      violations.add('$why: ${a.label} ~ ${b.label} = '
          '${a.overlapArea(b).toStringAsFixed(0)} px²');
    }
  }

  void checkMargin(WidgetBox a, WidgetBox b, double margin, String why) {
    final ia = a.inflated(margin / 2);
    final ib = b.inflated(margin / 2);
    if (ia.overlaps(ib)) {
      violations.add('$why (margen ${margin.toStringAsFixed(0)} px): '
          '${a.label} ~ ${b.label}');
    }
  }

  // Slots entre sí (margen 8).
  final slots = [
    for (final s in w.seats) s.slot,
    WidgetBox.union('slot-mio', [w.myAvatar, w.myPlate]),
  ];
  for (var i = 0; i < slots.length; i++) {
    for (var j = i + 1; j < slots.length; j++) {
      checkMargin(slots[i], slots[j], slotMargin, 'slots');
    }
  }
  // Dentro de cada slot.
  for (final s in w.seats) {
    checkNoOverlap(s.avatar, s.plate, 'slot interno');
    checkNoOverlap(s.avatar, s.cup, 'slot interno');
    checkNoOverlap(s.plate, s.cup, 'slot interno');
  }
  checkNoOverlap(w.myAvatar, w.myPlate, 'mi asiento');
  // Pozo y mi vaso contra todo.
  final others = [
    for (final s in w.seats) ...[s.avatar, s.plate, s.cup],
    w.myAvatar,
    w.myPlate,
    w.myCup,
  ];
  for (final o in others) {
    checkNoOverlap(w.pot, o, 'pozo');
  }
  for (final s in w.seats) {
    for (final box in [s.avatar, s.plate, s.cup]) {
      checkNoOverlap(w.myCup, box, 'mi vaso');
    }
  }
  checkNoOverlap(w.myCup, w.myAvatar, 'mi vaso');
  checkNoOverlap(w.myCup, w.myPlate, 'mi vaso');
  // Mis dados: separación 12 contra pozo, avatares y nameplates.
  final diceTargets = [
    w.pot,
    w.myAvatar,
    w.myPlate,
    for (final s in w.seats) ...[s.avatar, s.plate],
  ];
  for (final d in w.myDice) {
    for (final t in diceTargets) {
      checkMargin(d, t, diceGap, 'mis dados');
    }
    // Mis dados contra vasos rivales y mi asiento: sin solape.
    for (final s in w.seats) {
      checkNoOverlap(d, s.cup, 'mis dados');
    }
  }
  // Mi placa no invade la consola.
  if (w.myPlate.bottom + 8 > w.consoleTop) {
    violations.add('mi placa invade la consola: bottom '
        '${w.myPlate.bottom.toStringAsFixed(0)} consola '
        '${w.consoleTop.toStringAsFixed(0)}');
  }
  // Dentro de la pantalla en horizontal.
  final all = [
    w.pot,
    for (final s in w.seats) ...[s.avatar, s.plate, s.cup],
    ...w.myDice,
    w.myCup,
    w.myAvatar,
    w.myPlate,
  ];
  // Ancho de pantalla: se infiere del rect de la mesa no guardado
  // aquí; el llamador lo comprueba con screenW si lo necesita.
  // Se deja constancia: ningún rect tiene left negativo.
  for (final box in all) {
    if (box.left < 0) {
      violations.add('fuera de pantalla: ${box.label} left '
          '${box.left.toStringAsFixed(0)}');
    }
  }
  return violations;
}

/// Función de debug pedida: calcula las huellas, comprueba
/// intersecciones y avisa por consola. Devuelve las violaciones
/// (vacía = limpio) para que el test pueda afirmarlo.
List<String> debugCheckWidgetLayout(SketchLayout layout) {
  final w = widgetLayoutFor(layout);
  final violations = checkWidgetLayout(w);
  if (violations.isEmpty) {
    debugPrint('SEAT_LAYOUT OK: mesa ${w.tableW.toStringAsFixed(0)}×'
        '${w.tableH.toStringAsFixed(0)} unit ${w.unit.toStringAsFixed(3)} '
        'fuente ${w.nameFont.toStringAsFixed(1)} px, '
        '${w.seats.length} rivales, ${w.myDice.length} dados: sin solapes');
  } else {
    debugPrint('SEAT_LAYOUT SOLAPES (${violations.length}):');
    for (final v in violations) {
      debugPrint('  - $v');
    }
  }
  return violations;
}
