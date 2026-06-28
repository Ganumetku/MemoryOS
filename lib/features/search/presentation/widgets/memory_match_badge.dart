import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Reusable badge displaying search match percentage and classification.
class MemoryMatchBadge extends StatelessWidget {
  final double relevanceScore; // similarity score between 0.0 and 1.0

  const MemoryMatchBadge({
    super.key,
    required this.relevanceScore,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (relevanceScore * 100).round().clamp(15, 100);

    final String label;
    final Color color;

    if (percentage >= 95) {
      label = 'Exact Match';
      color = AppColors.brandPrimary;
    } else if (percentage >= 85) {
      label = 'Strong Match';
      color = AppColors.brandSecondary;
    } else if (percentage >= 70) {
      label = 'Related Match';
      color = AppColors.warning;
    } else {
      label = 'Weak Match';
      color = AppColors.textDarkTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1.0,
        ),
      ),
      child: Text(
        '$label • $percentage%',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
