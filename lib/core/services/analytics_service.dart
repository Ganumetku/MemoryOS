import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/memories/data/models/memory_model.dart';
import '../../features/memories/data/models/follow_up_model.dart';

class WeeklyReviewData {
  final int totalMemories;
  final String topCategory;
  final String topKeyword;
  final double reminderCompletionRate;
  final int longestStreak;

  WeeklyReviewData({
    required this.totalMemories,
    required this.topCategory,
    required this.topKeyword,
    required this.reminderCompletionRate,
    required this.longestStreak,
  });
}

class MonthlyReviewData {
  final int monthlyCaptures;
  final String mostActiveCategory;
  final String mostActiveKeyword;
  final String topPerson;
  final int completedReminders;
  final int missedReminders;
  final int scheduledReminders;

  MonthlyReviewData({
    required this.monthlyCaptures,
    required this.mostActiveCategory,
    required this.mostActiveKeyword,
    required this.topPerson,
    required this.completedReminders,
    required this.missedReminders,
    required this.scheduledReminders,
  });
}

class AnalyticsService {
  final Isar _isar;
  final SharedPreferences _prefs;

  AnalyticsService(this._isar, this._prefs);

  static const _searchCountKey = 'analytics_search_count';
  static const _textCaptureCountKey = 'analytics_capture_text_count';
  static const _voiceCaptureCountKey = 'analytics_capture_voice_count';
  static const _cameraCaptureCountKey = 'analytics_capture_camera_count';
  static const _notificationsFiredKey = 'analytics_notifications_fired_count';
  static const _openedMemoryPrefixKey = 'analytics_open_count_';

  // Increments
  Future<void> incrementSearchCount() async {
    final current = _prefs.getInt(_searchCountKey) ?? 0;
    await _prefs.setInt(_searchCountKey, current + 1);
  }

  Future<void> incrementCaptureCount(String method) async {
    final key = method == 'voice' 
        ? _voiceCaptureCountKey 
        : (method == 'camera' ? _cameraCaptureCountKey : _textCaptureCountKey);
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);
  }

  Future<void> incrementMemoryOpenedCount(int memoryId) async {
    final key = '$_openedMemoryPrefixKey$memoryId';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);
  }

  Future<void> incrementNotificationsFired() async {
    final current = _prefs.getInt(_notificationsFiredKey) ?? 0;
    await _prefs.setInt(_notificationsFiredKey, current + 1);
  }

  // Getters for stored stats
  int getSearchCount() => _prefs.getInt(_searchCountKey) ?? 0;
  int getCaptureCount(String method) {
    final key = method == 'voice' 
        ? _voiceCaptureCountKey 
        : (method == 'camera' ? _cameraCaptureCountKey : _textCaptureCountKey);
    return _prefs.getInt(key) ?? 0;
  }
  int getNotificationsFiredCount() => _prefs.getInt(_notificationsFiredKey) ?? 0;

  // Complex calculated statistics
  Future<int> getTotalMemories() async {
    return await _isar.memoryModels.count();
  }

  Future<int> getMemoriesCreatedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return await _isar.memoryModels.filter().createdAtGreaterThan(startOfDay).count();
  }

  Future<int> getMemoriesCreatedThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMon = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return await _isar.memoryModels.filter().createdAtGreaterThan(startOfMon).count();
  }

  Future<int> getMemoriesCreatedThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return await _isar.memoryModels.filter().createdAtGreaterThan(startOfMonth).count();
  }

  Future<double> getReminderCompletionRate() async {
    final totalReminders = await _isar.memoryModels.filter().reminderAtIsNotNull().count();
    if (totalReminders == 0) return 0.0;

    final completedFollowUps = await _isar.followUpModels.filter().statusEqualTo('completed').count();
    final rate = (completedFollowUps / totalReminders) * 100.0;
    return rate > 100.0 ? 100.0 : rate;
  }

  Future<double> getReminderMissRate() async {
    final totalReminders = await _isar.memoryModels.filter().reminderAtIsNotNull().count();
    if (totalReminders == 0) return 0.0;

    final now = DateTime.now();
    final pastReminders = await _isar.memoryModels.filter().reminderAtLessThan(now).findAll();
    if (pastReminders.isEmpty) return 0.0;

    int missed = 0;
    for (final r in pastReminders) {
      final followUp = await _isar.followUpModels.filter().memoryIdEqualTo(r.id).findFirst();
      if (followUp == null || followUp.status == 'dismissed' || followUp.status == 'pending' || followUp.status == 'remind_later') {
        missed++;
      }
    }
    final rate = (missed / totalReminders) * 100.0;
    return rate > 100.0 ? 100.0 : rate;
  }

  Future<double> getAverageMemoriesPerDay() async {
    final firstMemory = await _isar.memoryModels.where().sortByCreatedAt().findFirst();
    if (firstMemory == null) return 0.0;

    final days = DateTime.now().difference(firstMemory.createdAt).inDays + 1;
    final total = await getTotalMemories();
    return total / days;
  }

  Future<int> getCurrentStreak() async {
    final memories = await _isar.memoryModels.where().sortByCreatedAtDesc().findAll();
    if (memories.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final hasToday = memories.any((m) => _isSameDay(m.createdAt, today));
    final yesterday = today.subtract(const Duration(days: 1));
    final hasYesterday = memories.any((m) => _isSameDay(m.createdAt, yesterday));

    if (!hasToday && !hasYesterday) return 0;

    int streak = 0;
    DateTime checkDay = hasToday ? today : yesterday;

    while (true) {
      final hasDay = memories.any((m) => _isSameDay(m.createdAt, checkDay));
      if (hasDay) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> getLongestStreak() async {
    final memories = await _isar.memoryModels.where().sortByCreatedAt().findAll();
    if (memories.isEmpty) return 0;

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

  Future<Map<String, int>> getMemoryTypeDistribution() async {
    final memories = await _isar.memoryModels.where().findAll();
    final distribution = <String, int>{};
    for (final m in memories) {
      distribution[m.type] = (distribution[m.type] ?? 0) + 1;
    }
    return distribution;
  }

  Future<String> getMostCommonKeyword() async {
    final memories = await _isar.memoryModels.where().findAll();
    final counts = <String, int>{};
    for (final m in memories) {
      for (final t in m.tags) {
        if (_isCategory(t)) continue;
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return "None";
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Future<String> getMostCommonCategory() async {
    final memories = await _isar.memoryModels.where().findAll();
    final counts = <String, int>{};
    for (final m in memories) {
      counts[m.type] = (counts[m.type] ?? 0) + 1;
    }
    if (counts.isEmpty) return "None";
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Future<MemoryModel?> getMostOpenedMemory() async {
    final memories = await _isar.memoryModels.where().findAll();
    if (memories.isEmpty) return null;

    MemoryModel? mostOpened;
    int maxOpenCount = 0;

    for (final m in memories) {
      final openCount = _prefs.getInt('$_openedMemoryPrefixKey${m.id}') ?? 0;
      if (openCount > maxOpenCount) {
        maxOpenCount = openCount;
        mostOpened = m;
      }
    }

    return mostOpened;
  }

  // Periodic Reviews Calculations
  Future<WeeklyReviewData> getWeeklyReviewData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final weeklyMemories = await _isar.memoryModels
        .filter()
        .createdAtGreaterThan(sevenDaysAgo)
        .findAll();

    final total = await getTotalMemories();

    final typeCounts = <String, int>{};
    for (final m in weeklyMemories) {
      typeCounts[m.type] = (typeCounts[m.type] ?? 0) + 1;
    }
    String topCat = "None";
    if (typeCounts.isNotEmpty) {
      final sortedTypes = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCat = sortedTypes.first.key;
    }

    final keywordCounts = <String, int>{};
    for (final m in weeklyMemories) {
      for (final t in m.tags) {
        if (_isCategory(t)) continue;
        keywordCounts[t] = (keywordCounts[t] ?? 0) + 1;
      }
    }
    String topKey = "None";
    if (keywordCounts.isNotEmpty) {
      final sortedKeys = keywordCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topKey = sortedKeys.first.key;
    }

    final weeklyReminders = await _isar.memoryModels
        .filter()
        .reminderAtBetween(sevenDaysAgo, now)
        .findAll();
    
    double completionRate = 0.0;
    if (weeklyReminders.isNotEmpty) {
      int completed = 0;
      int totalReminders = 0;
      for (final r in weeklyReminders) {
        totalReminders++;
        if (r.tags.contains('completed_reminder')) {
          completed++;
        }
      }
      if (totalReminders > 0) {
        completionRate = (completed / totalReminders) * 100.0;
      }
    }

    final streak = await getLongestStreak();

    return WeeklyReviewData(
      totalMemories: total,
      topCategory: topCat,
      topKeyword: topKey,
      reminderCompletionRate: completionRate,
      longestStreak: streak,
    );
  }

  Future<MonthlyReviewData> getMonthlyReviewData() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final monthlyMemories = await _isar.memoryModels
        .filter()
        .createdAtGreaterThan(thirtyDaysAgo)
        .findAll();

    final monthlyCaptures = monthlyMemories.length;

    final typeCounts = <String, int>{};
    for (final m in monthlyMemories) {
      typeCounts[m.type] = (typeCounts[m.type] ?? 0) + 1;
    }
    String topCat = "None";
    if (typeCounts.isNotEmpty) {
      final sortedTypes = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCat = sortedTypes.first.key;
    }

    final keywordCounts = <String, int>{};
    for (final m in monthlyMemories) {
      for (final t in m.tags) {
        if (_isCategory(t)) continue;
        keywordCounts[t] = (keywordCounts[t] ?? 0) + 1;
      }
    }
    String topKey = "None";
    if (keywordCounts.isNotEmpty) {
      final sortedKeys = keywordCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topKey = sortedKeys.first.key;
    }

    final personRegex = RegExp(r'^(?:Dr\.?\s+)?[A-Z][a-zA-Z]+$');
    final nameCounts = <String, int>{};
    for (final m in monthlyMemories) {
      for (final t in m.tags) {
        if (_isCategory(t)) continue;
        if (personRegex.hasMatch(t)) {
          nameCounts[t] = (nameCounts[t] ?? 0) + 1;
        }
      }
    }
    String topPerson = "None";
    if (nameCounts.isNotEmpty) {
      final sortedNames = nameCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topPerson = sortedNames.first.key;
    }

    int completed = 0;
    int missed = 0;
    int scheduled = 0;

    final monthlyReminders = await _isar.memoryModels
        .filter()
        .reminderAtIsNotNull()
        .and()
        .reminderAtGreaterThan(thirtyDaysAgo)
        .findAll();

    for (final r in monthlyReminders) {
      if (r.tags.contains('completed_reminder')) {
        completed++;
      } else if (r.reminderAt!.isBefore(now)) {
        missed++;
      } else {
        scheduled++;
      }
    }

    return MonthlyReviewData(
      monthlyCaptures: monthlyCaptures,
      mostActiveCategory: topCat,
      mostActiveKeyword: topKey,
      topPerson: topPerson,
      completedReminders: completed,
      missedReminders: missed,
      scheduledReminders: scheduled,
    );
  }

  // Helpers
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCategory(String tag) {
    final normalized = tag.toLowerCase().trim();
    const categories = {
      'idea', 'health', 'work', 'personal', 'finance', 'shopping',
      'travel', 'birthday', 'meeting', 'reminder', 'task',
      'learning', 'fitness', 'family', 'startup', 'events', 'other', 'reflection'
    };
    return categories.contains(normalized);
  }
}
