import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/bindings/initial_binding.dart';
import 'core/localization/app_translations.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent settings service before runApp
  final settingsService = await Get.putAsync(() => SettingsService().init());

  runApp(EliteChatApp(settingsService: settingsService));
}

class EliteChatApp extends StatelessWidget {
  final SettingsService settingsService;

  const EliteChatApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: 'EliteChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settingsService.themeMode.value,
        translations: AppTranslations(),
        locale: settingsService.locale.value,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: InitialBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      ),
    );
  }
}
