import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/localization/app_translations.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EliteChatBootstrap());
}

class EliteChatBootstrap extends StatefulWidget {
  const EliteChatBootstrap({super.key});

  @override
  State<EliteChatBootstrap> createState() => _EliteChatBootstrapState();
}

class _EliteChatBootstrapState extends State<EliteChatBootstrap> {
  SettingsService? _settingsService;
  Object? _startupError;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    Object? startupError;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
    } catch (error, stackTrace) {
      startupError = error;
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
    }

    final settingsService = SettingsService();
    try {
      await settingsService.init().timeout(const Duration(seconds: 5));
    } catch (error, stackTrace) {
      debugPrint('Settings initialization failed; using defaults: $error\n$stackTrace');
    }
    Get.put<SettingsService>(settingsService, permanent: true);

    if (!mounted) return;
    setState(() {
      _settingsService = settingsService;
      _startupError = startupError;
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const _StartupLoadingView();
    return EliteChatApp(
      settingsService: _settingsService!,
      startupError: _startupError,
    );
  }
}

class EliteChatApp extends StatelessWidget {
  final SettingsService settingsService;
  final Object? startupError;

  const EliteChatApp({
    super.key,
    required this.settingsService,
    this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeMode = settingsService.themeMode.value;
      final locale = settingsService.locale.value;

      if (startupError != null) {
        return GetMaterialApp(
          title: 'EliteChat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: locale,
          home: _StartupErrorView(error: startupError!),
        );
      }

      return GetMaterialApp(
        title: 'EliteChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: const Locale('en', 'US'),
        initialBinding: InitialBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      );
    });
  }
}

class _StartupLoadingView extends StatelessWidget {
  const _StartupLoadingView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const Scaffold(
        backgroundColor: Color(0xFF101114),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 64, color: Color(0xFFF7D97A)),
              SizedBox(height: 16),
              Text(
                'EliteChat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  final Object error;

  const _StartupErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not connect to Firebase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Check the Firebase configuration and internet connection, then reopen the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
