import 'package:flutter/material.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/life_area_service.dart';
import '../../../../core/services/life_area_analytics_service.dart';
import '../../../../core/utils/memory_type_helper.dart';

class LifeBalanceCard extends StatelessWidget {
  const LifeBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        sl<LifeAreaService>().getLifeBalance(),
        sl<LifeAreaAnalyticsService>().getTotalMemoriesPerArea(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final results = snapshot.data;
        final Map<String, double> data = (results != null && results.isNotEmpty)
            ? results[0] as Map<String, double>
            : {};
        final Map<String, int> counts = (results != null && results.length > 1)
            ? results[1] as Map<String, int>
            : {};

        if (data.isEmpty) {
          return Container(
            padding: AppSpacing.pAll24,
            decoration: BoxDecoration(
              color: AppColors.bgDarkSecondary.withAlpha(150),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.bgDarkTertiary,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Life Balance',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.pie_chart_outline,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                  ],
                ),
                AppSpacing.v16,
                Text(
                  'Capture more memories to see your life balance.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Sort by percentage descending
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          padding: AppSpacing.pAll24,
          decoration: BoxDecoration(
            color: AppColors.bgDarkSecondary.withAlpha(150),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.bgDarkTertiary,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Life Balance',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.pie_chart_outline,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                ],
              ),
              AppSpacing.v16,
              ...List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                final area = entry.key;
                final percentage = entry.value;
                final count = counts[area] ?? 0;
                final config = MemoryTypeHelper.getConfig(area);

                // Show percentage only if it's the first element or different from the previous element's percentage
                final bool showPercentage = (index == 0) || 
                    (percentage.toStringAsFixed(0) != sortedEntries[index - 1].value.toStringAsFixed(0));

                final memoryWord = count == 1 ? "memory" : "memories";
                final countText = "($count $memoryWord)";
                final String labelText = showPercentage 
                    ? '${percentage.toStringAsFixed(0)}% $countText'
                    : countText;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                config.icon,
                                size: 16,
                                color: config.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                area,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textDarkPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            labelText,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDarkSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: percentage / 100.0),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: AppColors.bgDarkTertiary,
                              valueColor: AlwaysStoppedAnimation<Color>(config.color),
                              minHeight: 6,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
