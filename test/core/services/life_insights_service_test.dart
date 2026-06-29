import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:memory_os/app/di/service_locator.dart';
import 'package:memory_os/core/errors/failure.dart';
import 'package:memory_os/core/services/life_insights_service.dart';
import 'package:memory_os/core/services/life_area_service.dart';
import 'package:memory_os/core/parser/life_area_parser.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';
import 'package:memory_os/features/memories/domain/repositories/memory_repository.dart';

class FakeMemoryRepository implements MemoryRepository {
  List<Memory> memories = [];

  @override
  Future<Either<Failure, List<Memory>>> getMemories() async {
    return Right(memories);
  }

  @override
  Future<Either<Failure, void>> saveMemory(Memory memory) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateMemory(Memory memory) async => const Right(null);

  @override
  Future<Either<Failure, void>> deleteMemory(int id) async => const Right(null);
}

void main() {
  group('LifeInsightsService Tests', () {
    late FakeMemoryRepository repo;
    late LifeInsightsService service;
    final now = DateTime.now();

    setUp(() {
      // Ensure SmartParser dependencies are satisfied
      if (!sl.isRegistered<LifeAreaService>()) {
        sl.registerLazySingleton<LifeAreaService>(
          () => LifeAreaService(LifeAreaParser(), null as dynamic),
        );
      }

      repo = FakeMemoryRepository();
      service = LocalLifeInsightsService(repo);
    });

    test('empty database returns zero values', () async {
      repo.memories = [];
      final insights = await service.generateInsights();
      expect(insights.totalMemories, equals(0));
      expect(insights.todayMemories, equals(0));
      expect(insights.weeklyMemories, equals(0));
      expect(insights.completedReminders, equals(0));
      expect(insights.dominantCategory, equals('None'));
      expect(insights.busiestHour, equals(-1));
      expect(insights.busiestWeekday, equals('None'));
      expect(insights.busiestMonth, equals('None'));
      expect(insights.currentStreak, equals(0));
      expect(insights.longestStreak, equals(0));
      expect(insights.topKeywords, isEmpty);
    });

    test('single memory counts correctly', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Meeting with Rahul',
          content: 'Discussing Startup progress.',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const ['work'],
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.totalMemories, equals(1));
      expect(insights.todayMemories, equals(1));
      expect(insights.dominantCategory, equals('Work'));
    });

    test('today/yesterday/week/month counts', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Today memory',
          content: 'captured today',
          type: 'Personal',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 2,
          title: 'Yesterday memory',
          content: 'captured yesterday',
          type: 'Personal',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
          tags: const [],
        ),
        Memory(
          id: 3,
          title: '4 days ago memory',
          content: 'captured this week',
          type: 'Personal',
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now.subtract(const Duration(days: 4)),
          tags: const [],
        ),
        Memory(
          id: 4,
          title: '15 days ago memory',
          content: 'captured this month but not this week',
          type: 'Personal',
          createdAt: now.subtract(const Duration(days: 15)),
          updatedAt: now.subtract(const Duration(days: 15)),
          tags: const [],
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.totalMemories, equals(4));
      expect(insights.todayMemories, equals(1));
      expect(insights.yesterdayMemories, equals(1));
      expect(insights.weeklyMemories, equals(3));
      expect(insights.monthlyMemories, equals(4));
    });

    test('dominant category calculation', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Work 1',
          content: 'Work stuff',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 2,
          title: 'Health 1',
          content: 'Health stuff',
          type: 'Health',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 3,
          title: 'Work 2',
          content: 'Work stuff again',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.dominantCategory, equals('Work'));
      expect(insights.categoryDistribution['Work'], equals(2));
      expect(insights.categoryDistribution['Health'], equals(1));
    });

    test('top keywords extraction and stop words ignored', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Learn Flutter learning project',
          content: 'Flutter is the best layout engine to build mobile apps.',
          type: 'Learning',
          createdAt: now,
          updatedAt: now,
          tags: const ['flutter', 'code'],
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.topKeywords, contains('flutter'));
      expect(insights.topKeywords, contains('code'));
      expect(insights.topKeywords, contains('layout'));
      expect(insights.topKeywords, isNot(contains('the')));
      expect(insights.topKeywords, isNot(contains('is')));
      expect(insights.topKeywords, isNot(contains('to')));
    });

    test('busiest hour, busiest weekday and busiest month calculation', () async {
      // 15 July 2026 is a Wednesday (weekday 3)
      final midDay = DateTime(2026, 7, 15, 14, 0);
      final evening = DateTime(2026, 7, 15, 18, 0);

      repo.memories = [
        Memory(
          id: 1,
          title: 'M1',
          content: 'C1',
          type: 'Work',
          createdAt: midDay,
          updatedAt: midDay,
          tags: const [],
        ),
        Memory(
          id: 2,
          title: 'M2',
          content: 'C2',
          type: 'Work',
          createdAt: evening,
          updatedAt: evening,
          tags: const [],
        ),
        Memory(
          id: 3,
          title: 'M3',
          content: 'C3',
          type: 'Work',
          createdAt: midDay.add(const Duration(seconds: 10)),
          updatedAt: midDay,
          tags: const [],
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.busiestHour, equals(14));
      expect(insights.busiestWeekday, equals('Wednesday'));
      expect(insights.busiestMonth, equals('July'));
    });

    test('current streak and longest streak calculations', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Day 1',
          content: 'C1',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 2,
          title: 'Day 2',
          content: 'C2',
          type: 'Work',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
          tags: const [],
        ),
        // Gap of one day (2 days ago missed)
        Memory(
          id: 3,
          title: 'Day 4',
          content: 'C3',
          type: 'Work',
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 4,
          title: 'Day 5',
          content: 'C4',
          type: 'Work',
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 5,
          title: 'Day 6',
          content: 'C5',
          type: 'Work',
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
          tags: const [],
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.currentStreak, equals(2));
      expect(insights.longestStreak, equals(3));
    });

    test('reminder counts and reminder completion rate', () async {
      final scheduledTime = now.add(const Duration(hours: 5));
      final missedTime = now.subtract(const Duration(hours: 5));

      repo.memories = [
        Memory(
          id: 1,
          title: 'Completed reminder',
          content: 'completed',
          type: 'Work',
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 30)),
          tags: const ['completed_reminder'],
          reminderAt: now,
        ),
        Memory(
          id: 2,
          title: 'Missed reminder',
          content: 'missed',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
          reminderAt: missedTime,
        ),
        Memory(
          id: 3,
          title: 'Upcoming reminder',
          content: 'upcoming',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
          reminderAt: scheduledTime,
        ),
      ];

      final insights = await service.generateInsights();
      expect(insights.completedReminders, equals(1));
      expect(insights.missedReminders, equals(1));
      expect(insights.upcomingReminders, equals(1));
      expect(insights.reminderCompletionRate, closeTo(33.33, 0.01));
      expect(insights.averageReminderDelay, equals(30.0));
    });

    test('cache invalidation works correctly', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Title 1',
          content: 'C1',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];

      final run1 = await service.generateInsights();
      expect(run1.totalMemories, equals(1));

      // Update repository data without invalidating cache
      repo.memories = [
        ...repo.memories,
        Memory(
          id: 2,
          title: 'Title 2',
          content: 'C2',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];

      final run2 = await service.generateInsights();
      // Should still be cached run1 values
      expect(run2.totalMemories, equals(1));

      // Invalidate cache
      service.invalidateCache();

      final run3 = await service.generateInsights();
      // Cache cleared, should now compute new database state
      expect(run3.totalMemories, equals(2));
    });
  });
}
