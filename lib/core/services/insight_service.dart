import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/memories/data/models/memory_model.dart';
import '../../app/di/service_locator.dart';
import 'life_area_service.dart';

class AppInsight {
  final IconData icon;
  final String headline;
  final String description;

  AppInsight({
    required this.icon,
    required this.headline,
    required this.description,
  });
}

class InsightsResult {
  final List<AppInsight> insights;
  final bool hasEnoughData;

  InsightsResult({
    required this.insights,
    required this.hasEnoughData,
  });
}

class InsightService {
  final Isar _isar;
  final SharedPreferences _prefs;

  static const Set<String> _stopWords = {
    'the', 'is', 'at', 'which', 'on', 'in', 'a', 'an', 'and', 'or', 'to', 'with',
    'for', 'of', 'it', 'that', 'this', 'my', 'i', 'you', 'he', 'she', 'we', 'they',
    'was', 'as', 'are', 'be', 'from', 'by', 'but', 'not', 'have', 'has', 'had',
    'what', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few',
    'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'too', 'very', 'can',
    'will', 'just', 'should', 'now', 'do', 'does', 'did', 'am', 'me', 'us',
    'so', 'if', 'then', 'than', 'about', 'out', 'up', 'down', 'over', 'under',
  };

  InsightService(this._isar, this._prefs);

  Future<InsightsResult> getInsights() async {
    final all = await _isar.memoryModels.where().findAll();
    if (all.length < 5) {
      return InsightsResult(insights: [], hasEnoughData: false);
    }

    final pool = <AppInsight>[];

    // 1. Most common category
    final typeCounts = <String, int>{};
    for (final m in all) {
      typeCounts[m.type] = (typeCounts[m.type] ?? 0) + 1;
    }
    if (typeCounts.isNotEmpty) {
      final sorted = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final favorite = sorted.first.key;
      pool.add(AppInsight(
        icon: Icons.bookmark_added_outlined,
        headline: "Favorite Theme: $favorite",
        description: "You save memories about '$favorite' more than any other category.",
      ));
    }

    // 2. Most active day
    final dayCounts = <int, int>{};
    for (final m in all) {
      dayCounts[m.createdAt.weekday] = (dayCounts[m.createdAt.weekday] ?? 0) + 1;
    }
    if (dayCounts.isNotEmpty) {
      final sorted = dayCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final activeDayNum = sorted.first.key;
      final weekdays = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      final activeDayStr = weekdays[activeDayNum];
      pool.add(AppInsight(
        icon: Icons.calendar_month_outlined,
        headline: "Active $activeDayStr",
        description: "You tend to capture most of your memories on ${activeDayStr}s.",
      ));
    }

    // 3. Most active hour
    int morning = 0;
    int afternoon = 0;
    int evening = 0;
    int night = 0;
    for (final m in all) {
      final hour = m.createdAt.hour;
      if (hour >= 5 && hour < 12) {
        morning++;
      } else if (hour >= 12 && hour < 17) {
        afternoon++;
      } else if (hour >= 17 && hour < 21) {
        evening++;
      } else {
        night++;
      }
    }
    final Map<String, int> times = {"Morning": morning, "Afternoon": afternoon, "Evening": evening, "Night": night};
    final sortedTimes = times.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sortedTimes.first.value > 0) {
      final activeTime = sortedTimes.first.key;
      IconData hourIcon = Icons.wb_sunny_outlined;
      if (activeTime == "Night") hourIcon = Icons.nightlight_round_outlined;
      if (activeTime == "Evening") hourIcon = Icons.wb_twilight;
      pool.add(AppInsight(
        icon: hourIcon,
        headline: "$activeTime Creator",
        description: "Most of your thoughts and life fragments are captured during the $activeTime.",
      ));
    }

    // 4. Capture streak
    final uniqueDays = all.map((m) => DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day)).toSet();
    int streak = 0;
    DateTime checkDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!uniqueDays.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    while (uniqueDays.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    if (streak > 0) {
      pool.add(AppInsight(
        icon: Icons.local_fire_department_outlined,
        headline: "$streak Day Streak",
        description: "You've captured memories $streak day${streak == 1 ? '' : 's'} in a row. Keep it up!",
      ));
    }

    // 5. Completed reminders %
    final reminders = all.where((m) => m.reminderAt != null).toList();
    if (reminders.isNotEmpty) {
      final completed = reminders.where((m) => m.tags.contains('completed_reminder')).length;
      final pct = ((completed / reminders.length) * 100).round();
      pool.add(AppInsight(
        icon: Icons.check_circle_outline,
        headline: "Reminders Master: $pct%",
        description: "You have completed $pct% of your scheduled reminders.",
      ));
    }

    // 6. Missed reminders %
    if (reminders.isNotEmpty) {
      final now = DateTime.now();
      final missed = reminders.where((m) => !m.tags.contains('completed_reminder') && m.reminderAt!.isBefore(now)).length;
      final pct = ((missed / reminders.length) * 100).round();
      if (pct > 0) {
        pool.add(AppInsight(
          icon: Icons.error_outline_outlined,
          headline: "Overdue Rate: $pct%",
          description: "$pct% of your reminders passed without being completed.",
        ));
      }
    }

    // 7. Personal vs Work %
    final personalCount = all.where((m) => m.type.toLowerCase() == 'personal').length;
    final workCount = all.where((m) => m.type.toLowerCase() == 'work').length;
    if (personalCount > 0 || workCount > 0) {
      final total = personalCount + workCount;
      if (total > 0) {
        final personalPct = ((personalCount / total) * 100).round();
        final workPct = 100 - personalPct;
        pool.add(AppInsight(
          icon: Icons.pie_chart_outline_outlined,
          headline: "Work-Life Split: $personalPct% / $workPct%",
          description: "Your captures are split into $personalPct% Personal and $workPct% Work memories.",
        ));
      }
    }

    // 8. Ideas captured
    final ideasCount = all.where((m) => m.type.toLowerCase() == 'idea').length;
    if (ideasCount > 0) {
      pool.add(AppInsight(
        icon: Icons.lightbulb_outline,
        headline: "$ideasCount Idea${ideasCount == 1 ? '' : 's'} Captured",
        description: "You have stored $ideasCount flashes of inspiration in your memory vault.",
      ));
    }

    // 9. Upcoming reminders
    final upcomingCount = all.where((m) => m.reminderAt != null && m.reminderAt!.isAfter(DateTime.now())).length;
    if (upcomingCount > 0) {
      pool.add(AppInsight(
        icon: Icons.notification_important_outlined,
        headline: "$upcomingCount Upcoming Reminder${upcomingCount == 1 ? '' : 's'}",
        description: "You have $upcomingCount reminder${upcomingCount == 1 ? '' : 's'} scheduled for future followups.",
      ));
    }

    // 10. Longest inactive period
    final sortedAsc = all.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    int maxInactiveDays = 0;
    for (int i = 0; i < sortedAsc.length - 1; i++) {
      final diff = sortedAsc[i + 1].createdAt.difference(sortedAsc[i].createdAt).inDays;
      if (diff > maxInactiveDays) {
        maxInactiveDays = diff;
      }
    }
    if (maxInactiveDays > 1) {
      pool.add(AppInsight(
        icon: Icons.hourglass_empty_outlined,
        headline: "Inactive Gap: $maxInactiveDays Days",
        description: "Your longest break between capturing memories was $maxInactiveDays days.",
      ));
    }

    // 11. Most common keyword
    final keywordCounts = <String, int>{};
    for (final m in all) {
      final titleWords = _extractKeywords(m.title);
      final contentWords = _extractKeywords(m.content);
      for (final w in titleWords.union(contentWords)) {
        keywordCounts[w] = (keywordCounts[w] ?? 0) + 1;
      }
    }
    if (keywordCounts.isNotEmpty) {
      final sortedKeywords = keywordCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topKeyword = sortedKeywords.first.key;
      pool.add(AppInsight(
        icon: Icons.key_outlined,
        headline: "Core Focus: $topKeyword",
        description: "The keyword '$topKeyword' appears in ${sortedKeywords.first.value} of your captured memories.",
      ));
    }

    // Life Area Insights
    try {
      final lifeAreaService = sl<LifeAreaService>();
      final areaInsights = await lifeAreaService.getLifeAreaInsights();
      if (areaInsights.isNotEmpty) {
        final mostActive = areaInsights['most_active'];
        final leastActive = areaInsights['least_active'];
        final neglected = areaInsights['neglected'];
        final growing = areaInsights['growing'];

        if (mostActive != null && mostActive != 'Daily Life') {
          pool.add(AppInsight(
            icon: Icons.star_outline,
            headline: "Most Active: $mostActive",
            description: "Your $mostActive area has the highest concentration of memories.",
          ));
        }

        if (leastActive != null && leastActive != 'None' && leastActive != 'Daily Life') {
          pool.add(AppInsight(
            icon: Icons.trending_flat,
            headline: "Least Active: $leastActive",
            description: "Your $leastActive area has the lowest number of captured memories.",
          ));
        }

        if (neglected != null && neglected != 'None') {
          pool.add(AppInsight(
            icon: Icons.warning_amber_outlined,
            headline: "Neglected Area: $neglected",
            description: "You haven't captured any memories in '$neglected' for the last 7 days.",
          ));
        }

        if (growing != null && growing != 'None') {
          pool.add(AppInsight(
            icon: Icons.trending_up,
            headline: "Growing Area: $growing",
            description: "Your '$growing' area is growing fast, with the most captures this week.",
          ));
        }
      }
    } catch (_) {}

    if (pool.isEmpty) {
      return InsightsResult(insights: [], hasEnoughData: false);
    }

    // Rotate on every retrieval
    final offset = _prefs.getInt('insight_rotation_offset') ?? 0;
    await _prefs.setInt('insight_rotation_offset', offset + 1);

    final selected = <AppInsight>[];
    final countToTake = pool.length < 3 ? pool.length : 3;
    for (int i = 0; i < countToTake; i++) {
      selected.add(pool[(offset + i) % pool.length]);
    }

    return InsightsResult(insights: selected, hasEnoughData: true);
  }

  Set<String> _extractKeywords(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty && !_stopWords.contains(w) && w.length > 2).toSet();
  }
}
