import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import 'auth_controller.dart';

class WalletSignatureView extends GetView<AuthController> {
  const WalletSignatureView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('signature_request'.tr),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: controller.cancelSignature,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification Shield
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 44,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    'signature_request'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.darkSuccess.withValues(alpha: 0.15),
                        borderRadius: AppDimensions.borderPill,
                      ),
                      child: Text(
                        'signature_subtext'.tr,
                        style: const TextStyle(
                          color: AppColors.darkSuccess,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Raw EIP-4361 Message Box
                  Text(
                    'Message to Sign (EIP-4361)',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppDimensions.borderSmall,
                      border: Border.all(
                        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                      ),
                    ),
                    child: Obx(
                      () => SelectableText(
                        controller.currentSiweMessage.value,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.45,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Sign and Cancel actions
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'cancel'.tr,
                            variant: AppButtonVariant.outline,
                            onPressed: controller.isLoading.value ? null : controller.cancelSignature,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space16),
                        Expanded(
                          child: AppButton(
                            text: 'sign'.tr,
                            isLoading: controller.isLoading.value,
                            variant: AppButtonVariant.primary,
                            onPressed: controller.confirmSignature,
                          ),
                        ),
                      ],
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
