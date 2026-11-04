import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../table_themes.dart';
import '../widgets/panels.dart';
import '../theme.dart';
import '../widgets/casino_anims.dart';
import '../widgets/coin_widgets.dart';
import '../widgets/rotate_notice.dart';
import '../state/wallet.dart';
import '../config/room_configs.dart';

/// Paleta casino de MENU (sin cafe, 25-oct): fondos oscuros de la
/// familia del buscar_bg (azul noche -> casi negro -> purpura
/// profundo) con dorado mate #C9A24B (CachoColors.gold) como acento.
/// Constantes LOCALES de este archivo: theme.dart la redefine otro
/// agente y no se toca ni se redefine aqui.
const _menuCasino = Color(0xFF16203A);
const _menuCasinoDeep = Color(0xFF0B0B14);

/// R1 (rediseño completo): franja superior única de 56 px en casino oscuro
/// con filete dorado fino abajo. Home: saldo + rescate (si
/// existe) + Ajustes + Ayuda. Nada suelto sobre foto.
class HomeStrip extends StatelessWidget {
  final int balance;
  final bool canRescue;
  final VoidCallback onRescue;
  final VoidCallback onSettings;
  final VoidCallback onHelp;
  const HomeStrip({
    super.key,
    required this.balance,
    required this.canRescue,
    required this.onRescue,
    required this.onSettings,
    required this.onHelp,
  });

  Widget _pillButton(
      {required IconData icon,
      required String tooltip,
      required VoidCallback onTap}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _menuCasinoDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: CachoColors.gold.withValues(alpha: 0.55)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 22, color: CachoColors.gold),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _menuCasino,
        border: Border(
          bottom: BorderSide(
              color: CachoColors.gold.withValues(alpha: 0.55)),
        ),
      ),
      child: Row(
        children: [
          BalanceChip(balance: balance),
          if (canRescue) ...[
            const SizedBox(width: 8),
            Flexible(
              child: TextButton.icon(
                onPressed: onRescue,
                icon: const Icon(Icons.savings_outlined, size: 16),
                label: Text(
                  'Rescate +${coinsText(Wallet.rescueCoins)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: CachoColors.gold,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 44),
                ),
              ),
            ),
          ],
          const Spacer(),
          _pillButton(
              icon: Icons.tune, tooltip: 'Ajustes', onTap: onSettings),
          const SizedBox(width: 8),
          _pillButton(
              icon: Icons.help_outline,
              tooltip: 'Ayuda',
              onTap: onHelp),
        ],
      ),
    );
  }
}

/// R9/R29: franja de hoja propia — atrás 44×44 + título centrado +
/// saldo de la modalidad a la derecha (local: cifra real; en línea:
/// etiqueta "EN LÍNEA", sin cifra local mezclada, R17).
class SheetStrip extends StatelessWidget {
  final String title;
  final Widget? right;
  const SheetStrip({super.key, required this.title, this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _menuCasino,
        border: Border(
          bottom: BorderSide(
              color: CachoColors.gold.withValues(alpha: 0.55)),
        ),
      ),
      // Título con FittedBox scaleDown: a 18 px cuando cabe y
      // encogido (nunca cortado ni solapado con el saldo) cuando
      // el título es largo ("CONTRA LA MÁQUINA" solapaba el chip
      // de saldo en la captura 2026-10-25).
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 22, color: CachoColors.gold),
            tooltip: 'Atrás',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
                minWidth: 44, minHeight: 44),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_emblem.png',
                  height: 26,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: CachoFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: CachoColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          right ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Respuesta animada al toque (fase 2, frente A): escala 0,97
/// solo mientras el puntero está abajo, 150 ms, sin bucle y sin
/// mover el layout (Transform). Con animaciones apagadas o
/// reduce-motion devuelve el hijo tal cual, sin Listener ni
/// escala: el toque se comporta exactamente como antes. Usa
/// Listener (no GestureDetector) para no competir con el onTap
/// del hijo (ChoiceChip / InkWell) en la arena de gestos.
class _PressScale extends StatefulWidget {
  final Widget child;
  const _PressScale({required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// R13: placa del pozo fija justo sobre JUGAR/CREAR — dos líneas a
/// 14 px: fórmula con "jugadores" siempre junto a ×N (nunca ×N
/// aislado) y saldo en menor jerarquía, también a 14 px.
/// TODO HORIZONTAL: `compact` pone fórmula y saldo en UNA fila
/// (altura ~40 px en vez de ~62) para el pie horizontal de la hoja
/// local; por defecto sigue apilada (Con amigos mantiene la frase
/// larga de saldo apilada). Sin cambios de texto, color ni tamaño.
class PotPlaque extends StatelessWidget {
  final String formula;
  final String? saldoLine;
  final bool compact;
  const PotPlaque(
      {super.key,
      required this.formula,
      this.saldoLine,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Mismo relieve que las tarjetas del lobby: degradado
        // casino oscuro + sombra neutra, solo paleta casino.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _menuCasino,
            _menuCasinoDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: CachoColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: compact
          // Fila horizontal: fórmula y saldo lado a lado, cada uno
          // con hasta 2 líneas (en el pie ancho caben en 1; en el
          // caso límite de saldo 0 la frase larga envuelve, nunca
          // se corta ni se esconde).
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(formula,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CachoColors.gold)),
                ),
                if (saldoLine != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(saldoLine!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70)),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(formula,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CachoColors.gold)),
                if (saldoLine != null) ...[
                  const SizedBox(height: 2),
                  Text(saldoLine!,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70)),
                ],
              ],
            ),
    );
  }
}

/// R16: presets a 44 px, texto a 14 px, seleccionado dorado mate
/// con ✓, resto casino oscuro con borde dorado; "Ver qué cambia" a 14 px
/// y 44 px de alto, abre la misma explicación que hoy.
class PresetRow extends StatelessWidget {
  final String preset;
  final ValueChanged<String> onChanged;
  const PresetRow(
      {super.key, required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String key, String label) {
      final selected = preset == key;
      // Respuesta al toque: _PressScale (0,97, 150 ms). La
      // transición del estado seleccionado la anima el propio
      // ChoiceChip; aquí no se cambia su tipo ni su lógica.
      return _PressScale(
        child: ChoiceChip(
        label: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
        selected: selected,
        onSelected: (_) => onChanged(key),
        selectedColor: CachoColors.gold,
        backgroundColor: _menuCasino,
        labelStyle: TextStyle(
          color: selected
              ? const Color(0xFF2B1810)
              : CachoColors.ivory,
        ),
        side: BorderSide(
            color: CachoColors.gold
                .withValues(alpha: selected ? 1 : 0.55)),
        ),
      );
    }

    // TODO HORIZONTAL: chips + "Ver qué cambia" en un Wrap: en
    // una sola fila cuando la columna da el ancho (escritorio y
    // horizontal ancho), y envuelto a segunda línea cuando no.
    // Nunca se corta: el Wrap envuelve en vez de truncar (el
    // corte "Ver qué cam…" de la captura 2026-10-25 era por fila
    // fija; aquí no hay fila fija).
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 0,
      children: [
        chip('completo', 'Cacho completo'),
        chip('clasico', 'Clásico'),
        TextButton(
          style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft),
          onPressed: () => showPresetInfo(
            context,
            preset == 'clasico' ? 'Clásico' : 'Cacho completo',
            preset == 'clasico'
                ? GameConfig.clasico()
                : GameConfig.cachoCompleto(),
          ),
          child: const Text('Ver qué cambia',
              style: TextStyle(color: CachoColors.gold, fontSize: 14)),
        ),
      ],
    );
  }
}

/// R11: dificultad en segmentado compacto — 3 opciones en una
/// fila, cada una ≥44 px; seleccionada dorado mate, resto casino oscuro;
/// el subtítulo solo de la seleccionada, a 14 px, debajo.
class DifficultySegmented extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const DifficultySegmented(
      {super.key, required this.value, required this.onChanged});

  static const _opts = [
    ('facil', 'Fácil', 'juegan más al azar'),
    ('media', 'Media', 'piensan un poco sus apuestas'),
    ('dificil', 'Difícil', 'calculan probabilidades y hacen faroles'),
  ];

  @override
  Widget build(BuildContext context) {
    // Gate para la duración: con animaciones apagadas o
    // reduce-motion, la transición es instantánea (0 ms).
    final animOn = CasinoAnims.enabledIn(context);
    final desc =
        _opts.firstWhere((o) => o.$1 == value, orElse: () => _opts[1]).$3;
    // TODO HORIZONTAL: la etiqueta va EN LÍNEA a la izquierda
    // del segmentado (antes ocupaba su propia línea: 94 → ~68 px
    // de alto total). El subtítulo de la seleccionada sigue
    // debajo, a 14 px, en una línea con ellipsis de seguridad
    // (a ≥320 px de columna cabe entero).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Dificultad',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            for (var i = 0; i < _opts.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                // Respuesta al toque: _PressScale (0,97, 150 ms).
                // Transición del seleccionado: AnimatedContainer
                // 300 ms (color de fondo + borde); el Material
                // queda transparente para no tapar el ripple del
                // InkWell, que se pinta sobre él.
                child: _PressScale(
                  child: AnimatedContainer(
                    duration: animOn
                        ? const Duration(milliseconds: 300)
                        : Duration.zero,
                    decoration: BoxDecoration(
                      color: value == _opts[i].$1
                          ? CachoColors.gold
                          : _menuCasino,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CachoColors.gold.withValues(
                            alpha: value == _opts[i].$1 ? 1 : 0.55),
                        width: value == _opts[i].$1 ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onChanged(_opts[i].$1),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(
                            _opts[i].$2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: value == _opts[i].$1
                                  ? const Color(0xFF2B1810)
                                  : CachoColors.ivory,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}

/// R14: contador de bots — botones 44×44, número a 20 px en
/// negrita, etiqueta a 14 px con el rango real "1–5" (corrección
/// 26-oct 09:35: máximo 6 jugadores en total, yo + 5 bots). En los
/// extremos el botón se deshabilita (dorado 30 %, sin desaparecer).
class BotsStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const BotsStepper(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) {
      return IconButton(
        icon: Icon(icon,
            size: 24,
            color: enabled
                ? CachoColors.gold
                : CachoColors.gold.withValues(alpha: 0.3)),
        tooltip: enabled ? null : 'Límite alcanzado',
        padding: EdgeInsets.zero,
        constraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: enabled ? onTap : null,
      );
    }

    // TODO HORIZONTAL (corrección truncación 26-oct): etiqueta en
    // Expanded SIN Spacer: el Spacer (flex 1) se quedaba con la mitad
    // del resto tras los botones y la etiqueta ("Bots en la mesa (1–5)",
    // ~164 px a 14 px negrita) elidía en columna de ~398 px. Sin
    // Spacer, la etiqueta toma todo el resto (~274 px) y cabe entera.
    return Row(
      children: [
        Expanded(
          child: Text('Bots en la mesa (1–5)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        btn(Icons.remove_circle_outline, value > 1,
            () => onChanged(value - 1)),
        SizedBox(
          width: 36,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        btn(Icons.add_circle_outline, value < 5,
            () => onChanged(value + 1)),
      ],
    );
  }
}

/// TODO HORIZONTAL: cuerpo de las hojas de creación en DOS
/// columnas (reemplaza la columna vertical única; no convive con
/// ella). El scroll vertical ya no es la estructura: solo queda
/// como respaldo cuando la altura no da (a 844×390 faltan
/// ~60–70 px en la hoja local por la altura fija de los pickers
/// compartidos; el pie queda FUERA del scroll, siempre visible y
/// sin tapar ninguna fila). Ancho ≥700 px: dos columnas
/// expandibles, centradas con tope 1120 px (escritorio aprovecha
/// sin estirar sprites ni textos: las fuentes son fijas).
/// Ancho <700 px: LAS MISMAS dos columnas a 320 px fijas con
/// scroll horizontal — no es un layout vertical de portrait
/// (portrait lo cubre el aviso de girar del frente D), solo evita
/// overflows si la hoja se llega a ver estrecha. Con 320 px el
/// StakePicker sigue sin truncar nombres de tier (a ≥330 usa
/// 3 columnas).
class _SetupColumns extends StatelessWidget {
  final List<Widget> left;
  final List<Widget> right;
  const _SetupColumns({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= 700) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: left,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: left,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: right,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// R9: hoja CONTRA LA MÁQUINA como pantalla propia (franja R1 +
/// fondo R31 + atrás 44×44), mismo contenido y orden que la hoja
/// anterior. Placa fija sobre JUGAR (R13) y JUGAR último, 56 px,
/// Cinzel 18, nada debajo (R18).
class LocalSetupScreen extends StatefulWidget {
  final String initialPreset;
  final void Function({
    required int bots,
    required String difficulty,
    required int stake,
    required String tableTheme,
    required String preset,
  }) onPlay;
  const LocalSetupScreen({
    super.key,
    required this.initialPreset,
    required this.onPlay,
  });

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  var _bots = 3;
  var _difficulty = 'media';
  var _stake = 500;
  var _tableTheme = defaultTableTheme;
  late var _preset = widget.initialPreset;

  @override
  void initState() {
    super.initState();
    if (_stake > Wallet.instance.balance) {
      _stake = Wallet.stakes.lastWhere((x) => x <= Wallet.instance.balance,
          orElse: () => 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = Wallet.instance.balance;
    final players = _bots + 1;
    return Scaffold(
      body: DecoratedBox(
        decoration: menuDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Entrada de la hoja (fase 2, frente A): StaggerIn
              // existente, 250 ms, una sola vez al montar; con
              // animaciones apagadas devuelve el hijo tal cual.
              StaggerIn(
                index: 0,
                child: SheetStrip(
                  title: 'CONTRA LA MÁQUINA',
                  right: BalanceChip(balance: balance),
                ),
              ),
              // TODO HORIZONTAL: dos columnas (izquierda:
              // bots/dificultad/preset; derecha: apuesta/mesa).
              // El pie queda FUERA del scroll, en flujo normal:
              // siempre visible y sin tapar ninguna fila.
              Expanded(
                child: _SetupColumns(
                  left: [
                    StaggerIn(
                      index: 0,
                      child: const Text(
                        'Sin internet. Juegas contra bots en tu celular.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      index: 1,
                      child: BotsStepper(
                        value: _bots,
                        onChanged: (v) => setState(() => _bots = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      index: 2,
                      child: DifficultySegmented(
                        value: _difficulty,
                        onChanged: (v) =>
                            setState(() => _difficulty = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      index: 3,
                      child: PresetRow(
                        preset: _preset,
                        onChanged: (v) => setState(() => _preset = v),
                      ),
                    ),
                  ],
                  right: [
                    StaggerIn(
                      index: 4,
                      child: StakePicker(
                        value: _stake,
                        balance: balance,
                        onChanged: (v) => setState(() => _stake = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      index: 5,
                      child: TableThemePicker(
                        value: _tableTheme,
                        onChanged: (v) =>
                            setState(() => _tableTheme = v),
                      ),
                    ),
                  ],
                ),
              ),
              // Pie horizontal: placa compacta + JUGAR en una
              // fila (ancho), o apilados (estrecho). AN4: shimmer
              // mate en el botón dorado principal, intacto.
              StaggerIn(
                index: 5,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final playButton = SweepGlow(
                      cycle: const Duration(seconds: 3),
                      peakOpacity: 0.12,
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: BronzeButton(
                          label: 'JUGAR',
                          icon: Icons.play_arrow,
                          fontSize: 18,
                          fontFamily: CachoFonts.display,
                          onPressed: () async {
                            // M2: aviso de giro fuera de partida.
                            if (!await RotateNotice.confirmIfPortrait(
                                context)) {
                              return;
                            }
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            widget.onPlay(
                              bots: _bots,
                              difficulty: _difficulty,
                              stake: _stake,
                              tableTheme: _tableTheme,
                              preset: _preset,
                            );
                          },
                        ),
                      ),
                    );
                    final plaque = PotPlaque(
                      compact: box.maxWidth >= 700,
                      formula: _stake == 0
                          ? 'POZO = 0 × $players jugadores = 0'
                          : 'POZO = ${coinsText(_stake)} × $players jugadores = ${coinsText(_stake * players)}',
                      saldoLine: _stake == 0
                          ? 'Sin apuesta: tu saldo no alcanza ni la mínima. Usa el rescate del inicio.'
                          : 'Tu saldo local: ${coinsText(balance)}',
                    );
                    if (box.maxWidth >= 700) {
                      return Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 1120),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Expanded(child: plaque),
                                const SizedBox(width: 12),
                                SizedBox(width: 230, child: playButton),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          plaque,
                          const SizedBox(height: 8),
                          playButton,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla moderna 'JUGAR CON AMIGOS' estilo Casino AAA (v3.0).
/// Rediseñada desde cero:
/// - Selector de pestañas: 'CREAR SALA' vs 'UNIRSE CON CÓDIGO'.
/// - Carrusel visual de las 5 mesas 2D reales con sus apuestas y pozos.
/// - Opciones de juego esenciales (Cacho Completo vs Clásico).
/// - Indicadores interactivos de funciones sociales (Micrófono P2P & Rockola YouTube/Spotify).
/// - Entrada estilizada de código de sala con botón 'Pegar'.
class FriendsSetupScreen extends StatefulWidget {
  final String initialPreset;
  final bool? onlineOk;
  final VoidCallback onRetryProbe;
  final TextEditingController joinCode;
  final void Function({
    required int stake,
    required String tableTheme,
    required String preset,
  }) onCreate;
  final void Function(String code) onJoin;

  const FriendsSetupScreen({
    super.key,
    required this.initialPreset,
    required this.onlineOk,
    required this.onRetryProbe,
    required this.joinCode,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  State<FriendsSetupScreen> createState() => _FriendsSetupScreenState();
}

class _FriendsSetupScreenState extends State<FriendsSetupScreen>
    with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0 = Crear Sala, 1 = Unirse
  late int _selectedStake;
  late String _preset;
  bool _voiceChatActive = true;
  bool _musicSocialActive = true;

  // Las 5 mesas reales disponibles para salas privadas
  final List<RoomConfig> _rooms = [
    roomTaberna,
    roomBoliche,
    roomCasino,
    roomMansion,
    roomVip,
  ];

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _selectedStake = 500;
    if (_selectedStake > Wallet.instance.balance) {
      _selectedStake = Wallet.stakes.lastWhere(
        (x) => x <= Wallet.instance.balance,
        orElse: () => Wallet.stakes.first,
      );
    }
  }

  RoomConfig get _currentRoom =>
      _rooms.firstWhere((r) => r.entryFee == _selectedStake, orElse: () => _rooms[2]);

  @override
  Widget build(BuildContext context) {
    final onlineOk = widget.onlineOk;

    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      body: Stack(
        children: [
          // Fondo ambiental cálido de taberna/casino difuminado
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                _currentRoom.roomBackgroundAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF070B12).withValues(alpha: 0.92),
                    const Color(0xFF090E17).withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Bar de Navegación con saldo del jugador
                _buildTopBar(),

                // Si no hay conexión al servidor
                if (onlineOk == false) ...[
                  Expanded(child: _buildOfflineState()),
                ] else ...[
                  // 2. Selector de Pestañas (CREAR SALA / UNIRSE)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _buildTabBar(),
                  ),

                  // 3. Contenido de la pestaña activa
                  Expanded(
                    child: _activeTab == 0
                        ? _buildCreateRoomTab()
                        : _buildJoinRoomTab(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF090E17),
        border: Border(bottom: BorderSide(color: Color(0xFF1F293D), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CachoColors.gold, size: 20),
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.groups, color: CachoColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'JUGAR CON AMIGOS',
                style: TextStyle(
                  fontFamily: CachoFonts.display,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CachoColors.gold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          // Billetera del usuario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF121B2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CachoColors.gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: CachoColors.gold, size: 14),
                const SizedBox(width: 4),
                Text(
                  coinsText(Wallet.instance.balance),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: CachoColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F293D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? CachoColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: _activeTab == 0 ? Colors.black : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CREAR SALA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _activeTab == 0 ? Colors.black : Colors.white70,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? CachoColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        size: 16,
                        color: _activeTab == 1 ? Colors.black : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'UNIRSE A SALA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _activeTab == 1 ? Colors.black : Colors.white70,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: CREAR SALA
  // --------------------------------------------------------------------------
  Widget _buildCreateRoomTab() {
    final balance = Wallet.instance.balance;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SELECCIONA LA MESA Y APUESTA',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: CachoColors.gold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Carrusel de las 5 mesas fotorrealistas 2D
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final isSelected = _selectedStake == room.entryFee;
                final canAfford = balance >= room.entryFee;

                return GestureDetector(
                  onTap: canAfford ? () => setState(() => _selectedStake = room.entryFee) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 154,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A2338) : const Color(0xFF0F1524),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? CachoColors.gold : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: CachoColors.gold.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Imagen de la mesa 2D
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                room.tableAssetPath,
                                height: 50,
                                width: 138,
                                fit: BoxFit.cover,
                              ),
                              if (!canAfford)
                                Container(
                                  height: 50,
                                  width: 138,
                                  color: Colors.black.withValues(alpha: 0.65),
                                  child: const Center(
                                    child: Icon(Icons.lock, color: Colors.white70, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Nombre y Apuesta
                        Column(
                          children: [
                            Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? CachoColors.gold : Colors.white,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.monetization_on, color: CachoColors.gold, size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  coinsText(room.entryFee),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Fila: Modo de Juego + Funciones Sociales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modo de juego
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101726),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1F293D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MODO DE JUEGO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: CachoColors.gold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildModeChip('Cacho Completo', 'completo'),
                          const SizedBox(width: 6),
                          _buildModeChip('Clásico', 'clasico'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Funciones Sociales (Micrófono & Rockola)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101726),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1F293D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FUNCIONES DE SALA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: CachoColors.gold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildFeatureChip(
                            icon: _voiceChatActive ? Icons.mic : Icons.mic_off,
                            label: 'Voz P2P',
                            active: _voiceChatActive,
                            onTap: () => setState(() => _voiceChatActive = !_voiceChatActive),
                          ),
                          const SizedBox(width: 6),
                          _buildFeatureChip(
                            icon: Icons.music_note,
                            label: 'Rockola DJ',
                            active: _musicSocialActive,
                            onTap: () => setState(() => _musicSocialActive = !_musicSocialActive),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Resumen del pozo y botón CREAR SALA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1322),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CachoColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POZO ESTIMADO: ${coinsText(_selectedStake * 6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: CachoColors.gold,
                      ),
                    ),
                    const Text(
                      'La sala se puede rellenar con bots si faltan amigos.',
                      style: TextStyle(fontSize: 10, color: Colors.white60),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CachoColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.rocket_launch, size: 16),
                    label: const Text(
                      'CREAR SALA',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                    onPressed: widget.onlineOk == true
                        ? () {
                            Navigator.of(context).pop();
                            widget.onCreate(
                              stake: _selectedStake,
                              tableTheme: defaultTableTheme,
                              preset: _preset,
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String value) {
    final isSelected = _preset == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _preset = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? CachoColors.gold.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? CachoColors.gold : Colors.white24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? CachoColors.gold : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1E3A2F) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? const Color(0xFF4CAF50) : Colors.white24,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? const Color(0xFF4CAF50) : Colors.white54),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: UNIRSE A SALA
  // --------------------------------------------------------------------------
  Widget _buildJoinRoomTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF101726),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CachoColors.gold.withValues(alpha: 0.4)),
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
              const Icon(Icons.vpn_key_rounded, color: CachoColors.gold, size: 36),
              const SizedBox(height: 8),
              const Text(
                'CÓDIGO DE INVITACIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: CachoFonts.display,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CachoColors.gold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ingresa el código de 4 a 6 caracteres que te compartió tu amigo:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 14),

              // Campo de entrada de código con botón Pegar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.joinCode,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        fontFamily: CachoFonts.display,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CachoColors.gold,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF090E17),
                        hintText: 'EJ: K7QF',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          letterSpacing: 2,
                          color: Colors.white24,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1F293D)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: CachoColors.gold, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1A263D),
                      foregroundColor: CachoColors.gold,
                    ),
                    icon: const Icon(Icons.content_paste, size: 20),
                    tooltip: 'Pegar código',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        setState(() {
                          widget.joinCode.text = data!.text!.trim().toUpperCase();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón Unirse
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CachoColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text(
                    'ENTRAR A LA SALA',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  onPressed: widget.onlineOk == true
                      ? () {
                          final code = widget.joinCode.text.trim().toUpperCase();
                          if (code.length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('El código debe tener al menos 4 caracteres (ej: K7QF)'),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          widget.onJoin(code);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1218),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Sin conexión con el servidor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Revisa tu conexión a internet para jugar con amigos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRetryProbe();
              },
            ),
          ],
        ),
      ),
    );
  }
}
