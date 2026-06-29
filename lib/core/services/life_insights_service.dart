import '../models/life_insights.dart';
import '../../features/memories/domain/entities/memory.dart';
import '../../features/memories/domain/repositories/memory_repository.dart';
import '../parser/smart_parser.dart';

/// Contract definition for the AI Life Insights Engine.
abstract class LifeInsightsService {
  Future<LifeInsights> generateInsights();
  void invalidateCache();
}

/// Local implementation of [LifeInsightsService] doing fully offline computations.
class LocalLifeInsightsService implements LifeInsightsService {
  final MemoryRepository _repository;
  LifeInsights? _cachedInsights;

  LocalLifeInsightsService(this._repository);

  @override
  Future<LifeInsights> generateInsights() async {
    if (_cachedInsights != null) {
      return _cachedInsights!;
    }

    final result = await _repository.getMemories();
    return result.fold(
      (failure) => LifeInsights.empty(),
      (memories) {
        final insights = _calculate(memories);
        _cachedInsights = insights;
        return insights;
      },
    );
  }

  @override
  void invalidateCache() {
    _cachedInsights = null;
  }

  LifeInsights _calculate(List<Memory> memories) {
    if (memories.isEmpty) {
      return LifeInsights.empty();
    }

    final now = DateTime.now();

    // 1. Memory counts by period
    int todayCount = 0;
    int yesterdayCount = 0;
    int weeklyCount = 0;
    int monthlyCount = 0;

    final todayOnly = DateTime(now.year, now.month, now.day);

    for (final m in memories) {
      final dt = m.createdAt;
      final dtOnly = DateTime(dt.year, dt.month, dt.day);
      final daysDiff = todayOnly.difference(dtOnly).inDays;

      if (daysDiff == 0) {
        todayCount++;
      } else if (daysDiff == 1) {
        yesterdayCount++;
      }

      if (daysDiff >= 0 && daysDiff < 7) {
        weeklyCount++;
      }

      if (dt.year == now.year && dt.month == now.month) {
        monthlyCount++;
      }
    }

    // 2. Reminder stats
    int completedReminders = 0;
    int upcomingReminders = 0;
    int missedReminders = 0;
    final List<Memory> reminders = [];

    for (final m in memories) {
      if (m.reminderAt != null) {
        reminders.add(m);
        if (m.tags.contains('completed_reminder')) {
          completedReminders++;
        } else if (m.reminderAt!.isBefore(now)) {
          missedReminders++;
        } else {
          upcomingReminders++;
        }
      }
    }

    final totalReminders = reminders.length;
    final reminderCompletionRate = totalReminders > 0
        ? (completedReminders / totalReminders) * 100.0
        : 0.0;

    double averageReminderDelay = 0.0;
    final completedWithReminder = reminders
        .where((r) => r.tags.contains('completed_reminder') && r.reminderAt != null)
        .toList();

    if (completedWithReminder.isNotEmpty) {
      double totalDelay = 0.0;
      for (final r in completedWithReminder) {
        final diff = r.updatedAt.difference(r.reminderAt!).inMinutes;
        totalDelay += diff > 0 ? diff : 0.0;
      }
      averageReminderDelay = totalDelay / completedWithReminder.length;
    }

    // 3. Category analytics
    final categoryDistribution = <String, int>{};
    for (final m in memories) {
      final cat = m.type;
      categoryDistribution[cat] = (categoryDistribution[cat] ?? 0) + 1;
    }

    String dominantCategory = 'None';
    if (categoryDistribution.isNotEmpty) {
      final sortedCats = categoryDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      dominantCategory = sortedCats.first.key;
    }

    // 4. Keyword analytics
    final topKeywords = _extractTopKeywords(memories);

    // 5. Time analytics
    final hourlyDistribution = <int, int>{};
    final weekdayDistribution = <String, int>{};
    final monthlyDistribution = <String, int>{};

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    for (final m in memories) {
      final hour = m.createdAt.hour;
      hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;

      final wday = weekdays[m.createdAt.weekday - 1];
      weekdayDistribution[wday] = (weekdayDistribution[wday] ?? 0) + 1;

      final mon = months[m.createdAt.month - 1];
      monthlyDistribution[mon] = (monthlyDistribution[mon] ?? 0) + 1;
    }

    int busiestHour = -1;
    if (hourlyDistribution.isNotEmpty) {
      final sortedHours = hourlyDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      busiestHour = sortedHours.first.key;
    }

    String busiestWeekday = 'None';
    if (weekdayDistribution.isNotEmpty) {
      final sortedWdays = weekdayDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      busiestWeekday = sortedWdays.first.key;
    }

    String busiestMonth = 'None';
    if (monthlyDistribution.isNotEmpty) {
      final sortedMonths = monthlyDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      busiestMonth = sortedMonths.first.key;
    }

    // 6. People analytics
    final topPeople = _extractTopPeople(memories);

    // 7. Tag analytics
    final topTags = _extractTopTags(memories);

    // 8. Streak engine
    final currentStreak = _calculateCurrentStreak(memories, now);
    final longestStreak = _calculateLongestStreak(memories);

    // 9. Average activity
    final uniqueDays = memories
        .map((m) => DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day))
        .toSet()
        .length;
    final averageMemoriesPerDay = uniqueDays > 0 ? memories.length / uniqueDays : 0.0;

    return LifeInsights(
      totalMemories: memories.length,
      todayMemories: todayCount,
      yesterdayMemories: yesterdayCount,
      weeklyMemories: weeklyCount,
      monthlyMemories: monthlyCount,
      completedReminders: completedReminders,
      upcomingReminders: upcomingReminders,
      missedReminders: missedReminders,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      dominantCategory: dominantCategory,
      busiestHour: busiestHour,
      busiestWeekday: busiestWeekday,
      busiestMonth: busiestMonth,
      categoryDistribution: categoryDistribution,
      hourlyDistribution: hourlyDistribution,
      weekdayDistribution: weekdayDistribution,
      monthlyDistribution: monthlyDistribution,
      topKeywords: topKeywords,
      topPeople: topPeople,
      topTags: topTags,
      averageMemoriesPerDay: averageMemoriesPerDay,
      reminderCompletionRate: reminderCompletionRate,
      averageReminderDelay: averageReminderDelay,
    );
  }

  List<String> _extractTopKeywords(List<Memory> memories) {
    const stopWords = {
      'the', 'is', 'am', 'are', 'to', 'for', 'of', 'and', 'a', 'an',
      'i', 'me', 'my', 'please', 'remind', 'remember', 'today', 'tomorrow'
    };
    final Map<String, int> counts = {};

    for (final m in memories) {
      final text = "${m.title} ${m.content}".toLowerCase();
      final cleanedText = text.replaceAll(RegExp(r'[^\w\s]'), ' ');
      final words = cleanedText.split(RegExp(r'\s+'));

      for (final w in words) {
        final word = w.trim();
        if (word.length > 1 && !stopWords.contains(word)) {
          counts[word] = (counts[word] ?? 0) + 1;
        }
      }

      for (final tag in m.tags) {
        final cleanTag = tag.toLowerCase().trim();
        if (cleanTag.isNotEmpty &&
            !stopWords.contains(cleanTag) &&
            cleanTag != 'completed_reminder') {
          counts[cleanTag] = (counts[cleanTag] ?? 0) + 1;
        }
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    return sorted.take(10).map((e) => e.key).toList();
  }

  List<String> _extractTopPeople(List<Memory> memories) {
    final Map<String, int> counts = {};
    final parser = SmartParserImpl();

    for (final m in memories) {
      final parsedTitle = parser.parse(m.title);
      final parsedContent = parser.parse(m.content);

      if (parsedTitle.personName != null) {
        final name = _cleanPersonName(parsedTitle.personName!);
        counts[name] = (counts[name] ?? 0) + 1;
      }
      if (parsedContent.personName != null) {
        final name = _cleanPersonName(parsedContent.personName!);
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    return sorted.take(10).map((e) => e.key).toList();
  }

  String _cleanPersonName(String raw) {
    return raw.trim().split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  List<String> _extractTopTags(List<Memory> memories) {
    final Map<String, int> counts = {};

    for (final m in memories) {
      for (final tag in m.tags) {
        final cleanTag = tag.toLowerCase().trim();
        if (cleanTag.isNotEmpty && cleanTag != 'completed_reminder') {
          final formattedTag = cleanTag[0].toUpperCase() + cleanTag.substring(1);
          counts[formattedTag] = (counts[formattedTag] ?? 0) + 1;
        }
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    return sorted.take(10).map((e) => e.key).toList();
  }

  int _calculateCurrentStreak(List<Memory> memories, DateTime now) {
    final days = memories.map((m) {
      final d = m.createdAt;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final hasToday = days.contains(today);
    final hasYesterday = days.contains(yesterday);

    if (!hasToday && !hasYesterday) return 0;

    int streak = 0;
    DateTime checkDay = hasToday ? today : yesterday;

    while (true) {
      if (days.contains(checkDay)) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<Memory> memories) {
    final days = memories.map((m) {
      final d = m.createdAt;
      return DateTime(d.year, d.month, d.day);
    }).toSet().toList();

    days.sort();

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
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
