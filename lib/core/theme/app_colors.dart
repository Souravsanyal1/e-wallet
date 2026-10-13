import 'package:flutter/material.dart';

/// App color tokens according to EliteChat Design System (docs/design.md).
/// Uses an ink-first dark palette with warm gold accents, plus matching light palette.
abstract final class AppColors {
  // Dark Palette
  static const darkBackground = Color(0xFF0E1116);
  static const darkSurface = Color(0xFF161B22);
  static const darkSurfaceHigh = Color(0xFF1E252E);
  static const darkPrimary = Color(0xFFE5B84B); // warm gold
  static const darkOnPrimary = Color(0xFF0E1116);
  static const darkTextPrimary = Color(0xFFF0F3F6);
  static const darkTextSecondary = Color(0xFF9AA4B2);
  static const darkOutline = Color(0xFF2A323D);
  static const darkSuccess = Color(0xFF3FB27F);
  static const darkWarning = Color(0xFFE0A030);
  static const darkError = Color(0xFFF0616D);

  // Light Palette
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F6F8);
  static const lightSurfaceHigh = Color(0xFFE9ECF0);
  static const lightPrimary = Color(0xFF8A6A00);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF12161C);
  static const lightTextSecondary = Color(0xFF545E6B);
  static const lightOutline = Color(0xFFD3D8DF);
  static const lightSuccess = Color(0xFF1E7D55);
  static const lightWarning = Color(0xFF8F5F00);
  static const lightError = Color(0xFFC0392B);

  // Accent & Bubble tints
  static const goldGlow = Color(0x33E5B84B);
  static const bubbleOutgoingDark = Color(0xFF2C2619);
  static const bubbleOutgoingBorderDark = Color(0xFF5C4718);
  static const bubbleOutgoingLight = Color(0xFFFFF7E0);
}
