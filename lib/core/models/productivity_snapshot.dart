import 'package:flutter/foundation.dart';

/// Immutable model representing the user's calculated productivity scores and mood.
@immutable
class ProductivitySnapshot {
  final double productivityScore;
  final double focusScore;
  final double consistencyScore;
  final double reminderDisciplineScore;
  final double memoryGrowthScore;
  final String overallMood;

  const ProductivitySnapshot({
    required this.productivityScore,
    required this.focusScore,
    required this.consistencyScore,
    required this.reminderDisciplineScore,
    required this.memoryGrowthScore,
    required this.overallMood,
  });

  /// Factory constructor providing default zero values.
  factory ProductivitySnapshot.zero() {
    return const ProductivitySnapshot(
      productivityScore: 0.0,
      focusScore: 0.0,
      consistencyScore: 0.0,
      reminderDisciplineScore: 0.0,
      memoryGrowthScore: 0.0,
      overallMood: 'Quiet',
    );
  }

  ProductivitySnapshot copyWith({
    double? productivityScore,
    double? focusScore,
    double? consistencyScore,
    double? reminderDisciplineScore,
    double? memoryGrowthScore,
    String? overallMood,
  }) {
    return ProductivitySnapshot(
      productivityScore: productivityScore ?? this.productivityScore,
      focusScore: focusScore ?? this.focusScore,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      reminderDisciplineScore: reminderDisciplineScore ?? this.reminderDisciplineScore,
      memoryGrowthScore: memoryGrowthScore ?? this.memoryGrowthScore,
      overallMood: overallMood ?? this.overallMood,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductivitySnapshot &&
        other.productivityScore == productivityScore &&
        other.focusScore == focusScore &&
        other.consistencyScore == consistencyScore &&
        other.reminderDisciplineScore == reminderDisciplineScore &&
        other.memoryGrowthScore == memoryGrowthScore &&
        other.overallMood == overallMood;
  }

  @override
  int get hashCode {
    return Object.hash(
      productivityScore,
      focusScore,
      consistencyScore,
      reminderDisciplineScore,
      memoryGrowthScore,
      overallMood,
    );
  }
}
