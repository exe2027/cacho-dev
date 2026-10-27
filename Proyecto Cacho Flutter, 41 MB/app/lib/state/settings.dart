import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales del jugador (master prompt §1: sin cuentas;
/// preferencias y cosméticos se guardan en el dispositivo).
class Settings extends ChangeNotifier {
  static final Settings instance = Settings._();
  Settings._();

  String nickname = '';
  int leatherIndex = 0;
  bool soundEffects = true;
  bool murmur = true;
  bool music = true;
  bool reducedEffects = false;
  // AN17 (sentencia animaciones): interruptor de animaciones de casino.
  // Apagado, todo se vuelve instantáneo sin quitar funcionalidad; nunca
  // apaga semáforo, barra ni pitidos (información de juego).
  bool animationsEnabled = true;
  bool beginnerHelp = true;
  bool guidedDone = false;
  bool loaded = false;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      nickname = p.getString('nickname') ?? '';
      leatherIndex = p.getInt('leatherIndex') ?? 0;
      soundEffects = p.getBool('soundEffects') ?? true;
      murmur = p.getBool('murmur') ?? true;
      music = p.getBool('music') ?? true;
      reducedEffects = p.getBool('reducedEffects') ?? false;
      animationsEnabled = p.getBool('animationsEnabled') ?? true;
      beginnerHelp = p.getBool('beginnerHelp') ?? true;
      guidedDone = p.getBool('guidedDone') ?? false;
    } catch (_) {
      // Sin almacenamiento (tests): quedan los valores por defecto.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('nickname', nickname);
      await p.setInt('leatherIndex', leatherIndex);
      await p.setBool('soundEffects', soundEffects);
      await p.setBool('murmur', murmur);
      await p.setBool('music', music);
      await p.setBool('reducedEffects', reducedEffects);
      await p.setBool('animationsEnabled', animationsEnabled);
      await p.setBool('beginnerHelp', beginnerHelp);
      await p.setBool('guidedDone', guidedDone);
    } catch (_) {}
  }

  Future<void> markGuidedDone() async {
    if (guidedDone) return;
    guidedDone = true;
    await save();
  }
}
