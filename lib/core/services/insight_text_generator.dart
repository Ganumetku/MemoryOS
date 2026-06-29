import '../models/life_insights.dart';
import '../models/productivity_snapshot.dart';
import '../models/generated_insight.dart';

/// Natural language processor converting analytics metrics into human insights.
class InsightTextGenerator {
  /// Resolves clean readable focus name, renaming empty or 'Other' fallbacks.
  String _getCleanCategory(String category) {
    if (category == 'None' || category.toLowerCase().trim() == 'other') {
      return 'Daily Life';
    }
    return category;
  }

  GeneratedInsight generateDailySummary(LifeInsights insights, ProductivitySnapshot snapshot) {
    if (insights.totalMemories == 0) {
      return const GeneratedInsight(
        text: 'Start capturing your first memory to unlock AI insights!',
        type: 'daily',
      );
    }
    if (insights.todayMemories == 0) {
      return const GeneratedInsight(
        text: 'No memories recorded today. Capture a moment to start summarizing your day!',
        type: 'daily',
      );
    }

    final cleanCat = _getCleanCategory(insights.dominantCategory);
    final countText = insights.todayMemories == 1 ? '1 memory' : '${insights.todayMemories} memories';
    final text = 'Today you captured $countText. Most of your focus was on $cleanCat, maintaining a ${snapshot.overallMood.toLowerCase()} pace.';

    return GeneratedInsight(text: text, type: 'daily');
  }

  GeneratedInsight generateWeeklySummary(LifeInsights insights, ProductivitySnapshot snapshot) {
    if (insights.totalMemories == 0 || insights.weeklyMemories == 0) {
      return const GeneratedInsight(
        text: 'This week has been quiet. Record a few memories to generate a weekly summary!',
        type: 'weekly',
      );
    }

    final countText = insights.weeklyMemories == 1 ? '1 memory' : '${insights.weeklyMemories} memories';
    final streakSuffix = insights.currentStreak > 0
        ? ', keeping your journaling streak at ${insights.currentStreak} days.'
        : '.';
    final text = 'This week you recorded $countText$streakSuffix';

    return GeneratedInsight(text: text, type: 'weekly');
  }

  GeneratedInsight generateReminderInsight(LifeInsights insights) {
    final totalReminders = insights.completedReminders + insights.upcomingReminders + insights.missedReminders;
    if (insights.totalMemories == 0 || totalReminders == 0) {
      return const GeneratedInsight(
        text: 'Set your first reminder to build routine discipline.',
        type: 'reminder',
      );
    }

    if (insights.missedReminders > 0) {
      final s = insights.missedReminders == 1 ? '' : 's';
      return GeneratedInsight(
        text: 'You missed ${insights.missedReminders} reminder$s today. Consider rescheduling them.',
        type: 'reminder',
      );
    }

    if (insights.reminderCompletionRate >= 80.0) {
      return GeneratedInsight(
        text: 'Incredible discipline! You completed ${insights.reminderCompletionRate.toStringAsFixed(0)}% of your reminders.',
        type: 'reminder',
      );
    }

    return GeneratedInsight(
      text: 'You completed ${insights.completedReminders} of your reminders so far.',
      type: 'reminder',
    );
  }

  GeneratedInsight generateFocusInsight(LifeInsights insights) {
    if (insights.totalMemories == 0 || insights.dominantCategory == 'None' || insights.dominantCategory.isEmpty) {
      return const GeneratedInsight(
        text: 'Add categories or tags to your memories to see what grabs your attention.',
        type: 'focus',
      );
    }

    final cleanCat = _getCleanCategory(insights.dominantCategory);
    final count = insights.categoryDistribution[insights.dominantCategory] ?? 0;
    final percentage = insights.totalMemories > 0
        ? (count / insights.totalMemories * 100.0).toStringAsFixed(0)
        : '0';

    return GeneratedInsight(
      text: 'Your strongest focus area is $cleanCat, making up $percentage% of your entries.',
      type: 'focus',
    );
  }

  GeneratedInsight generateStreakInsight(LifeInsights insights) {
    if (insights.totalMemories == 0 || insights.currentStreak == 0) {
      return const GeneratedInsight(
        text: 'Record a memory today to start a brand new daily streak!',
        type: 'streak',
      );
    }

    return GeneratedInsight(
      text: 'You are on a ${insights.currentStreak}-day memory streak! Keep it going.',
      type: 'streak',
    );
  }

  GeneratedInsight generateKeywordInsight(LifeInsights insights) {
    if (insights.totalMemories == 0 || insights.topKeywords.isEmpty) {
      return const GeneratedInsight(
        text: 'Capture what is on your mind to build your custom keyword cloud.',
        type: 'keyword',
      );
    }

    final keyword = insights.topKeywords.first;
    // Capitalize the first letter beautifully for display
    final formattedKeyword = keyword[0].toUpperCase() + keyword.substring(1);
    return GeneratedInsight(
      text: '$formattedKeyword is becoming one of your top topics.',
      type: 'keyword',
    );
  }

  GeneratedInsight generateMoodInsight(ProductivitySnapshot snapshot) {
    String text;
    switch (snapshot.overallMood) {
      case 'Quiet':
        text = 'Your activity is quieter than usual today. Take some time to reflect.';
        break;
      case 'Overloaded':
        text = 'You have a lot of items pending. Try tackling them one by one.';
        break;
      case 'Productive':
        text = 'You are in a highly productive flow state today!';
        break;
      case 'Focused':
        text = 'Great job staying concentrated on your core topics.';
        break;
      case 'Balanced':
      default:
        text = 'You are maintaining a balanced activity level.';
        break;
    }

    return GeneratedInsight(text: text, type: 'mood');
  }

  List<GeneratedInsight> generateAllInsights(LifeInsights insights, ProductivitySnapshot snapshot) {
    return [
      generateDailySummary(insights, snapshot),
      generateWeeklySummary(insights, snapshot),
      generateReminderInsight(insights),
      generateFocusInsight(insights),
      generateStreakInsight(insights),
      generateKeywordInsight(insights),
      generateMoodInsight(snapshot),
    ];
  }
}
