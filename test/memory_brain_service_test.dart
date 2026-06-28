import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memory_os/core/services/synonym_dictionary.dart';
import 'package:memory_os/core/services/intent_parser.dart';
import 'package:memory_os/core/services/memory_answer_generator.dart';
import 'package:memory_os/features/search/data/repositories/search_history_repository_impl.dart';
import 'package:memory_os/features/memories/domain/entities/memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SynonymDictionary Tests', () {
    test('Resolves synonym sets correctly case-insensitively', () {
      final synsDoctor = SynonymDictionary.getSynonyms('hospital');
      expect(synsDoctor, contains('doctor'));
      expect(synsDoctor, contains('clinic'));
      expect(synsDoctor.contains('hospital'), isFalse);

      final synsWork = SynonymDictionary.getSynonyms('Job');
      expect(synsWork, contains('work'));
      expect(synsWork, contains('career'));
    });

    test('Returns query itself if no synonyms found', () {
      final synsNone = SynonymDictionary.getSynonyms('randomxyzterm');
      expect(synsNone, isEmpty);
    });
  });

  group('IntentParser Tests', () {
    test('Correctly identifies date and time intents', () {
      expect(IntentParser.parse('What did I do today?'), equals(MemoryBrainIntent.todaySummary));
      expect(IntentParser.parse('saved yesterday'), equals(MemoryBrainIntent.yesterdaySummary));
      expect(IntentParser.parse('memories from this week'), equals(MemoryBrainIntent.weekSummary));
      expect(IntentParser.parse('what did I do this month?'), equals(MemoryBrainIntent.monthSummary));
    });

    test('Correctly identifies reminder-based intents', () {
      expect(IntentParser.parse('upcoming reminders'), equals(MemoryBrainIntent.upcomingReminder));
      expect(IntentParser.parse('completed reminders'), equals(MemoryBrainIntent.completedReminder));
      expect(IntentParser.parse('missed reminders'), equals(MemoryBrainIntent.missedReminder));
      expect(IntentParser.parse('reminders tomorrow'), equals(MemoryBrainIntent.upcomingReminder));
      expect(IntentParser.parse('Did I forget anything?'), equals(MemoryBrainIntent.missedReminder));
    });

    test('Correctly identifies stats and highlights', () {
      expect(IntentParser.parse('how productive was I today?'), equals(MemoryBrainIntent.productivityQuery));
      expect(IntentParser.parse('how many memories did I capture today?'), equals(MemoryBrainIntent.statisticsQuery));
    });

    test('Fallback to unknown for normal keyword queries', () {
      expect(IntentParser.parse('pancake recipes'), equals(MemoryBrainIntent.unknown));
    });
  });

  group('SearchHistoryRepository Tests', () {
    late SharedPreferences prefs;
    late SearchHistoryRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SearchHistoryRepositoryImpl(prefs);
    });

    test('Saves and retrieves search history correctly', () async {
      await repository.saveSearch('flutter');
      await repository.saveSearch('doctor');

      final history = await repository.getRecentSearches();
      expect(history, equals(['doctor', 'flutter']));
    });

    test('Deduplicates searches case-insensitively and puts latest first', () async {
      await repository.saveSearch('flutter');
      await repository.saveSearch('FLUTTER');
      await repository.saveSearch('Doctor');

      final history = await repository.getRecentSearches();
      expect(history, equals(['Doctor', 'FLUTTER']));
    });

    test('Limits search history to 10 entries', () async {
      for (int i = 1; i <= 12; i++) {
        await repository.saveSearch('query_$i');
      }

      final history = await repository.getRecentSearches();
      expect(history.length, equals(10));
      expect(history.first, equals('query_12'));
      expect(history.contains('query_1'), isFalse);
    });

    test('Clears search history', () async {
      await repository.saveSearch('flutter');
      await repository.clearHistory();

      final history = await repository.getRecentSearches();
      expect(history, isEmpty);
    });
  });

  group('MemoryAnswerGenerator Tests', () {
    final List<Memory> testMemories = [
      Memory(
        id: 1,
        title: 'Doctor appointment',
        content: 'Checkup',
        type: 'Health',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: const [],
        reminderAt: DateTime.now().add(const Duration(hours: 2)),
      ),
    ];

    test('Generates correct sentences for today intent', () {
      final answer = MemoryAnswerGenerator.generate(
        intent: MemoryBrainIntent.todaySummary,
        memories: testMemories,
        query: 'today',
        completedCount: 1,
        upcomingCount: 0,
      );
      expect(answer, contains('You captured 1 memory today'));
      expect(answer, contains('completed 1 reminders'));
    });

    test('Generates correct sentence for empty memories list', () {
      final answer = MemoryAnswerGenerator.generate(
        intent: MemoryBrainIntent.todaySummary,
        memories: const [],
        query: 'today',
      );
      expect(answer, equals("I couldn't find anything related to that. Try asking about another day, category, or reminder."));
    });
  });
}
