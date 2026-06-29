import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:memory_os/core/errors/failure.dart';
import 'package:memory_os/core/models/life_insights.dart';
import 'package:memory_os/core/services/life_insights_service.dart';
import 'package:memory_os/core/services/personal_coach_engine.dart';
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

class FakeLifeInsightsService implements LifeInsightsService {
  LifeInsights? stubInsights;

  @override
  Future<LifeInsights> generateInsights() async {
    if (stubInsights != null) return stubInsights!;
    return LifeInsights.empty();
  }

  @override
  void invalidateCache() {}
}

void main() {
  group('PersonalCoachEngine Tests', () {
    late FakeMemoryRepository repo;
    late FakeLifeInsightsService insightsService;
    late PersonalCoachEngine coachEngine;
    final now = DateTime.now();

    setUp(() {
      repo = FakeMemoryRepository();
      insightsService = FakeLifeInsightsService();
      coachEngine = LocalPersonalCoachEngine(repo, insightsService);
    });

    test('empty database yields onboarding capture recommendation', () async {
      repo.memories = [];
      final recs = await coachEngine.generateRecommendations();

      expect(recs, isNotEmpty);
      expect(recs.any((r) => r.title == 'Capture your day' && r.priority == 'High'), isTrue);
    });

    test('productive user with streak and health missing recommendation', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Work task',
          content: 'Coding SQLite',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];
      insightsService.stubInsights = LifeInsights.empty().copyWith(
        totalMemories: 10,
        todayMemories: 2,
        yesterdayMemories: 1,
        weeklyMemories: 5,
        monthlyMemories: 10,
        completedReminders: 3,
        currentStreak: 9,
        longestStreak: 12,
        dominantCategory: 'Work',
        busiestHour: 14,
        categoryDistribution: {'Work': 10},
      );

      final recs = await coachEngine.generateRecommendations();
      // Streaks > 7 recommendation exists
      expect(recs.any((r) => r.title == 'Consistency Champion'), isTrue);
      // Health is missing recommendation exists
      expect(recs.any((r) => r.title == 'Check on Health'), isTrue);
    });

    test('missed reminders recommendation', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Missed task 1',
          content: 'No content',
          type: 'Personal',
          createdAt: now,
          updatedAt: now,
          tags: const [],
          reminderAt: now.subtract(const Duration(hours: 10)),
        ),
        Memory(
          id: 2,
          title: 'Missed task 2',
          content: 'No content',
          type: 'Personal',
          createdAt: now,
          updatedAt: now,
          tags: const [],
          reminderAt: now.subtract(const Duration(hours: 5)),
        ),
      ];

      final recs = await coachEngine.generateRecommendations();
      expect(recs.any((r) => r.title == 'Realistic Planning' && r.priority == 'High'), isTrue);
    });

    test('cache invalidation works correctly', () async {
      repo.memories = [];
      final firstRecs = await coachEngine.generateRecommendations();
      expect(firstRecs.any((r) => r.title == 'Capture your day'), isTrue);

      // Now add memories so that todayMemories > 0
      repo.memories = [
        Memory(
          id: 1,
          title: 'Morning routine',
          content: 'Logged morning session',
          type: 'Health',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];

      // Before invalidation, cached recommendations are returned
      final secondRecs = await coachEngine.generateRecommendations();
      expect(secondRecs.any((r) => r.title == 'Capture your day'), isTrue);

      // Invalidate cache
      coachEngine.invalidateCache();

      // Regenerated recommendations should not contain 'Capture your day' (since there's a memory today)
      final thirdRecs = await coachEngine.generateRecommendations();
      expect(thirdRecs.any((r) => r.title == 'Capture your day'), isFalse);
    });
  });
}
