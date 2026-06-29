import 'package:flutter/foundation.dart';

/// Immutable model representing a generated textual insight message.
@immutable
class GeneratedInsight {
  final String text;
  final String type; // 'daily', 'weekly', 'reminder', 'focus', 'streak', 'keyword', 'mood'

  const GeneratedInsight({
    required this.text,
    required this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedInsight &&
        other.text == text &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(text, type);
}
