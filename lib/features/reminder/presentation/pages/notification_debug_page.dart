import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/memory_glass_card.dart';

class NotificationDebugPage extends StatefulWidget {
  const NotificationDebugPage({super.key});

  @override
  State<NotificationDebugPage> createState() => _NotificationDebugPageState();
}

class _NotificationDebugPageState extends State<NotificationDebugPage> {
  final NotificationService _notificationService = sl<NotificationService>();

  bool _notificationGranted = false;
  bool _exactAlarmAllowed = false;
  String _currentTimezone = 'Unknown';
  int _pendingCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // refresh current device time every second
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final granted = await _notificationService.requestPermissions();
    final exact = await _notificationService.canScheduleExactAlarms();
    final pendingList = await _notificationService.getPendingNotifications();

    if (mounted) {
      setState(() {
        _notificationGranted = granted;
        _exactAlarmAllowed = exact;
        _currentTimezone = tz.local.name;
        _pendingCount = pendingList.length;
      });
    }
  }

  String _formatTime(DateTime date) {
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');
    final secStr = date.second.toString().padLeft(2, '0');
    return '$hourStr:$minStr:$secStr';
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[date.month - 1];
    return '${date.day} $monthStr ${date.year} • ${_formatTime(date)}';
  }

  void _showPendingNotificationsDialog() async {
    final pending = await _notificationService.getPendingNotifications();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.bgDarkSecondary,
          title: Text(
            'Pending Notifications (${pending.length})',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: pending.isEmpty
                ? Text(
                    'No pending reminders.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final item = pending[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'ID: ${item.id} | ${item.title ?? "No Title"}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDarkPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item.body ?? 'No Content',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.brandPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastTime = _notificationService.lastScheduledTime;
    final lastId = _notificationService.lastScheduledId;
    final lastErr = _notificationService.lastErrorMessage;
    final primaryScheduled = _notificationService.isPrimaryScheduled;
    final fallbackScheduled = _notificationService.isFallbackScheduled;

    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkPrimary,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDarkPrimary),
        title: Text(
          'Notification Debug',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDarkPrimary),
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pAll16,
          children: [
            // Status Variables Card
            MemoryGlassCard(
              padding: AppSpacing.pAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Diagnostics',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.v16,
                  _buildStatusRow(
                    'Notification Permission',
                    _notificationGranted ? 'Granted' : 'Denied',
                    _notificationGranted ? AppColors.success : AppColors.error,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'Exact Alarm Permission',
                    _exactAlarmAllowed ? 'Allowed' : 'Restricted',
                    _exactAlarmAllowed ? AppColors.success : AppColors.error,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'Current Timezone',
                    _currentTimezone,
                    AppColors.brandPrimary,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'Current Device Time',
                    _formatTime(now),
                    AppColors.textDarkPrimary,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'Pending Reminders Count',
                    '$_pendingCount',
                    AppColors.brandPrimary,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'primary notification scheduled',
                    primaryScheduled ? 'true' : 'false',
                    primaryScheduled
                        ? AppColors.success
                        : AppColors.textDarkSecondary,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'fallback scheduled',
                    fallbackScheduled ? 'true' : 'false',
                    fallbackScheduled
                        ? AppColors.success
                        : AppColors.textDarkSecondary,
                  ),
                ],
              ),
            ),
            AppSpacing.v16,

            // History & Log Card
            MemoryGlassCard(
              padding: AppSpacing.pAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Scheduling Logs',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.v16,
                  _buildStatusRow(
                    'Last Scheduled Time',
                    lastTime != null ? _formatDateTime(lastTime) : 'None',
                    AppColors.textDarkSecondary,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'Last Scheduled ID',
                    lastId != null ? '$lastId' : 'None',
                    AppColors.textDarkSecondary,
                  ),
                  const Divider(color: AppColors.bgDarkTertiary, height: 24),
                  _buildStatusRow(
                    'Last Error Message',
                    lastErr ?? 'No errors reported',
                    lastErr != null
                        ? AppColors.error
                        : AppColors.textDarkSecondary,
                  ),
                ],
              ),
            ),
            AppSpacing.v16,

            // MIUI User Warning Banner
            Card(
              color: AppColors.error.withAlpha(26),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.error, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                    AppSpacing.h16,
                    Expanded(
                      child: Text(
                        "For reliable reminders, allow MemoryOS to run in background.",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDarkPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.v24,

            // Actions Buttons Section
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await _notificationService.showInstantTestNotification();
                await _refreshStatus();
              },
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: Text(
                'Show Instant Notification',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.v12,

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgDarkSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.brandPrimary,
                    width: 1,
                  ),
                ),
              ),
              onPressed: () async {
                final targetTime = DateTime.now().add(
                  const Duration(seconds: 30),
                );

                // Dynamic permissions verification
                final exactAllowed = await _notificationService
                    .canScheduleExactAlarms();
                if (!exactAllowed && context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please allow exact reminders in system settings.",
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                await _notificationService.scheduleReminder(
                  id: 8888,
                  title: '30-Second Test Reminder',
                  body: 'This notification was scheduled 30 seconds ago.',
                  scheduledDate: targetTime,
                );

                await _refreshStatus();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Scheduled 30-sec reminder at ${_formatTime(targetTime)}",
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.timer_outlined,
                color: AppColors.brandPrimary,
              ),
              label: Text(
                'Schedule 30 Second Notification',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.v12,

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgDarkSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.bgDarkTertiary,
                    width: 1,
                  ),
                ),
              ),
              onPressed: _showPendingNotificationsDialog,
              icon: const Icon(
                Icons.list_alt_outlined,
                color: AppColors.textDarkSecondary,
              ),
              label: Text(
                'List Pending Notifications',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.v12,

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgDarkSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.bgDarkTertiary,
                    width: 1,
                  ),
                ),
              ),
              onPressed: () async {
                await _notificationService.openNotificationSettings();
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textDarkSecondary,
              ),
              label: Text(
                'Open App Notification Settings',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.v12,

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgDarkSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.bgDarkTertiary,
                    width: 1,
                  ),
                ),
              ),
              onPressed: () async {
                await _notificationService.openBatteryOptimizationSettings();
              },
              icon: const Icon(
                Icons.battery_charging_full_outlined,
                color: AppColors.textDarkSecondary,
              ),
              label: Text(
                'Open Battery Optimization Settings',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDarkSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
