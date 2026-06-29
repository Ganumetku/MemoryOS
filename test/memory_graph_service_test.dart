import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/services/memory_graph_service.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';
import 'package:memory_os/app/di/service_locator.dart';
import 'package:memory_os/core/services/life_area_service.dart';
import 'package:memory_os/core/parser/life_area_parser.dart';

void main() {
  group('MemoryGraphService Tests', () {
    late MemoryGraphService graphService;
    final now = DateTime.now();

    setUp(() {
      if (!sl.isRegistered<LifeAreaService>()) {
        sl.registerLazySingleton<LifeAreaService>(
          () => LifeAreaService(LifeAreaParser(), null as dynamic),
        );
      }
      graphService = MemoryGraphService(null as dynamic);
    });

    final target = Memory(
      id: 1,
      title: 'Doctor checkup with Dr Rahul',
      content: 'Meeting notes on health appointment with Dr Rahul.',
      type: 'Health',
      createdAt: now,
      updatedAt: now,
      tags: const ['health', 'doctor'],
      reminderAt: DateTime(now.year, now.month, now.day, 15, 0),
    );

    test('Calculates strong connection for overlapping type, keywords, and dates', () {
      final candidate = Memory(
        id: 2,
        title: 'Dr Rahul appointment at hospital',
        content: 'Health medicine update with Dr Rahul.',
        type: 'Health',
        createdAt: now.add(const Duration(hours: 4)),
        updatedAt: now,
        tags: const ['health'],
        reminderAt: DateTime(now.year, now.month, now.day, 18, 0),
      );

      final connections = graphService.getConnections(target, [candidate]);
      expect(connections, isNotEmpty);
      final conn = connections.first;
      expect(conn.strength, equals(ConnectionStrength.strong));
      expect(conn.similarityPercentage, greaterThanOrEqualTo(75));

      // Assert reasons list contains specific categories
      final reasonTexts = conn.reasons.map((r) => r.text).toList();
      expect(reasonTexts, contains('Same life area: Health'));
      expect(reasonTexts, contains('Created on the same day'));
      expect(reasonTexts, contains('Same reminder journey'));
    });

    test('Calculates related connection for partial overlap', () {
      final candidate = Memory(
        id: 3,
        title: 'Meeting notes',
        content: 'Discuss startup project with Rahul.',
        type: 'Work',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
        tags: const ['project'],
      );

      final connections = graphService.getConnections(target, [candidate]);
      expect(connections, isNotEmpty);
      final conn = connections.first;
      expect(conn.strength, equals(ConnectionStrength.lightlyRelated));
    });

    test('Caches graph results correctly and clears cache', () {
      final candidate = Memory(
        id: 4,
        title: 'Doctor appointment',
        content: 'Health medicine.',
        type: 'Health',
        createdAt: now,
        updatedAt: now,
        tags: const [],
      );

      final firstRun = graphService.getConnections(target, [candidate]);
      final secondRun = graphService.getConnections(target, [candidate]);

      // Cache hit test
      expect(firstRun, same(secondRun));

      // Cache invalidation test
      graphService.clearCache();
      final thirdRun = graphService.getConnections(target, [candidate]);
      expect(firstRun, isNot(same(thirdRun)));
    });
  });
}
