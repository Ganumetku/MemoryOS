import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A custom, premium loading spinner for MemoryOS.
/// Utilizes brand accent colors to render a smooth circular loader.
class MemoryLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const MemoryLoadingIndicator({
    super.key,
    this.size = 32.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.brandPrimary;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          backgroundColor: activeColor.withAlpha(26), // 10% opacity track
        ),
      ),
    );
  }
}
