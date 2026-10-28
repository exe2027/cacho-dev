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

/// R9/R15/R17: hoja CON AMIGOS como pantalla propia. Mismo
/// contenido y orden que la hoja anterior (crear, luego unirse),
/// con la placa fija sobre CREAR y la sección de unirse también
/// fija debajo (nada queda tapado ni fuera de alcance). Código de
/// unirse en Cinzel 24 con tracking (R15, aplicado al campo donde
/// el código existe antes de crear); la invitación por WhatsApp
/// vive en el lobby y se anuncia allí (R15/R20).
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

class _FriendsSetupScreenState extends State<FriendsSetupScreen> {
  var _stake = 500;
  // Rediseño CON AMIGOS (2026-10-28, por orden del usuario): ya no
  // hay selector de mesa en esta página (ni El Pub, ni Casino, ni
  // Neón). La sala creada usa siempre el tema por defecto Dorado
  // (defaultTableTheme, lib/table_themes.dart) y el usuario no
  // tiene que elegirlo ni entenderlo. El selector sigue intacto
  // en CONTRA LA MÁQUINA (LocalSetupScreen), que no se tocó.
  late var _preset = widget.initialPreset;

  @override
  void initState() {
    super.initState();
    if (_stake > Wallet.instance.balance) {
      _stake = Wallet.stakes.lastWhere((x) => x <= Wallet.instance.balance,
          orElse: () => Wallet.stakes.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineOk = widget.onlineOk;
    return Scaffold(
      body: DecoratedBox(
        decoration: menuDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaggerIn(
                index: 0,
                child: const SheetStrip(
                  title: 'CON AMIGOS',
                  // R17: modalidad en línea, sin cifra local mezclada.
                  right: Text('EN LÍNEA',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CachoColors.gold)),
                ),
              ),
              // Rediseño CON AMIGOS (2026-10-28): una sola columna
              // vertical, centrada y con scroll vertical — nunca
              // scroll horizontal ni dos columnas de 320 px que
              // dejaban la columna derecha fuera de pantalla y el
              // texto de arriba recortado ("bots.") en la captura
              // en vivo. Orden fijo, acorde al menú (fondo casino
              // oscuro de menuDecoration + dorado mate, sin cian
              // ni neón en ninguna parte): intro completa, reglas,
              // apuesta por tiers, billetera en línea con su placa
              // de pozo. El pie (CREAR + código + UNIRSE) sigue
              // fijo debajo, fuera del scroll, como antes.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StaggerIn(
                            index: 0,
                            child: const Text(
                              'Crea una sala y comparte el código, o únete '
                              'con el código de un amigo. La sala puede '
                              'rellenarse con bots.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 20),
                          StaggerIn(
                            index: 1,
                            child: const Text('Reglas',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CachoColors.gold)),
                          ),
                          const SizedBox(height: 6),
                          StaggerIn(
                            index: 1,
                            child: PresetRow(
                              preset: _preset,
                              onChanged: (v) =>
                                  setState(() => _preset = v),
                            ),
                          ),
                          const SizedBox(height: 20),
                          StaggerIn(
                            index: 2,
                            child: StakePicker(
                              value: _stake,
                              balance: Wallet.instance.balance,
                              onChanged: (v) =>
                                  setState(() => _stake = v),
                            ),
                          ),
                          const SizedBox(height: 20),
                          StaggerIn(
                            index: 3,
                            // R17: línea a 14 px sobre la placa, sin
                            // cifra local mezclada.
                            child: const Text('Billetera en línea',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CachoColors.gold)),
                          ),
                          const SizedBox(height: 6),
                          StaggerIn(
                            index: 3,
                            child: PotPlaque(
                              formula:
                                  'POZO = ${coinsText(_stake)} × jugadores al partir',
                              saldoLine:
                                  'La apuesta se cobra al partir la partida; el ganador se lleva el pozo completo.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // TODO HORIZONTAL: pie en una fila (CREAR + campo
              // código + UNIRSE) cuando hay ancho; apilado cuando
              // no. La rama sin conexión se mantiene apilada por
              // legibilidad. AN4: shimmer mate intacto.
              StaggerIn(
                index: 5,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final createButton = SweepGlow(
                      cycle: const Duration(seconds: 3),
                      peakOpacity: 0.12,
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: BronzeButton(
                          label:
                              onlineOk == null ? 'COMPROBANDO…' : 'CREAR SALA',
                          icon: Icons.groups,
                          fontSize: 18,
                          fontFamily: CachoFonts.display,
                          onPressed: onlineOk == true
                              ? () {
                                  Navigator.of(context).pop();
                                  widget.onCreate(
                                    stake: _stake,
                                    // Sin selector en CON AMIGOS:
                                    // tema por defecto Dorado.
                                    tableTheme: defaultTableTheme,
                                    preset: _preset,
                                  );
                                }
                              : null,
                        ),
                      ),
                    );
                    final joinField = TextField(
                      controller: widget.joinCode,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      // R15: código en Cinzel 24 con tracking,
                      // sobre casino oscuro.
                      style: const TextStyle(
                          fontFamily: CachoFonts.display,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3),
                      decoration: const InputDecoration(
                        labelText: 'Código de sala',
                        hintText: 'Ej: K7QF',
                      ),
                    );
                    final joinButton = BronzeButton(
                      label: 'UNIRSE',
                      onPressed: onlineOk == true
                          ? () {
                              final code =
                                  widget.joinCode.text.trim().toUpperCase();
                              // Sin pop si el código es corto: el
                              // aviso sale aquí y el código no se
                              // pierde.
                              if (code.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Escribe el código de la sala (ej: K7QF)')),
                                );
                                return;
                              }
                              Navigator.of(context).pop();
                              widget.onJoin(code);
                            }
                          : null,
                    );
                    if (onlineOk == false) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CachoColors.casinoRed
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: CachoColors.casinoRed
                                        .withValues(alpha: 0.6)),
                              ),
                              child: const Text(
                                'Sin conexión con el servidor de salas. '
                                'Revisa tu internet y vuelve a intentarlo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: BronzeButton(
                                label: 'REINTENTAR CONEXIÓN',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onRetryProbe();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (box.maxWidth >= 700) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 1120),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(width: 210, child: createButton),
                                const SizedBox(width: 12),
                                Expanded(child: joinField),
                                const SizedBox(width: 10),
                                joinButton,
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          createButton,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: joinField),
                              const SizedBox(width: 10),
                              joinButton,
                            ],
                          ),
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
