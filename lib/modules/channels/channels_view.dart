import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/ui_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/channel_model.dart';
import '../../data/repositories/channel_repository.dart';
import '../../routes/app_routes.dart';

class ChannelsController extends GetxController {
  final ChannelRepository _channelRepository;
  final UiService _uiService;

  ChannelsController(this._channelRepository, this._uiService);

  final RxList<ChannelModel> channels = <ChannelModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadChannels();
  }

  Future<void> loadChannels() async {
    isLoading.value = true;
    final res = await _channelRepository.fetchChannels();
    res.when(
      ok: (list) {
        channels.assignAll(list);
        isLoading.value = false;
      },
      err: (e) {
        isLoading.value = false;
        _uiService.showError(e.message);
      },
    );
  }

  Future<void> toggleSubscription(ChannelModel ch) async {
    if (ch.isTokenGated && !ch.isSubscribed) {
      _showTokenGatingDialog(ch);
      return;
    }

    await _channelRepository.toggleSubscription(ch.id);
    final idx = channels.indexWhere((c) => c.id == ch.id);
    if (idx != -1) {
      final current = channels[idx];
      channels[idx] = current.copyWith(
        isSubscribed: !current.isSubscribed,
        subscriberCount: current.subscriberCount + (current.isSubscribed ? -1 : 1),
      );
    }
  }

  void _showTokenGatingDialog(ChannelModel ch) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: AppColors.darkPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text('token_gated'.tr)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ch.title} is restricted to subscribers of the ${ch.requiredPlanSlug?.toUpperCase()} tier.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Token-gating verifies your cryptographic balance or active on-chain subscription NFT before granting read/write permissions.',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navigate to wallet plans
              Get.toNamed(AppRoutes.wallet);
            },
            child: Text('unlock_access'.tr),
          ),
        ],
      ),
    );
  }
}

class ChannelsView extends GetView<ChannelsController> {
  const ChannelsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('channels'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoader(label: 'Loading channels...'));
        }

        if (controller.channels.isEmpty) {
          return EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No channels found',
            message: 'Broadcast channels will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.space16),
          itemCount: controller.channels.length,
          itemBuilder: (context, index) {
            final ch = controller.channels[index];

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.space16),
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppDimensions.borderMedium,
                border: Border.all(
                  color: ch.isTokenGated
                      ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.5) : AppColors.lightPrimary.withValues(alpha: 0.5))
                      : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
                  width: ch.isTokenGated ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ch.isTokenGated ? Icons.stars_rounded : Icons.campaign_rounded,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ch.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${ch.subscriberCount} subscribers',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ch.isTokenGated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkPrimary.withValues(alpha: 0.15),
                            borderRadius: AppDimensions.borderPill,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 12, color: AppColors.darkPrimary),
                              SizedBox(width: 4),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (ch.description != null) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      ch.description!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: ch.isSubscribed
                            ? 'Subscribed ✓'
                            : (ch.isTokenGated ? 'Unlock Channel ⚡' : 'Subscribe'),
                        variant: ch.isSubscribed
                            ? AppButtonVariant.secondary
                            : AppButtonVariant.primary,
                        onPressed: () => controller.toggleSubscription(ch),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
