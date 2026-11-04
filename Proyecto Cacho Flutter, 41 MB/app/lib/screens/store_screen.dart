import 'package:flutter/material.dart';
import '../models/avatar_frame_model.dart';
import '../models/cup_skin_model.dart';
import '../models/shop_item_model.dart';
import '../services/auth_service.dart';
import '../services/shop_controller.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/game/player_avatar_widget.dart';

/// Pantalla completa de Tienda y Cosméticos del juego Cacho / Dudo
class StoreScreen extends StatefulWidget {
  final int initialTabIndex;

  const StoreScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ShopController _shopController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _shopController = ShopController();
    _shopController.addListener(_onShopUpdate);
    UserService.instance.addListener(_onUserUpdate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shopController.removeListener(_onShopUpdate);
    UserService.instance.removeListener(_onUserUpdate);
    super.dispose();
  }

  void _onShopUpdate() {
    if (!mounted) return;
    setState(() {});
    if (_shopController.lastTransactionMessage != null) {
      final msg = _shopController.lastTransactionMessage!;
      final isOk = _shopController.isSuccess;
      _shopController.lastTransactionMessage = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isOk ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isOk ? const Color(0xFF34C759) : Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1712),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isOk ? const Color(0xFF34C759) : const Color(0xFFD4AF37),
              width: 1.2,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onUserUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.instance.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A130E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: CachoColors.gold, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'TIENDA & COSMÉTICOS',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.2,
            color: CachoColors.gold,
          ),
        ),
        centerTitle: false,
        actions: [
          _buildCurrencyPill(
            icon: Icons.monetization_on,
            iconColor: const Color(0xFFFFD700),
            value: _formatNumber(user.coins),
            tooltip: 'Fichas (Entrada a mesas)',
          ),
          const SizedBox(width: 8),
          _buildCurrencyPill(
            icon: Icons.payments,
            iconColor: const Color(0xFF34C759),
            value: '\$${user.cash}',
            tooltip: 'Billetes (Para comprar cosméticos)',
          ),
          const SizedBox(width: 14),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CachoColors.gold,
          indicatorWeight: 3,
          labelColor: CachoColors.gold,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet, size: 18),
              text: 'FICHAS Y BILLETES',
            ),
            Tab(
              icon: Icon(Icons.palette, size: 18),
              text: 'COSMÉTICOS',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPlayerProfileBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCurrencyTab(),
                _buildCosmeticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF261D16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.45), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: iconColor == const Color(0xFF34C759) ? Colors.greenAccent : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerProfileBar() {
    final user = UserService.instance.user;
    final frame = UserService.instance.equippedFrame;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1510),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CachoColors.gold.withValues(alpha: 0.25), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con marco y StarLevelBadge
          PlayerAvatarWidget(
            name: user.name,
            size: 52,
            level: user.level,
            frame: frame,
          ),
          const SizedBox(width: 14),
          // Info de nivel y XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isGuest ? Colors.grey.shade800 : const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.isGuest ? 'INVITADO' : 'GOOGLE',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: user.isGuest ? Colors.white70 : const Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Barra de XP
                Row(
                  children: [
                    Text(
                      'Nivel ${user.level}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: CachoColors.gold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${user.xp} / ${user.xpForNextLevel} XP',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: user.levelProgress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(CachoColors.gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botón de autenticación / perfil
          IconButton(
            tooltip: user.isGuest ? 'Vincular Google' : 'Perfil y Cuenta',
            icon: Icon(
              user.isGuest ? Icons.account_circle_outlined : Icons.verified_user,
              color: user.isGuest ? Colors.white60 : const Color(0xFF34C759),
              size: 26,
            ),
            onPressed: () => _showAuthDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        // SECCIÓN 1: FICHAS PARA ENTRADA A MESAS
        _buildSectionHeader(
          title: 'FICHAS (COINS)',
          subtitle: 'Utilizadas exclusivamente para el pago de la tarifa de entrada (Buy-in) en las mesas.',
          icon: Icons.monetization_on,
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(height: 10),
        ...ShopItemModel.coinPackages.map((pack) => _buildCoinPackCard(pack)),
        const SizedBox(height: 22),

        // SECCIÓN 2: BILLETES PARA COSMÉTICOS
        _buildSectionHeader(
          title: 'BILLETES (CASH PREMIUM)',
          subtitle: 'Moneda para adquirir cosméticos, skins exclusivas y marcos de avatar en la tienda.',
          icon: Icons.payments,
          color: const Color(0xFF34C759),
        ),
        const SizedBox(height: 10),
        ...ShopItemModel.cashPackages.map((pack) => _buildCashPackCard(pack)),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildCoinPackCard(ShopItemModel pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1712),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pack.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(pack.icon, color: pack.accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pack.title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (pack.bannerTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: pack.accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: pack.accentColor, width: 0.8),
                        ),
                        child: Text(
                          pack.bannerTag!,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            color: pack.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  pack.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E2218),
              foregroundColor: Colors.white,
              side: const BorderSide(color: CachoColors.gold, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _shopController.buyCoinPackage(pack),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments, size: 14, color: Color(0xFF34C759)),
                const SizedBox(width: 4),
                Text(
                  '\$${pack.priceCash}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPackCard(ShopItemModel pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF142417),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pack.accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(pack.icon, color: pack.accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pack.title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (pack.bannerTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: pack.accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: pack.accentColor, width: 0.8),
                        ),
                        child: Text(
                          pack.bannerTag!,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            color: pack.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  pack.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22543D),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF34C759), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _shopController.buyCashPackage(pack),
            child: Text(
              'OBTENER',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmeticsTab() {
    final user = UserService.instance.user;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        // SECCIÓN 1: SKINS DE VASOS
        _buildSectionHeader(
          title: 'SKINS DE VASOS (CACHOS)',
          subtitle: 'Personaliza tu vaso de cuero en la mesa. Visible para todos los jugadores.',
          icon: Icons.wine_bar,
          color: CachoColors.gold,
        ),
        const SizedBox(height: 12),
        ...CupSkinModel.allSkins.map((skin) {
          final isEquipped = user.equippedCupSkinId == skin.id;
          final isOwned = user.ownedCupSkinIds.contains(skin.id);
          return _buildCupSkinCard(skin, isEquipped: isEquipped, isOwned: isOwned);
        }),
        const SizedBox(height: 24),

        // SECCIÓN 2: MARCOS DE AVATAR
        _buildSectionHeader(
          title: 'MARCOS DE AVATAR',
          subtitle: 'Efectos visuales animados y auras relucientes alrededor de tu foto de perfil.',
          icon: Icons.camera_front,
          color: const Color(0xFF00F0FF),
        ),
        const SizedBox(height: 12),
        ...AvatarFrameModel.allFrames.map((frame) {
          final isEquipped = user.equippedFrameId == frame.id;
          final isOwned = user.ownedFrameIds.contains(frame.id);
          return _buildAvatarFrameCard(frame, isEquipped: isEquipped, isOwned: isOwned);
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCupSkinCard(CupSkinModel skin, {required bool isEquipped, required bool isOwned}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1712),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEquipped
              ? CachoColors.gold
              : skin.glowColor.withValues(alpha: 0.3),
          width: isEquipped ? 2.0 : 1.0,
        ),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: CachoColors.gold.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Vista previa del vaso
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: skin.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: skin.glowColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: skin.glowColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Image.asset(
              skin.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.wine_bar,
                color: CachoColors.gold,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info del vaso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      skin.name,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (skin.isAnimated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: skin.glowColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: skin.glowColor, width: 0.8),
                        ),
                        child: const Text(
                          'ANIMADO',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  skin.description,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botón de acción (Equipado / Equipar / Comprar)
          _buildActionButton(
            isEquipped: isEquipped,
            isOwned: isOwned,
            priceCash: skin.priceCash,
            onPressed: () => _shopController.buyOrEquipCupSkin(skin),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFrameCard(AvatarFrameModel frame, {required bool isEquipped, required bool isOwned}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161C24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEquipped
              ? const Color(0xFF00F0FF)
              : frame.primaryColor.withValues(alpha: 0.3),
          width: isEquipped ? 2.0 : 1.0,
        ),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Vista previa del avatar con el marco
          PlayerAvatarWidget(
            name: UserService.instance.user.name,
            size: 46,
            level: UserService.instance.user.level,
            frame: frame,
          ),
          const SizedBox(width: 14),
          // Info del marco
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      frame.name,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (frame.isAnimated) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: frame.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: frame.primaryColor, width: 0.8),
                        ),
                        child: const Text(
                          'AURA',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  frame.description,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botón de acción
          _buildActionButton(
            isEquipped: isEquipped,
            isOwned: isOwned,
            priceCash: frame.priceCash,
            onPressed: () => _shopController.buyOrEquipAvatarFrame(frame),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required bool isEquipped,
    required bool isOwned,
    required int priceCash,
    required VoidCallback onPressed,
  }) {
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF34C759), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Color(0xFF34C759), size: 14),
            SizedBox(width: 4),
            Text(
              'EQUIPADO',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: Color(0xFF34C759),
              ),
            ),
          ],
        ),
      );
    }

    if (isOwned) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        onPressed: onPressed,
        child: const Text(
          'EQUIPAR',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A2F),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF34C759), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments, size: 13, color: Color(0xFF34C759)),
          const SizedBox(width: 4),
          Text(
            '\$$priceCash',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    final user = UserService.instance.user;
    final nameCtrl = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A130E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: CachoColors.gold, width: 1.2),
              ),
              title: Row(
                children: [
                  const Icon(Icons.person, color: CachoColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    user.isGuest ? 'Cuenta de Invitado' : 'Perfil de Jugador',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: CachoColors.gold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Apodo',
                        labelStyle: TextStyle(color: Colors.white60),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: CachoColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ID: ${user.id}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      'Partidas ganadas: ${user.gamesWon} / ${user.gamesPlayed}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    if (user.isGuest) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                        label: const Text(
                          'Iniciar sesión con Google',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(dialogCtx).pop();
                          await AuthService.instance.signInWithGoogle(
                            customName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                          );
                        },
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Cerrar sesión (Volver a Invitado)'),
                        onPressed: () async {
                          Navigator.of(dialogCtx).pop();
                          await AuthService.instance.signOut();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CachoColors.gold,
                    foregroundColor: const Color(0xFF1A130E),
                  ),
                  child: const Text('Guardar Nombre', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    final trimmed = nameCtrl.text.trim();
                    if (trimmed.isNotEmpty) {
                      UserService.instance.updateProfile(user.copyWith(name: trimmed));
                    }
                    Navigator.of(dialogCtx).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toString();
  }
}

