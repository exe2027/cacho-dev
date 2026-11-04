import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

/// Servicio de Autenticación real con Firebase Auth: Google Sign-In y modo Invitado (anónimo).
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._() {
    // Escuchar cambios de estado de autenticación de Firebase
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  bool _isLoading = false;
  String? _authError;

  bool get isLoading => _isLoading;
  String? get authError => _authError;
  bool get isAuthenticated => !UserService.instance.user.isGuest;

  /// Escucha cambios en el estado de Firebase Auth y sincroniza UserService
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) return;
    // Sincronizar perfil con Firestore cuando el usuario ya está autenticado
    await UserService.instance.syncFromFirestore(firebaseUser);
    notifyListeners();
  }

  /// Iniciar sesión con Google (OAuth real vía Firebase)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      UserCredential credential;

      if (kIsWeb) {
        // En web se usa popup (no redirect para simplificar)
        final provider = GoogleAuthProvider();
        credential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // En móvil se usa el flujo nativo de Google Sign-In
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          // El usuario canceló el flujo
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        credential = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Usuario nulo tras Google Auth');

      // Migrar datos locales (invitado) a la cuenta de Google en Firestore
      await UserService.instance.migrateGuestToGoogle(firebaseUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _authError = _translateFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _authError = 'No se pudo iniciar sesión con Google: $e';
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesión como Invitado (anónimo en Firebase)
  Future<void> signInAsGuest({String? nickname}) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Usuario anónimo nulo');

      // Crear perfil de invitado con el UID de Firebase
      await UserService.instance.createGuestProfile(
        uid: firebaseUser.uid,
        nickname: nickname,
      );
    } on FirebaseAuthException catch (e) {
      _authError = _translateFirebaseError(e.code);
    } catch (e) {
      _authError = 'No se pudo iniciar como invitado: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cerrar sesión de Firebase y volver a perfil de invitado
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      await UserService.instance.clearLocalProfile();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Convierte códigos de error de Firebase a mensajes en español
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Inicio de sesión cancelado.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese email.';
      default:
        return 'Error al iniciar sesión ($code).';
    }
  }
}
