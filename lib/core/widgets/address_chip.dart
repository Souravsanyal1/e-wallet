import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/ui_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AddressChip extends StatelessWidget {
  final String address;
  final bool showCopy;
  final String? networkName;

  const AddressChip({
    super.key,
    required this.address,
    this.showCopy = true,
    this.networkName,
  });

  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uiService = Get.isRegistered<UiService>() ? Get.find<UiService>() : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh,
        borderRadius: AppDimensions.borderPill,
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.darkSuccess,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          if (networkName != null) ...[
            Text(
              '$networkName ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ],
          Text(
            shortAddress,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          if (showCopy) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                uiService?.copyToClipboard(address, feedback: 'address_copied'.tr);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
