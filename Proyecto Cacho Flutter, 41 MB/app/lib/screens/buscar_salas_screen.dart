import 'package:flutter/material.dart';

import '../state/wallet.dart';
import '../widgets/casino_anims.dart';
import '../table_themes.dart';
import '../theme.dart';
import '../widgets/coin_widgets.dart';
import '../widgets/sprite_button.dart';
import '../widgets/rotate_notice.dart';

/// Fondo de "Buscar salas" por el método de sprites: buscar_bg.png
/// 780×1688 reproduce el gradiente exacto que antes dibujaba el
/// código (0xFF16203A → 0xFF0B0B14 → 0xFF120A24, stops 0/0,55/1),
/// generado con PIL; la pantalla ya no usa LinearGradient.
const _buscarBg = 'assets/images/buscar_bg.png';

/// Sprite de tarjeta por tier, variante ALTA (780×680) generada con
/// PIL a partir del sprite 780×320: se conservan intactas las
/// franjas superior e inferior (40 px cada una, con borde y brillo
/// por tier) y se rellena el centro con el color plano del sprite,
/// que es uniforme; así la tarjeta variable (~310–340 px de alto)
/// no deforma las esquinas a elipse. El sprite original 780×320
/// NO se usa aquí: a 350 px de ancho daría solo ~144 px de alto y
/// estirarlo a ~330 px deformaría el aspecto 2,44 → 1,06.
///
/// En el carrusel horizontal (26-oct) la tarjeta ancha (~731 px a
/// 844 de viewport) es mucho más ancha que alta, así que el sprite
/// se dibuja con BoxFit.cover y NO con fill: fill lo aplastaría
/// ~70% en vertical. Cover no deforma (preserva el aspecto y
/// recorta el centro plano, que es uniforme); la identidad por
/// tier en tarjeta ancha la sostienen el borde por código en color
/// de acento, la sombra de acento, la placa de icono y el nombre.
/// En tarjeta angosta apilada, cover muestra además los brillos
/// superior e inferior del sprite.
String _tierSprite(int stake) => switch (stake) {
      100 => 'assets/images/card_barrio_tall.png',
      250 => 'assets/images/card_salon_tall.png',
      500 => 'assets/images/card_casino_tall.png',
      1000 => 'assets/images/card_vip_tall.png',
      2500 => 'assets/images/card_highroller_tall.png',
      _ => 'assets/images/card_casino_tall.png',
    };

/// Pantalla "Buscar salas" (menú, NO mesa).
///
/// Paleta CASINO por corrección del usuario 25-oct 19:32 (manda sobre
/// cualquier identidad marrón anterior PARA EL MENÚ): fondo casi
/// negro / azul noche profundo, dorado mate #C9A24B como acento,
/// tarjetas con brillo y relieve, color vivo por tier sobre fondo
/// oscuro. NUNCA una superficie marrón cuero dominante como base.
/// La MESA de juego no se toca por esta orden (su madera sí es
/// madera) y esta pantalla no usa menuDecoration ni ningún fondo
/// de mesa: su fondo es buscar_bg.png. (menuDecoration ya no es
/// pub: desde el reemplazo de café 25-oct es el mismo gradiente
/// casino que buscar_bg, dibujado por código.)
///
/// Composición (solo composición, nunca contenido copiado, de las
/// 5 referencias del 25-oct): una tarjeta por tier con nombre del
/// tier, apuesta por jugador, pozo por fórmula y botón grande
/// "JUGAR AHORA". Desde el pase a TODO HORIZONTAL (26-oct) la
/// lista vertical queda REEMPLAZADA por un carrusel horizontal:
/// las 5 tarjetas en fila desplazable con snap a la tarjeta al
/// soltar, asomo (peek) de la siguiente y puntos de posición.
/// A 390 px de ancho un carrusel recortaría la fórmula del pozo y
/// los dos botones; en horizontal la tarjeta es casi a ancho
/// completo y su interior se dispone en fila (datos a la izquierda,
/// botones a la derecha), así que todo cabe completo. En vertical
/// (portrait) NO se construye un layout vertical propio: esa
/// pantalla la cubre el aviso de girar del frente D; la tarjeta
/// solo se adapta por ancho (angosta → apilada) para no romperse
/// si llegara a mostrarse.
///
/// Flujos REALES (no hay navegador público de salas: la sentencia
/// del rediseño lo pone fuera de alcance, C3, y docs/01 decisión 33
/// deja la lista de salas para Fase C sin inventar datos; no se
/// inventa un directorio de salas con jugadores falsos):
/// - "JUGAR AHORA" -> _playLocal(stake) -> GameScreen: partida
///   local contra la máquina con ese stake (3 bots, dificultad
///   fácil, preset actual). Antes de entrar se valida el saldo
///   real de Wallet.instance. El stake viajado es el de LA
///   tarjeta pulsada: cada _TierCard cierra sobre su propio campo
///   `stake` (construida con Wallet.stakes[i] de su página), nunca
///   sobre un índice compartido ni siempre el primero.
/// - "CREAR SALA EN LÍNEA" -> _createOnline(stake) -> LobbyScreen:
///   crear sala en línea con ese stake (el flujo de crear ya existe
///   y no pide más datos; el lobby muestra "Apuesta: X por jugador",
///   lobby_screen.dart:374).
/// - "UNIRSE CON CÓDIGO" -> _joinOnlineWith(código) -> LobbyScreen:
///   unirse con el código de un amigo (flujo real existente). El
///   código se escribe UNA vez en el campo del pie fijo y sirve
///   tanto al botón del pie como al botón UNIRSE de cada tarjeta.
/// - Unirse a una sala pública ajena NO existe: no hay botón para
///   eso, solo el estado vacío honesto "Sin salas públicas: crea
///   una o únete con código" en la fila de puntos, sin salas falsas.
/// Saldos rotulados por modalidad, nunca mezclados: el saldo que se
/// muestra es el LOCAL (Wallet.instance.balance); en línea la
/// apuesta se cobra al partir, con la billetera en línea (patrón
/// de FriendsSetupScreen), y así se rotula bajo el botón en línea.
class BuscarSalasScreen extends StatefulWidget {
  final String initialPreset;
  final void Function({
    required int bots,
    required String difficulty,
    required int stake,
    required String tableTheme,
    required String preset,
  }) onPlayLocal;
  final void Function({
    required int stake,
    required String tableTheme,
    required String preset,
  }) onCreateOnline;
  final void Function(String code) onJoinOnline;

  const BuscarSalasScreen({
    super.key,
    required this.initialPreset,
    required this.onPlayLocal,
    required this.onCreateOnline,
    required this.onJoinOnline,
  });

  @override
  State<BuscarSalasScreen> createState() => _BuscarSalasScreenState();
}

class _BuscarSalasScreenState extends State<BuscarSalasScreen> {
  /// 0,88 de fracción de viewport: a 844 px la tarjeta mide ~743 px
  /// y el asomo es ~50 px por lado; la fracción es constante para
  /// no recrear el controlador al cambiar el ancho (a anchos
  /// mayores la tarjeta se centra con un tope de 1100 px).
  late final PageController _pageController =
      PageController(viewportFraction: 0.88);
  int _activeIndex = 0;
  final _code = TextEditingController();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _pageController.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// Ir a una tarjeta desde los puntos: animado con easing cuando
  /// las animaciones están permitidas, salto instantáneo cuando
  /// están OFF o hay reduce-motion (nunca salto con animaciones
  /// activadas).
  void _goToPage(int index) {
    if (CasinoAnims.enabledIn(context)) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  /// Unirse con el código del campo único del pie. Sin código
  /// válido (menos de 4 caracteres) no navega: avisa con el mismo
  /// texto que el home, enfoca el campo y no pierde lo escrito.
  void _submitJoin() {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escribe el código de la sala (ej: K7QF)')),
      );
      _codeFocus.requestFocus();
      return;
    }
    Navigator.of(context).pop();
    widget.onJoinOnline(code);
  }

  @override
  Widget build(BuildContext context) {
    final balance = Wallet.instance.balance;
    final anim = CasinoAnims.enabledIn(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_buscarBg, fit: BoxFit.cover),
          ),
          // Ambiente SOLO en fondo libre: detrás del contenido
          // (nunca sobre tarjetas, botones ni textos), tras
          // enabledIn (apagado o reduce-motion = sin ambiente).
          // 2 bucles infinitos, el máximo del presupuesto:
          // LampGlow ciclo 6 s, opacidad 0,10–0,13; motas AN2
          // ciclo 16 s atenuadas con Opacity 0,65 para que su
          // pico efectivo (0,22 × 0,65 ≈ 0,14) quede ≤ 0,15.
          // El SweepGlow de JUGAR AHORA lo pone otro agente en
          // sprite_button.dart: aquí el botón queda como está.
          if (anim) ...[
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LampGlow(),
            ),
            const Positioned.fill(
              child: Opacity(
                opacity: 0.65,
                child: GoldParticles(),
              ),
            ),
          ],
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Franja propia (no SheetStrip: ese usa cuero marrón).
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border(
                      bottom: BorderSide(
                          color: CachoColors.gold.withValues(alpha: 0.55)),
                    ),
                  ),
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
                            'BUSCAR SALAS',
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
                      BalanceChip(balance: balance),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
                  child: Text(
                    'Elige tu mesa por apuesta. El pozo se fija al partir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                // Carrusel horizontal: reemplaza la lista vertical
                // (no convive con ella). Snap nativo de PageView:
                // el desplazamiento anima con easing y al soltar
                // cae en la tarjeta; con animaciones OFF el
                // PageView sigue funcionando sin animación.
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: Wallet.stakes.length,
                    onPageChanged: (i) =>
                        setState(() => _activeIndex = i),
                    itemBuilder: (context, i) {
                      return StaggerIn(
                        index: i,
                        child: _CarouselEmphasis(
                          controller: _pageController,
                          index: i,
                          fallbackPage: _activeIndex,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Tope de 1100 px en escritorio:
                                // la tarjeta no se estira sin fin.
                                final width = constraints.maxWidth > 1100
                                    ? 1100.0
                                    : constraints.maxWidth;
                                return Center(
                                  child: SizedBox(
                                    width: width,
                                    child: _TierCard(
                                      stake: Wallet.stakes[i],
                                      balance: balance,
                                      preset: widget.initialPreset,
                                      onPlayLocal: widget.onPlayLocal,
                                      onCreateOnline: widget.onCreateOnline,
                                      onJoinRequest: _submitJoin,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Fila de posición real (puntos = 5 tiers, desde
                // Wallet.stakes, no un número fijo) + estado vacío
                // honesto. Los puntos son táctiles: saltan a su
                // tarjeta con la animación del carrusel.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < Wallet.stakes.length; i++)
                        GestureDetector(
                          onTap: () => _goToPage(i),
                          child: SizedBox(
                            width: 28,
                            height: 24,
                            child: Center(
                              child: AnimatedContainer(
                                duration: anim
                                    ? const Duration(milliseconds: 250)
                                    : Duration.zero,
                                width: i == _activeIndex ? 26 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: i == _activeIndex
                                      ? CachoColors.gold
                                      : Colors.white30,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Sin salas públicas: crea una o únete con código.',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pie fijo con el campo de código único: no se
                // desplaza con el carrusel, así que UNIRSE está
                // disponible desde cualquier tarjeta.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _code,
                            focusNode: _codeFocus,
                            textCapitalization:
                                TextCapitalization.characters,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: 'Código de sala',
                              hintText: 'Ej: K7QF',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        width: 210,
                        // UNIRSE por sprite secundario (siempre
                        // habilitado: la validación del código
                        // sigue siendo el aviso al pulsar, sin
                        // perder lo escrito).
                        child: SpriteButton(
                          label: 'UNIRSE CON CÓDIGO',
                          icon: Icons.groups,
                          fontSize: 16,
                          fontFamily: CachoFonts.display,
                          asset: 'assets/images/btn_secundario.png',
                          disabledAsset:
                              'assets/images/btn_secundario_off.png',
                          foreground: CachoColors.ivory,
                          onPressed: _submitJoin,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Énfasis animado de la tarjeta activa del carrusel: SOLO
/// Opacity + Transform.scale (nunca deforma sprites), detrás del
/// gating de animaciones. La tarjeta centrada queda a escala 1,00
/// y opacidad 1,00; las vecinas bajan a 0,96 / 0,82 según su
/// distancia a la página actual. Con animaciones OFF o
/// reduce-motion devuelve la tarjeta tal cual.
class _CarouselEmphasis extends StatefulWidget {
  final PageController controller;
  final int index;
  final int fallbackPage;
  final Widget child;

  const _CarouselEmphasis({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
  });

  @override
  State<_CarouselEmphasis> createState() => _CarouselEmphasisState();
}

class _CarouselEmphasisState extends State<_CarouselEmphasis> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!CasinoAnims.enabledIn(context)) return widget.child;
    final page = widget.controller.hasClients &&
            widget.controller.page != null
        ? widget.controller.page!
        : widget.fallbackPage.toDouble();
    final distance = (page - widget.index).abs();
    final scale = (1.0 - 0.04 * distance).clamp(0.94, 1.0);
    final opacity = (1.0 - 0.18 * distance).clamp(0.82, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(scale: scale, child: widget.child),
    );
  }
}

/// Color vivo por tier sobre fondo oscuro (tarea: verde La Taberna,
/// azul El Boliche, negro El Casino, púrpura La Mansión, bronce
/// El Club VIP; nombres nuevos docs/19 C7, colores intactos).
/// El Casino es negro: se representa con tarjeta oscura + filete
/// dorado y acento gris plata legible, no con una mancha negra
/// invisible sobre fondo negro.
/// Calibración por medición PIL del agente de color (25-oct): en
/// las referencias domina lo oscuro (38,7–80,0%) y el neón cian es
/// prácticamente cero (máx. 1,6%); por eso NO hay cian/magenta
/// neón como identidad: el Salón usa azul profundo saturado (no
/// cian eléctrico) y cada acento vive solo puntual (icono, borde,
/// línea de pozo), nunca como fondo. El Boliche usa ese azul
/// profundo. El dorado mate #C9A24B sigue
/// mandando por orden del usuario 19:32.
/// Movimiento (70% animación web, orden 21:20): ambiente SOLO en
/// fondo libre — LampGlow (ciclo 6 s, opacidad 0,10–0,13) + motas
/// AN2 (ciclo 16 s, pico efectivo ≈0,14), nunca sobre tarjetas,
/// botones ni textos — más SweepGlow mate solo en JUGAR AHORA
/// (ciclo 3 s, pico 0,12) y sonido turnPop al toque. Además del
/// lenguaje que Cacho YA tiene: entrada escalonada de las
/// tarjetas con StaggerIn existente (60 ms por índice, 250 ms,
/// ease-out implícito, una sola vez al entrar), transición de
/// pantalla con CachoPageRoute existente (250 ms fundido + leve
/// deslizamiento, ya usada al entrar desde el home), y
/// micro-feedback de pulsación del BronzeButton existente
/// (escala 0,97 sin desplazar layout, acción al toque sin retraso).
/// Todo detrás de animationsEnabled + reduce-motion del sistema
/// (CasinoAnims.enabledIn): apagado = estado final estático.
/// Sin PulseBorder aquí: no hay tarjeta "seleccionada" (las 5 son
/// iguales y la acción vive en el botón de cada una; pulsar todas
/// violaría "solo en la seleccionada, nada más"). StaggerIn se usa
/// SOLO como entrada de lista (ángulo 2: es el que menos sensación
/// casino da y no se vende como tal); la sensación casino de esta
/// pantalla ahora es ambiente + sweep en el primario, además del
/// brillo estático + relieve.
/// NO se copian aquí los gestos fuertes de Cacho, deliberadamente:
/// vaso/dados, CoinRain y DigitRoller viven en mesa/victoria y
/// ShuffleChips + DigitRoller se VEN al llegar al lobby (son visuales,
/// sin sonido: lobby_screen.dart no llama a AudioService)
/// (lobby_screen.dart:263,413), que es el destino de "CREAR SALA
/// EN LÍNEA"; repetirlos en el selector retrasaría la acción o
/// falsearía un estado (un rodillo implicaría un pozo real ya
/// fijado, y aquí el pozo aún es fórmula). _ChipDrop (0,4 s al
/// seleccionar tier) es privado del selector de tiers y aquí no
/// hay paso de selección: tocar JUGAR AHORA navega de inmediato.
/// El hueco de gating ya está cerrado (21:20): CoinRain y SpinningCoin
/// consultan animationsEnabled + reduce-motion; nada de eso se usa aquí. Todo lo de esta pantalla pasa por
/// CasinoAnims.enabledIn (animationsEnabled + reduce-motion del
/// sistema). Sin EqualizerBars como ambiente, sin shimmer, sin
/// barridos ni pulsos nuevos, y NADA en partida: AN15 no existe
/// en código y está rechazado, no se resucita en ninguna forma.
({Color accent, IconData icon}) _tierStyle(int stake) => switch (stake) {
      100 => (accent: const Color(0xFF34C759), icon: Icons.home_outlined),
      250 => (accent: const Color(0xFF3A6BD8), icon: Icons.weekend_outlined),
      500 => (accent: const Color(0xFFC0C8D4), icon: Icons.casino_outlined),
      1000 => (accent: const Color(0xFF9B5CFF), icon: Icons.star_outlined),
      2500 => (accent: const Color(0xFFCD7F32), icon: Icons.diamond_outlined),
      _ => (accent: CachoColors.gold, icon: Icons.casino_outlined),
    };

class _TierCard extends StatelessWidget {
  final int stake;
  final int balance;
  final String preset;
  final void Function({
    required int bots,
    required String difficulty,
    required int stake,
    required String tableTheme,
    required String preset,
  }) onPlayLocal;
  final void Function({
    required int stake,
    required String tableTheme,
    required String preset,
  }) onCreateOnline;

  /// Unirse con el código del campo único del pie (flujo real
  /// existente, compartido con el botón del pie).
  final VoidCallback onJoinRequest;

  const _TierCard({
    required this.stake,
    required this.balance,
    required this.preset,
    required this.onPlayLocal,
    required this.onCreateOnline,
    required this.onJoinRequest,
  });

  @override
  Widget build(BuildContext context) {
    final style = _tierStyle(stake);
    final name = stakeTierName(stake);
    // Partida local por defecto de esta pantalla: 3 bots + yo = 4
    // jugadores. La fórmula se muestra con ese número y se aclara
    // que el pozo final se fija al partir según los jugadores.
    const players = 4;
    final affords = balance >= stake;
    final missing = affords ? 0 : stake - balance;
    // Tarjeta por sprite (método de sprites): la imagen alta del
    // tier va abajo y TODO el contenido se dibuja por código
    // encima (textos, cifras, fórmula de pozo, placa de icono y
    // botones); nada de texto va horneado en el PNG. El sprite se
    // dibuja con cover (sin deformar: ver el comentario de
    // _tierSprite) y el marco por tier lo pone el borde por código.
    // Las sombras antiguas se conservan por código bajo el sprite.
    // El interior va en scroll vertical solo como red de seguridad:
    // en el caso común cabe completo sin desplazar nada (ver
    // audit/todo_horizontal_buscar.md para las medidas).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: style.accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: style.accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _tierSprite(stake),
                fit: BoxFit.cover,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Tarjeta ancha (horizontal): datos a la izquierda
                // y botones a la derecha, para que todo quepa en
                // la altura corta de 390 px. Tarjeta angosta:
                // interior apilado original.
                final wide = constraints.maxWidth >= 560;
                final content = wide
                    ? _wideContent(
                        context, style, name, players, affords, missing)
                    : _stackedContent(
                        context, style, name, players, affords, missing);
                return SingleChildScrollView(
                  child: Padding(
                    padding: wide
                        ? const EdgeInsets.fromLTRB(16, 12, 16, 12)
                        : const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: content,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fila de nombre + icono (compartida por ambos interiores).
  Widget _nameRow(
      ({Color accent, IconData icon}) style, String name, double iconSize) {
    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: style.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: style.accent.withValues(alpha: 0.7)),
          ),
          child: Icon(style.icon, color: style.accent, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          // Sin "...": el nombre se encoge con diseño si
          // no cabe ("HIGH ROLLER" es el más largo).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              name.toUpperCase(),
              style: const TextStyle(
                fontFamily: CachoFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoLines(
      ({Color accent, IconData icon}) style,
      int players,
      bool affords,
      int missing,
      {bool includeRescue = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Apuesta por jugador: ${coinsText(stake)}',
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Pozo con $players jugadores: ${coinsText(stake * players)}',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: style.accent),
        ),
        const SizedBox(height: 2),
        const Text(
          'Pozo = apuesta × jugadores al partir',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          affords
              ? 'Tu saldo local: ${coinsText(balance)}'
              : 'No te alcanza el saldo: te faltan '
                  '${coinsText(missing)} monedas · '
                  'Tu saldo local: ${coinsText(balance)}',
          style: TextStyle(
            fontSize: 14,
            color: affords ? Colors.white70 : const Color(0xFFFF8A80),
            fontWeight: affords ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
        if (!affords && includeRescue) ...[
          const SizedBox(height: 2),
          const Text(
            'Si tu saldo no alcanza ni la mínima, usa el rescate '
            'del inicio.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ],
    );
  }

  /// Botón JUGAR AHORA por sprite: dorado mate si el saldo
  /// alcanza, variante apagada si no (el estado deshabilitado
  /// ya existía: saldo < apuesta). El `stake` viajado es el de
  /// ESTA tarjeta (campo propio, no índice compartido).
  Widget _playButton(BuildContext context, double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: SpriteButton(
        label: 'JUGAR AHORA',
        sweep: true,
        icon: Icons.play_arrow,
        fontSize: 16,
        fontFamily: CachoFonts.display,
        asset: 'assets/images/btn_jugar_ahora.png',
        disabledAsset: 'assets/images/btn_jugar_ahora_off.png',
        // Texto oscuro sobre el dorado mate del sprite:
        // casi negro casino, no marrón madera. El sprite
        // en sí no se toca (su dorado es el acento #C9A24B).
        foreground: CachoColors.menuMid,
        disabledForeground: Colors.white70,
        onPressed: balance >= stake
            ? () async {
                // Mismo aviso de giro que la hoja local.
                if (!await RotateNotice.confirmIfPortrait(context)) {
                  return;
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
                onPlayLocal(
                  bots: 3,
                  difficulty: 'facil',
                  stake: stake,
                  tableTheme: defaultTableTheme,
                  preset: preset,
                );
              }
            : null,
      ),
    );
  }

  /// Botón CREAR SALA EN LÍNEA por sprite secundario (oscuro con
  /// borde dorado). NO se bloquea por el saldo LOCAL: crear no
  /// cobra nada; la apuesta en línea se cobra al partir con la
  /// billetera EN LÍNEA y el servidor bloquea el inicio con
  /// `saldo_insuficiente` si esa billetera no alcanza (patrón del
  /// lobby). Bloquearlo por el saldo local mezclaría dos
  /// billeteras distintas (auditoría F).
  Widget _createButton(BuildContext context, double height, double fontSize) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: SpriteButton(
        label: 'CREAR SALA EN LÍNEA',
        fontSize: fontSize,
        asset: 'assets/images/btn_secundario.png',
        disabledAsset: 'assets/images/btn_secundario_off.png',
        foreground: CachoColors.ivory,
        onPressed: () {
          Navigator.of(context).pop();
          onCreateOnline(
            stake: stake,
            tableTheme: defaultTableTheme,
            preset: preset,
          );
        },
      ),
    );
  }

  /// Botón UNIRSE CON CÓDIGO por sprite secundario: usa el código
  /// del campo único del pie (el llamador valida y avisa).
  Widget _joinButton(double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: SpriteButton(
        label: 'UNIRSE CON CÓDIGO',
        icon: Icons.groups,
        fontSize: 16,
        fontFamily: CachoFonts.display,
        asset: 'assets/images/btn_secundario.png',
        disabledAsset: 'assets/images/btn_secundario_off.png',
        foreground: CachoColors.ivory,
        onPressed: onJoinRequest,
      ),
    );
  }

  /// Interior ancho: datos a la izquierda, botones a la derecha.
  Widget _wideContent(
    BuildContext context,
    ({Color accent, IconData icon}) style,
    String name,
    int players,
    bool affords,
    int missing,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _nameRow(style, name, 40),
              const SizedBox(height: 6),
              _infoLines(style, players, affords, missing),
              // Saldo en línea rotulado por modalidad: la apuesta en
              // línea se cobra al partir, no al pulsar la tarjeta, y
              // con la billetera en línea (no con el saldo local).
              const SizedBox(height: 6),
              const Text(
                'En línea se cobra al partir, con tu billetera en línea.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _playButton(context, 44),
              const SizedBox(height: 8),
              _createButton(context, 44, 14),
              const SizedBox(height: 8),
              _joinButton(44),
            ],
          ),
        ),
      ],
    );
  }

  /// Interior angosto: apilado original (nombre, datos, botones).
  Widget _stackedContent(
    BuildContext context,
    ({Color accent, IconData icon}) style,
    String name,
    int players,
    bool affords,
    int missing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _nameRow(style, name, 44),
        const SizedBox(height: 10),
        _infoLines(style, players, affords, missing),
        const SizedBox(height: 12),
        _playButton(context, 48),
        const SizedBox(height: 10),
        _createButton(context, 48, 14),
        // Saldo en línea rotulado por modalidad: la apuesta en
        // línea se cobra al partir, no al pulsar la tarjeta, y
        // con la billetera en línea (no con el saldo local).
        const SizedBox(height: 6),
        const Text(
          'En línea se cobra al partir, con tu billetera en línea.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        _joinButton(48),
      ],
    );
  }
}
