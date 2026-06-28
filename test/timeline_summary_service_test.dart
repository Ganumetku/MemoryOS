import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/services/timeline_summary_service.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';

void main() {
  group('TimelineSummaryService Tests', () {
    final now = DateTime.now();

    final List<Memory> testMemories = [
      // Today Work memory
      Memory(
        id: 1,
        title: 'Project kick off meeting with Rahul',
        content: 'Discussed architecture and deliverables.',
        type: 'Work',
        createdAt: now,
        updatedAt: now,
        tags: const [],
        reminderAt: DateTime(now.year, now.month, now.day, 14, 0), // 2 PM
      ),
      // Today Health completed reminder
      Memory(
        id: 2,
        title: 'Drink 2L water checkup',
        content: 'Stay hydrated.',
        type: 'Health',
        createdAt: now,
        updatedAt: now,
        tags: const ['completed_reminder'],
        reminderAt: DateTime(now.year, now.month, now.day, 10, 0), // 10 AM
      ),
      // Yesterday Work memory
      Memory(
        id: 3,
        title: 'Yesterday flutter layout tutorial draft',
        content: 'Built dark theme widgets.',
        type: 'Work',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        tags: const [],
      ),
      // 5 Days Ago learning memory
      Memory(
        id: 4,
        title: 'Learn dart streams',
        content: 'Studied async/await structures.',
        type: 'Learning',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        tags: const ['completed_reminder'],
        reminderAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    test('Generates natural summary correctly for Today', () {
      final summary = TimelineSummaryService.generate(
        memories: testMemories,
        period: 'Today',
      );

      expect(summary.naturalSummary, contains('Today you captured 2 memories.'));
      expect(summary.naturalSummary, contains('Most were related to'));
      expect(summary.emoji, equals('🌞'));
      expect(summary.insights.isNotEmpty, isTrue);
    });

    test('Generates natural summary correctly for Yesterday', () {
      final summary = TimelineSummaryService.generate(
        memories: testMemories,
        period: 'Yesterday',
      );

      expect(summary.naturalSummary, contains('Yesterday was a quieter day.'));
      expect(summary.naturalSummary, contains('recorded 1 memory.'));
      expect(summary.emoji, equals('🌙'));
    });

    test('Filters Correctly by 7 Days period and aggregates count', () {
      final summary = TimelineSummaryService.generate(
        memories: testMemories,
        period: 'Last 7 Days',
      );

      // Should contain Today, Yesterday, and 5 Days Ago = 4 memories
      expect(summary.naturalSummary, contains('captured 4 memories.'));
      expect(summary.emoji, equals('📈'));
    });

    test('Calculates top keywords correctly excluding filler words', () {
      final summary = TimelineSummaryService.generate(
        memories: testMemories,
        period: 'All Time',
      );

      expect(summary.naturalSummary, contains('Project'));
    });

    test('Gracefully handles empty lists', () {
      final summary = TimelineSummaryService.generate(
        memories: const [],
        period: 'Today',
      );

      expect(summary.naturalSummary, contains("You haven't captured any memories today."));
      expect(summary.productivityScore, equals(0.0));
    });
  });
}
