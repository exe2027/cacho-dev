import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Billetera de monedas FICTICIAS (sin dinero real, sin cuentas).
///
/// - Al crear el perfil se reciben [welcomeCoins] monedas.
/// - Cada partida cuesta una apuesta (a elegir: [stakes]); el pozo es
///   apuesta × jugadores y se lo lleva el ganador.
/// - El saldo local vive en el dispositivo; en línea, el servidor
///   custodia SU saldo asociado a [token] (un identificador anónimo
///   del dispositivo, no una cuenta).
/// - Si el saldo no alcanza ni la apuesta mínima, hay un rescate de
///   [rescueCoins] una vez al día para no quedar bloqueado.
class Wallet extends ChangeNotifier {
  static final Wallet instance = Wallet._();
  Wallet._();

  static const List<int> stakes = [100, 250, 500, 1000, 2500];
  static const int welcomeCoins = 5000;
  static const int rescueCoins = 1000;

  int balance = welcomeCoins;

  /// Identidad anónima y persistente del dispositivo ante el servidor.
  String token = '';

  String _lastRescueDay = '';
  bool loaded = false;

  static String _today() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getInt('coins_balance');
      if (saved == null) {
        balance = welcomeCoins;
        await p.setInt('coins_balance', balance);
      } else {
        balance = saved;
      }
      token = p.getString('wallet_token') ?? '';
      if (token.isEmpty) {
        final r = Random.secure();
        token = List.generate(
            24, (_) => r.nextInt(16).toRadixString(16)).join();
        await p.setString('wallet_token', token);
      }
      _lastRescueDay = p.getString('coins_last_rescue') ?? '';
    } catch (_) {
      // Sin almacenamiento (tests): saldo de bienvenida en memoria.
      if (token.isEmpty) token = 'test-token';
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('coins_balance', balance);
      await p.setString('coins_last_rescue', _lastRescueDay);
    } catch (_) {}
  }

  /// Cobra una apuesta. Devuelve false si no alcanza el saldo.
  bool charge(int amount) {
    if (amount <= 0) return true;
    if (balance < amount) return false;
    balance -= amount;
    _save();
    notifyListeners();
    return true;
  }

  /// Acredita monedas (pozo ganado, devolución o rescate).
  void credit(int amount) {
    if (amount <= 0) return;
    balance += amount;
    _save();
    notifyListeners();
  }

  /// Rescate disponible: saldo bajo la apuesta mínima y no usado hoy.
  bool get canRescue => balance < stakes.first && _lastRescueDay != _today();

  void rescue() {
    if (!canRescue) return;
    _lastRescueDay = _today();
    credit(rescueCoins);
  }

  /// Establece el saldo directamente (usado al sincronizar desde Firestore).
  void setBalance(int amount) {
    if (amount < 0) return;
    balance = amount;
    _save();
    notifyListeners();
  }
}

/// 2000 → "2.000" (formato chileno, sin decimales).
String coinsText(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}
