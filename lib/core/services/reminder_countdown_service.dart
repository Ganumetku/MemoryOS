import '../../features/memories/domain/entities/memory.dart';

class ReminderCountdownService {
  static String getCountdown(Memory m) {
    if (m.reminderAt == null) return '';
    final isCompleted = m.tags.contains('completed_reminder');
    if (isCompleted) return 'Completed';

    final now = DateTime.now();
    if (m.reminderAt!.isBefore(now)) {
      return 'Expired';
    }

    final diff = m.reminderAt!.difference(now);
    
    // Check calendar days
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(m.reminderAt!.year, m.reminderAt!.month, m.reminderAt!.day);
    final daysDiff = reminderDay.difference(today).inDays;

    if (daysDiff == 0) {
      if (diff.inHours > 0) {
        return 'In ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"}';
      } else {
        return 'In ${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"}';
      }
    } else if (daysDiff == 1) {
      return 'Tomorrow';
    } else {
      return 'In $daysDiff days';
    }
  }

  static String getCardCountdown(Memory m) {
    if (m.reminderAt == null) return '';
    final isCompleted = m.tags.contains('completed_reminder');
    if (isCompleted) return 'Completed';

    final now = DateTime.now();
    if (m.reminderAt!.isBefore(now)) {
      return 'Expired';
    }

    final diff = m.reminderAt!.difference(now);
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(m.reminderAt!.year, m.reminderAt!.month, m.reminderAt!.day);
    final daysDiff = reminderDay.difference(today).inDays;

    if (daysDiff == 0) {
      if (diff.inHours > 0) {
        return 'Starts in ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"}';
      } else {
        return 'Starts in ${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"}';
      }
    } else if (daysDiff == 1) {
      return 'Tomorrow';
    } else {
      return '$daysDiff days';
    }
  }
}
