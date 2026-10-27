import 'package:flutter/material.dart';

import 'state/settings.dart';
import 'theme.dart';

/// Mesas temáticas de la v2.0, Fase A (sentencia v2.0 frontend).
/// La mesa viaja con la sala: todos ven la misma. El neón vive SOLO
/// dentro del rectángulo-mesa (marco y miniatura); fuera de ahí,
/// Cuero y Paño y dorado envejecido, como siempre.

const String tableThemePub = 'pub';
const String tableThemeDorado = 'dorado';
const String tableThemeNeon = 'neon';

/// Mesa por defecto de las salas nuevas (decisión D1).
const String defaultTableTheme = tableThemeDorado;

bool isValidTableTheme(String? id) =>
    id == tableThemePub || id == tableThemeDorado || id == tableThemeNeon;

String tableThemeName(String id) => switch (id) {
      tableThemePub => 'El Pub',
      tableThemeNeon => 'Neón Nocturno',
      _ => 'Casino Dorado',
    };

/// Fondo de la pantalla de partida según la mesa. El Pub mantiene su
/// foto de bar; Casino Dorado usa el paño verde; Neón usa fondo
/// oscuro (el brillo va en el marco, no en toda la pantalla).
BoxDecoration tableThemeDecoration(String id) {
  if (id == tableThemePub) return pubDecoration;
  if (id == tableThemeNeon) {
    return const BoxDecoration(color: Color(0xFF05070C));
  }
  return feltDecoration;
}

/// Color del marco neón (solo dentro del rectángulo-mesa).
const neonFrameColor = Color(0xFF37E6FF);

/// Sala horizontal (Etapa 4, prototipo): la sala PIL vive FUERA del
/// rectángulo-mesa; el rectángulo lleva el paño/madera y el marco.
/// El vertical NO usa estas funciones (queda congelado).
BoxDecoration landscapeRoomDecoration(String id) {
  if (id == tableThemePub) {
    return const BoxDecoration(
      color: Color(0xFF0D0906),
      image: DecorationImage(
        image: AssetImage('assets/images/bg_pub.jpg'),
        fit: BoxFit.cover,
      ),
    );
  }
  if (id == tableThemeNeon) {
    // R41: textura oscura propia (grano + viñeta, casi negra,
    // sin cian, sin animación) en vez del plano vacío.
    return const BoxDecoration(
      color: Color(0xFF05070C),
      image: DecorationImage(
        image: AssetImage('assets/images/room_neon_dark.png'),
        fit: BoxFit.cover,
      ),
    );
  }
  // RONDA 3 (F3f): taberna difuminada PROPIA (generada
  // proceduralmente, sin foto ni arte copiado) en vez del
  // casi-negro plano de room_dorado.png (que medía #020101
  // tras el tinte del tier): halos cálidos y barra difuminados,
  // sin personas ni texto, para que detrás del óvalo haya
  // ambiente sin robar contraste a mesa ni placas.
  return const BoxDecoration(
    color: Color(0xFF0D0906),
    image: DecorationImage(
      image: AssetImage('assets/images/room_taverna_blur.jpg'),
      fit: BoxFit.cover,
    ),
  );
}

/// Relleno + marco del rectángulo-mesa en horizontal (Etapa 4).
BoxDecoration landscapeTableDecoration(String id) {
  if (id == tableThemeNeon) {
    return BoxDecoration(
      color: const Color(0xFF05070C),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: neonFrameColor, width: 2.5),
    );
  }
  if (id == tableThemePub) {
    return BoxDecoration(
      color: const Color(0xFF2A1A0E),
      image: DecorationImage(
        image: AssetImage('assets/images/wood.png'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Color(0x40000000),
          BlendMode.srcOver,
        ),
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF2A1A0E), width: 8),
    );
  }
  // Dorado = NEGRO/carbón (bosquejo/master prompt §2): el verde
  // queda solo para El Pub y para el tier La Taberna. Sin imagen de
  // paño verde.
  return BoxDecoration(
    color: const Color(0xFF171717),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: const Color(0xFF2A1A0E), width: 8),
  );
}

/// R38 (rediseño completo): doble filete del marco en horizontal —
/// exterior madera oscura (o cian 2,5 en Neón, que solo vive dentro
/// del rectángulo-mesa) + filete interior dorado mate + línea fina
/// marfil al 20 % por dentro, como el ribete de un paño de casino
/// real. Solo bordes, sin tocar assets ni geometría.
Color landscapeFilletColor(String id) =>
    CachoColors.gold.withValues(alpha: 0.9);

/// Línea fina interior del doble filete (R38): marfil al 20 %.
Color landscapeFilletInnerColor(String id) =>
    CachoColors.ivory.withValues(alpha: 0.20);

/// Variantes de sala y paño según el MONTO DE APUESTA (enmienda
/// 11b, 25-oct ~03:54): en partida el tier manda sobre el selector
/// de tema (interacción PENDIENTE de aprobación). El paño NEGRO de
/// la referencia es Casino Dorado (500, definitivo por el usuario);
/// las demás variantes son PROPUESTAS con captura, NO definitivas
/// sin su sí. La guiada (apuesta 0) no tiene tier y usa el tema
/// elegido en la hoja (el llamador decide, no esta función).
class TierLook {
  final String name;
  final Color feltCenter;
  final Color feltEdge;
  final Color rimTop;
  final Color rimBottom;
  final Color roomTint;
  final double filletWidth;
  final bool doubleFillet;
  const TierLook({
    required this.name,
    required this.feltCenter,
    required this.feltEdge,
    required this.rimTop,
    required this.rimBottom,
    required this.roomTint,
    this.filletWidth = 0,
    this.doubleFillet = false,
  });
}

TierLook tierLookFor(int stake) {
  switch (stake) {
    case 100:
      // PROPUESTA La Taberna: paño verde barrial clásico + sala pub.
      // Nombre nuevo docs/19 C7; el monto (100) y el paño no cambian.
      return const TierLook(
        name: 'La Taberna',
        feltCenter: Color(0xFF0B5D3B),
        feltEdge: Color(0xFF083020),
        rimTop: Color(0xFF8A5A30),
        rimBottom: Color(0xFF4A2C14),
        roomTint: Color(0x00000000),
      );
    case 250:
      // PROPUESTA El Boliche: paño azul noche + sala pub atenuada.
      // Nombre nuevo docs/19 C7; el monto (250) y el paño no cambian.
      return const TierLook(
        name: 'El Boliche',
        feltCenter: Color(0xFF14324A),
        feltEdge: Color(0xFF0C2233),
        rimTop: Color(0xFF7A4E28),
        rimBottom: Color(0xFF422710),
        roomTint: Color(0x400A1626),
      );
    case 1000:
      // PROPUESTA La Mansión: paño púrpura oscuro + filete dorado +
      // sala oscura. El negro/carbón queda RESERVADO a El Casino 500
      // (sentencia F1): la versión anterior (grafito) se apropiaba
      // de esa identidad y se corrigió a púrpura.
      // Nombre nuevo docs/19 C7; el monto (1000) y el paño no cambian.
      return const TierLook(
        name: 'La Mansión',
        feltCenter: Color(0xFF2E1B3A),
        feltEdge: Color(0xFF1D1024),
        rimTop: Color(0xFF5A3A1E),
        rimBottom: Color(0xFF2E1C0D),
        roomTint: Color(0x99000000),
        filletWidth: 2,
      );
    case 2500:
      // PROPUESTA El Club VIP: paño bronce + doble filete dorado +
      // sala casi negra. La versión anterior (negro profundo) se
      // apropiaba del negro reservado a El Casino 500; se corrigió a
      // bronce, claramente distinto del carbón.
      // Nombre nuevo docs/19 C7; el monto (2500) y el paño no cambian.
      return const TierLook(
        name: 'El Club VIP',
        feltCenter: Color(0xFF4A3512),
        feltEdge: Color(0xFF2E2008),
        rimTop: Color(0xFF5A3A1E),
        rimBottom: Color(0xFF2E1C0D),
        roomTint: Color(0xCC000000),
        filletWidth: 2,
        doubleFillet: true,
      );
    default:
      // El Casino 500 = paño NEGRO/carbón de la referencia (definitivo).
      // Nombre nuevo docs/19 C7; el monto (500) y el paño no cambian.
      return const TierLook(
        name: 'El Casino',
        feltCenter: Color(0xFF171717),
        feltEdge: Color(0xFF0C0C0C),
        rimTop: Color(0xFF5A3A1E),
        rimBottom: Color(0xFF2E1C0D),
        // RONDA 3 (F3f): tinte 0xB8 → 0x55: con 0xB8 la taberna
        // nueva quedaba otra vez en negro plano (0,28× brillo);
        // con 0x55 (0,67×) los halos cálidos se leen detrás del
        // óvalo y la mesa opaca + placas (fondo negro 0,72 con
        // texto marfil) mantienen su contraste.
        roomTint: Color(0x55000000),
      );
  }
}

/// Asset de la sala por tema, para miniaturas reales (R12/R19).
String tableRoomAsset(String id) => switch (id) {
      tableThemePub => 'assets/images/bg_pub.jpg',
      tableThemeNeon => 'assets/images/room_neon_dark.png',
      // RONDA 3 (F3f): la miniatura del tema usa la misma
      // taberna difuminada que el fondo de partida.
      _ => 'assets/images/room_taverna_blur.jpg',
    };

/// Miniatura REAL del tema (R12): la foto de la sala + el
/// rectángulo-mesa con los colores y el marco reales del tema, a
/// escala (no un bloque de color abstracto). El cian de Neón vive
/// solo dentro de esta miniatura.
class ThemeMiniature extends StatelessWidget {
  final String id;
  final double height;
  const ThemeMiniature({super.key, required this.id, this.height = 44});

  @override
  Widget build(BuildContext context) {
    final frame = id == tableThemeNeon
        ? neonFrameColor
        : const Color(0xFF2A1A0E);
    // Dorado = carbón (bosquejo), no verde: el verde es de El Pub
    // (tema) y del tier La Taberna.
    final fill = id == tableThemeNeon
        ? const Color(0xFF05070C)
        : (id == tableThemePub
            ? const Color(0xFF2A1A0E)
            : const Color(0xFF171717));
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(tableRoomAsset(id), fit: BoxFit.cover),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.72,
                heightFactor: 0.62,
                child: Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: frame,
                        width: id == tableThemeNeon ? 1.5 : 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nombre del tier por apuesta (docs/19 C7: nombres nuevos,
/// montos sin cambiar). Lo usan buscar_salas, lobby y el
/// StakePicker, así que el cambio se propaga a todas las tarjetas.
String stakeTierName(int stake) => switch (stake) {
      0 => 'Sin apuesta',
      100 => 'La Taberna',
      250 => 'El Boliche',
      500 => 'El Casino',
      1000 => 'La Mansión',
      2500 => 'El Club VIP',
      _ => 'Mesa $stake',
    };

/// Mesas en el orden del selector.
const _themeIds = [tableThemePub, tableThemeDorado, tableThemeNeon];

/// Selector de mesa para las hojas de creación (local y en línea).
/// R12: miniatura REAL de cada tema (foto de sala + rectángulo-mesa
/// con sus colores y marco). Seleccionado: borde dorado 2 px (R34).
/// Cada opción mide ≥44 px.
class TableThemePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const TableThemePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Fase 2: la transición propia del picker (200 ms) respeta el
    // interruptor de animaciones y reduce-motion: con el gate apagado
    // es instantánea, exactamente como antes (sin animar).
    final bool animOn = Settings.instance.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    final Duration pickDuration =
        animOn ? const Duration(milliseconds: 200) : Duration.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Mesa',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var k = 0; k < _themeIds.length; k++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: k < 2 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onChanged(_themeIds[k]),
                    // F9: la elegida crece +4 px con borde dorado
                    // y fundido cruzado (AnimatedContainer +
                    // AnimatedSwitcher); la mesa toma el tema nuevo
                    // en la partida siguiente, no a mitad de partida.
                    child: AnimatedContainer(
                      duration: pickDuration,
                      height: value == _themeIds[k] ? 92 : 88,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: value == _themeIds[k]
                              ? CachoColors.gold
                              : Colors.white24,
                          width: value == _themeIds[k] ? 2 : 1,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: pickDuration,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Column(
                          key: ValueKey(value == _themeIds[k]),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          ThemeMiniature(id: _themeIds[k], height: 36),
                          const SizedBox(height: 4),
                          // Nombre en 2 líneas: "Casino Dorado" y
                          // "Neón Nocturno" truncaban a 1 línea
                          // ("Casino Do…", captura 2026-10-25).
                          Text(
                            tableThemeName(_themeIds[k]),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: value == _themeIds[k]
                                  ? CachoColors.gold
                                  : CachoColors.ivory,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
