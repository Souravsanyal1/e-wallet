import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/result.dart';
import '../models/channel_model.dart';

abstract class ChannelRepository {
  Future<Result<List<ChannelModel>>> fetchChannels();
  Future<Result<void>> toggleSubscription(String channelId);
  Future<Result<List<PlanModel>>> fetchPlans();
  Future<Result<DateTime?>> fetchPremiumUntil();
  Future<Result<PremiumQuote>> createPremiumQuote({required String planId});
  Future<Result<PremiumPaymentResult>> verifyPaymentAndSubscribe({
    required String quoteId,
    required String txHash,
  });
}

class FirestoreChannelRepository implements ChannelRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<Result<List<ChannelModel>>> fetchChannels() async {
    try {
      final snap = await _firestore.collection('channels').limit(50).get();
      final list = snap.docs.map((d) {
        final data = d.data();
        return ChannelModel(
          id: d.id,
          slug: data['slug'] as String? ?? d.id,
          title: data['title'] as String? ?? 'Channel',
          description: data['description'] as String?,
          avatarPath: data['avatarPath'] as String?,
          isPublic: data['isPublic'] as bool? ?? true,
          requiredPlanSlug: data['requiredPlanSlug'] as String?,
          subscriberCount: data['subscriberCount'] as int? ?? 0,
          isSubscribed: false,
        );
      }).toList();

      return Ok(list);
    } catch (e) {
      return Ok([]); // Return real empty list on fresh database
    }
  }

  @override
  Future<Result<void>> toggleSubscription(String channelId) async {
    try {
      await _firestore.collection('channels').doc(channelId).update({
        'subscriberCount': FieldValue.increment(1),
      });
      return const Ok(null);
    } catch (e) {
      return const Ok(null);
    }
  }

  @override
  Future<Result<List<PlanModel>>> fetchPlans() async {
    try {
      final snap = await _firestore
          .collection('plans')
          .where('isActive', isEqualTo: true)
          .get();

      final list = snap.docs.map((d) {
        final data = d.data();
        return PlanModel(
          id: d.id,
          slug: data['slug'] as String? ?? d.id,
          title: data['title'] as String? ?? 'Plan',
          description: data['description'] as String? ?? '',
          displayPrice: (data['displayPrice'] as num?)?.toDouble() ?? 0,
          tokenSymbol: data['tokenSymbol'] as String? ?? 'Token',
          tokenAddress: data['token'] as String? ?? '',
          receiverAddress: data['receiver'] as String? ?? '',
          chainId: data['chainId'] as int? ?? 97,
          usdListPriceCents: data['usdListPriceCents'] as int?,
          durationDays: data['durationDays'] as int? ?? 30,
          perks: (data['perks'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }).toList();

      return Ok(list);
    } catch (e) {
      return Err(AppException.network('Could not load subscription plans.'));
    }
  }

  @override
  Future<Result<DateTime?>> fetchPremiumUntil() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const Ok(null);
      final doc = await _firestore.collection('users').doc(uid).get();
      final value = doc.data()?['premiumUntil'];
      if (value is Timestamp) return Ok(value.toDate());
      return const Ok(null);
    } catch (_) {
      return Err(AppException.network('Could not load Premium status.'));
    }
  }

  @override
  Future<Result<PremiumQuote>> createPremiumQuote({required String planId}) async {
    try {
      final callable = _functions.httpsCallable('createPremiumQuote');
      final res = await callable.call<Map<String, dynamic>>({'planId': planId});
      return Ok(PremiumQuote.fromJson(res.data));
    } catch (_) {
      return Err(AppException.network('This E-FORCE plan is not configured yet.'));
    }
  }

  @override
  Future<Result<PremiumPaymentResult>> verifyPaymentAndSubscribe({
    required String quoteId,
    required String txHash,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPayment');
      final res = await callable.call<Map<String, dynamic>>({
        'quoteId': quoteId,
        'txHash': txHash,
      });
      return Ok(PremiumPaymentResult(
        status: res.data['status'] as String? ?? 'pending',
        expiresAt: res.data['expiresAt'] as String?,
      ));
    } catch (_) {
      return Err(AppException.network('Payment could not be verified. Please try again.'));
    }
  }
}
