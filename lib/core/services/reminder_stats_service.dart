import '../../features/memories/domain/entities/memory.dart';

class ReminderStats {
  final int upcomingCount;
  final int completedTodayCount;
  final int missedCount;
  final double completionRate;
  final Duration averageCompletionDelay;
  final int longestStreak;

  ReminderStats({
    required this.upcomingCount,
    required this.completedTodayCount,
    required this.missedCount,
    required this.completionRate,
    required this.averageCompletionDelay,
    required this.longestStreak,
  });
}

class ReminderStatsService {
  static ReminderStats calculateStats(List<Memory> memories) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final reminders = memories.where((m) => m.reminderAt != null).toList();

    int upcoming = 0;
    int completedToday = 0;
    int missed = 0;
    int completedTotal = 0;

    List<Duration> delays = [];
    Set<DateTime> completionDays = {};

    for (final m in reminders) {
      final isCompleted = m.tags.contains('completed_reminder');
      final isMissed = !isCompleted && m.reminderAt!.isBefore(now);
      final isUpcoming = !isCompleted && m.reminderAt!.isAfter(now);

      if (isUpcoming) upcoming++;
      if (isMissed) missed++;
      if (isCompleted) {
        completedTotal++;
        if (m.updatedAt.isAfter(todayStart) && m.updatedAt.isBefore(todayEnd)) {
          completedToday++;
        }
        delays.add(m.updatedAt.difference(m.reminderAt!));
        completionDays.add(DateTime(m.updatedAt.year, m.updatedAt.month, m.updatedAt.day));
      }
    }

    final rate = reminders.isEmpty ? 0.0 : (completedTotal / reminders.length) * 100.0;

    final avgDelay = delays.isEmpty 
        ? Duration.zero 
        : Duration(microseconds: (delays.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / delays.length).round());

    // Calculate longest streak of consecutive days
    int longest = 0;
    if (completionDays.isNotEmpty) {
      final sortedDays = completionDays.toList()..sort();
      int currentStreak = 1;
      longest = 1;
      for (int i = 1; i < sortedDays.length; i++) {
        final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
        if (diff == 1) {
          currentStreak++;
          if (currentStreak > longest) {
            longest = currentStreak;
          }
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }
    }

    return ReminderStats(
      upcomingCount: upcoming,
      completedTodayCount: completedToday,
      missedCount: missed,
      completionRate: rate,
      averageCompletionDelay: avgDelay,
      longestStreak: longest,
    );
  }
}
