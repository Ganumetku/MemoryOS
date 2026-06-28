import '../../features/memories/domain/entities/memory.dart';

enum ReminderStatus { upcoming, completed, missed, none }

class ReminderStatusService {
  static ReminderStatus getStatus(Memory m) {
    if (m.reminderAt == null) return ReminderStatus.none;
    final isCompleted = m.tags.contains('completed_reminder');
    if (isCompleted) return ReminderStatus.completed;
    if (m.reminderAt!.isAfter(DateTime.now())) {
      return ReminderStatus.upcoming;
    }
    return ReminderStatus.missed;
  }
}
