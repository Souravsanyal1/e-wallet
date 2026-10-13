import 'package:flutter/material.dart';

abstract final class AppDimensions {
  // Spacing grid (4dp)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Corner radiuses
  static const double radiusSmall = 8.0; // inputs, small cards
  static const double radiusMedium = 16.0; // bubbles, sheets, cards
  static const double radiusPill = 999.0; // avatars, pills, badges

  static const BorderRadius borderSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(radiusPill));

  // Touch targets & layouts
  static const double minTouchTarget = 48.0;
  static const double maxMessageColumnWidth = 720.0;
  static const double maxBubbleWidth = 520.0;

  // Breakpoints
  static const double breakpointCompact = 600.0;
  static const double breakpointExpanded = 840.0;
}
