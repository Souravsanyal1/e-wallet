import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../theme/app_theme.dart';

class AdminLoginView extends StatelessWidget {
  const AdminLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final emailController = TextEditingController(text: 'ops@elitechat.app');
    final passwordController = TextEditingController(text: '••••••••••••');
    final totpController = TextEditingController(text: '123456');

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.outline),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          size: 38, color: AdminColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EliteChat Operations',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Authorized Admin & Moderation Access Only',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 28),

                  const Text('Admin Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('2-Factor Auth (TOTP Code)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: totpController,
                    decoration: const InputDecoration(
                      hintText: '6-digit authenticator code',
                      prefixIcon: Icon(Icons.security_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.login(
                                emailController.text,
                                passwordController.text,
                                totpController.text,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: const Color(0xFF0F172A),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In with MFA', style: TextStyle(fontWeight: FontWeight.w700)),
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
