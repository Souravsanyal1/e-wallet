import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum MessageDeliveryStatus { pending, sent, delivered, read, failed }

class StatusBadge extends StatelessWidget {
  final MessageDeliveryStatus status;
  final VoidCallback? onRetry;

  const StatusBadge({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Delivery status: ${status.name}',
      child: switch (status) {
        MessageDeliveryStatus.pending => const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: AppColors.darkTextSecondary,
          ),
        MessageDeliveryStatus.sent => const Icon(
            Icons.check_rounded,
            size: 14,
            color: AppColors.darkTextSecondary,
          ),
        MessageDeliveryStatus.delivered => const Icon(
            Icons.done_all_rounded,
            size: 14,
            color: AppColors.darkTextSecondary,
          ),
        MessageDeliveryStatus.read => const Icon(
            Icons.done_all_rounded,
            size: 14,
            color: AppColors.darkPrimary, // accent gold
          ),
        MessageDeliveryStatus.failed => InkWell(
            onTap: onRetry,
            child: const Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: AppColors.darkError,
            ),
          ),
      },
    );
  }
}
