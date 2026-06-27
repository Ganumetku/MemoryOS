import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// The root Widget of the MemoryOS application.
/// Integrates [AppRouter] navigation and [AppTheme] themes.
class MemoryOSApp extends StatelessWidget {
  const MemoryOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MemoryOS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to dark theme first
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
