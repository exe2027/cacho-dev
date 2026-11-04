import 'dart:math';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

/// Servicio de Autenticación con soporte para Google Sign-In simulado/nativo y Modo Invitado (Guest).
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  bool _isLoading = false;
  String? _authError;

  bool get isLoading => _isLoading;
  String? get authError => _authError;
  bool get isAuthenticated => !UserService.instance.user.isGuest;

  /// Iniciar sesión con Google (simulación instantánea y extensible con credenciales de OAuth)
  Future<bool> signInWithGoogle({String? customName, String? customEmail}) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      // Simulación de respuesta de Google OAuth sin dependencias externas pesadas
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final currentUser = UserService.instance.user;
      final email = customEmail ?? 'jugador_${currentUser.id.substring(0, min(6, currentUser.id.length))}@gmail.com';
      final name = customName ?? (currentUser.name.startsWith('Jugador') ? 'Google Player' : currentUser.name);

      final loggedInUser = currentUser.copyWith(
        id: 'google_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        avatarUrl: 'https://lh3.googleusercontent.com/a/default-user',
        isGuest: false,
      );

      UserService.instance.updateProfile(loggedInUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _authError = 'No se pudo iniciar sesión con Google: $e';
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesión como Invitado (Guest anónimo)
  Future<void> signInAsGuest({String? nickname}) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final r = Random().nextInt(9999).toString().padLeft(4, '0');
    final guestId = 'guest_$r';
    final name = nickname ?? 'Jugador $r';

    final guestUser = UserService.instance.user.copyWith(
      id: guestId,
      name: name,
      email: '',
      avatarUrl: '',
      isGuest: true,
    );

    UserService.instance.updateProfile(guestUser);
    _isLoading = false;
    notifyListeners();
  }

  /// Cerrar sesión y volver al perfil de Invitado
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final resetGuest = UserService.instance.user.copyWith(
      isGuest: true,
      email: '',
      avatarUrl: '',
    );

    UserService.instance.updateProfile(resetGuest);
    _isLoading = false;
    notifyListeners();
  }
}

