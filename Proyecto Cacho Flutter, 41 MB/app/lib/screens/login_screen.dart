import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Pantalla de inicio de sesión estilo casino de alta gama.
/// Dados y fichas flotantes, animaciones escalonadas, logo en paño verde.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controladores de animación ───────────────────────────────────────
  late final AnimationController _entryCtrl;   // Entrada general (1.8 s)
  late final AnimationController _floatCtrl;   // Partículas flotantes (loop)
  late final AnimationController _shimmerCtrl; // Shimmer botón Google (loop)

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _dividerFade;
  late final Animation<Offset> _btn1Slide;
  late final Animation<Offset> _btn2Slide;
  late final Animation<double> _btnFade;
  late final Animation<double> _shimmer;

  final TextEditingController _nicknameCtrl = TextEditingController();
  final List<_FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Logo: baja desde arriba (0–600 ms)
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // Subtítulo: aparece después del logo (400–800 ms)
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );

    // Divisor (600–1000 ms)
    _dividerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );

    // Botones suben desde abajo con stagger (900–1800 ms)
    _btn1Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    ));
    _btn2Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
    ));
    _btnFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    // Shimmer sweep (loop)
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    // Generar partículas flotantes
    final rng = math.Random(42);
    for (int i = 0; i < 12; i++) {
      _particles.add(_FloatingParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 10 + rng.nextDouble() * 18,
        speed: 0.3 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble() * math.pi * 2,
        isDice: i < 6, // 6 dados + 6 fichas
        face: (rng.nextInt(6) + 1),
        rotation: rng.nextDouble() * math.pi * 2,
      ));
    }

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _onGoogleSignIn() async {
    final ok = await AuthService.instance.signInWithGoogle();
    if (ok && mounted) _goToHome();
  }

  Future<void> _onGuestSignIn() async {
    final nickname = _nicknameCtrl.text.trim().isEmpty
        ? null
        : _nicknameCtrl.text.trim();
    await AuthService.instance.signInAsGuest(nickname: nickname);
    if (mounted) _goToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo de paño casino ──────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [
                    const Color(0xFF0D2518),
                    const Color(0xFF06100A),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ── Partículas flotantes (dados + fichas) ────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _floatCtrl.value,
                ),
              ),
            ),
          ),

          // ── Contenido central ─────────────────────────────────────────
          SafeArea(
            child: ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) {
                final isLoading = AuthService.instance.isLoading;
                final error = AuthService.instance.authError;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Logo / Emblem ──────────────────────────
                          FadeTransition(
                            opacity: _logoFade,
                            child: SlideTransition(
                              position: _logoSlide,
                              child: Image.asset(
                                'assets/images/logo_emblem.png',
                                height: 110,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Título CACHO ───────────────────────────
                          FadeTransition(
                            opacity: _logoFade,
                            child: SlideTransition(
                              position: _logoSlide,
                              child: Text(
                                'CACHO',
                                style: titleStyle.copyWith(
                                  fontSize: 52,
                                  letterSpacing: 10,
                                  shadows: [
                                    Shadow(
                                      color: CachoColors.gold
                                          .withValues(alpha: 0.5),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Subtítulo ──────────────────────────────
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: Text(
                              'EL DUDO',
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 13,
                                color: CachoColors.gold
                                    .withValues(alpha: 0.65),
                                letterSpacing: 6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Botón Google ───────────────────────────
                          FadeTransition(
                            opacity: _btnFade,
                            child: SlideTransition(
                              position: _btn1Slide,
                              child: _ShimmerButton(
                                shimmer: _shimmer,
                                onPressed:
                                    isLoading ? null : _onGoogleSignIn,
                                isLoading: isLoading,
                                icon: const _GoogleIcon(),
                                label: 'Continuar con Google',
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Divisor ornamental ─────────────────────
                          FadeTransition(
                            opacity: _dividerFade,
                            child: const _GoldDivider(),
                          ),

                          const SizedBox(height: 20),

                          // ── Campo apodo ────────────────────────────
                          FadeTransition(
                            opacity: _btnFade,
                            child: SlideTransition(
                              position: _btn2Slide,
                              child: _CasinoTextField(
                                controller: _nicknameCtrl,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Botón Invitado ─────────────────────────
                          FadeTransition(
                            opacity: _btnFade,
                            child: SlideTransition(
                              position: _btn2Slide,
                              child: _GuestButton(
                                onPressed:
                                    isLoading ? null : _onGuestSignIn,
                              ),
                            ),
                          ),

                          // ── Error ──────────────────────────────────
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBox(message: error),
                          ],

                          const SizedBox(height: 28),

                          // ── Aviso persistencia ─────────────────────
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: Text(
                              'Con Google, tu progreso se guarda en la nube.\nComo invitado, se guarda solo en este dispositivo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CachoColors.ivory
                                    .withValues(alpha: 0.32),
                                fontSize: 11.5,
                                height: 1.6,
                              ),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Partículas flotantes: dados y fichas de casino
// ═══════════════════════════════════════════════════════════════

class _FloatingParticle {
  final double x, y, size, speed, phase, rotation;
  final bool isDice;
  final int face;
  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.isDice,
    required this.face,
    required this.rotation,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;

  const _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final dy = math.sin(t * math.pi * 2) * 18;
      final dx = math.cos(t * math.pi * 1.3 + p.phase) * 10;
      final ox = p.x * size.width + dx;
      final oy = p.y * size.height + dy;

      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(p.rotation + progress * 0.4 * p.speed);

      final paint = Paint()
        ..color = const Color(0xFFC9A24B).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      if (p.isDice) {
        _drawDice(canvas, p.size, paint);
      } else {
        _drawChip(canvas, p.size, paint);
      }

      canvas.restore();
    }
  }

  void _drawDice(Canvas canvas, double s, Paint paint) {
    final half = s / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s, height: s),
      Radius.circular(s * 0.18),
    );
    canvas.drawRRect(rrect, paint);
    // Borde
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFFC9A24B).withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
    // Puntos centrales simplificados
    final dotPaint = Paint()
      ..color = const Color(0xFFC9A24B).withValues(alpha: 0.12);
    canvas.drawCircle(Offset.zero, half * 0.18, dotPaint);
  }

  void _drawChip(Canvas canvas, double s, Paint paint) {
    final r = s / 2;
    canvas.drawCircle(Offset.zero, r, paint);
    // Borde dentado simplificado
    canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..color = const Color(0xFFC9A24B).withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    canvas.drawCircle(
        Offset.zero,
        r * 0.65,
        Paint()
          ..color = const Color(0xFFC9A24B).withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// Botón Google con shimmer
// ═══════════════════════════════════════════════════════════════

class _ShimmerButton extends StatelessWidget {
  final Animation<double> shimmer;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget icon;
  final String label;

  const _ShimmerButton({
    required this.shimmer,
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Stack(
        children: [
          // Botón base
          Positioned.fill(
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black87),
                    )
                  : icon,
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: CachoColors.gold,
                foregroundColor: Colors.black87,
                elevation: 8,
                shadowColor: CachoColors.gold.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Shimmer overlay
          if (onPressed != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AnimatedBuilder(
                  animation: shimmer,
                  builder: (_, __) => CustomPaint(
                    painter: _ShimmerPainter(shimmer.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double x;
  _ShimmerPainter(this.x);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = x * w;
    final gradient = LinearGradient(
      begin: Alignment(cx / w * 2 - 1.5, 0),
      end: Alignment(cx / w * 2 + 0.5, 0),
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.22),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.x != x;
}

// ═══════════════════════════════════════════════════════════════
// Separador dorado ornamental
// ═══════════════════════════════════════════════════════════════

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                CachoColors.gold.withValues(alpha: 0.5),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.diamond_outlined,
                  color: CachoColors.gold.withValues(alpha: 0.6), size: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'o juega como invitado',
                  style: TextStyle(
                    color: CachoColors.ivory.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Icon(Icons.diamond_outlined,
                  color: CachoColors.gold.withValues(alpha: 0.6), size: 10),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                CachoColors.gold.withValues(alpha: 0.5),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Campo de texto estilo casino
// ═══════════════════════════════════════════════════════════════

class _CasinoTextField extends StatelessWidget {
  final TextEditingController controller;
  const _CasinoTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: CachoColors.ivory),
      decoration: InputDecoration(
        hintText: 'Tu apodo (opcional)',
        hintStyle: TextStyle(color: CachoColors.ivory.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CachoColors.gold.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CachoColors.gold.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CachoColors.gold.withValues(alpha: 0.7)),
        ),
        prefixIcon: Icon(Icons.person_outline,
            color: CachoColors.gold.withValues(alpha: 0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLength: 20,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Botón Invitado
// ═══════════════════════════════════════════════════════════════

class _GuestButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GuestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.person_outline,
            size: 18, color: CachoColors.ivory.withValues(alpha: 0.85)),
        label: const Text('Jugar como Invitado'),
        style: OutlinedButton.styleFrom(
          foregroundColor: CachoColors.ivory,
          side: BorderSide(color: CachoColors.gold.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Caja de error
// ═══════════════════════════════════════════════════════════════

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Ícono de Google (CustomPainter)
// ═══════════════════════════════════════════════════════════════

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(center, r, Paint()..color = Colors.white);

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final rect = Rect.fromCircle(center: center, radius: r * 0.7);
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final startAngle = (i * 90 - 45) * math.pi / 180;
      final sweep = 90 * math.pi / 180;
      path
        ..reset()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, startAngle, sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
    canvas.drawCircle(center, r * 0.42, Paint()..color = Colors.white);
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx, center.dy - r * 0.13, r * 0.68, r * 0.26),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
