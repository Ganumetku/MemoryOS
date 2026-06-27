import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_loading_indicator.dart';
import '../../../capture/presentation/widgets/capture_bottom_sheet.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../memories/presentation/bloc/memory_state.dart';
import '../../../memories/presentation/widgets/memory_options_bottom_sheet.dart';

/// Redesigned Dashboard Page showing local memories from Isar database.
/// Incorporates premium Apple/Arc-like spacing, summary logs, pinned scrolling,
/// swipe action tags, and custom animated bottom navigation overlays.
class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryCubit>()..fetchMemories(),
      child: const _TimelinePageView(),
    );
  }
}

class _TimelinePageView extends StatefulWidget {
  const _TimelinePageView();

  @override
  State<_TimelinePageView> createState() => _TimelinePageViewState();
}

class _TimelinePageViewState extends State<_TimelinePageView> {
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
          side: const BorderSide(color: AppColors.brandPrimary, width: 1.0),
        ),
      ),
    );
  }

  void _showMemoryOptions(
    BuildContext context,
    Memory memory,
    MemoryCubit cubit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: MemoryOptionsBottomSheet(memory: memory),
        );
      },
    );
  }

  void _showCaptureSheet(BuildContext context, MemoryCubit cubit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: sl<MemoryCubit>(),
          child: const CaptureBottomSheet(),
        );
      },
    ).then((_) {
      cubit.fetchMemories();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final memoryCubit = context.read<MemoryCubit>();

    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            BlocBuilder<MemoryCubit, MemoryState>(
              builder: (context, state) {
                if (state is MemoryLoading) {
                  return const Center(child: MemoryLoadingIndicator());
                }

                if (state is MemoryError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }

                if (state is MemoryLoaded) {
                  final memories = state.memories;

                  // Split and group memories
                  final pinned = memories.where((m) => m.isPinned).toList();
                  final unpinned = memories.where((m) => !m.isPinned).toList();

                  final now = DateTime.now();
                  final todayMemories = unpinned
                      .where((m) => _isSameDay(m.createdAt, now))
                      .toList();
                  final yesterdayMemories = unpinned
                      .where((m) => _isYesterday(m.createdAt, now))
                      .toList();
                  final earlierMemories = unpinned
                      .where(
                        (m) =>
                            !_isSameDay(m.createdAt, now) &&
                            !_isYesterday(m.createdAt, now),
                      )
                      .toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // 1. Premium Top AppBar
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()}, Ganesh 👋',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.textDarkPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.textDarkSecondary,
                                    ),
                                    onPressed: () => _showComingSoonToast(
                                      context,
                                      'Notifications',
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showComingSoonToast(
                                      context,
                                      'Profile',
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.brandPrimary,
                                            AppColors.brandSecondary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Vault Glass Card
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _EntranceAnimation(
                            index: 0,
                            child: _buildVaultCard(memories.length),
                          ),
                        ),
                      ),

                      // If database has 0 memories, render the journey starts here placeholder directly
                      if (memories.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildEmptyState(context, memoryCubit),
                          ),
                        )
                      else ...[
                        // 3. Today's Summary Card
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _EntranceAnimation(
                              index: 1,
                              child: _buildSummaryCard(memories),
                            ),
                          ),
                        ),

                        // 4. Pinned memories section (Horizontal scrolling)
                        if (pinned.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            sliver: SliverToBoxAdapter(
                              child: _EntranceAnimation(
                                index: 2,
                                child: _buildPinnedSection(
                                  context,
                                  pinned,
                                  memoryCubit,
                                ),
                              ),
                            ),
                          ),

                        // 5. Timeline sections (grouped list)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (todayMemories.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Today',
                                  Icons.today,
                                  AppColors.brandSecondary,
                                ),
                                AppSpacing.v12,
                                ...todayMemories.map(
                                  (m) => _buildSwipeableMemoryCard(
                                    context,
                                    m,
                                    memoryCubit,
                                  ),
                                ),
                                AppSpacing.v16,
                              ],
                              if (yesterdayMemories.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Yesterday',
                                  Icons.calendar_today,
                                  AppColors.textDarkSecondary,
                                ),
                                AppSpacing.v12,
                                ...yesterdayMemories.map(
                                  (m) => _buildSwipeableMemoryCard(
                                    context,
                                    m,
                                    memoryCubit,
                                  ),
                                ),
                                AppSpacing.v16,
                              ],
                              if (earlierMemories.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Earlier',
                                  Icons.history,
                                  AppColors.textDarkTertiary,
                                ),
                                AppSpacing.v12,
                                ...earlierMemories.map(
                                  (m) => _buildSwipeableMemoryCard(
                                    context,
                                    m,
                                    memoryCubit,
                                  ),
                                ),
                                AppSpacing.v16,
                              ],
                              // Safety space at the bottom to scroll above navigation bar
                              const SizedBox(height: 100),
                            ]),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // 6. Custom Labeled Bottom Navigation Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _FloatingBottomBar(
                currentIndex: 0,
                onTimelineTap: () {},
                onRecallTap: () => context.go('/recall'),
                onCaptureTap: () => _showCaptureSheet(context, memoryCubit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        AppSpacing.h8,
        Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildVaultCard(int count) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Memory Vault',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.v4,
                  Text(
                    '$count memories safely stored',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
              const _AnimatedVaultIcon(),
            ],
          ),
          AppSpacing.v24,
          // Storage Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDarkSecondary,
                ),
              ),
              Text(
                '$count / Unlimited',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.v8,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count > 0 ? (count / 100).clamp(0.02, 1.0) : 0.0,
              backgroundColor: AppColors.bgDarkTertiary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandPrimary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Memory> memories) {
    final now = DateTime.now();
    final todayCount = memories
        .where((m) => _isSameDay(m.createdAt, now))
        .length;
    final remindersCount = memories.where((m) => m.reminderAt != null).length;
    final ideasCount = memories.where((m) => m.tags.contains('Idea')).length;
    final lastActivity = _getLastActivityText(memories);

    return MemoryGlassCard(
      padding: AppSpacing.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.v16,
          _SummaryBullet('• $todayCount Memories Captured'),
          _SummaryBullet(
            '• $remindersCount Reminder${remindersCount != 1 ? "s" : ""}',
          ),
          _SummaryBullet('• $ideasCount Idea${ideasCount != 1 ? "s" : ""}'),
          AppSpacing.v12,
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 12,
                color: AppColors.textDarkTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                lastActivity,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDarkSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedSection(
    BuildContext context,
    List<Memory> pinned,
    MemoryCubit cubit,
  ) {
    // Show maximum 3 pinned cards
    final cardsToShow = pinned.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSectionHeader(
            'Pinned Memories',
            Icons.push_pin,
            AppColors.brandPrimary,
          ),
        ),
        AppSpacing.v12,
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: cardsToShow.length,
            separatorBuilder: (_, __) => AppSpacing.h12,
            itemBuilder: (context, index) {
              final m = cardsToShow[index];
              return _buildPinnedScrollCard(context, m, cubit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedScrollCard(
    BuildContext context,
    Memory m,
    MemoryCubit cubit,
  ) {
    return GestureDetector(
      onTap: () =>
          context.push('/memories/${m.id}').then((_) => cubit.fetchMemories()),
      onLongPress: () => _showMemoryOptions(context, m, cubit),
      child: Container(
        width: 200,
        padding: AppSpacing.pAll16,
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withAlpha(20),
          borderRadius: AppRadius.brAll16,
          border: Border.all(
            color: AppColors.brandPrimary.withAlpha(80),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  m.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.push_pin,
                  size: 12,
                  color: AppColors.brandPrimary,
                ),
                Text(
                  _formatTime(m.createdAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textDarkTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableMemoryCard(
    BuildContext context,
    Memory m,
    MemoryCubit cubit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key('memory_${m.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right: Pin/Unpin
            cubit.togglePin(m);
            // Snap card back
            return false;
          } else {
            // Swipe left: Delete
            _showDeleteAlert(context, m, cubit);
            return false;
          }
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withAlpha(40),
            borderRadius: AppRadius.brAll16,
          ),
          child: Icon(
            m.isPinned ? Icons.pin_end_outlined : Icons.push_pin,
            color: AppColors.brandPrimary,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(40),
            borderRadius: AppRadius.brAll16,
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        child: GestureDetector(
          onLongPress: () => _showMemoryOptions(context, m, cubit),
          child: _buildMemoryCard(context, m, cubit),
        ),
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, Memory m, MemoryCubit cubit) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll16,
      onTap: () =>
          context.push('/memories/${m.id}').then((_) => cubit.fetchMemories()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppSpacing.h8,
              Text(
                _formatTime(m.createdAt),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDarkTertiary,
                ),
              ),
            ],
          ),
          AppSpacing.v8,
          Text(
            m.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDarkSecondary,
            ),
          ),
          AppSpacing.v12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 14,
                    color: AppColors.textDarkTertiary,
                  ),
                  if (m.tags.isNotEmpty) ...[
                    AppSpacing.h8,
                    ...m.tags
                        .take(2)
                        .map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
              if (m.isPinned)
                const Icon(
                  Icons.push_pin,
                  size: 12,
                  color: AppColors.brandPrimary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAlert(BuildContext context, Memory m, MemoryCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brAll16,
          side: BorderSide(color: AppColors.bgDarkTertiary, width: 1.0),
        ),
        title: Text(
          'Erase Memory?',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this memory?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDarkSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cubit.removeMemory(m.id);
              Navigator.pop(dialogCtx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MemoryCubit cubit) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Placeholder
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 56,
              color: AppColors.brandPrimary.withAlpha(200),
            ),
          ),
          AppSpacing.v24,
          Text(
            'Your journey starts here.',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.v8,
          Text(
            'Capture your first memory.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDarkSecondary,
            ),
          ),
          AppSpacing.v24,
          MemoryGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onTap: () => _showCaptureSheet(context, cubit),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.brandPrimary,
                  size: 18,
                ),
                AppSpacing.h8,
                Text(
                  'Capture Memory',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isYesterday(DateTime date, DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _formatTime(DateTime date) {
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr';
  }

  String _getLastActivityText(List<Memory> memories) {
    if (memories.isEmpty) {
      return 'No activity captured yet';
    }
    final latest = memories.first.createdAt;
    final diff = DateTime.now().difference(latest);
    if (diff.inMinutes < 1) {
      return 'Last activity just now';
    }
    if (diff.inMinutes < 60) {
      return 'Last activity ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return 'Last activity ${diff.inHours} hour${diff.inHours > 1 ? "s" : ""} ago';
    }
    return 'Last activity ${diff.inDays} day${diff.inDays > 1 ? "s" : ""} ago';
  }
}

class _SummaryBullet extends StatelessWidget {
  final String text;

  const _SummaryBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDarkSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Custom animated rotating lock icon to make the dashboard feel alive.
class _AnimatedVaultIcon extends StatefulWidget {
  const _AnimatedVaultIcon();

  @override
  State<_AnimatedVaultIcon> createState() => _AnimatedVaultIconState();
}

class _AnimatedVaultIconState extends State<_AnimatedVaultIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(); // repeats rotation infinitely
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RotationTransition(
          turns: _rotationController,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brandPrimary.withAlpha(80),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandSecondary.withAlpha(50),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Icon(Icons.lock_outline, size: 20, color: AppColors.brandPrimary),
      ],
    );
  }
}

/// Smooth staggered slide-up fade-in transition widget.
class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int index;

  const _EntranceAnimation({required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 120).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Labeled premium bottom navigation row with a large center capture button.
class _FloatingBottomBar extends StatefulWidget {
  final int currentIndex;
  final VoidCallback onTimelineTap;
  final VoidCallback onRecallTap;
  final VoidCallback onCaptureTap;

  const _FloatingBottomBar({
    required this.currentIndex,
    required this.onTimelineTap,
    required this.onRecallTap,
    required this.onCaptureTap,
  });

  @override
  State<_FloatingBottomBar> createState() => _FloatingBottomBarState();
}

class _FloatingBottomBarState extends State<_FloatingBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.bgDarkSecondary.withAlpha(225),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.bgDarkTertiary.withAlpha(128),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Timeline Tab
              GestureDetector(
                onTap: widget.onTimelineTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.currentIndex == 0
                          ? Icons.dashboard
                          : Icons.dashboard_outlined,
                      color: widget.currentIndex == 0
                          ? AppColors.textDarkPrimary
                          : AppColors.textDarkTertiary,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Timeline',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.currentIndex == 0
                            ? AppColors.textDarkPrimary
                            : AppColors.textDarkTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Empty spacer representing center FAB
              const SizedBox(width: 48),

              // Recall Tab
              GestureDetector(
                onTap: widget.onRecallTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.currentIndex == 2
                          ? Icons.psychology
                          : Icons.psychology_outlined,
                      color: widget.currentIndex == 2
                          ? AppColors.textDarkPrimary
                          : AppColors.textDarkTertiary,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recall',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.currentIndex == 2
                            ? AppColors.textDarkPrimary
                            : AppColors.textDarkTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // High Elevated Animated Capture FAB Center Overlay
          Positioned(
            top: -24,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTapDown: (_) {
                    _pulseController.forward();
                  },
                  onTapUp: (_) {
                    _pulseController.reverse();
                    widget.onCaptureTap();
                  },
                  onTapCancel: () {
                    _pulseController.reverse();
                  },
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandPrimary,
                          AppColors.brandSecondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withAlpha(128),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
