import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../bloc/capture_cubit.dart';
import 'smart_analysis_bottom_sheet.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';

/// The bottom sheet containing capture triggers (Speak, Write, Camera, Scan).
/// Expands dynamically into a text entry zone upon clicking "Write".
class CaptureBottomSheet extends StatefulWidget {
  const CaptureBottomSheet({super.key});

  @override
  State<CaptureBottomSheet> createState() => _CaptureBottomSheetState();
}

class _CaptureBottomSheetState extends State<CaptureBottomSheet> {
  bool _isWriting = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showComingSoonToast(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is coming soon',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.bgDarkSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.brandPrimary, width: 1),
        ),
      ),
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppColors.bgDarkTertiary,
              borderRadius: AppRadius.brAll8,
            ),
          ),
          AppSpacing.v24,

          if (!_isWriting) ...[
            // Ingress Options Grid
            Text(
              'Capture Moment',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textDarkPrimary,
              ),
            ),
            AppSpacing.v20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OptionTile(
                  icon: Icons.mic_none_outlined,
                  label: 'Speak',
                  isActive: false,
                  onTap: () => _showComingSoonToast(context, 'Speak capture'),
                ),
                _OptionTile(
                  icon: Icons.edit_note_outlined,
                  label: 'Write',
                  isActive: true,
                  onTap: () {
                    setState(() {
                      _isWriting = true;
                    });
                  },
                ),
                _OptionTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  isActive: false,
                  onTap: () => _showComingSoonToast(context, 'Camera capture'),
                ),
                _OptionTile(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan',
                  isActive: false,
                  onTap: () => _showComingSoonToast(context, 'Scan capture'),
                ),
              ],
            ),
          ] else ...[
            // Write Mode Expansion Text Input Panel
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
                      _isWriting = false;
                    });
                  },
                ),
                Text(
                  'Write Memory',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                  ),
                ),
              ],
            ),
            AppSpacing.v16,
            MemoryTextField(
              controller: _controller,
              hintText: 'What would you like me to remember?',
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            AppSpacing.v24,
            MemoryPrimaryButton(
              text: 'Remember This',
              onPressed: () {
                final text = _controller.text;
                if (text.trim().isNotEmpty) {
                  final captureCubit = context.read<CaptureCubit>();
                  MemoryCubit? memoryCubit;
                  try {
                    memoryCubit = context.read<MemoryCubit>();
                  } catch (_) {}

                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) {
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: captureCubit),
                          if (memoryCubit != null)
                            BlocProvider.value(value: memoryCubit),
                        ],
                        child: SmartAnalysisBottomSheet(rawContent: text),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = isActive
        ? AppColors.brandPrimary.withAlpha(20)
        : AppColors.bgDarkTertiary.withAlpha(128);
    final contentColor = isActive
        ? AppColors.brandPrimary
        : AppColors.textDarkTertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brAll16,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: AppRadius.brAll16,
          border: isActive
              ? Border.all(
                  color: AppColors.brandPrimary.withAlpha(50),
                  width: 1.2,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: contentColor, size: 24),
            AppSpacing.v8,
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: contentColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
