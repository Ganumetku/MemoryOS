import 'package:flutter/material.dart';

/// Uniform border-radius system for MemoryOS.
/// Standardizes rounding styles across cards, dialogs, buttons, and chips.
class AppRadius {
  AppRadius._();

  // Raw numerical values
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  // ==========================================
  // Radius Objects
  // ==========================================
  static const Radius circular4 = Radius.circular(r4);
  static const Radius circular8 = Radius.circular(r8);
  static const Radius circular12 = Radius.circular(r12);
  static const Radius circular16 = Radius.circular(r16);
  static const Radius circular20 = Radius.circular(r20);
  static const Radius circular24 = Radius.circular(r24);
  static const Radius circular32 = Radius.circular(r32);

  // ==========================================
  // BorderRadius Objects
  // ==========================================
  static const BorderRadius brAll4 = BorderRadius.all(circular4);
  static const BorderRadius brAll8 = BorderRadius.all(circular8);
  static const BorderRadius brAll12 = BorderRadius.all(circular12);
  static const BorderRadius brAll16 = BorderRadius.all(circular16);
  static const BorderRadius brAll20 = BorderRadius.all(circular20);
  static const BorderRadius brAll24 = BorderRadius.all(circular24);
  static const BorderRadius brAll32 = BorderRadius.all(circular32);

  // Top Rounded Corners (For BottomSheets, Cards, Modals)
  static const BorderRadius brTop12 = BorderRadius.vertical(top: circular12);
  static const BorderRadius brTop16 = BorderRadius.vertical(top: circular16);
  static const BorderRadius brTop24 = BorderRadius.vertical(top: circular24);
  static const BorderRadius brTop32 = BorderRadius.vertical(top: circular32);

  // Bottom Rounded Corners
  static const BorderRadius brBottom12 = BorderRadius.vertical(
    bottom: circular12,
  );
  static const BorderRadius brBottom16 = BorderRadius.vertical(
    bottom: circular16,
  );
  static const BorderRadius brBottom24 = BorderRadius.vertical(
    bottom: circular24,
  );
  static const BorderRadius brBottom32 = BorderRadius.vertical(
    bottom: circular32,
  );
}
