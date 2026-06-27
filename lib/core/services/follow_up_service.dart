import 'package:isar/isar.dart';
import '../../features/memories/data/models/follow_up_model.dart';
import '../../features/memories/data/models/memory_model.dart';
import 'notification_service.dart';

class FollowUpService {
  final Isar _isar;
  final NotificationService _notifications;

  FollowUpService(this._isar, this._notifications);

  // Called when a memory is saved/updated
  Future<void> handleMemorySaved(MemoryModel memory) async {
    if (memory.reminderAt == null) {
      // If reminder was removed, cancel any follow up
      await handleMemoryDeleted(memory.id);
      return;
    }

    // Check if follow up already exists
    final existing = await _isar.followUpModels.filter().memoryIdEqualTo(memory.id).findFirst();

    final scheduledAt = memory.reminderAt!.add(const Duration(days: 1));
    final question = _generateFollowUpQuestion(memory);

    if (existing != null) {
      // If reminder time changed or follow-up details changed, reschedule
      if (existing.scheduledAt != scheduledAt || existing.question != question) {
        existing.scheduledAt = scheduledAt;
        existing.question = question;
        // Keep status pending if it wasn't completed yet
        if (existing.status != 'completed') {
          existing.status = 'pending';
        }
        await _isar.writeTxn(() async {
          await _isar.followUpModels.put(existing);
        });

        // Reschedule notification
        await _notifications.cancelReminder(memory.id + 100000);
        if (scheduledAt.isAfter(DateTime.now()) && existing.status != 'completed') {
          await _notifications.scheduleReminder(
            id: memory.id + 100000,
            title: "Memory Follow-up",
            body: question,
            scheduledDate: scheduledAt,
          );
        }
      }
    } else {
      // Create new follow up
      final newFollowUp = FollowUpModel()
        ..memoryId = memory.id
        ..status = 'pending'
        ..scheduledAt = scheduledAt
        ..question = question;

      await _isar.writeTxn(() async {
        await _isar.followUpModels.put(newFollowUp);
      });

      if (scheduledAt.isAfter(DateTime.now())) {
        await _notifications.scheduleReminder(
          id: memory.id + 100000,
          title: "Memory Follow-up",
          body: question,
          scheduledDate: scheduledAt,
        );
      }
    }
  }

  // Called when memory is deleted
  Future<void> handleMemoryDeleted(int memoryId) async {
    final existing = await _isar.followUpModels.filter().memoryIdEqualTo(memoryId).findFirst();
    if (existing != null) {
      await _isar.writeTxn(() async {
        await _isar.followUpModels.delete(existing.id);
      });
    }
    await _notifications.cancelReminder(memoryId + 100000);
  }

  // Get active follow-up to show on dashboard (only one to avoid spam)
  Future<FollowUpModel?> getActiveFollowUp() async {
    final now = DateTime.now();
    // Find followups scheduled in past and status is pending or remind_later
    return await _isar.followUpModels
        .filter()
        .scheduledAtLessThan(now)
        .and()
        .group((q) => q.statusEqualTo('pending').or().statusEqualTo('remind_later'))
        .findFirst();
  }

  // Actions
  Future<void> markYes(int followUpId) async {
    final followUp = await _isar.followUpModels.get(followUpId);
    if (followUp != null) {
      followUp.status = 'completed';
      await _isar.writeTxn(() async {
        await _isar.followUpModels.put(followUp);
      });
      await _notifications.cancelReminder(followUp.memoryId + 100000);
    }
  }

  Future<void> markNo(int followUpId) async {
    final followUp = await _isar.followUpModels.get(followUpId);
    if (followUp != null) {
      followUp.status = 'dismissed';
      await _isar.writeTxn(() async {
        await _isar.followUpModels.put(followUp);
      });
      await _notifications.cancelReminder(followUp.memoryId + 100000);
    }
  }

  Future<void> remindLater(int followUpId) async {
    final followUp = await _isar.followUpModels.get(followUpId);
    if (followUp != null) {
      followUp.status = 'remind_later';
      // Reschedule for 2 hours later
      followUp.scheduledAt = DateTime.now().add(const Duration(hours: 2));
      await _isar.writeTxn(() async {
        await _isar.followUpModels.put(followUp);
      });
      await _notifications.cancelReminder(followUp.memoryId + 100000);
      await _notifications.scheduleReminder(
        id: followUp.memoryId + 100000,
        title: "Memory Follow-up",
        body: followUp.question,
        scheduledDate: followUp.scheduledAt,
      );
    }
  }

  String _generateFollowUpQuestion(MemoryModel m) {
    final title = m.title.toLowerCase();
    final content = m.content.toLowerCase();
    final type = m.type.toLowerCase();
    
    if (type == 'birthday' || title.contains('birthday') || content.contains('birthday')) {
      return "How was the birthday celebration?";
    }
    if (type == 'travel' || title.contains('travel') || title.contains('trip') || content.contains('travel') || content.contains('trip')) {
      return "How was your trip?";
    }
    if (type == 'shopping' || title.contains('shopping') || title.contains('buy') || content.contains('shopping') || content.contains('buy')) {
      return "Did you get everything on your shopping list?";
    }
    if (title.contains('medicine') || title.contains('pill') || title.contains('dose') ||
        content.contains('medicine') || content.contains('pill') || content.contains('dose')) {
      return "Did you take your medicine?";
    }
    if (title.contains('bill') || title.contains('payment') || title.contains('pay') ||
        content.contains('bill') || content.contains('payment') || content.contains('pay')) {
      return "Did you pay the bill?";
    }
    if (title.contains('renew') || title.contains('renewal') || content.contains('renew') || content.contains('renewal')) {
      return "Did you renew it?";
    }
    if (type == 'meeting' || title.contains('meeting') || content.contains('meeting')) {
      return "Did your meeting happen?";
    }
    
    return "Did your appointment happen?"; // Default fallback
  }
}
