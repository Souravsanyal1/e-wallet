import '../../core/errors/result.dart';
import '../models/profile_model.dart';

abstract class AuthRepository {
  /// Whether user has active session
  bool get isAuthenticated;

  /// Current logged-in user profile
  ProfileModel? get currentProfile;

  /// Obtains SIWE nonce and server-formatted message
  Future<Result<({String message, String nonce})>> requestNonce({
    required String address,
    required String chainNamespace,
    required int chainId,
  });

  /// Verifies personal_sign signature and creates session
  Future<Result<ProfileModel>> verifySignature({
    required String message,
    required String signature,
  });

  /// Updates current user profile details
  Future<Result<ProfileModel>> updateProfile({
    String? handle,
    String? displayName,
    String? bio,
  });

  /// Signs out current session
  Future<Result<void>> signOut();
}
