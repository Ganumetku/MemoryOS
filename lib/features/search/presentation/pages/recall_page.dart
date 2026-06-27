import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
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
import '../../../../core/utils/memory_type_helper.dart';
import '../../../../core/services/life_area_service.dart';

/// Recall page providing local search/retrieval of stored memories.
class RecallPage extends StatefulWidget {
  const RecallPage({super.key});

  @override
  State<RecallPage> createState() => _RecallPageState();
}

class _RecallPageState extends State<RecallPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String? _selectedLifeArea;

  late final List<String> _lifeAreaChips;

  @override
  void initState() {
    super.initState();
    _lifeAreaChips = ['All', ...sl<LifeAreaService>().areas];
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
          Text(config.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            config.icon == Icons.help_outline ? (type ?? 'Personal') : type ?? 'Personal',
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

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MemoryCubit>()..fetchMemories(),
      child: Scaffold(
        backgroundColor: AppColors.bgDarkPrimary,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: AppSpacing.pHoriz16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.v24,
                    // 1. Redesigned Header
                    Text(
                      'Ask your memory',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.v4,
                    Text(
                      'Search anything you have captured.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                    AppSpacing.v20,

                    // 2. Search Input Box
                    MemoryTextField(
                      controller: _searchController,
                      hintText: 'Try: birthday, meeting, idea, Flutter...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textDarkTertiary,
                      ),
                    ),
                    AppSpacing.v12,

                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _lifeAreaChips.length,
                        separatorBuilder: (_, __) => AppSpacing.h8,
                        itemBuilder: (context, index) {
                          final chip = _lifeAreaChips[index];
                          final isSelected = (chip == 'All' && _selectedLifeArea == null) ||
                              (_selectedLifeArea?.toLowerCase() == chip.toLowerCase());
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (chip == 'All') {
                                  _selectedLifeArea = null;
                                } else {
                                  _selectedLifeArea = chip;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.brandPrimary.withAlpha(40)
                                    : AppColors.bgDarkSecondary,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.brandPrimary
                                      : AppColors.bgDarkTertiary,
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  chip,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isSelected
                                        ? AppColors.brandPrimary
                                        : AppColors.textDarkSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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

                            // 1. Empty State
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
                              // Filter by selected Life Area first
                              if (_selectedLifeArea != null) {
                                if (m.type.toLowerCase().trim() != _selectedLifeArea!.toLowerCase().trim()) {
                                  return false;
                                }
                              }

                              final searchKey = _query.trim().toLowerCase();
                              if (searchKey.isEmpty) return true;

                              // Special conditions
                              if (searchKey == 'today') {
                                return _isSameDay(m.createdAt, DateTime.now());
                              }
                              if (searchKey == 'pinned') {
                                return m.isPinned;
                              }

                              return m.title.toLowerCase().contains(
                                    searchKey,
                                  ) ||
                                  m.content.toLowerCase().contains(searchKey) ||
                                  m.tags.any(
                                    (t) => t.toLowerCase() == searchKey,
                                  );
                            }).toList();

                            // 3. No match state
                            if (filtered.isEmpty) {
                              return MemoryEmptyState(
                                icon: Icons.psychology_alt_outlined,
                                title: "I couldn't find that memory yet.",
                                description:
                                    'Try searching other keywords, or confirm the details of what you logged.',
                              );
                            }

                            // 4. Render results with count header
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_query.trim().isNotEmpty) ...[
                                  Text(
                                    filtered.length == 1
                                        ? "I found 1 memory for '$_query'"
                                        : "I found ${filtered.length} memories for '$_query'",
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  AppSpacing.v16,
                                ],
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: filtered.length,
                                    padding: const EdgeInsets.only(bottom: 100),
                                    separatorBuilder: (_, __) => AppSpacing.v12,
                                    itemBuilder: (context, index) {
                                      final m = filtered[index];
                                      return GestureDetector(
                                        onLongPress: () => _showMemoryOptions(
                                          context,
                                          m,
                                          cubit,
                                        ),
                                        child: () {
                                          final typeConfig =
                                              MemoryTypeHelper.getConfig(
                                                m.type,
                                              );
                                          return MemoryGlassCard(
                                            padding: EdgeInsets.zero,
                                            onTap: () => context
                                                .push('/memories/${m.id}')
                                                .then(
                                                  (_) => cubit.fetchMemories(),
                                                ),
                                            child: IntrinsicHeight(
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Container(
                                                    width: 4,
                                                    decoration: BoxDecoration(
                                                      color: typeConfig.color,
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  16,
                                                                ),
                                                            bottomLeft:
                                                                Radius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          AppSpacing.pAll16,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  m.title,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: AppTextStyles
                                                                      .titleMedium
                                                                      .copyWith(
                                                                        color: AppColors
                                                                            .textDarkPrimary,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                ),
                                                              ),
                                                              if (m
                                                                  .isPinned) ...[
                                                                const Icon(
                                                                  Icons
                                                                      .push_pin,
                                                                  size: 14,
                                                                  color: AppColors
                                                                      .brandPrimary,
                                                                ),
                                                                AppSpacing.h8,
                                                              ],
                                                              Text(
                                                                _formatDateTime(
                                                                  m.createdAt,
                                                                ),
                                                                style: AppTextStyles
                                                                    .labelSmall
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
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTextStyles
                                                                .bodyMedium
                                                                .copyWith(
                                                                  color: AppColors
                                                                      .textDarkSecondary,
                                                                ),
                                                          ),
                                                          AppSpacing.v12,
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  _buildTypeBadge(
                                                                    m.type,
                                                                  ),
                                                                  if (m
                                                                      .tags
                                                                      .isNotEmpty) ...[
                                                                    AppSpacing
                                                                        .h8,
                                                                    ...m.tags
                                                                        .where(
                                                                          (
                                                                            tag,
                                                                          ) =>
                                                                              tag !=
                                                                              m.type,
                                                                        )
                                                                        .take(2)
                                                                        .map((
                                                                          tag,
                                                                        ) {
                                                                          return Padding(
                                                                            padding: const EdgeInsets.only(
                                                                              right: 6.0,
                                                                            ),
                                                                            child: Container(
                                                                              padding: const EdgeInsets.symmetric(
                                                                                horizontal: 6,
                                                                                vertical: 2,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                color: AppColors.brandPrimary.withAlpha(
                                                                                  20,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(
                                                                                  4,
                                                                                ),
                                                                              ),
                                                                              child: Text(
                                                                                tag,
                                                                                style: AppTextStyles.labelSmall.copyWith(
                                                                                  color: AppColors.brandPrimary,
                                                                                  fontSize: 9,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }),
                                                                  ],
                                                                ],
                                                              ),
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
                                        }(),
                                      );
                                    },
                                  ),
                                ),
                              ],
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

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[date.month - 1];
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minStr = date.minute.toString().padLeft(2, '0');
    return '${date.day} $monthStr • $hourStr:$minStr';
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
