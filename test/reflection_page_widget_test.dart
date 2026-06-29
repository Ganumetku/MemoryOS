import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:memory_os/core/models/daily_reflection.dart';
import 'package:memory_os/core/services/reflection_engine.dart';
import 'package:memory_os/core/models/coach_recommendation.dart';
import 'package:memory_os/core/services/personal_coach_engine.dart';
import 'package:memory_os/features/timeline/presentation/pages/reflection_page.dart';
import 'package:memory_os/features/memories/presentation/bloc/memory_cubit.dart';
import 'package:memory_os/features/memories/domain/repositories/memory_repository.dart';
import 'package:memory_os/features/memories/domain/usecases/get_memories_usecase.dart';
import 'package:memory_os/features/memories/domain/usecases/save_memory_usecase.dart';
import 'package:memory_os/features/memories/domain/usecases/update_memory_usecase.dart';
import 'package:memory_os/features/memories/domain/usecases/delete_memory_usecase.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';
import 'package:memory_os/core/errors/failure.dart';

class FakeReflectionEngine implements ReflectionEngine {
  @override
  Future<DailyReflection> generateTodayReflection() async {
    return DailyReflection(
      date: DateTime.now(),
      title: 'Balanced Routine',
      summary: 'Today was steady and balanced.',
      mood: 'Balanced',
      score: 75.0,
      highlights: const ['Saved a key thought'],
      concerns: const [],
      suggestedActions: const ['Plan tomorrow\'s reminder'],
      reflectionQuestions: const ['What made today meaningful?'],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<DailyReflection> generateReflectionForDate(DateTime date) async {
    return generateTodayReflection();
  }
}

class FakeMemoryRepository implements MemoryRepository {
  @override
  Future<Either<Failure, List<Memory>>> getMemories() async => const Right([]);
  @override
  Future<Either<Failure, void>> saveMemory(Memory memory) async => const Right(null);
  @override
  Future<Either<Failure, void>> updateMemory(Memory memory) async => const Right(null);
  @override
  Future<Either<Failure, void>> deleteMemory(int id) async => const Right(null);
}

class FakePersonalCoachEngine implements PersonalCoachEngine {
  @override
  Future<List<CoachRecommendation>> generateRecommendations() async {
    return [
      const CoachRecommendation(
        title: 'Plan Tomorrow',
        description: 'Planning tomorrow before sleep helps.',
        priority: 'Medium',
        icon: Icons.edit_calendar_outlined,
        category: 'Productivity',
        actionType: 'none',
      )
    ];
  }

  @override
  String generateDailyCoachMessage(DailyReflection reflection) => 'Good coach message.';

  @override
  void invalidateCache() {}
}

void main() {
  final sl = GetIt.instance;

  setUpAll(() {
    sl.allowReassignment = true;
    final fakeRepo = FakeMemoryRepository();
    sl.registerLazySingleton<MemoryRepository>(() => fakeRepo);
    sl.registerLazySingleton(() => GetMemoriesUseCase(fakeRepo));
    sl.registerLazySingleton(() => SaveMemoryUseCase(fakeRepo));
    sl.registerLazySingleton(() => UpdateMemoryUseCase(fakeRepo));
    sl.registerLazySingleton(() => DeleteMemoryUseCase(fakeRepo));
    sl.registerLazySingleton<MemoryCubit>(() => MemoryCubit(
      getMemoriesUseCase: sl(),
      saveMemoryUseCase: sl(),
      updateMemoryUseCase: sl(),
      deleteMemoryUseCase: sl(),
    ));
    sl.registerLazySingleton<ReflectionEngine>(() => FakeReflectionEngine());
    sl.registerLazySingleton<PersonalCoachEngine>(() => FakePersonalCoachEngine());
  });

  testWidgets('ReflectionPage renders reflection content correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<MemoryCubit>.value(
          value: sl<MemoryCubit>(),
          child: const ReflectionPage(),
        ),
      ),
    );

    // Initial load state
    await tester.pump();

    // Pump and settle for FutureBuilder
    await tester.pumpAndSettle();

    // Verify reflection header
    expect(find.text('Balanced Routine'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);

    // Verify summary card
    expect(find.text('Today was steady and balanced.'), findsOneWidget);

    // Verify highlights
    expect(find.text('Saved a key thought'), findsOneWidget);

    // Verify suggested action
    expect(find.text('Plan tomorrow\'s reminder'), findsOneWidget);

    // Verify dynamic prompt question
    expect(find.text('What made today meaningful?'), findsOneWidget);
  });
}
