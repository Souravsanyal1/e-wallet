import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/result.dart';
import '../models/profile_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  ProfileModel? _cachedProfile;

  FirebaseAuthRepository() {
    _initListener();
  }

  void _initListener() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _cachedProfile = ProfileModel.fromJson({
            'id': user.uid,
            ...?doc.data(),
          });
        }
      } else {
        _cachedProfile = null;
      }
    });
  }

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  @override
  ProfileModel? get currentProfile => _cachedProfile;

  @override
  Future<Result<({String message, String nonce})>> requestNonce({
    required String address,
    required String chainNamespace,
    required int chainId,
  }) async {
    try {
      final callable = _functions.httpsCallable('authNonce');
      final res = await callable.call<Map<String, dynamic>>({
        'address': address,
        'chainId': chainId,
      });

      final data = res.data;
      return Ok((
        message: data['message'] as String,
        nonce: data['nonce'] as String,
      ));
    } catch (e) {
      return Err(AppException.network('Could not start wallet sign-in. Please try again.'));
    }
  }

  @override
  Future<Result<ProfileModel>> verifySignature({
    required String message,
    required String signature,
  }) async {
    try {
      final callable = _functions.httpsCallable('authVerify');
      final res = await callable.call<Map<String, dynamic>>({
        'message': message,
        'signature': signature,
      });

      final token = res.data['token'] as String;
      final cred = await _auth.signInWithCustomToken(token);
      final uid = cred.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      final profile = ProfileModel(
        id: uid,
        handle: doc.data()?['handle'] ?? 'user_${uid.substring(0, 6)}',
        displayName: doc.data()?['displayName'] ?? 'User',
        createdAt: DateTime.now(),
      );

      _cachedProfile = profile;
      return Ok(profile);
    } catch (e) {
      return Err(AppException.network('Wallet verification failed. Please try again.'));
    }
  }

  @override
  Future<Result<ProfileModel>> updateProfile({
    String? handle,
    String? displayName,
    String? bio,
  }) async {
    final uid = _auth.currentUser?.uid ?? _cachedProfile?.id;
    if (uid == null) return Err(AppException.unauthorized());

    try {
      final updateData = <String, dynamic>{};
      if (handle != null) updateData['handle'] = handle;
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;

      await _firestore.collection('users').doc(uid).set(updateData, SetOptions(merge: true));

      _cachedProfile = _cachedProfile?.copyWith(
        handle: handle,
        displayName: displayName,
        bio: bio,
      );

      return Ok(_cachedProfile!);
    } catch (e) {
      return Err(AppException.network('Failed to update profile: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _cachedProfile = null;
    return const Ok(null);
  }
}
