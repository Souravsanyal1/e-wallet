import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/result.dart';
import '../models/profile_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const _uuid = Uuid();
  ProfileModel? _currentProfile;

  MockAuthRepository({ProfileModel? initialProfile}) {
    _currentProfile = initialProfile;
  }

  @override
  bool get isAuthenticated => _currentProfile != null;

  @override
  ProfileModel? get currentProfile => _currentProfile;

  @override
  Future<Result<({String message, String nonce})>> requestNonce({
    required String address,
    required String chainNamespace,
    required int chainId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final nonce = _uuid.v4().replaceAll('-', '');
    final now = DateTime.now().toUtc();
    final expiry = now.add(const Duration(minutes: 5));

    final message =
        '''${AppConfig.authDomain} wants you to sign in with your Ethereum account:
$address

Sign in to EliteChat. This does not send a transaction or cost any gas.

URI: https://${AppConfig.authDomain}
Version: 1
Chain ID: $chainId
Nonce: $nonce
Issued At: ${now.toIso8601String()}
Expiration Time: ${expiry.toIso8601String()}''';

    return Ok((message: message, nonce: nonce));
  }

  @override
  Future<Result<ProfileModel>> verifySignature({
    required String message,
    required String signature,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (signature.isEmpty) {
      return Err(AppException.validation('Invalid or empty signature'));
    }

    // Return logged-in user profile
    _currentProfile = ProfileModel(
      id: 'user_me',
      handle: 'vitalik_fan',
      displayName: 'Crypto Native',
      bio: 'Decentralized communications advocate',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      isOnline: true,
    );

    return Ok(_currentProfile!);
  }

  @override
  Future<Result<ProfileModel>> updateProfile({
    String? handle,
    String? displayName,
    String? bio,
  }) async {
    if (_currentProfile == null) {
      return Err(AppException.unauthorized());
    }

    _currentProfile = _currentProfile!.copyWith(
      handle: handle,
      displayName: displayName,
      bio: bio,
    );
    return Ok(_currentProfile!);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentProfile = null;
    return const Ok(null);
  }
}
