import 'package:flutter/material.dart';

import '../theme.dart';
import '../texts.dart';
import '../widgets/dice_and_cup.dart';

/// Glosario: pintas con su dado y nombre, y qué es un comodín (§7).
class GlossaryContent extends StatelessWidget {
  const GlossaryContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LAS PINTAS',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: CachoColors.gold,
                fontSize: 14,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var f = 1; f <= 6; f++)
              Column(
                children: [
                  DiceFace(value: f, size: 44, showBadge: true),
                  const SizedBox(height: 3),
                  Text(faceName(f),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Horizontal: a ancho real >=640 (la página a 844) las líneas
        // van en 2 columnas para no leer líneas de ~130 caracteres;
        // por debajo (p. ej. el diálogo de glosario desde partida)
        // siguen en una sola columna. Sin ancho fijo a 844.
        LayoutBuilder(
          builder: (context, constraints) {
            const lines = <Widget>[
              _GlossaryLine(
                title: 'Comodín',
                text: 'El As (1) vale por cualquier pinta cuando se resuelve una '
                    'apuesta de otra pinta. Si la apuesta es de Ases, solo cuentan '
                    'los 1 reales.',
              ),
              _GlossaryLine(
                title: 'Dudo',
                text: 'No le crees la apuesta al anterior. Se revelan todos los '
                    'dados: si la apuesta era falsa, pierde un dado quien apostó; '
                    'si era verdadera, lo pierdes tú.',
              ),
              _GlossaryLine(
                title: 'Calzo',
                text: 'Dices que la cantidad apostada es exacta. Si aciertas, '
                    'recuperas un dado; si no, pierdes uno. Se puede calzar '
                    'siempre, queden los dados que queden en juego.',
              ),
              _GlossaryLine(
                title: 'Paso',
                text: 'Con tus 5 dados: o son todos distintos, o forman un Full '
                    '(3 de un número y 2 de otro). Solo el siguiente jugador puede '
                    'desafiarlo, y solo apenas lo dices.',
              ),
              _GlossaryLine(
                title: 'Kamikaze',
                text: 'Una sola vez por partida: la primera vez que quedas con 1 '
                    'dado siendo el único. Todos lanzan de nuevo y NADIE puede '
                    'ver sus dados hasta que el kamikaze elige el número que '
                    'cae: todos pierden los dados con ese número, sin comodines.',
              ),
              _GlossaryLine(
                title: 'Ases (entrar y salir)',
                text: 'Para pasar a Ases, la cantidad mínima es la mitad hacia '
                    'arriba (de 8 Cuadras → 4 Ases). Para salir, el doble + 1 '
                    '(de 4 Ases → 9 de otra pinta).',
              ),
              _GlossaryLine(
                title: 'Monedas y el pozo',
                text: 'Monedas ficticias, sin dinero real. Al crear tu perfil '
                    'recibes 5.000. Cada partida cuesta la apuesta elegida '
                    '(100 a 2.500): en local la eliges tú; en una sala la fija '
                    'el anfitrión al crearla. El pozo es la apuesta por la '
                    'cantidad de jugadores y se lo lleva todo el ganador; si '
                    'hay empate, se devuelve la apuesta. Salir a mitad de una '
                    'partida con apuesta es perderla. Si tu saldo no alcanza '
                    'ni la apuesta mínima, en el inicio aparece un rescate de '
                    '+1.000 una vez al día.',
              ),
            ];
            if (constraints.maxWidth >= 640) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.sublist(0, 4),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.sublist(4),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            );
          },
        ),
      ],
    );
  }
}

class _GlossaryLine extends StatelessWidget {
  final String title;
  final String text;
  const _GlossaryLine({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, height: 1.35, color: CachoColors.ivory),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: CachoColors.gold),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

void showGlossaryDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      // Glosario en azul noche casino, no cuero.
      backgroundColor: CachoColors.menuTop,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: CachoColors.gold.withValues(alpha: 0.55)),
      ),
      title: const Text('GLOSARIO', style: titleStyle),
      content: const SingleChildScrollView(child: GlossaryContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              const Text('CERRAR', style: TextStyle(fontSize: 14, color: CachoColors.gold)),
        ),
      ],
    ),
  );
}

/// "Cómo se juega" en 4 pantallas cortas (master prompt §7).
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = <(String, String)>[
    (
      'Tus dados son secretos',
      'Cada jugador tiene 5 dados bajo su cacho. Solo tú ves los tuyos: '
          'agita el celular o toca tu cacho para mirarlos.',
    ),
    (
      'Apuesta por TODOS los dados',
      'Por turnos, cada uno apuesta cuántos dados de una pinta hay entre '
          'TODOS los de la mesa. Ejemplo: "4 Cuadras" = creo que hay al '
          'menos 4 dados con un 4, contando los Ases como comodines.',
    ),
    (
      'Sube la apuesta… o duda',
      'En tu turno puedes subir (más dados, o la misma cantidad con una '
          'pinta mayor), o dudar si crees que el anterior se pasó. '
          'También puedes calzar si crees que la cantidad es exacta.',
    ),
    (
      'Quien se equivoca pierde un dado',
      'Al dudar o calzar se revelan los dados y se cuenta la verdad. '
          'Quien se quedó sin dados sale del juego. Gana el último '
          'cacho en pie.',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: menuDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  // Franja superior en azul noche casino, no cuero.
                  color: CachoColors.menuTop,
                  border: Border(
                    bottom: BorderSide(
                        color: CachoColors.gold.withValues(alpha: 0.55)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: CachoColors.gold),
                      tooltip: 'Atrás',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 44, minHeight: 44),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text('CÓMO SE JUEGA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: CachoFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: CachoColors.gold,
                              letterSpacing: 2)),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _pages.length + 1,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    if (i == _pages.length) {
                      return const SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: GlossaryContent(),
                      );
                    }
                    final (title, text) = _pages[i];
                    // Horizontal (ÚNICA composición, sin layout vertical
                    // en paralelo): ilustración a la izquierda y texto
                    // desplazable a la derecha. Así cabe a 390 de alto
                    // (el texto hace scroll si la altura no alcanza) y
                    // se adapta a anchos mayores sin fijar 844: la
                    // ilustración ocupa ~26 % del ancho, entre 150 y 220.
                    final illWidth = (MediaQuery.sizeOf(context).width * 0.26)
                        .clamp(150.0, 220.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: illWidth,
                            child: Center(child: _illustration(i)),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${i + 1}. $title',
                                    style:
                                        titleStyle.copyWith(fontSize: 20),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    text,
                                    style: const TextStyle(
                                        fontSize: 16, height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= _pages.length; i++)
                    Container(
                      width: _index == i ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _index == i
                            ? CachoColors.gold
                            : CachoColors.gold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              // Cromado compactado para landscape a 390 de alto:
              // botón sigue a 48 px y pie sigue a 14 px.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    // Botón a 48 px de alto: el BronzeButton solo
                    // (padding 12+12 + línea ~19) quedaba en ~43 px,
                    // bajo el piso táctil de 44 px (R33/R34).
                    if (_index < _pages.length)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: BronzeButton(
                            label: _index == _pages.length - 1
                                ? 'VER EL GLOSARIO'
                                : 'SIGUIENTE',
                            onPressed: () => _page.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: BronzeButton(
                            label: '¡A JUGAR!',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // R4: pie mudado desde el home (mismo texto, 14 px).
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Sin cuentas y sin dinero real: solo apodo, dados y farol.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _illustration(int i) {
    switch (i) {
      case 0:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachoCup(width: 92, height: 106, leather: CachoColors.leatherLight),
            SizedBox(width: 14),
            Column(
              children: [
                DiceFace(value: 4, size: 40),
                SizedBox(height: 6),
                DiceFace(value: 1, size: 40),
              ],
            ),
          ],
        );
      case 1:
        return const Wrap(
          spacing: 6,
          children: [
            DiceFace(value: 4, size: 42),
            DiceFace(value: 4, size: 42),
            DiceFace(value: 1, size: 42),
            DiceFace(value: 4, size: 42),
            DiceFace(value: 6, size: 42, dimmed: true),
          ],
        );
      case 2:
        // Wrap (no Row): los 3 chips suman ~265 px y la columna de
        // ilustración en horizontal es de 150–220 px; con Row
        // desbordarían, con Wrap bajan a 2 filas sin recorte.
        return const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // SUBIR en cuero claro de la paleta: el bronce
            // #8A6D2F con marfil daba 4,12:1, bajo el piso 4,5:1
            // (R35); cuero claro da 7,52:1.
            _MiniChip(label: 'SUBIR', color: CachoColors.leatherLight),
            _MiniChip(label: 'DUDO', color: CachoColors.casinoRed),
            _MiniChip(label: 'CALZO', color: CachoColors.calzoGreen),
          ],
        );
      default:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DiceFace(value: 6, size: 46),
            SizedBox(width: 8),
            Icon(Icons.emoji_events, color: CachoColors.gold, size: 54),
            SizedBox(width: 8),
            DiceFace(value: 6, size: 46),
          ],
        );
    }
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }
}
