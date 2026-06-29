import 'package:isar/isar.dart';

import '../../domain/entities/memory.dart';

part 'memory_model.g.dart';

@collection
class MemoryModel {
  Id id = Isar.autoIncrement;

  late String title;
  late String content;
  late String type;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  late List<String> tags;

  @Index()
  late bool isPinned;

  DateTime? reminderAt;

  /// Converts database model back to clean domain [Memory] entity.
  Memory toEntity() {
    return Memory(
      id: id,
      title: title,
      content: content,
      type: type == 'Other' ? 'Daily Life' : type,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: tags,
      isPinned: isPinned,
      reminderAt: reminderAt,
    );
  }

  static MemoryModel fromEntity(Memory memory) {
    final model = MemoryModel()
      ..title = memory.title
      ..content = memory.content
      ..type = memory.type == 'Other' ? 'Daily Life' : memory.type
      ..createdAt = memory.createdAt
      ..updatedAt = memory.updatedAt
      ..tags = memory.tags
      ..isPinned = memory.isPinned
      ..reminderAt = memory.reminderAt;

    if (memory.id != 0) {
      model.id = memory.id;
    }
    return model;
  }
}
