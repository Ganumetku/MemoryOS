import 'package:flutter/material.dart';
import '../entities/life_area.dart';

class MemoryTypeConfig {
  final IconData icon;
  final Color color;
  final String emoji;

  const MemoryTypeConfig({
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

class MemoryTypeHelper {
  MemoryTypeHelper._();

  static MemoryTypeConfig getConfig(String? type) {
    final area = LifeArea.fromName(type);
    return MemoryTypeConfig(
      icon: area.icon,
      color: area.color,
      emoji: area.emoji,
    );
  }
}
