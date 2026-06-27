import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_radius.dart';

/// A premium glassmorphic card component for MemoryOS.
/// Utilizes background blurring ([BackdropFilter]) and theme-extended translucent colors.
class MemoryGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const MemoryGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final cardRadius = borderRadius ?? AppRadius.brAll16;

    // Glass properties derived from theme extension
    final glassColor = ext?.glassSurface ?? Colors.white.withAlpha(13);
    final borderColor = ext?.glassBorder ?? Colors.white.withAlpha(26);
    final shadows = ext?.cardShadows ?? [];

    Widget cardWidget = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent, // Handled by ClipRRect & BackdropFilter
        borderRadius: cardRadius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: cardRadius,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );

    // If onTap is provided, wrap in InkWell for ripple feedback
    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
