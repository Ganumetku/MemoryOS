import '../../../features/memories/domain/entities/memory.dart';

class TimelineSummaryData {
  final String naturalSummary;
  final List<String> insights;
  final String emoji;
  final double productivityScore;

  TimelineSummaryData({
    required this.naturalSummary,
    required this.insights,
    required this.emoji,
    required this.productivityScore,
  });
}

class TimelineSummaryService {
  static const _fillerWords = {
    'a', 'an', 'the', 'and', 'but', 'or', 'for', 'with', 'at', 'by', 'from',
    'in', 'on', 'to', 'of', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    'my', 'your', 'his', 'her', 'their', 'our', 'have', 'has', 'had', 'do',
    'does', 'did', 'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
    'this', 'that', 'these', 'those', 'me', 'what', 'show'
  };

  static TimelineSummaryData generate({
    required List<Memory> memories,
    required String period, // "Today", "Yesterday", "Last 7 Days", "This Month", "All Time"
  }) {
    final now = DateTime.now();

    // 1. Filter memories by selected period
    List<Memory> periodMemories = [];
    switch (period) {
      case 'Today':
        periodMemories = memories.where((m) => _isSameDay(m.createdAt, now)).toList();
        break;
      case 'Yesterday':
        periodMemories = memories.where((m) => _isSameDay(m.createdAt, now.subtract(const Duration(days: 1)))).toList();
        break;
      case 'Last 7 Days':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        periodMemories = memories.where((m) => m.createdAt.isAfter(sevenDaysAgo)).toList();
        break;
      case 'This Month':
        periodMemories = memories.where((m) => m.createdAt.year == now.year && m.createdAt.month == now.month).toList();
        break;
      case 'All Time':
      default:
        periodMemories = memories;
        break;
    }

    if (periodMemories.isEmpty) {
      final emoji = _getPeriodEmoji(period);
      return TimelineSummaryData(
        naturalSummary: period == 'Today'
            ? "You haven't captured any memories today. Log a new thought, guide, or reminder to start your day!"
            : "No memories recorded during this period.",
        insights: [
          "Save memories to generate personalized local insights.",
          if (memories.isNotEmpty) "Try exploring other periods above."
        ],
        emoji: emoji,
        productivityScore: 0.0,
      );
    }

    // 2. Calculations for the selected period
    final memoryCount = periodMemories.length;
    final reminders = periodMemories.where((m) => m.reminderAt != null).toList();
    final completedReminders = reminders.where((m) => m.tags.contains('completed_reminder')).toList();
    final missedReminders = reminders.where((m) => m.reminderAt != null && m.reminderAt!.isBefore(now) && !m.tags.contains('completed_reminder')).toList();

    final completedCount = completedReminders.length;
    final missedCount = missedReminders.length;
    final totalFinished = completedCount + missedCount;
    final completionRate = totalFinished > 0 ? (completedCount / totalFinished * 100) : 0.0;

    // Top Category
    final categoryCounts = <String, int>{};
    for (final m in periodMemories) {
      categoryCounts[m.type] = (categoryCounts[m.type] ?? 0) + 1;
    }
    String topCategory = "None";
    int maxCatCount = 0;
    categoryCounts.forEach((cat, count) {
      if (count > maxCatCount) {
        maxCatCount = count;
        topCategory = cat;
      }
    });

    // Top Keywords
    final keywordCounts = <String, int>{};
    for (final m in periodMemories) {
      final words = m.title.toLowerCase().split(RegExp(r'\s+'));
      for (final w in words) {
        final clean = w.replaceAll(RegExp(r'[^\w]'), '');
        if (clean.length > 2 && !_fillerWords.contains(clean)) {
          keywordCounts[clean] = (keywordCounts[clean] ?? 0) + 1;
        }
      }
    }
    String topKeyword = "None";
    int maxKeywordCount = 0;
    keywordCounts.forEach((kw, count) {
      if (count > maxKeywordCount) {
        maxKeywordCount = count;
        topKeyword = kw;
      }
    });
    if (topKeyword != "None") {
      topKeyword = topKeyword[0].toUpperCase() + topKeyword.substring(1);
    }

    // Most Active Day (Name of weekday)
    final weekdayCounts = <int, int>{};
    for (final m in periodMemories) {
      weekdayCounts[m.createdAt.weekday] = (weekdayCounts[m.createdAt.weekday] ?? 0) + 1;
    }
    int activeWeekday = 1;
    int maxWeekdayCount = 0;
    weekdayCounts.forEach((day, count) {
      if (count > maxWeekdayCount) {
        maxWeekdayCount = count;
        activeWeekday = day;
      }
    });
    final activeDayName = _getWeekdayName(activeWeekday);

    // Most Active Hour
    final hourCounts = <int, int>{};
    for (final m in periodMemories) {
      hourCounts[m.createdAt.hour] = (hourCounts[m.createdAt.hour] ?? 0) + 1;
    }
    int activeHour = 12;
    int maxHourCount = 0;
    hourCounts.forEach((hr, count) {
      if (count > maxHourCount) {
        maxHourCount = count;
        activeHour = hr;
      }
    });
    final activeHourName = _formatHour(activeHour);

    // Longest Streak
    final longestStreakVal = _calculateLongestStreak(memories);

    // Productivity score
    final double productivityScore = (completionRate * 0.7 + (memoryCount.clamp(0, 10) * 10) * 0.3).clamp(0, 100);

    // 3. Natural Summary compilation
    String naturalSummary = "";
    final emoji = _getPeriodEmoji(period);

    switch (period) {
      case 'Today':
        final catText = topCategory != "None" ? "Most were related to $topCategory." : "";
        final remText = completedCount > 0 || missedCount > 0
            ? "You completed $completedCount reminders and missed $missedCount."
            : "You had no reminder deadlines today.";
        final hourText = maxHourCount > 0 ? "Your busiest time was $activeHourName." : "";
        final prodText = productivityScore > 70
            ? "Overall today was productive."
            : (productivityScore > 40 ? "Overall today was moderate." : "Overall today was quiet.");
        naturalSummary = "Today you captured $memoryCount ${memoryCount == 1 ? "memory" : "memories"}.\n\n$catText\n\n$remText\n\n$hourText\n\n$prodText";
        break;

      case 'Yesterday':
        final catText = topCategory != "None" ? "Most were $topCategory related." : "";
        final remText = missedCount > 0
            ? "You completed $completedCount reminders and missed $missedCount."
            : "No reminders were missed.";
        final activityLevel = memoryCount > 5 ? "a very active day" : (memoryCount > 2 ? "a steady day" : "a quieter day");
        naturalSummary = "Yesterday was $activityLevel.\n\nYou recorded $memoryCount ${memoryCount == 1 ? "memory" : "memories"}.\n\n$catText\n\n$remText";
        break;

      case 'Last 7 Days':
        final catText = topCategory != "None" ? "$topCategory was your most active category." : "";
        final streakText = longestStreakVal > 0 ? "You stayed consistent for $longestStreakVal days." : "";
        final dayText = maxWeekdayCount > 0 ? "Your busiest day of the week was $activeDayName." : "";
        naturalSummary = "This week you captured $memoryCount ${memoryCount == 1 ? "memory" : "memories"}.\n\n$catText\n\nYou created ${reminders.length} reminders.\n\nReminder completion reached ${completionRate.toStringAsFixed(0)}%.\n\n$dayText\n\n$streakText";
        break;

      case 'This Month':
        final catText = topCategory != "None" ? "Your most common category was $topCategory." : "";
        final kwText = topKeyword != "None" ? "Most active keyword: $topKeyword." : "";
        naturalSummary = "This month you stored $memoryCount ${memoryCount == 1 ? "memory" : "memories"}.\n\n$catText\n\n$kwText\n\nYou completed $completedCount reminders.\n\nGreat consistency.";
        break;

      case 'All Time':
      default:
        final catText = topCategory != "None" ? "Your favorite category is $topCategory." : "";
        final kwText = topKeyword != "None" ? "Common keyword: $topKeyword." : "";
        final streakText = longestStreakVal > 0 ? "Your longest completion streak is $longestStreakVal days." : "";
        naturalSummary = "In total, you have captured $memoryCount ${memoryCount == 1 ? "memory" : "memories"}.\n\n$catText\n\n$kwText\n\nYou completed $completedCount reminders.\n\n$streakText";
        break;
    }

    // 4. Generate local insights
    final insights = <String>[];

    // Insight 1: Time of day pattern
    final morningCount = memories.where((m) => m.createdAt.hour >= 6 && m.createdAt.hour < 12).length;
    final afternoonCount = memories.where((m) => m.createdAt.hour >= 12 && m.createdAt.hour < 18).length;
    final eveningCount = memories.where((m) => m.createdAt.hour >= 18 && m.createdAt.hour < 22).length;
    final nightCount = memories.where((m) => m.createdAt.hour >= 22 || m.createdAt.hour < 6).length;

    if (morningCount >= afternoonCount && morningCount >= eveningCount && morningCount >= nightCount) {
      insights.add("Morning is your most productive time. 🌞");
    } else if (afternoonCount >= morningCount && afternoonCount >= eveningCount && afternoonCount >= nightCount) {
      insights.add("Afternoon is when you capture most memories. 🌞");
    } else if (eveningCount >= morningCount && eveningCount >= afternoonCount && eveningCount >= nightCount) {
      insights.add("You save most of your notes in the evening. 🌙");
    } else {
      insights.add("You usually save ideas at night. 🌙");
    }

    // Insight 2: Category trends (Health)
    final healthThisWeek = memories.where((m) => m.type.toLowerCase() == 'health' && m.createdAt.isAfter(now.subtract(const Duration(days: 7)))).length;
    final healthPrevWeek = memories.where((m) => m.type.toLowerCase() == 'health' && m.createdAt.isAfter(now.subtract(const Duration(days: 14))) && m.createdAt.isBefore(now.subtract(const Duration(days: 7)))).length;
    if (healthThisWeek > healthPrevWeek) {
      insights.add("Health memories increased this week. 📈");
    } else if (topCategory != "None") {
      insights.add("$topCategory is your most active focus area. 💼");
    }

    // Insight 3: Inactivity warning
    final sortedByDate = List<Memory>.from(memories);
    sortedByDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (sortedByDate.isNotEmpty) {
      final daysDiff = now.difference(sortedByDate.first.createdAt).inDays;
      if (daysDiff >= 2) {
        insights.add("You haven't captured anything for two days. 🧠");
      }
    }

    return TimelineSummaryData(
      naturalSummary: naturalSummary,
      insights: insights,
      emoji: emoji,
      productivityScore: productivityScore,
    );
  }

  static bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  static String _getPeriodEmoji(String period) {
    switch (period) {
      case 'Today':
        return '🌞';
      case 'Yesterday':
        return '🌙';
      case 'Last 7 Days':
        return '📈';
      case 'This Month':
        return '🧠';
      case 'All Time':
      default:
        return '🔥';
    }
  }

  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return 'Day';
    }
  }

  static String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }

  static int _calculateLongestStreak(List<Memory> memories) {
    final completedDates = memories
        .where((m) => m.tags.contains('completed_reminder'))
        .map((m) {
          final date = m.reminderAt ?? m.updatedAt;
          return DateTime(date.year, date.month, date.day);
        })
        .toSet()
        .toList();
    if (completedDates.isEmpty) return 0;
    completedDates.sort();

    int maxStreak = 1;
    int currentStreak = 1;
    for (int i = 0; i < completedDates.length - 1; i++) {
      final diff = completedDates[i + 1].difference(completedDates[i]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }
    return maxStreak;
  }
}
