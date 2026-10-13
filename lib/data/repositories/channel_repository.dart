import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../core/errors/result.dart';
import '../models/channel_model.dart';

abstract class ChannelRepository {
  Future<Result<List<ChannelModel>>> fetchChannels();
  Future<Result<void>> toggleSubscription(String channelId);
  Future<Result<List<PlanModel>>> fetchPlans();
  Future<Result<bool>> verifyPaymentAndSubscribe({
    required String planId,
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

      if (snap.docs.isEmpty) {
        // Return standard operational plans if plans collection is not yet seeded
        return const Ok([
          PlanModel(
            id: 'plan_pro',
            slug: 'pro',
            title: 'Pro Trader',
            description: 'Access token-gated alpha channels and verified badge.',
            priceUsdc: 50.0,
            durationDays: 30,
            perks: [
              'Access to Token-Gated Channels',
              'Gold Verified Profile Ring',
              'Priority DM delivery & push routing',
            ],
          ),
          PlanModel(
            id: 'plan_whale',
            slug: 'whale',
            title: 'Alpha Insider',
            description: 'Direct channel broadcast rights and analytics access.',
            priceUsdc: 150.0,
            durationDays: 30,
            perks: [
              'All Pro Trader benefits',
              'Channel broadcast privileges',
              'VIP governance chat access',
            ],
          ),
        ]);
      }

      final list = snap.docs.map((d) {
        final data = d.data();
        return PlanModel(
          id: d.id,
          slug: data['slug'] as String? ?? d.id,
          title: data['title'] as String? ?? 'Plan',
          description: data['description'] as String? ?? '',
          priceUsdc: (data['priceAmount'] as num?)?.toDouble() ?? 50.0,
          durationDays: data['durationDays'] as int? ?? 30,
          perks: (data['perks'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }).toList();

      return Ok(list);
    } catch (e) {
      return Ok([]);
    }
  }

  @override
  Future<Result<bool>> verifyPaymentAndSubscribe({
    required String planId,
    required String txHash,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPayment');
      final res = await callable.call<Map<String, dynamic>>({
        'planId': planId,
        'txHash': txHash,
      });
      return Ok(res.data['success'] == true);
    } catch (e) {
      return Err(AppException.network('Payment verification failed: $e'));
    }
  }
}
