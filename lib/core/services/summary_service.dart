import 'package:isar/isar.dart';

import '../../features/memories/data/models/memory_model.dart';

class DashboardSummary {
  final int todayCaptures;
  final int upcomingRemindersToday;
  final int missedReminders;
  final int pinnedCount;
  final DateTime? lastActivity;
  final int currentStreak;
  final int thisWeekCaptures;
  final int yesterdayCaptures;

  DashboardSummary({
    required this.todayCaptures,
    required this.upcomingRemindersToday,
    required this.missedReminders,
    required this.pinnedCount,
    this.lastActivity,
    required this.currentStreak,
    required this.thisWeekCaptures,
    required this.yesterdayCaptures,
  });
}

class SummaryService {
  final Isar _isar;

  SummaryService(this._isar);

  Future<DashboardSummary> getSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    // Get all memories ordered by creation date to calculate streak and last activity
    final allMemories = await _isar.memoryModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();

    int todayCaptures = 0;
    int yesterdayCaptures = 0;
    int thisWeekCaptures = 0;
    int pinnedCount = 0;
    int upcomingRemindersToday = 0;
    int missedReminders = 0;
    DateTime? lastActivity;

    if (allMemories.isNotEmpty) {
      lastActivity = allMemories.first.createdAt;
    }

    Set<DateTime> uniqueCaptureDays = {};

    for (var m in allMemories) {
      final createdAt = m.createdAt;
      final dateOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);
      uniqueCaptureDays.add(dateOnly);

      if (m.isPinned) pinnedCount++;

      if (createdAt.isAfter(todayStart) && createdAt.isBefore(todayEnd)) {
        todayCaptures++;
      }

      if (createdAt.isAfter(yesterdayStart) && createdAt.isBefore(todayStart)) {
        yesterdayCaptures++;
      }

      if (createdAt.isAfter(weekStart)) {
        thisWeekCaptures++;
      }

      if (m.reminderAt != null) {
        if (m.reminderAt!.isBefore(now)) {
          missedReminders++;
        } else if (m.reminderAt!.isAfter(now) && m.reminderAt!.isBefore(todayEnd)) {
          upcomingRemindersToday++;
        }
      }
    }

    // Calculate streak
    int streak = 0;
    DateTime checkDate = todayStart;
    
    // If no capture today, check if there was one yesterday. 
    // If not, streak is 0.
    if (!uniqueCaptureDays.contains(checkDate)) {
      checkDate = yesterdayStart;
    }

    while (uniqueCaptureDays.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return DashboardSummary(
      todayCaptures: todayCaptures,
      upcomingRemindersToday: upcomingRemindersToday,
      missedReminders: missedReminders,
      pinnedCount: pinnedCount,
      lastActivity: lastActivity,
      currentStreak: streak,
      thisWeekCaptures: thisWeekCaptures,
      yesterdayCaptures: yesterdayCaptures,
    );
  }
}
