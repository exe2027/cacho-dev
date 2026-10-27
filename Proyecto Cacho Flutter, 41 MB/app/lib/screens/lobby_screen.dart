import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/match_controller.dart';
import '../state/wallet.dart';
import '../table_themes.dart';
import '../widgets/coin_widgets.dart';
import '../widgets/casino_anims.dart';
import '../widgets/menu_transitions.dart';
import '../theme.dart';
import 'game_screen.dart';
import '../widgets/rotate_notice.dart';

/// Paleta casino de MENU (sin cafe, 25-oct): fondos oscuros de la
/// familia del buscar_bg (azul noche -> casi negro -> purpura
/// profundo) con dorado mate #C9A24B (CachoColors.gold) como acento.
/// Constantes LOCALES de este archivo: theme.dart la redefine otro
/// agente y no se toca ni se redefine aqui.
const _menuCasino = Color(0xFF16203A);
const _menuCasinoDeep = Color(0xFF0B0B14);
const _menuCasinoDialog = Color(0xFF120A24);

class LobbyScreen extends StatefulWidget {
  final MatchController controller;
  final Color leather;
  // AN7: barajar fichas al revelar el código (solo al crear, no al unirse).
  final bool showCodeShuffle;
  // F8: rejoin (sala activa) -> sin telón AN6 ni vaso AN16 al entrar.
  final bool isRejoin;
  const LobbyScreen(
      {super.key,
      required this.controller,
      required this.leather,
      this.showCodeShuffle = false,
      this.isRejoin = false});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  /// Cambiar mi nombre sin salir de la sala (pedido del usuario,
  /// 24-oct): el servidor lo difunde a todos al instante.
  Future<void> _renameDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: c.myNickname);
    final name = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: _menuCasinoDialog,
        title: const Text('Tu nombre en la sala'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
          onSubmitted: (v) => Navigator.of(dctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) c.renameMe(name);
  }

  int _fillBots = 0;
  String _botDifficulty = 'media';
  bool _navigated = false;
  String? _shownError;
  // AN6: cortina de cierre al partir (se abre en GameScreen).
  bool _closingCurtain = false;
  bool _curtainNavigating = false;
  // AN7: barajar fichas al revelar el código (solo anfitrión, una vez).
  bool _codeShuffleDone = false;
  bool _showShuffle = false;
  // M2: aviso de giro lobby→mesa (una vez por visita al lobby; si
  // cancela, no se le vuelve a preguntar hasta rotar o reingresar).
  bool _rotateAsked = false;
  // TODO HORIZONTAL: scroll horizontal de asientos (con asa visible).
  final _seatScroll = ScrollController();
  bool _declinedVertical = false;

  MatchController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
  }

  @override
  void dispose() {
    _seatScroll.dispose();
    c.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _goToGame() async {
    if (_navigated || !mounted) return;
    // M2: aviso de giro al pasar de pantalla vertical a mesa
    // (confirmIfPortrait ya resuelve horizontal/elegido).
    if (!_rotateAsked) {
      _rotateAsked = true;
      final go = await RotateNotice.confirmIfPortrait(context);
      if (!mounted) return;
      if (!go) {
        // Cancelar: queda en el lobby (la partida ya arrancó); al
        // rotar a horizontal el gancho del build navega solo.
        _declinedVertical = true;
        _curtainNavigating = false;
        setState(() => _closingCurtain = false);
        return;
      }
    }
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      pushReplacementMenuPage(
        context,
        builder: (_) => GameScreen(
            controller: c,
            leather: widget.leather,
            curtainEntry: !widget.isRejoin,
            cupEntry: !widget.isRejoin),
      );
    });
  }

  void _onChange() {
    if (!mounted) return;
    if (c.gameStarted && !_navigated && !_declinedVertical) {
      if (CasinoAnims.enabledIn(context) &&
          !_closingCurtain &&
          !_curtainNavigating) {
        // AN6: la cortina se cierra en el lobby y se abre en la mesa;
        // la propia cortina navega al cerrarse (o al tocarla).
        _curtainNavigating = true;
        setState(() => _closingCurtain = true);
        return;
      }
      if (_closingCurtain) return;
      _goToGame();
    }
    // AN7: al llegar el código (solo anfitrión que creó la sala).
    if (c.roomCode != null &&
        c.isHost &&
        widget.showCodeShuffle &&
        !_codeShuffleDone &&
        CasinoAnims.enabled) {
      _codeShuffleDone = true;
      _showShuffle = true;
    }
    final err = c.errorMessage;
    if (err != null && err != _shownError) {
      _shownError = err;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        c.clearError();
        _shownError = null;
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final me = c.me;
    final humans = c.players.where((p) => !p.isBot).toList();
    final allReady = humans.isNotEmpty && humans.every((p) => p.ready);
    // Corrección 26-oct 09:35: máximo 6 jugadores en total.
    final maxFill = (6 - c.players.length).clamp(0, 5);
    if (_fillBots > maxFill) _fillBots = maxFill;
    // M2: si declinó vertical y luego rota, la mesa arranca sola.
    if (c.gameStarted &&
        !_navigated &&
        MediaQuery.of(context).orientation == Orientation.landscape) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToGame());
    }
    return Scaffold(
      // R19/R31: fondo de menú (nunca paño a pantalla completa).
      body: DecoratedBox(
        decoration: menuDecoration,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera fija: atrás + SALA + miniatura real (R19).
                  // Frente B fase 2: entrada de una sola vez
                  // (StaggerIn 250 ms, índice 0); sin bucle nuevo
                  // y sin tocar tamaños ni centrado.
                  StaggerIn(
                    index: 0,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _menuCasino,
                        border: Border(
                          bottom: BorderSide(
                              color: CachoColors.gold.withValues(alpha: 0.55)),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Lados de 64 px a ambos lados para que
                          // SALA quede centrada de verdad (antes el
                          // lado derecho medía 64 y el izquierdo 44).
                          SizedBox(
                            width: 64,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    size: 22, color: CachoColors.gold),
                                tooltip: 'Atrás',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 44, minHeight: 44),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text('SALA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: CachoFonts.display,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: CachoColors.gold,
                                    // 1,5 como SheetStrip: mismo cromo
                                    // de hoja en lobby y creación.
                                    letterSpacing: 1.5)),
                          ),
                          SizedBox(
                            width: 64,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 36,
                                  child: ThemeMiniature(
                                      id: c.tableTheme, height: 36),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // TODO HORIZONTAL (26-oct): una sola estructura
                  // horizontal, sin lista vertical de asientos en
                  // paralelo. Izquierda: código + invitación +
                  // apuesta/pozo. Derecha: asientos en scroll
                  // horizontal + controles fijos debajo (PARTIR
                  // nunca se empuja fuera de vista). En portrait
                  // NO se construye layout vertical (frente D).
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, cst) {
                        final availW = cst.maxWidth - 36;
                        final leftW =
                            cst.maxWidth >= 1200 ? 440.0 : availW * 0.46;
                        // Tarjetas de 210 + margen 8: el aviso de
                        // scroll aparece solo si realmente no caben.
                        final rightW = availW - leftW - 16;
                        final seatsOverflow =
                            c.players.length * 218 - 8 > rightW;
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ---- Columna izquierda: sala ----
                                  SizedBox(
                                    width: leftW,
                                    // Red de seguridad, no estructura:
                                    // en el caso normal cabe sin
                                    // scroll; solo desplaza si
                                    // coinciden conectando + saldo en
                                    // línea + aviso de saldo bajo.
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // AN7: fichas que se barajan
                                          // antes de revelar el código
                                          // (solo al crear, no al
                                          // unirse).
                                          if (_showShuffle)
                                            SizedBox(
                                              height: 56,
                                              child: Center(
                                                child: ShuffleChips(onDone: () {
                                                  if (mounted) {
                                                    setState(() =>
                                                        _showShuffle = false);
                                                  }
                                                }),
                                              ),
                                            )
                                          else
                                            PulseOpacity(
                                              child: Text(
                                                c.roomCode ?? '·····',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily: CachoFonts.display,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 44,
                                                  color: CachoColors.gold,
                                                  letterSpacing: 12,
                                                ),
                                              ),
                                            ),
                                          // Frente B fase 2: entrada
                                          // de una sola vez
                                          // (StaggerIn 250 ms, índice
                                          // 1); el pulso del código
                                          // sigue siendo el
                                          // PulseOpacity
                                          // preexistente, sin bucle
                                          // nuevo.
                                          StaggerIn(
                                            index: 1,
                                            child: Center(
                                              child: TextButton.icon(
                                                style: TextButton.styleFrom(
                                                    minimumSize:
                                                        const Size(0, 44)),
                                                onPressed: c.roomCode == null
                                                    ? null
                                                    : () async {
                                                        await Clipboard.setData(
                                                            ClipboardData(
                                                          text:
                                                              '¡Juguemos Cacho! Entra a mi sala con el código ${c.roomCode}',
                                                        ));
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Invitación copiada: pégala en WhatsApp')),
                                                          );
                                                        }
                                                      },
                                                icon: const Icon(Icons.share,
                                                    size: 16),
                                                label: const Text(
                                                    'Copiar invitación para WhatsApp',
                                                    style: TextStyle(
                                                        fontSize: 14)),
                                              ),
                                            ),
                                          ),
                                          // AN8: dado girando mientras
                                          // conecta.
                                          if (!c.connected &&
                                              c.errorMessage == null)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  DiceSpinner(size: 26),
                                                  SizedBox(width: 8),
                                                  Text(
                                                      'Conectando con el servidor…',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Color(
                                                              0xFFFF9A9A))),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          // Apuesta y pozo de la sala
                                          // (lo eligió el anfitrión).
                                          // R21: pozo provisional
                                          // rotulado. Relieve de
                                          // tarjeta (R42 radio 12):
                                          // degradado casino oscuro +
                                          // sombra neutra, solo paleta
                                          // casino, sin color nuevo.
                                          StaggerIn(
                                            index: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    _menuCasino,
                                                    _menuCasinoDeep,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: CachoColors.gold
                                                        .withValues(
                                                            alpha: 0.55)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.35),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  // Wrap (antes Row
                                                  // rígida): a 390 px la
                                                  // línea "El Club VIP ·
                                                  // Apuesta: 2.500 por
                                                  // jugador" quedaba al
                                                  // borde del desborde;
                                                  // en Wrap baja ordenada.
                                                  Wrap(
                                                    alignment:
                                                        WrapAlignment.center,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [
                                                      const CoinIcon(size: 20),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${stakeTierName(c.stake)} · Apuesta: ${coinsText(c.stake)} por jugador',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 15),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Mesa: ${tableThemeName(c.tableTheme)}',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white70),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  // D18: POZO nunca
                                                  // PREMIO y la fórmula
                                                  // con "jugadores"
                                                  // junto a ×N, valor
                                                  // real. AN11: rodillo
                                                  // de dígitos.
                                                  // "Se fija al partir."
                                                  // va dentro del mismo
                                                  // Wrap (antes línea
                                                  // propia) para no
                                                  // gastar una línea de
                                                  // cabecera fija.
                                                  Wrap(
                                                    alignment:
                                                        WrapAlignment.center,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Pozo si se parte ahora: ${coinsText(c.stake)} × ${c.players.length + _fillBots} '
                                                        '${(c.players.length + _fillBots) == 1 ? 'jugador' : 'jugadores'} = ',
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                      DigitRoller(
                                                        target: c.stake *
                                                            (c.players.length +
                                                                _fillBots),
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                      const Text(
                                                        ' · Se fija al partir.',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                    ],
                                                  ),
                                                  if (c.serverBalance !=
                                                      null) ...[
                                                    const SizedBox(height: 6),
                                                    // M4: la cifra lleva
                                                    // su modalidad en
                                                    // la misma línea
                                                    // (antes el chip de
                                                    // saldo en línea iba
                                                    // sin rótulo).
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Text(
                                                            'Billetera en línea',
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    CachoColors
                                                                        .gold)),
                                                        const SizedBox(
                                                            width: 8),
                                                        BalanceChip(
                                                            balance: c
                                                                .serverBalance!,
                                                            spinning: false),
                                                      ],
                                                    ),
                                                    if (c.serverBalance! <
                                                        c.stake)
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 6),
                                                        child: Shake(
                                                          child: Text(
                                                            'No te alcanza el saldo para la apuesta de esta sala.',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0xFFFF9A9A),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // ---- Columna derecha: asientos + controles ----
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                                'ASIENTOS · ${c.players.length}',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: CachoColors.gold,
                                                    letterSpacing: 1.0)),
                                            const Spacer(),
                                            // Indicación de scroll:
                                            // visible solo si hay
                                            // más asientos que los
                                            // que caben en la fila.
                                            if (seatsOverflow)
                                              const Text(
                                                  'Desliza para ver más →',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white54)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 112,
                                          child: Scrollbar(
                                            controller: _seatScroll,
                                            thumbVisibility: true,
                                            thickness: 4,
                                            radius: const Radius.circular(2),
                                            child: ListView.builder(
                                              controller: _seatScroll,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: c.players.length,
                                              itemBuilder: (sctx, idx) {
                                                final p = c.players[idx];
                                                // AN9: pop de entrada
                                                // (solo transform).
                                                // F9: escalonada 60 ms
                                                // + AN9 pop.
                                                return StaggerIn(
                                                  key: ValueKey(
                                                      'stagger-${p.id}'),
                                                  index: idx,
                                                  child: PopIn(
                                                    key: ValueKey(p.id),
                                                    child: _seatCard(p),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Controles fijos bajo los
                                        // asientos (R20 adaptado a
                                        // horizontal): nunca dentro
                                        // del scroll, así PARTIR no
                                        // se empuja fuera de vista.
                                        if (me != null && !me.isBot)
                                          StaggerIn(
                                            index: 1,
                                            child: SizedBox(
                                              height: 44,
                                              child: Row(
                                                children: [
                                                  const Text('Estoy listo',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                  Switch(
                                                    value: me.ready,
                                                    activeThumbColor:
                                                        CachoColors.gold,
                                                    onChanged: c.setReady,
                                                  ),
                                                  if (c.isHost) ...[
                                                    const Spacer(),
                                                    const Text(
                                                        'Rellenar con bots: ',
                                                        style: TextStyle(
                                                            fontSize: 14)),
                                                    IconButton(
                                                      onPressed: _fillBots > 0
                                                          ? () => setState(
                                                              () => _fillBots--)
                                                          : null,
                                                      icon: const Icon(Icons
                                                          .remove_circle_outline),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 44,
                                                              minHeight: 44),
                                                    ),
                                                    Text('$_fillBots',
                                                        style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800)),
                                                    IconButton(
                                                      onPressed: _fillBots <
                                                              maxFill
                                                          ? () => setState(
                                                              () => _fillBots++)
                                                          : null,
                                                      icon: const Icon(Icons
                                                          .add_circle_outline),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 44,
                                                              minHeight: 44),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (c.isHost) ...[
                                          Wrap(
                                            spacing: 8,
                                            alignment: WrapAlignment.center,
                                            children: [
                                              for (final d in const {
                                                'facil': 'Fácil',
                                                'media': 'Media',
                                                'dificil': 'Difícil',
                                              }.entries)
                                                ChoiceChip(
                                                  label: Text(d.value,
                                                      style: const TextStyle(
                                                          fontSize: 14)),
                                                  selected:
                                                      _botDifficulty == d.key,
                                                  onSelected: (_) => setState(
                                                      () => _botDifficulty =
                                                          d.key),
                                                  selectedColor:
                                                      CachoColors.gold,
                                                  labelStyle: TextStyle(
                                                    color:
                                                        _botDifficulty == d.key
                                                            ? const Color(
                                                                0xFF2B1810)
                                                            : CachoColors.ivory,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  backgroundColor: _menuCasino,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // AN4: shimmer mate en el
                                          // botón dorado. Frente B
                                          // fase 2: entrada de una
                                          // sola vez del primario
                                          // (StaggerIn 250 ms, índice
                                          // 2) POR FUERA del SweepGlow
                                          // preexistente: el barrido
                                          // sigue siendo el único
                                          // bucle del botón, sin
                                          // bucle nuevo. La respuesta
                                          // al toque sigue siendo la
                                          // escala 0,97 propia de
                                          // BronzeButton, sin cambios.
                                          StaggerIn(
                                            index: 2,
                                            child: SweepGlow(
                                              cycle: const Duration(seconds: 3),
                                              peakOpacity: 0.12,
                                              child: BronzeButton(
                                                label: 'PARTIR LA PARTIDA',
                                                icon: Icons.play_arrow,
                                                fontSize: 16,
                                                onPressed: allReady &&
                                                        (c.players.length +
                                                                _fillBots) >=
                                                            2
                                                    ? () => c.startOnline(
                                                        fillBots: _fillBots,
                                                        botDifficulty:
                                                            _botDifficulty)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (!allReady)
                                            const Padding(
                                              padding: EdgeInsets.only(top: 6),
                                              child: Text(
                                                  'Faltan jugadores por ponerse listos',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white54)),
                                            ),
                                        ] else
                                          // Frente B fase 2: misma
                                          // entrada de una sola vez
                                          // que el bloque del
                                          // anfitrión (StaggerIn
                                          // 250 ms, índice 2); sin
                                          // bucle nuevo, sin tocar el
                                          // texto.
                                          StaggerIn(
                                            index: 2,
                                            child: const Padding(
                                              padding: EdgeInsets.only(top: 10),
                                              child: Text(
                                                  'Esperando a que el anfitrión parta la partida…',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white60)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // AN6: cortina de cierre; al cerrarse (o al tocarla)
              // navega.
              if (_closingCurtain)
                Positioned.fill(
                  child: EntryCurtain(
                    opening: false,
                    onDone: _goToGame,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de asiento compacta para la fila horizontal (210 px):
  /// nombre + saldo arriba, estado abajo, y (solo yo) renombrar +
  /// micrófono a 44 px. Mismo relieve que la placa de pozo:
  /// degradado casino oscuro + sombra neutra, borde dorado 1 px
  /// (R42). Los datos son los mismos de la tarjeta vertical
  /// anterior; solo cambia la disposición.
  Widget _seatCard(PlayerView p) {
    return Container(
      width: 210,
      height: 112,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _menuCasino,
            _menuCasinoDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CachoColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                p.isBot ? Icons.smart_toy_outlined : Icons.person_outline,
                color: CachoColors.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.nickname + (p.id == c.myId ? ' (tú)' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              if (p.balance != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 14),
                      const SizedBox(width: 3),
                      Text(coinsText(p.balance!),
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFE9A8),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (p.id == c.hostId)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.star, size: 16, color: CachoColors.gold),
                ),
              if (!p.isBot && p.id != c.myId)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    p.micOn ? Icons.mic : Icons.mic_off,
                    size: 16,
                    color: p.micOn ? const Color(0xFF7DFF9A) : Colors.white24,
                  ),
                ),
              Icon(
                p.ready ? Icons.check_circle : Icons.hourglass_empty,
                size: 18,
                color: p.ready ? Colors.greenAccent : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(p.ready ? 'Listo' : 'Esperando',
                  style: const TextStyle(fontSize: 14, color: Colors.white60)),
            ],
          ),
          const Spacer(),
          if (!p.isBot && p.id == c.myId)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _renameDialog(context),
                  tooltip: 'Cambiar mi nombre',
                  icon: const Icon(Icons.edit_outlined,
                      size: 19, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                IconButton(
                  onPressed: c.toggleMic,
                  tooltip: c.myMicOn
                      ? 'Apagar mi micrófono'
                      : 'Activar mi micrófono',
                  icon: Icon(
                    c.myMicOn ? Icons.mic : Icons.mic_off,
                    size: 19,
                    color: c.myMicOn ? const Color(0xFF7DFF9A) : Colors.white38,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
