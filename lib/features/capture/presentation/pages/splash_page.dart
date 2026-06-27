import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';

/// Screen 001 - Splash Screen.
/// Displays a minimal glowing logo and text with a smooth fade animation,
/// then redirects to `/welcome`.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _opacity = 0.0;
  late Timer _fadeTimer;
  late Timer _navTimer;

  @override
  @override
  void initState() {
    super.initState();

    // Trigger fade in animation shortly after build
    _fadeTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Navigate to Welcome screen or Timeline based on onboarding completion status
    _navTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        final completed = sl<StorageService>().getHasCompletedOnboarding();
        if (completed) {
          context.go('/');
        } else {
          context.go('/welcome');
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeTimer.cancel();
    _navTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Brain Logo Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withAlpha(20),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withAlpha(50),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 64,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // Brand Text
              Text(
                'MemoryOS',
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDarkPrimary,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
