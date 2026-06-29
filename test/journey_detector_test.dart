import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/services/journey_detector.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';

void main() {
  group('JourneyDetector Tests', () {
    final now = DateTime.now();

    test('Detects Health Journey when 3 health memories cluster in 30 days', () {
      final m1 = Memory(
        id: 1,
        title: 'Checkup doctor',
        content: 'Went to clinic.',
        type: 'Health',
        createdAt: now,
        updatedAt: now,
        tags: const [],
      );

      final m2 = Memory(
        id: 2,
        title: 'Medicine check',
        content: 'Pills bought.',
        type: 'Health',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
        tags: const [],
      );

      final m3 = Memory(
        id: 3,
        title: 'Running 5k fitness',
        content: 'Feeling good.',
        type: 'Health',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
        tags: const [],
      );

      final journey = JourneyDetector.detectJourney(m1, [m1, m2, m3]);
      expect(journey, equals('Health'));
    });

    test('Detects Flutter Learning Journey when 3 flutter topic memories cluster', () {
      final m1 = Memory(
        id: 1,
        title: 'Flutter layout tutorial',
        content: 'Studied row and column widgets.',
        type: 'Learning',
        createdAt: now,
        updatedAt: now,
        tags: const [],
      );

      final m2 = Memory(
        id: 2,
        title: 'Dart streams guide',
        content: 'Learned flutter streambuilder usage.',
        type: 'Learning',
        createdAt: now.add(const Duration(days: 2)),
        updatedAt: now,
        tags: const [],
      );

      final m3 = Memory(
        id: 3,
        title: 'State management with flutter bloc',
        content: 'Setup local provider.',
        type: 'Learning',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        tags: const [],
      );

      final journey = JourneyDetector.detectJourney(m1, [m1, m2, m3]);
      expect(journey, equals('Flutter Learning'));
    });

    test('Returns null when memories are sparse or not matching topics', () {
      final m1 = Memory(
        id: 1,
        title: 'Doctor checkup',
        content: 'No problem.',
        type: 'Health',
        createdAt: now,
        updatedAt: now,
        tags: const [],
      );

      final m2 = Memory(
        id: 2,
        title: 'Office work meeting',
        content: 'Work notes.',
        type: 'Work',
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now,
        tags: const [],
      );

      final journey = JourneyDetector.detectJourney(m1, [m1, m2]);
      expect(journey, isNull);
    });
  });
}
