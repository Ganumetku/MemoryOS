import 'package:flutter/material.dart';

/// Central color definitions for MemoryOS.
/// Focused on premium dark-first, minimal, Apple-like aesthetics with glowing AI accents.
class AppColors {
  AppColors._();

  // Brand Colors (Futuristic Glowing Accent System)
  static const Color brandPrimary = Color(0xFF8B5CF6); // Neon Violet / Purple
  static const Color brandSecondary = Color(
    0xFF06B6D4,
  ); // Neon Cyan / Electric Blue
  static const Color brandAccent = Color(
    0xFFEC4899,
  ); // Electric Pink (for active notifications/highlights)

  // ==========================================
  // DARK THEME PALETTE (Primary)
  // ==========================================

  // Backgrounds (Pure Pitch Black / Slate Deep Navy)
  static const Color bgDarkPrimary = Color(
    0xFF09090B,
  ); // Apple-like Slate-Black
  static const Color bgDarkSecondary = Color(
    0xFF121214,
  ); // Deep Charcoal Card Base
  static const Color bgDarkTertiary = Color(
    0xFF1C1C1E,
  ); // Elevated borders/menus

  // Glassmorphic Surface Cards (Semi-Translucent White Overlays)
  static const Color glassDarkSurface = Color(0x0DFFFFFF); // 5% White overlay
  static const Color glassDarkBorder = Color(
    0x1AFFFFFF,
  ); // 10% White boundary overlay
  static const Color glassDarkFill = Color(0x14FFFFFF); // 8% White fill

  // Text Colors (High Contrast White / Muted Silver)
  static const Color textDarkPrimary = Color(0xFFF9FAFB); // Pure crisp white
  static const Color textDarkSecondary = Color(
    0xFF9CA3AF,
  ); // Slate/Silver Muted
  static const Color textDarkTertiary = Color(0xFF6B7280); // Deep Dark Gray

  // ==========================================
  // LIGHT THEME PALETTE (Fallback)
  // ==========================================

  // Backgrounds
  static const Color bgLightPrimary = Color(0xFFFAFAFA); // Paper White
  static const Color bgLightSecondary = Color(0xFFF4F4F5); // Very Soft Gray
  static const Color bgLightTertiary = Color(0xFFE4E4E7); // Active borders

  // Glassmorphic Surface Cards (Semi-Translucent Dark Overlays)
  static const Color glassLightSurface = Color(0x0A000000); // 4% Black overlay
  static const Color glassLightBorder = Color(
    0x0F000000,
  ); // 6% Black boundary overlay
  static const Color glassLightFill = Color(0x05000000); // 2% Black fill

  // Text Colors
  static const Color textLightPrimary = Color(0xFF09090B); // Pure carbon black
  static const Color textLightSecondary = Color(0xFF52525B); // Zinc Muted Gray
  static const Color textLightTertiary = Color(0xFF71717A); // Soft Gray

  // ==========================================
  // FUNCTIONAL STATUS COLORS
  // ==========================================
  static const Color error = Color(0xFFEF4444); // Neon Red
  static const Color success = Color(0xFF10B981); // Neon Green
  static const Color warning = Color(0xFFF59E0B); // Neon Gold
  static const Color info = Color(0xFF3B82F6); // Clean Blue
}
