import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/memory_brain_service.dart';
import '../../../../core/utils/memory_type_helper.dart';
import '../../../../features/memories/domain/entities/memory.dart';
import '../../../../shared/widgets/memory_glass_card.dart';

class MemorySummaryCard extends StatelessWidget {
  final MemoryBrainResult brainResult;
  final VoidCallback? onOpenTimeline;
  final void Function(Memory?)? onOpenReminder;
  final void Function(Memory?)? onReschedule;
  final void Function(Memory?)? onCompleteReminder;
  final void Function(String)? onViewCategory;

  const MemorySummaryCard({
    super.key,
    required this.brainResult,
    this.onOpenTimeline,
    this.onOpenReminder,
    this.onReschedule,
    this.onCompleteReminder,
    this.onViewCategory,
  });

  @override
  Widget build(BuildContext context) {
    final answer = brainResult.naturalAnswer;
    if (answer.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withAlpha(35),
            AppColors.brandSecondary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.brandPrimary.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: MemoryGlassCard(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  '🧠',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memory Brain',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Local Intelligence',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDarkTertiary.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Natural Answer text
            Text(
              answer,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textDarkPrimary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Chips/Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Count Pill
                _buildPill(
                  icon: Icons.inventory_2_outlined,
                  label: '${brainResult.count} ${brainResult.count == 1 ? "memory" : "memories"}',
                  color: AppColors.brandPrimary,
                ),

                // Category Pill
                if (brainResult.relevantCategory != null) ...[
                  _buildCategoryPill(brainResult.relevantCategory!),
                ],

                // Reminder Status Pill
                if (brainResult.relevantReminderStatus != null) ...[
                  _buildReminderStatusPill(brainResult.relevantReminderStatus!),
                ],
              ],
            ),

            // Action Buttons Wrap/Stack
            if (brainResult.actionLabels.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.glassDarkBorder, height: 1),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 360;

                  final buttons = brainResult.actionLabels.map((label) {
                    final isComplete = label == "Mark Complete";
                    final isReschedule = label == "Reschedule";

                    Color btnColor = AppColors.brandPrimary.withAlpha(45);
                    Color borderColor = AppColors.brandPrimary;
                    IconData icon = _getActionIcon(label);

                    if (isComplete) {
                      btnColor = AppColors.success.withAlpha(45);
                      borderColor = AppColors.success;
                    } else if (isReschedule) {
                      btnColor = AppColors.error.withAlpha(45);
                      borderColor = AppColors.error;
                    }

                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: borderColor, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: Icon(icon, size: 16, color: isComplete ? AppColors.success : (isReschedule ? AppColors.error : Colors.white)),
                      label: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => _handleAction(label),
                    );
                  }).toList();

                  if (isSmall) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: buttons.map((btn) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: btn,
                      )).toList(),
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: buttons,
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String category) {
    final config = MemoryTypeHelper.getConfig(category);
    return _buildPill(
      icon: config.icon,
      label: category,
      color: config.color,
    );
  }

  Widget _buildReminderStatusPill(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'upcoming':
        color = Colors.cyan;
        icon = Icons.alarm;
        break;
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case 'missed':
        color = AppColors.error;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return _buildPill(
      icon: icon,
      label: status,
      color: color,
    );
  }

  IconData _getActionIcon(String label) {
    if (label.contains('Timeline')) return Icons.dashboard;
    if (label.contains('Reminder')) return Icons.alarm;
    if (label.contains('Complete')) return Icons.check_circle_outline;
    if (label.contains('Reschedule')) return Icons.history;
    return Icons.category_outlined;
  }

  void _handleAction(String label) {
    if (label.contains('Timeline')) {
      onOpenTimeline?.call();
    } else if (label.contains('Reminder')) {
      onOpenReminder?.call(brainResult.targetMemory);
    } else if (label.contains('Category')) {
      if (brainResult.relevantCategory != null) {
        onViewCategory?.call(brainResult.relevantCategory!);
      }
    } else if (label.contains('Reschedule')) {
      onReschedule?.call(brainResult.targetMemory);
    } else if (label.contains('Complete')) {
      onCompleteReminder?.call(brainResult.targetMemory);
    }
  }
}
