import '../models/daily_reflection.dart';
import '../../features/memories/domain/entities/memory.dart';
import '../../features/memories/domain/repositories/memory_repository.dart';
import '../../app/di/service_locator.dart';
import 'personal_coach_engine.dart';

/// Contract definition for the AI Daily Reflection and Coach Engine.
abstract class ReflectionEngine {
  Future<DailyReflection> generateTodayReflection();
  Future<DailyReflection> generateReflectionForDate(DateTime date);
}

/// Concrete implementation of [ReflectionEngine] computing reflections locally.
class LocalReflectionEngine implements ReflectionEngine {
  final MemoryRepository _repository;

  LocalReflectionEngine(this._repository);

  @override
  Future<DailyReflection> generateTodayReflection() {
    return generateReflectionForDate(DateTime.now());
  }

  @override
  Future<DailyReflection> generateReflectionForDate(DateTime date) async {
    final result = await _repository.getMemories();
    return result.fold(
      (failure) => _emptyReflection(date),
      (memories) => _calculateReflection(date, memories),
    );
  }

  DailyReflection _emptyReflection(DateTime date) {
    return DailyReflection(
      date: date,
      title: 'A New Day',
      summary: 'Start capturing memories to unlock personal daily reflections!',
      mood: 'Quiet',
      score: 0.0,
      highlights: const [],
      concerns: const ['No memories recorded yet.'],
      suggestedActions: const ['Capture your first memory today'],
      reflectionQuestions: const ['What is one moment from today worth saving?'],
      generatedAt: DateTime.now(),
    );
  }

  DailyReflection _calculateReflection(DateTime date, List<Memory> allMemories) {
    try {
      sl<PersonalCoachEngine>().invalidateCache();
    } catch (_) {}

    final memoriesForDate = allMemories.where((m) => _isSameDay(m.createdAt, date)).toList();
    final remindersForDate = allMemories.where((m) => m.reminderAt != null && _isSameDay(m.reminderAt!, date)).toList();

    // Calculate streaks overall
    final streak = _calculateCurrentStreak(allMemories, date);

    if (memoriesForDate.isEmpty && remindersForDate.isEmpty) {
      return DailyReflection(
        date: date,
        title: 'A Quiet Space',
        summary: 'Today was quiet. What is one moment from today worth saving?',
        mood: 'Quiet',
        score: 0.0,
        highlights: const [],
        concerns: const ['No entries captured today.'],
        suggestedActions: const [
          'Capture one more memory before sleep',
          'Plan tomorrow’s first reminder'
        ],
        reflectionQuestions: const [
          'What is one moment from today worth saving?',
          'What is your biggest goal tomorrow?'
        ],
        generatedAt: DateTime.now(),
        wins: const [],
        needsImprovement: const ['No memories or reminders recorded today.'],
        tomorrowFocus: 'Tomorrow focus on capturing one learning.',
        scoreExplanation: 'Zero captures or reminders created today.',
      );
    }

    // Counts
    int completedReminders = 0;
    int missedReminders = 0;

    for (final r in remindersForDate) {
      if (r.tags.contains('completed_reminder')) {
        completedReminders++;
      } else if (r.reminderAt!.isBefore(DateTime.now())) {
        missedReminders++;
      }
    }

    final totalReminders = remindersForDate.length;
    final completionRate = totalReminders > 0 ? (completedReminders / totalReminders) * 100.0 : 100.0;

    // Category
    final categoryDistribution = <String, int>{};
    for (final m in memoriesForDate) {
      final cat = m.type;
      categoryDistribution[cat] = (categoryDistribution[cat] ?? 0) + 1;
    }

    String dominantCategory = 'None';
    if (categoryDistribution.isNotEmpty) {
      final sortedCats = categoryDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      dominantCategory = sortedCats.first.key;
    }
    final cleanCat = dominantCategory == 'None' || dominantCategory.toLowerCase().trim() == 'other'
        ? 'Daily Life'
        : dominantCategory;

    // Mood heuristics
    String mood = 'Balanced';
    if ((memoriesForDate.length >= 5 || remindersForDate.length >= 8) && missedReminders >= 3) {
      mood = 'Overloaded';
    } else if (missedReminders >= 2 && completedReminders == 0) {
      mood = 'NeedsAttention';
    } else if (memoriesForDate.length <= 1 && completedReminders == 0 && missedReminders == 0) {
      mood = 'Quiet';
    } else if (memoriesForDate.any((m) => m.tags.contains('reflection') || m.content.toLowerCase().contains('reflect'))) {
      mood = 'Reflective';
    } else if (memoriesForDate.length >= 3 && completedReminders >= 1 && missedReminders == 0) {
      mood = 'Productive';
    } else if (dominantCategory != 'None' && cleanCat != 'Daily Life' && memoriesForDate.length >= 2) {
      mood = 'Focused';
    }

    // Rotating templates (PART 5)
    final phrases = [
      "Nice progress.",
      "You're building a strong habit.",
      "Small steps create long-term consistency.",
      "You're becoming more organized.",
      "You're building a reliable second brain."
    ];
    final rotationPhrase = phrases[date.day % phrases.length];

    // Wording details
    String title;
    String summary;
    final List<String> wins = [];
    final List<String> needsImprovement = [];
    final List<String> suggestedActions = [];
    final List<String> reflectionQuestions = [
      'What made today meaningful?',
      'What is one thing you want to remember from today?',
      'What is your biggest goal tomorrow?'
    ];

    switch (mood) {
      case 'Quiet':
        title = 'A Quiet Day';
        summary = memoriesForDate.length == 1
            ? 'Today was calm. You captured one memory and kept things light. Tomorrow is a good chance to build your streak again.'
            : 'Today was calm. You captured no memories and kept things light. Tomorrow is a good chance to reflect or set a small reminder to build your streak again.';
        summary = '$summary $rotationPhrase';
        suggestedActions.addAll([
          'Capture one more memory before sleep',
          'Plan tomorrow’s first reminder'
        ]);
        break;
      case 'Productive':
        title = 'Highly Productive Flow';
        summary = 'Great work today. You captured multiple memories, stayed consistent, and completed your reminders. $rotationPhrase';
        suggestedActions.addAll([
          'Review today’s timeline',
          'Keep your streak alive'
        ]);
        break;
      case 'Focused':
        title = 'Concentrated Focus';
        summary = 'Most of your attention today went toward $cleanCat. You stayed focused and kept your memory streak alive. $rotationPhrase';
        suggestedActions.addAll([
          'Review today’s timeline',
          'Plan tomorrow’s first reminder'
        ]);
        break;
      case 'Overloaded':
        title = 'Time to Recharge';
        summary = 'Things felt busy and overloaded today. Try rescheduling what you missed and take some time to unwind. $rotationPhrase';
        suggestedActions.addAll([
          'Reschedule missed reminders',
          'Review today’s timeline'
        ]);
        break;
      case 'NeedsAttention':
        title = 'Unfinished Business';
        summary = 'You missed $missedReminders reminders today. Consider rescheduling them before tomorrow begins. $rotationPhrase';
        suggestedActions.addAll([
          'Reschedule missed reminders',
          'Plan tomorrow’s first reminder'
        ]);
        break;
      case 'Reflective':
        title = 'Deep Reflection';
        summary = 'Today was a reflective day. You took time to capture deeper thoughts and personal logs. $rotationPhrase';
        suggestedActions.addAll([
          'Review today’s timeline',
          'Capture one more memory before sleep'
        ]);
        reflectionQuestions.add('What did your reflection today reveal about your current state?');
        break;
      case 'Balanced':
      default:
        title = 'Balanced Routine';
        summary = 'Today felt balanced and steady. You recorded a couple of memories and kept your routine on track. $rotationPhrase';
        suggestedActions.addAll([
          'Review today’s timeline',
          'Keep your streak alive'
        ]);
        break;
    }

    if (missedReminders > 0) {
      reflectionQuestions.add('Do you want to reschedule what you missed?');
    }
    if (memoriesForDate.isEmpty) {
      reflectionQuestions.add('What is one moment from today worth saving?');
    }

    // Wins (PART 4)
    if (streak > 0) wins.add('✓ You maintained your streak.');
    if (memoriesForDate.isNotEmpty) wins.add('✓ You captured useful memories.');
    if (mood == 'Focused') wins.add('✓ You stayed focused.');
    if (completedReminders > 0) wins.add('✓ You completed scheduled reminders.');

    // Needs Improvement (PART 4)
    if (missedReminders > 0) {
      needsImprovement.add('• Missed reminders.');
    }
    final hasHealth = allMemories.any((m) => m.type.toLowerCase().trim() == 'health');
    if (!hasHealth) {
      needsImprovement.add('• No health memories.');
    }
    final hasLearning = allMemories.any((m) => m.type.toLowerCase().trim() == 'learning');
    if (!hasLearning) {
      needsImprovement.add('• No learning memories.');
    }

    // Tomorrow Focus (PART 4)
    String tomorrowFocus;
    if (missedReminders > 0) {
      tomorrowFocus = 'Tomorrow finish pending reminders.';
    } else if (!hasHealth) {
      tomorrowFocus = 'Tomorrow focus on Health.';
    } else if (!hasLearning) {
      tomorrowFocus = 'Tomorrow capture one learning.';
    } else {
      tomorrowFocus = 'Tomorrow review unfinished ideas.';
    }

    // Scoring heuristics
    final captureBase = (memoriesForDate.length * 30.0).clamp(0.0, 60.0);
    final reminderBase = totalReminders > 0 ? (completionRate * 0.3) : 30.0;
    final streakBase = (streak * 5.0).clamp(0.0, 10.0);
    final missedPenalty = missedReminders * 15.0;
    final score = (captureBase + reminderBase + streakBase - missedPenalty).clamp(0.0, 100.0);

    // Score Explanation (PART 6)
    String consistencyDesc = streakBase >= 8.0
        ? 'Strong consistency'
        : (streakBase >= 4.0 ? 'Moderate consistency' : 'Build consistency');
    String activityDesc = captureBase >= 40.0 ? 'good focus' : 'light activity';
    String reminderDesc = missedPenalty > 0
        ? 'but reminder discipline could improve'
        : (totalReminders > 0 && completionRate >= 80.0 ? 'perfect reminder discipline' : 'stable organization');
    final scoreExplanation = '$consistencyDesc, $activityDesc, $reminderDesc.';

    return DailyReflection(
      date: date,
      title: title,
      summary: summary,
      mood: mood,
      score: score,
      highlights: wins,
      concerns: needsImprovement,
      wins: wins,
      needsImprovement: needsImprovement,
      tomorrowFocus: tomorrowFocus,
      scoreExplanation: scoreExplanation,
      suggestedActions: suggestedActions,
      reflectionQuestions: reflectionQuestions,
      generatedAt: DateTime.now(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _calculateCurrentStreak(List<Memory> memories, DateTime date) {
    final days = memories.map((m) {
      final d = m.createdAt;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    final today = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final hasToday = days.contains(today);
    final hasYesterday = days.contains(yesterday);

    if (!hasToday && !hasYesterday) return 0;

    int streak = 0;
    DateTime checkDay = hasToday ? today : yesterday;

    while (true) {
      if (days.contains(checkDay)) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
