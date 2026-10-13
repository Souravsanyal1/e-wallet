import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/admin_controller.dart';
import 'theme/app_theme.dart';
import 'views/admin_login_view.dart';
import 'views/admin_shell_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: AdminTheme.dark(),
      home: Obx(
        () => controller.isAuthenticated
            ? const AdminShellView()
            : const AdminLoginView(),
      ),
    );
  }
}
