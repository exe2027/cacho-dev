import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cacho_app/state/wallet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('billetera nueva: 5000 de bienvenida y token persistente', () async {
    final w = Wallet.instance;
    await w.load();
    expect(w.balance, Wallet.welcomeCoins);
    expect(w.token, isNotEmpty);
    final token1 = w.token;
    await w.load();
    expect(w.token, token1, reason: 'el token no cambia entre cargas');
  });

  test('cobrar y acreditar mueven el saldo; cobrar de más no', () async {
    final w = Wallet.instance;
    await w.load();
    expect(w.charge(500), isTrue);
    expect(w.balance, 4500);
    expect(w.charge(99999), isFalse);
    expect(w.balance, 4500);
    w.credit(2000);
    expect(w.balance, 6500);
  });

  test('rescate: solo con saldo bajo la mínima y una vez al día', () async {
    final w = Wallet.instance;
    await w.load();
    expect(w.canRescue, isFalse, reason: 'con 5000 no hay rescate');
    expect(w.charge(4950), isTrue);
    expect(w.balance, 50);
    expect(w.canRescue, isTrue);
    w.rescue();
    expect(w.balance, 50 + Wallet.rescueCoins);
    expect(w.canRescue, isFalse, reason: 'ya se usó el rescate de hoy');
  });

  test('formato de monedas chileno', () {
    expect(coinsText(500), '500');
    expect(coinsText(2000), '2.000');
    expect(coinsText(1234567), '1.234.567');
  });
}
