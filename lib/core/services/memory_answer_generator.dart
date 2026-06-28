import '../../features/memories/domain/entities/memory.dart';
import 'intent_parser.dart';

class MemoryAnswerGenerator {
  static String generate({
    required MemoryBrainIntent intent,
    required List<Memory> memories,
    required String query,
    int longestStreakVal = 0,
    String? mostActiveCategoryName,
    int mostActiveCategoryCount = 0,
    int completedCount = 0,
    int upcomingCount = 0,
    int missedCount = 0,
    double completionRate = 0.0,
    String? dominantCategory,
  }) {
    if (memories.isEmpty &&
        intent != MemoryBrainIntent.productivityQuery &&
        intent != MemoryBrainIntent.statisticsQuery) {
      return "I couldn't find anything related to that. Try asking about another day, category, or reminder.";
    }

    final count = memories.length;

    switch (intent) {
      case MemoryBrainIntent.todaySummary:
        final catText = dominantCategory != null ? ", mostly related to $dominantCategory" : "";
        final remText = completedCount > 0
            ? ". You also completed $completedCount reminders"
            : (upcomingCount > 0 ? ". You have $upcomingCount upcoming reminders scheduled" : "");
        return "You captured $count ${count == 1 ? "memory" : "memories"} today$catText$remText.";

      case MemoryBrainIntent.yesterdaySummary:
        final catText = dominantCategory != null ? ", focusing on $dominantCategory" : "";
        final remText = completedCount > 0
            ? ". You completed $completedCount reminders"
            : (missedCount > 0 ? ". You missed $missedCount reminders" : "");
        return "Yesterday you saved $count ${count == 1 ? "memory" : "memories"}$catText$remText.";

      case MemoryBrainIntent.weekSummary:
        final catText = dominantCategory != null ? ", primarily in $dominantCategory" : "";
        return "This week you recorded $count ${count == 1 ? "memory" : "memories"}$catText. You successfully completed $completedCount reminders.";

      case MemoryBrainIntent.monthSummary:
        final catText = dominantCategory != null ? ", with the majority in $dominantCategory" : "";
        return "This month you gathered $count ${count == 1 ? "memory" : "memories"}$catText. You completed $completedCount reminders.";

      case MemoryBrainIntent.reminderQuery:
        return "You have $count total ${count == 1 ? "reminder" : "reminders"}: $upcomingCount upcoming, $missedCount missed, and $completedCount completed.";

      case MemoryBrainIntent.upcomingReminder:
        return "You have $upcomingCount upcoming ${upcomingCount == 1 ? "reminder" : "reminders"} scheduled. Make sure to complete them on time!";

      case MemoryBrainIntent.missedReminder:
        return "You have $missedCount missed ${missedCount == 1 ? "reminder" : "reminders"}. Reschedule or finish them to stay on track.";

      case MemoryBrainIntent.completedReminder:
        return "You have completed $completedCount ${completedCount == 1 ? "reminder" : "reminders"} successfully. Keep up the great momentum!";

      case MemoryBrainIntent.categoryQuery:
        final catName = dominantCategory ?? query;
        return "I found $count ${count == 1 ? "memory" : "memories"} related to $catName. You have $completedCount completed and $upcomingCount upcoming reminders in this area.";

      case MemoryBrainIntent.timeQuery:
        final catText = dominantCategory != null ? ", focusing mostly on $dominantCategory" : "";
        return "During that time period, you logged $count ${count == 1 ? "memory" : "memories"}$catText. You completed $completedCount reminders.";

      case MemoryBrainIntent.productivityQuery:
        return "Your local brain productivity report: you completed $completedCount reminders with a completion rate of ${completionRate.toStringAsFixed(0)}%. Your longest streak of completed reminders is $longestStreakVal days.";

      case MemoryBrainIntent.timelineQuery:
        final catText = dominantCategory != null ? ", primarily categorized under $dominantCategory" : "";
        return "Your timeline has $count ${count == 1 ? "memory" : "memories"}$catText. You completed $completedCount reminders.";

      case MemoryBrainIntent.statisticsQuery:
        final activeCat = mostActiveCategoryName ?? "None";
        return "You have captured $count total ${count == 1 ? "memory" : "memories"} since you started using MemoryOS. Your most active category is $activeCat with $mostActiveCategoryCount entries.";

      case MemoryBrainIntent.unknown:
        return "I found $count ${count == 1 ? "memory" : "memories"} matching \"$query\". Here's a quick overview of what you saved.";
    }
  }
}
