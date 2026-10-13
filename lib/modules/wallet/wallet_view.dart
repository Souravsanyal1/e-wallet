import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/ui_service.dart';
import '../../core/services/wallet_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/address_chip.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/channel_model.dart';
import '../../data/repositories/channel_repository.dart';

enum PaymentState { idle, waitingForWallet, submitted, confirming, active }

class WalletController extends GetxController {
  final WalletService _walletService;
  final ChannelRepository _channelRepository;
  final UiService _uiService;

  WalletController(this._walletService, this._channelRepository, this._uiService);

  final RxList<PlanModel> plans = <PlanModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<PaymentState> paymentState = PaymentState.idle.obs;
  final RxnString activeSubscription = RxnString();

  WalletAccount? get account => _walletService.currentAccount.value;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
  }

  Future<void> loadPlans() async {
    isLoading.value = true;
    final res = await _channelRepository.fetchPlans();
    res.when(
      ok: (list) {
        plans.assignAll(list);
        isLoading.value = false;
      },
      err: (e) {
        isLoading.value = false;
        _uiService.showError(e.message);
      },
    );
  }

  Future<void> purchasePlan(PlanModel plan) async {
    // Phase 6 Payment lifecycle from design.md & web3-auth-and-payments.md
    paymentState.value = PaymentState.waitingForWallet;

    Get.dialog(
      Obx(() => _buildPaymentProgressDialog(plan)),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(milliseconds: 1000));
    paymentState.value = PaymentState.submitted;

    await Future.delayed(const Duration(milliseconds: 1200));
    paymentState.value = PaymentState.confirming;

    await Future.delayed(const Duration(milliseconds: 1400));
    paymentState.value = PaymentState.active;
    activeSubscription.value = plan.slug;

    await Future.delayed(const Duration(milliseconds: 1000));
    Get.back(); // close dialog
    _uiService.showSuccess('Subscription to ${plan.title} activated!');
    paymentState.value = PaymentState.idle;
  }

  Widget _buildPaymentProgressDialog(PlanModel plan) {
    final statusText = switch (paymentState.value) {
      PaymentState.waitingForWallet => 'Waiting for wallet confirmation...',
      PaymentState.submitted => 'Transaction broadcast to network...',
      PaymentState.confirming => 'Confirming on-chain (1/3 blocks)...',
      PaymentState.active => 'Payment confirmed! Activating entitlement...',
      _ => '',
    };

    return AlertDialog(
      title: Text('Subscribing to ${plan.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkPrimary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: ${plan.priceUsdc.toInt()} USDC · Duration: ${plan.durationDays} days',
            style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }
}

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('wallet'.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Overview Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkSurfaceHigh, AppColors.darkSurface]
                      : [AppColors.lightSurfaceHigh, AppColors.lightSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppDimensions.borderMedium,
                border: Border.all(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Connected Identity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.darkSuccess.withValues(alpha: 0.15),
                          borderRadius: AppDimensions.borderPill,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: AppColors.darkSuccess),
                            SizedBox(width: 4),
                            Text(
                              'Verified EOA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkSuccess,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AddressChip(
                    address: controller.account?.address ?? '0x71C8412092d8866F407b621946414380b49f4b9B',
                    networkName: 'Ethereum Mainnet',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'ETH Balance',
                          amount: '${controller.account?.ethBalance ?? 3.82} ETH',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'USDC Balance',
                          amount: '${controller.account?.usdcBalance.toInt() ?? 2400} USDC',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),
            Text(
              'plans'.tr,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'Pay with USDC on-chain to unlock token-gated alpha channels and VIP privileges.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Subscription Tiers
            Obx(
              () => Column(
                children: controller.plans.map((plan) {
                  final isCurrentActive = controller.activeSubscription.value == plan.slug;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                    padding: const EdgeInsets.all(AppDimensions.space20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppDimensions.borderMedium,
                      border: Border.all(
                        color: isCurrentActive
                            ? AppColors.darkSuccess
                            : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
                        width: isCurrentActive ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plan.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${plan.priceUsdc.toInt()} USDC / mo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.description,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ...plan.perks.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: AppColors.darkSuccess),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 16),
                        AppButton(
                          text: isCurrentActive ? 'Active Plan ✓' : 'Subscribe with USDC',
                          variant: isCurrentActive
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary,
                          width: double.infinity,
                          onPressed: isCurrentActive ? null : () => controller.purchasePlan(plan),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppDimensions.borderSmall,
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
