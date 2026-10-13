import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool showBadge;

  const Avatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 44,
    this.isOnline = false,
    this.showBadge = false,
  });

  Color _getDeterministicColor(String text) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFE5B84B), // Gold
    ];
    if (text.isEmpty) return colors.first;
    final hash = text.codeUnits.reduce((a, b) => a + b);
    return colors[hash % colors.length];
  }

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    final parts = text.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return text.substring(0, text.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getDeterministicColor(name);
    final initials = _getInitials(name);

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor.withValues(alpha: 0.2),
            border: Border.all(color: bgColor.withValues(alpha: 0.6), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: bgColor,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.darkSuccess : AppColors.darkTextSecondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
