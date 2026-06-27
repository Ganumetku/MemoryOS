import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Represents a Life Area category for memory classification.
class LifeArea {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;

  const LifeArea({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
  });

  static const LifeArea work = LifeArea(
    id: 'work',
    name: 'Work',
    emoji: '💼',
    icon: Icons.business_center_outlined,
    color: AppColors.info,
  );

  static const LifeArea personal = LifeArea(
    id: 'personal',
    name: 'Personal',
    emoji: '❤️',
    icon: Icons.person_outline,
    color: AppColors.brandSecondary,
  );

  static const LifeArea health = LifeArea(
    id: 'health',
    name: 'Health',
    emoji: '🏥',
    icon: Icons.favorite_border,
    color: AppColors.error,
  );

  static const LifeArea finance = LifeArea(
    id: 'finance',
    name: 'Finance',
    emoji: '💰',
    icon: Icons.account_balance_wallet_outlined,
    color: AppColors.success,
  );

  static const LifeArea learning = LifeArea(
    id: 'learning',
    name: 'Learning',
    emoji: '🎓',
    icon: Icons.school_outlined,
    color: Color(0xFFAB47BC), // Purple
  );

  static const LifeArea fitness = LifeArea(
    id: 'fitness',
    name: 'Fitness',
    emoji: '🏋️',
    icon: Icons.directions_run_outlined,
    color: Color(0xFFE65100), // Orange
  );

  static const LifeArea family = LifeArea(
    id: 'family',
    name: 'Family',
    emoji: '👨‍👩‍👧',
    icon: Icons.people_outline,
    color: Color(0xFF26A69A), // Teal
  );

  static const LifeArea startup = LifeArea(
    id: 'startup',
    name: 'Startup',
    emoji: '🚀',
    icon: Icons.rocket_launch_outlined,
    color: Color(0xFFFFB300), // Amber
  );

  static const LifeArea travel = LifeArea(
    id: 'travel',
    name: 'Travel',
    emoji: '✈️',
    icon: Icons.flight_takeoff_outlined,
    color: AppColors.brandSecondary,
  );

  static const LifeArea shopping = LifeArea(
    id: 'shopping',
    name: 'Shopping',
    emoji: '🛒',
    icon: Icons.shopping_bag_outlined,
    color: AppColors.brandAccent,
  );

  static const LifeArea events = LifeArea(
    id: 'events',
    name: 'Events',
    emoji: '📅',
    icon: Icons.event_outlined,
    color: Color(0xFFF06292), // Pink
  );

  static const LifeArea other = LifeArea(
    id: 'other',
    name: 'Other',
    emoji: '📌',
    icon: Icons.help_outline,
    color: AppColors.textDarkTertiary,
  );

  static const List<LifeArea> values = [
    work,
    personal,
    health,
    finance,
    learning,
    fitness,
    family,
    startup,
    travel,
    shopping,
    events,
    other,
  ];

  static LifeArea fromName(String? name) {
    if (name == null || name.isEmpty) return other;
    final normalized = name.toLowerCase().trim();
    return values.firstWhere(
      (area) => area.id == normalized || area.name.toLowerCase() == normalized,
      orElse: () => other,
    );
  }
}
