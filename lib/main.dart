import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di/service_locator.dart';
import 'core/logger/logger_service.dart';

Future<void> main() async {
  // Ensure Flutter engine binding is fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services & Local Settings
  await _initializePlatformServices();

  // Run the application inside a guarded zone for error telemetry
  runZonedGuarded(() => runApp(const MemoryOSApp()), (error, stack) {
    if (sl.isRegistered<LoggerService>()) {
      sl<LoggerService>().e(
        'Uncaught root application error occurred',
        error,
        stack,
      );
    } else {
      debugPrint('Uncaught Exception: $error\n$stack');
    }
  });
}

/// Initializes dependencies, service locator container, and external modules (e.g. Supabase).
Future<void> _initializePlatformServices() async {
  try {
    // 1. Initialize Supabase Client
    // Note: We wrap it in a try-catch blocks to allow offline-first mode to proceed
    // even if keys are not set up or backend environment is unreachable.
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://placeholder.supabase.co',
      ),
      publishableKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'placeholder-anon-key-here',
      ),
    );
  } catch (e) {
    debugPrint(
      'Warning: Supabase client initialization failed (offline-first activated): $e',
    );
  }

  // 2. Initialize Dependency Injection Service Locator
  await initServiceLocator();

  // 3. Log Startup
  sl<LoggerService>().i(
    'MemoryOS successfully initialized services and service locator container.',
  );
}
