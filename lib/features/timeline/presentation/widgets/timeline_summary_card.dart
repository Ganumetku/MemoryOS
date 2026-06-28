import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/timeline_summary_service.dart';
import '../../../../features/memories/domain/entities/memory.dart';
import '../../../../shared/widgets/memory_glass_card.dart';

class TimelineSummaryCard extends StatefulWidget {
  final List<Memory> memories;

  const TimelineSummaryCard({
    super.key,
    required this.memories,
  });

  @override
  State<TimelineSummaryCard> createState() => _TimelineSummaryCardState();
}

class _TimelineSummaryCardState extends State<TimelineSummaryCard> {
  String _selectedPeriod = 'Today';
  static const List<String> _periods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
    'All Time'
  ];

  @override
  Widget build(BuildContext context) {
    // Generate summary data dynamically
    final summaryData = TimelineSummaryService.generate(
      memories: widget.memories,
      period: _selectedPeriod,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.brandSecondary.withAlpha(35),
            AppColors.brandPrimary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.brandSecondary.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandSecondary.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: MemoryGlassCard(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Text(
                  summaryData.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline Journal',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Intelligence summary',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDarkTertiary.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Productivity score badge (optional delight)
                if (summaryData.productivityScore > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brandPrimary.withAlpha(80), width: 1),
                    ),
                    child: Text(
                      'Score: ${summaryData.productivityScore.toStringAsFixed(0)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),

            // Horizontal Period Selector Tabs
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  final isSelected = _selectedPeriod == period;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPrimary.withAlpha(180)
                            : AppColors.bgDarkSecondary.withAlpha(100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : AppColors.glassDarkBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Natural Summary and Insights (Animated Switcher for smooth tab swaps)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey<String>(_selectedPeriod),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paragraph Natural Wording
                  Text(
                    summaryData.naturalSummary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Small Insight Chips Section
                  if (summaryData.insights.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.glassDarkBorder, height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Insights & Trends:',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textDarkTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: summaryData.insights.map((insight) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brandSecondary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.brandSecondary.withAlpha(40),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            insight,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textDarkSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
