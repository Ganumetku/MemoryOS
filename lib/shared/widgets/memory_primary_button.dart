import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import 'memory_loading_indicator.dart';

/// Premium brand action button for MemoryOS.
/// Features a linear gradient, capsule design, and built-in loading indicator.
class MemoryPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const MemoryPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final gradient =
        ext?.brandGradient ??
        const LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandSecondary],
        );
    final shadows = ext?.brandGlowShadows ?? [];

    final bool isEnabled = onPressed != null && !isLoading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brAll12,
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : theme.colorScheme.surface.withAlpha(128),
        boxShadow: isEnabled ? shadows : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: AppRadius.brAll12,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: isLoading
                ? const MemoryLoadingIndicator(size: 24, color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isEnabled ? Colors.white : theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
