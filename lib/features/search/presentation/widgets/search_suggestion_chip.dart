import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Clickable chip widget for showing search autocomplete and suggestions.
class SearchSuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SearchSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withAlpha(20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.brandPrimary.withAlpha(40),
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
