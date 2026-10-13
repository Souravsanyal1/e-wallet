import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import 'auth_controller.dart';

class WalletLoginView extends GetView<AuthController> {
  const WalletLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final walletProviders = [
      (
        name: 'MetaMask',
        desc: 'Connect an installed browser or mobile wallet',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFF6851B),
      ),
      (
        name: 'Rainbow',
        desc: 'Connect Rainbow through a supported wallet provider',
        icon: Icons.looks_rounded,
        color: const Color(0xFF0019FF),
      ),
      (
        name: 'Coinbase',
        desc: 'Connect Coinbase Wallet through a supported provider',
        icon: Icons.circle_outlined,
        color: const Color(0xFF0052FF),
      ),
      (
        name: 'Browser Wallet',
        desc: 'Connect to any injected Web3 provider (EIP-1193)',
        icon: Icons.bolt_rounded,
        color: AppColors.darkPrimary,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space24,
              vertical: AppDimensions.space32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.15),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 38,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'sign_in_title'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    'wallet_explanation'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Wallet list
                  Obx(
                    () => Column(
                      children: walletProviders.map((provider) {
                        final isSelected = controller.selectedProvider.value == provider.name;
                        final isThisLoading = controller.isLoading.value && isSelected;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.space12),
                          child: InkWell(
                            onTap: controller.isLoading.value
                                ? null
                                : () => controller.connectWithProvider(provider.name),
                            borderRadius: AppDimensions.borderMedium,
                            child: Container(
                              padding: const EdgeInsets.all(AppDimensions.space16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: AppDimensions.borderMedium,
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                      : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: provider.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(provider.icon, color: provider.color, size: 24),
                                  ),
                                  const SizedBox(width: AppDimensions.space16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.name,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          provider.desc,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isThisLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Web3 Wallets 101'),
                            content: const Text(
                              'A crypto wallet is your digital identity on decentralized networks. '
                              'It holds your private keys and lets you sign messages to prove ownership '
                              'without ever sharing passwords or personal data.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'new_to_wallets'.tr,
                        style: TextStyle(
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
