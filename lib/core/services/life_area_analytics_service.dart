import 'package:isar/isar.dart';
import '../../features/memories/data/models/memory_model.dart';
import '../entities/life_area.dart';

class LifeAreaAnalyticsService {
  final Isar? _isar;

  LifeAreaAnalyticsService(this._isar);

  Future<Map<String, double>> getLifeBalance() async {
    if (_isar == null) return {};
    final allMemories = await _isar.memoryModels.where().findAll();
    if (allMemories.isEmpty) {
      return {};
    }

    final counts = <String, int>{};
    for (final area in LifeArea.values) {
      counts[area.name] = 0;
    }

    for (final m in allMemories) {
      final normalizedType = LifeArea.fromName(m.type).name;
      counts[normalizedType] = (counts[normalizedType] ?? 0) + 1;
    }

    final total = allMemories.length;
    final Map<String, double> percentages = {};
    for (final entry in counts.entries) {
      if (entry.value > 0) {
        percentages[entry.key] = (entry.value / total) * 100;
      }
    }

    return percentages;
  }

  Future<Map<String, String>> getLifeAreaInsights() async {
    if (_isar == null) return {};
    final allMemories = await _isar.memoryModels.where().findAll();
    if (allMemories.isEmpty) {
      return {};
    }

    final counts = <String, int>{};
    for (final area in LifeArea.values) {
      counts[area.name] = 0;
    }

    for (final m in allMemories) {
      final normalizedType = LifeArea.fromName(m.type).name;
      counts[normalizedType] = (counts[normalizedType] ?? 0) + 1;
    }

    // Most Active
    String mostActive = LifeArea.other.name;
    int maxCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostActive = entry.key;
      }
    }

    // Least Active (having at least 1 memory)
    String leastActive = LifeArea.other.name;
    int minCount = 999999;
    bool foundLeast = false;
    for (final entry in counts.entries) {
      if (entry.value > 0 && entry.value < minCount) {
        minCount = entry.value;
        leastActive = entry.key;
        foundLeast = true;
      }
    }
    if (!foundLeast) {
      leastActive = 'None';
    }

    // Neglected Area (0 memories in last 7 days but has at least 1 overall)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentMemories = allMemories.where((m) => m.createdAt.isAfter(sevenDaysAgo)).toList();

    final recentCounts = <String, int>{};
    for (final area in LifeArea.values) {
      recentCounts[area.name] = 0;
    }
    for (final m in recentMemories) {
      final normalizedType = LifeArea.fromName(m.type).name;
      recentCounts[normalizedType] = (recentCounts[normalizedType] ?? 0) + 1;
    }

    String neglected = 'None';
    int highestTotalOfNeglected = -1;
    for (final area in LifeArea.values) {
      if (counts[area.name]! > 0 && recentCounts[area.name] == 0) {
        if (counts[area.name]! > highestTotalOfNeglected) {
          highestTotalOfNeglected = counts[area.name]!;
          neglected = area.name;
        }
      }
    }

    // Growing Area: most memories in last 7 days
    String growing = 'None';
    int maxRecentCount = 0;
    for (final entry in recentCounts.entries) {
      if (entry.value > maxRecentCount) {
        maxRecentCount = entry.value;
        growing = entry.key;
      }
    }

    return {
      'most_active': mostActive,
      'least_active': leastActive,
      'neglected': neglected,
      'growing': growing,
    };
  }

  /// Calculates total memories per area.
  Future<Map<String, int>> getTotalMemoriesPerArea() async {
    if (_isar == null) return {};
    final allMemories = await _isar.memoryModels.where().findAll();
    
    final counts = <String, int>{};
    for (final area in LifeArea.values) {
      counts[area.name] = 0;
    }

    for (final m in allMemories) {
      final normalizedType = LifeArea.fromName(m.type).name;
      counts[normalizedType] = (counts[normalizedType] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Calculates growth percentage (last 7 days vs previous 7 days) per area.
  Future<Map<String, String>> getGrowthPercentagePerArea() async {
    if (_isar == null) return {};
    final allMemories = await _isar.memoryModels.where().findAll();
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final currentWeek = <String, int>{};
    final prevWeek = <String, int>{};

    for (final area in LifeArea.values) {
      currentWeek[area.name] = 0;
      prevWeek[area.name] = 0;
    }

    for (final m in allMemories) {
      final area = LifeArea.fromName(m.type).name;
      if (m.createdAt.isAfter(sevenDaysAgo)) {
        currentWeek[area] = (currentWeek[area] ?? 0) + 1;
      } else if (m.createdAt.isAfter(fourteenDaysAgo)) {
        prevWeek[area] = (prevWeek[area] ?? 0) + 1;
      }
    }

    final growth = <String, String>{};
    for (final area in LifeArea.values) {
      final current = currentWeek[area.name] ?? 0;
      final prev = prevWeek[area.name] ?? 0;

      if (prev == 0) {
        growth[area.name] = current > 0 ? '+100%' : '0%';
      } else {
        final diff = current - prev;
        final pct = (diff / prev) * 100;
        final sign = pct > 0 ? '+' : '';
        growth[area.name] = '$sign${pct.toStringAsFixed(0)}%';
      }
    }

    return growth;
  }

  /// Retrieves memories created per area this week.
  Future<Map<String, int>> getWeeklyMemoriesPerArea() async {
    if (_isar == null) return {};
    final allMemories = await _isar.memoryModels.where().findAll();
    
    final now = DateTime.now();
    // Usually "this week" could be from Monday, but for simplicity we'll use last 7 days here or a fixed start of week
    // Just using last 7 days
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final counts = <String, int>{};
    for (final area in LifeArea.values) {
      counts[area.name] = 0;
    }

    for (final m in allMemories) {
      if (m.createdAt.isAfter(weekStart)) {
        final area = LifeArea.fromName(m.type).name;
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Retrieves memories created per area this month.
  Future<Map<String, int>> getMonthlyMemoriesPerArea() async {
    if (_isar == null) return {};
    final allMemories = await _isar.memoryModels.where().findAll();
    
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final counts = <String, int>{};
    for (final area in LifeArea.values) {
      counts[area.name] = 0;
    }

    for (final m in allMemories) {
      if (m.createdAt.isAfter(monthStart)) {
        final area = LifeArea.fromName(m.type).name;
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }

    return counts;
  }
}
