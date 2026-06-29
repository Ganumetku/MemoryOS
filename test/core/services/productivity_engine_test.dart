import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/models/life_insights.dart';
import 'package:memory_os/core/services/productivity_engine.dart';

void main() {
  group('ProductivityEngine Tests', () {
    late ProductivityEngine engine;

    setUp(() {
      engine = ProductivityEngine();
    });

    test('empty insights produce zeroed snapshot and quiet mood', () {
      final insights = LifeInsights.empty();
      final snapshot = engine.calculate(insights);

      expect(snapshot.productivityScore, equals(0.0));
      expect(snapshot.focusScore, equals(0.0));
      expect(snapshot.consistencyScore, equals(0.0));
      expect(snapshot.reminderDisciplineScore, equals(0.0));
      expect(snapshot.memoryGrowthScore, equals(0.0));
      expect(snapshot.overallMood, equals('Quiet'));
    });

    test('score ranges stay strictly 0-100', () {
      // Create high-activity inputs
      final insights = const LifeInsights(
        totalMemories: 100,
        todayMemories: 50,
        yesterdayMemories: 20,
        weeklyMemories: 80,
        monthlyMemories: 90,
        completedReminders: 40,
        upcomingReminders: 10,
        missedReminders: 0,
        currentStreak: 50,
        longestStreak: 100,
        dominantCategory: 'Work',
        busiestHour: 10,
        busiestWeekday: 'Monday',
        busiestMonth: 'July',
        categoryDistribution: {'Work': 100},
        hourlyDistribution: {},
        weekdayDistribution: {},
        monthlyDistribution: {},
        topKeywords: [],
        topPeople: [],
        topTags: [],
        averageMemoriesPerDay: 5.0,
        reminderCompletionRate: 100.0,
        averageReminderDelay: 0.0,
      );

      final snapshot = engine.calculate(insights);
      expect(snapshot.productivityScore, inInclusiveRange(0.0, 100.0));
      expect(snapshot.focusScore, inInclusiveRange(0.0, 100.0));
      expect(snapshot.consistencyScore, inInclusiveRange(0.0, 100.0));
      expect(snapshot.reminderDisciplineScore, inInclusiveRange(0.0, 100.0));
      expect(snapshot.memoryGrowthScore, inInclusiveRange(0.0, 100.0));
    });

    test('overloaded mood is triggered correctly', () {
      final insights = const LifeInsights(
        totalMemories: 20,
        todayMemories: 6,
        yesterdayMemories: 0,
        weeklyMemories: 16,
        monthlyMemories: 20,
        completedReminders: 1,
        upcomingReminders: 0,
        missedReminders: 4,
        currentStreak: 1,
        longestStreak: 1,
        dominantCategory: 'Work',
        busiestHour: 9,
        busiestWeekday: 'Tuesday',
        busiestMonth: 'June',
        categoryDistribution: {},
        hourlyDistribution: {},
        weekdayDistribution: {},
        monthlyDistribution: {},
        topKeywords: [],
        topPeople: [],
        topTags: [],
        averageMemoriesPerDay: 1.0,
        reminderCompletionRate: 20.0,
        averageReminderDelay: 0.0,
      );

      final snapshot = engine.calculate(insights);
      expect(snapshot.overallMood, equals('Overloaded'));
    });

    test('productive and focused moods are detected correctly', () {
      final insightsProductive = const LifeInsights(
        totalMemories: 5,
        todayMemories: 3,
        yesterdayMemories: 0,
        weeklyMemories: 5,
        monthlyMemories: 5,
        completedReminders: 1,
        upcomingReminders: 0,
        missedReminders: 0,
        currentStreak: 1,
        longestStreak: 1,
        dominantCategory: 'Work',
        busiestHour: 12,
        busiestWeekday: 'Wednesday',
        busiestMonth: 'June',
        categoryDistribution: {'Work': 2},
        hourlyDistribution: {},
        weekdayDistribution: {},
        monthlyDistribution: {},
        topKeywords: [],
        topPeople: [],
        topTags: [],
        averageMemoriesPerDay: 1.0,
        reminderCompletionRate: 100.0,
        averageReminderDelay: 0.0,
      );

      final snapshotProd = engine.calculate(insightsProductive);
      expect(snapshotProd.overallMood, equals('Productive'));

      final insightsFocused = const LifeInsights(
        totalMemories: 4,
        todayMemories: 1,
        yesterdayMemories: 0,
        weeklyMemories: 2,
        monthlyMemories: 4,
        completedReminders: 0,
        upcomingReminders: 0,
        missedReminders: 0,
        currentStreak: 1,
        longestStreak: 1,
        dominantCategory: 'Work',
        busiestHour: 10,
        busiestWeekday: 'Monday',
        busiestMonth: 'July',
        categoryDistribution: {'Work': 3}, // 3 out of 4 is 75% focus
        hourlyDistribution: {},
        weekdayDistribution: {},
        monthlyDistribution: {},
        topKeywords: [],
        topPeople: [],
        topTags: [],
        averageMemoriesPerDay: 1.0,
        reminderCompletionRate: 0.0,
        averageReminderDelay: 0.0,
      );

      final snapshotFocused = engine.calculate(insightsFocused);
      expect(snapshotFocused.overallMood, equals('Focused'));
    });

    test('missed reminders reduce productivity score', () {
      final insightsGood = const LifeInsights(
        totalMemories: 4,
        todayMemories: 2,
        yesterdayMemories: 0,
        weeklyMemories: 4,
        monthlyMemories: 4,
        completedReminders: 2,
        upcomingReminders: 0,
        missedReminders: 0,
        currentStreak: 1,
        longestStreak: 1,
        dominantCategory: 'Work',
        busiestHour: 10,
        busiestWeekday: 'Monday',
        busiestMonth: 'July',
        categoryDistribution: {},
        hourlyDistribution: {},
        weekdayDistribution: {},
        monthlyDistribution: {},
        topKeywords: [],
        topPeople: [],
        topTags: [],
        averageMemoriesPerDay: 1.0,
        reminderCompletionRate: 100.0,
        averageReminderDelay: 0.0,
      );

      final insightsBad = insightsGood.copyWith(
        missedReminders: 3,
        reminderCompletionRate: 40.0,
      );

      final scoreGood = engine.calculate(insightsGood).productivityScore;
      final scoreBad = engine.calculate(insightsBad).productivityScore;

      expect(scoreBad, lessThan(scoreGood));
    });

    test('streak improves consistency score', () {
      final insightsShort = LifeInsights.empty().copyWith(
        totalMemories: 5,
        currentStreak: 1,
      );
      final insightsLong = LifeInsights.empty().copyWith(
        totalMemories: 5,
        currentStreak: 5,
      );

      final shortScore = engine.calculate(insightsShort).consistencyScore;
      final longScore = engine.calculate(insightsLong).consistencyScore;

      expect(shortScore, equals(20.0));
      expect(longScore, equals(100.0));
    });
  });
}
