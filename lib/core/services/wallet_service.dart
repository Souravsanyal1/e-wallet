import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:get/get.dart';

class WalletAccount {
  final String address;
  final String chainNamespace;
  final int chainId;
  final String walletName;
  final double ethBalance;
  final double usdcBalance;

  const WalletAccount({
    required this.address,
    this.chainNamespace = 'eip155',
    this.chainId = 1,
    required this.walletName,
    this.ethBalance = 2.45,
    this.usdcBalance = 1250.0,
  });

  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class WalletService extends GetxService {
  final Rxn<WalletAccount> currentAccount = Rxn<WalletAccount>();
  final RxBool isConnecting = false.obs;

  bool get isConnected => currentAccount.value != null;

  /// Connects to selected wallet provider
  Future<WalletAccount> connectWallet(String providerName) async {
    isConnecting.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      // Deterministic demo addresses based on provider
      final String address = switch (providerName.toLowerCase()) {
        'metamask' => '0x71C8412092d8866F407b621946414380b49f4b9B',
        'rainbow' => '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
        'coinbase' => '0x4981447B950eBCA026b47D688784E11d08eB17a7',
        _ => '0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5',
      };

      final account = WalletAccount(
        address: address,
        walletName: providerName,
        ethBalance: 3.82,
        usdcBalance: 2400.00,
      );

      currentAccount.value = account;
      return account;
    } finally {
      isConnecting.value = false;
    }
  }

  /// Generates standard EIP-4361 SIWE message
  String generateSiweMessage({
    required String address,
    required String domain,
    required String nonce,
    required String uri,
    required int chainId,
  }) {
    final now = DateTime.now().toUtc();
    final expiry = now.add(const Duration(minutes: 5));
    final isoNow = now.toIso8601String();
    final isoExpiry = expiry.toIso8601String();

    return '''$domain wants you to sign in with your Ethereum account:
$address

Sign in to EliteChat. This does not send a transaction or cost any gas.

URI: $uri
Version: 1
Chain ID: $chainId
Nonce: $nonce
Issued At: $isoNow
Expiration Time: $isoExpiry''';
  }

  /// Simulates personal_sign on the wallet
  Future<String> personalSign(String message) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final bytes = utf8.encode(message);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}3c5b8e9f2a1b4c7d0e8f';
  }

  /// Disconnects active wallet
  void disconnect() {
    currentAccount.value = null;
  }
}
