import '../../features/memories/domain/entities/memory.dart';

class JourneyDetector {
  static const _journeyTopics = ['flutter', 'startup', 'health', 'finance', 'work', 'learning', 'ideas', 'shopping'];

  /// Detects if the targetMemory is part of a "Journey".
  /// Returns the name of the journey, e.g., "Health", "Flutter Learning", "Startup", or null.
  static String? detectJourney(Memory targetMemory, List<Memory> allMemories) {
    // 1. First search for specific topic keywords overlap
    final words = _extractWords("${targetMemory.title} ${targetMemory.content}");
    for (final topic in _journeyTopics) {
      if (words.contains(topic)) {
        final topicMemories = allMemories.where((m) {
          final mWords = _extractWords("${m.title} ${m.content}");
          return mWords.contains(topic);
        }).toList();
        
        if (topicMemories.length >= 3) {
          final targetTime = targetMemory.createdAt;
          final nearby = topicMemories.where((m) => m.createdAt.difference(targetTime).inDays.abs() <= 30).toList();
          if (nearby.length >= 3) {
            if (topic == 'flutter') return "Flutter Learning";
            if (topic == 'startup') return "Startup";
            return _capitalize(topic);
          }
        }
      }
    }

    // 2. Group candidate memories by general life area as fallback
    final sameAreaMemories = allMemories.where((m) => m.type.toLowerCase().trim() == targetMemory.type.toLowerCase().trim()).toList();
    if (sameAreaMemories.length >= 3) {
      final targetTime = targetMemory.createdAt;
      final nearby = sameAreaMemories.where((m) => m.createdAt.difference(targetTime).inDays.abs() <= 30).toList();
      if (nearby.length >= 3) {
        return _capitalize(targetMemory.type);
      }
    }

    return null;
  }

  static Set<String> _extractWords(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
