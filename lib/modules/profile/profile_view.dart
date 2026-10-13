import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/ui_service.dart';
import '../../core/services/wallet_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/address_chip.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository;
  final WalletService _walletService;
  final UiService _uiService;

  ProfileController(this._authRepository, this._walletService, this._uiService);

  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();

  @override
  void onInit() {
    super.onInit();
    profile.value = _authRepository.currentProfile ??
        ProfileModel(
          id: 'user_me',
          handle: 'vitalik_fan',
          displayName: 'Crypto Native',
          bio: 'Decentralized communications advocate',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          isOnline: true,
        );
  }

  Future<void> updateBio(String newBio) async {
    final res = await _authRepository.updateProfile(bio: newBio);
    res.when(
      ok: (p) {
        profile.value = p;
        _uiService.showSuccess('Bio updated');
      },
      err: (e) => _uiService.showError(e.message),
    );
  }

  void logout() {
    _authRepository.signOut();
    _walletService.disconnect();
    Get.offAllNamed(AppRoutes.walletLogin);
  }
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('profile'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.to(() => const SettingsView()),
          ),
        ],
      ),
      body: Obx(() {
        final p = controller.profile.value;
        if (p == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User header
              Center(
                child: Column(
                  children: [
                    Avatar(name: p.displayName, size: 76, showBadge: true, isOnline: true),
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      p.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${p.handle}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                    if (p.bio != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        p.bio!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),
              // Linked Wallets
              Text(
                'Linked Wallets',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppDimensions.borderMedium,
                  border: Border.all(
                    color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Primary (EVM)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('Chain ID: 1', style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AddressChip(
                      address: '0x71C8412092d8866F407b621946414380b49f4b9B',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space20),
              // Account Details
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppDimensions.borderMedium,
                  border: Border.all(
                    color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded, size: 20),
                      title: const Text('Member Since', style: TextStyle(fontSize: 14)),
                      trailing: Text(
                        DateFormat.yMMMd().format(p.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined, size: 20),
                      title: Text('settings'.tr, style: const TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.to(() => const SettingsView()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space32),
              AppButton(
                text: 'logout'.tr,
                variant: AppButtonVariant.outline,
                onPressed: controller.logout,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        children: [
          // Theme Section
          Text('theme'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppDimensions.borderMedium,
                border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text('theme_dark'.tr),
                    trailing: settingsService.themeMode.value == ThemeMode.dark
                        ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : null,
                    onTap: () => settingsService.setThemeMode(ThemeMode.dark),
                  ),
                  ListTile(
                    title: Text('theme_light'.tr),
                    trailing: settingsService.themeMode.value == ThemeMode.light
                        ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : null,
                    onTap: () => settingsService.setThemeMode(ThemeMode.light),
                  ),
                  ListTile(
                    title: Text('theme_system'.tr),
                    trailing: settingsService.themeMode.value == ThemeMode.system
                        ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : null,
                    onTap: () => settingsService.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space24),
          // Language Section
          Text('language'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppDimensions.borderMedium,
                border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('English (US)'),
                    trailing: settingsService.locale.value.languageCode == 'en'
                        ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : null,
                    onTap: () => settingsService.setLocale(const Locale('en', 'US')),
                  ),
                  ListTile(
                    title: const Text('বাংলা (Bengali - BD)'),
                    trailing: settingsService.locale.value.languageCode == 'bn'
                        ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : null,
                    onTap: () => settingsService.setLocale(const Locale('bn', 'BD')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space24),
          // Security Architecture Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppDimensions.borderMedium,
              border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, size: 20, color: AppColors.darkSuccess),
                    SizedBox(width: 8),
                    Text('Security Posture', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Postgres Row Level Security (RLS) restricts database queries at the engine level.\n'
                  '• Identity is verified via Sign-In with Ethereum (EIP-4361).\n'
                  '• Zero client-side private key handling; all cryptographic signatures remain inside your personal wallet.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
