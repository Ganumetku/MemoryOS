import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_text_styles.dart';

/// Central theme management class for MemoryOS.
/// Couples custom token variables into Flutter ThemeData configurations.
/// Implements custom ThemeExtensions for glassmorphism styling and shadow glows.
class AppTheme {
  AppTheme._();

  /// Returns the default dark theme (Primary Focus).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDarkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandSecondary,
        surface: AppColors.bgDarkSecondary,
        error: AppColors.error,
        onPrimary: AppColors.textDarkPrimary,
        onSecondary: AppColors.textDarkPrimary,
        onSurface: AppColors.textDarkPrimary,
        onError: AppColors.textDarkPrimary,
      ),

      // Card Styling (Transparent Borders for Glass Overlay effect)
      cardTheme: CardThemeData(
        color: AppColors.bgDarkSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brAll16,
          side: const BorderSide(color: AppColors.bgDarkTertiary, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgDarkSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // App Bar Style
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDarkPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textDarkPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Text Selection Handles & Cursor Colors
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brandPrimary,
        selectionColor: AppColors.glassDarkBorder,
        selectionHandleColor: AppColors.brandPrimary,
      ),

      // Input Decoration (Minimal Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgDarkSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: const BorderSide(
            color: AppColors.bgDarkTertiary,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
        hintStyle: const TextStyle(color: AppColors.textDarkTertiary),
      ),

      // Buttons (Apple-like Capsule Pill Shapes)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.textDarkPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brAll12),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Typography Mapping
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textDarkTertiary,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textDarkPrimary,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textDarkTertiary,
        ),
      ),

      // Theme Extensions (Glass overlays & brand shadows)
      extensions: [
        AppThemeExtension(
          glassSurface: AppColors.glassDarkSurface,
          glassBorder: AppColors.glassDarkBorder,
          glassFill: AppColors.glassDarkFill,
          cardShadows: AppShadows.darkCard,
          brandGlowShadows: AppShadows.brandGlow,
          glassOutlineShadows: AppShadows.glassOutline,
          brandGradient: const LinearGradient(
            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  /// Returns the supplementary light theme.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLightPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandSecondary,
        surface: AppColors.bgLightSecondary,
        error: AppColors.error,
        onPrimary: AppColors.textLightPrimary,
        onSecondary: AppColors.textLightPrimary,
        onSurface: AppColors.textLightPrimary,
        onError: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: AppColors.bgLightSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brAll16,
          side: const BorderSide(color: AppColors.bgLightTertiary, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgLightSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textLightPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textLightPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brandPrimary,
        selectionColor: AppColors.glassLightBorder,
        selectionHandleColor: AppColors.brandPrimary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLightSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: const BorderSide(
            color: AppColors.bgLightTertiary,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brAll12,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textLightSecondary),
        hintStyle: const TextStyle(color: AppColors.textLightTertiary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brAll12),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textLightPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textLightPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textLightPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textLightPrimary,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textLightPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textLightPrimary,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textLightPrimary,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textLightPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textLightPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLightSecondary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textLightTertiary,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textLightPrimary,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textLightSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textLightTertiary,
        ),
      ),

      extensions: [
        AppThemeExtension(
          glassSurface: AppColors.glassLightSurface,
          glassBorder: AppColors.glassLightBorder,
          glassFill: AppColors.glassLightFill,
          cardShadows: AppShadows.lightCard,
          brandGlowShadows: AppShadows.brandGlow,
          glassOutlineShadows: AppShadows.glassOutline,
          brandGradient: const LinearGradient(
            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }
}

/// Custom [ThemeExtension] enabling simple, compile-safe use of
/// futuristic glass overlays, glows, and brand gradients throughout the layout.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color? glassSurface;
  final Color? glassBorder;
  final Color? glassFill;
  final List<BoxShadow>? cardShadows;
  final List<BoxShadow>? brandGlowShadows;
  final List<BoxShadow>? glassOutlineShadows;
  final Gradient? brandGradient;

  AppThemeExtension({
    required this.glassSurface,
    required this.glassBorder,
    required this.glassFill,
    required this.cardShadows,
    required this.brandGlowShadows,
    required this.glassOutlineShadows,
    required this.brandGradient,
  });

  @override
  AppThemeExtension copyWith({
    Color? glassSurface,
    Color? glassBorder,
    Color? glassFill,
    List<BoxShadow>? cardShadows,
    List<BoxShadow>? brandGlowShadows,
    List<BoxShadow>? glassOutlineShadows,
    Gradient? brandGradient,
  }) {
    return AppThemeExtension(
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      glassFill: glassFill ?? this.glassFill,
      cardShadows: cardShadows ?? this.cardShadows,
      brandGlowShadows: brandGlowShadows ?? this.brandGlowShadows,
      glassOutlineShadows: glassOutlineShadows ?? this.glassOutlineShadows,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t),
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t),
      glassFill: Color.lerp(glassFill, other.glassFill, t),
      cardShadows: t < 0.5 ? cardShadows : other.cardShadows,
      brandGlowShadows: t < 0.5 ? brandGlowShadows : other.brandGlowShadows,
      glassOutlineShadows: t < 0.5
          ? glassOutlineShadows
          : other.glassOutlineShadows,
      brandGradient: Gradient.lerp(brandGradient, other.brandGradient, t),
    );
  }
}
