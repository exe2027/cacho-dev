import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda la última sala en línea de este dispositivo.
///
/// Pedido del usuario (22-oct): si está en el navegador y sin
/// querer se sale — toca "atrás", recarga, cierra la pestaña — al
/// volver la app tiene que ofrecerle "Entrar a la sala activa" en
/// vez de obligarlo a buscar el código y partir de cero.
///
/// Se guarda SOLO el código: la identidad del jugador la pone su
/// token de billetera (persistente), con el que el servidor le
/// devuelve su asiento a mitad de partida. Se borra cuando la
/// partida termina, cuando la sala deja de existir o cuando el
/// jugador descarta el aviso; NUNCA al salir de la partida, porque
/// salir sin querer es justo el caso que esto rescata.
class ActiveRoomStore {
  static const _key = 'active_room_code';

  static Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
