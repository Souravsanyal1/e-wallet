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

class WalletController extends GetxController {
  final WalletService _walletService;
  final ChannelRepository _channelRepository;
  final UiService _uiService;

  WalletController(this._walletService, this._channelRepository, this._uiService);

  final RxList<PlanModel> plans = <PlanModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPaying = false.obs;
  final Rxn<DateTime> premiumUntil = Rxn<DateTime>();

  WalletAccount? get account => _walletService.currentAccount.value;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
    loadPremiumStatus();
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

  Future<void> loadPremiumStatus() async {
    final result = await _channelRepository.fetchPremiumUntil();
    result.when(
      ok: (value) => premiumUntil.value = value,
      err: (_) {},
    );
  }

  Future<void> purchasePlan(PlanModel plan) async {
    if (!_walletService.isConnected) {
      _uiService.showError('Connect your wallet before purchasing a plan.');
      return;
    }
    if (isPaying.value) return;
    isPaying.value = true;
    try {
      PremiumQuote? quote;
      final quoteResult = await _channelRepository.createPremiumQuote(planId: plan.id);
      quoteResult.when(
        ok: (value) => quote = value,
        err: (error) => _uiService.showError(error.message),
      );
      if (quote == null) return;
      if (account?.chainId != quote!.chainId) {
        _uiService.showError('Switch your wallet to the BNB Smart Chain test network, then try again.');
        return;
      }

      final receiver = quote!.receiverAddress.substring(2).toLowerCase().padLeft(64, '0');
      final amount = BigInt.parse(quote!.amount).toRadixString(16).padLeft(64, '0');
      final txHash = await _walletService.sendTransaction(
        to: quote!.tokenAddress,
        value: '0x0',
        data: '0xa9059cbb$receiver$amount',
        chainId: quote!.chainId,
      );
      final verification = await _channelRepository.verifyPaymentAndSubscribe(
        quoteId: quote!.quoteId,
        txHash: txHash,
      );
      verification.when(
        ok: (result) {
          if (result.isConfirmed) {
            loadPremiumStatus();
            _uiService.showSuccess('E-FORCE payment confirmed. Premium is active.');
          } else {
            _uiService.showSnackbar(
                title: 'Payment submitted',
                message: 'Confirming your transaction. Premium starts after network confirmation.',
            );
          }
        },
        err: (error) => _uiService.showError(error.message),
      );
    } catch (_) {
      _uiService.showError('Wallet payment could not be completed. Check your wallet connection and try again.');
    } finally {
      isPaying.value = false;
    }
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
                    address: controller.account?.address ?? 'No wallet connected',
                    networkName: 'BNB Smart Chain Testnet',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Wallet status',
                          amount: controller.account == null ? 'Not connected' : 'Connected',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Token balance',
                          amount: 'Shown in your wallet',
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
              'Pay on BNB Smart Chain to unlock token-gated channels and plan benefits.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            Obx(() {
              final expiry = controller.premiumUntil.value;
              if (expiry == null || !expiry.isAfter(DateTime.now())) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Premium active until ${MaterialLocalizations.of(context).formatMediumDate(expiry.toLocal())}'),
              );
            }),
            const SizedBox(height: AppDimensions.space16),

            // Subscription Tiers
            Obx(
              () => Column(
                children: controller.plans.map((plan) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                    padding: const EdgeInsets.all(AppDimensions.space20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppDimensions.borderMedium,
                      border: Border.all(
                        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                        width: 1,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${plan.displayPrice} ${plan.tokenSymbol} / ${plan.durationDays} days',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  ),
                                ),
                                if (plan.usdListPriceCents != null)
                                  Text('USD list $${(plan.usdListPriceCents! / 100).toStringAsFixed(2)}'),
                              ],
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
                          text: 'Pay with E-FORCE',
                          variant: AppButtonVariant.primary,
                          width: double.infinity,
                          isLoading: controller.isPaying.value,
                          onPressed: () => controller.purchasePlan(plan),
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
