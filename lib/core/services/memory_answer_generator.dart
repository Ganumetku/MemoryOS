import '../../features/memories/domain/entities/memory.dart';
import 'intent_parser.dart';

class MemoryAnswerGenerator {
  static const _fillerWords = {
    'a', 'an', 'the', 'and', 'but', 'or', 'for', 'with', 'at', 'by', 'from',
    'in', 'on', 'to', 'of', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    'my', 'your', 'his', 'her', 'their', 'our', 'have', 'has', 'had', 'do',
    'does', 'did', 'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
    'this', 'that', 'these', 'those', 'me', 'what', 'show', 'here', 'some',
    'about', 'more', 'can', 'will', 'would', 'should', 'could', 'how', 'why',
    'when', 'where', 'who', 'whom', 'which', 'whose', 'them', 'him',
    'us', 'its', 'there', 'then', 'once', 'yesterday', 'today', 'tomorrow'
  };

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
        // Case 1: Active reminders
        if (completedCount > 0 || upcomingCount > 0) {
          final catText = dominantCategory != null ? " Most of your activity was focused on $dominantCategory." : "";
          final remText = " You completed $completedCount ${completedCount == 1 ? "reminder" : "reminders"}${upcomingCount > 0 ? " and still have $upcomingCount upcoming reminder${upcomingCount == 1 ? "" : "s"}" : ""}.";
          return "You captured $count ${count == 1 ? "memory" : "memories"} today.$catText$remText";
        }
        // Case 2: Productive day without reminders
        if (count >= 4) {
          final catText = dominantCategory != null ? " Most were related to $dominantCategory." : "";
          return "You stayed productive today by saving $count memories.$catText";
        }
        // Case 3: Quieter day
        return "You recorded $count ${count == 1 ? "memory" : "memories"} today${dominantCategory != null ? " focusing primarily on $dominantCategory" : ""}, but didn't create any reminders.";

      case MemoryBrainIntent.yesterdaySummary:
        if (count <= 2) {
          final catText = dominantCategory != null ? " Most were related to $dominantCategory." : "";
          return "Yesterday was a quieter day. You recorded only $count ${count == 1 ? "memory" : "memories"}.$catText No reminders were missed.";
        } else {
          final catText = dominantCategory != null ? " Most of your focus was on $dominantCategory." : "";
          final remText = completedCount > 0
              ? " You successfully finished $completedCount reminders."
              : " No reminders were missed.";
          return "Yesterday you saved $count memories.$catText$remText";
        }

      case MemoryBrainIntent.weekSummary:
        // Extract top title keyword dynamically
        final wordCounts = <String, int>{};
        for (final m in memories) {
          final words = m.title.toLowerCase().split(RegExp(r'\s+'));
          for (final w in words) {
            final clean = w.replaceAll(RegExp(r'[^\w]'), '');
            if (clean.length > 3 && !_fillerWords.contains(clean)) {
              wordCounts[clean] = (wordCounts[clean] ?? 0) + 1;
            }
          }
        }
        String? topKeyword;
        int maxCount = 0;
        wordCounts.forEach((word, cnt) {
          if (cnt > maxCount) {
            maxCount = cnt;
            topKeyword = word[0].toUpperCase() + word.substring(1);
          }
        });

        final mostAbout = (topKeyword != null && dominantCategory != null)
            ? " Most were about $topKeyword and $dominantCategory."
            : (dominantCategory != null ? " Most were related to $dominantCategory." : "");

        final remText = " You completed $completedCount ${completedCount == 1 ? "reminder" : "reminders"} and missed $missedCount.";
        return "This week you captured $count ${count == 1 ? "memory" : "memories"}.$mostAbout$remText";

      case MemoryBrainIntent.monthSummary:
        final catText = dominantCategory != null ? ", with the majority in $dominantCategory" : "";
        return "This month you gathered $count ${count == 1 ? "memory" : "memories"}$catText. You completed $completedCount reminders.";

      case MemoryBrainIntent.reminderQuery:
        return "You have $count total ${count == 1 ? "reminder" : "reminders"}: $upcomingCount upcoming, $missedCount missed, and $completedCount completed.";

      case MemoryBrainIntent.upcomingReminder:
        final upcomingList = memories.where((m) => m.reminderAt != null && m.reminderAt!.isAfter(DateTime.now()) && !m.tags.contains('completed_reminder')).toList();
        upcomingList.sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
        if (upcomingList.isNotEmpty) {
          final closest = upcomingList.first;
          final timeStr = _formatTime(closest.reminderAt!);
          return "You still have an upcoming reminder later today. Remember to ${closest.title} at $timeStr.";
        }
        return "You have $count upcoming reminders scheduled. Make sure to complete them on time!";

      case MemoryBrainIntent.missedReminder:
        final missedList = memories.where((m) => m.reminderAt != null && m.reminderAt!.isBefore(DateTime.now()) && !m.tags.contains('completed_reminder')).toList();
        missedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final title = missedList.isNotEmpty ? missedList.first.title : 'your task';
        return "You missed your reminder to $title. You can either reschedule it or mark it as completed if you already finished it.";

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
        final capQuery = query.isNotEmpty ? query[0].toUpperCase() + query.substring(1) : "related";
        return "I found $count ${count == 1 ? "memory" : "memories"} matching \"$query\". You have $count connected $capQuery memories.";
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$displayHour:$min $suffix";
  }
}
