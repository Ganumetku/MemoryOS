import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../../domain/entities/memory.dart';
import '../bloc/memory_cubit.dart';

/// Interactive bottom sheet modal triggered when a user taps/selects a memory on the timeline.
/// Supports inline Editing, deletion triggers, and pin-toggle events.
class MemoryOptionsBottomSheet extends StatefulWidget {
  final Memory memory;

  const MemoryOptionsBottomSheet({super.key, required this.memory});

  @override
  State<MemoryOptionsBottomSheet> createState() =>
      _MemoryOptionsBottomSheetState();
}

class _MemoryOptionsBottomSheetState extends State<MemoryOptionsBottomSheet> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memory.title);
    _contentController = TextEditingController(text: widget.memory.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoryCubit = context.read<MemoryCubit>();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgDarkSecondary,
        borderRadius: AppRadius.brTop24,
        border: Border.all(
          color: AppColors.bgDarkTertiary.withAlpha(128),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.bgDarkTertiary,
                borderRadius: AppRadius.brAll8,
              ),
            ),
          ),
          AppSpacing.v24,

          if (!_isEditing) ...[
            // General Menu Options
            Text(
              'Memory Options',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textDarkPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.v24,

            // Pin / Unpin option
            _OptionTile(
              icon: widget.memory.isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              label: widget.memory.isPinned ? 'Unpin Memory' : 'Pin Memory',
              color: AppColors.brandPrimary,
              onTap: () {
                memoryCubit.togglePin(widget.memory);
                Navigator.pop(context);
              },
            ),
            AppSpacing.v12,

            // Edit option
            _OptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Details',
              color: AppColors.brandSecondary,
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            AppSpacing.v12,

            // Delete option
            _OptionTile(
              icon: Icons.delete_outline,
              label: 'Delete Memory',
              color: AppColors.error,
              onTap: () {
                _showDeleteConfirmation(context, memoryCubit);
              },
            ),
          ] else ...[
            // Inline Edit Form Panel
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.textDarkSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                ),
                Text(
                  'Edit Details',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.v16,
            MemoryTextField(controller: _titleController, hintText: 'Title'),
            AppSpacing.v12,
            MemoryTextField(
              controller: _contentController,
              hintText: 'Content details',
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            AppSpacing.v24,
            MemoryPrimaryButton(
              text: 'Save Changes',
              onPressed: () {
                final newTitle = _titleController.text;
                final newContent = _contentController.text;
                if (newContent.trim().isNotEmpty) {
                  memoryCubit.updateMemoryContent(
                    widget.memory,
                    newTitle,
                    newContent,
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MemoryCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brAll16,
          side: BorderSide(color: AppColors.bgDarkTertiary, width: 1.0),
        ),
        title: Text(
          'Forget this memory?',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This action cannot be undone. Are you sure you want to permanently delete this memory?',
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
              cubit.removeMemory(widget.memory.id);
              Navigator.pop(dialogCtx); // close dialog
              Navigator.pop(context); // close sheet
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
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = color == AppColors.error;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brAll12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.error.withAlpha(20)
              : AppColors.bgDarkTertiary.withAlpha(128),
          borderRadius: AppRadius.brAll12,
          border: Border.all(
            color: isDanger
                ? AppColors.error.withAlpha(50)
                : AppColors.bgDarkTertiary.withAlpha(100),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            AppSpacing.h16,
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: isDanger ? AppColors.error : AppColors.textDarkPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isDanger
                  ? AppColors.error.withAlpha(128)
                  : AppColors.textDarkTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
