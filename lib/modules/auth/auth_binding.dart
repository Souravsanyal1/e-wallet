import 'package:get/get.dart';
import '../../core/services/ui_service.dart';
import '../../core/services/wallet_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        Get.find<AuthRepository>(),
        Get.find<WalletService>(),
        Get.find<UiService>(),
      ),
    );
  }
}
