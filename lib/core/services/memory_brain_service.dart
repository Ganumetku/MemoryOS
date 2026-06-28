import '../../features/memories/domain/entities/memory.dart';
import 'intent_parser.dart';
import 'memory_answer_generator.dart';
import 'recall_engine_service.dart';

class MemoryBrainResult {
  final MemoryBrainIntent intent;
  final String naturalAnswer;
  final int count;
  final List<Memory> memories;
  final Map<int, double> relevanceScores;
  final String? relevantCategory;
  final String? relevantReminderStatus; // "Upcoming", "Completed", "Missed"
  final List<String> actionLabels;
  final Memory? targetMemory;

  MemoryBrainResult({
    required this.intent,
    required this.naturalAnswer,
    required this.count,
    required this.memories,
    required this.relevanceScores,
    this.relevantCategory,
    this.relevantReminderStatus,
    required this.actionLabels,
    this.targetMemory,
  });
}

class MemoryBrainService {
  final RecallEngineService _recallEngine;
  
  // Local cache map key: "query_lengthOfMemories"
  final Map<String, MemoryBrainResult> _cache = {};

  MemoryBrainService(this._recallEngine);

  /// Clears the service cache (e.g. when database changes).
  void clearCache() {
    _cache.clear();
  }

  Future<MemoryBrainResult> process({
    required String query,
    required List<Memory> memories,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return MemoryBrainResult(
        intent: MemoryBrainIntent.unknown,
        naturalAnswer: '',
        count: 0,
        memories: [],
        relevanceScores: const {},
        actionLabels: const [],
      );
    }

    final cacheKey = "${cleanQuery.toLowerCase()}_${memories.length}";
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final now = DateTime.now();
    final intent = IntentParser.parse(cleanQuery);
    List<Memory> filtered = [];
    String? category;
    String? reminderStatus;
    final actionLabels = <String>[];

    // Compute global metrics over all memories for stats/productivity reports
    final globalCompletedCount = memories.where((m) => m.tags.contains('completed_reminder')).length;
    final globalUpcomingCount = memories.where((m) => m.reminderAt != null && m.reminderAt!.isAfter(now) && !m.tags.contains('completed_reminder')).length;
    final globalMissedCount = memories.where((m) => m.reminderAt != null && m.reminderAt!.isBefore(now) && !m.tags.contains('completed_reminder')).length;
    final globalTotalReminders = globalCompletedCount + globalMissedCount;
    final globalCompletionRate = globalTotalReminders > 0 ? (globalCompletedCount / globalTotalReminders * 100) : 0.0;

    switch (intent) {
      case MemoryBrainIntent.todaySummary:
        filtered = memories.where((m) => _isSameDay(m.createdAt, now)).toList();
        break;

      case MemoryBrainIntent.yesterdaySummary:
        filtered = memories.where((m) => _isSameDay(m.createdAt, now.subtract(const Duration(days: 1)))).toList();
        break;

      case MemoryBrainIntent.weekSummary:
        final startOfWeek = now.subtract(const Duration(days: 7));
        filtered = memories.where((m) => m.createdAt.isAfter(startOfWeek)).toList();
        break;

      case MemoryBrainIntent.monthSummary:
        filtered = memories.where((m) => m.createdAt.year == now.year && m.createdAt.month == now.month).toList();
        break;

      case MemoryBrainIntent.reminderQuery:
        filtered = memories.where((m) => m.reminderAt != null).toList();
        break;

      case MemoryBrainIntent.upcomingReminder:
        filtered = memories.where((m) => m.reminderAt != null && m.reminderAt!.isAfter(now) && !m.tags.contains('completed_reminder')).toList();
        reminderStatus = "Upcoming";
        break;

      case MemoryBrainIntent.completedReminder:
        filtered = memories.where((m) => m.tags.contains('completed_reminder')).toList();
        reminderStatus = "Completed";
        break;

      case MemoryBrainIntent.missedReminder:
        filtered = memories.where((m) => m.reminderAt != null && m.reminderAt!.isBefore(now) && !m.tags.contains('completed_reminder')).toList();
        reminderStatus = "Missed";
        break;

      case MemoryBrainIntent.categoryQuery:
        final qLower = cleanQuery.toLowerCase();
        if (qLower.contains('health') || qLower.contains('doctor') || qLower.contains('hospital') || qLower.contains('medicine') || qLower.contains('clinic')) {
          category = 'Health';
        } else if (qLower.contains('work') || qLower.contains('meeting') || qLower.contains('office') || qLower.contains('job') || qLower.contains('project') || qLower.contains('todo') || qLower.contains('task')) {
          category = 'Work';
        } else if (qLower.contains('finance') || qLower.contains('money') || qLower.contains('bank') || qLower.contains('bill') || qLower.contains('payment')) {
          category = 'Finance';
        } else if (qLower.contains('learning') || qLower.contains('learn') || qLower.contains('flutter') || qLower.contains('dart') || qLower.contains('study') || qLower.contains('course')) {
          category = 'Learning';
        } else if (qLower.contains('ideas') || qLower.contains('idea') || qLower.contains('thought') || qLower.contains('brainstorm')) {
          category = 'Ideas';
        } else if (qLower.contains('shopping') || qLower.contains('buy') || qLower.contains('groceries') || qLower.contains('list')) {
          category = 'Shopping';
        } else if (qLower.contains('family') || qLower.contains('mom') || qLower.contains('dad') || qLower.contains('parent')) {
          category = 'Family';
        } else if (qLower.contains('fitness') || qLower.contains('gym') || qLower.contains('workout') || qLower.contains('exercise')) {
          category = 'Fitness';
        }
        
        if (category != null) {
          filtered = memories.where((m) => m.type.toLowerCase().trim() == category!.toLowerCase().trim()).toList();
        } else {
          filtered = memories;
        }
        break;

      case MemoryBrainIntent.timeQuery:
        final qLower = cleanQuery.toLowerCase();
        filtered = memories.where((m) {
          if (qLower.contains('january') && m.createdAt.month == 1) return true;
          if (qLower.contains('february') && m.createdAt.month == 2) return true;
          if (qLower.contains('march') && m.createdAt.month == 3) return true;
          if (qLower.contains('april') && m.createdAt.month == 4) return true;
          if (qLower.contains('may') && m.createdAt.month == 5) return true;
          if (qLower.contains('june') && m.createdAt.month == 6) return true;
          if (qLower.contains('july') && m.createdAt.month == 7) return true;
          if (qLower.contains('august') && m.createdAt.month == 8) return true;
          if (qLower.contains('september') && m.createdAt.month == 9) return true;
          if (qLower.contains('october') && m.createdAt.month == 10) return true;
          if (qLower.contains('november') && m.createdAt.month == 11) return true;
          if (qLower.contains('december') && m.createdAt.month == 12) return true;

          if (qLower.contains('monday') && m.createdAt.weekday == DateTime.monday) return true;
          if (qLower.contains('tuesday') && m.createdAt.weekday == DateTime.tuesday) return true;
          if (qLower.contains('wednesday') && m.createdAt.weekday == DateTime.wednesday) return true;
          if (qLower.contains('thursday') && m.createdAt.weekday == DateTime.thursday) return true;
          if (qLower.contains('friday') && m.createdAt.weekday == DateTime.friday) return true;
          if (qLower.contains('saturday') && m.createdAt.weekday == DateTime.saturday) return true;
          if (qLower.contains('sunday') && m.createdAt.weekday == DateTime.sunday) return true;

          if (qLower.contains('3 days ago')) {
            final targetDate = now.subtract(const Duration(days: 3));
            return _isSameDay(m.createdAt, targetDate);
          }
          if (qLower.contains('last week')) {
            final start = now.subtract(const Duration(days: 14));
            final end = now.subtract(const Duration(days: 7));
            return m.createdAt.isAfter(start) && m.createdAt.isBefore(end);
          }
          if (qLower.contains('last month')) {
            final lastMonth = now.month == 1 ? 12 : now.month - 1;
            final targetYear = now.month == 1 ? now.year - 1 : now.year;
            return m.createdAt.year == targetYear && m.createdAt.month == lastMonth;
          }
          return false;
        }).toList();
        break;

      case MemoryBrainIntent.productivityQuery:
        // Productivity focuses on completed reminders
        filtered = memories.where((m) => m.tags.contains('completed_reminder')).toList();
        break;

      case MemoryBrainIntent.timelineQuery:
      case MemoryBrainIntent.statisticsQuery:
        filtered = memories;
        break;

      case MemoryBrainIntent.unknown:
        final recallRes = await _recallEngine.recall(query: cleanQuery, memories: memories);
        filtered = recallRes.results.map((r) => r.memory).toList();
        break;
    }

    // Dynamic stats computation for streaks and active category counts
    int longestStreakVal = _calculateLongestStreak(memories);

    String? mostActiveCategoryName;
    int mostActiveCategoryCount = 0;
    final categoryCounts = <String, int>{};
    for (final m in memories) {
      categoryCounts[m.type] = (categoryCounts[m.type] ?? 0) + 1;
    }
    categoryCounts.forEach((cat, cnt) {
      if (cnt > mostActiveCategoryCount) {
        mostActiveCategoryCount = cnt;
        mostActiveCategoryName = cat;
      }
    });

    // Compute dominant category in the filtered list
    String? dominantCategory;
    if (filtered.isNotEmpty) {
      final counts = <String, int>{};
      for (final m in filtered) {
        counts[m.type] = (counts[m.type] ?? 0) + 1;
      }
      String? bestCat;
      int maxCnt = 0;
      counts.forEach((cat, cnt) {
        if (cnt > maxCnt) {
          maxCnt = cnt;
          bestCat = cat;
        }
      });
      dominantCategory = bestCat;
    }

    // Filtered list reminder stats
    final localCompletedCount = filtered.where((m) => m.tags.contains('completed_reminder')).length;
    final localUpcomingCount = filtered.where((m) => m.reminderAt != null && m.reminderAt!.isAfter(now) && !m.tags.contains('completed_reminder')).length;
    final localMissedCount = filtered.where((m) => m.reminderAt != null && m.reminderAt!.isBefore(now) && !m.tags.contains('completed_reminder')).length;
    final localTotalReminders = localCompletedCount + localMissedCount;
    final localCompletionRate = localTotalReminders > 0 ? (localCompletedCount / localTotalReminders * 100) : 0.0;

    // Map metrics depending on context
    final completedCount = (intent == MemoryBrainIntent.productivityQuery || intent == MemoryBrainIntent.statisticsQuery)
        ? globalCompletedCount
        : localCompletedCount;
    final upcomingCount = (intent == MemoryBrainIntent.productivityQuery || intent == MemoryBrainIntent.statisticsQuery)
        ? globalUpcomingCount
        : localUpcomingCount;
    final missedCount = (intent == MemoryBrainIntent.productivityQuery || intent == MemoryBrainIntent.statisticsQuery)
        ? globalMissedCount
        : localMissedCount;
    final completionRate = (intent == MemoryBrainIntent.productivityQuery || intent == MemoryBrainIntent.statisticsQuery)
        ? globalCompletionRate
        : localCompletionRate;

    // Pick target memory context for rescheduling or completing
    Memory? targetMemory;
    if (intent == MemoryBrainIntent.missedReminder || localMissedCount > 0) {
      final missedList = filtered.where((m) => m.reminderAt != null && m.reminderAt!.isBefore(now) && !m.tags.contains('completed_reminder')).toList();
      if (missedList.isNotEmpty) {
        missedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        targetMemory = missedList.first;
      }
    }
    if (targetMemory == null && (intent == MemoryBrainIntent.upcomingReminder || localUpcomingCount > 0)) {
      final upcomingList = filtered.where((m) => m.reminderAt != null && m.reminderAt!.isAfter(now) && !m.tags.contains('completed_reminder')).toList();
      if (upcomingList.isNotEmpty) {
        upcomingList.sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
        targetMemory = upcomingList.first;
      }
    }
    if (targetMemory == null && filtered.isNotEmpty) {
      final sorted = List<Memory>.from(filtered);
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      targetMemory = sorted.first;
    }

    // Dynamic Action Button assignment (Part 5)
    switch (intent) {
      case MemoryBrainIntent.upcomingReminder:
        actionLabels.add("Mark Complete");
        actionLabels.add("Open Reminder");
        break;
      case MemoryBrainIntent.missedReminder:
        actionLabels.add("Reschedule");
        actionLabels.add("Open Reminder");
        break;
      case MemoryBrainIntent.reminderQuery:
        actionLabels.add("Open Timeline");
        if (localUpcomingCount > 0) {
          actionLabels.add("Open Reminder");
        }
        break;
      case MemoryBrainIntent.todaySummary:
        actionLabels.add("Open Timeline");
        if (localUpcomingCount > 0) {
          actionLabels.add("Open Reminder");
        }
        break;
      case MemoryBrainIntent.yesterdaySummary:
        actionLabels.add("Open Timeline");
        if (localMissedCount > 0) {
          actionLabels.add("Reschedule");
        }
        break;
      case MemoryBrainIntent.weekSummary:
      case MemoryBrainIntent.monthSummary:
      case MemoryBrainIntent.timeQuery:
      case MemoryBrainIntent.timelineQuery:
      case MemoryBrainIntent.productivityQuery:
      case MemoryBrainIntent.statisticsQuery:
      case MemoryBrainIntent.completedReminder:
        actionLabels.add("Open Timeline");
        break;
      case MemoryBrainIntent.categoryQuery:
        actionLabels.add("View Category");
        break;
      case MemoryBrainIntent.unknown:
        // For search matches, add contextually
        if (localMissedCount > 0) {
          actionLabels.add("Reschedule");
          actionLabels.add("Open Reminder");
        } else if (localUpcomingCount > 0) {
          actionLabels.add("Mark Complete");
          actionLabels.add("Open Reminder");
        } else {
          actionLabels.add("Open Timeline");
        }
        break;
    }

    final naturalAnswer = MemoryAnswerGenerator.generate(
      intent: intent,
      memories: filtered,
      query: cleanQuery,
      longestStreakVal: longestStreakVal,
      mostActiveCategoryName: mostActiveCategoryName,
      mostActiveCategoryCount: mostActiveCategoryCount,
      completedCount: completedCount,
      upcomingCount: upcomingCount,
      missedCount: missedCount,
      completionRate: completionRate,
      dominantCategory: dominantCategory,
    );

    // Compute relevance scores map
    final relevanceScores = <int, double>{};
    if (intent == MemoryBrainIntent.unknown) {
      final recallRes = await _recallEngine.recall(query: cleanQuery, memories: memories);
      for (final r in recallRes.results) {
        relevanceScores[r.memory.id] = r.relevanceScore;
      }
    } else {
      for (final m in filtered) {
        relevanceScores[m.id] = 1.0;
      }
    }

    final result = MemoryBrainResult(
      intent: intent,
      naturalAnswer: naturalAnswer,
      count: filtered.length,
      memories: filtered,
      relevanceScores: relevanceScores,
      relevantCategory: category,
      relevantReminderStatus: reminderStatus,
      actionLabels: actionLabels,
      targetMemory: targetMemory,
    );

    _cache[cacheKey] = result;
    return result;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  int _calculateLongestStreak(List<Memory> memories) {
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
