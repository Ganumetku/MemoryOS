import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../features/memories/data/models/memory_model.dart';
import '../../features/memories/data/models/follow_up_model.dart';
import '../../features/memories/domain/entities/memory.dart';
import 'memory_connection_service.dart';

enum TimePeriod { morning, afternoon, evening, night }

class HomeExperienceData {
  final TimePeriod period;
  final String greeting;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  
  // Morning stats
  final int todayRemindersCount;
  final int upcomingFollowUpsCount;
  final String motivationalLine;
  
  // Afternoon stats
  final int todayCapturesCount;
  final int completedRemindersCount;
  
  // Evening stats
  final List<MemoryModel> todayMemories;
  final int connectionsCreatedCount;
  
  // Night stats
  final int completedTodayCount;
  final int tomorrowRemindersCount;

  HomeExperienceData({
    required this.period,
    required this.greeting,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.todayRemindersCount,
    required this.upcomingFollowUpsCount,
    required this.motivationalLine,
    required this.todayCapturesCount,
    required this.completedRemindersCount,
    required this.todayMemories,
    required this.connectionsCreatedCount,
    required this.completedTodayCount,
    required this.tomorrowRemindersCount,
  });
}

class HomeExperienceService {
  final Isar _isar;
  final MemoryConnectionService _connections;

  HomeExperienceService(this._isar, this._connections);

  TimePeriod getCurrentPeriod() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return TimePeriod.morning;
    } else if (hour >= 11 && hour < 17) {
      return TimePeriod.afternoon;
    } else if (hour >= 17 && hour < 21) {
      return TimePeriod.evening;
    } else {
      return TimePeriod.night;
    }
  }

  Future<HomeExperienceData> getExperienceData() async {
    final period = getCurrentPeriod();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startOfTomorrow = endOfDay;
    final endOfTomorrow = startOfTomorrow.add(const Duration(days: 1));

    // Get today's memories
    final todayMemories = await _isar.memoryModels
        .filter()
        .createdAtBetween(startOfDay, endOfDay)
        .findAll();

    // 1. Morning stats
    final todayReminders = await _isar.memoryModels
        .filter()
        .reminderAtBetween(startOfDay, endOfDay)
        .count();

    final upcomingFollowUps = await _isar.followUpModels
        .filter()
        .scheduledAtBetween(startOfDay, endOfDay)
        .and()
        .statusEqualTo('pending')
        .count();

    final motivationalLine = _getMotivationalLine(now.day);

    // 2. Afternoon stats
    final todayCaptures = todayMemories.length;
    
    final completedReminders = await _isar.memoryModels
        .filter()
        .reminderAtBetween(startOfDay, endOfDay)
        .and()
        .tagsElementContains('completed_reminder') // check tags
        .count();

    // 3. Evening stats: connections created
    int connectionsCreated = 0;
    for (final m in todayMemories) {
      final memoryEntity = Memory(
        id: m.id,
        title: m.title,
        content: m.content,
        type: m.type,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
        tags: m.tags.toList(),
        isPinned: m.isPinned,
        reminderAt: m.reminderAt,
      );
      final related = await _connections.getRelatedMemories(memoryEntity);
      if (related.isNotEmpty) {
        connectionsCreated++;
      }
    }

    // 4. Night stats: completed today & tomorrow preview
    final completedFollowUpsToday = await _isar.followUpModels
        .filter()
        .statusEqualTo('completed')
        .count();
    final completedToday = completedReminders + completedFollowUpsToday;

    final tomorrowReminders = await _isar.memoryModels
        .filter()
        .reminderAtBetween(startOfTomorrow, endOfTomorrow)
        .count();

    // Time-based config
    String greeting;
    String subtitle;
    IconData icon;
    Color accentColor;

    switch (period) {
      case TimePeriod.morning:
        greeting = "Good Morning";
        subtitle = "Ready to focus?";
        icon = Icons.wb_sunny_outlined;
        accentColor = const Color(0xFFFFD54F); // Amber/Gold
        break;
      case TimePeriod.afternoon:
        greeting = "Good Afternoon";
        subtitle = "Halfway through the day.";
        icon = Icons.wb_cloudy_outlined;
        accentColor = const Color(0xFF29B6F6); // Sky Blue
        break;
      case TimePeriod.evening:
        greeting = "Good Evening";
        subtitle = "Reflecting on your day.";
        icon = Icons.nights_stay_outlined;
        accentColor = const Color(0xFFAB47BC); // Twilight Purple
        break;
      case TimePeriod.night:
        greeting = "Good Night";
        subtitle = "Rest up. Tomorrow is a new start.";
        icon = Icons.bedtime_outlined;
        accentColor = const Color(0xFF3F51B5); // Deep Indigo
        break;
    }

    return HomeExperienceData(
      period: period,
      greeting: greeting,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      todayRemindersCount: todayReminders,
      upcomingFollowUpsCount: upcomingFollowUps,
      motivationalLine: motivationalLine,
      todayCapturesCount: todayCaptures,
      completedRemindersCount: completedReminders,
      todayMemories: todayMemories,
      connectionsCreatedCount: connectionsCreated,
      completedTodayCount: completedToday,
      tomorrowRemindersCount: tomorrowReminders,
    );
  }

  String _getMotivationalLine(int day) {
    final quotes = [
      "Your mind is for having ideas, not holding them.",
      "Capture the day, secure the details.",
      "A clear mind makes room for great thoughts.",
      "Every logged memory strengthens your digital second brain.",
      "Yesterday is history, tomorrow is a mystery, today is a gift."
    ];
    return quotes[day % quotes.length];
  }
}
