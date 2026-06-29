import 'package:isar/isar.dart';
import '../../features/memories/domain/entities/memory.dart';
import '../parser/smart_parser.dart';

enum ConnectionStrength {
  strong,
  related,
  lightlyRelated,
}

class ConnectionReason {
  final String text;
  final String type; // "type", "lifeArea", "person", "keyword", "time", "reminder", "topic"

  const ConnectionReason({required this.text, required this.type});
}

class MemoryConnection {
  final Memory targetMemory;
  final Memory connectedMemory;
  final ConnectionStrength strength;
  final List<ConnectionReason> reasons;
  final int similarityPercentage;

  MemoryConnection({
    required this.targetMemory,
    required this.connectedMemory,
    required this.strength,
    required this.reasons,
    required this.similarityPercentage,
  });
}

class MemoryGraphService {
  final Map<int, List<MemoryConnection>> _connectionsCache = {};

  MemoryGraphService([Isar? _]);

  void clearCache() {
    _connectionsCache.clear();
  }

  static const Set<String> _stopWords = {
    'the', 'is', 'at', 'which', 'on', 'in', 'a', 'an', 'and', 'or', 'to', 'with',
    'for', 'of', 'it', 'that', 'this', 'my', 'i', 'you', 'he', 'she', 'we', 'they',
    'was', 'as', 'are', 'be', 'from', 'by', 'but', 'not', 'have', 'has', 'had',
    'what', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few',
    'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'too', 'very', 'can',
    'will', 'just', 'should', 'now', 'do', 'does', 'did', 'am', 'me', 'us',
    'so', 'if', 'then', 'than', 'about', 'out', 'up', 'down', 'over', 'under',
  };

  /// Synchronously returns all calculated connection links for the target memory in relation to all memories.
  List<MemoryConnection> getConnections(Memory targetMemory, List<Memory> allMemories) {
    if (_connectionsCache.containsKey(targetMemory.id)) {
      return _connectionsCache[targetMemory.id]!;
    }

    final targetTitleWords = _extractKeywords(targetMemory.title);
    final targetContentWords = _extractKeywords(targetMemory.content);
    final targetTags = targetMemory.tags.map((t) => t.toLowerCase()).toSet();

    final targetParsed = SmartParserImpl().parse(targetMemory.content);
    final targetPerson = targetParsed.personName;

    final connections = <MemoryConnection>[];

    for (final candidate in allMemories) {
      if (candidate.id == targetMemory.id) continue;

      double score = 0.0;
      final reasons = <ConnectionReason>[];

      // 1. Same memory type / life area (+20)
      if (candidate.type.toLowerCase().trim() == targetMemory.type.toLowerCase().trim()) {
        score += 20.0;
        reasons.add(ConnectionReason(
          text: "Same life area: ${targetMemory.type}",
          type: "lifeArea",
        ));
      }

      // 2. Same person (+25)
      final candidateParsed = SmartParserImpl().parse(candidate.content);
      final candidatePerson = candidateParsed.personName;
      if (targetPerson != null && candidatePerson != null &&
          targetPerson.toLowerCase().trim() == candidatePerson.toLowerCase().trim()) {
        score += 25.0;
        reasons.add(ConnectionReason(
          text: "Same person: $targetPerson",
          type: "person",
        ));
      }

      // 3. Same tags (+15 per tag)
      final candidateTags = candidate.tags.map((t) => t.toLowerCase()).toSet();
      final commonTags = targetTags.intersection(candidateTags);
      if (commonTags.isNotEmpty) {
        score += (commonTags.length * 15.0);
        for (final tag in commonTags) {
          reasons.add(ConnectionReason(
            text: "Same tag: $tag",
            type: "keyword",
          ));
        }
      }

      // 4. Same reminder category / Same reminder day (+15)
      if (targetMemory.reminderAt != null && candidate.reminderAt != null) {
        final tReminder = targetMemory.reminderAt!;
        final cReminder = candidate.reminderAt!;
        if (tReminder.year == cReminder.year &&
            tReminder.month == cReminder.month &&
            tReminder.day == cReminder.day) {
          score += 15.0;
          reasons.add(const ConnectionReason(
            text: "Same reminder journey",
            type: "reminder",
          ));
        }
      }

      // 5. Shared Title Keywords (+10 per word)
      final candidateTitleWords = _extractKeywords(candidate.title);
      final commonTitleWords = targetTitleWords.intersection(candidateTitleWords);
      if (commonTitleWords.isNotEmpty) {
        score += (commonTitleWords.length * 10.0);
        for (final word in commonTitleWords) {
          reasons.add(ConnectionReason(
            text: "Common keyword: $word",
            type: "keyword",
          ));
        }
      }

      // 6. Shared Content Keywords (+5 per word)
      final candidateContentWords = _extractKeywords(candidate.content);
      final commonContentWords = targetContentWords.intersection(candidateContentWords);
      if (commonContentWords.isNotEmpty) {
        score += (commonContentWords.length * 5.0);
        for (final word in commonContentWords) {
          if (!commonTitleWords.contains(word)) {
            reasons.add(ConnectionReason(
              text: "Common keyword: $word",
              type: "keyword",
            ));
          }
        }
      }

      // 7. Created close together
      final daysDiff = targetMemory.createdAt.difference(candidate.createdAt).inDays.abs();
      if (daysDiff <= 2) {
        score += 25.0;
        reasons.add(ConnectionReason(
          text: "Created ${daysDiff == 0 ? "on the same day" : "$daysDiff days apart"}",
          type: "time",
        ));
      } else if (daysDiff <= 7) {
        score += 15.0;
        reasons.add(ConnectionReason(
          text: "Created $daysDiff days apart",
          type: "time",
        ));
      }

      // 8. Same project/topic (+20)
      final cleanTitleTarget = targetMemory.title.toLowerCase();
      final cleanTitleCand = candidate.title.toLowerCase();
      const topics = ['flutter', 'startup', 'work', 'finance', 'health', 'learning'];
      for (final topic in topics) {
        if (cleanTitleTarget.contains(topic) && cleanTitleCand.contains(topic)) {
          score += 20.0;
          reasons.add(ConnectionReason(
            text: "Same topic: ${topic[0].toUpperCase() + topic.substring(1)}",
            type: "topic",
          ));
        }
      }

      // Deduplicate reasons
      final uniqueReasonsMap = <String, ConnectionReason>{};
      for (final r in reasons) {
        uniqueReasonsMap[r.text] = r;
      }
      final uniqueReasons = uniqueReasonsMap.values.toList();

      int finalPercentage = score.round();
      if (finalPercentage > 100) finalPercentage = 100;

      if (finalPercentage >= 15 && uniqueReasons.isNotEmpty) {
        ConnectionStrength strength;
        if (finalPercentage >= 75) {
          strength = ConnectionStrength.strong;
        } else if (finalPercentage >= 40) {
          strength = ConnectionStrength.related;
        } else {
          strength = ConnectionStrength.lightlyRelated;
        }

        connections.add(MemoryConnection(
          targetMemory: targetMemory,
          connectedMemory: candidate,
          strength: strength,
          reasons: uniqueReasons,
          similarityPercentage: finalPercentage,
        ));
      }
    }

    connections.sort((a, b) => b.similarityPercentage.compareTo(a.similarityPercentage));
    _connectionsCache[targetMemory.id] = connections;
    return connections;
  }

  Set<String> _extractKeywords(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty && !_stopWords.contains(w) && w.length > 2).toSet();
  }
}
