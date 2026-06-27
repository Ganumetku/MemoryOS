import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/parser/parsed_memory.dart';
import '../../../../core/parser/smart_parser.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../bloc/capture_cubit.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';

/// Bottom sheet showcasing natural language analysis tags.
/// Prompts the user to review, edit, and confirm auto-extracted details.
class SmartAnalysisBottomSheet extends StatefulWidget {
  final String rawContent;

  const SmartAnalysisBottomSheet({super.key, required this.rawContent});

  @override
  State<SmartAnalysisBottomSheet> createState() =>
      _SmartAnalysisBottomSheetState();
}

class _SmartAnalysisBottomSheetState extends State<SmartAnalysisBottomSheet> {
  late ParsedMemory _parsed;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;
  late TextEditingController _personController;

  final List<String> _types = [
    'Idea',
    'Health',
    'Work',
    'Personal',
    'Finance',
    'Shopping',
    'Travel',
    'Birthday',
    'Meeting',
    'Reminder',
    'Task',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  String _selectedType = 'Personal';
  String _selectedPriority = 'Low';
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    // Parse content offline
    _parsed = SmartParserImpl().parse(widget.rawContent);

    _titleController = TextEditingController(text: _parsed.title);
    _contentController = TextEditingController(text: _parsed.content);
    _categoryController = TextEditingController(text: _parsed.category);
    _personController = TextEditingController(text: _parsed.personName ?? '');

    _selectedType = _parsed.type;
    _selectedPriority = _parsed.priority;
    _reminderAt = _parsed.reminderAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _personController.dispose();
    super.dispose();
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
    return '${date.day} $monthStr ${date.year} at $hourStr:$minStr';
  }

  String _formatTimeOnly(DateTime date) {
    final minStr = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final int displayHour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    return '$displayHour:$minStr $suffix';
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
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
            AppSpacing.v16,

            Text(
              'Smart Memory Analysis',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textDarkPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.v8,
            Text(
              'Verify what was parsed from your thought.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDarkSecondary,
              ),
            ),
            AppSpacing.v16,

            // Extraction Status Badges (Checkmarks)
            MemoryGlassCard(
              padding: AppSpacing.pAll12,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildDetectionIndicator('✓ Memory Type', true),
                  _buildDetectionIndicator('✓ Date', _parsed.date != null),
                  _buildDetectionIndicator('✓ Time', _parsed.time != null),
                  _buildDetectionIndicator(
                    '✓ Person',
                    _parsed.personName != null,
                  ),
                  _buildDetectionIndicator(
                    '✓ Reminder',
                    _parsed.reminderAt != null,
                  ),
                ],
              ),
            ),
            AppSpacing.v20,

            // Fields Editor
            Text(
              'EDIT DETECTION',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkTertiary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            AppSpacing.v12,

            // Title Input
            Text(
              'Title',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkSecondary,
              ),
            ),
            AppSpacing.v4,
            MemoryTextField(
              controller: _titleController,
              hintText: 'Memory Title',
            ),
            AppSpacing.v12,

            // Type Dropdown
            Text(
              'Memory Type',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkSecondary,
              ),
            ),
            AppSpacing.v4,
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              dropdownColor: AppColors.bgDarkSecondary,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDarkPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bgDarkTertiary.withAlpha(128),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                  });
                }
              },
            ),
            AppSpacing.v12,

            // Person Name
            Text(
              'Person Detected',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkSecondary,
              ),
            ),
            AppSpacing.v4,
            MemoryTextField(
              controller: _personController,
              hintText: 'Name (Optional)',
            ),
            AppSpacing.v12,

            // Reminder Switch & Picker Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminder Schedule',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                Switch(
                  value: _reminderAt != null,
                  activeTrackColor: AppColors.brandPrimary,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _reminderAt = DateTime.now().add(
                          const Duration(minutes: 30),
                        );
                      } else {
                        _reminderAt = null;
                      }
                    });
                  },
                ),
              ],
            ),
            AppSpacing.v4,
            if (_reminderAt != null) ...[
              GestureDetector(
                onTap: () async {
                  await sl<NotificationService>().requestPermissions();
                  if (!context.mounted) return;

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _reminderAt!,
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
                    initialTime: TimeOfDay.fromDateTime(_reminderAt!),
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
                  if (pickedTime != null) {
                    setState(() {
                      _reminderAt = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgDarkTertiary.withAlpha(128),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.brandPrimary.withAlpha(100),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: AppColors.brandPrimary,
                      ),
                      AppSpacing.h8,
                      Text(
                        _formatDateTime(_reminderAt!),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDarkPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: AppColors.textDarkTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkTertiary.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_off,
                      size: 16,
                      color: AppColors.textDarkTertiary,
                    ),
                    AppSpacing.h8,
                    Text(
                      'No schedule set',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDarkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppSpacing.v12,

            // Category & Priority
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                      AppSpacing.v4,
                      MemoryTextField(
                        controller: _categoryController,
                        hintText: 'Category',
                      ),
                    ],
                  ),
                ),
                AppSpacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                      AppSpacing.v4,
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPriority,
                        dropdownColor: AppColors.bgDarkSecondary,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDarkPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.bgDarkTertiary.withAlpha(128),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _priorities
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPriority = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.v24,

            // Action Buttons
            MemoryPrimaryButton(
              text: 'Confirm & Save',
              icon: Icons.check,
              onPressed: () {
                final tagsList = <String>[];
                if (_categoryController.text.trim().isNotEmpty) {
                  tagsList.add(_categoryController.text.trim());
                }
                if (_personController.text.trim().isNotEmpty) {
                  tagsList.add(_personController.text.trim());
                }

                // If reminder time has already passed, show error and block saving
                if (_reminderAt != null &&
                    _reminderAt!.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Reminder time has already passed.",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                // If reminder scheduled, prompt notification permissions request
                if (_reminderAt != null) {
                  try {
                    sl<NotificationService>().requestPermissions();
                  } catch (_) {}
                }

                bool saved = false;
                try {
                  final memoryCubit = context.read<MemoryCubit>();
                  memoryCubit.addMemory(
                    _contentController.text.trim(),
                    title: _titleController.text.trim(),
                    type: _selectedType,
                    reminderAt: _reminderAt,
                    tags: tagsList,
                  );
                  saved = true;
                } catch (_) {}

                if (!saved) {
                  try {
                    final captureCubit = context.read<CaptureCubit>();
                    captureCubit.saveMemory(
                      _contentController.text.trim(),
                      title: _titleController.text.trim(),
                      type: _selectedType,
                      reminderAt: _reminderAt,
                      tags: tagsList,
                    );
                    saved = true;
                  } catch (_) {}
                }

                // Show success snackbar
                if (_reminderAt != null) {
                  final formattedTime = _formatTimeOnly(_reminderAt!);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "I'll remind you at $formattedTime.",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.brandPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }

                Navigator.pop(
                  context,
                  true,
                ); // Pop Smart Preview with success status
              },
            ),
            AppSpacing.v8,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.titleSmall.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionIndicator(String label, bool isDetected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDetected ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: isDetected ? AppColors.success : AppColors.textDarkTertiary,
        ),
        AppSpacing.h4,
        Text(
          label.replaceAll('✓ ', ''),
          style: AppTextStyles.labelSmall.copyWith(
            color: isDetected
                ? AppColors.textDarkPrimary
                : AppColors.textDarkTertiary,
            fontWeight: isDetected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
