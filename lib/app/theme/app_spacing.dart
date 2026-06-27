import 'package:flutter/material.dart';

/// Standard layout spacing definitions for MemoryOS.
/// Enforces a layout grid based on the scale: 4, 8, 12, 16, 20, 24, 32, 40.
class AppSpacing {
  AppSpacing._();

  // Baseline Values
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;

  // ==========================================
  // Vertical Spacers (Heights)
  // ==========================================
  static const SizedBox v4 = SizedBox(height: s4);
  static const SizedBox v8 = SizedBox(height: s8);
  static const SizedBox v12 = SizedBox(height: s12);
  static const SizedBox v16 = SizedBox(height: s16);
  static const SizedBox v20 = SizedBox(height: s20);
  static const SizedBox v24 = SizedBox(height: s24);
  static const SizedBox v32 = SizedBox(height: s32);
  static const SizedBox v40 = SizedBox(height: s40);

  // ==========================================
  // Horizontal Spacers (Widths)
  // ==========================================
  static const SizedBox h4 = SizedBox(width: s4);
  static const SizedBox h8 = SizedBox(width: s8);
  static const SizedBox h12 = SizedBox(width: s12);
  static const SizedBox h16 = SizedBox(width: s16);
  static const SizedBox h20 = SizedBox(width: s20);
  static const SizedBox h24 = SizedBox(width: s24);
  static const SizedBox h32 = SizedBox(width: s32);
  static const SizedBox h40 = SizedBox(width: s40);

  // ==========================================
  // EdgeInsets Shortcuts (Padding & Margins)
  // ==========================================

  // All sides equal
  static const EdgeInsets pAll4 = EdgeInsets.all(s4);
  static const EdgeInsets pAll8 = EdgeInsets.all(s8);
  static const EdgeInsets pAll12 = EdgeInsets.all(s12);
  static const EdgeInsets pAll16 = EdgeInsets.all(s16);
  static const EdgeInsets pAll20 = EdgeInsets.all(s20);
  static const EdgeInsets pAll24 = EdgeInsets.all(s24);
  static const EdgeInsets pAll32 = EdgeInsets.all(s32);
  static const EdgeInsets pAll40 = EdgeInsets.all(s40);

  // Symmetric Horizontal
  static const EdgeInsets pHoriz4 = EdgeInsets.symmetric(horizontal: s4);
  static const EdgeInsets pHoriz8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets pHoriz12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets pHoriz16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets pHoriz20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets pHoriz24 = EdgeInsets.symmetric(horizontal: s24);
  static const EdgeInsets pHoriz32 = EdgeInsets.symmetric(horizontal: s32);

  // Symmetric Vertical
  static const EdgeInsets pVert4 = EdgeInsets.symmetric(vertical: s4);
  static const EdgeInsets pVert8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets pVert12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets pVert16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets pVert20 = EdgeInsets.symmetric(vertical: s20);
  static const EdgeInsets pVert24 = EdgeInsets.symmetric(vertical: s24);
  static const EdgeInsets pVert32 = EdgeInsets.symmetric(vertical: s32);
}
