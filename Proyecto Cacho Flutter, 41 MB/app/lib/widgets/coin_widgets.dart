import 'dart:math';

import 'package:flutter/material.dart';

import '../state/settings.dart';
import '../state/wallet.dart';
import '../table_themes.dart';
import '../theme.dart';

/// Paleta casino de MENU (sin cafe, 25-oct): fondos oscuros de la
/// familia del buscar_bg (azul noche -> casi negro -> purpura
/// profundo) con dorado mate #C9A24B (CachoColors.gold) como acento.
/// Constantes LOCALES de este archivo: theme.dart la redefine otro
/// agente y no se toca ni se redefine aqui.
const _menuCasino = Color(0xFF16203A);

/// La moneda de oro (frames renderizados en Blender: giro completo).
String coinFrame(int i) =>
    'assets/images/coins/coin_${(i % 12).toString().padLeft(2, '0')}.png';

/// Moneda estática con respaldo dorado si falta el asset.
class CoinIcon extends StatelessWidget {
  final double size;
  final int frame;
  const CoinIcon({super.key, this.size = 20, this.frame = 0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      coinFrame(frame),
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFFE9A8), Color(0xFFD9A441), Color(0xFF9A6B1F)],
            center: Alignment(-0.3, -0.3),
          ),
        ),
        child: Icon(Icons.star,
            size: size * 0.55, color: const Color(0xFF7A5410)),
      ),
    );
  }
}

/// Moneda girando sin parar (saldo y celebración).
class SpinningCoin extends StatefulWidget {
  final double size;
  const SpinningCoin({super.key, this.size = 22});

  @override
  State<SpinningCoin> createState() => _SpinningCoinState();
}

class _SpinningCoinState extends State<SpinningCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gate completo (interruptor + reduce-motion): sin animación,
    // moneda estática (mismo frame que usa BalanceChip con
    // spinning: false). La cifra del saldo nunca se toca.
    if (!Settings.instance.animationsEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return CoinIcon(size: widget.size, frame: 0);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) =>
          CoinIcon(size: widget.size, frame: (_c.value * 12).floor()),
    );
  }
}

/// Pastilla de saldo: moneda girando + monto. La cifra es siempre
/// real ([balance]); cuando cambia, rueda hasta el valor nuevo en
/// 600 ms con [_RollingBalanceText] (misma idea que el DigitRoller
/// del pozo del lobby, implementada aquí y no importada de
/// casino_anims.dart para no crear un ciclo de imports:
/// casino_anims.dart ya importa este archivo). Con animaciones
/// apagadas o reduce-motion, la cifra se muestra estática al
/// instante. La rodada es única por cambio, nunca en bucle, y no
/// cambia tamaños ni layout: rueda dígito a dígito sobre el texto
/// ya formateado (los separadores '.' pasan intactos, así el ancho
/// no salta al aterrizar).
class BalanceChip extends StatefulWidget {
  final int balance;
  final bool spinning;
  const BalanceChip({super.key, required this.balance, this.spinning = true});

  @override
  State<BalanceChip> createState() => _BalanceChipState();
}

class _BalanceChipState extends State<BalanceChip> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: CachoColors.gold.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.spinning
              ? const SpinningCoin(size: 19)
              : const CoinIcon(size: 19),
          const SizedBox(width: 6),
          _RollingBalanceText(balance: widget.balance),
        ],
      ),
    );
  }
}

/// Cifra de saldo que rueda al cambiar (o al montarse, como el
/// DigitRoller del pozo). Determinista: rueda 2 vueltas 0–9 por
/// dígito y aterriza exactamente en [balance]; nunca inventa una
/// cifra. Solo intercambio de texto, sin animar tamaños.
class _RollingBalanceText extends StatefulWidget {
  final int balance;
  const _RollingBalanceText({required this.balance});

  @override
  State<_RollingBalanceText> createState() => _RollingBalanceTextState();
}

class _RollingBalanceTextState extends State<_RollingBalanceText>
    with SingleTickerProviderStateMixin {
  static const _style = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFFFFE9A8),
  );

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (Settings.instance.animationsEnabled) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(_RollingBalanceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      if (Settings.instance.animationsEnabled) {
        _c.forward(from: 0);
      } else {
        _c.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Dígito del rodillo en `progress` para el dígito objetivo
  /// `target`: misma fórmula determinista del DigitRoller (2 vueltas).
  int _rollerDigit(double progress, int target) {
    if (progress >= 1) return target;
    final total = 2 * 10 + target;
    return ((progress * total).floor()) % 10;
  }

  String _shown(double progress) {
    final formatted = coinsText(widget.balance);
    if (progress >= 1) return formatted;
    final buf = StringBuffer();
    for (var i = 0; i < formatted.length; i++) {
      final ch = formatted[i];
      final d = int.tryParse(ch);
      buf.write(d == null ? ch : _rollerDigit(progress, d).toString());
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Gate completo (interruptor + reduce-motion del sistema):
    // sin animación, cifra final estática al instante.
    if (!Settings.instance.animationsEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return Text(coinsText(widget.balance), style: _style);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Text(_shown(_c.value), style: _style),
    );
  }
}

/// Ficha que cae (AN5, selección de sala/tier). Cae 0,4 s en la zona
/// libre superior derecha, sin mover el layout ni tapar nombre/monto.
class _ChipDrop extends StatefulWidget {
  final VoidCallback onDone;
  const _ChipDrop({required this.onDone});

  @override
  State<_ChipDrop> createState() => _ChipDropState();
}

class _ChipDropState extends State<_ChipDrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

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
    // Gate completo (fase 2, frente A; hallazgo del frente C):
    // antes solo se consultaba Settings.animationsEnabled en el
    // llamador, así que reduce-motion de iOS no detenía la ficha.
    // Sin animación, invisible desde el primer fotograma; el
    // onDone del controlador (initState) sigue limpiando
    // _showDrop en el padre, así que no queda estado colgado.
    // No se importa casino_anims.dart (ciclo de imports): el
    // gate se replica con el patrón ya usado en CoinRain y
    // SpinningCoin de este mismo archivo.
    if (!Settings.instance.animationsEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -18 * (1 - t)),
            child: const CoinIcon(size: 22),
          ),
        );
      },
    );
  }
}

/// Respuesta animada al toque (fase 2, frente A): escala 0,97
/// solo mientras el puntero está abajo, 150 ms, sin bucle y sin
/// mover el layout (Transform). Con animaciones apagadas o
/// reduce-motion devuelve el hijo tal cual. Este archivo no
/// importa casino_anims.dart (evita el ciclo de imports), así
/// que el gate se replica con el patrón ya usado aquí en
/// CoinRain/SpinningCoin. Usa Listener (no GestureDetector)
/// para no competir con el onTap del InkWell hijo.
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
    if (!Settings.instance.animationsEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
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

/// Selector de apuesta: los montos oficiales; los que superan el
/// saldo quedan deshabilitados.
class StakePicker extends StatefulWidget {
  final int value;
  final int balance;
  final ValueChanged<int> onChanged;
  const StakePicker({
    super.key,
    required this.value,
    required this.balance,
    required this.onChanged,
  });

  @override
  State<StakePicker> createState() => _StakePickerState();
}

class _StakePickerState extends State<StakePicker> {
  bool _showDrop = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final balance = widget.balance;
    // Gate para la duración de la transición del seleccionado:
    // con animaciones apagadas o reduce-motion, 0 ms.
    final animOn = Settings.instance.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    // R10 (rediseño completo): rejilla 3+2 sin scroll (nunca "High R"
    // cortado): nombre + apuesta exacta en cada tarjeta, ≥44 px de
    // alto, texto ≥14 px. Seleccionada: fondo dorado mate + texto
    // oscuro + borde dorado 2 px (R34); resto casino oscuro + borde dorado
    // 1 px. Si el ancho no da para 3 columnas sin truncar, cae a 2
    // columnas antes de cortar un nombre. Deshabilitada por saldo:
    // borde dorado 30 % + texto 50 %, sin desaparecer (R34).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Apuesta por jugador',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (_, box) {
                final cols = box.maxWidth >= 330 ? 3 : 2;
                final stakes = Wallet.stakes;
                final rows = <List<int>>[];
                for (var i = 0; i < stakes.length; i += cols) {
                  rows.add(stakes.sublist(
                      i,
                      (i + cols) > stakes.length
                          ? stakes.length
                          : (i + cols)));
                }
                return Column(
                  children: [
                    for (var r = 0; r < rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var ti = 0;
                              ti < rows[r].length;
                              ti++) ...[
                            if (ti > 0) const SizedBox(width: 8),
                            Expanded(
                                child: _tierTile(
                                    rows[r][ti], value, balance, animOn)),
                          ],
                          for (var k = rows[r].length; k < cols; k++) ...[
                            const SizedBox(width: 8),
                            const Expanded(child: SizedBox()),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        if (_showDrop)
          Positioned(
            right: 4,
            top: 0,
            child: _ChipDrop(onDone: () {
              if (mounted) setState(() => _showDrop = false);
            }),
          ),
      ],
    );
  }

  Widget _tierTile(int s, int value, int balance, bool animOn) {
    final selected = value == s;
    final enabled = s <= balance;
    final dark = const Color(0xFF2B1810);
    // Respuesta al toque: _PressScale (0,97, 150 ms).
    // Transición del seleccionado: AnimatedContainer 300 ms
    // (color de fondo + borde); el Material queda transparente
    // para no tapar el ripple del InkWell. La ficha AN5
    // preexistente (_ChipDrop) no se toca.
    return _PressScale(
      child: AnimatedContainer(
        duration: animOn
            ? const Duration(milliseconds: 300)
            : Duration.zero,
        decoration: BoxDecoration(
          color: selected
              ? CachoColors.gold
              : _menuCasino.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? CachoColors.gold
                : CachoColors.gold.withValues(
                    alpha: enabled ? 0.55 : 0.30),
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled
                ? () {
                    widget.onChanged(s);
                    // AN5: la selección es efectiva al toque; la ficha
                    // solo adorna, sin retrasarla. Gate completo:
                    // tampoco se monta con reduce-motion de iOS
                    // (antes solo se miraba el interruptor).
                    if (Settings.instance.animationsEnabled &&
                        !MediaQuery.disableAnimationsOf(context) &&
                        s != value) {
                      setState(() => _showDrop = true);
                    }
                  }
                : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            // Pila vertical centrada: con el icono al lado, el
            // nombre solo tenía ~72 px y "El Club VIP" truncaba
            // ("El Club…", captura 2026-10-25, R10; antes
            // "High Roller", renombrado en docs/19 C7). A ancho
            // completo caben los 11 caracteres.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: const CoinIcon(size: 18),
                ),
                const SizedBox(height: 4),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        stakeTierName(s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? dark
                              : (enabled
                                  ? CachoColors.ivory
                                  : Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                      Text(
                        coinsText(s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? dark
                              : (enabled
                                  ? CachoColors.gold
                                  : Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
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

class _FallingCoin {
  final double x; // 0..1
  final double delay; // 0..0.45
  final double size;
  final double spin; // vueltas durante la caída
  final double drift;
  const _FallingCoin(this.x, this.delay, this.size, this.spin, this.drift);
}

/// Lluvia de monedas de la celebración del pozo: monedas de Blender
/// cayendo con giros distintos sobre toda la pantalla.
class CoinRain extends StatefulWidget {
  final int count;
  const CoinRain({super.key, this.count = 22});

  @override
  State<CoinRain> createState() => _CoinRainState();
}

class _CoinRainState extends State<CoinRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..forward();
  late final List<_FallingCoin> _coins = _make();

  List<_FallingCoin> _make() {
    final r = Random(20261022);
    return [
      for (var i = 0; i < widget.count; i++)
        _FallingCoin(
          r.nextDouble(),
          r.nextDouble() * 0.45,
          22 + r.nextDouble() * 20,
          1.5 + r.nextDouble() * 2.5,
          (r.nextDouble() - 0.5) * 30,
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gate completo (interruptor + reduce-motion): sin animación,
    // sin lluvia (mismo patrón que ConfettiLayer).
    if (!Settings.instance.animationsEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return LayoutBuilder(
            builder: (context, box) {
              return Stack(
                children: [
                  for (final coin in _coins)
                    if (t > coin.delay)
                      Positioned(
                        left: coin.x * box.maxWidth +
                            coin.drift * ((t - coin.delay) / (1 - coin.delay)),
                        top: -50 +
                            ((t - coin.delay) / (1 - coin.delay)) *
                                (box.maxHeight + 90),
                        child: Opacity(
                          opacity: (t > 0.92)
                              ? max(0.0, 1 - (t - 0.92) / 0.08)
                              : 1.0,
                          child: CoinIcon(
                            size: coin.size,
                            frame: (((t - coin.delay) /
                                        (1 - coin.delay) *
                                        coin.spin *
                                        12)
                                    .floor()) %
                                12,
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
