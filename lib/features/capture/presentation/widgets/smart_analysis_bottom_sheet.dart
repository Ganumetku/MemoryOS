import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
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
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/memory_type_helper.dart';
import '../../../../core/services/life_area_service.dart';
import '../../../memories/data/models/memory_model.dart';

/// Bottom sheet showcasing natural language analysis tags.
/// Prompts the user to review, edit, and confirm auto-extracted details.
class SmartAnalysisBottomSheet extends StatefulWidget {
  final String rawContent;
  final int? parentMemoryId;

  const SmartAnalysisBottomSheet({
    super.key,
    required this.rawContent,
    this.parentMemoryId,
  });

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

  late final List<String> _types;

  String _selectedType = 'Personal';
  String _selectedPriority = 'Low';
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    _types = sl<LifeAreaService>().areas;
    // Parse content offline
    _parsed = SmartParserImpl().parse(widget.rawContent);

    _titleController = TextEditingController(text: _parsed.title);
    _contentController = TextEditingController(text: _parsed.content);
    _categoryController = TextEditingController(text: _parsed.category);
    _personController = TextEditingController(text: _parsed.personName ?? '');

    final String typeFromParser = _parsed.type;
    _selectedType = _types.firstWhere(
      (t) => t.toLowerCase() == typeFromParser.toLowerCase().trim(),
      orElse: () => 'Other',
    );
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textDarkTertiary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.v16,

            Text(
              'I understood this memory',
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

            // Extraction Status Badges (Chips)
            MemoryGlassCard(
              padding: AppSpacing.pAll12,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetectedChip(
                    MemoryTypeHelper.getConfig(_selectedType).icon,
                    'Type',
                    '${MemoryTypeHelper.getConfig(_selectedType).emoji} $_selectedType',
                    true,
                  ),
                  _buildDetectedChip(
                    Icons.calendar_today,
                    'Date',
                    _parsed.date != null
                        ? _formatDateOnly(_parsed.date!)
                        : 'None',
                    _parsed.date != null,
                  ),
                  _buildDetectedChip(
                    Icons.access_time,
                    'Time',
                    _parsed.time ?? 'None',
                    _parsed.time != null,
                  ),
                  _buildDetectedChip(
                    Icons.notifications_active_outlined,
                    'Reminder',
                    _reminderAt != null
                        ? _formatTimeOnly(_reminderAt!)
                        : 'None',
                    _reminderAt != null,
                  ),
                  _buildDetectedChip(
                    Icons.person_outline,
                    'Person',
                    _personController.text.trim().isNotEmpty
                        ? _personController.text.trim()
                        : 'None',
                    _personController.text.trim().isNotEmpty,
                  ),
                  _buildDetectedChip(
                    Icons.priority_high,
                    'Priority',
                    _selectedPriority,
                    true,
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
                      Icons.notifications_off_outlined,
                      size: 16,
                      color: AppColors.textDarkTertiary,
                    ),
                    AppSpacing.h8,
                    Expanded(
                      child: Text(
                        "No reminder found. I’ll still remember this.",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDarkTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppSpacing.v24,

            // Action Buttons
            MemoryPrimaryButton(
              text: "I'll Remember This",
              icon: Icons.check,
              onPressed: () {
                final tagsList = <String>[];
                if (_parsed.category.isNotEmpty) {
                  tagsList.add(_parsed.category);
                }
                if (_parsed.personName != null &&
                    _parsed.personName!.isNotEmpty) {
                  tagsList.add(_parsed.personName!);
                }
                tagsList.addAll(
                  _parsed.tags.where(
                    (t) => t != _parsed.category && t != _parsed.personName,
                  ),
                );

                if (widget.parentMemoryId != null) {
                  try {
                    final isar = sl<Isar>();
                    final parentModel = isar.memoryModels.getSync(widget.parentMemoryId!);
                    if (parentModel != null) {
                      for (final tag in parentModel.tags) {
                        if (!tagsList.map((t) => t.toLowerCase()).contains(tag.toLowerCase())) {
                          tagsList.add(tag);
                        }
                      }
                    }
                  } catch (_) {}
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

                if (saved) {
                  HapticFeedback.lightImpact();
                  try {
                    sl<AnalyticsService>().incrementCaptureCount('text');
                  } catch (_) {}
                }

                // Show success snackbar/success state
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _reminderAt != null
                          ? "I'll remember this for you. I'll remind you at ${_formatTimeOnly(_reminderAt!)}."
                          : "I'll remember this for you.",
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
                'Edit Text',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textDarkSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateOnly(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildDetectedChip(
    IconData icon,
    String label,
    String value,
    bool isDetected,
  ) {
    final color = isDetected
        ? AppColors.brandPrimary
        : AppColors.textDarkTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDetected ? AppColors.glassDarkSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDetected
              ? AppColors.glassDarkBorder
              : AppColors.bgDarkTertiary,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textDarkSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: isDetected
                  ? AppColors.textDarkPrimary
                  : AppColors.textDarkTertiary,
              fontWeight: isDetected ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
