import 'package:flutter/foundation.dart';
import '../../features/memories/domain/entities/memory.dart';
import 'synonym_dictionary.dart';

/// Single search match inside Recall Engine.
class RecallSearchResult {
  final Memory memory;
  final double relevanceScore; // Normalized similarity score between 0.0 and 1.0

  RecallSearchResult({
    required this.memory,
    required this.relevanceScore,
  });
}

/// Consolidated engine result for search queries.
class RecallEngineResult {
  final String summary;
  final List<RecallSearchResult> results;

  RecallEngineResult({
    required this.summary,
    required this.results,
  });
}

/// Abstract contract for Recall Engine to support future LLM swaps.
abstract class RecallEngineService {
  Future<RecallEngineResult> recall({
    required String query,
    required List<Memory> memories,
  });
}

/// Utility class to normalize, clean, and map synonyms/aliases.
class QueryNormalizer {
  static const Map<String, String> _aliases = {
    'docter': 'doctor',
    'dr': 'doctor',
    'doc': 'doctor',
    'doctor': 'doctor',
    'appointment': 'appointment',
    'appt': 'appointment',
    'meeting': 'appointment',
    'medicine': 'medicine',
    'medication': 'medicine',
    'gym': 'fitness',
    'fitness': 'fitness',
    'mom': 'mother',
    'mum': 'mother',
    'mother': 'mother',
    'bill': 'payment',
    'payment': 'payment',
    'renew': 'renewal',
    'renewal': 'renewal',
  };

  static const Set<String> fillerWords = {
    'what', 'did', 'i', 'me', 'tell', 'about', 'show', 'find', 'my', 'the', 'is', 'at', 'on', 'in',
    'a', 'an', 'and', 'or', 'to', 'with', 'for', 'of', 'it', 'that', 'this', 'from', 'by', 'you',
    'please', 'remind', 'other'
  };

  /// Normalizes raw text: clean punctuation (p.m. -> pm), apply lowercase, aliases, and trim.
  static String normalize(String text) {
    String cleaned = text.toLowerCase().trim();
    cleaned = cleaned.replaceAll('p.m.', 'pm');
    cleaned = cleaned.replaceAll('a.m.', 'am');
    cleaned = cleaned.replaceAll('p.m', 'pm');
    cleaned = cleaned.replaceAll('a.m', 'am');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), ' ');

    final tokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final normalizedTokens = tokens.map((token) {
      return _aliases[token] ?? token;
    });

    return normalizedTokens.join(' ');
  }

  /// Tokenizes a query to clean keywords, filtering out filler words.
  static Set<String> tokenizeQuery(String query) {
    final normalized = normalize(query);
    return normalized
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !fillerWords.contains(t))
        .toSet();
  }

  /// Extracts clean normalized tokens as a List.
  static List<String> getNormalizedTokens(String text) {
    final norm = normalize(text);
    return norm.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }
}

/// Local offline client-side query matcher and summary generator.
class LocalRecallEngineServiceImpl implements RecallEngineService {


  List<String> _getWords(String text) {
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    return cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  @override
  Future<RecallEngineResult> recall({
    required String query,
    required List<Memory> memories,
  }) async {
    final now = DateTime.now();
    final queryClean = query.trim();
    if (queryClean.isEmpty) {
      return RecallEngineResult(summary: '', results: []);
    }

    final originalQuery = queryClean;
    final normalizedQuery = QueryNormalizer.normalize(originalQuery);
    final queryTokens = QueryNormalizer.tokenizeQuery(originalQuery);

    if (kDebugMode) {
      debugPrint('=== RecallDebug Log ===');
      debugPrint('Original Query: "$originalQuery"');
      debugPrint('Normalized Query: "$normalizedQuery"');
      debugPrint('Total Memories Loaded: ${memories.length}');
    }

    // Identify time constraints & filters
    final hasToday = queryTokens.contains('today');
    final hasYesterday = queryTokens.contains('yesterday');
    final hasTomorrow = queryTokens.contains('tomorrow');
    final hasThisWeek = queryTokens.contains('week');
    final hasLastWeek = normalizedQuery.contains('last week');
    final hasThisMonth = queryTokens.contains('month');

    // Identify reminder status constraints
    final hasReminder = queryTokens.contains('reminder') || queryTokens.contains('reminders');
    final hasMissed = queryTokens.contains('missed');
    final hasUpcoming = queryTokens.contains('upcoming');

    // Filter tokens list
    final filterTokens = {
      'today', 'yesterday', 'tomorrow', 'week', 'month',
      'reminder', 'reminders', 'missed', 'upcoming', 'memories', 'memory'
    };

    final queryWords = _getWords(originalQuery).where((w) => !QueryNormalizer.fillerWords.contains(w)).toList();
    final nonFilterQueryWords = queryWords.where((w) => !filterTokens.contains(w)).toList();
    final isFilterOnlyQuery = nonFilterQueryWords.isEmpty;

    final results = <RecallSearchResult>[];

    for (final memory in memories) {
      // 1. Check strict constraints
      final isCompleted = memory.tags.contains('completed_reminder');
      final isMissed = memory.reminderAt != null &&
          memory.reminderAt!.isBefore(now) &&
          !isCompleted;
      final isUpcoming = memory.reminderAt != null &&
          memory.reminderAt!.isAfter(now) &&
          !isCompleted;

      // Reminder status filter rule
      if ((hasReminder || hasMissed || hasUpcoming) && memory.reminderAt == null) {
        continue;
      }
      if (hasMissed && !isMissed) continue;
      if (hasUpcoming && !isUpcoming) continue;

      // Time filter rules
      if (hasToday && !_isSameDay(memory.createdAt, now)) continue;
      if (hasYesterday && !_isSameDay(memory.createdAt, now.subtract(const Duration(days: 1)))) continue;
      if (hasTomorrow) {
        final tomorrow = now.add(const Duration(days: 1));
        final matchesReminderTomorrow = memory.reminderAt != null && _isSameDay(memory.reminderAt!, tomorrow);
        final matchesTextTomorrow = memory.content.toLowerCase().contains('tomorrow') || memory.title.toLowerCase().contains('tomorrow');
        if (!matchesReminderTomorrow && !matchesTextTomorrow) continue;
      }

      double score = 0.0;
      final matchingPriorities = <int>[];

      // Exact title match (100)
      if (normalizedQuery == QueryNormalizer.normalize(memory.title)) {
        matchingPriorities.add(100);
      }

      final titleWords = _getWords(memory.title);
      final contentWords = _getWords(memory.content);
      final tagsLower = memory.tags.map((t) => t.toLowerCase()).toList();
      final typeLower = memory.type.toLowerCase();

      final titleWordsNormalized = titleWords.map((w) => QueryNormalizer._aliases[w] ?? w).toList();
      final contentWordsNormalized = contentWords.map((w) => QueryNormalizer._aliases[w] ?? w).toList();
      final tagsNormalized = tagsLower.map((w) => QueryNormalizer._aliases[w] ?? w).toList();
      final typeNormalized = QueryNormalizer._aliases[typeLower] ?? typeLower;

      int matchedQueryWordsCount = 0;

      if (isFilterOnlyQuery) {
        // If it's a filter-only query and the memory passed constraints, give it a base score of 80
        matchingPriorities.add(80);
        matchedQueryWordsCount = 1;
      } else {
        for (final qw in nonFilterQueryWords) {
          bool matched = false;

          // 1. Reminder / Title word match (85)
          if (titleWords.contains(qw)) {
            matchingPriorities.add(85);
            matched = true;
            matchedQueryWordsCount++;
          }

          // 2. Description (80)
          if (contentWords.contains(qw)) {
            matchingPriorities.add(80);
            matched = true;
            if (!titleWords.contains(qw)) {
              matchedQueryWordsCount++;
            }
          }

          // 3. Tags (75)
          if (tagsLower.contains(qw)) {
            matchingPriorities.add(75);
            matched = true;
            if (!titleWords.contains(qw) && !contentWords.contains(qw)) {
              matchedQueryWordsCount++;
            }
          }

          // 4. Category (70)
          if (typeLower == qw) {
            matchingPriorities.add(70);
            matched = true;
            if (!titleWords.contains(qw) && !contentWords.contains(qw) && !tagsLower.contains(qw)) {
              matchedQueryWordsCount++;
            }
          }

          // 5. Synonyms (60)
          if (!matched) {
            final synonyms = SynonymDictionary.getSynonyms(qw);
            bool synonymFound = false;
            for (final syn in synonyms) {
              if (titleWords.contains(syn) ||
                  contentWords.contains(syn) ||
                  tagsLower.contains(syn) ||
                  typeLower == syn) {
                synonymFound = true;
                break;
              }
            }
            if (synonymFound) {
              matchingPriorities.add(60);
              matched = true;
              matchedQueryWordsCount++;
            }
          }

          // 6. Partial word (50)
          if (!matched && qw.length >= 2) {
            final isPartial = titleWords.any((w) => w.contains(qw)) ||
                contentWords.any((w) => w.contains(qw)) ||
                tagsLower.any((t) => t.contains(qw)) ||
                typeLower.contains(qw);
            if (isPartial) {
              matchingPriorities.add(50);
              matched = true;
              matchedQueryWordsCount++;
            }
          }
        }
      }

      // Fallback contains search (50)
      if (matchingPriorities.isEmpty && !isFilterOnlyQuery) {
        final normalizedMemoryText = (titleWordsNormalized + contentWordsNormalized + tagsNormalized + [typeNormalized]).join(' ');
        bool fallbackMatch = false;
        for (final qwNormalized in nonFilterQueryWords.map((qw) => QueryNormalizer._aliases[qw] ?? qw)) {
          if (qwNormalized.length >= 2 && normalizedMemoryText.contains(qwNormalized)) {
            fallbackMatch = true;
            break;
          }
        }
        if (fallbackMatch) {
          matchingPriorities.add(50);
          matchedQueryWordsCount = 1;
        }
      }

      if (matchingPriorities.isNotEmpty) {
        final baseScore = matchingPriorities.reduce((a, b) => a > b ? a : b).toDouble();
        final matchDensity = nonFilterQueryWords.isNotEmpty
            ? (matchedQueryWordsCount / nonFilterQueryWords.length).clamp(0.0, 1.0)
            : 1.0;

        if (baseScore == 100) {
          score = 100.0;
        } else if (baseScore == 95) {
          score = 95.0 + matchDensity * 4.0; // range 95-99
        } else if (baseScore == 90) {
          score = 90.0 + matchDensity * 4.0; // range 90-94
        } else if (baseScore == 85) {
          score = 85.0 + matchDensity * 4.0; // range 85-89
        } else if (baseScore == 80) {
          score = 80.0 + matchDensity * 4.0; // range 80-84
        } else if (baseScore == 75) {
          score = 75.0 + matchDensity * 4.0; // range 75-79
        } else if (baseScore == 70) {
          score = 70.0 + matchDensity * 4.0; // range 70-74
        } else if (baseScore == 60) {
          score = 60.0 + matchDensity * 9.0; // range 60-69
        } else if (baseScore == 50) {
          score = 50.0 + matchDensity * 9.0; // range 50-59
        }

        // Apply time bounds & reminder boosts (up to +2.0)
        double boost = 0.0;
        if (hasToday && _isSameDay(memory.createdAt, now)) boost += 1.0;
        if (hasYesterday && _isSameDay(memory.createdAt, now.subtract(const Duration(days: 1)))) boost += 1.0;
        if (hasReminder && memory.reminderAt != null) boost += 1.0;
        if (hasThisWeek && memory.createdAt.isAfter(now.subtract(const Duration(days: 7)))) boost += 1.0;
        if (hasLastWeek) {
          final startOfLastWeek = now.subtract(const Duration(days: 14));
          final endOfLastWeek = now.subtract(const Duration(days: 7));
          if (memory.createdAt.isAfter(startOfLastWeek) && memory.createdAt.isBefore(endOfLastWeek)) {
            boost += 1.0;
          }
        }
        if (hasThisMonth && memory.createdAt.year == now.year && memory.createdAt.month == now.month) boost += 1.0;

        score = (score + boost).clamp(15.0, 100.0);

        results.add(
          RecallSearchResult(
            memory: memory,
            relevanceScore: score / 100.0,
          ),
        );
      }
    }

    // Sort by relevance score in descending order
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // Generate response summary
    final summary = _generateSummary(normalizedQuery, results.length, now, queryTokens);

    return RecallEngineResult(
      summary: summary,
      results: results,
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _generateSummary(String query, int count, DateTime now, Set<String> queryTokens) {
    if (count == 0) {
      return "I couldn't remember anything about that yet.";
    }

    final hasToday = queryTokens.contains('today');
    final hasTomorrow = queryTokens.contains('tomorrow');
    final hasYesterday = queryTokens.contains('yesterday');
    final hasReminder = queryTokens.contains('reminder') || queryTokens.contains('reminders') || queryTokens.contains('meeting') || queryTokens.contains('appointment');
    final hasMissed = queryTokens.contains('missed');
    final hasUpcoming = queryTokens.contains('upcoming');

    if (hasReminder && hasToday) {
      return "You have $count reminder${count == 1 ? '' : 's'} today.";
    }
    if (hasReminder && hasTomorrow) {
      return "You have $count reminder${count == 1 ? '' : 's'} scheduled tomorrow.";
    }
    if (hasReminder && hasMissed) {
      return "I found $count missed reminder${count == 1 ? '' : 's'}.";
    }
    if (hasReminder && hasUpcoming) {
      return "You have $count upcoming reminder${count == 1 ? '' : 's'}.";
    }
    if (hasReminder) {
      return "I found $count memory reminder${count == 1 ? '' : 's'}.";
    }

    // Idea special handling
    if (query.contains('idea') || query.contains('ideas')) {
      final otherTokens = queryTokens.where((t) => !{
        'idea', 'ideas', 'show', 'find', 'search', 'what', 'did', 'say', 'my', 'me', 'i'
      }.contains(t)).toList();
      if (otherTokens.isNotEmpty) {
        final topic = otherTokens.map((t) => t[0].toUpperCase() + t.substring(1)).join(' ');
        return "I found $count idea${count == 1 ? '' : 's'} about $topic.";
      }
      return "I found $count idea${count == 1 ? '' : 's'}.";
    }

    if (hasToday) {
      return "I found $count memory${count == 1 ? '' : 'ies'} from today.";
    }
    if (hasYesterday) {
      return "I found $count memory${count == 1 ? '' : 'ies'} from yesterday.";
    }
    if (query.contains('this week')) {
      return "I found $count memory${count == 1 ? '' : 'ies'} captured this week.";
    }
    if (query.contains('last week')) {
      return "I found $count memory${count == 1 ? '' : 'ies'} from last week.";
    }

    for (final area in [
      'work', 'health', 'finance', 'learning', 'fitness', 'family', 'startup',
      'travel', 'shopping', 'personal'
    ]) {
      if (query.contains(area)) {
        return "I found $count $area memory${count == 1 ? '' : 'ies'}.";
      }
    }

    if (query.contains('birthday')) {
      return "I found $count birthday related memory${count == 1 ? '' : 'ies'}.";
    }

    final cleanKeywords = queryTokens.where((t) => !{
      'today', 'yesterday', 'tomorrow', 'reminder', 'reminders', 'upcoming', 'missed', 'week', 'month'
    }.contains(t)).toList();

    final cleanTopic = cleanKeywords.isNotEmpty ? cleanKeywords.first : query;
    return "I remembered $count thing${count == 1 ? '' : 's'} about $cleanTopic.";
  }
}
