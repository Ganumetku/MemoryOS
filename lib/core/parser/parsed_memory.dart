/// Model holding parsed attributes extracted from unstructured text.
class ParsedMemory {
  final String title;
  final String content;
  final String type;
  final DateTime? reminderAt;
  final String? personName;
  final DateTime? date;
  final String? time;
  final String priority;
  final String category;
  final List<String> tags;

  ParsedMemory({
    required this.title,
    required this.content,
    required this.type,
    this.reminderAt,
    this.personName,
    this.date,
    this.time,
    required this.priority,
    required this.category,
    required this.tags,
  });

  ParsedMemory copyWith({
    String? title,
    String? content,
    String? type,
    DateTime? reminderAt,
    String? personName,
    DateTime? date,
    String? time,
    String? priority,
    String? category,
    List<String>? tags,
  }) {
    return ParsedMemory(
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      reminderAt: reminderAt ?? this.reminderAt,
      personName: personName ?? this.personName,
      date: date ?? this.date,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}
