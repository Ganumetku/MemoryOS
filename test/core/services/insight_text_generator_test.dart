import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/models/life_insights.dart';
import 'package:memory_os/core/models/productivity_snapshot.dart';
import 'package:memory_os/core/services/insight_text_generator.dart';

void main() {
  group('InsightTextGenerator Tests', () {
    late InsightTextGenerator generator;

    setUp(() {
      generator = InsightTextGenerator();
    });

    test('empty insights produce onboarding text', () {
      final insights = LifeInsights.empty();
      final snapshot = ProductivitySnapshot.zero();

      final daily = generator.generateDailySummary(insights, snapshot);
      final weekly = generator.generateWeeklySummary(insights, snapshot);
      final reminder = generator.generateReminderInsight(insights);
      final focus = generator.generateFocusInsight(insights);
      final streak = generator.generateStreakInsight(insights);
      final keyword = generator.generateKeywordInsight(insights);
      final mood = generator.generateMoodInsight(snapshot);

      expect(daily.text, contains('Start capturing'));
      expect(weekly.text, contains('This week has been quiet'));
      expect(reminder.text, contains('Set your first reminder'));
      expect(focus.text, contains('Add categories or tags'));
      expect(streak.text, contains('Record a memory today'));
      expect(keyword.text, contains('Capture what is on your mind'));
      expect(mood.text, contains('Your activity is quieter than usual'));
    });

    test('dominant category is converted properly from Other to Daily Life', () {
      final insightsOther = const LifeInsights(
        totalMemories: 5,
        todayMemories: 2,
        yesterdayMemories: 0,
        weeklyMemories: 5,
        monthlyMemories: 5,
        completedReminders: 0,
        upcomingReminders: 0,
        missedReminders: 0,
        currentStreak: 1,
        longestStreak: 1,
        dominantCategory: 'Other',
        busiestHour: 10,
        busiestWeekday: 'Monday',
        busiestMonth: 'July',
        categoryDistribution: {'Other': 5},
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

      final snapshot = ProductivitySnapshot.zero();
      final daily = generator.generateDailySummary(insightsOther, snapshot);
      final focus = generator.generateFocusInsight(insightsOther);

      expect(daily.text, isNot(contains('Other')));
      expect(daily.text, contains('Daily Life'));

      expect(focus.text, isNot(contains('Other')));
      expect(focus.text, contains('Daily Life'));
    });

    test('natural insights generation are not empty and contain formatted keywords', () {
      final insights = const LifeInsights(
        totalMemories: 3,
        todayMemories: 2,
        yesterdayMemories: 0,
        weeklyMemories: 3,
        monthlyMemories: 3,
        completedReminders: 4,
        upcomingReminders: 0,
        missedReminders: 0,
        currentStreak: 2,
        longestStreak: 2,
        dominantCategory: 'Fitness',
        busiestHour: 14,
        busiestWeekday: 'Tuesday',
        busiestMonth: 'July',
        categoryDistribution: {'Fitness': 3},
        hourlyDistribution: {},
        weekdayDistribution: {},
        monthlyDistribution: {},
        topKeywords: ['flutter', 'code'],
        topPeople: [],
        topTags: [],
        averageMemoriesPerDay: 1.0,
        reminderCompletionRate: 100.0,
        averageReminderDelay: 0.0,
      );

      final snapshot = const ProductivitySnapshot(
        productivityScore: 85.0,
        focusScore: 100.0,
        consistencyScore: 40.0,
        reminderDisciplineScore: 100.0,
        memoryGrowthScore: 42.0,
        overallMood: 'Productive',
      );

      final all = generator.generateAllInsights(insights, snapshot);
      expect(all, hasLength(7));

      for (final insight in all) {
        expect(insight.text.isNotEmpty, isTrue);
      }

      // Check daily summary contents
      final daily = generator.generateDailySummary(insights, snapshot);
      expect(daily.text, contains('2 memories'));
      expect(daily.text, contains('Fitness'));
      expect(daily.text, contains('productive pace'));

      // Check keyword insight formats
      final kw = generator.generateKeywordInsight(insights);
      expect(kw.text, contains('Flutter')); // should capitalize correctly
    });
  });
}
