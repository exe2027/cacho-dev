import 'package:flutter/material.dart';

import '../state/audio.dart';
import 'casino_anims.dart';

/// Botón con fondo de sprite (método de sprites del menú).
///
/// El texto (y el icono opcional) se dibujan POR CÓDIGO encima del
/// sprite, nunca horneados en el PNG. El sprite se estira con
/// [BoxFit.fill] al tamaño del botón: los sprites de botón son
/// 700×112 (aspecto 6,25) y el botón se usa a ~318–350×48
/// (aspecto 6,6–7,3), un estiramiento horizontal del 6–16% que
/// solo ensancha levemente las esquinas redondeadas; el centro es
/// plano y no se afecta. La variante `_off` se usa cuando
/// [onPressed] es null (botón deshabilitado, sin acción).
///
/// El feedback de pulsación es escala 0,97 (el mismo que
/// BronzeButton), sin desplazar el layout. NO se usa en hojas ni
/// en el lobby: BronzeButton sigue siendo el primario allí (su
/// SweepGlow del botón PARTIR no se toca).
///
/// [sweep] es opt-in y por defecto inactivo: solo el botón primario
/// JUGAR AHORA de las tarjetas de Buscar salas lo pasa en `true`
/// (los secundarios NO lo llevan, y ningún otro uso —incluida una
/// eventual mesa en partida— lo hereda por defecto). Con `sweep`
/// activo el botón se envuelve en el SweepGlow ya existente con
/// los mismos parámetros del PARTIR del lobby (ciclo 3 s, pico
/// 0,12, dorado mate), y solo cuando está habilitado
/// ([onPressed] no nulo) y tras [CasinoAnims.enabledIn]: con el
/// interruptor de animaciones apagado o con reduce-motion del
/// sistema no hay sweep. No se toca el sprite, el texto ni la
/// variante `_off` (deshabilitado nunca lleva sweep).
class SpriteButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String asset;
  final String disabledAsset;
  final double fontSize;
  final String? fontFamily;
  final FontWeight fontWeight;
  final Color foreground;
  final Color disabledForeground;
  final bool sweep;

  const SpriteButton({
    super.key,
    required this.label,
    required this.asset,
    required this.disabledAsset,
    required this.onPressed,
    this.icon,
    this.fontSize = 16,
    this.fontFamily,
    this.fontWeight = FontWeight.w800,
    this.foreground = Colors.white,
    this.disabledForeground = Colors.white70,
    this.sweep = false,
  });

  @override
  State<SpriteButton> createState() => _SpriteButtonState();
}

class _SpriteButtonState extends State<SpriteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final button = GestureDetector(
      onTap: widget.onPressed == null
          ? null
          : () {
              AudioService.instance.turnPop();
              widget.onPressed!();
            },
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: Transform.scale(
        scale: _pressed ? 0.97 : 1.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              enabled ? widget.asset : widget.disabledAsset,
              fit: BoxFit.fill,
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon,
                        size: 20,
                        color: enabled
                            ? widget.foreground
                            : widget.disabledForeground),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: widget.fontFamily,
                        fontSize: widget.fontSize,
                        fontWeight: widget.fontWeight,
                        color: enabled
                            ? widget.foreground
                            : widget.disabledForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // Sweep solo opt-in + habilitado + animaciones permitidas
    // (interruptor y reduce-motion): fuera de eso, el botón es
    // exactamente el de antes. El sweep es el único bucle infinito
    // que aporta este widget (uno por pantalla visible cuando el
    // primario está en pantalla).
    if (widget.sweep && enabled && CasinoAnims.enabledIn(context)) {
      return SweepGlow(
        cycle: const Duration(seconds: 3),
        peakOpacity: 0.12,
        child: button,
      );
    }
    return button;
  }
}
