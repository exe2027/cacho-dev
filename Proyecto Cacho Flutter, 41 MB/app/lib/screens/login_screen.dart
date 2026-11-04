import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Pantalla de inicio de sesión: Google Sign-In o modo Invitado.
/// Se muestra al abrir la app si no hay sesión activa.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _logoAnim;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  final TextEditingController _nicknameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoFade = CurvedAnimation(parent: _logoAnim, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _onGoogleSignIn() async {
    final ok = await AuthService.instance.signInWithGoogle();
    if (ok && mounted) _goToHome();
  }

  Future<void> _onGuestSignIn() async {
    final nickname = _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim();
    await AuthService.instance.signInAsGuest(nickname: nickname);
    if (mounted) _goToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: menuDecoration,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) {
              final isLoading = AuthService.instance.isLoading;
              final error = AuthService.instance.authError;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo animado ──
                        SlideTransition(
                          position: _logoSlide,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'CACHO',
                                  style: titleStyle.copyWith(fontSize: 48, letterSpacing: 8),
                                ),
                                Text(
                                  'EL DUDO CHILENO',
                                  style: TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 13,
                                    color: CachoColors.gold.withValues(alpha: 0.75),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ── Botón Google ──
                        _LoginButton(
                          onPressed: isLoading ? null : _onGoogleSignIn,
                          isLoading: isLoading,
                          icon: _GoogleIcon(),
                          label: 'Continuar con Google',
                          primary: true,
                        ),

                        const SizedBox(height: 20),

                        // ── Divisor ──
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white24, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o juega como invitado',
                                style: TextStyle(color: CachoColors.ivory.withValues(alpha: 0.5), fontSize: 13),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.white24, height: 1)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Campo nickname opcional ──
                        TextField(
                          controller: _nicknameCtrl,
                          style: const TextStyle(color: CachoColors.ivory),
                          decoration: InputDecoration(
                            hintText: 'Tu apodo (opcional)',
                            hintStyle: TextStyle(color: CachoColors.ivory.withValues(alpha: 0.4)),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: CachoColors.gold.withValues(alpha: 0.6)),
                            ),
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.white38),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          maxLength: 20,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        ),

                        const SizedBox(height: 12),

                        // ── Botón invitado ──
                        _LoginButton(
                          onPressed: isLoading ? null : _onGuestSignIn,
                          isLoading: false,
                          icon: const Icon(Icons.person_outline, size: 20, color: CachoColors.ivory),
                          label: 'Jugar como Invitado',
                          primary: false,
                        ),

                        // ── Error ──
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // ── Aviso datos ──
                        Text(
                          'Con Google, tu progreso se guarda en la nube.\nComo invitado, se guarda solo en este dispositivo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CachoColors.ivory.withValues(alpha: 0.38),
                            fontSize: 12,
                            height: 1.5,
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
      ),
    );
  }
}

// ─────────────────────────── Botón de Login ───────────────────────────────

class _LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget icon;
  final String label;
  final bool primary;

  const _LoginButton({
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading && primary
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
              )
            : icon,
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? CachoColors.gold : Colors.white10,
          foregroundColor: primary ? Colors.black87 : CachoColors.ivory,
          elevation: primary ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: primary ? BorderSide.none : const BorderSide(color: Colors.white24),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Ícono de Google ──────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Fondo blanco del círculo
    canvas.drawCircle(center, r, Paint()..color = Colors.white);

    final path = Path();
    final rect = Rect.fromCircle(center: center, radius: r * 0.7);

    // G de Google simplificada con arcos de colores
    final colors = [
      const Color(0xFF4285F4), // azul
      const Color(0xFF34A853), // verde
      const Color(0xFFFBBC05), // amarillo
      const Color(0xFFEA4335), // rojo
    ];

    for (int i = 0; i < 4; i++) {
      final startAngle = (i * 90 - 45) * 3.14159 / 180;
      final sweepAngle = 90 * 3.14159 / 180;
      path.reset();
      path.moveTo(center.dx, center.dy);
      path.arcTo(rect, startAngle, sweepAngle, false);
      path.close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }

    // Círculo blanco central para el hueco
    canvas.drawCircle(center, r * 0.42, Paint()..color = Colors.white);

    // Barra horizontal derecha de la G
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx, center.dy - r * 0.13, r * 0.68, r * 0.26),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

