import 'package:get/get.dart';

class WalletAccount {
  final String address;
  final String chainNamespace;
  final int chainId;
  final String walletName;

  const WalletAccount({
    required this.address,
    this.chainNamespace = 'eip155',
    required this.chainId,
    required this.walletName,
  });

  String get shortAddress => address.length < 10
      ? address
      : '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}

/// Wallet boundary. A platform-specific WalletConnect/EIP-1193 adapter must be
/// registered before use; this class deliberately never fabricates accounts
/// or signatures when no provider is available.
class WalletService extends GetxService {
  final Rxn<WalletAccount> currentAccount = Rxn<WalletAccount>();
  final RxBool isConnecting = false.obs;

  bool get isConnected => currentAccount.value != null;

  Future<WalletAccount> connectWallet(String providerName) async {
    throw UnsupportedError(
      'No wallet provider is configured. Connect a supported EVM wallet and try again.',
    );
  }

  Future<String> personalSign(String message) async {
    throw UnsupportedError(
      'No wallet provider is configured to sign this request.',
    );
  }

  Future<String> sendTransaction({
    required String to,
    required String value,
    String? data,
    required int chainId,
  }) async {
    throw UnsupportedError(
      'No wallet provider is configured to submit transactions.',
    );
  }

  void disconnect() => currentAccount.value = null;
}
