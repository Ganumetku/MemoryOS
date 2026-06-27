import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/domain/usecases/save_memory_usecase.dart';
import 'capture_state.dart';

/// Cubit managing Screen 001 (Capture Experience) state transitions.
/// Resolves [SaveMemoryUseCase] to save user entry into the Isar database.
class CaptureCubit extends Cubit<CaptureState> {
  final SaveMemoryUseCase saveMemoryUseCase;

  CaptureCubit({SaveMemoryUseCase? saveMemoryUseCase})
    : saveMemoryUseCase = saveMemoryUseCase ?? sl<SaveMemoryUseCase>(),
      super(const CaptureInitial());

  /// Saves the text memory into local Isar secure storage.
  Future<void> saveMemory(
    String text, {
    String? title,
    String? type,
    DateTime? reminderAt,
    List<String>? tags,
  }) async {
    if (text.trim().isEmpty) return;

    emit(const CaptureLoading());

    // Generate a unique 32-bit safe integer ID
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final finalTitle = title ?? _generateFallbackTitle(text);

    final newMemory = Memory(
      id: id,
      title: finalTitle,
      content: text,
      type: type ?? 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags ?? const [],
      reminderAt: reminderAt,
    );

    final result = await saveMemoryUseCase(newMemory);

    result.fold(
      (failure) =>
          emit(const CaptureInitial()), // Reset back to default welcome
      (_) async {
        // Schedule notification if reminder set
        if (reminderAt != null) {
          try {
            await sl<NotificationService>().scheduleReminder(
              id: id,
              title: finalTitle,
              body: text,
              scheduledDate: reminderAt,
            );
          } catch (_) {}
        }
        emit(CaptureSuccess(text));
      },
    );
  }

  /// Resets state back to the idle welcome page.
  void reset() {
    emit(const CaptureInitial());
  }

  String _generateFallbackTitle(String content) {
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || content.isEmpty) return 'Unstructured Note';
    final limit = words.length > 4 ? 4 : words.length;
    return '${words.sublist(0, limit).join(' ')}...';
  }
}
