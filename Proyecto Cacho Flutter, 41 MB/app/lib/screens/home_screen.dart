import 'package:blobatar/flutter.dart' as blobatar;
import 'package:cacho_engine/bots.dart';
import 'package:cacho_engine/cacho_engine.dart';
import 'package:flutter/material.dart';

import '../state/match_controller.dart';
import '../state/active_room.dart';
import '../state/route_observer.dart';
import '../state/audio.dart';
import '../state/settings.dart';
import '../state/wallet.dart';
import '../widgets/carousel_fling.dart';
import '../widgets/casino_anims.dart';
import '../widgets/menu_transitions.dart';
import '../table_themes.dart';
import '../theme.dart';
import '../widgets/dice_and_cup.dart';
import '../widgets/store_showcase.dart';
import '../state/app_viewport.dart';
import '../widgets/rotate_notice.dart';
import '../widgets/coin_widgets.dart';
import 'buscar_salas_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'lobby_screen.dart';
import 'setup_screens.dart';

/// Inicio SIN scroll (master prompt §7): logo, tres caminos claros y
/// Personalizar. Apodo y cuero viven en Personalizar, ya rellenados.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with RouteAware, WidgetsBindingObserver {
  final _joinCode = TextEditingController();
  // TODO HORIZONTAL: el scroll principal desapareció; el controlador
  // se conserva solo como Listenable del fondo parallax (estático
  // sin scroll: _ParallaxBg lee offset 0 cuando no hay clientes).
  final _homeScroll = ScrollController();
  static const _realPageCount = 6;
  final _carouselKey = GlobalKey<_CircularRoomCarouselState>();
  int _carouselIndex = 0; // real index 0..5
  bool? _onlineOk; // null = comprobando
  String _preset = 'completo';

  // Sala activa (salió sin querer del navegador y volvió).
  String? _activeCode;
  String _activePhase = '';

  // AN1 (sentencia animaciones): telón de apertura, una sola vez por
  // sesión, montado tras el primer frame para no retrasar la pintura.
  static bool _curtainShown = false;
  bool _showCurtain = false;
  // AN13: moneda que cae al rescatar.
  bool _rescueCoin = false;

  Settings get _s => Settings.instance;

  String get _name =>
      _s.nickname.trim().isEmpty ? 'Jugador' : _s.nickname.trim();

  Color get _leather =>
      CachoColors.leatherChoices.values.elementAt(_s.leatherIndex);

  String get _initials {
    final parts = _name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'YO';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  GameConfig get _config =>
      _preset == 'clasico' ? GameConfig.clasico() : GameConfig.cachoCompleto();

  @override
  void initState() {
    super.initState();
    _probe();
    _checkActiveRoom();
    _s.addListener(_refresh);
    Wallet.instance.addListener(_refresh);
    WidgetsBinding.instance.addObserver(this);
    if (!_curtainShown && CasinoAnims.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _curtainShown = true;
        setState(() => _showCurtain = true);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  /// Volvió al inicio desde una partida o un lobby (en la APK el
  /// inicio no se recrea: sin este re-chequeo el aviso de sala
  /// activa jamás aparecía).
  @override
  void didPopNext() => _checkActiveRoom();

  /// Volvió a la app desde otra aplicación o segundo plano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkActiveRoom();
  }

  /// Si este dispositivo quedó dentro de una sala (salió sin querer
  /// del navegador: atrás, recarga, pestaña cerrada), el inicio le
  /// ofrece volver a entrar. La sala se valida contra el servidor:
  /// si ya no existe o la partida terminó, el aviso se borra solo.
  Future<void> _checkActiveRoom() async {
    final code = await ActiveRoomStore.read();
    if (!mounted) return;
    if (code == null) {
      // Sin sala guardada: si el aviso estaba puesto, se baja.
      if (_activeCode != null) setState(() => _activeCode = null);
      return;
    }
    final st = await MatchController.probeRoom(code);
    if (!mounted) return;
    if (st == null) {
      // Sin respuesta del servidor: se muestra igual (al tocarlo se
      // vuelve a comprobar); mejor un aviso de más que perder la sala.
      setState(() {
        _activeCode = code;
        _activePhase = '';
      });
      return;
    }
    final usable = st.exists &&
        st.phase != 'finished' &&
        (st.member || st.phase == 'lobby');
    if (usable) {
      setState(() {
        _activeCode = code;
        _activePhase = st.phase;
      });
    } else {
      await ActiveRoomStore.clear();
      if (mounted) setState(() => _activeCode = null);
    }
  }

  Future<void> _enterActiveRoom() async {
    final code = _activeCode;
    if (code == null) return;
    final st = await MatchController.probeRoom(code);
    if (!mounted) return;
    if (st == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sin conexión con el servidor de salas')));
      return;
    }
    if (st.exists && st.phase == 'playing' && st.member) {
      // Partida en curso y su asiento lo espera (cubierto por un
      // bot): entra directo a la mesa recuperando su lugar.
      // M2: aviso de giro fuera de partida.
      if (!await RotateNotice.confirmIfPortrait(context)) return;
      if (!mounted) return;
      final c = MatchController.onlineRejoin(
        nickname: _name,
        code: code,
        config: _config,
      );
      pushMenuPage(
        context,
        builder: (_) =>
            GameScreen(controller: c, leather: _leather, cupEntry: false),
      );
      return;
    }
    if (st.exists && st.phase == 'lobby') {
      final c = MatchController.onlineJoin(
        nickname: _name,
        code: code,
        config: _config,
      );
      pushMenuPage(
        context,
        builder: (_) =>
            LobbyScreen(controller: c, leather: _leather, isRejoin: true),
      );
      return;
    }
    await ActiveRoomStore.clear();
    if (!mounted) return;
    setState(() => _activeCode = null);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa sala ya no está activa')));
  }

  Future<void> _dismissActiveRoom() async {
    await ActiveRoomStore.clear();
    if (mounted) setState(() => _activeCode = null);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _s.removeListener(_refresh);
    Wallet.instance.removeListener(_refresh);
    _homeScroll.dispose();
    _joinCode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _probe() async {
    final ok = await MatchController.probeServer();
    if (mounted) setState(() => _onlineOk = ok);
  }

  // ---------------- partidas ----------------

  void _playLocal(
      {required int bots,
      required String difficulty,
      int stake = 0,
      String tableTheme = defaultTableTheme,
      String? preset}) async {
    if (!await RotateNotice.confirmIfPortrait(context)) return;
    if (!mounted) return;
    if (preset != null) _preset = preset;
    final c = MatchController.local(
      nickname: _name,
      botCount: bots,
      difficulty: BotDifficulty.values.byName(difficulty),
      config: _config,
      stake: stake,
      tableTheme: tableTheme,
    );
    c.startLocal();
    pushMenuPage(
      context,
      builder: (_) => GameScreen(controller: c, leather: _leather),
    );
  }

  void _playGuided() async {
    // M2: aviso de giro fuera de partida (la guiada va directa a
    // la mesa, sin hoja intermedia).
    if (!await RotateNotice.confirmIfPortrait(context)) return;
    if (!mounted) return;
    final c = MatchController.local(
      nickname: _name,
      botCount: 2,
      difficulty: BotDifficulty.media,
      config: GameConfig.cachoCompleto(),
      guided: true,
    );
    c.startLocal();
    pushMenuPage(
      context,
      builder: (_) => GameScreen(controller: c, leather: _leather),
    );
  }

  void _createOnline(
      {int stake = 500,
      String tableTheme = defaultTableTheme,
      String? preset}) async {
    if (!await RotateNotice.confirmIfPortrait(context)) return;
    if (!mounted) return;
    if (preset != null) _preset = preset;
    final c = MatchController.onlineCreate(
      nickname: _name,
      preset: _preset,
      config: _config,
      stake: stake,
      tableTheme: tableTheme,
    );
    pushMenuPage(
      context,
      builder: (_) =>
          LobbyScreen(controller: c, leather: _leather, showCodeShuffle: true),
    );
  }

  // ---------------- hojas y diálogos ----------------

  void _showLocalSheet() {
    // R9: pantalla propia (ya no bottom sheet que tape el logo).
    pushMenuPage(
      context,
      builder: (_) => LocalSetupScreen(
        initialPreset: _preset,
        onPlay: ({
          required int bots,
          required String difficulty,
          required int stake,
          required String tableTheme,
          required String preset,
        }) =>
            _playLocal(
          bots: bots,
          difficulty: difficulty,
          stake: stake,
          tableTheme: tableTheme,
          preset: preset,
        ),
      ),
    );
  }

  /// Entrada discreta a "Buscar salas": no rediseña las tarjetas
  /// del home; solo abre la pantalla nueva con los flujos reales
  /// (local con 3 bots fácil, y crear sala en línea con ese stake).
  void _showBuscarSalas() {
    pushMenuPage(
      context,
      builder: (_) => BuscarSalasScreen(
        initialPreset: _preset,
        onPlayLocal: ({
          required int bots,
          required String difficulty,
          required int stake,
          required String tableTheme,
          required String preset,
        }) =>
            _playLocal(
          bots: bots,
          difficulty: difficulty,
          stake: stake,
          tableTheme: tableTheme,
          preset: preset,
        ),
        onCreateOnline: ({
          required int stake,
          required String tableTheme,
          required String preset,
        }) =>
            _createOnline(
          stake: stake,
          tableTheme: tableTheme,
          preset: preset,
        ),
        onJoinOnline: (code) => _joinOnlineWith(code),
      ),
    );
  }

  void _showFriendsSheet() {
    // R9: pantalla propia (ya no bottom sheet que tape el logo).
    pushMenuPage(
      context,
      builder: (_) => FriendsSetupScreen(
        initialPreset: _preset,
        onlineOk: _onlineOk,
        onRetryProbe: () {
          setState(() => _onlineOk = null);
          _probe();
        },
        joinCode: _joinCode,
        onCreate: ({
          required int stake,
          required String tableTheme,
          required String preset,
        }) =>
            _createOnline(
          stake: stake,
          tableTheme: tableTheme,
          preset: preset,
        ),
        onJoin: (code) => _joinOnlineWith(code),
      ),
    );
  }

  void _joinOnlineWith(String code) {
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escribe el código de la sala (ej: K7QF)')),
      );
      return;
    }
    final c = MatchController.onlineJoin(
      nickname: _name,
      code: code,
      config: _config,
    );
    pushMenuPage(
      context,
      builder: (_) => LobbyScreen(controller: c, leather: _leather),
    );
  }

  void _showPersonalize() {
    final nickCtrl = TextEditingController(text: _s.nickname);
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlg) => AlertDialog(
          // Menú casino (25-oct): diálogo en azul noche, no cuero.
          backgroundColor: CachoColors.menuTop,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: CachoColors.gold.withValues(alpha: 0.55)),
          ),
          title: const Text('PERSONALIZAR', style: titleStyle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nickCtrl,
                  maxLength: 12,
                  onChanged: (v) {
                    _s.nickname = v;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Apodo (así te ven en la mesa)',
                    hintText: 'Ej: El Seba',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Cuero de tu cacho',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < CachoColors.leatherChoices.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setDlg(() => _s.leatherIndex = i),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: CachoColors.leatherChoices.values
                                  .elementAt(i),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _s.leatherIndex == i
                                    ? CachoColors.gold
                                    : Colors.white24,
                                width: _s.leatherIndex == i ? 2 : 1,
                              ),
                            ),
                            child: _s.leatherIndex == i
                                ? const Icon(Icons.check,
                                    size: 18, color: CachoColors.gold)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  CachoColors.leatherChoices.keys.elementAt(_s.leatherIndex),
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Sonidos'),
                  value: _s.soundEffects,
                  onChanged: (v) => setDlg(() => _s.soundEffects = v),
                  activeColor: CachoColors.gold,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Música de casino'),
                  subtitle: const Text('Una canción de salón, en bucle',
                      style: TextStyle(fontSize: 14)),
                  value: _s.music,
                  onChanged: (v) => setDlg(() => _s.music = v),
                  activeColor: CachoColors.gold,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Murmullo de fondo'),
                  subtitle: const Text('El ambiente del casino, bajito',
                      style: TextStyle(fontSize: 14)),
                  value: _s.murmur,
                  onChanged: (v) => setDlg(() => _s.murmur = v),
                  activeColor: CachoColors.gold,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Efectos reducidos'),
                  subtitle: const Text('Menos animaciones y destellos',
                      style: TextStyle(fontSize: 14)),
                  value: _s.reducedEffects,
                  onChanged: (v) => setDlg(() => _s.reducedEffects = v),
                  activeColor: CachoColors.gold,
                  contentPadding: EdgeInsets.zero,
                ),
                // AN17: interruptor de animaciones de casino.
                SwitchListTile(
                  title: const Text('Animaciones'),
                  subtitle: const Text('Telón, partículas y efectos de casino',
                      style: TextStyle(fontSize: 14)),
                  value: _s.animationsEnabled,
                  onChanged: (v) => setDlg(() => _s.animationsEnabled = v),
                  activeColor: CachoColors.gold,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Ayuda para principiantes'),
                  subtitle: const Text(
                      'Muestra la probabilidad de tu apuesta al subir',
                      style: TextStyle(fontSize: 14)),
                  value: _s.beginnerHelp,
                  onChanged: (v) => setDlg(() => _s.beginnerHelp = v),
                  activeColor: CachoColors.gold,
                  contentPadding: EdgeInsets.zero,
                ),
                // R23/R48/R49 (rediseño): renglones de pantalla,
                // solo en menús, debajo y separados. En
                // escritorio/Android: botón real de pantalla
                // completa; en iPhone: NINGÚN botón, solo el
                // renglón exacto + añadir a inicio (función
                // oficial de Safari). Se muestran porque R48/R49
                // quedaron resueltos (puente + manifest + iconos).
                if (appViewport.fullscreenEnabled) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Pantalla completa',
                            style: TextStyle(fontSize: 14)),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: const Size(0, 44)),
                        onPressed: () async {
                          if (appViewport.isFullscreen) {
                            appViewport.exitFullscreen();
                          } else {
                            appViewport.requestFullscreen();
                          }
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          if (dlgCtx.mounted) setDlg(() {});
                        },
                        child: Text(
                          appViewport.isFullscreen ? 'Salir' : 'Activar',
                          style: const TextStyle(
                              fontSize: 14,
                              color: CachoColors.gold,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ] else if (appViewport.isIOS) ...[
                  const Divider(height: 24),
                  const Text(
                    'En iPhone la pantalla completa de página no está permitida: el juego se ve completo sin ella.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Añadir a pantalla de inicio (opcional): función oficial de Safari — Compartir → Añadir a pantalla de inicio. No instala nada por fuera: crea un icono que abre la misma web (https://cacho.pages.dev) sin las barras del navegador.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
                // D27–D30 (sentencia final): tienda PRESENTADA, no
                // construida. Escaparate con bandas aprobadas, vista
                // previa sin equipar sin pagar; sin compra, sin
                // cobro, sin billeteras.
                const StoreShowcase(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _s.save();
                if (dlgCtx.mounted) Navigator.of(dlgCtx).pop();
              },
              child: const Text('LISTO',
                  style: TextStyle(
                      color: CachoColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- pantalla ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: CachoColors.menuMid,
            child: Stack(
              children: [
                // F9: parallax leve del fondo casino (0,3x el scroll
                // del home; estático si las animaciones están
                // apagadas). Antes era fondo pub.
                Positioned.fill(child: _ParallaxBg(scroll: _homeScroll)),
                // F9: luz cálida de lámpara arriba (Home, nunca mesa).
                const Positioned(top: 0, left: 0, right: 0, child: LampGlow()),
                // AN2: motas doradas sobre el fondo libre del home.
                const Positioned.fill(child: GoldParticles()),
                SafeArea(
                  child: Column(
                    children: [
                      // Barra superior casino estilo Monopoly Poker
                      _buildTopBar(),
                      if (_activeCode != null) _activeRoomBanner(),
                      // Carrusel horizontal de mesas (tiers)
                      Expanded(
                        child: _buildCarouselSection(),
                      ),
                      // Barra inferior con perfil y accesos rápidos
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // AN13: moneda que cae junto a la franja al rescatar.
          if (_rescueCoin)
            Positioned(
              left: 24,
              top: 48,
              child: FallingCoin(onDone: () {
                if (mounted) {
                  setState(() => _rescueCoin = false);
                }
              }),
            ),
          // AN1: telón de apertura, una sola vez por sesión.
          if (_showCurtain)
            Positioned.fill(
              child: EntryCurtain(
                opening: true,
                showLogo: true,
                onDone: () {
                  if (mounted) setState(() => _showCurtain = false);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- LOBBY HORIZONTAL CASINO (ESTILO MONOPOLY POKER) ----------------

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: CachoColors.menuTop.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: CachoColors.gold.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Píldora de Fichas (Monopoly Poker style)
          GestureDetector(
            onTap: () {
              if (Wallet.instance.canRescue) {
                Wallet.instance.rescue();
                AudioService.instance.coinOne();
                if (CasinoAnims.enabled) setState(() => _rescueCoin = true);
              } else {
                _showPersonalize();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: CachoColors.gold.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinningCoin(size: 20),
                  const SizedBox(width: 8),
                  Text(
                    coinsText(Wallet.instance.balance),
                    style: const TextStyle(
                      fontFamily: CachoFonts.display,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CachoColors.ivory,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: CachoColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.add, size: 13, color: CachoColors.menuMid),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Dinero virtual / billetes ($0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: const Color(0xFF34C759).withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments, size: 17, color: Color(0xFF34C759)),
                const SizedBox(width: 6),
                const Text(
                  '\$0',
                  style: TextStyle(
                    fontFamily: CachoFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF34C759),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 13, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Centro: Marca y Slogans
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SweepGlow(child: const DudoLogo(fontSize: 16)),
              Text(
                '¿QUÉ TAN BUENO ERES MINTIENDO?',
                style: TextStyle(
                  letterSpacing: 1.2,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: CachoColors.gold.withValues(alpha: 0.9),
                ),
              ),
              const Text(
                'CACHO · EL DUDO CHILENO',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Rescate disponible
          if (Wallet.instance.canRescue)
            Tooltip(
              message: 'Rescate diario disponible (+1.000 fichas)',
              child: IconButton(
                icon: const Icon(Icons.card_giftcard,
                    color: CachoColors.gold, size: 22),
                onPressed: () {
                  Wallet.instance.rescue();
                  AudioService.instance.coinOne();
                  if (CasinoAnims.enabled) setState(() => _rescueCoin = true);
                },
              ),
            ),
          // Dot de conectividad
          Tooltip(
            message: _onlineOk == true
                ? 'Conectado al servidor en línea'
                : (_onlineOk == false
                    ? 'Sin conexión a internet'
                    : 'Verificando red...'),
            child: Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _onlineOk == true
                    ? const Color(0xFF35D461)
                    : (_onlineOk == false
                        ? Colors.redAccent
                        : Colors.orangeAccent),
                boxShadow: [
                  BoxShadow(
                    color: (_onlineOk == true
                            ? const Color(0xFF35D461)
                            : Colors.orangeAccent)
                        .withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          // Botón Reglas / Cómo se juega
          IconButton(
            icon: const Icon(Icons.menu_book_outlined,
                color: CachoColors.ivory, size: 22),
            tooltip: 'CÓMO SE JUEGA',
            onPressed: () => pushMenuPage(context,
                builder: (_) => const HowToPlayScreen()),
          ),
          // Botón Ajustes
          IconButton(
            icon: const Icon(Icons.settings, color: CachoColors.gold, size: 22),
            tooltip: 'Ajustes',
            onPressed: _showPersonalize,
          ),
        ],
      ),
    );
  }

  /// Navigate the circular carousel to the given real index (0..5).
  void _goToRealPage(int realIndex) {
    _carouselKey.currentState?.goTo(realIndex);
  }

  Widget _buildCarouselSection() {
    return Column(
      children: [
        Expanded(
          child: _CircularRoomCarousel(
            key: _carouselKey,
            itemCount: _realPageCount,
            initialIndex: _carouselIndex,
            onIndexChanged: (newIdx) {
              // El sonido no suena aquí: un cambio de una sala
              // suena su ráfaga al inicio (_animateSteps), y un
              // fling multi-sala suena un tack por paso al
              // asentarse cada paso. Aquí solo se actualiza el
              // índice (no al entrar al menú: el carrusel no llama
              // a onIndexChanged en init).
              setState(() => _carouselIndex = newIdx);
            },
            itemBuilder: (context, index, isSelected) {
              return _buildLobbyCard(index, isSelected: isSelected);
            },
          ),
        ),
        // Puntos de página interactivos (circular dots)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _realPageCount; i++)
                GestureDetector(
                  onTap: () => _goToRealPage(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _carouselIndex ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _carouselIndex
                          ? CachoColors.gold
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyCard(int index, {bool isSelected = false}) {
    if (index == 0) {
      // ──────────────────────────────────────────────────────
      // Tarjeta 0: TU PRIMERA PARTIDA GUIADA (Tutorial)
      // Academia de Cacho · Paleta clásica pizarra/teal (NO NEÓN)
      // ──────────────────────────────────────────────────────
      const academyColor = Color(0xFF388E8E);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? academyColor : academyColor.withValues(alpha: 0.5),
            width: isSelected ? 2.2 : 1.2,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162B28), Color(0xFF0C1816)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            if (isSelected)
              BoxShadow(
                color: academyColor.withValues(alpha: 0.25),
                blurRadius: 22,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: LayoutBuilder(
                  builder: (ctx, inner) {
                    final compact = inner.maxHeight < 200;
                    final showExtra = inner.maxHeight >= 210;
                    final emblemSize = compact ? 28.0 : 38.0;
                    final iconSize = compact ? 16.0 : 22.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: academyColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: academyColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Text(
                                  'EMPIEZA AQUÍ',
                                  style: TextStyle(
                                    fontFamily: CachoFonts.body,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: academyColor,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.school, color: academyColor, size: 18),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: emblemSize,
                                  height: emblemSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: academyColor.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: academyColor.withValues(alpha: 0.65),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: academyColor.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.school, size: iconSize, color: academyColor),
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'MESA DE PRÁCTICA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: CachoFonts.display,
                                      fontSize: compact ? 13 : 14,
                                      fontWeight: FontWeight.w800,
                                      color: academyColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                if (showExtra) ...[
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 1,
                                          color: academyColor.withValues(alpha: 0.4),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 5),
                                          child: Text(
                                            'TU PRIMERA PARTIDA GUIADA',
                                            style: TextStyle(
                                              fontFamily: CachoFonts.body,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 1,
                                          color: academyColor.withValues(alpha: 0.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (showExtra)
                          Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 12, color: academyColor),
                                  SizedBox(width: 4),
                                  Text(
                                    '2 bots lentos · Sin riesgo de fichas',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        BronzeButton(
                          label: 'JUGAR TUTORIAL',
                          icon: Icons.play_arrow,
                          color: academyColor,
                          fontSize: 12,
                          fontFamily: CachoFonts.display,
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: compact ? 6 : 8,
                          ),
                          onPressed: _playGuided,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ──────────────────────────────────────────────────────
    // Tiers 1–5: diseños progresivos NO NEON
    //   1 = La Taberna (rústico, caoba/cuero, novatos)
    //   2 = El Boliche (clásico, paño verde billar, plata)
    //   3 = El Casino  (elegante, oro pulido, carbón oficial)
    //   4 = La Mansión (lujoso, borgoña/rubí, alta tensión)
    //   5 = El Club VIP (exclusivo, ónix negro, champagne/platino)
    // ──────────────────────────────────────────────────────
    final tierStakes = [100, 250, 500, 1000, 2500];
    final stake = tierStakes[index - 1];
    final tierNames = [
      'LA TABERNA',
      'EL BOLICHE',
      'EL CASINO',
      'LA MANSIÓN',
      'EL CLUB VIP'
    ];
    final tierSubtitles = [
      '6 Jugadores · Novatos',
      'Paño Tradicional · Nivel Medio',
      'Mesa Oficial · Paño Carbón',
      'Alta Tensión · Grandes Apostadores',
      'Leyendas del Cacho · Exclusivo VIP',
    ];
    // Warm, elegant palette — NO neon colors:
    final tierAccent = [
      const Color(0xFFB0855E), // warm wood/leather
      const Color(0xFF5D9C6A), // classic billiard green
      const Color(0xFFD4A843), // rich casino gold
      const Color(0xFF8B3A4A), // deep wine burgundy
      const Color(0xFFD4AF72), // champagne gold on onyx
    ];
    final tierGradientTop = [
      const Color(0xFF382315), // dark mahogany wood
      const Color(0xFF16321D), // deep billiard forest
      const Color(0xFF261D12), // dark gold velvet
      const Color(0xFF2D1121), // royal wine
      const Color(0xFF151518), // onyx black
    ];
    final tierGradientBot = [
      const Color(0xFF1B110A), // pitch wood
      const Color(0xFF0B190E), // pitch forest
      const Color(0xFF110D07), // pitch velvet
      const Color(0xFF14070F), // pitch wine
      const Color(0xFF060607), // deep onyx
    ];
    final tierSprites = [
      'assets/images/bg_taberna.jpg',
      'assets/images/bg_boliche.jpg',
      'assets/images/bg_casino.jpg',
      'assets/images/bg_mansion.jpg',
      'assets/images/bg_clubvip.jpg',
    ];
    // Tier icon (progressing elegance)
    final tierIcons = [
      Icons.sports_bar,        // tavern: beer mug
      Icons.casino,            // boliche: classic dice
      Icons.diamond_outlined,  // casino: diamond
      Icons.villa,             // mansion: palace villa
      Icons.workspace_premium, // vip: royal crown
    ];

    final name = tierNames[index - 1];
    final sub = tierSubtitles[index - 1];
    final color = tierAccent[index - 1];
    final sprite = tierSprites[index - 1];
    final gradTop = tierGradientTop[index - 1];
    final gradBot = tierGradientBot[index - 1];
    final tierIcon = tierIcons[index - 1];
    final affords = Wallet.instance.balance >= stake;
    final pot = stake * 6; // 6 jugadores en mesa completa
    final theme = index == 1 ? tableThemePub : defaultTableTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.5),
          width: isSelected ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (isSelected)
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background: tier gradient + sprite overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradTop, gradBot],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.45,
                child: Image.asset(
                  sprite,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LayoutBuilder(
                builder: (ctx, inner) {
                  final compact = inner.maxHeight < 200;
                  final showSub = inner.maxHeight >= 205;
                  final emblemSize = compact ? 28.0 : 38.0;
                  final eIconSize = compact ? 16.0 : 20.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tierIcon, size: 15, color: color),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: color.withValues(alpha: 0.45)),
                                    ),
                                    child: Text(
                                      'MESA 6 JUGADORES',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: CachoFonts.body,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (stake == 500) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CachoColors.gold,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'OFICIAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (index == 5) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VIP',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Material(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _createOnline(
                                    stake: stake,
                                    tableTheme: theme,
                                    preset: _preset,
                                  ),
                                  child: Tooltip(
                                    message:
                                        'Crear sala en línea (${coinsText(stake)})',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.wifi, size: 11, color: color),
                                          const SizedBox(width: 3),
                                          Text(
                                            'ONLINE',
                                            style: TextStyle(
                                              fontFamily: CachoFonts.body,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: color,
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
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: emblemSize,
                                height: emblemSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.16),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.65),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(tierIcon, size: eIconSize, color: color),
                              ),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: CachoFonts.display,
                                    fontSize: compact ? 13 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (showSub) ...[
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 1,
                                        color: color.withValues(alpha: 0.4),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 5),
                                        child: Text(
                                          sub,
                                          style: const TextStyle(
                                            fontFamily: CachoFonts.body,
                                            fontSize: 9.5,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 1,
                                        color: color.withValues(alpha: 0.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Estante de apuestas y pozo (Monopoly Poker style)
                      Container(
                        margin: EdgeInsets.only(bottom: compact ? 4 : 8),
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: compact ? 2.5 : 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('BUY-IN',
                                      style: TextStyle(
                                          fontSize: 9, color: Colors.white60)),
                                  Text(
                                    coinsText(stake),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: CachoColors.ivory),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 20, color: Colors.white24),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  const Text('POZO',
                                      style: TextStyle(
                                          fontSize: 9, color: Colors.white60)),
                                  Text(
                                    coinsText(pot),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: color),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // index == 1 tiene 'JUGAR CONTRA LA MÁQUINA' para satisfacer widget_test
                      BronzeButton(
                        label: index == 1
                            ? 'JUGAR CONTRA LA MÁQUINA'
                            : 'JUGAR AHORA',
                        icon: affords ? Icons.play_arrow : Icons.lock,
                        color: affords ? color : Colors.grey,
                        fontSize: 12,
                        fontFamily: CachoFonts.display,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: compact ? 6 : 8,
                        ),
                        onPressed: affords
                            ? () => _playLocal(
                                  bots: 5,
                                  difficulty: index <= 2
                                      ? 'facil'
                                      : (index <= 4 ? 'media' : 'dificil'),
                                  stake: stake,
                                  tableTheme: theme,
                                  preset: _preset,
                                )
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Necesitas ${coinsText(stake)} fichas para esta mesa'),
                                    action: Wallet.instance.canRescue
                                        ? SnackBarAction(
                                            label: 'RESCATAR +1.000',
                                            textColor: CachoColors.gold,
                                            onPressed: () {
                                              Wallet.instance.rescue();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                  ),
                                );
                              },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CachoColors.menuMid.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: CachoColors.gold.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // JUGAR CON AMIGOS (etiqueta requerida por test)
          ElevatedButton.icon(
            onPressed: _showFriendsSheet,
            icon: const Icon(Icons.groups, size: 18, color: CachoColors.ivory),
            label: const Text(
              'JUGAR CON AMIGOS',
              style: TextStyle(
                fontFamily: CachoFonts.display,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CachoColors.ivory,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2434),
              foregroundColor: CachoColors.ivory,
              side: BorderSide(color: CachoColors.gold.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          // BUSCAR SALAS
          ElevatedButton.icon(
            onPressed: _showBuscarSalas,
            icon: const Icon(Icons.search, size: 18, color: CachoColors.gold),
            label: const Text(
              'BUSCAR SALAS',
              style: TextStyle(
                fontFamily: CachoFonts.display,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CachoColors.gold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14100C),
              foregroundColor: CachoColors.gold,
              side: BorderSide(color: CachoColors.gold.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const Spacer(),
          // Cápsula de perfil del jugador
          GestureDetector(
            onTap: _showPersonalize,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CachoColors.menuTop,
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: CachoColors.gold.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: CachoColors.gold, width: 1.5),
                    ),
                    child: ClipOval(
                      child: blobatar.Blobatar(
                        name: _name,
                        size: 32,
                        options: const blobatar.BlobatarOptions(
                          hue: 45.0,
                          background: blobatar.Backdrop.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $_name',
                        style: const TextStyle(
                          fontFamily: CachoFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: CachoColors.ivory,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _leather,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Personalizar cacho',
                            style: TextStyle(
                                fontSize: 10, color: CachoColors.gold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 14, color: Colors.white54),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // CÓMO SE JUEGA
          ElevatedButton.icon(
            onPressed: () => pushMenuPage(context,
                builder: (_) => const HowToPlayScreen()),
            icon:
                const Icon(Icons.help_outline, size: 18, color: Colors.white70),
            label: const Text(
              'CÓMO SE JUEGA',
              style: TextStyle(
                fontFamily: CachoFonts.display,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141B28),
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// R2/R8/R29: panel de estado único — avatar Blobatar (mismos
  /// parámetros que la mesa: tono 45, círculo, semilla = apodo;
  /// sin punto de presencia ni placa de mesa) + saludo. La sala
  /// activa ya NO va aquí: es el banner bajo la franja. La cifra
  /// de saldo NO va aquí: vive solo en la franja R1 (HomeStrip),
  /// y el rescate solo en la franja si cabe; duplicarla en el
  /// panel violaría la tabla canónica R29. El renglón a 14 px lo
  /// dice para que nadie busque el saldo donde ya no está.
  /// Relieve propio: degradado casino azul noche→casi negro +
  /// sombra neutra (misma altura que antes: 54 + 52 + 12, R7
  /// intacto). Antes era cuero→madera.
  Widget _statusPanel({double topPad = 54}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CachoColors.gold.withValues(alpha: 0.55)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CachoColors.menuTop, CachoColors.menuMid],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CachoColors.gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: blobatar.Blobatar(
                      name: _name,
                      size: 48,
                      options: const blobatar.BlobatarOptions(
                        hue: 45.0,
                        background: blobatar.Backdrop.circle,
                      ),
                      semanticLabel: _name,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $_name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CachoColors.ivory)),
                    const SizedBox(height: 2),
                    const Text('Saldo en la franja superior',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Banner compacto de sala activa bajo la franja (TODO
  /// HORIZONTAL): una sola fila — código, detalle corto, botón
  /// Entrar (44 px) y descartar (44 px) — para que la columna
  /// izquierda quepa también con sala activa sin scroll.
  Widget _activeRoomBanner() {
    final detail = _activePhase == 'playing'
        ? 'Partida en curso · tu asiento te espera'
        : _activePhase == 'lobby'
            ? 'La sala sigue abierta en el lobby'
            : 'Tu sala sigue ahí';
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CachoColors.menuTop,
        border: Border(
          bottom: BorderSide(color: CachoColors.gold.withValues(alpha: 0.55)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room, color: CachoColors.gold, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SALA ACTIVA · $_activeCode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: CachoFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.5)),
                Text(detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _enterActiveRoom,
            style: FilledButton.styleFrom(
              backgroundColor: CachoColors.gold,
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Entrar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          IconButton(
            onPressed: _dismissActiveRoom,
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white54,
            tooltip: 'Descartar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;
  final double titleSize;
  // Compacto horizontal: menos aire lateral y placa de 40 px para
  // dar ~16 px más al texto en celdas de ~236 px (el subtítulo
  // offline "Sin conexión con el servidor de salas" queda justo
  // a 126 px; con compacto dispone de ~142 px en 2 líneas).
  final bool compact;

  /// R6 (rediseño): la miniatura lateral se QUITÓ tras la
  /// verificación en captura 2026-10-25: con 56 px los títulos
  /// ("TU PRIMERA PARTIDA GUIADA", "JUGAR CONTRA LA MÁQUINA")
  /// y los subtítulos truncaban, y a 48 px seguirían truncando.
  /// La condición R6 ("solo si cabe sin bajar textos") no se
  /// cumple: las miniaturas reales quedan solo en el selector
  /// de mesa (R12), donde sí caben.
  const _HomeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlight = false,
    this.titleSize = 15,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tarjeta del home por sprite (método de sprites): card_home.png
    // 700×176, generado con PIL desde card_menu.png (mismo estilo
    // oscuro con borde dorado fino, centro plano, sin texto) por
    // empalme vertical + reescalado uniforme, así su aspecto
    // 3,977 coincide EXACTO con la tarjeta 350×88 y BoxFit.fill no
    // deforma nada. card_menu.png directo (780×280, aspecto 2,79)
    // NO encajaba: estirarlo a 350×88 habría aplastado el borde a
    // elipse. TODO el texto va por código encima del sprite.
    // Corrección del truncamiento (regresión auditada, confirmada
    // EN CAPTURA por el agente de verificación 25-oct noche: con
    // 76 px la 2ª línea del subtítulo de la guiada ("jugando")
    // quedaba cortada a la mitad por el borde inferior): título y
    // subtítulo con maxLines:2 y altura 76→88 (la vía prevista).
    // 2 líneas de título Cinzel 15 px + 2 de subtítulo 14 px miden
    // ~86 px reales (la estimación de ~70 px era corta: Cinzel
    // tiene ascenso/descenso mayor), así que 88 px los contiene
    // sin recorte y el home vertical sigue sin scroll (el contenido
    // termina a ~833 px de 844). Placa 44×44 y chevron se mantienen.
    // La guiada conserva su distinción: placa EMPIEZA AQUÍ + filete dorado
    // 2 px, aquí como borde superpuesto al sprite (el sprite ya
    // trae su propio filete fino; el overlay lo engrosa a 2 px).
    // Sombra por código bajo el sprite, como antes.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/card_home.png',
                    fit: BoxFit.fill,
                  ),
                ),
                if (highlight)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CachoColors.gold, width: 2),
                      ),
                    ),
                  ),
                Container(
                  height: 88,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 40 : 44,
                        height: compact ? 40 : 44,
                        decoration: BoxDecoration(
                          // Placa del icono: azul noche casino, no madera.
                          color: CachoColors.menuTop,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: CachoColors.gold.withValues(alpha: 0.55)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: CachoColors.gold, size: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                // Título sin tracking: "TU PRIMERA
                                // PARTIDA GUIADA" truncaba a 15.5 px con
                                // tracking 0.6 (captura 2026-10-25).
                                // En horizontal titleSize 14 (mínimo
                                // exigido) para caber en 2 líneas en
                                // celdas de ~236 px a 844 de ancho.
                                style: TextStyle(
                                  fontFamily: CachoFonts.display,
                                  fontWeight: FontWeight.w700,
                                  fontSize: titleSize,
                                )),
                            Text(subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 20, color: Colors.white54),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fondo casino con parallax leve (F9): la imagen se desplaza a
/// 0,3x el scroll del home, con escala 1,12 para no dejar huecos.
/// Estático cuando las animaciones están apagadas. Usa buscar_bg.png
/// (el gradiente casino ya existente, 0 % cálido oscuro medido),
/// no la foto del pub (82 % cálido oscuro arriba).
class _ParallaxBg extends StatelessWidget {
  final ScrollController scroll;
  const _ParallaxBg({required this.scroll});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scroll,
      builder: (_, __) {
        final dy = CasinoAnims.enabledIn(context) && scroll.hasClients
            ? -scroll.offset * 0.3
            : 0.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: 1.12,
            child: Image.asset(
              'assets/images/buscar_bg.png',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

/// Carrusel circular con solapamiento 3D ("sobre puesto") estilo Parchisi Star.
/// La tarjeta central está en primer plano (z-index superior, escala 1.0, sombras profundas).
/// Las tarjetas laterales quedan por detrás (solapadas un 25-30% bajo la central,
/// escala 0.86, atenuadas) y son interactivas al tocarse o deslizarse.
class _CircularRoomCarousel extends StatefulWidget {
  final int itemCount;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final Widget Function(BuildContext context, int index, bool isSelected)
      itemBuilder;

  const _CircularRoomCarousel({
    super.key,
    required this.itemCount,
    this.initialIndex = 0,
    this.onIndexChanged,
    required this.itemBuilder,
  });

  @override
  State<_CircularRoomCarousel> createState() => _CircularRoomCarouselState();
}

class _CarouselSlotData {
  final int index;
  final double pos; // normalized position (-2.0 .. 2.0)
  final double dist; // abs(pos)
  _CarouselSlotData(
      {required this.index, required this.pos, required this.dist});
}

class _CircularRoomCarouselState extends State<_CircularRoomCarousel>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _animCtrl;
  Animation<double>? _offsetAnim;
  double _pageOffset = 0.0; // [-1.0 .. 1.0]
  double _dragAccum = 0.0;

  /// Fling multi-sala en curso: pasos que quedan (incluye el paso
  /// actual) y dirección en índices (+1 = siguiente sala, -1 =
  /// anterior). [_flingTotalSteps] distingue un cambio lento de
  /// una sala (ráfaga de ruleta al inicio) de un barrido rápido
  /// (un tack por sala al asentarse cada paso).
  int _pendingSteps = 0;
  int _pendingDir = 1;
  int _flingTotalSteps = 0;

  int get currentIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animCtrl = AnimationController(
      vsync: this,
      // Un paso dura 120 ms (carouselStepDurationMs): un fling
      // de 3 salas tarda ~360 ms y cada tarjeta se ve pasar.
      duration: const Duration(milliseconds: carouselStepDurationMs),
    )
      ..addListener(() {
        if (_offsetAnim != null) {
          setState(() => _pageOffset = _offsetAnim!.value);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final rounded = _pageOffset.round();
          if (rounded != 0) {
            _currentIndex = (_currentIndex - rounded + widget.itemCount) %
                widget.itemCount;
            _pageOffset = 0.0;
            widget.onIndexChanged?.call(_currentIndex);
            // En un fling multi-sala, un tack por sala al
            // asentarse el paso (tack tack tack). En un cambio
            // de una sola sala ya sonó la ráfaga al inicio.
            if (_flingTotalSteps > 1) {
              AudioService.instance.tack();
            }
          } else {
            _pageOffset = 0.0;
          }
          if (_pendingSteps > 0) {
            _pendingSteps--;
            if (_pendingSteps > 0) {
              _startStep();
            } else {
              _flingTotalSteps = 0;
              setState(() {});
            }
          } else {
            setState(() {});
          }
        }
      });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// Un paso de animación: desde el offset actual (0 tras un paso
  /// anterior, o el arrastre del usuario en el primer paso) hasta
  /// la tarjeta siguiente en la dirección del fling.
  void _startStep() {
    _offsetAnim = Tween<double>(
      begin: _pageOffset,
      end: -_pendingDir.toDouble(),
    ).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward(from: 0.0);
  }

  /// Anima [steps] salas en dirección [dir] (+1 siguiente, -1
  /// anterior), paso a paso. Si ya hay un fling en curso, la
  /// petición nueva se ignora (el arrastre del usuario lo cancela
  /// en _onDragStart). Con animaciones apagadas, salto directo
  /// al índice final con una sola ráfaga de ruleta.
  void _animateSteps(int dir, int steps) {
    if (steps <= 0) return;
    if (!CasinoAnims.enabledIn(context)) {
      AudioService.instance.roulette();
      _currentIndex =
          (_currentIndex + dir * steps + widget.itemCount * steps) %
              widget.itemCount;
      _pageOffset = 0.0;
      widget.onIndexChanged?.call(_currentIndex);
      setState(() {});
      return;
    }
    if (_animCtrl.isAnimating || _pendingSteps > 0) return;
    _pendingDir = dir;
    _pendingSteps = steps;
    _flingTotalSteps = steps;
    // Cambio lento de una sala: ráfaga de ruleta al inicio, como
    // antes. Fling multi-sala: sin ráfaga; cada paso suena su
    // tack al asentarse (ver el listener de completed).
    if (steps == 1) AudioService.instance.roulette();
    _startStep();
  }

  void next() => _animateSteps(1, 1);

  void previous() => _animateSteps(-1, 1);

  void goTo(int target) {
    if (target == _currentIndex) return;
    int diff = target - _currentIndex;
    if (diff > widget.itemCount ~/ 2) diff -= widget.itemCount;
    if (diff < -widget.itemCount ~/ 2) diff += widget.itemCount;
    // Ir a una sala lejana ya no es un salto instantáneo: gira
    // paso a paso por las intermedias, con tack por sala si son
    // varias, o ráfaga si es solo la vecina.
    _animateSteps(diff > 0 ? 1 : -1, diff.abs());
  }

  void _animateToOffset(double target) {
    if (target == 0.0) {
      // Volver al sitio: animación de retorno, sin sonido ni pasos.
      _offsetAnim = Tween<double>(begin: _pageOffset, end: 0.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
      );
      _animCtrl.forward(from: 0.0);
      return;
    }
    _animateSteps(target < 0 ? 1 : -1, 1);
  }

  void _onDragStart(DragStartDetails details) {
    // Agarrar el carrusel cancela cualquier fling en curso.
    _pendingSteps = 0;
    _flingTotalSteps = 0;
    _animCtrl.stop();
    _dragAccum = _pageOffset;
  }

  void _onDragUpdate(DragUpdateDetails details, double cardSpacing) {
    if (cardSpacing <= 0) return;
    final delta = details.primaryDelta ?? 0.0;
    _dragAccum += delta / cardSpacing;
    setState(() {
      _pageOffset = _dragAccum.clamp(-1.25, 1.25);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0.0;
    // Sensibilidad: umbral de arrastre 0.08 de página (antes 0.18)
    // y velocidad 150 px/s (antes 300). Un movimiento ligero y
    // rápido ya dispara el giro; un toque o arrastre mínimo
    // (velocidad < 150 Y distancia < 0.08) vuelve a su sitio sin
    // cambiar de sala. La velocidad decide cuántas salas avanza:
    // 150-600 = 1, 600-1400 = 2, 1400-2600 = 3, >= 2600 = 4.
    final steps = carouselFlingSteps(
      velocity: v,
      offset: _pageOffset,
      itemCount: widget.itemCount,
    );
    if (steps == 0) {
      _animateToOffset(0.0);
      return;
    }
    // La velocidad manda si supera el umbral; si no, el signo del
    // arrastre (en home, arrastrar a la izquierda, offset/velocidad
    // negativos, avanza a la sala siguiente, dir +1).
    final dir = v.abs() >= 150
        ? (v < 0 ? 1 : -1)
        : (_pageOffset < 0 ? 1 : -1);
    _animateSteps(dir, steps);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final totalW = box.maxWidth;
        final totalH = box.maxHeight;
        final cardH = (totalH - 32).clamp(180.0, 248.0);
        final cardW = (cardH * 1.55).clamp(280.0, 395.0);
        final maxSpacing = (totalW - cardW * 0.35) / 2;
        final cardSpacing = (cardW * 0.72)
            .clamp(cardW * 0.45, maxSpacing.clamp(140.0, 380.0));

        final List<_CarouselSlotData> slots = [];
        for (int k = -2; k <= 2; k++) {
          final pos = k + _pageOffset;
          final dist = pos.abs();
          if (dist > 1.85) continue;
          final idx =
              (_currentIndex + k + widget.itemCount * 2) % widget.itemCount;
          slots.add(_CarouselSlotData(index: idx, pos: pos, dist: dist));
        }

        // Clave del solapamiento ("sobre puesto"):
        // Ordenamos por distancia decreciente: los más lejanos se pintan primero (al fondo),
        // y la tarjeta central (dist ≈ 0) se pinta al FINAL (encima de ambas laterales).
        slots.sort((a, b) => b.dist.compareTo(a.dist));

        // FIX mouse_tracker.dart:199 — Las tarjetas superpuestas con
        // Transform+Scale confunden el hit-testing de Flutter Web porque
        // múltiples widgets responden al cursor simultáneamente.
        // Solución: IgnorePointer en TODAS las tarjetas y manejo de taps
        // en el GestureDetector padre via onTapUp por posición.

        return Stack(
          alignment: Alignment.center,
          children: [
            // Área de arrastre y tarjetas
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, cardSpacing),
                onHorizontalDragEnd: _onDragEnd,
                onTapUp: (details) {
                  // Taps en laterales: calcular posición relativa al centro
                  final centerX = totalW / 2;
                  final tapX = details.localPosition.dx;
                  final dx = tapX - centerX;
                  // Si el tap cae fuera de la mitad central, navegar
                  if (dx.abs() > cardW * 0.35) {
                    if (dx > 0) {
                      next();
                    } else {
                      previous();
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: slots.map((slot) {
                    final isCenter = slot.dist < 0.25;
                    final scale =
                        (1.0 - (slot.dist * 0.13)).clamp(0.85, 1.0);
                    final opacity =
                        (1.0 - (slot.dist * 0.35)).clamp(0.50, 1.0);
                    final xOffset = slot.pos * cardSpacing;

                    return IgnorePointer(
                      // Solo la tarjeta central recibe eventos directos
                      // (botones internos); las laterales delegan al
                      // GestureDetector padre.
                      ignoring: !isCenter,
                      child: Transform.translate(
                        offset: Offset(xOffset, 0),
                        child: Transform.scale(
                          scale: CasinoAnims.enabledIn(context) ? scale : 1.0,
                          child: Opacity(
                            opacity:
                                CasinoAnims.enabledIn(context) ? opacity : 1.0,
                            child: SizedBox(
                              width: cardW,
                              height: cardH,
                              child: Stack(
                                children: [
                                  widget.itemBuilder(
                                      context, slot.index, isCenter),
                                  // Velo sutil en tarjetas laterales (solo visual, sin InkWell)
                                  if (!isCenter)
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: (slot.dist * 0.38)
                                                .clamp(0.12, 0.42),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Flecha izquierda — siempre visible (circular)
            Positioned(
              left: 10,
              child: _buildNavArrow(
                icon: Icons.arrow_back_ios_new,
                tooltip: 'Mesa anterior',
                onPressed: previous,
              ),
            ),

            // Flecha derecha — siempre visible (circular)
            Positioned(
              right: 10,
              child: _buildNavArrow(
                icon: Icons.arrow_forward_ios,
                tooltip: 'Siguiente mesa',
                onPressed: next,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.70),
        shape: BoxShape.circle,
        border: Border.all(
          color: CachoColors.gold.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: CachoColors.gold, size: 18),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
