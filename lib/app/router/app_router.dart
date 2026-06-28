import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/timeline/presentation/pages/timeline_page.dart';
import '../../features/capture/presentation/pages/capture_page.dart';
import '../../features/capture/presentation/pages/splash_page.dart';
import '../../features/capture/presentation/pages/welcome_page.dart';
import '../../features/memories/presentation/pages/memory_detail_page.dart';
import '../../features/reminder/presentation/pages/notification_debug_page.dart';
import '../../features/reminder/presentation/pages/reminder_page.dart';
import '../../features/reminder/presentation/pages/reminder_detail_page.dart';
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/search/presentation/pages/recall_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/developer_dashboard_page.dart';
import '../../features/timeline/presentation/pages/reflection_page.dart';
import '../../features/timeline/presentation/pages/weekly_review_page.dart';
import '../../features/timeline/presentation/pages/monthly_review_page.dart';
import '../../features/capture/presentation/pages/voice_capture_page.dart';

/// Central routing management using [GoRouter].
/// Outlines the entire navigation hierarchy for the MemoryOS application.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(path: '/recall', builder: (context, state) => const RecallPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      GoRoute(path: '/', builder: (context, state) => const TimelinePage()),
      GoRoute(
        path: '/capture',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CapturePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up transition for capture flow
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/voice-capture',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const VoiceCapturePage(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/memories/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildFadeSlideTransitionPage(
            state: state,
            child: MemoryDetailPage(memoryId: id),
          );
        },
      ),
      GoRoute(
        path: '/reminder',
        pageBuilder: (context, state) => _buildFadeSlideTransitionPage(
          state: state,
          child: const ReminderPage(),
        ),
      ),
      GoRoute(
        path: '/reminder/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildFadeSlideTransitionPage(
            state: state,
            child: ReminderDetailPage(reminderId: id),
          );
        },
      ),
      GoRoute(
        path: '/notification-debug',
        builder: (context, state) => const NotificationDebugPage(),
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) => const AiChatPage(),
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildFadeSlideTransitionPage(
          state: state,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: '/developer-dashboard',
        builder: (context, state) => const DeveloperDashboardPage(),
      ),
      GoRoute(
        path: '/reflection',
        builder: (context, state) => const ReflectionPage(),
      ),
      GoRoute(
        path: '/weekly-review',
        pageBuilder: (context, state) => _buildFadeSlideTransitionPage(
          state: state,
          child: const WeeklyReviewPage(),
        ),
      ),
      GoRoute(
        path: '/monthly-review',
        pageBuilder: (context, state) => _buildFadeSlideTransitionPage(
          state: state,
          child: const MonthlyReviewPage(),
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route error: ${state.error}'))),
  );

  static Page<dynamic> _buildFadeSlideTransitionPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }
}
