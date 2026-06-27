import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class MemoryTypeConfig {
  final IconData icon;
  final Color color;

  const MemoryTypeConfig({required this.icon, required this.color});
}

class MemoryTypeHelper {
  MemoryTypeHelper._();

  static MemoryTypeConfig getConfig(String? type) {
    final t = (type ?? 'Personal').toLowerCase().trim();
    switch (t) {
      case 'idea':
        return const MemoryTypeConfig(
          icon: Icons.lightbulb_outline,
          color: AppColors.warning,
        );
      case 'health':
        return const MemoryTypeConfig(
          icon: Icons.favorite_border,
          color: AppColors.error,
        );
      case 'work':
        return const MemoryTypeConfig(
          icon: Icons.business_center_outlined,
          color: AppColors.info,
        );
      case 'finance':
        return const MemoryTypeConfig(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.success,
        );
      case 'shopping':
        return const MemoryTypeConfig(
          icon: Icons.shopping_bag_outlined,
          color: AppColors.brandAccent,
        );
      case 'travel':
        return const MemoryTypeConfig(
          icon: Icons.flight_takeoff_outlined,
          color: AppColors.brandSecondary,
        );
      case 'birthday':
        return const MemoryTypeConfig(
          icon: Icons.cake_outlined,
          color: AppColors.brandAccent,
        );
      case 'meeting':
        return const MemoryTypeConfig(
          icon: Icons.people_outline,
          color: AppColors.brandPrimary,
        );
      case 'reminder':
        return const MemoryTypeConfig(
          icon: Icons.notifications_none_outlined,
          color: AppColors.brandPrimary,
        );
      case 'task':
        return const MemoryTypeConfig(
          icon: Icons.check_circle_outline,
          color: AppColors.info,
        );
      case 'personal':
      default:
        return const MemoryTypeConfig(
          icon: Icons.person_outline,
          color: AppColors.brandSecondary,
        );
    }
  }
}
