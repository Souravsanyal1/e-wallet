import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import 'controllers/admin_controller.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'views/admin_login_view.dart';
import 'views/admin_shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  Get.put(AdminController());
  runApp(const EliteChatAdminApp());
}

class EliteChatAdminApp extends StatelessWidget {
  const EliteChatAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return GetMaterialApp(
      title: 'EliteChat Admin Portal',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      theme: AdminTheme.dark(),
      home: Obx(
        () => controller.isAuthenticated
            ? const AdminShellView()
            : const AdminLoginView(),
      ),
    );
  }
}
