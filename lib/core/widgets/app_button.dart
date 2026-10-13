import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary)
                    : (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppDimensions.space8),
              ],
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            foregroundColor: isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary,
            minimumSize: Size(width ?? 88, AppDimensions.minTouchTarget),
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderSmall),
            elevation: 0,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            minimumSize: Size(width ?? 88, AppDimensions.minTouchTarget),
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderSmall),
            elevation: 0,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            side: BorderSide(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
            minimumSize: Size(width ?? 88, AppDimensions.minTouchTarget),
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderSmall),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            minimumSize: Size(width ?? 88, AppDimensions.minTouchTarget),
          ),
          child: child,
        ),
    };

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
