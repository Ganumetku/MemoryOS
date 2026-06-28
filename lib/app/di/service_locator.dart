import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/storage_service.dart';

import '../../core/logger/logger_service.dart';
import '../../core/network/network_info.dart';
import '../../core/services/memory_connection_service.dart';
import '../../core/services/summary_service.dart';
import '../../core/services/insight_service.dart';
import '../../core/services/follow_up_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/home_experience_service.dart';
import '../../core/services/life_area_service.dart';
import '../../core/services/life_area_analytics_service.dart';
import '../../core/parser/life_area_parser.dart';
import '../../core/services/recall_engine_service.dart';
import '../../features/memories/data/datasources/memory_local_datasource.dart';
import '../../features/memories/data/models/memory_model.dart';
import '../../features/memories/data/models/follow_up_model.dart';
import '../../features/memories/data/repositories/memory_repository_impl.dart';
import '../../features/memories/domain/repositories/memory_repository.dart';
import '../../features/memories/domain/usecases/delete_memory_usecase.dart';
import '../../features/memories/domain/usecases/get_memories_usecase.dart';
import '../../features/memories/domain/usecases/save_memory_usecase.dart';
import '../../features/memories/domain/usecases/update_memory_usecase.dart';
import '../../core/services/notification_service.dart';
import '../../features/capture/presentation/bloc/capture_cubit.dart';
import '../../features/memories/presentation/bloc/memory_cubit.dart';
import '../../core/services/memory_brain_service.dart';
import '../../features/search/domain/repositories/search_history_repository.dart';
import '../../features/search/data/repositories/search_history_repository_impl.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Initializes dependency injection for the entire application.
Future<void> initServiceLocator() async {
  // ==========================================
  // External Clients & Database
  // ==========================================

  // Initialize Isar Local Database
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [MemoryModelSchema, FollowUpModelSchema],
    directory: dir.path,
  );
  sl.registerSingleton<Isar>(isar);

  // Initialize and Register SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);

  // Register Storage Service
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(sl()));

  // Supabase Client (Initialized after Supabase.initialize is called in main.dart)
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ==========================================
  // Core Services & Helpers
  // ==========================================

  // Logger Service
  sl.registerLazySingleton<LoggerService>(() => LoggerServiceImpl());

  // Notification Service
  final notificationService = NotificationServiceImpl();
  await notificationService.init();
  sl.registerSingleton<NotificationService>(notificationService);

  // Network Info / Internet Connection
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Summary Service
  sl.registerLazySingleton<SummaryService>(() => SummaryService(sl()));

  // Memory Connection Service
  sl.registerLazySingleton<MemoryConnectionService>(
    () => MemoryConnectionService(sl()),
  );

  // Insight Service
  sl.registerLazySingleton<InsightService>(
    () => InsightService(sl(), sl()),
  );

  // FollowUp Service
  sl.registerLazySingleton<FollowUpService>(
    () => FollowUpService(sl(), sl()),
  );

  // Analytics Service
  sl.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(sl(), sl()),
  );

  // HomeExperience Service
  sl.registerLazySingleton<HomeExperienceService>(
    () => HomeExperienceService(sl(), sl()),
  );

  // Recall Engine Service
  sl.registerLazySingleton<RecallEngineService>(
    () => LocalRecallEngineServiceImpl(),
  );

  // Search History Repository
  sl.registerLazySingleton<SearchHistoryRepository>(
    () => SearchHistoryRepositoryImpl(sl()),
  );

  // Memory Brain Service
  sl.registerLazySingleton<MemoryBrainService>(
    () => MemoryBrainService(sl()),
  );

  // LifeArea Services
  sl.registerLazySingleton<LifeAreaParser>(
    () => LifeAreaParser(),
  );

  sl.registerLazySingleton<LifeAreaAnalyticsService>(
    () => LifeAreaAnalyticsService(sl()),
  );

  sl.registerLazySingleton<LifeAreaService>(
    () => LifeAreaService(sl(), sl()),
  );

  // ==========================================
  // Memories Feature
  // ==========================================

  // Data sources
  sl.registerLazySingleton<MemoryLocalDataSource>(
    () => MemoryLocalDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<MemoryRepository>(() => MemoryRepositoryImpl(sl()));

  // Use Cases
  sl.registerLazySingleton(() => GetMemoriesUseCase(sl()));
  sl.registerLazySingleton(() => SaveMemoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMemoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMemoryUseCase(sl()));

  // Cubits
  sl.registerFactory(() => CaptureCubit(saveMemoryUseCase: sl()));

  sl.registerFactory(
    () => MemoryCubit(
      getMemoriesUseCase: sl(),
      saveMemoryUseCase: sl(),
      updateMemoryUseCase: sl(),
      deleteMemoryUseCase: sl(),
    ),
  );
}
