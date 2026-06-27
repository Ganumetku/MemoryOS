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
import '../../../capture/presentation/bloc/capture_cubit.dart';
import '../../../capture/presentation/widgets/capture_bottom_sheet.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../memories/presentation/bloc/memory_state.dart';
import '../../../memories/presentation/widgets/memory_options_bottom_sheet.dart';
import '../widgets/life_balance_card.dart';
import '../../../../core/services/summary_service.dart';
import '../../../../core/services/insight_service.dart';
import '../../../../core/services/follow_up_service.dart';
import '../../../../core/services/home_experience_service.dart';
import '../../../../core/utils/memory_type_helper.dart';
import '../../../memories/data/models/follow_up_model.dart';
import '../../../memories/data/models/memory_model.dart';
import 'package:isar/isar.dart';

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
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider(create: (_) => sl<CaptureCubit>()),
          ],
          child: const CaptureBottomSheet(),
        );
      },
    ).then((_) {
      cubit.fetchMemories();
    });
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

                  return FutureBuilder<HomeExperienceData>(
                    future: sl<HomeExperienceService>().getExperienceData(),
                    builder: (context, expSnapshot) {
                      final exp = expSnapshot.data;
                      final greetingText = exp?.greeting ?? 'Good Morning';
                      final subtitleText = exp?.subtitle ?? 'Ready to focus?';
                      final accentColor = exp?.accentColor ?? AppColors.brandPrimary;
                      final icon = exp?.icon ?? Icons.wb_sunny_outlined;

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
                                  Row(
                                    children: [
                                      Icon(
                                        icon,
                                        color: accentColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$greetingText, Ganesh 👋',
                                            style: AppTextStyles.titleMedium.copyWith(
                                              color: AppColors.textDarkPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            subtitleText,
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.textDarkTertiary,
                                            ),
                                          ),
                                        ],
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
                                    onPressed: () => context.push('/reminder'),
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
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: exp == null
                                    ? _buildSummaryCard(memories)
                                    : _buildExperienceCard(exp, memories),
                              ),
                            ),
                          ),
                        ),

                        // 3.2. Active Follow-up Card
                        _buildFollowUpSliver(context, memoryCubit),

                        // 3.3. Life Balance Card
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: LifeBalanceCard(),
                          ),
                        ),

                        // 3.5. Memory Insights Card
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _EntranceAnimation(
                              index: 3,
                              child: _buildInsightsCard(),
                            ),
                          ),
                        ),

                        // 4. Pinned memories section (Horizontal scrolling)
                        if (pinned.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            sliver: SliverToBoxAdapter(
                              child: _EntranceAnimation(
                                index: 4,
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
                },
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
    return FutureBuilder<DashboardSummary>(
      future: sl<SummaryService>().getSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final summary = snapshot.data!;
        String titleText = 'Daily Briefing';
        String subtitleText = '';
        IconData titleIcon = Icons.insights;
        Color titleColor = AppColors.brandPrimary;
        
        List<Widget> summaryItems = [];

        if (summary.todayCaptures == 0) {
          subtitleText = "Nothing captured today. Capture something worth remembering.";
          titleColor = AppColors.textDarkSecondary;
        } else {
          summaryItems.add(_SummaryBullet('• ${summary.todayCaptures} Memories Captured Today'));
        }

        if (summary.yesterdayCaptures > 0 && summary.todayCaptures == 0) {
          summaryItems.add(_SummaryBullet('• Yesterday you captured ${summary.yesterdayCaptures} memories'));
        }

        if (summary.upcomingRemindersToday > 0) {
          titleText = 'Needs Attention';
          titleColor = AppColors.brandSecondary;
          subtitleText = "You have ${summary.upcomingRemindersToday} things waiting for you.";
          summaryItems.add(_SummaryBullet('• ${summary.upcomingRemindersToday} Upcoming Reminder${summary.upcomingRemindersToday > 1 ? "s" : ""}'));
        }

        if (summary.missedReminders > 0) {
          titleText = 'Overdue';
          titleColor = AppColors.error;
          subtitleText = "Some things slipped through the cracks.";
          summaryItems.add(_SummaryBullet('• ${summary.missedReminders} Missed Reminder${summary.missedReminders > 1 ? "s" : ""}'));
        }

        if (summary.pinnedCount > 0) {
          summaryItems.add(_SummaryBullet('• ${summary.pinnedCount} Pinned Memor${summary.pinnedCount > 1 ? "ies" : "y"}'));
        }

        if (summary.currentStreak > 0) {
          summaryItems.add(_SummaryBullet('• ${summary.currentStreak} Day Capture Streak 🔥'));
        }

        if (summary.thisWeekCaptures > 0) {
          summaryItems.add(_SummaryBullet('• ${summary.thisWeekCaptures} Captures This Week'));
        }

        String lastActivity = "No previous activity";
        if (summary.lastActivity != null) {
          final diff = DateTime.now().difference(summary.lastActivity!);
          if (diff.inMinutes < 1) {
            lastActivity = "Captured just now";
          } else if (diff.inHours < 1) {
            lastActivity = "Captured ${diff.inMinutes}m ago";
          } else if (diff.inHours < 24) {
            lastActivity = "Captured ${diff.inHours}h ago";
          } else {
            lastActivity = "Captured ${diff.inDays}d ago";
          }
        }

        return MemoryGlassCard(
          padding: AppSpacing.pAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    titleIcon,
                    size: 16,
                    color: titleColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    titleText,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (subtitleText.isNotEmpty) ...[
                AppSpacing.v8,
                Text(
                  subtitleText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (summaryItems.isNotEmpty) ...[
                AppSpacing.v16,
                ...summaryItems,
              ],
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
      },
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

  Widget _buildTypeBadge(String? type) {
    final config = MemoryTypeHelper.getConfig(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withAlpha(40), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            config.icon == Icons.help_outline ? (type ?? 'Personal') : type ?? 'Personal', // Just in case
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, Memory m, MemoryCubit cubit) {
    final typeConfig = MemoryTypeHelper.getConfig(m.type);
    return MemoryGlassCard(
      padding: EdgeInsets.zero,
      onTap: () =>
          context.push('/memories/${m.id}').then((_) => cubit.fetchMemories()),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeConfig.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppSpacing.pAll16,
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
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildTypeBadge(m.type),
                              if (m.tags.isNotEmpty) ...[
                                ...m.tags
                                    .where((tag) => tag != m.type)
                                    .take(2)
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandPrimary
                                              .withAlpha(20),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.brandPrimary,
                                                fontSize: 9,
                                              ),
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                        if (m.isPinned) ...[
                          AppSpacing.h8,
                          const Icon(
                            Icons.push_pin,
                            size: 12,
                            color: AppColors.brandPrimary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          'Forget this memory?',
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

  Widget _buildInsightsCard() {
    return FutureBuilder<InsightsResult>(
      future: sl<InsightService>().getInsights(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MemoryGlassCard(
            padding: AppSpacing.pAll24,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final result = snapshot.data!;

        if (!result.hasEnoughData) {
          return MemoryGlassCard(
            padding: AppSpacing.pAll24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: AppColors.textDarkTertiary,
                ),
                AppSpacing.v12,
                Text(
                  'Keep capturing memories to unlock insights.',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.v8,
                Text(
                  'As you store more of your life fragments, MemoryOS will reveal personal patterns.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return MemoryGlassCard(
          padding: AppSpacing.pAll20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Memory Insights',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.v16,
              ...result.insights.map((insight) {
                final isLast = result.insights.last == insight;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
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
                          insight.icon,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      AppSpacing.h12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.headline,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.textDarkPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.v4,
                            Text(
                              insight.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDarkSecondary,
                              ),
                            ),
                          ],
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

  Widget _buildFollowUpSliver(BuildContext context, MemoryCubit cubit) {
    return FutureBuilder<FollowUpModel?>(
      future: sl<FollowUpService>().getActiveFollowUp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final followUp = snapshot.data!;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          sliver: SliverToBoxAdapter(
            child: _EntranceAnimation(
              index: 2,
              child: _buildFollowUpCard(context, followUp, cubit),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowUpCard(BuildContext context, FollowUpModel followUp, MemoryCubit cubit) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_outlined,
                size: 16,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Follow-up',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDarkTertiary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          AppSpacing.v12,
          Text(
            followUp.question,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Remind Later Button
              _buildFollowUpActionButton(
                icon: Icons.access_time_outlined,
                label: 'Later',
                color: AppColors.textDarkSecondary,
                onTap: () async {
                  await sl<FollowUpService>().remindLater(followUp.id);
                  cubit.fetchMemories();
                },
              ),
              AppSpacing.h12,
              // No Button
              _buildFollowUpActionButton(
                icon: Icons.close,
                label: 'No',
                color: AppColors.error,
                onTap: () async {
                  await sl<FollowUpService>().markNo(followUp.id);
                  cubit.fetchMemories();
                },
              ),
              AppSpacing.h12,
              // Yes Button
              _buildFollowUpActionButton(
                icon: Icons.check,
                label: 'Yes',
                color: AppColors.brandPrimary,
                onTap: () async {
                  if (!context.mounted) return;
                  
                  final captureCubit = context.read<CaptureCubit>();
                  
                  showDialog<bool>(
                    context: context,
                    builder: (dialContext) {
                      return AlertDialog(
                        backgroundColor: AppColors.bgDarkSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Add Details',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textDarkPrimary,
                          ),
                        ),
                        content: Text(
                          'Would you like to add what happened?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              'No, Skip',
                              style: TextStyle(color: AppColors.textDarkTertiary),
                            ),
                            onPressed: () {
                              Navigator.pop(dialContext, false);
                            },
                          ),
                          TextButton(
                            child: Text(
                              'Yes, Capture',
                              style: TextStyle(color: AppColors.brandPrimary),
                            ),
                            onPressed: () {
                              Navigator.pop(dialContext, true);
                            },
                          ),
                        ],
                      );
                    },
                  ).then((addDetails) async {
                    if (addDetails == true) {
                      final isar = sl<Isar>();
                      final originalMemory = await isar.memoryModels.get(followUp.memoryId);
                      
                      String prefilledText = "";
                      if (originalMemory != null) {
                        prefilledText = "Follow-up to ${originalMemory.title}: ";
                      }

                      if (context.mounted) {
                        showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) {
                            return MultiBlocProvider(
                              providers: [
                                BlocProvider.value(value: captureCubit),
                                BlocProvider.value(value: cubit),
                              ],
                              child: CaptureBottomSheet(
                                prefilledText: prefilledText,
                                parentMemoryId: followUp.memoryId,
                              ),
                            );
                          },
                        ).then((_) async {
                          await sl<FollowUpService>().markYes(followUp.id);
                          cubit.fetchMemories();
                        });
                      }
                    } else {
                      await sl<FollowUpService>().markYes(followUp.id);
                      cubit.fetchMemories();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(HomeExperienceData exp, List<Memory> memories) {
    switch (exp.period) {
      case TimePeriod.morning:
        return _buildMorningFocusCard(exp);
      case TimePeriod.afternoon:
        return _buildAfternoonProgressCard(exp);
      case TimePeriod.evening:
        return _buildEveningReflectionCard(exp);
      case TimePeriod.night:
        return _buildNightReflectionCard(exp);
    }
  }

  Widget _buildMorningFocusCard(HomeExperienceData data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Focus",
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.center_focus_strong_outlined,
                color: data.accentColor,
                size: 20,
              ),
            ],
          ),
          AppSpacing.v16,
          _buildDetailRow(Icons.alarm, '${data.todayRemindersCount} reminders scheduled today'),
          AppSpacing.v8,
          _buildDetailRow(Icons.rate_review_outlined, '${data.upcomingFollowUpsCount} pending follow-ups today'),
          AppSpacing.v16,
          const Divider(color: AppColors.bgDarkTertiary),
          AppSpacing.v8,
          Text(
            data.motivationalLine,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDarkSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfternoonProgressCard(HomeExperienceData data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Afternoon Progress',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.show_chart,
                color: data.accentColor,
                size: 20,
              ),
            ],
          ),
          AppSpacing.v16,
          _buildDetailRow(Icons.edit_note, '${data.todayCapturesCount} memories captured today'),
          AppSpacing.v8,
          _buildDetailRow(Icons.check_circle_outline, '${data.completedRemindersCount} reminders completed today'),
        ],
      ),
    );
  }

  Widget _buildEveningReflectionCard(HomeExperienceData data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evening Reflection',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.favorite_border,
                color: data.accentColor,
                size: 20,
              ),
            ],
          ),
          AppSpacing.v16,
          _buildDetailRow(Icons.history, '${data.todayMemories.length} memories captured today'),
          AppSpacing.v8,
          _buildDetailRow(Icons.hub_outlined, '${data.connectionsCreatedCount} connections formed today'),
        ],
      ),
    );
  }

  Widget _buildNightReflectionCard(HomeExperienceData data) {
    return MemoryGlassCard(
      padding: AppSpacing.pAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day Completed',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.bedtime_outlined,
                color: data.accentColor,
                size: 20,
              ),
            ],
          ),
          AppSpacing.v16,
          _buildDetailRow(Icons.task_alt, '${data.completedTodayCount} tasks/reminders completed today'),
          AppSpacing.v8,
          _buildDetailRow(Icons.next_plan_outlined, '${data.tomorrowRemindersCount} upcoming reminders tomorrow'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textDarkTertiary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDarkSecondary,
            ),
          ),
        ),
      ],
    );
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
