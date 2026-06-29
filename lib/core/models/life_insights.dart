import 'package:flutter/foundation.dart';

/// Immutable model representing computed stats and analytics for MemoryOS.
@immutable
class LifeInsights {
  final int totalMemories;
  final int todayMemories;
  final int yesterdayMemories;
  final int weeklyMemories;
  final int monthlyMemories;
  final int completedReminders;
  final int upcomingReminders;
  final int missedReminders;
  final int currentStreak;
  final int longestStreak;
  final String dominantCategory;
  final int busiestHour;
  final String busiestWeekday;
  final String busiestMonth;
  final Map<String, int> categoryDistribution;
  final Map<int, int> hourlyDistribution;
  final Map<String, int> weekdayDistribution;
  final Map<String, int> monthlyDistribution;
  final List<String> topKeywords;
  final List<String> topPeople;
  final List<String> topTags;
  final double averageMemoriesPerDay;
  final double reminderCompletionRate;
  final double averageReminderDelay;

  const LifeInsights({
    required this.totalMemories,
    required this.todayMemories,
    required this.yesterdayMemories,
    required this.weeklyMemories,
    required this.monthlyMemories,
    required this.completedReminders,
    required this.upcomingReminders,
    required this.missedReminders,
    required this.currentStreak,
    required this.longestStreak,
    required this.dominantCategory,
    required this.busiestHour,
    required this.busiestWeekday,
    required this.busiestMonth,
    required this.categoryDistribution,
    required this.hourlyDistribution,
    required this.weekdayDistribution,
    required this.monthlyDistribution,
    required this.topKeywords,
    required this.topPeople,
    required this.topTags,
    required this.averageMemoriesPerDay,
    required this.reminderCompletionRate,
    required this.averageReminderDelay,
  });

  /// Factory constructor providing default zero/empty values.
  factory LifeInsights.empty() {
    return const LifeInsights(
      totalMemories: 0,
      todayMemories: 0,
      yesterdayMemories: 0,
      weeklyMemories: 0,
      monthlyMemories: 0,
      completedReminders: 0,
      upcomingReminders: 0,
      missedReminders: 0,
      currentStreak: 0,
      longestStreak: 0,
      dominantCategory: 'None',
      busiestHour: -1,
      busiestWeekday: 'None',
      busiestMonth: 'None',
      categoryDistribution: {},
      hourlyDistribution: {},
      weekdayDistribution: {},
      monthlyDistribution: {},
      topKeywords: [],
      topPeople: [],
      topTags: [],
      averageMemoriesPerDay: 0.0,
      reminderCompletionRate: 0.0,
      averageReminderDelay: 0.0,
    );
  }

  LifeInsights copyWith({
    int? totalMemories,
    int? todayMemories,
    int? yesterdayMemories,
    int? weeklyMemories,
    int? monthlyMemories,
    int? completedReminders,
    int? upcomingReminders,
    int? missedReminders,
    int? currentStreak,
    int? longestStreak,
    String? dominantCategory,
    int? busiestHour,
    String? busiestWeekday,
    String? busiestMonth,
    Map<String, int>? categoryDistribution,
    Map<int, int>? hourlyDistribution,
    Map<String, int>? weekdayDistribution,
    Map<String, int>? monthlyDistribution,
    List<String>? topKeywords,
    List<String>? topPeople,
    List<String>? topTags,
    double? averageMemoriesPerDay,
    double? reminderCompletionRate,
    double? averageReminderDelay,
  }) {
    return LifeInsights(
      totalMemories: totalMemories ?? this.totalMemories,
      todayMemories: todayMemories ?? this.todayMemories,
      yesterdayMemories: yesterdayMemories ?? this.yesterdayMemories,
      weeklyMemories: weeklyMemories ?? this.weeklyMemories,
      monthlyMemories: monthlyMemories ?? this.monthlyMemories,
      completedReminders: completedReminders ?? this.completedReminders,
      upcomingReminders: upcomingReminders ?? this.upcomingReminders,
      missedReminders: missedReminders ?? this.missedReminders,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      dominantCategory: dominantCategory ?? this.dominantCategory,
      busiestHour: busiestHour ?? this.busiestHour,
      busiestWeekday: busiestWeekday ?? this.busiestWeekday,
      busiestMonth: busiestMonth ?? this.busiestMonth,
      categoryDistribution: categoryDistribution ?? this.categoryDistribution,
      hourlyDistribution: hourlyDistribution ?? this.hourlyDistribution,
      weekdayDistribution: weekdayDistribution ?? this.weekdayDistribution,
      monthlyDistribution: monthlyDistribution ?? this.monthlyDistribution,
      topKeywords: topKeywords ?? this.topKeywords,
      topPeople: topPeople ?? this.topPeople,
      topTags: topTags ?? this.topTags,
      averageMemoriesPerDay: averageMemoriesPerDay ?? this.averageMemoriesPerDay,
      reminderCompletionRate: reminderCompletionRate ?? this.reminderCompletionRate,
      averageReminderDelay: averageReminderDelay ?? this.averageReminderDelay,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeInsights &&
        other.totalMemories == totalMemories &&
        other.todayMemories == todayMemories &&
        other.yesterdayMemories == yesterdayMemories &&
        other.weeklyMemories == weeklyMemories &&
        other.monthlyMemories == monthlyMemories &&
        other.completedReminders == completedReminders &&
        other.upcomingReminders == upcomingReminders &&
        other.missedReminders == missedReminders &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.dominantCategory == dominantCategory &&
        other.busiestHour == busiestHour &&
        other.busiestWeekday == busiestWeekday &&
        other.busiestMonth == busiestMonth &&
        mapEquals(other.categoryDistribution, categoryDistribution) &&
        mapEquals(other.hourlyDistribution, hourlyDistribution) &&
        mapEquals(other.weekdayDistribution, weekdayDistribution) &&
        mapEquals(other.monthlyDistribution, monthlyDistribution) &&
        listEquals(other.topKeywords, topKeywords) &&
        listEquals(other.topPeople, topPeople) &&
        listEquals(other.topTags, topTags) &&
        other.averageMemoriesPerDay == averageMemoriesPerDay &&
        other.reminderCompletionRate == reminderCompletionRate &&
        other.averageReminderDelay == averageReminderDelay;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      totalMemories,
      todayMemories,
      yesterdayMemories,
      weeklyMemories,
      monthlyMemories,
      completedReminders,
      upcomingReminders,
      missedReminders,
      currentStreak,
      longestStreak,
      dominantCategory,
      busiestHour,
      busiestWeekday,
      busiestMonth,
      categoryDistribution,
      hourlyDistribution,
      weekdayDistribution,
      monthlyDistribution,
      topKeywords,
      topPeople,
      topTags,
      averageMemoriesPerDay,
      reminderCompletionRate,
      averageReminderDelay,
    ]);
  }
}
