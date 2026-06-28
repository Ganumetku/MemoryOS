import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/services/recall_engine_service.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';
import 'package:memory_os/features/search/presentation/widgets/relative_date_text.dart';

void main() {
  late RecallEngineService recallEngine;
  late List<Memory> testMemories;

  setUp(() {
    recallEngine = LocalRecallEngineServiceImpl();
    testMemories = [
      Memory(
        id: 1,
        title: 'Doctor appointment checkup',
        content: 'Check cholesterol level with doctor and request medicine refills',
        type: 'Health',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: const ['doctor', 'medicine', 'health'],
        reminderAt: DateTime.now().add(const Duration(hours: 2)),
      ),
      Memory(
        id: 2,
        title: 'Buy fresh milk and eggs',
        content: 'Get organic products tomorrow morning',
        type: 'Shopping',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: const ['shopping', 'milk'],
      ),
      Memory(
        id: 3,
        title: 'Flutter architecture setup',
        content: 'Draft state management with bloc and clean architecture design patterns',
        type: 'Work',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        tags: const ['flutter', 'code', 'idea'],
      ),
      Memory(
        id: 4,
        title: 'Dr appointment tomorrow at 5:00 p.m.',
        content: 'Discuss next steps',
        type: 'Personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: const ['appt', 'appointment', 'dr', 'pm'],
      ),
      Memory(
        id: 5,
        title: 'today I have docter appointment evening 5 PM',
        content: 'Doctor consultation scheduled',
        type: 'Health',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: const ['docter', 'appointment', 'evening', '5 pm'],
      ),
    ];
  });

  group('RecallEngineService Query Matching Tests', () {
    test('Matches memory by title keyword', () async {
      final result = await recallEngine.recall(
        query: 'doctor',
        memories: testMemories,
      );

      // Matches ID 1 (Doctor), ID 4 (Dr), and ID 5 (docter)
      expect(result.results.length, equals(3));
    });

    test('Matches memory by tag / content keywords', () async {
      final result = await recallEngine.recall(
        query: 'milk',
        memories: testMemories,
      );

      expect(result.results.length, equals(1));
      expect(result.results.first.memory.id, equals(2));
    });

    test('Returns correct summary for zero matches', () async {
      final result = await recallEngine.recall(
        query: 'notmatchinganything',
        memories: testMemories,
      );

      expect(result.results.isEmpty, isTrue);
      expect(result.summary, equals("I couldn't remember anything about that yet."));
    });

    test('Identifies and generates summary for health area matching', () async {
      final result = await recallEngine.recall(
        query: 'health memories',
        memories: testMemories,
      );

      // Matches ID 1, ID 4 (via synonyms), and ID 5
      expect(result.results.length, equals(3));
      expect(result.summary, contains('health'));
    });

    test('Applies time filters correctly for tomorrow reminders', () async {
      final result = await recallEngine.recall(
        query: 'reminders today',
        memories: testMemories,
      );

      expect(result.results.length, equals(1));
      expect(result.summary, contains('reminder'));
      expect(result.summary, contains('today'));
    });

    test('Acceptance: doctor query variations all return the Doctor appointment memory', () async {
      final queries = [
        'docter',
        'doctor',
        'dr',
        'doctor appointment',
        'what did doctor tell me',
        'tomorrow appointment',
      ];

      for (final q in queries) {
        final result = await recallEngine.recall(
          query: q,
          memories: testMemories,
        );

        expect(
          result.results.any((r) => r.memory.id == 4),
          isTrue,
          reason: 'Query "$q" failed to return memory ID 4',
        );
      }
    });

    test('Acceptance: docter appointment query variations match newly saved memory ID 5', () async {
      final queries = [
        'docter',
        'doctor',
        'appointment',
        'evening',
        '5 PM',
      ];

      for (final q in queries) {
        final result = await recallEngine.recall(
          query: q,
          memories: testMemories,
        );

        expect(
          result.results.any((r) => r.memory.id == 5),
          isTrue,
          reason: 'Query "$q" failed to return memory ID 5',
        );
      }
    });
  });

  group('RecallEngineService Weighted Scoring and Relative Date Tests', () {
    test('Calculates correct relative date mapping', () {
      final now = DateTime(2026, 6, 28, 12, 0, 0);
      expect(RelativeDateText.getRelativeDateString(now, now), equals('Today'));
      expect(RelativeDateText.getRelativeDateString(now.subtract(const Duration(days: 1)), now), equals('Yesterday'));
      expect(RelativeDateText.getRelativeDateString(now.subtract(const Duration(days: 3)), now), equals('3 days ago'));
      expect(RelativeDateText.getRelativeDateString(now.subtract(const Duration(days: 8)), now), equals('Last week'));
      expect(RelativeDateText.getRelativeDateString(now.subtract(const Duration(days: 18)), now), equals('2 weeks ago'));
      expect(RelativeDateText.getRelativeDateString(now.subtract(const Duration(days: 62)), now), equals('2 months ago'));
    });

    test('Assigns correct weighted priority ranges', () async {
      final recallEngine = LocalRecallEngineServiceImpl();
      final testMemories = [
        Memory(
          id: 1,
          title: 'Flutter layout guide',
          content: 'Building screens with flutter layout rules',
          type: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: const ['guide', 'layout', 'draft'],
        ),
      ];

      // Exact title match (should be 100%)
      final resultExact = await recallEngine.recall(
        query: 'Flutter layout guide',
        memories: testMemories,
      );
      expect(resultExact.results.first.relevanceScore, equals(1.0));

      // Keyword match in title (should be in 85-89% range)
      final resultTitle = await recallEngine.recall(
        query: 'layout',
        memories: testMemories,
      );
      final scoreTitle = resultTitle.results.first.relevanceScore * 100;
      expect(scoreTitle >= 85.0 && scoreTitle <= 89.0, isTrue);

      // Keyword match in body (should be in 80-84% range)
      final resultBody = await recallEngine.recall(
        query: 'screens',
        memories: testMemories,
      );
      final scoreBody = resultBody.results.first.relevanceScore * 100;
      expect(scoreBody >= 80.0 && scoreBody <= 84.0, isTrue);

      // Tag match (should be in 75-79% range)
      final resultTag = await recallEngine.recall(
        query: 'draft',
        memories: testMemories,
      );
      final scoreTag = resultTag.results.first.relevanceScore * 100;
      expect(scoreTag >= 75.0 && scoreTag <= 79.0, isTrue);
    });
  });
}
