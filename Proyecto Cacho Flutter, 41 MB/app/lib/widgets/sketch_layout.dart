import 'dart:math' as math;

/// Geometría PURA de la mesa bosquejo (sentencia F1/F2 + master
/// prompt §2 + corrección del usuario 25-oct: la captura debe
/// parecerse al bosquejo). Una sola fuente de verdad para el
/// widget (`_sketchTable`) y para `sketch_layout_test.dart`. Nada
/// aquí pinta: solo rectángulos en coordenadas de pantalla 844×390
/// (o el alto útil que se pase). Los solapes se miden en el test,
/// nunca se afirman a ciegas.
///
/// Reglas aplicadas (medidas, no estimadas):
/// - CORRECCIÓN 26-oct (mockup-6, ≤5 rivales): puestos FIJOS, no
///   elipse: superior-izquierda, superior-derecha,
///   inferior-izquierda, inferior-derecha, centro arriba (en ese
///   orden de ocupación); costados con avatar 58, placa 88×34
///   SIEMPRE DEBAJO, vaso 56×64 hacia fuera; asiento superior con
///   avatar 48 + placa de una línea 88×18 (el hueco pozo~mi-vaso
///   no da para más) y vaso a su derecha junto al avatar
///   (RONDA 3: centro cx + 57, hueco 5 px; antes cx + 92); en
///   mesa corta su placa se corre a la izquierda. Medido 0
///   solapes a 844×390 y a 350
///   (mesa 230) con dados 5/3/1; residuos solo a mesa real 206/178
///   (ver informe). La elipse de abajo solo rige para 6 rivales
///   (referencia) y el arco igual para ≥7.
/// - Elipse de asientos (378, 90) centrada en la mesa (70 en
///   vertical para 7+ rivales: con 90 los asientos inferiores
///   quedan tan bajos que su placa colgaría bajo la mesa). El 90
///   (no el 95 de la sentencia) deja la placa de una línea de los
///   asientos inferiores con 1 px de aire sobre la consola: la
///   placa se cortaba abajo porque su texto quedaba bajo la
///   consola, que pinta después (captura 6_final).
/// - Avatar rival: rect 58 = círculo 56 + aro en referencia
///   (≤6 rivales); 50 = círculo 46 + aro en arco igual (7+):
///   con 58/56×64 el par diagonal vaso~avatar es estructural
///   (el radio y la cuerda casi coinciden: el vaso cae a ~25 px
///   del avatar vecino con paso ~105). La huella del widget es
///   64/56 con la sombra, que no es información y no cuenta
///   para solapes; el widget se recentra 3 px sobre el rect.
///   Mi avatar mantiene 64 (abajo, sin pares).
/// - ≤6 rivales: ángulos referencia-primero (2 laterales arriba
///   + 2 costados + inferiores + yo abajo, como el bosquejo).
/// - ≥7 rivales: distribución de ARCO IGUAL sobre la elipse
///   (corrección 25-oct: rediseñar antes de declarar no-cabe).
///   El ángulo igual apelotona los costados (la elipse corre
///   ~95 px/rad junto a 0°/180° y ~378 px/rad arriba/abajo); el
///   arco igual deja ~90 px entre asientos vecinos a 12.
///   Se excluyen los arcos donde el asiento, su placa o su vaso
///   tocarían el pozo, mi asiento, mi vaso o mis dados, donde el
///   vaso tocaría su propio avatar, donde la placa colgaría
///   bajo la mesa (su texto lo taparía la consola) o donde el
///   vaso saldría de la página. Las placas van SIEMPRE DEBAJO
///   (84 de ancho, 32 de alto = texto real: "La Morocha" a
///   14 px negrita mide ~78-80 en fuente real, y 84 le da aire
///   sin recorte) — la divergencia superior ENCIMA ya no
///   existe (ÁREA 2, mockup). Los vasos de arco igual van
///   radiales a 52 abajo / 100 arriba (40×46), salvo en los
///   costados (|cos| ≥ 0,8) donde van hacia fuera en x (±54).
///   CORRECCIÓN 25-oct (ÁREA 2): el "0 solapes a 7 y 8
///   jugadores" anterior está DESACTUALIZADO; medido a 8
///   jugadores (7 rivales, dados=5) hay 7 solapes, 2415 px² a
///   390 y 3757 px² a 340 compacto — 8 jugadores es NO-CABE
///   con placa debajo + vaso radial hacia el centro (ver
///   informe del área 2).
/// - Vasos rivales: 56×64 (huella con posavasos 70×72) en
///   referencia; 40×46 (huella 54×54) en arco igual, lisos, sin
///   iniciales (corrección 25-oct: el bosquejo no las tiene).
///   Radial 68 (80 costados) en referencia; radial 52 (hacia
///   fuera ±54 en costados) en arco igual.
/// - Pozo: fila [POZO + vaso 30×36 + monto real] de 140×36
///   arriba al centro, como el bosquejo (vaso pequeño, etiqueta
///   y cifra legible, sin tapar el centro).
/// - Mi vaso 64×76 (no 101×118: el vaso enorme al centro era lo
///   que el usuario leyó como "vaso del pozo" tapando el centro).
///   Mis dados 48 (28 en compacto, con pintas Blender agrandadas
///   25-oct: a 36 las pintas eran invisibles a 390) en BANDA
///   INFERIOR, centrados en el vaso con hueco 104: el centro
///   queda limpio para que "CACHO O DUDO" se lea completo; los
///   dados sueltos al centro van SOLO en revelación. En compacto
///   el vaso es 44×52 y los dados 28, con las mismas reglas. La
///   banda de dados en completo va a top myCup.top+8 (no +16):
///   con +16 y dados 48 el dado derecho tocaba al avatar-60 en
///   90 px² medidos (fondo del dado 238 contra avatar 236).
/// - Mi asiento en fila (avatar + placa a la derecha), abajo.

class SketchRect {
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  const SketchRect(this.label, this.left, this.top, this.width, this.height);
  double get right => left + width;
  double get bottom => top + height;
  double get cx => left + width / 2;
  double get cy => top + height / 2;

  /// Solape estricto (tocar el borde no es solape).
  bool overlaps(SketchRect o) =>
      left < o.right && right > o.left && top < o.bottom && bottom > o.top;

  /// Área de solape (0 si no hay).
  double overlapArea(SketchRect o) {
    if (!overlaps(o)) return 0;
    return (math.min(right, o.right) - math.max(left, o.left)) *
        (math.min(bottom, o.bottom) - math.max(top, o.top));
  }
}

class SketchSeat {
  final double angleDeg;
  final SketchRect avatar;
  final SketchRect plate;
  final SketchRect cup;

  /// Placa de una línea ("×5 · nombre") en vez de dos líneas.
  /// Solo la usa el asiento superior del mockup-6 (ver
  /// `mockupSeat`): su pila avatar+placa debe caber en el hueco
  /// pozo~mi-vaso (80 px a 390), imposible con placa de 34.
  final bool singleLinePlate;
  const SketchSeat(this.angleDeg, this.avatar, this.plate, this.cup,
      {this.singleLinePlate = false});
}

class SketchLayout {
  final double screenW;
  final double tableTop;
  final double tableH;
  final double tableLeft;
  final double tableW;
  final double consoleH;
  final SketchRect table;
  final SketchRect pot;
  final List<SketchSeat> seats;
  final List<SketchRect> myDice;
  final SketchRect myCup;
  final SketchRect myAvatar;
  final SketchRect myPlate;
  final SketchRect console;
  const SketchLayout({
    required this.screenW,
    required this.tableTop,
    required this.tableH,
    required this.tableLeft,
    required this.tableW,
    required this.consoleH,
    required this.table,
    required this.pot,
    required this.seats,
    required this.myDice,
    required this.myCup,
    required this.myAvatar,
    required this.myPlate,
    required this.console,
  });

  double get tableBottom => tableTop + tableH;

  /// Todos los rectángulos con etiqueta, salvo los dados propios
  /// (se añaden aparte para poder excluir la pareja
  /// dados-vaso-propio, que es peek por diseño).
  List<SketchRect> get all => [
        table,
        pot,
        for (final s in seats) ...[s.avatar, s.plate, s.cup],
        myCup,
        myAvatar,
        myPlate,
        console,
      ];

  /// Pares con solape > 0, excluyendo dados-vaso-propio.
  List<(SketchRect, SketchRect, double)> overlaps({int myDiceCount = 5}) {
    final rects = [...all, ...myDice];
    final out = <(SketchRect, SketchRect, double)>[];
    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        final a = rects[i];
        final b = rects[j];
        // La mesa y la consola son fondos: no cuentan como solape
        // con lo que vive dentro de ellas.
        if (a.label == 'mesa' || b.label == 'mesa') continue;
        if (a.label == 'consola' || b.label == 'consola') continue;
        // Peek por diseño: mis dados viven bajo mi vaso.
        if ((a.label.startsWith('dado') && b.label == 'mi-vaso') ||
            (b.label.startsWith('dado') && a.label == 'mi-vaso')) {
          continue;
        }
        final area = a.overlapArea(b);
        if (area > 0) out.add((a, b, area));
      }
    }
    return out;
  }
}

/// Ángulos de referencia (6 rivales exactos, legado; y respaldo
/// del arco igual). Para ≤5 rivales sketchLayout ya NO usa esta
/// lista: usa la rama mockup-6 (ver `mockupAngles` y la cabecera
/// de `sketchLayout`). SIN 270 superior central en esta lista
/// vieja: la columna central la ocupan el pozo (arriba), mi vaso
/// y mi asiento (abajo); un asiento a 270 solapaba el pozo en
/// 3520 px² medidos con la geometría vieja. Para ≥7 rivales
/// sketchLayout usa arco igual (abajo), no esta lista.
List<double> sketchAngles(int rivals) {
  if (rivals <= 0) return [];
  if (rivals == 1) return [240];
  if (rivals == 2) return [240, 300];
  if (rivals == 3) return [240, 300, 180];
  const priority = [
    240.0,
    300.0,
    180.0,
    0.0,
    120.0,
    60.0,
    330.0,
    210.0,
    30.0,
    150.0
  ];
  return priority.take(rivals).toList();
}

/// Puestos FIJOS del mockup-6 (corrección 26-oct, ≤5 rivales = 6
/// jugadores máx): 1 arriba al centro, 2 a la izquierda, 2 a la
/// derecha, yo abajo al centro. Orden de ocupación por pares y
/// centro arriba último (progresión simétrica; a 5 rivales están
/// los 5 ocupados y el orden ya no importa): superior-izquierda,
/// superior-derecha, inferior-izquierda, inferior-derecha, centro
/// arriba. Con menos rivales los puestos vacíos quedan libres: la
/// lista es un prefijo, nunca se rebalancea.
List<double> mockupAngles(int rivals) {
  const order = [225.0, 315.0, 135.0, 45.0, 270.0];
  if (rivals <= 0) return [];
  return order.take(rivals).toList();
}

/// Un asiento de la rama mockup-6 (geometría medida, ver informe
/// `audit/correccion_6jugadores_mesa.md`). Costados: avatar 58×58,
/// placa 88×34 SIEMPRE DEBAJO, vaso 56×64 hacia fuera en x (±67),
/// anclados a `sideCy` (cy − 18: compensa que la placa va debajo)
/// con separación vertical 52. Asiento superior central: el hueco
/// pozo~mi-vaso es de solo 80 px a 390 (pozo hasta 94, mi vaso
/// desde 174), así que avatar 58 + placa 34 (94 px) NO cabe:
/// avatar 48 + placa de UNA línea 88×18 (68 px). Avatar top =
/// tableTop + 38 (= 94, toca el pozo en rect sin solaparlo),
/// placa 144..162 (12 px de aire a mi vaso a 390, 4 px a mesa
/// 230); su
/// vaso va a la derecha junto al avatar (RONDA 3: centro cx + 57,
/// hueco 5 px; antes cx + 92: el radial hacia el centro
/// chocaría con mi vaso). Avatar top = tableTop + 38 (= 94: toca
/// el pozo en rect sin solaparlo) para que a mesa 206 su base
/// (142) toque mi vaso compacto (142) sin solaparlo. En mesa 178
/// el asiento superior ya no cabe en absoluto (mi vaso 114..166
/// contra avatar 94..142 y vaso superior contra mis dados):
/// residuo medido, ver informe. En mesa corta (206) la placa se
/// corre a la izquierda (left = cx − 200), siempre debajo del
/// avatar, limpia de mi vaso y mis dados.
SketchSeat mockupSeat({
  required double angle,
  required double cx,
  required double sideCy,
  required double sideDy,
  required double sideX,
  required double tableTop,
  required double myCupTop,
}) {
  if (angle == 270) {
    // Pila corta (ver cabecera): avatar 48 + placa de una línea.
    // Centrada si cabe sobre mi vaso; si no (mesa corta), corrida
    // a la izquierda en el hueco libre tras la placa lateral
    // (left = cx − sideX + 48: con sideX 200 queda en 270..358,
    // 4 px tras la placa lateral 178..266 y 42 px antes de mi
    // vaso; el cx − 200 viejo chocaba con esa placa lateral
    // cuando sideX bajó a 200, 440 px² a mesa 206), siempre
    // debajo del avatar.
    // RONDA 3 (F3e): el vaso va JUNTO a su avatar (hueco 5 px:
    // left = cx + 29, centro a 57 del centro del avatar), no a
    // cx + 64 (centro a 92: +10,9 puntos sobre el avatar, y
    // +9,1 sobre la referencia 49–55 %). Centrarlo exacto sobre
    // el avatar es imposible sin romper la columna (el vaso
    // bajo la placa solaparía mi vaso en 1456 px² a mesa 290 y
    // en 2288 px² a mesa 232 compacta, medido): piso = junto al
    // avatar con hueco estándar. Para que el vaso junto no tape
    // el texto de la placa (el widget la ensancha a 132 hacia la
    // derecha), la placa geométrica se corre 38 a la izquierda
    // (left = cx − 82): el widget queda en 340..472 (centro 406,
    // −16 del avatar, dentro del margen ±2–3 puntos), su texto
    // termina en ~451 y el vaso visual empieza en ~457 (aire
    // ~6 px). Sin este corrimiento el vaso taparía la cola del
    // texto ("El Huaso").
    final avatarTop = tableTop + 38;
    final plateTop = avatarTop + 50;
    final centered = plateTop + 18 + 2 <= myCupTop;
    return SketchSeat(
      angle,
      SketchRect('avatar-270', cx - 24, avatarTop, 48, 48),
      SketchRect('placa-270',
          centered ? cx - 82 : cx - sideX + 48, plateTop, 88, 18),
      SketchRect('vaso-270', cx + 29, avatarTop + 6, 56, 64),
      singleLinePlate: true,
    );
  }
  final left = angle == 225 || angle == 135;
  final upper = angle == 225 || angle == 315;
  final scx = left ? cx - sideX : cx + sideX;
  final scy = upper ? sideCy - sideDy : sideCy + sideDy;
  // RONDA 2 (26-oct, F3): vasos SOBRE el anillo junto a su avatar.
  // Superiores: hacia DENTRO (al centro): hacia fuera caían fuera
  // del óvalo (el óvalo se estrecha arriba: a la altura del vaso
  // superior el borde queda en x ~118 y el vaso exterior
  // 58..128 flotaba sobre la sala). Hacia dentro el vaso queda
  // sobre el paño junto al avatar (hueco 5 px) y con 3 px de aire
  // a la placa (su y se baja 2 para eso). Inferiores: hacia fuera
  // como siempre, pero a 62 (no 67): hueco 5 px al avatar.
  // En pantallas anchas (> 844, web/desktop), todos los vasos van orientados hacia
  // el interior de la mesa desde su lado (arreglo.md §4: izquierda +62, derecha -62).
  // En pantallas angostas (<= 844), los inferiores van hacia afuera para no tocar
  // los 5 dados centrales del jugador en 844x350.
  final cupCx = (cx * 2 > 844)
      ? (left ? scx + 62 : scx - 62)
      : (upper ? (left ? scx + 62 : scx - 62) : (left ? scx - 62 : scx + 62));
  final cupTop = upper ? scy - 4 - 32 : scy - 6 - 32;
  return SketchSeat(
    angle,
    SketchRect('avatar-${angle.round()}', scx - 29, scy - 29, 58, 58),
    SketchRect('placa-${angle.round()}', scx - 44, scy + 31, 88, 34),
    SketchRect('vaso-${angle.round()}', cupCx - 28, cupTop, 56, 64),
  );
}

/// Distribución de arco igual para ≥7 rivales (corrección
/// 25-oct). Muestrea la elipse, excluye los arcos donde el
/// asiento, su placa o su vaso tocarían el pozo, mi asiento, mi
/// vaso o mis dados, o donde la placa colgaría bajo la mesa, y
/// reparte los rivales a igual distancia de arco sobre lo que
/// queda. Devuelve ángulos en grados (misma convención: 0 =
/// costado derecho, 90 = abajo, 270 = arriba).
List<double> _equalArcAngles({
  required int rivals,
  required double screenW,
  required double cx,
  required double cy,
  required double rx,
  required double ry,
  required SketchRect pot,
  required SketchRect myAvatar,
  required SketchRect myPlate,
  required SketchRect myCup,
  required List<SketchRect> myDice,
  required double tableBottom,
  required bool compact,
}) {
  const steps = 1440;
  final px = <double>[];
  final py = <double>[];
  for (var i = 0; i < steps; i++) {
    final rad = i * 360.0 / steps * math.pi / 180;
    px.add(cx + rx * math.cos(rad));
    py.add(cy + ry * math.sin(rad));
  }

  bool blocked(double x, double y) {
    final av = SketchRect('tmp', x - 24, y - 24, 48, 48);
    if (av.left < 0 || av.right > screenW) return true;
    if (av.overlaps(pot) ||
        av.overlaps(myAvatar) ||
        av.overlaps(myPlate) ||
        av.overlaps(myCup)) {
      return true;
    }
    // NOTA ÁREA 2 (25-oct, intento revertido): el muestreador
    // comprueba una placa ENCIMA (y-68 / y-102) y un vaso
    // radial 52, mientras la colocación FINAL usa placa
    // SIEMPRE DEBAJO y vaso superior radial 100. Alinear el
    // muestreador a la geometría final se probó y se revirtió:
    // a 8 jugadores bajó de 2416 a 2046 px² (dados=5) pero
    // desplazó el apiñamiento a pares placa~placa y ROMPIÓ
    // el invariante avatar~avatar a 10 rivales (avatar-28 ~
    // avatar-41 < 50 px). La causa es vecina~vecina (el
    // muestreador solo mira elementos fijos, nunca el asiento
    // vecino), así que ningún ajuste del muestreador solo
    // cierra 8 jugadores: queda como propuesta para el final
    // del día (redistribución con chequeo par a par), no como
    // parche aquí.
    final plate = y < cy
        ? SketchRect('tmp', x - 42, y - 68, 84, 32)
        : SketchRect('tmp', x - 42, y + 27, 84, 32);
    final plateHigh =
        y < cy ? SketchRect('tmp', x - 42, y - 102, 84, 32) : null;
    if (plate.left < 0 || plate.right > screenW) return true;
    if (y >= cy && plate.bottom > tableBottom) return true;
    if (plate.overlaps(pot) ||
        plate.overlaps(myAvatar) ||
        plate.overlaps(myPlate) ||
        plate.overlaps(myCup)) {
      return true;
    }
    if (plateHigh != null && plateHigh.overlaps(pot)) return true;
    for (final d in myDice) {
      if (plate.overlaps(d)) return true;
    }
    // Vaso rect solo del vaso (40×46, sin posavasos: el
    // posavasos sobresale 7 px por lado y 4 px abajo en el
    // widget, pero es una elipse oscura sobre el paño, no
    // información jugable). Costados: hacia fuera en x (±54;
    // los vasos radiales de un par vertical se solapan); resto:
    // radial 52. Si el vaso toca su propio avatar, el ángulo
    // no sirve (bandas cerca de arriba/abajo). Si el vaso sale
    // de la página, tampoco (costados extremos).
    final side = ((x - cx) / rx).abs() >= 0.8;
    double ccx, ccy;
    if (side) {
      ccx = x + (x < cx ? -54.0 : 54.0);
      ccy = y - 4;
    } else {
      final dx = cx - x;
      final dy = cy - y;
      final len = math.sqrt(dx * dx + dy * dy);
      ccx = x + dx / len * 52;
      ccy = y + dy / len * 52;
    }
    final cup = SketchRect('tmp', ccx - 20, ccy - 23, 40, 46);
    if (cup.left < 0 || cup.right > screenW) return true;
    if (cup.overlaps(av)) return true;
    if (cup.overlaps(pot) ||
        cup.overlaps(myAvatar) ||
        cup.overlaps(myPlate) ||
        cup.overlaps(myCup)) {
      return true;
    }
    for (final d in myDice) {
      if (cup.overlaps(d)) return true;
    }
    return false;
  }

  // Arco permitido acumulado (los pasos bloqueados aportan 0).
  final allowed = <double>[0.0];
  for (var i = 1; i <= steps; i++) {
    final ax = px[(i - 1) % steps];
    final ay = py[(i - 1) % steps];
    final bx = px[i % steps];
    final by = py[i % steps];
    final seg = math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
    final blockedHere = blocked(bx, by);
    allowed.add(allowed.last + (blockedHere ? 0 : seg));
  }
  final total = allowed.last;
  if (total <= 0) return sketchAngles(rivals);

  double angleAt(double target) {
    // Búsqueda binaria sobre allowed.
    var lo = 0;
    var hi = steps;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (allowed[mid] < target) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final i = lo.clamp(1, steps);
    final prev = allowed[i - 1];
    final next = allowed[i];
    final f = next > prev ? (target - prev) / (next - prev) : 0.0;
    final a0 = (i - 1) * 360.0 / steps;
    final a1 = i * 360.0 / steps;
    return a0 + (a1 - a0) * f;
  }

  final out = <double>[];
  for (var k = 0; k < rivals; k++) {
    out.add(angleAt((k + 0.5) * total / rivals));
  }
  return out;
}

SketchLayout sketchLayout({
  required double screenW,
  required double screenH,
  required int rivals,
  required int myDiceCount,
  double tableTop = 56,
  double consoleH = 72,
}) {
  const tableLeft = 16.0;
  final tableW = screenW - 32;
  final tableH = screenH - tableTop - consoleH;
  final cx = screenW / 2;
  final cy = tableTop + tableH / 2;
  final rx = math.min(378.0, tableW / 2 - 36);
  // 7+ rivales: elipse más plana (70) para que los asientos
  // inferiores suban y sus placas quepan sobre la mesa.
  final ry = math.min(rivals >= 7 ? 70.0 : 90.0, tableH / 2 - 36);
  final table = SketchRect('mesa', tableLeft, tableTop, tableW, tableH);
  // Compacto (mesa < 262): vaso propio 44×52 y dados 28, o la
  // columna central (pozo + vaso + asiento) no cabe en 212.
  final compact = tableH < 262;
  // Pozo bosquejo: fila [POZO + vaso 30×36 + monto] de 140×36.
  final pot = SketchRect('pozo', cx - 70, tableTop + 2, 140, 36);
  final console =
      SketchRect('consola', 0, tableTop + tableH, screenW, consoleH);

  // Mi vaso y mis dados (banda inferior, hueco 104).
  final tableBottom = tableTop + tableH;
  final myCupBottom = tableBottom - 68;
  final myCupH = compact ? 52.0 : 76.0;
  final myCupW = compact ? 44.0 : 64.0;
  final myCup = SketchRect(
      'mi-vaso', cx - myCupW / 2, myCupBottom - myCupH, myCupW, myCupH);
  final dieSize = compact ? 28.0 : 48.0;
  final diceTop = myCup.top + (compact ? 24.0 : 8.0);
  final n = myDiceCount;
  final leftCount = n ~/ 2;
  final leftW =
      leftCount == 0 ? 0.0 : leftCount * dieSize + (leftCount - 1) * 2.0;
  final diceLeft = cx - 165 + 113.0 - leftW;
  final dice = <SketchRect>[];
  for (var i = 0; i < leftCount; i++) {
    dice.add(SketchRect(
        'dado-$i', diceLeft + i * (dieSize + 2), diceTop, dieSize, dieSize));
  }
  final rightStart = diceLeft + leftW + 104;
  for (var i = leftCount; i < n; i++) {
    dice.add(SketchRect('dado-$i', rightStart + (i - leftCount) * (dieSize + 2),
        diceTop, dieSize, dieSize));
  }

  // Mi asiento en fila: avatar + placa a la derecha, abajo.
  final myAvatar = SketchRect('mi-avatar', cx - 79, tableBottom - 64, 64, 64);
  final myPlate =
      SketchRect('mi-placa', myAvatar.right + 6, myAvatar.top + 15, 88, 34);

  // Ángulos: mockup-6 fijo hasta 5 rivales, referencia solo con
  // 6 rivales exactos, arco igual desde 7.
  final List<double> angles;
  if (rivals <= 5) {
    angles = mockupAngles(rivals);
  } else if (rivals <= 6) {
    angles = sketchAngles(rivals);
  } else {
    angles = _equalArcAngles(
      rivals: rivals,
      screenW: screenW,
      cx: cx,
      cy: cy,
      rx: rx,
      ry: ry,
      pot: pot,
      myAvatar: myAvatar,
      myPlate: myPlate,
      myCup: myCup,
      myDice: dice,
      tableBottom: tableBottom,
      compact: compact,
    );
  }

  // Rama mockup-6: columna lateral centrada en cy − 18 (compensa
  // la placa debajo) y con tope para que el avatar superior no
  // suba sobre la barra (top ≥ tableTop + 2). A mesa 178 el tope
  // manda y las placas inferiores desbordan bajo la mesa: residuo
  // medido, ver informe (a 390 y a mesa 206/250 no ocurre).
  final double mockupSideDy = screenH > 390
      ? (tableH * 0.22).clamp(52.0, 95.0)
      : 52.0;
  // En pantallas anchas (> 844), distribuir los asientos a lo largo de las curvas
  // de la mesa como en el mockup (arreglo.md §3/§5), conservando 262 en 844.
  final double mockupSideX = screenW > 844
      ? (screenW / 2 - 95).clamp(262.0, screenW * 0.38)
      : math.min(compact ? 200.0 : 262.0, screenW / 2 - 160);
  var mockupSideCy = cy - 18;
  final mockupSideCyMin = tableTop + 2 + mockupSideDy + 29;
  if (mockupSideCy < mockupSideCyMin) mockupSideCy = mockupSideCyMin;

  final seats = <SketchSeat>[];
  for (var seatIndex = 0; seatIndex < angles.length; seatIndex++) {
    final angle = angles[seatIndex];
    if (rivals <= 5) {
      seats.add(mockupSeat(
        angle: angle,
        cx: cx,
        sideCy: mockupSideCy,
        sideDy: mockupSideDy,
        sideX: mockupSideX,
        tableTop: tableTop,
        myCupTop: myCup.top,
      ));
      continue;
    }
    final rad = angle * math.pi / 180;
    final scx = cx + rx * math.cos(rad);
    final scy = cy + ry * math.sin(rad);
    final reference = rivals <= 6;
    final avatar = reference
        ? SketchRect('avatar-${angle.round()}', scx - 29, scy - 29, 58, 58)
        : SketchRect('avatar-${angle.round()}', scx - 24, scy - 24, 48, 48);
    SketchRect plate;
    // ÁREA 2 (mockup): placa SIEMPRE DEBAJO del avatar, sin
    // excepciones laterales (antes 240 iba a la izquierda y 300
    // a la derecha). Mi asiento en fila (derecha) es la única
    // excepción y queda intacto: debajo de mi avatar ya no hay
    // mesa (su borde inferior es tableBottom) y caería sobre
    // la consola.
    // Superiores 240/300: la placa va debajo pero desplazada
    // 16 px hacia fuera: centrada, su esquina choca con el
    // propio vaso radial (256 px² medidos a 390, 202 a 350);
    // con 16 px queda un aire de ~7 px al vaso y sigue debajo
    // del avatar (no es placa lateral: su borde superior sigue
    // a avatar.bottom+2).
    if (reference && (angle == 240 || angle == 300)) {
      final off = angle == 240 ? -16.0 : 16.0;
      plate = SketchRect(
          'placa-${angle.round()}', scx - 44 + off, avatar.bottom + 2, 88, 34);
    } else if (reference && (angle == 60 || angle == 120)) {
      // Inferiores de referencia: una sola línea debajo del
      // avatar, ahora de 120 (no 88): "×5 · El Huaso" a 14 px
      // mide ~110 y en 88 se cortaba ("El Hu...").
      plate = SketchRect(
          'placa-${angle.round()}', scx - 60, avatar.bottom + 2, 120, 18);
    } else if (reference) {
      plate = SketchRect(
          'placa-${angle.round()}', scx - 44, avatar.bottom + 2, 88, 34);
    } else {
      // Arco igual, orden mockup (25-oct, orden del usuario):
      // placa SIEMPRE DEBAJO del avatar, hacia el centro, como
      // en el mockup (placa bajo la foto, nunca encima hacia
      // la barra superior). Antes la superior iba ENCIMA y
      // chocaba con la barra y la píldora de turno. El vaso
      // superior se corre más adentro (r 100, abajo) para no
      // tapar esta placa.
      plate = SketchRect(
          'placa-${angle.round()}', scx - 42, avatar.bottom + 2, 84, 32);
    }
    SketchRect cup;
    if (reference && (angle == 60 || angle == 120)) {
      // Inferiores de referencia: hacia fuera en x para no
      // invadir mi banda de dados (dy -4 en ambas variantes:
      // con +10 en compacto la placa-120 tocaba su vaso en
      // 88 px² medidos).
      // RONDA 2 (F3): 66 → 62, hueco 5 px al avatar (era 9).
      final off = angle == 60 ? 62.0 : -62.0;
      cup = SketchRect(
          'vaso-${angle.round()}', scx + off - 28, scy - 4 - 32, 56, 64);
    } else if (!reference && (math.cos(rad).abs() >= 0.8)) {
      // Arco igual, costados: vaso hacia fuera en x (±54;
      // radial solaparía el vaso del par vertical).
      final off = scx < cx ? -54.0 : 54.0;
      cup = SketchRect(
          'vaso-${angle.round()}', scx + off - 20, scy - 4 - 23, 40, 46);
    } else {
      // Rect solo del vaso; el posavasos sobresale en el widget
      // pero no es información jugable. Referencia 56×64,
      // arco igual 40×46 (radial 52: ver cabecera).
      // RONDA 2 (F3): radial 80 → 74 (costados) y 68 → 64 (resto):
      // vasos 4–6 px más junto a su avatar, sin tocarlo (hueco ≥7).
      final r = reference
          ? ((angle == 0 || angle == 180) ? 74.0 : 64.0)
          : (scy < cy ? 100.0 : 52.0);
      final dx = cx - scx;
      final dy = cy - scy;
      final len = math.sqrt(dx * dx + dy * dy);
      final ccx = scx + dx / len * r;
      final ccy = scy + dy / len * r;
      final cw = reference ? 56.0 : 40.0;
      final ch = reference ? 64.0 : 46.0;
      cup = SketchRect(
          'vaso-${angle.round()}', ccx - cw / 2, ccy - ch / 2, cw, ch);
    }
    seats.add(SketchSeat(angle, avatar, plate, cup));
  }

  return SketchLayout(
    screenW: screenW,
    tableTop: tableTop,
    tableH: tableH,
    tableLeft: tableLeft,
    tableW: tableW,
    consoleH: consoleH,
    table: table,
    pot: pot,
    seats: seats,
    myDice: dice,
    myCup: myCup,
    myAvatar: myAvatar,
    myPlate: myPlate,
    console: console,
  );
}
