import 'package:flutter/material.dart';

import '../state/wallet.dart';
import '../table_themes.dart';
import '../theme.dart';
import 'coin_widgets.dart';
import 'dice_and_cup.dart';

/// Paleta casino de MENU (sin cafe, 25-oct): fondos oscuros de la
/// familia del buscar_bg (azul noche -> casi negro -> purpura
/// profundo) con dorado mate #C9A24B (CachoColors.gold) como acento.
/// Constantes LOCALES de este archivo: theme.dart la redefine otro
/// agente y no se toca ni se redefine aqui.
const _menuCasinoDialog = Color(0xFF120A24);

/// Escaparate de la tienda (sentencia final D27–D30, PRESENTADA,
/// no construida): se mira y se prueba, no se compra.
///
/// Reglas que cumple, sin excepción:
/// - SIN botón de compra, SIN cobro, SIN tocar billeteras (la
///   billetera local y la del servidor ni se leen aquí: M4 se
///   cumple por omisión, sin cifra que mezcle modalidades).
/// - SIN equipar: la vista previa muestra el artículo en un
///   diálogo aparte y no cambia el cuero ni ningún ajuste.
/// - SIN etiqueta "Equipado": no se afirma ningún equipamiento
///   (R24: solo si es real; aquí no se afirma ninguno).
/// - Solo las BANDAS aprobadas (D2): vasos 500–1.500, dados
///   300–1.000, marcos 200–500, celebraciones 500. Nunca un
///   precio puntual nuevo.
/// - R24–R26 (rediseño): cuadrícula uniforme 2×2, misma tarjeta
///   para las 4 categorías, vista previa instantánea y
///   reversible en las 4, todos los textos a 14 px o más.
/// - D30: los dados nuevos mantienen el símbolo de la pinta,
///   no solo el color; los marcos nunca tiñen el aro del
///   turno (la vista previa es un diálogo fuera de partida);
///   las celebraciones solo se ven al ganar (aquí la vista
///   previa es estática, nunca se reproduce sola).
class StoreShowcase extends StatelessWidget {
  const StoreShowcase({super.key});

  void _previewDialog(
      BuildContext context, String title, String band, Widget visual,
      String note) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: _menuCasinoDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: CachoColors.gold.withValues(alpha: 0.55)),
        ),
        title: Text(title, style: titleStyle, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 12),
            Text(band,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              note,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('CERRAR',
                style: TextStyle(
                    fontSize: 14,
                    color: CachoColors.gold,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _previewCups(BuildContext context) {
    _previewDialog(
      context,
      'Vasos',
      'Vasos: ${coinsText(500)}–${coinsText(1500)}',
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final entry in CachoColors.leatherChoices.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  if (cupAssetFor(entry.value) != null)
                    Image.asset(cupAssetFor(entry.value)!,
                        width: 44, height: 52),
                  const SizedBox(height: 4),
                  Text(entry.key,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
      'Vista previa: no se equipa ni se cobra desde aquí.',
    );
  }

  void _previewDice(BuildContext context) {
    _previewDialog(
      context,
      'Dados',
      'Dados: ${coinsText(300)}–${coinsText(1000)}',
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 3; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/images/die_$i.png',
                      width: 40, height: 40),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 4; i <= 6; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/images/die_$i.png',
                      width: 40, height: 40),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Tus dados actuales',
              style: TextStyle(fontSize: 14)),
        ],
      ),
      'Los diseños nuevos mantienen el símbolo de la pinta, '
      'no solo el color. Vista previa: no se equipa ni se cobra.',
    );
  }

  void _previewFrames(BuildContext context) {
    const ids = [tableThemePub, tableThemeDorado, tableThemeNeon];
    _previewDialog(
      context,
      'Marcos',
      'Marcos: ${coinsText(200)}–${coinsText(500)}',
      Column(
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: ThemeMiniature(id: id, height: 44),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tableThemeName(id),
                        style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
        ],
      ),
      'Los marcos nunca tiñen el aro del turno: el semáforo '
      'manda siempre. Vista previa: no se equipa ni se cobra.',
    );
  }

  void _previewCelebrations(BuildContext context) {
    _previewDialog(
      context,
      'Celebraciones',
      'Celebraciones: ${coinsText(500)}',
      const Column(
        children: [
          CoinIcon(size: 48),
          SizedBox(height: 8),
          Text('Lluvia de monedas al ganar',
              style: TextStyle(fontSize: 14)),
        ],
      ),
      'Las celebraciones solo se ven al ganar una partida; '
      'aquí no se reproducen. Vista previa: no se cobra.',
    );
  }

  Widget _card(BuildContext context, String title, String band,
      Widget visual, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      // Padding 8 (no 12): "Celebraciones" a 14 px w800 se
      // partía en dos líneas con 12 (captura 2026-10-25).
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: CachoColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(band,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CachoColors.gold)),
            const SizedBox(height: 8),
            visual,
            const SizedBox(height: 8),
            const Text('Toca para vista previa',
                style: TextStyle(fontSize: 14, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24),
        const Text('TIENDA',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Escaparate: mira y prueba sin comprar. Nada se cobra '
          'ni se equipa desde aquí.',
          style: TextStyle(fontSize: 14, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.92,
          children: [
            _card(
              context,
              'Vasos',
              '${coinsText(500)}–${coinsText(1500)}',
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final entry
                      in CachoColors.leatherChoices.entries)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 2),
                      child: cupAssetFor(entry.value) != null
                          ? Image.asset(cupAssetFor(entry.value)!,
                              width: 30, height: 36)
                          : const SizedBox(width: 30, height: 36),
                    ),
                ],
              ),
              () => _previewCups(context),
            ),
            _card(
              context,
              'Dados',
              '${coinsText(300)}–${coinsText(1000)}',
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 3; i++)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 2),
                      child: Image.asset('assets/images/die_$i.png',
                          width: 30, height: 30),
                    ),
                ],
              ),
              () => _previewDice(context),
            ),
            _card(
              context,
              'Marcos',
              '${coinsText(200)}–${coinsText(500)}',
              const SizedBox(
                width: 110,
                child: ThemeMiniature(
                    id: tableThemeDorado, height: 44),
              ),
              () => _previewFrames(context),
            ),
            _card(
              context,
              'Celebraciones',
              coinsText(500),
              const CoinIcon(size: 40),
              () => _previewCelebrations(context),
            ),
          ],
        ),
      ],
    );
  }
}
