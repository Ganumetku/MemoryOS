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

class MonthlyReviewPage extends StatelessWidget {
  const MonthlyReviewPage({super.key});

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
          'Monthly Review',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<MonthlyReviewData>(
          future: sl<AnalyticsService>().getMonthlyReviewData(),
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
            if (data == null || data.monthlyCaptures == 0) {
              return MemoryEmptyState(
                icon: Icons.analytics_outlined,
                title: 'Not enough data yet',
                description: 'Capture more memories to unlock your monthly review and insights.',
                actionLabel: 'Capture Memory',
                onActionPressed: () => context.push('/capture'),
              );
            }

            final catConfig = MemoryTypeHelper.getConfig(data.mostActiveCategory);

            return SingleChildScrollView(
              padding: AppSpacing.pAll24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "A retrospective of your last 30 days of logging, thinking patterns, and reminders.",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                  AppSpacing.v24,

                  // Monthly captures
                  _buildStatCard(
                    icon: Icons.calendar_month,
                    iconColor: AppColors.brandPrimary,
                    title: "Monthly Captures",
                    valueWidget: AnimatedNumber(
                      value: data.monthlyCaptures,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    description: "Memories logged in the past 30 days",
                  ),
                  AppSpacing.v16,

                  // Active Category
                  _buildStatCard(
                    icon: catConfig.icon,
                    iconColor: catConfig.color,
                    title: "Most Active Category",
                    valueWidget: Text(
                      data.mostActiveCategory == "None" 
                          ? "Capture more memories to discover patterns." 
                          : "${catConfig.emoji} ${data.mostActiveCategory}",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: data.mostActiveCategory == "None" ? 14 : 20,
                      ),
                    ),
                    description: "Your dominant category of thoughts and logs",
                  ),
                  AppSpacing.v16,

                  // Active Keyword
                  _buildStatCard(
                    icon: Icons.tag,
                    iconColor: AppColors.brandSecondary,
                    title: "Most Active Keyword",
                    valueWidget: Text(
                      data.mostActiveKeyword == "None" ? "Still learning your habits..." : "#${data.mostActiveKeyword}",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: data.mostActiveKeyword == "None" ? 15 : 20,
                      ),
                    ),
                    description: "Your most mentioned keyword tag this month",
                  ),
                  AppSpacing.v16,

                  // Top Person
                  _buildStatCard(
                    icon: Icons.person_outline,
                    iconColor: AppColors.brandAccent,
                    title: "Top Person Mentioned",
                    valueWidget: Text(
                      data.topPerson == "None" ? "No frequent people yet." : data.topPerson,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: data.topPerson == "None" ? 15 : 20,
                      ),
                    ),
                    description: "Most frequent person parsed from logs",
                  ),
                  AppSpacing.v16,

                  // Reminder Statistics Details Card
                  MemoryGlassCard(
                    padding: AppSpacing.pAll24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reminder Statistics (Past 30 Days)",
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textDarkPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.v16,
                        Row(
                          children: [
                            _buildStatItem("Completed", data.completedReminders, AppColors.success),
                            const SizedBox(width: 12),
                            _buildStatItem("Missed", data.missedReminders, AppColors.error),
                            const SizedBox(width: 12),
                            _buildStatItem("Scheduled", data.scheduledReminders, AppColors.brandPrimary),
                          ],
                        ),
                      ],
                    ),
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

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(30),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            AnimatedNumber(
              value: value,
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
