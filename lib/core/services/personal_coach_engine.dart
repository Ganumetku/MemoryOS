import 'package:flutter/material.dart';
import '../models/coach_recommendation.dart';
import '../models/daily_reflection.dart';
import '../../features/memories/domain/repositories/memory_repository.dart';
import 'life_insights_service.dart';

abstract class PersonalCoachEngine {
  Future<List<CoachRecommendation>> generateRecommendations();
  String generateDailyCoachMessage(DailyReflection reflection);
  void invalidateCache();
}

class LocalPersonalCoachEngine implements PersonalCoachEngine {
  final MemoryRepository _repository;
  final LifeInsightsService _insightsService;

  List<CoachRecommendation>? _cachedRecommendations;

  LocalPersonalCoachEngine(this._repository, this._insightsService);

  @override
  void invalidateCache() {
    _cachedRecommendations = null;
  }

  @override
  String generateDailyCoachMessage(DailyReflection reflection) {
    final mood = reflection.mood;
    if (mood == 'Overloaded') {
      return 'You seem overloaded. Take a short break and review your priorities.';
    } else if (mood == 'Quiet') {
      return 'Today was relatively quiet. Try capturing one meaningful moment before bedtime.';
    } else if (mood == 'NeedsAttention') {
      return 'You missed scheduled reminders today. Try to reschedule them to stay aligned.';
    }

    final isAllRemindersCompleted = reflection.wins.any((w) => w.contains('reminders finished') || w.contains('Completed scheduled'));
    if (isAllRemindersCompleted) {
      return 'You completed every reminder today. Excellent discipline.';
    }

    return 'Good work today. You stayed consistent and protected your memory streak.';
  }

  @override
  Future<List<CoachRecommendation>> generateRecommendations() async {
    if (_cachedRecommendations != null) {
      return _cachedRecommendations!;
    }

    final List<CoachRecommendation> recs = [];
    final result = await _repository.getMemories();

    await result.fold(
      (failure) async {
        // Fallback onboarding recommendations
        recs.add(const CoachRecommendation(
          title: 'Capture your day',
          description: 'Capture one meaningful memory today.',
          priority: 'High',
          icon: Icons.add_circle_outline,
          category: 'Reflection',
          actionType: 'capture',
        ));
      },
      (memories) async {
        final insights = await _insightsService.generateInsights();
        final now = DateTime.now();

        // 1. No memories today
        final todayMemories = memories.where((m) => _isSameDay(m.createdAt, now)).toList();
        if (todayMemories.isEmpty) {
          recs.add(const CoachRecommendation(
            title: 'Capture your day',
            description: 'Capture one meaningful memory today.',
            priority: 'High',
            icon: Icons.add_circle_outline,
            category: 'Reflection',
            actionType: 'capture',
          ));
        }

        // 2. Reminder completion below 50%
        int totalReminders = 0;
        int completedReminders = 0;

        for (final m in memories) {
          if (m.reminderAt != null) {
            totalReminders++;
            if (m.tags.contains('completed_reminder')) {
              completedReminders++;
            }
          }
        }

        final completionRate = totalReminders > 0 ? (completedReminders / totalReminders) : 1.0;
        if (totalReminders > 0 && completionRate < 0.50) {
          recs.add(const CoachRecommendation(
            title: 'Realistic Planning',
            description: 'You missed several reminders recently. Try scheduling fewer but more realistic reminders.',
            priority: 'High',
            icon: Icons.schedule_outlined,
            category: 'Productivity',
            actionType: 'reschedule',
          ));
        }

        // 3. No reminder created today
        final todayReminders = memories.where((m) => m.reminderAt != null && _isSameDay(m.reminderAt!, now)).toList();
        if (todayReminders.isEmpty) {
          recs.add(const CoachRecommendation(
            title: 'Prepare for Tomorrow',
            description: 'Planning tomorrow before sleep may help you stay organized.',
            priority: 'Medium',
            icon: Icons.edit_calendar_outlined,
            category: 'Productivity',
            actionType: 'none',
          ));
        }

        // 4. Current streak > 7
        if (insights.currentStreak > 7) {
          recs.add(const CoachRecommendation(
            title: 'Consistency Champion',
            description: 'Excellent consistency. Keep your streak alive tomorrow.',
            priority: 'Medium',
            icon: Icons.local_fire_department_outlined,
            category: 'Personal',
            actionType: 'none',
          ));
        }

        // 5. Most memories happen after 10 PM
        if (insights.busiestHour >= 22) {
          recs.add(const CoachRecommendation(
            title: 'Record in the Moment',
            description: 'Most of your memories are captured late at night. Try recording important ideas immediately when they happen.',
            priority: 'Low',
            icon: Icons.wb_sunny_outlined,
            category: 'Learning',
            actionType: 'none',
          ));
        }

        // 6. Health category missing for 30 days
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        final hasRecentHealth = memories.any((m) =>
            m.type.toLowerCase().trim() == 'health' && m.createdAt.isAfter(thirtyDaysAgo));
        if (!hasRecentHealth) {
          recs.add(const CoachRecommendation(
            title: 'Check on Health',
            description: "You haven't logged any health-related memories recently.",
            priority: 'Medium',
            icon: Icons.favorite_border_outlined,
            category: 'Health',
            actionType: 'capture',
          ));
        }

        // 7. No Work memories this week
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final hasRecentWork = memories.any((m) =>
            m.type.toLowerCase().trim() == 'work' && m.createdAt.isAfter(sevenDaysAgo));
        if (!hasRecentWork) {
          recs.add(const CoachRecommendation(
            title: 'Work Progress Tracker',
            description: "You haven't recorded any work progress this week.",
            priority: 'Medium',
            icon: Icons.work_outline,
            category: 'Productivity',
            actionType: 'capture',
          ));
        }

        // 8. One category dominates above 80%
        if (memories.length >= 5) {
          final distribution = <String, int>{};
          for (final m in memories) {
            final type = m.type;
            distribution[type] = (distribution[type] ?? 0) + 1;
          }
          for (final entry in distribution.entries) {
            final pct = entry.value / memories.length;
            if (pct > 0.80) {
              recs.add(const CoachRecommendation(
                title: 'Balance Your Focus',
                description: 'Most of your attention is focused on one life area. Consider balancing time with other priorities.',
                priority: 'Medium',
                icon: Icons.scale_outlined,
                category: 'Personal',
                actionType: 'none',
              ));
              break;
            }
          }
        }
      },
    );

    _cachedRecommendations = recs;
    return recs;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
