import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/memory_empty_state.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_loading_indicator.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../memories/presentation/bloc/memory_state.dart';

/// Reminder Center screen displaying all upcoming and past memory reminder logs.
class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  String _formatTimeOnly(DateTime date) {
    final minStr = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final int displayHour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    return '$displayHour:$minStr $suffix';
  }

  String _formatDateTimeShort(DateTime date) {
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
    final minStr = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final int displayHour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    return '${date.day} $monthStr • $displayHour:$minStr $suffix';
  }

  void _showReminderOptions(
    BuildContext context,
    Memory memory,
    MemoryCubit cubit,
  ) {
    final isCompleted = memory.tags.contains('completed_reminder');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.bgDarkSecondary,
            borderRadius: AppRadius.brTop24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reminder Controls',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.v16,
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.bgDarkTertiary,
                  child: Icon(
                    isCompleted ? Icons.undo : Icons.check_circle_outline,
                    color: isCompleted
                        ? AppColors.textDarkSecondary
                        : AppColors.success,
                  ),
                ),
                title: Text(
                  isCompleted ? 'Mark Incomplete' : 'Mark Completed',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  cubit.toggleReminderCompleted(memory);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.bgDarkTertiary,
                  child: Icon(
                    Icons.edit_calendar,
                    color: AppColors.brandPrimary,
                  ),
                ),
                title: Text(
                  'Reschedule Reminder',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _rescheduleFlow(context, memory, cubit);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.bgDarkTertiary,
                  child: Icon(
                    Icons.notifications_off_outlined,
                    color: AppColors.error,
                  ),
                ),
                title: Text(
                  'Cancel Reminder',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  cubit.cancelReminder(memory);
                },
              ),
              AppSpacing.v8,
            ],
          ),
        );
      },
    );
  }

  Future<void> _rescheduleFlow(
    BuildContext context,
    Memory memory,
    MemoryCubit cubit,
  ) async {
    await sl<NotificationService>().requestPermissions();
    if (!context.mounted) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: memory.reminderAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.bgDarkSecondary,
              onSurface: AppColors.textDarkPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(memory.reminderAt ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.bgDarkSecondary,
              onSurface: AppColors.textDarkPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && context.mounted) {
      final newTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      cubit.rescheduleReminder(memory, newTime);

      final formattedTime = _formatTimeOnly(newTime);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rescheduled reminder to $formattedTime.",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.brandPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryCubit>()..fetchMemories(),
      child: Scaffold(
        backgroundColor: AppColors.bgDarkPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgDarkPrimary,
          elevation: 0,
          leading: const BackButton(color: AppColors.textDarkPrimary),
          title: Text(
            'Reminder Center',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            if (kDebugMode)
              IconButton(
                icon: const Icon(
                  Icons.bug_report,
                  color: AppColors.brandPrimary,
                ),
                onPressed: () => context.push('/notification-debug').then((_) {
                  if (context.mounted) {
                    context.read<MemoryCubit>().fetchMemories();
                  }
                }),
              ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<MemoryCubit, MemoryState>(
            builder: (context, state) {
              final cubit = context.read<MemoryCubit>();

              if (state is MemoryLoading) {
                return const Center(child: MemoryLoadingIndicator());
              }

              if (state is MemoryError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (state is MemoryLoaded) {
                // Filter memories that have reminders
                final remindersList = state.memories
                    .where((m) => m.reminderAt != null)
                    .toList();

                // Sort by reminderAt (soonest first)
                remindersList.sort(
                  (a, b) => a.reminderAt!.compareTo(b.reminderAt!),
                );

                // Group by Today, Tomorrow, Later
                final todayReminders = remindersList
                    .where((m) => _isToday(m.reminderAt!))
                    .toList();
                final tomorrowReminders = remindersList
                    .where((m) => _isTomorrow(m.reminderAt!))
                    .toList();
                final laterReminders = remindersList.where((m) {
                  return !_isToday(m.reminderAt!) &&
                      !_isTomorrow(m.reminderAt!);
                }).toList();

                return ListView(
                  padding: AppSpacing.pAll16,
                  children: [
                    if (remindersList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: MemoryEmptyState(
                          icon: Icons.notifications_none,
                          title: 'Nothing scheduled.',
                          description: "I'll tell you when something matters.",
                        ),
                      )
                    else ...[
                      if (todayReminders.isNotEmpty) ...[
                        _buildHeaderSection('Today'),
                        AppSpacing.v12,
                        ...todayReminders.map(
                          (m) => _buildReminderCard(context, m, cubit, true),
                        ),
                        AppSpacing.v24,
                      ],
                      if (tomorrowReminders.isNotEmpty) ...[
                        _buildHeaderSection('Tomorrow'),
                        AppSpacing.v12,
                        ...tomorrowReminders.map(
                          (m) => _buildReminderCard(context, m, cubit, true),
                        ),
                        AppSpacing.v24,
                      ],
                      if (laterReminders.isNotEmpty) ...[
                        _buildHeaderSection('Later'),
                        AppSpacing.v12,
                        ...laterReminders.map(
                          (m) => _buildReminderCard(context, m, cubit, false),
                        ),
                        AppSpacing.v24,
                      ],
                    ],
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String title) {
    return Text(
      title,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textDarkTertiary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Memory m,
    MemoryCubit cubit,
    bool isShortTime,
  ) {
    final isCompleted = m.tags.contains('completed_reminder');
    final isMissed = !isCompleted && m.reminderAt!.isBefore(DateTime.now());

    // Status config
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isCompleted) {
      statusIcon = Icons.check_circle;
      statusColor = AppColors.textDarkTertiary;
      statusText = 'Completed';
    } else if (isMissed) {
      statusIcon = Icons.error_outline;
      statusColor = AppColors.error;
      statusText = 'Missed';
    } else {
      statusIcon = Icons.notifications_active_outlined;
      statusColor = AppColors.brandPrimary;
      statusText = 'Scheduled';
    }

    final reminderStr = isShortTime
        ? _formatTimeOnly(m.reminderAt!)
        : _formatDateTimeShort(m.reminderAt!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onLongPress: () => _showReminderOptions(context, m, cubit),
        child: MemoryGlassCard(
          padding: AppSpacing.pAll16,
          onTap: () => context
              .push('/memories/${m.id}')
              .then((_) => cubit.fetchMemories()),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withAlpha(20),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
              AppSpacing.h16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            m.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textDarkPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statusColor.withAlpha(50),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.v4,
                    Text(
                      reminderStr,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.v8,
                    Text(
                      m.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
