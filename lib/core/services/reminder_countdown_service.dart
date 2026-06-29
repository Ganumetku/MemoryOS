import '../../features/memories/domain/entities/memory.dart';

class ReminderCountdownService {
  static String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute < 10 ? '0$minute' : '$minute';
    return '$displayHour:$displayMinute $period';
  }

  static String getCountdown(Memory m) {
    if (m.reminderAt == null) return '';
    final isCompleted = m.tags.contains('completed_reminder');
    if (isCompleted) return 'Completed';

    final now = DateTime.now();
    if (m.reminderAt!.isBefore(now)) {
      final diff = now.difference(m.reminderAt!);
      if (diff.inMinutes < 60) {
        return 'Missed ${diff.inMinutes} minute${diff.inMinutes == 1 ? "" : "s"} ago';
      } else if (diff.inHours < 24) {
        return 'Missed ${diff.inHours} hour${diff.inHours == 1 ? "" : "s"} ago';
      } else {
        return 'Missed ${diff.inDays} day${diff.inDays == 1 ? "" : "s"} ago';
      }
    }

    final diff = m.reminderAt!.difference(now);
    
    // Check calendar days
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(m.reminderAt!.year, m.reminderAt!.month, m.reminderAt!.day);
    final daysDiff = reminderDay.difference(today).inDays;

    if (daysDiff == 0) {
      if (diff.inMinutes < 60) {
        return 'Starts in ${diff.inMinutes} minute${diff.inMinutes == 1 ? "" : "s"}';
      } else {
        return 'Today • ${_formatTime(m.reminderAt!)}';
      }
    } else if (daysDiff == 1) {
      return 'Tomorrow • ${_formatTime(m.reminderAt!)}';
    } else {
      return 'In $daysDiff days • ${_formatTime(m.reminderAt!)}';
    }
  }

  static String getCardCountdown(Memory m) {
    return getCountdown(m);
  }
}
