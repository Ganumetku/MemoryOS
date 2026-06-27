import 'package:flutter/material.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/life_area_service.dart';
import '../../../../core/utils/memory_type_helper.dart';

class LifeBalanceCard extends StatelessWidget {
  const LifeBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: sl<LifeAreaService>().getLifeBalance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return Container(
            padding: AppSpacing.pAll20,
            decoration: BoxDecoration(
              color: AppColors.bgDarkSecondary.withAlpha(150),
              borderRadius: BorderRadius.circular(16),
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
          padding: AppSpacing.pAll20,
          decoration: BoxDecoration(
            color: AppColors.bgDarkSecondary.withAlpha(150),
            borderRadius: BorderRadius.circular(16),
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
              ...sortedEntries.map((entry) {
                final area = entry.key;
                final percentage = entry.value;
                final config = MemoryTypeHelper.getConfig(area);

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
                            '${percentage.toStringAsFixed(0)}%',
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
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.bgDarkTertiary,
                          valueColor: AlwaysStoppedAnimation<Color>(config.color),
                          minHeight: 6,
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
