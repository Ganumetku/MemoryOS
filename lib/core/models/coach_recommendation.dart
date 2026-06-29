import 'package:flutter/widgets.dart';

@immutable
class CoachRecommendation {
  final String title;
  final String description;
  final String priority; // 'High', 'Medium', 'Low'
  final IconData icon;
  final String category; // 'Productivity', 'Health', 'Learning', 'Finance', 'Personal', 'Relationships', 'Reflection'
  final String actionType; // 'capture', 'reschedule', 'none'

  const CoachRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    required this.category,
    required this.actionType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachRecommendation &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.icon == icon &&
        other.category == category &&
        other.actionType == actionType;
  }

  @override
  int get hashCode {
    return Object.hash(title, description, priority, icon, category, actionType);
  }
}
