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
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/search/presentation/pages/recall_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

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
        path: '/memories/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MemoryDetailPage(memoryId: id);
        },
      ),
      GoRoute(
        path: '/reminder',
        builder: (context, state) => const ReminderPage(),
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
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route error: ${state.error}'))),
  );
}
