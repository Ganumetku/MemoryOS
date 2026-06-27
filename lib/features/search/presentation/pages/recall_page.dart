import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_empty_state.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/memory_loading_indicator.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../../../capture/presentation/widgets/capture_bottom_sheet.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../memories/presentation/bloc/memory_state.dart';
import '../../../memories/presentation/widgets/memory_options_bottom_sheet.dart';

/// Recall page providing local search/retrieval of stored memories.
class RecallPage extends StatefulWidget {
  const RecallPage({super.key});

  @override
  State<RecallPage> createState() => _RecallPageState();
}

class _RecallPageState extends State<RecallPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryCubit>()..fetchMemories(),
      child: Scaffold(
        backgroundColor: AppColors.bgDarkPrimary,
        appBar: AppBar(
          title: Text(
            'Recall Memory',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: AppSpacing.pHoriz16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.v16,
                    // Search Input Box
                    MemoryTextField(
                      controller: _searchController,
                      hintText: 'What do you want to remember?',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textDarkTertiary,
                      ),
                    ),
                    AppSpacing.v24,

                    // Search results panel
                    Expanded(
                      child: BlocBuilder<MemoryCubit, MemoryState>(
                        builder: (context, state) {
                          final cubit = context.read<MemoryCubit>();

                          if (state is MemoryLoading) {
                            return const Center(
                              child: MemoryLoadingIndicator(),
                            );
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

                            // 1. If database is completely empty
                            if (memories.isEmpty) {
                              return MemoryEmptyState(
                                icon: Icons.search_off_outlined,
                                title: 'Nothing remembered yet.',
                                description:
                                    'Your search index is empty. Log a new memory on the capture tab to begin searching.',
                                actionLabel: 'Capture Memory',
                                onActionPressed: () async {
                                  await context.push('/capture');
                                  cubit.fetchMemories();
                                },
                              );
                            }

                            // 2. Perform client-side keyword matching
                            final filtered = memories.where((m) {
                              final searchKey = _query.trim().toLowerCase();
                              if (searchKey.isEmpty) return true;
                              return m.title.toLowerCase().contains(
                                    searchKey,
                                  ) ||
                                  m.content.toLowerCase().contains(searchKey);
                            }).toList();

                            // 3. No match state
                            if (filtered.isEmpty) {
                              return MemoryEmptyState(
                                icon: Icons.psychology_alt_outlined,
                                title: "I couldn't find that memory.",
                                description:
                                    'Try searching other keywords, or confirm the details of what you logged.',
                              );
                            }

                            // 4. Render results
                            return ListView.separated(
                              itemCount: filtered.length,
                              padding: const EdgeInsets.only(bottom: 100),
                              separatorBuilder: (_, __) => AppSpacing.v12,
                              itemBuilder: (context, index) {
                                final m = filtered[index];
                                return GestureDetector(
                                  onLongPress: () =>
                                      _showMemoryOptions(context, m, cubit),
                                  child: MemoryGlassCard(
                                    padding: AppSpacing.pAll16,
                                    onTap: () => context
                                        .push('/memories/${m.id}')
                                        .then((_) => cubit.fetchMemories()),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                m.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.titleMedium
                                                    .copyWith(
                                                      color: AppColors
                                                          .textDarkPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            if (m.isPinned)
                                              const Icon(
                                                Icons.push_pin,
                                                size: 14,
                                                color: AppColors.brandPrimary,
                                              ),
                                            AppSpacing.h8,
                                            Text(
                                              _formatTime(m.createdAt),
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                    color: AppColors
                                                        .textDarkTertiary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        AppSpacing.v8,
                                        Text(
                                          m.content,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color:
                                                    AppColors.textDarkSecondary,
                                              ),
                                        ),
                                        if (m.tags.isNotEmpty) ...[
                                          AppSpacing.v12,
                                          Wrap(
                                            spacing: 8,
                                            children: m.tags.map((tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandPrimary
                                                      .withAlpha(15),
                                                  borderRadius:
                                                      AppRadius.brAll8,
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: AppTextStyles
                                                      .labelSmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .brandPrimary,
                                                        fontSize: 10,
                                                      ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Custom Floating Bottom Navigation Bar (matches Timeline exactly)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: BlocBuilder<MemoryCubit, MemoryState>(
                  builder: (context, state) {
                    final cubit = context.read<MemoryCubit>();
                    return _FloatingBottomBar(
                      currentIndex: 2, // Recall active
                      onTimelineTap: () => context.go('/'),
                      onRecallTap: () {},
                      onCaptureTap: () => _showCaptureSheet(context, cubit),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr';
  }
}

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
