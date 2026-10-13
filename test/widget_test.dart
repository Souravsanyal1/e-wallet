import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elite_chat/core/theme/app_colors.dart';
import 'package:elite_chat/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('AppTheme dark conforms to ink and gold design tokens', () {
    final theme = AppTheme.dark();
    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(theme.colorScheme.primary, AppColors.darkPrimary);
    expect(theme.colorScheme.surface, AppColors.darkSurface);
    expect(theme.brightness, Brightness.dark);
  });

  test('AppTheme light conforms to light tokens', () {
    final theme = AppTheme.light();
    expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
    expect(theme.colorScheme.primary, AppColors.lightPrimary);
    expect(theme.colorScheme.surface, AppColors.lightSurface);
    expect(theme.brightness, Brightness.light);
  });
}
