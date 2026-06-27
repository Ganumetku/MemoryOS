import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_loading_indicator.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../bloc/capture_cubit.dart';
import '../bloc/capture_state.dart';
import '../widgets/capture_bottom_sheet.dart';
import '../widgets/success_card.dart';

/// Screen 001 - Welcome Page.
/// Displays the headline copy, capture trigger button, and renders loading / success overlays.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide self-contained CaptureCubit to the screen widget subtree
    return BlocProvider(
      create: (_) => CaptureCubit(),
      child: const _WelcomePageView(),
    );
  }
}

class _WelcomePageView extends StatelessWidget {
  const _WelcomePageView();

  void _showCaptureSheet(BuildContext context, CaptureCubit cubit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        // Pass the parent context cubit so that the sheet can invoke saveMemory
        return BlocProvider.value(
          value: cubit,
          child: const CaptureBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptureCubit>();

    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Content
            Center(
              child: Padding(
                padding: AppSpacing.pAll32,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Small header badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MEMORY VAULT PROTO',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AppSpacing.v40,

                    // Headline Title
                    Text(
                      "Don't trust your memory.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    AppSpacing.v12,

                    // Subtitle
                    Text(
                      "Trust MemoryOS.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.brandSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.v40,

                    // Primary Action trigger
                    BlocBuilder<CaptureCubit, CaptureState>(
                      builder: (context, state) {
                        final isInteractive = state is! CaptureLoading;
                        return MemoryPrimaryButton(
                          text: 'Capture Memory',
                          icon: Icons.add_circle_outline,
                          onPressed: isInteractive
                              ? () => _showCaptureSheet(context, cubit)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Loading Overlay (Simulated indexing processing)
            BlocBuilder<CaptureCubit, CaptureState>(
              builder: (context, state) {
                if (state is! CaptureLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withAlpha(150),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MemoryLoadingIndicator(size: 40),
                        AppSpacing.v16,
                        Text(
                          'Securing memory in vault...',
                          style: TextStyle(color: AppColors.textDarkSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Success Overlay State Card
            BlocBuilder<CaptureCubit, CaptureState>(
              builder: (context, state) {
                if (state is! CaptureSuccess) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withAlpha(178), // Deep overlay mask
                  padding: AppSpacing.pAll24,
                  child: Center(
                    child: SuccessCard(
                      text: state.capturedText,
                      onClose: () {
                        cubit.reset();
                        context.go('/');
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
