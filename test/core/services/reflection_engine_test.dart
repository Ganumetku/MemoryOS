import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:memory_os/core/errors/failure.dart';
import 'package:memory_os/core/services/reflection_engine.dart';
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
  group('ReflectionEngine Tests', () {
    late FakeMemoryRepository repo;
    late ReflectionEngine engine;
    final now = DateTime.now();

    setUp(() {
      repo = FakeMemoryRepository();
      engine = LocalReflectionEngine(repo);
    });

    test('no memories reflection triggers onboarding fallback', () async {
      repo.memories = [];
      final reflection = await engine.generateReflectionForDate(now);

      expect(reflection.mood, equals('Quiet'));
      expect(reflection.score, equals(0.0));
      expect(reflection.title, equals('A Quiet Space'));
      expect(reflection.summary, contains('What is one moment from today worth saving?'));
      expect(reflection.reflectionQuestions, isNotEmpty);
      expect(reflection.suggestedActions, isNotEmpty);
      expect(reflection.generatedAt, isNotNull);
    });

    test('quiet day reflection with exactly one memory', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Morning reflection',
          content: 'Just woke up, feeling calm.',
          type: 'text',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];

      final reflection = await engine.generateReflectionForDate(now);
      expect(reflection.mood, equals('Quiet'));
      expect(reflection.summary, contains('You captured one memory and kept things light.'));
      expect(reflection.score, inInclusiveRange(0.0, 100.0));
    });

    test('productive day reflection', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Workout session',
          content: 'Gym was great',
          type: 'Health',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 2,
          title: 'Finished feature code',
          content: 'Coded local SQLite',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 3,
          title: 'Plan reminder',
          content: 'Buy milk',
          type: 'Shopping',
          createdAt: now,
          updatedAt: now,
          tags: const ['completed_reminder'],
          reminderAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];

      final reflection = await engine.generateReflectionForDate(now);
      expect(reflection.mood, equals('Productive'));
      expect(reflection.summary, contains('multiple memories'));
      expect(reflection.summary, contains('completed your reminders'));
      expect(reflection.score, inInclusiveRange(0.0, 100.0));
    });

    test('focused day reflection', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Work task 1',
          content: 'Designing flowcharts',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
        Memory(
          id: 2,
          title: 'Work task 2',
          content: 'Meeting with Rahul',
          type: 'Work',
          createdAt: now,
          updatedAt: now,
          tags: const [],
        ),
      ];

      final reflection = await engine.generateReflectionForDate(now);
      expect(reflection.mood, equals('Focused'));
      expect(reflection.summary, contains('attention today went toward Work.'));
    });

    test('missed reminder reflection and reschedule question integration', () async {
      repo.memories = [
        Memory(
          id: 1,
          title: 'Buy medicine',
          content: 'Missed this task',
          type: 'Health',
          createdAt: now,
          updatedAt: now,
          tags: const [],
          reminderAt: now.subtract(const Duration(minutes: 10)),
        ),
        Memory(
          id: 2,
          title: 'Meeting doctor',
          content: 'Missed this doctor meeting',
          type: 'Health',
          createdAt: now,
          updatedAt: now,
          tags: const [],
          reminderAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];

      final reflection = await engine.generateReflectionForDate(now);
      expect(reflection.mood, equals('NeedsAttention'));
      expect(reflection.summary, contains('missed 2 reminders today. Consider rescheduling'));
      expect(reflection.reflectionQuestions, contains('Do you want to reschedule what you missed?'));
    });
  });
}
