import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AdminColors {
  static const background = Color(0xFF0F172A); // slate-900
  static const surface = Color(0xFF1E293B);    // slate-800
  static const surfaceHigh = Color(0xFF334155); // slate-700
  static const primary = Color(0xFFE5B84B);    // gold
  static const accent = Color(0xFF38BDF8);     // sky-400
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const outline = Color(0xFF334155);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

abstract final class AdminTheme {
  static ThemeData dark() {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.primary,
        onPrimary: Color(0xFF0F172A),
        surface: AdminColors.surface,
        onSurface: AdminColors.textPrimary,
        outline: AdminColors.outline,
        error: AdminColors.error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AdminColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AdminColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AdminColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surfaceHigh,
        hintStyle: const TextStyle(color: AdminColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
