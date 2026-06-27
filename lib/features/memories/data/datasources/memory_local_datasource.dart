import 'package:isar/isar.dart';

import '../models/memory_model.dart';

/// Contract for local storage operations on [MemoryModel].
abstract class MemoryLocalDataSource {
  Future<List<MemoryModel>> getMemories();
  Future<void> saveMemory(MemoryModel model);
  Future<void> updateMemory(MemoryModel model);
  Future<void> deleteMemory(int id);
}

/// Isar database implementation of [MemoryLocalDataSource].
class MemoryLocalDataSourceImpl implements MemoryLocalDataSource {
  final Isar isar;

  MemoryLocalDataSourceImpl(this.isar);

  @override
  Future<List<MemoryModel>> getMemories() async {
    // Sort pinned memories to the top (descending), then sort by creation date (newest first)
    return await isar.memoryModels
        .where()
        .sortByIsPinnedDesc()
        .thenByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<void> saveMemory(MemoryModel model) async {
    await isar.writeTxn(() async {
      await isar.memoryModels.put(model);
    });
  }

  @override
  Future<void> updateMemory(MemoryModel model) async {
    await isar.writeTxn(() async {
      await isar.memoryModels.put(model);
    });
  }

  @override
  Future<void> deleteMemory(int id) async {
    await isar.writeTxn(() async {
      await isar.memoryModels.delete(id);
    });
  }
}
