import '../models/life_insights.dart';
import '../models/productivity_snapshot.dart';

/// Calculation engine for user productivity scoring and mood analysis.
class ProductivityEngine {
  ProductivitySnapshot calculate(LifeInsights insights) {
    if (insights.totalMemories == 0) {
      return ProductivitySnapshot.zero();
    }

    // 1. Memory Growth Score (Weekly captures benchmarked against target of 7 memories/week)
    final memoryGrowthScore = (insights.weeklyMemories / 7.0 * 100.0).clamp(0.0, 100.0);

    // 2. Focus Score (Dominant category concentration)
    double focusScore = 0.0;
    if (insights.dominantCategory != 'None' && insights.dominantCategory.isNotEmpty) {
      final dominantCount = insights.categoryDistribution[insights.dominantCategory] ?? 0;
      focusScore = (dominantCount / insights.totalMemories * 100.0).clamp(0.0, 100.0);
    }

    // 3. Consistency Score (Based on current journaling streak)
    final consistencyScore = (insights.currentStreak * 20.0).clamp(0.0, 100.0);

    // 4. Reminder Discipline Score
    // Higher completion rate is good, penalty applies for completion delay. If no reminders, defaults to 100.
    final totalReminders = insights.completedReminders + insights.upcomingReminders + insights.missedReminders;
    double reminderDisciplineScore = 100.0;
    if (totalReminders > 0) {
      final delayPenalty = (insights.averageReminderDelay / 60.0).clamp(0.0, 20.0);
      reminderDisciplineScore = (insights.reminderCompletionRate - delayPenalty).clamp(0.0, 100.0);
    }

    // 5. Productivity Score
    // Combines memory counts (credit for captures) + reminder completion, penalized by missed reminders.
    final countCredit = (insights.todayMemories * 25.0).clamp(0.0, 50.0) +
                        (insights.weeklyMemories * 5.0).clamp(0.0, 30.0);
    final reminderCredit = totalReminders > 0 ? (insights.reminderCompletionRate * 0.2) : 20.0;
    final missedPenalty = insights.missedReminders * 10.0;
    final productivityScore = (countCredit + reminderCredit - missedPenalty).clamp(0.0, 100.0);

    // 6. Overall Mood Categorization
    String overallMood = 'Balanced';
    if ((insights.todayMemories >= 5 || insights.weeklyMemories >= 15) && insights.missedReminders >= 3) {
      overallMood = 'Overloaded';
    } else if (insights.todayMemories == 0 && insights.weeklyMemories < 3 && insights.completedReminders == 0) {
      overallMood = 'Quiet';
    } else if (productivityScore >= 70.0) {
      overallMood = 'Productive';
    } else if (focusScore >= 70.0 && productivityScore >= 50.0) {
      overallMood = 'Focused';
    }

    return ProductivitySnapshot(
      productivityScore: productivityScore,
      focusScore: focusScore,
      consistencyScore: consistencyScore,
      reminderDisciplineScore: reminderDisciplineScore,
      memoryGrowthScore: memoryGrowthScore,
      overallMood: overallMood,
    );
  }
}
