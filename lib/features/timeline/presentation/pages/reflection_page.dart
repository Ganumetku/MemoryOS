import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_primary_button.dart';
import '../../../../core/services/reflection_engine.dart';
import '../../../../core/models/daily_reflection.dart';
import '../../../../core/models/coach_recommendation.dart';
import '../../../../core/services/personal_coach_engine.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../capture/presentation/bloc/capture_cubit.dart';
import '../../../capture/presentation/widgets/capture_bottom_sheet.dart';
import '../../../capture/presentation/widgets/smart_analysis_bottom_sheet.dart';

class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key});

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  late Future<DailyReflection> _reflectionFuture;
  late Future<List<CoachRecommendation>> _recsFuture;

  @override
  void initState() {
    super.initState();
    _reflectionFuture = sl<ReflectionEngine>().generateTodayReflection();
    _recsFuture = sl<PersonalCoachEngine>().generateRecommendations();
  }

  void _showCaptureSheet(BuildContext context, MemoryCubit cubit, {String? prefilledText}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider(create: (_) => sl<CaptureCubit>()),
          ],
          child: CaptureBottomSheet(prefilledText: prefilledText),
        );
      },
    ).then((voiceTranscript) {
      if (voiceTranscript is String && voiceTranscript.trim().isNotEmpty) {
        if (context.mounted) {
          showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<CaptureCubit>()),
                  BlocProvider.value(value: cubit),
                ],
                child: SmartAnalysisBottomSheet(
                  rawContent: voiceTranscript,
                ),
              );
            },
          ).then((_) {
            cubit.fetchMemories();
            setState(() {
              _reflectionFuture = sl<ReflectionEngine>().generateTodayReflection();
              _recsFuture = sl<PersonalCoachEngine>().generateRecommendations();
            });
          });
        }
      } else {
        cubit.fetchMemories();
        setState(() {
          _reflectionFuture = sl<ReflectionEngine>().generateTodayReflection();
          _recsFuture = sl<PersonalCoachEngine>().generateRecommendations();
        });
      }
    });
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Quiet':
        return Icons.nightlight_round_outlined;
      case 'Productive':
        return Icons.flash_on_outlined;
      case 'Focused':
        return Icons.track_changes_outlined;
      case 'Overloaded':
        return Icons.warning_amber_outlined;
      case 'NeedsAttention':
        return Icons.priority_high_outlined;
      case 'Reflective':
        return Icons.psychology_outlined;
      case 'Balanced':
      default:
        return Icons.scale_outlined;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Quiet':
        return Colors.blueAccent;
      case 'Productive':
        return Colors.amber;
      case 'Focused':
        return Colors.purpleAccent;
      case 'Overloaded':
        return Colors.redAccent;
      case 'NeedsAttention':
        return Colors.deepOrangeAccent;
      case 'Reflective':
        return Colors.cyanAccent;
      case 'Balanced':
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = sl<MemoryCubit>();

    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Reflection',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<DailyReflection>(
          future: _reflectionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'Failed to load today\'s reflection.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
              );
            }

            final reflection = snapshot.data!;
            final bool isEmptyDay = reflection.score == 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gradient Score Header Card
                  Container(
                    padding: AppSpacing.pAll24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandPrimary.withAlpha(40),
                          AppColors.bgDarkSecondary.withAlpha(100),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.brAll24,
                      border: Border.all(color: AppColors.brandPrimary.withAlpha(60), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reflection.title,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.textDarkPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.v8,
                              Row(
                                children: [
                                  Icon(
                                    _getMoodIcon(reflection.mood),
                                    size: 16,
                                    color: _getMoodColor(reflection.mood),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getMoodColor(reflection.mood).withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getMoodColor(reflection.mood).withAlpha(55), width: 1.0),
                                    ),
                                    child: Text(
                                      reflection.mood,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: _getMoodColor(reflection.mood),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (reflection.scoreExplanation.isNotEmpty) ...[
                                AppSpacing.v8,
                                Text(
                                  reflection.scoreExplanation,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textDarkTertiary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        AppSpacing.h16,
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: reflection.score / 100.0,
                                strokeWidth: 6,
                                backgroundColor: AppColors.bgDarkTertiary,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            Text(
                              reflection.score.toStringAsFixed(0),
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textDarkPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.v20,

                  // Summary block
                  MemoryGlassCard(
                    padding: AppSpacing.pAll20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY SUMMARY',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textDarkTertiary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        AppSpacing.v12,
                        Text(
                          isEmptyDay ? 'Your day is still waiting to be remembered.' : reflection.summary,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textDarkPrimary,
                            height: 1.5,
                          ),
                        ),
                        if (isEmptyDay) ...[
                          AppSpacing.v20,
                          SizedBox(
                            width: double.infinity,
                            child: MemoryPrimaryButton(
                              text: 'Capture a Memory',
                              icon: Icons.add_circle_outline,
                              onPressed: () => _showCaptureSheet(context, cubit),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.v20,

                  if (!isEmptyDay) ...[
                    // Wins & Needs Improvement
                    if (reflection.wins.isNotEmpty || reflection.needsImprovement.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reflection.wins.isNotEmpty)
                            Expanded(
                              child: MemoryGlassCard(
                                padding: AppSpacing.pAll16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WINS',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppSpacing.v12,
                                    ...reflection.wins.map((h) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check, size: 12, color: Colors.greenAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              h,
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textDarkPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          if (reflection.wins.isNotEmpty && reflection.needsImprovement.isNotEmpty)
                            AppSpacing.h12,
                          if (reflection.needsImprovement.isNotEmpty)
                            Expanded(
                              child: MemoryGlassCard(
                                padding: AppSpacing.pAll16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEEDS IMPROVEMENT',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppSpacing.v12,
                                    ...reflection.needsImprovement.map((c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.priority_high, size: 12, color: Colors.redAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              c,
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textDarkPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.v20,
                    ],

                    // Tomorrow Focus Card
                    if (reflection.tomorrowFocus.isNotEmpty) ...[
                      MemoryGlassCard(
                        padding: AppSpacing.pAll16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOMORROW FOCUS',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.brandSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.v8,
                            Text(
                              reflection.tomorrowFocus,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDarkPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.v20,
                    ],

                    // Suggested Actions
                    if (reflection.suggestedActions.isNotEmpty) ...[
                      MemoryGlassCard(
                        padding: AppSpacing.pAll20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUGGESTED ACTIONS',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textDarkTertiary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            AppSpacing.v12,
                            ...reflection.suggestedActions.map((action) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    action.contains('Reschedule') ? Icons.schedule_outlined : Icons.arrow_right_alt_outlined,
                                    size: 16,
                                    color: AppColors.brandPrimary,
                                  ),
                                  AppSpacing.h12,
                                  Expanded(
                                    child: Text(
                                      action,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textDarkPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                      AppSpacing.v20,
                    ],

                    // Personal Coach Section
                    Text(
                      'PERSONAL COACH',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textDarkTertiary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    AppSpacing.v12,
                    FutureBuilder<List<CoachRecommendation>>(
                      future: _recsFuture,
                      builder: (context, recSnapshot) {
                        if (recSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(color: AppColors.brandPrimary),
                            ),
                          );
                        }
                        if (recSnapshot.hasError || !recSnapshot.hasData || recSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final recommendations = recSnapshot.data!;
                        return Column(
                          children: recommendations.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: MemoryGlassCard(
                              padding: AppSpacing.pAll16,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      rec.icon,
                                      size: 16,
                                      color: AppColors.brandPrimary,
                                    ),
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
                                                rec.title,
                                                style: AppTextStyles.bodyMedium.copyWith(
                                                  color: AppColors.textDarkPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildPriorityBadge(rec.priority),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          rec.description,
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
                          )).toList(),
                        );
                      },
                    ),
                    AppSpacing.v20,

                    // Reflection Questions
                    if (reflection.reflectionQuestions.isNotEmpty) ...[
                      Text(
                        'REFLECTIVE PROMPTS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textDarkTertiary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      AppSpacing.v12,
                      ...reflection.reflectionQuestions.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: MemoryGlassCard(
                          padding: AppSpacing.pAll16,
                          onTap: () {
                            _showCaptureSheet(
                              context,
                              cubit,
                              prefilledText: "Responding to prompt: '$q'\n\n",
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline, size: 16, color: AppColors.brandSecondary),
                              AppSpacing.h12,
                              Expanded(
                                child: Text(
                                  q,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textDarkPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16, color: AppColors.textDarkTertiary),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color badgeColor;
    switch (priority) {
      case 'High':
        badgeColor = Colors.redAccent;
        break;
      case 'Medium':
        badgeColor = Colors.orangeAccent;
        break;
      case 'Low':
      default:
        badgeColor = Colors.blueAccent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withAlpha(60), width: 1.0),
      ),
      child: Text(
        priority,
        style: AppTextStyles.labelSmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}
