import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/memory_type_helper.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_loading_indicator.dart';
import '../../../../shared/widgets/memory_empty_state.dart';
import '../../../../shared/widgets/animated_number.dart';

class WeeklyReviewPage extends StatelessWidget {
  const WeeklyReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Weekly Review',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<WeeklyReviewData>(
          future: sl<AnalyticsService>().getWeeklyReviewData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: MemoryLoadingIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading review: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null || data.totalMemories == 0) {
              return MemoryEmptyState(
                icon: Icons.analytics_outlined,
                title: 'Not enough data yet',
                description: 'Capture more memories to unlock your weekly review and insights.',
                actionLabel: 'Capture Memory',
                onActionPressed: () => context.push('/capture'),
              );
            }

            final topCatConfig = MemoryTypeHelper.getConfig(data.topCategory);

            return SingleChildScrollView(
              padding: AppSpacing.pAll24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Your week at a glance.",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                  AppSpacing.v24,

                  // Captured Memories Card
                  _buildStatCard(
                    context: context,
                    icon: Icons.all_inclusive,
                    iconColor: AppColors.brandPrimary,
                    title: "Captured Memories",
                    valueWidget: AnimatedNumber(
                      value: data.totalMemories,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    description: "Total fragments secure in your memory vault",
                  ),
                  AppSpacing.v16,

                  // Top Category Card
                  _buildStatCard(
                    context: context,
                    icon: topCatConfig.icon,
                    iconColor: topCatConfig.color,
                    title: "Top Category",
                    valueWidget: Text(
                      data.topCategory == "None" 
                          ? "Capture more memories to discover patterns." 
                          : "${topCatConfig.emoji} ${data.topCategory}",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: data.topCategory == "None" ? 14 : 20,
                      ),
                    ),
                    description: "Where you focused most of your attention",
                  ),
                  AppSpacing.v16,

                  // Most Frequent Topic Card
                  _buildStatCard(
                    context: context,
                    icon: Icons.tag,
                    iconColor: AppColors.brandSecondary,
                    title: "Most Frequent Topic",
                    valueWidget: Text(
                      data.topKeyword == "None" ? "Still learning your habits..." : "#${data.topKeyword}",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: data.topKeyword == "None" ? 15 : 20,
                      ),
                    ),
                    description: "Most recurring theme or subject this week",
                  ),
                  AppSpacing.v16,

                  // Reminder Success Card with Progress Bar
                  MemoryGlassCard(
                    padding: AppSpacing.pAll24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Reminder Success",
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textDarkSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AnimatedNumber(
                              value: data.reminderCompletionRate,
                              suffix: "%",
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.v12,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: data.reminderCompletionRate / 100.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: AppColors.bgDarkTertiary,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                minHeight: 8,
                              );
                            },
                          ),
                        ),
                        AppSpacing.v12,
                        Text(
                          data.reminderCompletionRate == 0 
                              ? "Complete reminders to improve this score."
                              : "Rate of successfully completed tasks and scheduled notifications",
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textDarkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.v16,

                  // Longest Streak Card
                  _buildStatCard(
                    context: context,
                    icon: Icons.local_fire_department_outlined,
                    iconColor: Colors.orange,
                    title: "Longest Streak",
                    valueWidget: Row(
                      children: [
                        AnimatedNumber(
                          value: data.longestStreak,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textDarkPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          " days",
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textDarkPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    description: "Your best record for logging memories consistently",
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget valueWidget,
    required String description,
  }) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll24,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          AppSpacing.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDarkSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget,
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDarkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
