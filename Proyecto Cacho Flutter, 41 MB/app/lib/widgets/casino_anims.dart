import 'dart:math';

import 'package:flutter/material.dart';

import '../state/settings.dart';
import '../state/wallet.dart';
import '../theme.dart';
import 'coin_widgets.dart';
import 'dice_and_cup.dart';

/// Animaciones de casino (sentencia animaciones 25-oct: AN1–AN18, sin
/// AN15 rechazada). Todo es visual, del lado de la app, sin servidor.
/// Si el interruptor AN17 está apagado, cada widget dibuja su estado
/// final estático: nunca se quita funcionalidad, solo movimiento.
class CasinoAnims {
  static bool get enabled => Settings.instance.animationsEnabled;

  /// Apagado con el interruptor AN17 O con "reducir movimiento" del
  /// sistema (F8): ningún widget nuevo usa solo `enabled`.
  static bool enabledIn(BuildContext context) =>
      enabled && !MediaQuery.disableAnimationsOf(context);

  /// Duración efectiva: cero cuando las animaciones están apagadas.
  static Duration dur(Duration d) => enabled ? d : Duration.zero;
}

/// Dígito que muestra el rodillo AN11 en un instante `progress` (0..1)
/// para un dígito objetivo `target`: rueda 0–9 `spins` vueltas y aterriza
/// exactamente en `target` (determinista, sin azar).
int rollerDigit(double progress, int target, {int spins = 2}) {
  if (progress >= 1) return target;
  final total = spins * 10 + target;
  return ((progress * total).floor()) % 10;
}

/// Telón dorado mate (AN1 apertura, AN6 transición). `opening: true`
/// parte cerrado y se abre; `opening: false` parte abierto y se cierra.
/// Un toque salta al instante. Al terminar llama a `onDone`.
class EntryCurtain extends StatefulWidget {
  final bool opening;
  final bool showLogo;
  final VoidCallback onDone;
  const EntryCurtain({
    super.key,
    required this.opening,
    required this.onDone,
    this.showLogo = false,
  });

  @override
  State<EntryCurtain> createState() => _EntryCurtainState();
}

class _EntryCurtainState extends State<EntryCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  bool _doneFired = false;

  @override
  void initState() {
    super.initState();
    if (widget.opening) {
      _c.forward().then((_) => widget.onDone());
    } else {
      _c.value = 1;
      _c.reverse().then((_) => widget.onDone());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    if (widget.opening) {
      _c.value = 1;
    } else {
      _c.value = 0;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    // Reducir-movimiento del sistema: sin telón, termina al instante.
    // (El gate vive aquí, no en initState: MediaQuery.dependOn no
    // está permitido antes de completar initState.)
    if (!CasinoAnims.enabledIn(context)) {
      if (!_doneFired) {
        _doneFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      }
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: _skip,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // 0 = cerrado, 1 = abierto.
          final open = widget.opening ? _c.value : 1 - _c.value;
          if (open >= 1) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              return Stack(
                children: [
                  // Sin-café menú: cortinas casino oscuro, no
                  // madera (antes CachoColors.wood 0xFF2B1810).
                  // Solo cambia el color; geometría, duración,
                  // toque-para-saltar y gating enabledIn intactos.
                  Positioned(
                    left: -w / 2 * open,
                    width: w / 2,
                    top: 0,
                    bottom: 0,
                    child: Container(color: CachoColors.menuTop),
                  ),
                  Positioned(
                    right: -w / 2 * open,
                    width: w / 2,
                    top: 0,
                    bottom: 0,
                    child: Container(color: CachoColors.menuTop),
                  ),
                  if (widget.showLogo && open < 0.5)
                    Center(
                      child: Opacity(
                        opacity: (1 - open * 2).clamp(0, 1),
                        child: const DudoLogo(fontSize: 44),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Motas doradas mates flotando lento (AN2, solo home). 24 sprites por
/// transform, nunca CustomPainter a pantalla completa; al salir del home
/// el widget se destruye (pausa por construcción).
class GoldParticles extends StatefulWidget {
  const GoldParticles({super.key});

  @override
  State<GoldParticles> createState() => _GoldParticlesState();
}

class _GoldParticlesState extends State<GoldParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  late final List<(double, double, double, double, double)> _motes = (() {
    final r = Random(20251025);
    return [
      for (var i = 0; i < 24; i++)
        (
          r.nextDouble(), // x 0..1
          r.nextDouble(), // y inicial 0..1
          2 + r.nextDouble() * 3, // tamaño 2..5
          0.08 + r.nextDouble() * 0.14, // opacidad
          0.02 + r.nextDouble() * 0.05, // velocidad
        ),
    ];
  })();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return const SizedBox.shrink();
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, box) {
                return Stack(
                  children: [
                    for (final m in _motes)
                      Positioned(
                        left: m.$1 * box.maxWidth,
                        top: ((m.$2 - _c.value * m.$5 * 16) % 1.0) *
                            box.maxHeight,
                        child: Container(
                          width: m.$3,
                          height: m.$3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CachoColors.gold.withValues(alpha: m.$4),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Barrido de luz mate sobre un hijo (AN3 logo, AN4 botones). El brillo
/// viaja por DETRÁS del contenido: el texto nunca pierde contraste.
class SweepGlow extends StatefulWidget {
  final Widget child;
  final Duration cycle;
  final double peakOpacity;
  const SweepGlow({
    super.key,
    required this.child,
    this.cycle = const Duration(seconds: 8),
    this.peakOpacity = 0.15,
  });

  @override
  State<SweepGlow> createState() => _SweepGlowState();
}

class _SweepGlowState extends State<SweepGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.cycle,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 300.0;
          return ClipRect(
            child: Stack(
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) {
                        final bandW = w * 0.4;
                        final left = -bandW + _c.value * (w + bandW);
                        return Stack(
                          children: [
                            Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: bandW,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      CachoColors.gold.withValues(alpha: 0),
                                      CachoColors.gold.withValues(
                                          alpha: widget.peakOpacity),
                                      CachoColors.gold.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pilas de fichas que se barajan (AN7, creación de sala). 0,8 s; un
/// toque salta al instante.
class ShuffleChips extends StatefulWidget {
  final VoidCallback onDone;
  const ShuffleChips({super.key, required this.onDone});

  @override
  State<ShuffleChips> createState() => _ShuffleChipsState();
}

class _ShuffleChipsState extends State<ShuffleChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  bool _doneFired = false;

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    _c.value = 1;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    // Sin animación (AN17 apagado o reduce-motion): estado final
    // estático (pilas apiladas al centro) y onDone al instante, para
    // que el lobby revele el código en vez de quedarse esperando.
    // Antes este widget no consultaba ningún gate: barajaba siempre.
    if (!CasinoAnims.enabledIn(context)) {
      if (!_doneFired) {
        _doneFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      }
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoinIcon(size: 30),
          CoinIcon(size: 30),
          CoinIcon(size: 30),
        ],
      );
    }
    return GestureDetector(
      onTap: _skip,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          // Tres pilas que se cruzan y terminan apiladas al centro.
          final spread = (1 - t) * 46;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                  offset: Offset(-spread, 0),
                  child: const CoinIcon(size: 30)),
              Transform.translate(
                  offset: Offset(0, -8 * (1 - t)),
                  child: const CoinIcon(size: 30)),
              Transform.translate(
                  offset: Offset(spread, 0),
                  child: const CoinIcon(size: 30)),
            ],
          );
        },
      ),
    );
  }
}

/// Dado marfil girando en 2D (AN8, espera de conexión). Giro del sprite
/// existente, sin tumbo 3D; el padre lo retira al conectar o al error.
class DiceSpinner extends StatefulWidget {
  final double size;
  const DiceSpinner({super.key, this.size = 40});

  @override
  State<DiceSpinner> createState() => _DiceSpinnerState();
}

class _DiceSpinnerState extends State<DiceSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) {
      return DiceFace(value: 6, size: widget.size);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.rotate(
        angle: _c.value * 2 * pi,
        child: DiceFace(
          value: (_c.value * 6).floor() + 1,
          size: widget.size,
        ),
      ),
    );
  }
}

/// Entrada con pop (AN9, filas del lobby). Escala por transform (sin
/// mover el layout) + fundido, 0,3 s, solo al montarse.
class PopIn extends StatelessWidget {
  final Widget child;
  const PopIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.8 + 0.2 * t,
          child: Container(
            // Destello dorado que se apaga al completar el pop.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CachoColors.gold.withValues(alpha: 0.5 * (1 - t)),
                  blurRadius: 18,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Borde con pulso dorado mate (AN10, banner SALA ACTIVA). Solo pulsa el
/// borde: el fondo del texto y el botón quedan intactos.
class PulseBorder extends StatefulWidget {
  final Widget child;
  final double radius;
  const PulseBorder({super.key, required this.child, this.radius = 14});

  @override
  State<PulseBorder> createState() => _PulseBorderState();
}

class _PulseBorderState extends State<PulseBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(
                    color: CachoColors.gold
                        .withValues(alpha: 0.45 + 0.55 * _c.value),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

/// Rodillo de dígitos (AN11, pozo). Determinista: siempre aterriza en el
/// pozo real, ≤1,5 s, rodada única por vista. Sin azar ni copy de premio.
class DigitRoller extends StatefulWidget {
  final int target;
  final TextStyle? style;
  final String prefix;
  const DigitRoller({
    super.key,
    required this.target,
    this.style,
    this.prefix = '',
  });

  @override
  State<DigitRoller> createState() => _DigitRollerState();
}

class _DigitRollerState extends State<DigitRoller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (CasinoAnims.enabled) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce-motion también detiene el rodillo: sin este gate, el
    // initState (que no puede usar enabledIn: MediaQuery.dependOn no
    // está permitido en initState) lo habría puesto en marcha aunque
    // el sistema pidiera no animar. Estado final = cifra real.
    if (!CasinoAnims.enabledIn(context)) {
      return Text('${widget.prefix}${coinsText(widget.target)}',
          style: widget.style);
    }
    if (_c.value >= 1) {
      return Text('${widget.prefix}${coinsText(widget.target)}',
          style: widget.style);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        if (_c.value >= 1) {
          return Text('${widget.prefix}${coinsText(widget.target)}',
              style: widget.style);
        }
        final digits = widget.target.toString().split('');
        final shown = digits
            .map((d) => rollerDigit(_c.value, int.parse(d)).toString())
            .join();
        return Text('${widget.prefix}$shown', style: widget.style);
      },
    );
  }
}

/// Confeti dorado mate (AN12, solo pantalla de victoria). Máx. 40 piezas
/// por transform, dentro del overlay, sin alargar su cierre.
class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key});

  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..forward();

  late final List<(double, double, double, double, double)> _pieces = (() {
    final r = Random(20251025);
    return [
      for (var i = 0; i < 40; i++)
        (
          r.nextDouble(), // x
          r.nextDouble() * 0.4, // retraso
          5 + r.nextDouble() * 6, // tamaño
          (r.nextDouble() - 0.5) * 60, // deriva
          r.nextBool() ? 0.9 : 0.5, // opacidad (mate)
        ),
    ];
  })();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return LayoutBuilder(
            builder: (context, box) {
              return Stack(
                children: [
                  for (final p in _pieces)
                    if (t > p.$2)
                      Positioned(
                        left: p.$1 * box.maxWidth +
                            p.$4 * ((t - p.$2) / (1 - p.$2)),
                        top: -20 +
                            ((t - p.$2) / (1 - p.$2)) * (box.maxHeight + 40),
                        child: Opacity(
                          opacity: p.$5 *
                              (t > 0.9 ? (1 - (t - 0.9) / 0.1) : 1.0),
                          child: Container(
                            width: p.$3,
                            height: p.$3 * 0.6,
                            color: CachoColors.gold,
                          ),
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Moneda que cae y se funde (AN13, rescate). Cae 0,7 s junto al chip de
/// saldo y se funde: nunca tapa la cifra final.
class FallingCoin extends StatefulWidget {
  final VoidCallback onDone;
  const FallingCoin({super.key, required this.onDone});

  @override
  State<FallingCoin> createState() => _FallingCoinState();
}

class _FallingCoinState extends State<FallingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _doneFired = false;

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sin animación (AN17 apagado o reduce-motion): estado final
    // estático (al final la moneda se funde a opacidad 0, o sea,
    // invisible) y onDone al instante, para que el home no deje la
    // moneda colgada. Antes este widget no consultaba ningún gate.
    if (!CasinoAnims.enabledIn(context)) {
      if (!_doneFired) {
        _doneFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      }
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final fall = Curves.easeOut.transform((t / 0.65).clamp(0, 1));
        final fade = t > 0.65 ? (1 - (t - 0.65) / 0.35) : 1.0;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, -34 * (1 - fall)),
            child: const CoinIcon(size: 22),
          ),
        );
      },
    );
  }
}

/// Ecualizador de barras (AN14, MusicBar). Solo se mueve con DJ en
/// reproducción real; en pausa queda plano. Nunca mide audio ni mic.
class EqualizerBars extends StatefulWidget {
  final bool playing;
  const EqualizerBars({super.key, required this.playing});

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context) || !widget.playing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 3,
              height: 5,
              margin: const EdgeInsets.only(right: 2),
              color: CachoColors.gold,
            ),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 3,
                height: 4 +
                    9 *
                        (0.5 +
                            0.5 *
                                sin(_c.value * 2 * pi + i * 1.4)),
                margin: const EdgeInsets.only(right: 2),
                color: CachoColors.gold,
              ),
          ],
        );
      },
    );
  }
}

/// Fichas que se retiran (AN18, solo overlay de fin). Deslizan a un lado
/// y se funden en 0,6 s, sin mover el layout ni tapar botones.
class WithdrawingChips extends StatefulWidget {
  const WithdrawingChips({super.key});

  @override
  State<WithdrawingChips> createState() => _WithdrawingChipsState();
}

class _WithdrawingChipsState extends State<WithdrawingChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeOut.transform(_c.value);
          return Opacity(
            opacity: 1 - t,
            child: Transform.translate(
              offset: Offset(60 * t, 0),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoinIcon(size: 20),
                  SizedBox(width: 4),
                  CoinIcon(size: 20),
                  SizedBox(width: 4),
                  CoinIcon(size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pulso de opacidad (F8: código de sala del lobby). Solo opacidad,
/// nunca tamaño ni posición: no desplaza nada ni tapa controles.
class PulseOpacity extends StatefulWidget {
  final Widget child;
  const PulseOpacity({super.key, required this.child});

  @override
  State<PulseOpacity> createState() => _PulseOpacityState();
}

class _PulseOpacityState extends State<PulseOpacity>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: 0.6 + 0.4 * _c.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Sacudida corta, una vez, al aparecer (F8: aviso de saldo
/// insuficiente en el lobby). Solo desplazamiento X, nunca tamaño.
class Shake extends StatefulWidget {
  final Widget child;
  const Shake({super.key, required this.child});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    if (CasinoAnims.enabled) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final dx = sin(t * pi * 4) * 6 * (1 - t);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Aparición escalonada (F9: tarjetas Home y filas lobby, 60 ms por
/// índice). Solo Opacity + deslizamiento leve, nunca bloquea toques;
/// corre una vez al montar (claves estables en el llamador).
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    if (CasinoAnims.enabled) {
      Future.delayed(Duration(milliseconds: widget.index * 60), () {
        if (mounted) _c.forward();
      });
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: _c.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _c.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Luz cálida de lámpara (F9: Home/lobby, NUNCA mesa). Resplandor
/// radial ámbar con parpadeo muy lento y baja amplitud.
class LampGlow extends StatefulWidget {
  final double height;
  const LampGlow({super.key, this.height = 180});

  @override
  State<LampGlow> createState() => _LampGlowState();
}

class _LampGlowState extends State<LampGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final glow = 0.10 + 0.03 * sin(_c.value * 2 * pi);
        return IgnorePointer(
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: 1.0,
                colors: [
                  const Color(0xFFFFC978).withValues(alpha: glow),
                  const Color(0xFFFFC978).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Transición entre pantallas (F9: fundido + leve deslizamiento,
/// 250 ms) para el flujo principal home→setup→lobby→mesa. Misma API
/// que MaterialPageRoute; sin animación si están apagadas.
class CachoPageRoute<T> extends PageRouteBuilder<T> {
  CachoPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            if (!CasinoAnims.enabledIn(context)) return child;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        );
}
