import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../bloc/capture_cubit.dart';
import '../bloc/capture_state.dart';

/// Screen for creating a new memory fragment, launched from the Timeline dashboard.
class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
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
    return BlocProvider(
      create: (_) => CaptureCubit(),
      child: BlocListener<CaptureCubit, CaptureState>(
        listener: (context, state) {
          if (state is CaptureSuccess) {
            // Memory successfully written to local DB, pop back to Timeline
            context.pop();
          }
        },
        child: BlocBuilder<CaptureCubit, CaptureState>(
          builder: (context, state) {
            final cubit = context.read<CaptureCubit>();
            final isLoading = state is CaptureLoading;

            return Scaffold(
              backgroundColor: AppColors.bgDarkPrimary,
              appBar: AppBar(
                title: Text(
                  'Capture Memory',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textDarkSecondary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: AppSpacing.pAll24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'What is on your mind?',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textDarkPrimary,
                        ),
                      ),
                      AppSpacing.v24,
                      Expanded(
                        child: MemoryTextField(
                          controller: _controller,
                          hintText: 'Start writing or log an idea...',
                          maxLines: 10,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                      AppSpacing.v24,

                      // Inactive Media Capture Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MediaCaptureButton(
                            icon: Icons.mic_none,
                            label: 'Voice',
                            onTap: () =>
                                _showComingSoonToast(context, 'Voice capture'),
                          ),
                          _MediaCaptureButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: () =>
                                _showComingSoonToast(context, 'Camera capture'),
                          ),
                          _MediaCaptureButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () =>
                                _showComingSoonToast(context, 'Gallery upload'),
                          ),
                        ],
                      ),
                      AppSpacing.v24,
                      MemoryPrimaryButton(
                        text: 'Save Memory',
                        icon: Icons.check,
                        isLoading: isLoading,
                        onPressed: () {
                          final text = _controller.text;
                          if (text.trim().isNotEmpty) {
                            cubit.saveMemory(text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MediaCaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaCaptureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brAll12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgDarkSecondary,
          borderRadius: AppRadius.brAll12,
          border: Border.all(color: AppColors.bgDarkTertiary, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textDarkTertiary, size: 24),
            AppSpacing.v8,
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
