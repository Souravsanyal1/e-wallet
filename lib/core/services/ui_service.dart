import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

class UiService extends GetxService {
  void showSnackbar({
    required String title,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? AppColors.darkError : AppColors.darkSurfaceHigh,
      colorText: isError ? Colors.white : AppColors.darkTextPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      icon: Icon(
        isError ? Icons.error_outline : Icons.info_outline,
        color: isError ? Colors.white : AppColors.darkPrimary,
      ),
    );
  }

  void showSuccess(String message) {
    showSnackbar(title: 'Success', message: message, isError: false);
  }

  void showError(String message) {
    showSnackbar(title: 'Error', message: message, isError: true);
  }

  void copyToClipboard(String text, {String feedback = 'Copied to clipboard'}) {
    Clipboard.setData(ClipboardData(text: text));
    showSnackbar(title: 'Copied', message: feedback);
  }
}
