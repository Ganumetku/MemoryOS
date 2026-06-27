import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// A minimal glassmorphic icon button for toolbar hooks and panel headers.
class MemoryIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  const MemoryIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    final glassColor = ext?.glassSurface ?? Colors.white.withAlpha(13);
    final borderColor = ext?.glassBorder ?? Colors.white.withAlpha(26);
    final iconColor = color ?? theme.colorScheme.onSurface;

    Widget button = Container(
      decoration: BoxDecoration(
        color: glassColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: IconButton(
        iconSize: size,
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(10.0),
        constraints: const BoxConstraints(),
        splashRadius: size + 8,
      ),
    );

    return button;
  }
}
