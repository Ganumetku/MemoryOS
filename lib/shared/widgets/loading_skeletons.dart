import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A premium pulsating shimmer loading box for MemoryOS skeletons.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.12, end: 0.28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((_animation.value * 255).round()),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Shimmer loading skeleton list matching memory timeline cards.
class TimelineSkeleton extends StatelessWidget {
  const TimelineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgDarkSecondary.withAlpha(150),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.bgDarkTertiary, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ShimmerBox(width: 120, height: 16, borderRadius: 4),
                  const ShimmerBox(width: 40, height: 12, borderRadius: 4),
                ],
              ),
              const SizedBox(height: 16),
              const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
              const SizedBox(height: 8),
              const ShimmerBox(width: 200, height: 12, borderRadius: 4),
              const SizedBox(height: 16),
              Row(
                children: [
                  const ShimmerBox(width: 60, height: 16, borderRadius: 8),
                  const SizedBox(width: 8),
                  const ShimmerBox(width: 50, height: 16, borderRadius: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmer loading skeleton card matching the today experience dashboard focus cards.
class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgDarkSecondary.withAlpha(150),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.bgDarkTertiary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerBox(width: 100, height: 16, borderRadius: 4),
              const ShimmerBox(width: 20, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const ShimmerBox(width: 16, height: 16, borderRadius: 8),
              const SizedBox(width: 8),
              const ShimmerBox(width: 180, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const ShimmerBox(width: 16, height: 16, borderRadius: 8),
              const SizedBox(width: 8),
              const ShimmerBox(width: 140, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.bgDarkTertiary),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
        ],
      ),
    );
  }
}
