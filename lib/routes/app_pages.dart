import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/wallet_login_view.dart';
import '../modules/auth/wallet_signature_view.dart';
import '../modules/conversation/conversation_binding.dart';
import '../modules/conversation/conversation_view.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_view.dart';
import '../modules/profile/profile_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/wallet/wallet_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.walletLogin,
      page: () => const WalletLoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.walletSignature,
      page: () => const WalletSignatureView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.conversation,
      page: () => const ConversationView(),
      binding: ConversationBinding(),
    ),
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletView(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
    ),
  ];
}
