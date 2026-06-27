import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_glass_card.dart';

/// A premium glassmorphic success confirmation card shown after saving a memory.
/// Plays a clean scale-in entrance animation and shows secure indexing details.
class SuccessCard extends StatefulWidget {
  final String text;
  final VoidCallback onClose;

  const SuccessCard({super.key, required this.text, required this.onClose});

  @override
  State<SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<SuccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MemoryGlassCard(
          padding: AppSpacing.pAll24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Row with glowing success circle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: AppSpacing.pAll8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                  AppSpacing.h12,
                  Text(
                    "I'll remember this for you.",
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.v16,
              // Stored memory fragment body
              Container(
                padding: AppSpacing.pAll16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(51), // 20% opacity black mask
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '"${widget.text}"',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDarkSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    AppSpacing.v12,
                    Text(
                      'Secured and encrypted in your personal vault.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.brandSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.v20,
              // Tap-to-dismiss helper button
              TextButton(
                onPressed: widget.onClose,
                child: Text(
                  'Dismiss',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
