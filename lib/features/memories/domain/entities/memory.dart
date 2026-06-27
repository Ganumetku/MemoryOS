import 'package:equatable/equatable.dart';

/// Pure domain entity representing a User Memory inside MemoryOS.
class Memory extends Equatable {
  final int id;
  final String title;
  final String content;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isPinned;
  final DateTime? reminderAt;

  const Memory({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    this.isPinned = false,
    this.reminderAt,
  });

  /// Utility method to easily create copies with altered values.
  Memory copyWith({
    int? id,
    String? title,
    String? content,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPinned,
    DateTime? reminderAt,
  }) {
    return Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      reminderAt: reminderAt ?? this.reminderAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    type,
    createdAt,
    updatedAt,
    tags,
    isPinned,
    reminderAt,
  ];
}
