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

class MockChannelRepository implements ChannelRepository {
  final List<ChannelModel> _channels = [
    const ChannelModel(
      id: 'ch_announcements',
      slug: 'announcements',
      title: 'EliteChat Official',
      description: 'Protocol updates, security disclosures, and client release notes.',
      subscriberCount: 14200,
      isPublic: true,
      isSubscribed: true,
    ),
    const ChannelModel(
      id: 'ch_defi',
      slug: 'defi-pulse',
      title: 'DeFi Pulse & Yields',
      description: 'Real-time onchain yield opportunities and protocol metrics.',
      subscriberCount: 8940,
      isPublic: true,
      isSubscribed: false,
    ),
    const ChannelModel(
      id: 'ch_alpha',
      slug: 'alpha-insiders',
      title: 'Whale Alpha Desk [Token Gated]',
      description: 'Exclusive research desk for Pro and Whale subscribers.',
      subscriberCount: 650,
      isPublic: false,
      requiredPlanSlug: 'pro',
      isSubscribed: false,
    ),
  ];

  final List<PlanModel> _plans = const [
    PlanModel(
      id: 'plan_pro',
      slug: 'pro',
      title: 'Pro Trader',
      description: 'Access token-gated alpha channels, uncompressed media uploads, and verified badge.',
      priceUsdc: 50.0,
      durationDays: 30,
      perks: [
        'Access to Whale Alpha Desk',
        'Gold Verified Profile Ring',
        'Large media attachment uploads (up to 50MB)',
        'Priority DM delivery & push routing',
      ],
    ),
    PlanModel(
      id: 'plan_whale',
      slug: 'whale',
      title: 'Alpha Insider',
      description: 'Direct channel broadcast rights, priority DM delivery, and on-chain analytics bot.',
      priceUsdc: 150.0,
      durationDays: 30,
      perks: [
        'All Pro Trader benefits',
        'Channel broadcast privileges',
        'Dedicated RPC gateway connection',
        'VIP access to closed governance chats',
      ],
    ),
  ];

  @override
  Future<Result<List<ChannelModel>>> fetchChannels() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Ok(List.unmodifiable(_channels));
  }

  @override
  Future<Result<void>> toggleSubscription(String channelId) async {
    final idx = _channels.indexWhere((c) => c.id == channelId);
    if (idx != -1) {
      final current = _channels[idx];
      _channels[idx] = current.copyWith(
        isSubscribed: !current.isSubscribed,
        subscriberCount: current.subscriberCount + (current.isSubscribed ? -1 : 1),
      );
    }
    return const Ok(null);
  }

  @override
  Future<Result<List<PlanModel>>> fetchPlans() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Ok(List.unmodifiable(_plans));
  }

  @override
  Future<Result<bool>> verifyPaymentAndSubscribe({
    required String planId,
    required String txHash,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Ok(true);
  }
}
