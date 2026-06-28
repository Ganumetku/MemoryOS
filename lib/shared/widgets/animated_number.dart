import 'package:flutter/material.dart';

/// A premium animated counter widget for MemoryOS.
/// Animates numbers from 0 to [value] using easeOutCubic curve.
class AnimatedNumber extends StatelessWidget {
  final num value;
  final TextStyle style;
  final String suffix;
  final int precision;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.precision = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final displayStr = val.toStringAsFixed(precision);
        return Text(
          '$displayStr$suffix',
          style: style,
        );
      },
    );
  }
}
