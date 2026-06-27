import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable shadows and glow effects for MemoryOS.
/// Provides Apple-like minimal depth and glowing accents.
class AppShadows {
  AppShadows._();

  /// Very soft shadow for dark mode cards to separate from background
  static final List<BoxShadow> darkCard = [
    BoxShadow(
      color: Colors.black.withAlpha(128), // 50% opacity black
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];

  /// Extremely soft shadow for light mode cards
  static final List<BoxShadow> lightCard = [
    BoxShadow(
      color: Colors.black.withAlpha(15), // 6% opacity black
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -8,
    ),
  ];

  /// Glowing brand effect (e.g. for primary floating buttons, active indicators)
  static final List<BoxShadow> brandGlow = [
    BoxShadow(
      color: AppColors.brandPrimary.withAlpha(76), // 30% brand color glow
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// Secondary glow effect (e.g. for AI triggers, audio waveform active glows)
  static final List<BoxShadow> secondaryGlow = [
    BoxShadow(
      color: AppColors.brandSecondary.withAlpha(76),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  /// Glassmorphism subtle outline shadow (emulates a physical double border highlight)
  static final List<BoxShadow> glassOutline = [
    BoxShadow(
      color: Colors.white.withAlpha(13),
      offset: const Offset(-1, -1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withAlpha(76),
      offset: const Offset(1, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
}
