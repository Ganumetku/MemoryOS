import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/life_area_analytics_service.dart';
import '../../../memories/data/models/follow_up_model.dart';

class DeveloperDashboardPage extends StatefulWidget {
  const DeveloperDashboardPage({super.key});

  @override
  State<DeveloperDashboardPage> createState() => _DeveloperDashboardPageState();
}

class _DeveloperDashboardPageState extends State<DeveloperDashboardPage> {
  late final AnalyticsService _analytics;
  late final NotificationService _notifications;
  late final LifeAreaAnalyticsService _lifeAreaAnalytics;
  late final Isar _isar;

  @override
  void initState() {
    super.initState();
    _analytics = sl<AnalyticsService>();
    _notifications = sl<NotificationService>();
    _lifeAreaAnalytics = sl<LifeAreaAnalyticsService>();
    _isar = sl<Isar>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDarkPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Developer Dashboard',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadDashboardData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading stats: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }

            final data = snapshot.data ?? {};

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                _buildHeader('System Health'),
                _buildSystemHealthCard(data),
                AppSpacing.v24,

                _buildHeader('Database Stats'),
                _buildDatabaseStatsCard(data),
                AppSpacing.v24,

                _buildHeader('Analytics telemetry'),
                _buildAnalyticsCard(data),
                AppSpacing.v24,

                _buildHeader('Life Area Analytics'),
                _buildLifeAreaAnalyticsCard(data),
                AppSpacing.v24,

                _buildHeader('Reminder Stats'),
                _buildReminderStatsCard(data),
                AppSpacing.v24,

                _buildHeader('Parser Stats'),
                _buildParserStatsCard(data),
                AppSpacing.v24,

                _buildHeader('Notification Stats'),
                _buildNotificationStatsCard(data),
                AppSpacing.v24,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textDarkTertiary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSystemHealthCard(Map<String, dynamic> data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          _buildRow('Database status', data['db_status']),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Platform', data['platform']),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('App Version', '1.0.0 (Build 1)'),
        ],
      ),
    );
  }

  Widget _buildDatabaseStatsCard(Map<String, dynamic> data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          _buildRow('Total Memories', '${data['total_memories']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Total Follow-ups', '${data['total_followups']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Database Path', data['db_path'], subtitleMode: true),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> data) {
    final dist = data['type_distribution'] as Map<String, int>;
    final distText = dist.isEmpty 
        ? 'None' 
        : dist.entries.map((e) => '${e.key.toUpperCase()}: ${e.value}').join(', ');

    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          _buildRow('Search Count', '${data['search_count']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Text Capture Count', '${data['capture_text']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Voice Capture Count', '${data['capture_voice']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Camera Capture Count', '${data['capture_camera']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Current Capture Streak', '${data['current_streak']} days'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Longest Capture Streak', '${data['longest_streak']} days'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Memories created today', '${data['memories_today']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Memories this week', '${data['memories_week']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Memories this month', '${data['memories_month']}'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Average memories / day', data['avg_memories_day']),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Type Distribution', distText, subtitleMode: true),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Most Opened Memory', data['most_opened_title'] ?? 'None'),
        ],
      ),
    );
  }

  Widget _buildLifeAreaAnalyticsCard(Map<String, dynamic> data) {
    final Map<String, int> totalPerArea = data['life_area_total'];
    final Map<String, String> growthPerArea = data['life_area_growth'];
    final Map<String, int> weeklyPerArea = data['life_area_weekly'];
    final Map<String, int> monthlyPerArea = data['life_area_monthly'];

    if (totalPerArea.isEmpty) {
      return MemoryGlassCard(
        padding: AppSpacing.pAll16,
        child: const Text(
          'No Life Area data available yet.',
          style: TextStyle(color: AppColors.textDarkSecondary),
        ),
      );
    }

    final children = <Widget>[];

    for (final area in totalPerArea.keys) {
      final total = totalPerArea[area] ?? 0;
      if (total == 0) continue; // Only show areas that have memories
      
      final growth = growthPerArea[area] ?? '0%';
      final weekly = weeklyPerArea[area] ?? 0;
      final monthly = monthlyPerArea[area] ?? 0;

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total: $total',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDarkSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Growth: $growth',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: growth.startsWith('-') ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Weekly: $weekly',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDarkSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Monthly: $monthly',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDarkSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.bgDarkTertiary),
            ],
          ),
        ),
      );
    }

    if (children.isNotEmpty) {
      // Remove the last divider
      children.removeLast();
    }

    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildReminderStatsCard(Map<String, dynamic> data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          _buildRow('Reminder completion rate', '${data['reminder_completion']}%'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Reminder miss rate', '${data['reminder_miss']}%'),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Total notification alerts fired', '${data['notifications_fired']}'),
        ],
      ),
    );
  }

  Widget _buildParserStatsCard(Map<String, dynamic> data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          _buildRow('Most common category', data['most_common_category']),
          const Divider(color: AppColors.bgDarkTertiary),
          _buildRow('Most common keyword', data['most_common_keyword']),
        ],
      ),
    );
  }

  Widget _buildNotificationStatsCard(Map<String, dynamic> data) {
    final List<PendingNotificationRequest> pending = data['pending_notifications'];
    
    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Pending scheduled count', '${pending.length}'),
          if (pending.isNotEmpty) ...[
            const Divider(color: AppColors.bgDarkTertiary),
            const SizedBox(height: 8),
            Text(
              'Scheduled Queue Details:',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pending.map((req) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${req.id}',
                        style: const TextStyle(
                          color: AppColors.brandPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.title ?? 'No Title',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDarkPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            req.body ?? 'No Body',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDarkSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool subtitleMode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: subtitleMode
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final dbStatus = _isar.isOpen ? 'Open & Healthy' : 'Disconnected';
    final platform = Theme.of(context).platform.name;
    final totalMemories = await _analytics.getTotalMemories();
    final totalFollowups = await _isar.followUpModels.count();
    final dbPath = _isar.path ?? 'Unknown';

    final searchCount = _analytics.getSearchCount();
    final captureText = _analytics.getCaptureCount('text');
    final captureVoice = _analytics.getCaptureCount('voice');
    final captureCamera = _analytics.getCaptureCount('camera');
    final memoriesToday = await _analytics.getMemoriesCreatedToday();
    final memoriesWeek = await _analytics.getMemoriesCreatedThisWeek();
    final memoriesMonth = await _analytics.getMemoriesCreatedThisMonth();
    
    final currentStreak = await _analytics.getCurrentStreak();
    final longestStreak = await _analytics.getLongestStreak();

    final completionRate = await _analytics.getReminderCompletionRate();
    final missRate = await _analytics.getReminderMissRate();
    final notificationsFired = _analytics.getNotificationsFiredCount();

    final avgMemPerDay = await _analytics.getAverageMemoriesPerDay();
    final avgText = avgMemPerDay.toStringAsFixed(2);

    final typeDistribution = await _analytics.getMemoryTypeDistribution();
    final mostCommonCategory = await _analytics.getMostCommonCategory();
    final mostCommonKeyword = await _analytics.getMostCommonKeyword();
    
    final mostOpenedMemory = await _analytics.getMostOpenedMemory();
    final mostOpenedTitle = mostOpenedMemory != null 
        ? '${mostOpenedMemory.title} (${mostOpenedMemory.type})'
        : 'None';

    final pending = await _notifications.getPendingNotifications();

    final lifeAreaTotal = await _lifeAreaAnalytics.getTotalMemoriesPerArea();
    final lifeAreaGrowth = await _lifeAreaAnalytics.getGrowthPercentagePerArea();
    final lifeAreaWeekly = await _lifeAreaAnalytics.getWeeklyMemoriesPerArea();
    final lifeAreaMonthly = await _lifeAreaAnalytics.getMonthlyMemoriesPerArea();

    return {
      'db_status': dbStatus,
      'platform': platform,
      'total_memories': totalMemories,
      'total_followups': totalFollowups,
      'db_path': dbPath,
      'search_count': searchCount,
      'capture_text': captureText,
      'capture_voice': captureVoice,
      'capture_camera': captureCamera,
      'memories_today': memoriesToday,
      'memories_week': memoriesWeek,
      'memories_month': memoriesMonth,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'reminder_completion': completionRate.toStringAsFixed(1),
      'reminder_miss': missRate.toStringAsFixed(1),
      'notifications_fired': notificationsFired,
      'avg_memories_day': avgText,
      'type_distribution': typeDistribution,
      'most_common_category': mostCommonCategory,
      'most_common_keyword': mostCommonKeyword,
      'most_opened_title': mostOpenedTitle,
      'pending_notifications': pending,
      'life_area_total': lifeAreaTotal,
      'life_area_growth': lifeAreaGrowth,
      'life_area_weekly': lifeAreaWeekly,
      'life_area_monthly': lifeAreaMonthly,
    };
  }
}
