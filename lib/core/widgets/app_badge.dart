import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../algorithms/sm2_engine.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory AppBadge.forMasteryStatus(CardMasteryStatus status) {
    switch (status) {
      case CardMasteryStatus.learning:
        return const AppBadge(
          label: 'Learning',
          backgroundColor: Color(0xFF451A03),
          textColor: AppColors.warning,
          icon: Icons.school_outlined,
        );
      case CardMasteryStatus.reviewing:
        return const AppBadge(
          label: 'Reviewing',
          backgroundColor: Color(0xFF1E3A8A),
          textColor: Color(0xFF93C5FD),
          icon: Icons.refresh_rounded,
        );
      case CardMasteryStatus.mastered:
        return const AppBadge(
          label: 'Mastered',
          backgroundColor: Color(0xFF064E3B),
          textColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
    }
  }

  factory AppBadge.newCard() {
    return const AppBadge(
      label: 'New Card',
      backgroundColor: Color(0xFF083344),
      textColor: Color(0xFF67E8F9),
      icon: Icons.auto_awesome_rounded,
    );
  }

  factory AppBadge.dueToday() {
    return const AppBadge(
      label: 'Due Today',
      backgroundColor: Color(0xFF7F1D1D),
      textColor: Color(0xFFFCA5A5),
      icon: Icons.timer_outlined,
    );
  }

  factory AppBadge.scheduledIn(int days) {
    return AppBadge(
      label: 'In ${days < 1 ? 1 : days}d',
      backgroundColor: const Color(0xFF1E293B),
      textColor: const Color(0xFF94A3B8),
      icon: Icons.event_available_rounded,
    );
  }

  factory AppBadge.weakCard() {
    return const AppBadge(
      label: 'Needs Attention',
      backgroundColor: Color(0xFF4C0519),
      textColor: Color(0xFFFDA4AF),
      icon: Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
