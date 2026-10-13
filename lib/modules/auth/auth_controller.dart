import 'package:get/get.dart';
import '../../core/services/ui_service.dart';
import '../../core/services/wallet_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final WalletService _walletService;
  final UiService _uiService;

  AuthController(this._authRepository, this._walletService, this._uiService);

  final RxBool isLoading = false.obs;
  final RxString selectedProvider = ''.obs;
  final RxString currentSiweMessage = ''.obs;
  final RxString currentNonce = ''.obs;

  Future<void> connectWithProvider(String providerName) async {
    selectedProvider.value = providerName;
    isLoading.value = true;
    try {
      final account = await _walletService.connectWallet(providerName);

      // Request SIWE nonce
      final nonceRes = await _authRepository.requestNonce(
        address: account.address,
        chainNamespace: account.chainNamespace,
        chainId: account.chainId,
      );

      nonceRes.when(
        ok: (res) {
          currentSiweMessage.value = res.message;
          currentNonce.value = res.nonce;
          Get.toNamed(AppRoutes.walletSignature);
        },
        err: (e) {
          _uiService.showError(e.message);
        },
      );
    } catch (e) {
      _uiService.showError('Failed to connect to $providerName: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmSignature() async {
    if (currentSiweMessage.value.isEmpty) return;

    isLoading.value = true;
    try {
      final signature = await _walletService.personalSign(currentSiweMessage.value);

      final verifyRes = await _authRepository.verifySignature(
        message: currentSiweMessage.value,
        signature: signature,
      );

      verifyRes.when(
        ok: (profile) {
          _uiService.showSuccess('Welcome back, @${profile.handle}!');
          Get.offAllNamed(AppRoutes.home);
        },
        err: (e) {
          _uiService.showError(e.message);
        },
      );
    } catch (e) {
      _uiService.showError('Signature error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void cancelSignature() {
    _walletService.disconnect();
    currentSiweMessage.value = '';
    currentNonce.value = '';
    Get.back();
  }
}
