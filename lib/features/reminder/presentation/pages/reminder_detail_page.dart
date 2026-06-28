import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/reminder_countdown_service.dart';
import '../../../../core/services/reminder_status_service.dart';
import '../../../../core/services/reminder_action_service.dart';
import '../../../../core/utils/memory_type_helper.dart';
import '../../../../shared/widgets/memory_glass_card.dart';
import '../../../../shared/widgets/loading_skeletons.dart';
import '../../../memories/domain/entities/memory.dart';
import '../../../memories/presentation/bloc/memory_cubit.dart';
import '../../../memories/presentation/bloc/memory_state.dart';

class ReminderDetailPage extends StatefulWidget {
  final String reminderId;

  const ReminderDetailPage({super.key, required this.reminderId});

  @override
  State<ReminderDetailPage> createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _showConfetti = false;
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    // Minute timer to refresh countdown
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

    // Shake animation setup for Missed reminders
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0.0);
  }

  void _triggerConfetti() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showConfetti = true;
    });
  }

  String _formatTime(DateTime date) {
    final minStr = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final int displayHour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    return '$displayHour:$minStr $suffix';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _rescheduleFlow(BuildContext context, Memory memory) async {
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

      await ReminderActionService.rescheduleReminder(context, memory, newTime);
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rescheduled to ${_formatTime(newTime)}."),
          backgroundColor: AppColors.brandPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirm(BuildContext context, Memory m) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgDarkSecondary,
        title: const Text('Delete Reminder?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to permanently delete this reminder?', style: TextStyle(color: AppColors.textDarkSecondary)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkTertiary)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ReminderActionService.deleteReminder(context, m);
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryIdInt = int.tryParse(widget.reminderId) ?? -1;

    return BlocProvider(
      create: (_) => sl<MemoryCubit>()..fetchMemories(),
      child: Scaffold(
        backgroundColor: AppColors.bgDarkPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgDarkPrimary,
          elevation: 0,
          leading: const BackButton(color: AppColors.textDarkPrimary),
          title: Text(
            'Reminder Details',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDarkPrimary),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            BlocConsumer<MemoryCubit, MemoryState>(
              listener: (context, state) {
                if (state is MemoryLoaded) {
                  final list = state.memories.where((m) => m.id == memoryIdInt);
                  if (list.isNotEmpty) {
                    final m = list.first;
                    final status = ReminderStatusService.getStatus(m);
                    if (status == ReminderStatus.missed) {
                      _triggerShake();
                    }
                  }
                }
              },
              builder: (context, state) {
                if (state is MemoryLoading) {
                  return const TimelineSkeleton();
                }
                if (state is MemoryError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: AppColors.error)));
                }
                if (state is MemoryLoaded) {
                  final list = state.memories.where((m) => m.id == memoryIdInt);
                  if (list.isEmpty) {
                    return const Center(child: Text('Reminder not found.', style: TextStyle(color: AppColors.textDarkSecondary)));
                  }
                  final m = list.first;
                  final status = ReminderStatusService.getStatus(m);
                  final countdown = ReminderCountdownService.getCountdown(m);
                  final typeConfig = MemoryTypeHelper.getConfig(m.type);

                  // Color mapping
                  Color statusColor;
                  String statusText;
                  if (status == ReminderStatus.completed) {
                    statusColor = AppColors.success;
                    statusText = 'Completed';
                  } else if (status == ReminderStatus.missed) {
                    statusColor = AppColors.error;
                    statusText = 'Missed';
                  } else {
                    statusColor = AppColors.brandSecondary;
                    statusText = 'Upcoming';
                  }

                  return SingleChildScrollView(
                    padding: AppSpacing.pAll24,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            if (status == ReminderStatus.missed)
                              BoxShadow(
                                color: AppColors.error.withAlpha(40),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                          ],
                        ),
                        child: MemoryGlassCard(
                          borderRadius: BorderRadius.circular(24),
                          padding: AppSpacing.pAll24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Header Row (Category and Status Badge)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Category chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: typeConfig.color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: typeConfig.color.withAlpha(50), width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(typeConfig.emoji, style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 6),
                                        Text(
                                          m.type,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: typeConfig.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withAlpha(55), width: 1.0),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.v24,

                              // Reminder Title
                              Text(
                                m.title,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.textDarkPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              AppSpacing.v12,

                              // Countdown Row
                              if (countdown.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.hourglass_empty, size: 16, color: statusColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      countdown,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.v24,
                              ],

                              // Description Content
                              Text(
                                'Description',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textDarkTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.v8,
                              Text(
                                m.content,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textDarkSecondary,
                                ),
                              ),
                              AppSpacing.v24,

                              const Divider(color: AppColors.glassDarkBorder, height: 1),
                              AppSpacing.v24,

                              // Date and Time info
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DATE',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.textDarkTertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDate(m.reminderAt!),
                                          style: AppTextStyles.titleMedium.copyWith(
                                            color: AppColors.textDarkPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TIME',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.textDarkTertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTime(m.reminderAt!),
                                          style: AppTextStyles.titleMedium.copyWith(
                                            color: AppColors.textDarkPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.v32,

                              // Controls Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Toggle Completed Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: status == ReminderStatus.completed
                                          ? AppColors.bgDarkTertiary
                                          : AppColors.success.withAlpha(45),
                                      foregroundColor: status == ReminderStatus.completed
                                          ? AppColors.textDarkSecondary
                                          : Colors.white,
                                      side: BorderSide(
                                        color: status == ReminderStatus.completed
                                            ? AppColors.textDarkTertiary
                                            : AppColors.success,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    icon: Icon(status == ReminderStatus.completed ? Icons.undo : Icons.check_circle_outline),
                                    label: Text(
                                      status == ReminderStatus.completed ? 'Mark Incomplete' : 'Complete Reminder',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    onPressed: () {
                                      if (status != ReminderStatus.completed) {
                                        _triggerConfetti();
                                      } else {
                                        HapticFeedback.lightImpact();
                                      }
                                      ReminderActionService.completeReminder(context, m);
                                    },
                                  ),
                                  AppSpacing.v12,

                                  // Reschedule & Edit row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.brandPrimary,
                                            side: const BorderSide(color: AppColors.brandPrimary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          icon: const Icon(Icons.calendar_month),
                                          label: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: () => _rescheduleFlow(context, m),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.textDarkPrimary,
                                            side: const BorderSide(color: AppColors.glassDarkBorder),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            context.push('/memories/${m.id}').then((_) {
                                              if (context.mounted) {
                                                context.read<MemoryCubit>().fetchMemories();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.v12,

                                  // Cancel/Delete Button
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () => _showDeleteConfirm(context, m),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiBurst(
                    onComplete: () {
                      setState(() {
                        _showConfetti = false;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Particle model for Confetti
class Particle {
  double x, y;
  double vx, vy;
  final Color color;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx * 0.016; // 60 FPS approx delta
    y += vy * 0.016;
    vy += 9.8 * 15.0 * 0.016; // gravity
  }
}

class ConfettiBurst extends StatefulWidget {
  final VoidCallback onComplete;

  const ConfettiBurst({super.key, required this.onComplete});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final random = Random();
    final colors = [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
      AppColors.success,
      Colors.amber,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];

    // Burst particles from center-ish top
    for (int i = 0; i < 60; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 100.0 + random.nextDouble() * 250.0;
      _particles.add(
        Particle(
          x: 0, // dynamic start relative to layout custom painter offset
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 150.0, // slight upward force
          color: colors[random.nextInt(colors.length)],
          size: 4.0 + random.nextDouble() * 6.0,
        ),
      );
    }

    _controller.addListener(() {
      for (final p in _particles) {
        p.update();
      }
    });

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.save();
    // Center alignment for particle origin
    canvas.translate(size.width / 2, size.height / 3);

    for (final p in particles) {
      paint.color = p.color.withAlpha(((1.0 - progress) * 255).round().clamp(0, 255));
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
