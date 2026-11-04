import 'package:flutter/material.dart';
import '../models/shop_item_model.dart';
import '../models/cup_skin_model.dart';
import '../models/avatar_frame_model.dart';
import 'user_service.dart';

/// Controlador para la gestión y compras en la Tienda (StoreScreen)
class ShopController extends ChangeNotifier {
  final UserService userService;

  ShopController({UserService? service}) : userService = service ?? UserService.instance;

  String? lastTransactionMessage;
  bool isSuccess = false;

  /// Compra de paquetes de monedas virtuales con Cash
  bool buyCoinPackage(ShopItemModel pack) {
    if (pack.priceCash > 0) {
      if (userService.user.cash < pack.priceCash) {
        lastTransactionMessage = 'No tienes suficientes Billetes (Cash).';
        isSuccess = false;
        notifyListeners();
        return false;
      }
      userService.deductCash(pack.priceCash);
    }

    userService.addCoins(pack.amount);
    lastTransactionMessage = '¡Compraste ${pack.title}! (+${pack.amount} Fichas)';
    isSuccess = true;
    notifyListeners();
    return true;
  }

  /// Compra virtual de Billetes (Cash) simulada
  void buyCashPackage(ShopItemModel pack) {
    userService.addCash(pack.amount);
    lastTransactionMessage = '¡Recibiste ${pack.title}! (+${pack.amount} Billetes)';
    isSuccess = true;
    notifyListeners();
  }

  /// Adquisición de skin de vaso
  bool buyOrEquipCupSkin(CupSkinModel skin) {
    final alreadyOwned = userService.user.ownedCupSkinIds.contains(skin.id);

    if (alreadyOwned) {
      userService.equipCupSkin(skin.id);
      lastTransactionMessage = 'Equipaste ${skin.name}.';
      isSuccess = true;
      notifyListeners();
      return true;
    }

    if (userService.user.cash < skin.priceCash) {
      lastTransactionMessage = 'Billetes insuficientes para ${skin.name}.';
      isSuccess = false;
      notifyListeners();
      return false;
    }

    final success = userService.purchaseCupSkin(skin);
    if (success) {
      lastTransactionMessage = '¡Compraste y equipaste ${skin.name}!';
      isSuccess = true;
    }
    notifyListeners();
    return success;
  }

  /// Adquisición de marco de avatar
  bool buyOrEquipAvatarFrame(AvatarFrameModel frame) {
    final alreadyOwned = userService.user.ownedFrameIds.contains(frame.id);

    if (alreadyOwned) {
      userService.equipAvatarFrame(frame.id);
      lastTransactionMessage = 'Equipaste ${frame.name}.';
      isSuccess = true;
      notifyListeners();
      return true;
    }

    if (userService.user.cash < frame.priceCash) {
      lastTransactionMessage = 'Billetes insuficientes para ${frame.name}.';
      isSuccess = false;
      notifyListeners();
      return false;
    }

    final success = userService.purchaseAvatarFrame(frame);
    if (success) {
      lastTransactionMessage = '¡Compraste y equipaste ${frame.name}!';
      isSuccess = true;
    }
    notifyListeners();
    return success;
  }
}

