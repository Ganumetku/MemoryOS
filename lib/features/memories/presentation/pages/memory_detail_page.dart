import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_loading_indicator.dart';
import '../../domain/entities/memory.dart';
import '../bloc/memory_cubit.dart';
import '../bloc/memory_state.dart';

/// Screen representing the detailed visualization of a stored Memory fragment.
/// Integrates App Bar actions (Edit content, Toggle Pin, Delete) and showcases metadata logs.
class MemoryDetailPage extends StatefulWidget {
  final String memoryId;

  const MemoryDetailPage({super.key, required this.memoryId});

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  void _editMemory(BuildContext context, Memory memory, MemoryCubit cubit) {
    final titleController = TextEditingController(text: memory.title);
    final contentController = TextEditingController(text: memory.content);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brAll16,
          side: BorderSide(color: AppColors.bgDarkTertiary, width: 1.0),
        ),
        title: Text(
          'Edit Memory',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDarkTertiary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              AppSpacing.v16,
              TextField(
                controller: contentController,
                maxLines: 5,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDarkTertiary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (contentController.text.trim().isNotEmpty) {
                cubit.updateMemoryContent(
                  memory,
                  titleController.text.trim(),
                  contentController.text.trim(),
                );
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Memory memory, MemoryCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brAll16,
          side: BorderSide(color: AppColors.bgDarkTertiary, width: 1.0),
        ),
        title: Text(
          'Erase Memory?',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this memory?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cubit.removeMemory(memory.id);
              Navigator.pop(dialogCtx); // Pop dialog
              context.pop(); // Pop Detail Page
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');
    return '${date.day} $monthStr ${date.year} • $hourStr:$minStr';
  }

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(widget.memoryId) ?? 0;

    return BlocProvider(
      create: (_) => sl<MemoryCubit>()..fetchMemories(),
      child: BlocBuilder<MemoryCubit, MemoryState>(
        builder: (context, state) {
          final cubit = context.read<MemoryCubit>();

          if (state is MemoryLoading) {
            return const Scaffold(
              backgroundColor: AppColors.bgDarkPrimary,
              body: Center(child: MemoryLoadingIndicator()),
            );
          }

          if (state is MemoryError) {
            return Scaffold(
              backgroundColor: AppColors.bgDarkPrimary,
              appBar: AppBar(leading: const BackButton()),
              body: Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }

          if (state is MemoryLoaded) {
            // Retrieve matching memory entity
            final memories = state.memories;
            final m = memories.firstWhere(
              (element) => element.id == parsedId,
              orElse: () => Memory(
                id: -1,
                title: '',
                content: '',
                type: 'text',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                tags: const [],
              ),
            );

            if (m.id == -1) {
              return Scaffold(
                backgroundColor: AppColors.bgDarkPrimary,
                appBar: AppBar(leading: const BackButton()),
                body: Center(
                  child: Text(
                    'Memory not found.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.bgDarkPrimary,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textDarkSecondary,
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textDarkSecondary,
                    ),
                    onPressed: () => _editMemory(context, m, cubit),
                  ),
                  IconButton(
                    icon: Icon(
                      m.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: m.isPinned
                          ? AppColors.brandPrimary
                          : AppColors.textDarkSecondary,
                    ),
                    onPressed: () => cubit.togglePin(m),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () => _confirmDelete(context, m, cubit),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: AppSpacing.pAll24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Memory Type Header tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit_note,
                                    size: 14,
                                    color: AppColors.brandPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Memory Type: Text',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.v20,

                            // Title
                            Text(
                              m.title,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textDarkPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.v16,

                            // Created / Updated Metadata details
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppColors.textDarkTertiary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Created: ${_formatDateTime(m.createdAt)}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.update,
                                  size: 12,
                                  color: AppColors.textDarkTertiary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Updated: ${_formatDateTime(m.updatedAt)}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.v24,

                            // Body Content
                            Text(
                              m.content,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textDarkPrimary,
                                height: 1.6,
                              ),
                            ),
                            AppSpacing.v40,

                            // Attributes Section Header
                            Text(
                              'ATTRIBUTES',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textDarkTertiary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            AppSpacing.v16,

                            // Glass card container mapping empty states for attributes
                            MemoryGlassCard(
                              padding: AppSpacing.pAll16,
                              child: Column(
                                children: [
                                  _buildMetadataRow(
                                    Icons.psychology_outlined,
                                    'Related Memories',
                                    'Coming Soon',
                                  ),
                                  const Divider(
                                    color: AppColors.bgDarkTertiary,
                                    height: 24,
                                  ),
                                  _buildMetadataRow(
                                    Icons.notifications_none_outlined,
                                    'Reminder',
                                    'Not Set',
                                  ),
                                  const Divider(
                                    color: AppColors.bgDarkTertiary,
                                    height: 24,
                                  ),
                                  _buildMetadataRow(
                                    Icons.location_on_outlined,
                                    'Location',
                                    'Not Captured',
                                  ),
                                  const Divider(
                                    color: AppColors.bgDarkTertiary,
                                    height: 24,
                                  ),
                                  _buildMetadataRow(
                                    Icons.attach_file_outlined,
                                    'Attachments',
                                    'None',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Floating AI Action Button (Disabled)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkSecondary,
                          borderRadius: AppRadius.brAll24,
                          border: Border.all(
                            color: AppColors.bgDarkTertiary,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: AppColors.textDarkTertiary,
                              ),
                              AppSpacing.h8,
                              Text(
                                'Ask AI About This Memory (Coming Soon)',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.textDarkTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textDarkSecondary),
        AppSpacing.h12,
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDarkTertiary,
          ),
        ),
      ],
    );
  }
}
