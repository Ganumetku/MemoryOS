import 'package:flutter/foundation.dart';

/// Immutable model representing an AI Daily Reflection and coaching plan.
@immutable
class DailyReflection {
  final DateTime date;
  final String title;
  final String summary;
  final String mood; // 'Quiet', 'Balanced', 'Productive', 'Focused', 'Overloaded', 'Reflective', 'NeedsAttention'
  final double score; // 0 to 100
  final List<String> highlights;
  final List<String> concerns;
  final List<String> suggestedActions;
  final List<String> reflectionQuestions;
  final DateTime generatedAt;

  // New Coaching fields
  final List<String> wins;
  final List<String> needsImprovement;
  final String tomorrowFocus;
  final String scoreExplanation;

  const DailyReflection({
    required this.date,
    required this.title,
    required this.summary,
    required this.mood,
    required this.score,
    required this.highlights,
    required this.concerns,
    required this.suggestedActions,
    required this.reflectionQuestions,
    required this.generatedAt,
    List<String>? wins,
    List<String>? needsImprovement,
    this.tomorrowFocus = '',
    this.scoreExplanation = '',
  })  : wins = wins ?? highlights,
        needsImprovement = needsImprovement ?? concerns;

  DailyReflection copyWith({
    DateTime? date,
    String? title,
    String? summary,
    String? mood,
    double? score,
    List<String>? highlights,
    List<String>? concerns,
    List<String>? suggestedActions,
    List<String>? reflectionQuestions,
    DateTime? generatedAt,
    List<String>? wins,
    List<String>? needsImprovement,
    String? tomorrowFocus,
    String? scoreExplanation,
  }) {
    return DailyReflection(
      date: date ?? this.date,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      mood: mood ?? this.mood,
      score: score ?? this.score,
      highlights: highlights ?? this.highlights,
      concerns: concerns ?? this.concerns,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      reflectionQuestions: reflectionQuestions ?? this.reflectionQuestions,
      generatedAt: generatedAt ?? this.generatedAt,
      wins: wins ?? this.wins,
      needsImprovement: needsImprovement ?? this.needsImprovement,
      tomorrowFocus: tomorrowFocus ?? this.tomorrowFocus,
      scoreExplanation: scoreExplanation ?? this.scoreExplanation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyReflection &&
        other.date == date &&
        other.title == title &&
        other.summary == summary &&
        other.mood == mood &&
        other.score == score &&
        listEquals(other.highlights, highlights) &&
        listEquals(other.concerns, concerns) &&
        listEquals(other.suggestedActions, suggestedActions) &&
        listEquals(other.reflectionQuestions, reflectionQuestions) &&
        other.generatedAt == generatedAt &&
        listEquals(other.wins, wins) &&
        listEquals(other.needsImprovement, needsImprovement) &&
        other.tomorrowFocus == tomorrowFocus &&
        other.scoreExplanation == scoreExplanation;
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      title,
      summary,
      mood,
      score,
      Object.hashAll(highlights),
      Object.hashAll(concerns),
      Object.hashAll(suggestedActions),
      Object.hashAll(reflectionQuestions),
      generatedAt,
      Object.hashAll(wins),
      Object.hashAll(needsImprovement),
      tomorrowFocus,
      scoreExplanation,
    );
  }
}
