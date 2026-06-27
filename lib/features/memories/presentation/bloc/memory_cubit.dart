import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/base_usecase.dart';
import '../../domain/entities/memory.dart';
import '../../domain/usecases/delete_memory_usecase.dart';
import '../../domain/usecases/get_memories_usecase.dart';
import '../../domain/usecases/save_memory_usecase.dart';
import '../../domain/usecases/update_memory_usecase.dart';
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

  /// Loads all stored memories sorted by pinned and creation time.
  Future<void> fetchMemories() async {
    emit(const MemoryLoading());

    final result = await getMemoriesUseCase(const NoParams());

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
  }) async {
    if (content.trim().isEmpty) return;
    emit(const MemoryLoading());

    final newMemory = Memory(
      id: 0, // Auto-increment indicator
      title: title ?? _generateFallbackTitle(content),
      content: content,
      type: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags ?? const [],
    );

    final result = await saveMemoryUseCase(newMemory);

    result.fold(
      (failure) => emit(MemoryError(failure.message)),
      (_) => fetchMemories(),
    );
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

  /// Updates title and body content details of a memory.
  Future<void> updateMemoryContent(
    Memory memory,
    String newTitle,
    String newContent,
  ) async {
    if (newContent.trim().isEmpty) return;
    emit(const MemoryLoading());

    final updated = memory.copyWith(
      title: newTitle,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    final result = await updateMemoryUseCase(updated);

    result.fold(
      (failure) => emit(MemoryError(failure.message)),
      (_) => fetchMemories(),
    );
  }

  /// Erases a memory by ID.
  Future<void> removeMemory(int id) async {
    emit(const MemoryLoading());

    final result = await deleteMemoryUseCase(id);

    result.fold(
      (failure) => emit(MemoryError(failure.message)),
      (_) => fetchMemories(),
    );
  }

  String _generateFallbackTitle(String content) {
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || content.isEmpty) return 'Unstructured Note';
    final limit = words.length > 4 ? 4 : words.length;
    return '${words.sublist(0, limit).join(' ')}...';
  }
}
