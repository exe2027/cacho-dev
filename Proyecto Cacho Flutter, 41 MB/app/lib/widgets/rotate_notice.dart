import 'package:flutter/material.dart';

import '../theme.dart';

/// Paleta casino de MENU (sin cafe, 25-oct): fondos oscuros de la
/// familia del buscar_bg (azul noche -> casi negro -> purpura
/// profundo) con dorado mate #C9A24B (CachoColors.gold) como acento.
/// Constantes LOCALES de este archivo: theme.dart la redefine otro
/// agente y no se toca ni se redefine aqui.
const _menuCasinoDialog = Color(0xFF120A24);

/// M2 (rediseño completo): aviso de giro FUERA de partida, en el
/// paso hoja → mesa, cuando el celular está en vertical. Nunca
/// fuerza la rotación: ofrece seguir igual en vertical con un
/// botón ≥44 px, y la elección se recuerda en la sesión (static,
/// no persistente). Si el usuario cancela, se vuelve a avisar la
/// próxima vez; si elige seguir en vertical, no se molesta más.
class RotateNotice {
  static bool _verticalChosen = false;

  static Future<bool> confirmIfPortrait(BuildContext context) async {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= size.height || _verticalChosen) return true;
    final go = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        backgroundColor: _menuCasinoDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: CachoColors.gold.withValues(alpha: 0.55)),
        ),
        title: const Text('MESA EN HORIZONTAL', style: titleStyle),
        content: const Text(
          'La mesa se juega mejor en horizontal. Gira el celular '
          'para verla completa, o sigue igual en vertical.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(dlg).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
          ),
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(dlg).pop(true),
            child: const Text('Jugar igual en vertical',
                style: TextStyle(
                    fontSize: 14,
                    color: CachoColors.gold,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (go == true) _verticalChosen = true;
    return go == true;
  }
}
