import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/memory_empty_state.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/loading_skeletons.dart';
import '../../../../shared/widgets/memory_text_field.dart';
import '../../../capture/presentation/widgets/capture_bottom_sheet.dart';
import '../../../capture/presentation/bloc/capture_cubit.dart';
import '../../../capture/presentation/widgets/smart_analysis_bottom_sheet.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../memories/presentation/bloc/memory_state.dart';
import '../../../memories/presentation/widgets/memory_options_bottom_sheet.dart';
import '../../../memories/domain/usecases/get_memories_usecase.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../../../../core/utils/memory_type_helper.dart';
import '../../../../core/services/life_area_service.dart';
import '../../../../core/services/recall_engine_service.dart';
import '../../../../core/services/memory_brain_service.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/memory_search_stats.dart';
import '../widgets/memory_summary_card.dart';
import '../widgets/search_suggestion_chip.dart';

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

  MemoryBrainResult? _brainResult;
  List<String> _recentSearches = [];
  Timer? _debounceTimer;
  bool _isSearching = false;

  Timer? _rotationTimer;
  int _currentRotationIndex = 0;

  static const List<String> _rotationExamples = [
    'What did doctor tell me?',
    'Show tomorrow reminders.',
    'When is mom\'s birthday?',
    'Flutter ideas.',
    'What did I save today?',
  ];

  static const List<String> _loadingMessages = [
    'Searching memories...',
    'Looking through your memory vault...',
    'Connecting related thoughts...',
  ];
  String _loadingMessage = 'Searching memories...';

  @override
  void initState() {
    super.initState();
    _lifeAreaChips = ['All', ...sl<LifeAreaService>().areas];
    _searchController.addListener(_onSearchChanged);
    _loadHistory();

    _rotationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentRotationIndex = (_currentRotationIndex + 1) % _rotationExamples.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await sl<SearchHistoryRepository>().getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
    }
  }

  void _onSearchChanged() {
    final queryText = _searchController.text;
    setState(() {
      _query = queryText;
    });

    if (queryText.trim().isEmpty) {
      _debounceTimer?.cancel();
      setState(() {
        _brainResult = null;
        _isSearching = false;
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        try {
          final state = context.read<MemoryCubit>().state;
          final memories = state is MemoryLoaded ? state.memories : <Memory>[];
          _runRecall(memories);
        } catch (_) {
          final state = sl<MemoryCubit>().state;
          final memories = state is MemoryLoaded ? state.memories : <Memory>[];
          _runRecall(memories);
        }
      }
    });
  }

  void _runSearchImmediately(String term) {
    _debounceTimer?.cancel();
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    try {
      final state = context.read<MemoryCubit>().state;
      final memories = state is MemoryLoaded ? state.memories : <Memory>[];
      _runRecall(memories, forceImmediate: true);
    } catch (_) {
      final state = sl<MemoryCubit>().state;
      final memories = state is MemoryLoaded ? state.memories : <Memory>[];
      _runRecall(memories, forceImmediate: true);
    }
  }

  Future<void> _runRecall(List<Memory> fallbackMemories, {bool forceImmediate = false}) async {
    final queryText = _searchController.text.trim();
    if (queryText.isEmpty) {
      setState(() {
        _brainResult = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _loadingMessage = _loadingMessages[DateTime.now().millisecond % _loadingMessages.length];
    });

    List<Memory> latestMemories = fallbackMemories;
    try {
      final getMemoriesRes = await sl<GetMemoriesUseCase>()(NoParams());
      getMemoriesRes.fold(
        (failure) {
          debugPrint('[RecallPage] Failed to fetch latest database memories: ${failure.message}');
        },
        (list) {
          latestMemories = list;
        },
      );
    } catch (e) {
      debugPrint('[RecallPage] Exception fetching database memories: $e');
    }

    // Save to history repository
    await sl<SearchHistoryRepository>().saveSearch(queryText);
    _loadHistory();

    final stopwatch = Stopwatch()..start();

    // Call MemoryBrainService to process intent and generate conversational answer
    final result = await sl<MemoryBrainService>().process(
      query: queryText,
      memories: latestMemories,
    );

    final elapsed = stopwatch.elapsedMilliseconds;
    final remainingDelay = forceImmediate ? 0 : (500 - elapsed);
    if (remainingDelay > 0) {
      await Future.delayed(Duration(milliseconds: remainingDelay));
    }

    if (mounted) {
      setState(() {
        _brainResult = result;
        _isSearching = false;
      });
    }
  }

  Future<void> _openVoiceAssistant() async {
    HapticFeedback.lightImpact();
    final result = await context.push<dynamic>('/voice-capture');
    if (result is String && result.trim().isNotEmpty) {
      _searchController.text = result.trim();
    }
  }

  Widget _buildSuggestionChips() {
    final chips = [
      'Today',
      'Health',
      'Work',
      'Ideas',
      'Shopping',
      'Upcoming',
      'This Week',
      'Reminders',
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, __) => AppSpacing.h8,
        itemBuilder: (context, index) {
          final label = chips[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              String query = label.toLowerCase();
              if (label == 'Ideas') {
                query = 'idea';
              } else if (label == 'Reminders') {
                query = 'reminder';
              }
              _searchController.text = query;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withAlpha(20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.brandPrimary.withAlpha(40),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          ),
          AppSpacing.v20,
          Text(
            _loadingMessage,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDarkSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelevanceBadge(double score) {
    final pct = (score * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgDarkSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$pct% Match',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textDarkSecondary.withAlpha(150),
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildReminderStatusBadge(Memory m) {
    final isCompleted = m.tags.contains('completed_reminder');
    final isMissed = m.reminderAt != null && m.reminderAt!.isBefore(DateTime.now()) && !isCompleted;

    final String label = isCompleted
        ? 'Completed'
        : (isMissed ? 'Missed' : 'Upcoming');
    final Color color = isCompleted
        ? AppColors.success
        : (isMissed ? AppColors.error : AppColors.brandSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40), width: 1.0),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: sl<MemoryCubit>(),
          child: const CaptureBottomSheet(),
        );
      },
    ).then((voiceTranscript) {
      if (voiceTranscript is String && voiceTranscript.trim().isNotEmpty) {
        if (context.mounted) {
          showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<CaptureCubit>()),
                  BlocProvider.value(value: sl<MemoryCubit>()),
                ],
                child: SmartAnalysisBottomSheet(
                  rawContent: voiceTranscript,
                ),
              );
            },
          ).then((_) {
            cubit.fetchMemories();
          });
        }
      } else {
        cubit.fetchMemories();
      }
    });
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
                      hintText: _rotationExamples[_currentRotationIndex],
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textDarkTertiary,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.mic,
                          color: AppColors.brandPrimary,
                        ),
                        onPressed: _openVoiceAssistant,
                      ),
                    ),
                    AppSpacing.v12,

                    if (_query.trim().isEmpty) ...[
                      _buildSuggestionChips(),
                    ] else ...[
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
                    ],
                    AppSpacing.v24,

                    // Search results panel
                    Expanded(
                      child: BlocListener<MemoryCubit, MemoryState>(
                        listener: (context, state) {
                          if (state is MemoryLoaded) {
                            _runRecall(state.memories);
                          }
                        },
                        child: BlocBuilder<MemoryCubit, MemoryState>(
                          builder: (context, state) {
                            final cubit = context.read<MemoryCubit>();

                            if (state is MemoryLoading) {
                              return const TimelineSkeleton();
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

                              final rawResults = _brainResult?.memories ?? [];
                              // Filter by selected Life Area first
                              final filtered = rawResults.where((m) {
                                if (_selectedLifeArea != null) {
                                  return m.type.toLowerCase().trim() ==
                                      _selectedLifeArea!.toLowerCase().trim();
                                }
                                return true;
                              }).toList();

                              Widget contentWidget;

                              if (_query.trim().isEmpty) {
                                contentWidget = _buildEmptyInputState();
                              } else if (_isSearching) {
                                contentWidget = _buildLoadingState();
                              } else if (filtered.isEmpty) {
                                contentWidget = _buildEmptyStateWidget(memories);
                              } else {
                                contentWidget = SingleChildScrollView(
                                  key: ValueKey('results_found_${_query}_${filtered.length}'),
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      MemorySummaryCard(
                                        brainResult: _brainResult!,
                                        onOpenTimeline: () {
                                          context.go('/');
                                        },
                                        onOpenReminder: (m) {
                                          if (m != null) {
                                            context.push('/reminder/${m.id}').then((_) => cubit.fetchMemories());
                                          } else {
                                            context.go('/');
                                          }
                                        },
                                        onReschedule: (m) async {
                                          if (m != null) {
                                            await _rescheduleBrainReminder(context, m, cubit);
                                          }
                                        },
                                        onCompleteReminder: (m) {
                                          if (m != null) {
                                            HapticFeedback.mediumImpact();
                                            cubit.toggleReminderCompleted(m);
                                            ScaffoldMessenger.of(context).clearSnackBars();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Reminder marked complete!"),
                                                backgroundColor: AppColors.success,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                            // Refresh recall state
                                            final state = cubit.state;
                                            final memories = state is MemoryLoaded ? state.memories : <Memory>[];
                                            _runRecall(memories, forceImmediate: true);
                                          }
                                        },
                                        onViewCategory: (cat) {
                                          setState(() {
                                            _selectedLifeArea = cat;
                                          });
                                          _runRecall(memories, forceImmediate: true);
                                        },
                                      ),
                                      AppSpacing.v12,
                                      MemorySearchStats(
                                        memories: filtered,
                                      ),
                                      AppSpacing.v12,
                                      _buildRelatedSearchSection(filtered),
                                      AppSpacing.v16,
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) => AppSpacing.v12,
                                        itemBuilder: (context, index) {
                                          final m = filtered[index];
                                          final relevanceScore = _brainResult?.relevanceScores[m.id] ?? 1.0;

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
                                                                    child: HighlightedText(
                                                                      text: m.title,
                                                                      query: _query,
                                                                      style: AppTextStyles
                                                                          .titleMedium
                                                                          .copyWith(
                                                                            color: AppColors
                                                                                .textDarkPrimary,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                      highlightStyle: AppTextStyles
                                                                          .titleMedium
                                                                          .copyWith(
                                                                            color: AppColors
                                                                                .brandPrimary,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                      maxLines: 1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
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
                                                              HighlightedText(
                                                                text: m.content,
                                                                query: _query,
                                                                style: AppTextStyles
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                      color: AppColors
                                                                          .textDarkSecondary,
                                                                    ),
                                                                highlightStyle: AppTextStyles
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                      color: AppColors
                                                                          .brandPrimary,
                                                                      fontWeight:
                                                                          FontWeight.bold,
                                                                    ),
                                                                maxLines: 3,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
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
                                                                      if (relevanceScore > 0) ...[
                                                                        AppSpacing.h8,
                                                                        _buildRelevanceBadge(relevanceScore),
                                                                      ],
                                                                      if (m.reminderAt != null) ...[
                                                                        AppSpacing.h8,
                                                                        _buildReminderStatusBadge(m),
                                                                      ],
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
                                                                                  m.type &&
                                                                                  tag != 'completed_reminder',
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
                                      const SizedBox(height: 140),
                                    ],
                                  ),
                                );
                              }

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0.0, 0.05),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slide,
                                      child: child,
                                    ),
                                  );
                                },
                                child: contentWidget,
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
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

  static const List<String> _suggestedQuestions = [
    'What did I do today?',
    'Show my reminders.',
    'What did I learn this week?',
    'Health memories.',
    'Upcoming reminders.',
    'What ideas did I save?',
    'Meeting notes.',
    'Shopping list.',
  ];

  Widget _buildEmptyInputState() {
    return SingleChildScrollView(
      key: const ValueKey('empty_input'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Centered Brain Icon & Title
            Center(
              child: Column(
                children: [
                  const Text(
                    '🧠',
                    style: TextStyle(fontSize: 48),
                  ),
                  AppSpacing.v16,
                  Text(
                    'Ask me anything about your memories.',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.v8,
                  Text(
                    'Search for words, categories, time periods, or reminder statuses.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recent Searches History
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textDarkTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await sl<SearchHistoryRepository>().clearHistory();
                      _loadHistory();
                    },
                    child: Text(
                      'Clear',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((term) {
                  return GestureDetector(
                    onTap: () => _runSearchImmediately(term),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgDarkSecondary.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.glassDarkBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 12, color: AppColors.textDarkTertiary),
                          const SizedBox(width: 6),
                          Text(
                            term,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Suggested Questions
            Text(
              'Suggested Questions',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textDarkTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestedQuestions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                final question = _suggestedQuestions[index];
                return GestureDetector(
                  onTap: () => _runSearchImmediately(question),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.brandPrimary.withAlpha(35),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        question,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDarkPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(List<Memory> allMemories) {
    final suggestions = _getEmptyStateSuggestions(allMemories);
    return Center(
      key: ValueKey('no_match_found_$_query'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🧠',
              style: TextStyle(fontSize: 48),
            ),
            AppSpacing.v16,
            Text(
              "I couldn't remember anything about \"$_query\" yet.",
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textDarkSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.v24,
            if (suggestions.isNotEmpty) ...[
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Try: ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDarkTertiary,
                    ),
                  ),
                  for (int i = 0; i < suggestions.length; i++) ...[
                    GestureDetector(
                      onTap: () => _runSearchImmediately(suggestions[i]),
                      child: Text(
                        suggestions[i],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (i < suggestions.length - 1)
                      Text(
                        ', ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDarkTertiary,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getEmptyStateSuggestions(List<Memory> allMemories) {
    final suggestions = <String>{};
    for (final m in allMemories) {
      suggestions.addAll(m.tags.map((t) => t.toLowerCase()));
      suggestions.add(m.type.toLowerCase());
    }
    final cleanQuery = _query.trim().toLowerCase();
    suggestions.removeWhere((s) => s.isEmpty || 
        QueryNormalizer.fillerWords.contains(s) || 
        s == cleanQuery);

    final list = suggestions.toList();
    list.sort();
    
    final fallbacks = ['appointment', 'hospital', 'medicine', 'health', 'work', 'ideas'];
    for (final fb in fallbacks) {
      if (list.length >= 4) break;
      if (fb != cleanQuery && !list.contains(fb)) {
        list.add(fb);
      }
    }

    return list.take(4).toList();
  }

  Widget _buildRelatedSearchSection(List<Memory> results) {
    final related = <String>{};
    for (final m in results) {
      related.addAll(m.tags.map((t) => t.toLowerCase().trim()));
      related.add(m.type.toLowerCase().trim());
      final titleWords = m.title.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2);
      related.addAll(titleWords);
    }
    
    final cleanQuery = _query.toLowerCase().trim();
    related.removeWhere((w) => w.isEmpty || 
        QueryNormalizer.fillerWords.contains(w) || 
        w == cleanQuery || 
        w == 'completed_reminder');

    final list = related.toList();
    list.sort();

    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(
            'Related searches:',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textDarkTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list.take(6).length,
            separatorBuilder: (_, __) => AppSpacing.h8,
            itemBuilder: (context, index) {
              final term = list[index];
              return SearchSuggestionChip(
                label: term,
                onTap: () => _runSearchImmediately(term),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _rescheduleBrainReminder(
    BuildContext context,
    Memory memory,
    MemoryCubit cubit,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: memory.reminderAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.bgDarkSecondary,
              onSurface: AppColors.textDarkPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(memory.reminderAt ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.bgDarkSecondary,
              onSurface: AppColors.textDarkPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && context.mounted) {
      final newTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      cubit.rescheduleReminder(memory, newTime);

      final minStr = newTime.minute.toString().padLeft(2, '0');
      final suffix = newTime.hour >= 12 ? 'PM' : 'AM';
      final int displayHour = newTime.hour > 12
          ? newTime.hour - 12
          : (newTime.hour == 0 ? 12 : newTime.hour);
      final formattedTime = '$displayHour:$minStr $suffix';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rescheduled reminder to $formattedTime.",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.brandPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      final state = cubit.state;
      final memories = state is MemoryLoaded ? state.memories : <Memory>[];
      _runRecall(memories, forceImmediate: true);
    }
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
