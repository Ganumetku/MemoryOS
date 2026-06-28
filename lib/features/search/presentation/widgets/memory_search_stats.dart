import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../memories/domain/entities/memory.dart';
import 'relative_date_text.dart';

/// Renders a 2x2 grid inside a premium glass card showing search results statistics.
class MemorySearchStats extends StatelessWidget {
  final List<Memory> memories;

  const MemorySearchStats({
    super.key,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();

    // Calculate count
    final count = memories.length;
    final foundText = '$count memory${count == 1 ? '' : 'ies'}';

    // Find the most frequent category
    final categoryCounts = <String, int>{};
    for (final m in memories) {
      categoryCounts[m.type] = (categoryCounts[m.type] ?? 0) + 1;
    }
    String mostFrequentCategory = 'None';
    int maxCount = -1;
    categoryCounts.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentCategory = category;
      }
    });

    // Find latest and oldest memories
    final latestMemory = memories.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    final oldestMemory = memories.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    );

    final latestStr = RelativeDateText.getRelativeDateString(latestMemory.createdAt, DateTime.now());
    final oldestStr = RelativeDateText.getRelativeDateString(oldestMemory.createdAt, DateTime.now());

    return MemoryGlassCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCell(
                  'Found',
                  foundText,
                  Icons.find_in_page_outlined,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Category',
                  mostFrequentCategory,
                  Icons.category_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCell(
                  'Latest',
                  latestStr,
                  Icons.access_time_outlined,
                ),
              ),
              Expanded(
                child: _buildStatCell(
                  'Oldest',
                  oldestStr,
                  Icons.history_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.brandPrimary.withAlpha(200),
        ),
        const SizedBox(width: 10),
        AnimatedCrossFade(
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDarkTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
