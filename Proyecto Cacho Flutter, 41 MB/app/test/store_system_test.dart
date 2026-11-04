import 'package:flutter_test/flutter_test.dart';
import 'package:cacho_app/models/user_model.dart';
import 'package:cacho_app/models/cup_skin_model.dart';
import 'package:cacho_app/models/avatar_frame_model.dart';
import 'package:cacho_app/models/shop_item_model.dart';
import 'package:cacho_app/services/user_service.dart';
import 'package:cacho_app/services/auth_service.dart';
import 'package:cacho_app/services/shop_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Data Models', () {
    test('UserModel defaults and serialization', () {
      const user = UserModel(
        id: 'test_123',
        name: 'Carlos',
        coins: 1000,
        cash: 50,
        level: 2,
        xp: 200,
      );

      final jsonStr = user.toJson();
      final decoded = UserModel.fromJson(jsonStr);

      expect(decoded.id, 'test_123');
      expect(decoded.name, 'Carlos');
      expect(decoded.coins, 1000);
      expect(decoded.cash, 50);
      expect(decoded.level, 2);
      expect(decoded.xp, 200);
      expect(decoded.xpForNextLevel, 1000); // 2 * 500
      expect(decoded.levelProgress, 0.2); // 200 / 1000
    });

    test('CupSkinModel presets and getById', () {
      expect(CupSkinModel.allSkins.length, 4);
      expect(CupSkinModel.getById('cup_standard').name, 'Vaso Estándar');
      expect(CupSkinModel.getById('cup_roble').priceCash, 150);
      expect(CupSkinModel.getById('cup_dorado').isAnimated, true);
      expect(CupSkinModel.getById('cup_fuego').priceCash, 500);
      expect(CupSkinModel.getById('unknown').id, CupSkinModel.standard.id);
    });

    test('AvatarFrameModel presets and getById', () {
      expect(AvatarFrameModel.allFrames.length, 4);
      expect(AvatarFrameModel.getById('frame_none').name, 'Sin Marco');
      expect(AvatarFrameModel.getById('frame_oro').effectType, 'gold');
      expect(AvatarFrameModel.getById('frame_neon').effectType, 'neon');
      expect(AvatarFrameModel.getById('frame_fuego').effectType, 'fire');
      expect(AvatarFrameModel.getById('unknown').id, AvatarFrameModel.none.id);
    });

    test('ShopItemModel bundles', () {
      expect(ShopItemModel.coinPackages.isNotEmpty, true);
      expect(ShopItemModel.cashPackages.isNotEmpty, true);
      expect(ShopItemModel.coinPackages.first.amount, 2500);
      expect(ShopItemModel.cashPackages.first.amount, 100);
    });
  });

  group('UserService & XP / Level-Up System', () {
    test('Initial user has starter coins and level 1', () async {
      final s = UserService.instance;
      await s.load();

      expect(s.user.level, 1);
      expect(s.user.xp, 0);
      expect(s.user.coins, greaterThanOrEqualTo(5000));
      expect(s.user.cash, greaterThanOrEqualTo(100));
    });

    test('addMatchResult awards XP and handles level-up rewards', () async {
      final s = UserService.instance;
      await s.load();

      // Partida ganada con stake 500: XP ganado = 250 + (500 ~/ 10) = 300 XP
      final res = s.addMatchResult(won: true, stake: 500);

      expect(res['xpGained'], 300);
      expect(s.user.gamesWon, 1);
      expect(s.user.gamesPlayed, 1);
      expect(s.user.xp, 300);

      // Otra victoria para cruzar el umbral de 500 XP del nivel 1
      final res2 = s.addMatchResult(won: true, stake: 500);

      expect(res2['leveledUp'], true);
      expect(res2['newLevel'], 2);
      expect(res2['rewardCash'], 50);
      expect(res2['rewardCoins'], 1000);
      expect(s.user.level, 2);
      expect(s.user.xp, 100); // 300 + 300 = 600 - 500 = 100
    });
  });

  group('ShopController & Cosmetic Purchases', () {
    test('Buy and equip cup skins with cash', () async {
      final s = UserService.instance;
      await s.load();
      s.updateProfile(s.user.copyWith(cash: 400));

      final shop = ShopController(service: s);
      final roble = CupSkinModel.roble; // Cost 150 Cash

      // Primera vez: comprar y equipar
      final bought = shop.buyOrEquipCupSkin(roble);
      expect(bought, true);
      expect(s.user.ownedCupSkinIds.contains(roble.id), true);
      expect(s.user.equippedCupSkinId, roble.id);
      expect(s.user.cash, 250); // 400 - 150

      // Re-equipar el estándar
      shop.buyOrEquipCupSkin(CupSkinModel.standard);
      expect(s.user.equippedCupSkinId, CupSkinModel.standard.id);

      // Equipar roble sin costo adicional
      shop.buyOrEquipCupSkin(roble);
      expect(s.user.equippedCupSkinId, roble.id);
      expect(s.user.cash, 250); // Mismo saldo
    });

    test('Buy and equip avatar frames', () async {
      final s = UserService.instance;
      await s.load();
      s.updateProfile(s.user.copyWith(cash: 200));

      final shop = ShopController(service: s);
      final oro = AvatarFrameModel.oro; // Cost 120 Cash

      final bought = shop.buyOrEquipAvatarFrame(oro);
      expect(bought, true);
      expect(s.user.ownedFrameIds.contains(oro.id), true);
      expect(s.user.equippedFrameId, oro.id);
      expect(s.user.cash, 80); // 200 - 120
    });

    test('Fails when cash is insufficient', () async {
      final s = UserService.instance;
      await s.load();
      s.updateProfile(s.user.copyWith(cash: 10));

      final shop = ShopController(service: s);
      final fuego = CupSkinModel.fuego; // Cost 500 Cash

      final bought = shop.buyOrEquipCupSkin(fuego);
      expect(bought, false);
      expect(shop.isSuccess, false);
      expect(s.user.cash, 10);
    });
  });

  group('AuthService', () {
    test('Google Sign-In and Sign-Out', () async {
      final auth = AuthService.instance;
      await UserService.instance.load();

      final ok = await auth.signInWithGoogle(customName: 'Juan Pérez');
      expect(ok, true);
      expect(UserService.instance.user.name, 'Juan Pérez');
      expect(UserService.instance.user.isGuest, false);

      await auth.signOut();
      expect(UserService.instance.user.isGuest, true);
    });
  });
}
