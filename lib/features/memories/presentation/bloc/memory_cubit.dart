import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../domain/entities/memory.dart';
import '../../domain/usecases/delete_memory_usecase.dart';
import '../../domain/usecases/get_memories_usecase.dart';
import '../../domain/usecases/save_memory_usecase.dart';
import '../../domain/usecases/update_memory_usecase.dart';
import '../../../../core/services/memory_graph_service.dart';
import '../../../../core/services/memory_brain_service.dart';
import '../../../../core/services/life_insights_service.dart';
import '../../../../core/services/personal_coach_engine.dart';
import 'memory_state.dart';

/// Cubit managing all database CRUD operations for memories.
class MemoryCubit extends Cubit<MemoryState> {
  final GetMemoriesUseCase getMemoriesUseCase;
  final SaveMemoryUseCase saveMemoryUseCase;
  final UpdateMemoryUseCase updateMemoryUseCase;
  final DeleteMemoryUseCase deleteMemoryUseCase;

  MemoryCubit({
    required this.getMemoriesUseCase,
    required this.saveMemoryUseCase,
    required this.updateMemoryUseCase,
    required this.deleteMemoryUseCase,
  }) : super(const MemoryInitial());

  /// Fetches all saved memories from local database.
  Future<void> fetchMemories() async {
    emit(const MemoryLoading());

    // Invalidate local memory connection graph and brain cache
    try {
      sl<MemoryGraphService>().clearCache();
    } catch (_) {}
    try {
      sl<MemoryBrainService>().clearCache();
    } catch (_) {}
    try {
      sl<LifeInsightsService>().invalidateCache();
    } catch (_) {}
    try {
      sl<PersonalCoachEngine>().invalidateCache();
    } catch (_) {}

    final result = await getMemoriesUseCase(NoParams());

    result.fold(
      (failure) => emit(MemoryError(failure.message)),
      (memories) => emit(MemoryLoaded(memories)),
    );
  }

  /// Inserts a new text memory into the database.
  Future<void> addMemory(
    String content, {
    String? title,
    List<String>? tags,
    String? type,
    DateTime? reminderAt,
  }) async {
    if (content.trim().isEmpty) return;
    emit(const MemoryLoading());

    // Generate a unique 32-bit safe integer ID
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final finalTitle = title ?? _generateFallbackTitle(content);

    final newMemory = Memory(
      id: id,
      title: finalTitle,
      content: content,
      type: type ?? 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags ?? const [],
      reminderAt: reminderAt,
    );

    final result = await saveMemoryUseCase(newMemory);

    result.fold((failure) => emit(MemoryError(failure.message)), (_) async {
      // Schedule notification if reminder set
      if (reminderAt != null) {
        try {
          await sl<NotificationService>().scheduleReminder(
            id: id,
            title: finalTitle,
            body: content,
            scheduledDate: reminderAt,
          );
        } catch (_) {}
      }
      fetchMemories();
    });
  }

  /// Toggles the pinning state of a memory in the database.
  Future<void> togglePin(Memory memory) async {
    emit(const MemoryLoading());

    final updated = memory.copyWith(
      isPinned: !memory.isPinned,
      updatedAt: DateTime.now(),
    );

    final result = await updateMemoryUseCase(updated);

    result.fold(
      (failure) => emit(MemoryError(failure.message)),
      (_) => fetchMemories(),
    );
  }

  Future<void> updateMemoryContent(
    Memory memory,
    String newTitle,
    String newContent, {
    String? newType,
  }) async {
    if (newContent.trim().isEmpty) return;
    emit(const MemoryLoading());

    final updated = memory.copyWith(
      title: newTitle,
      content: newContent,
      type: newType ?? memory.type,
      updatedAt: DateTime.now(),
    );

    final result = await updateMemoryUseCase(updated);

    result.fold((failure) => emit(MemoryError(failure.message)), (_) async {
      // Reschedule notification with updated content if reminder was set
      if (memory.reminderAt != null) {
        try {
          await sl<NotificationService>().scheduleReminder(
            id: memory.id,
            title: newTitle,
            body: newContent,
            scheduledDate: memory.reminderAt!,
          );
        } catch (_) {}
      }
      fetchMemories();
    });
  }

  /// Erases a memory by ID.
  Future<void> removeMemory(int id) async {
    emit(const MemoryLoading());

    final result = await deleteMemoryUseCase(id);

    result.fold((failure) => emit(MemoryError(failure.message)), (_) async {
      // Cancel scheduled notifications if any
      try {
        await sl<NotificationService>().cancelNotification(id);
      } catch (_) {}
      fetchMemories();
    });
  }

  /// Toggles reminder completion status locally using tag identifiers.
  Future<void> toggleReminderCompleted(Memory memory) async {
    emit(const MemoryLoading());
    final tags = List<String>.from(memory.tags);
    if (tags.contains('completed_reminder')) {
      tags.remove('completed_reminder');
    } else {
      tags.add('completed_reminder');
    }

    final updated = memory.copyWith(tags: tags, updatedAt: DateTime.now());
    final result = await updateMemoryUseCase(updated);

    result.fold((failure) => emit(MemoryError(failure.message)), (_) async {
      if (tags.contains('completed_reminder')) {
        try {
          await sl<NotificationService>().cancelNotification(memory.id);
        } catch (_) {}
      } else if (memory.reminderAt != null) {
        try {
          await sl<NotificationService>().scheduleReminder(
            id: memory.id,
            title: memory.title,
            body: memory.content,
            scheduledDate: memory.reminderAt!,
          );
        } catch (_) {}
      }
      fetchMemories();
    });
  }

  /// Reschedules memory alarm notifications to a new target datetime.
  Future<void> rescheduleReminder(Memory memory, DateTime newDateTime) async {
    emit(const MemoryLoading());
    final tags = List<String>.from(memory.tags)..remove('completed_reminder');
    final updated = memory.copyWith(
      reminderAt: newDateTime,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    final result = await updateMemoryUseCase(updated);

    result.fold((failure) => emit(MemoryError(failure.message)), (_) async {
      try {
        await sl<NotificationService>().scheduleReminder(
          id: memory.id,
          title: memory.title,
          body: memory.content,
          scheduledDate: newDateTime,
        );
      } catch (_) {}
      fetchMemories();
    });
  }

  /// Cancels scheduled reminder notification alarms and wipes the time logs.
  Future<void> cancelReminder(Memory memory) async {
    emit(const MemoryLoading());
    final tags = List<String>.from(memory.tags)..remove('completed_reminder');
    final updated = memory.copyWith(
      reminderAt: null,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    final result = await updateMemoryUseCase(updated);

    result.fold((failure) => emit(MemoryError(failure.message)), (_) async {
      try {
        await sl<NotificationService>().cancelNotification(memory.id);
      } catch (_) {}
      fetchMemories();
    });
  }

  String _generateFallbackTitle(String content) {
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || content.isEmpty) return 'Unstructured Note';
    final limit = words.length > 4 ? 4 : words.length;
    return '${words.sublist(0, limit).join(' ')}...';
  }
}
