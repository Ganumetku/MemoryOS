import 'package:isar/isar.dart';

import '../../features/memories/data/models/memory_model.dart';
import '../../features/memories/domain/entities/memory.dart';
import '../parser/smart_parser.dart';

class RelatedMemory {
  final Memory memory;
  final int similarityPercentage;
  final List<String> reasons;

  RelatedMemory({
    required this.memory,
    required this.similarityPercentage,
    required this.reasons,
  });
}

class MemoryConnectionService {
  final Isar _isar;

  // Simple set of stop words to ignore in similarity matching
  static const Set<String> _stopWords = {
    'the', 'is', 'at', 'which', 'on', 'in', 'a', 'an', 'and', 'or', 'to', 'with',
    'for', 'of', 'it', 'that', 'this', 'my', 'i', 'you', 'he', 'she', 'we', 'they',
    'was', 'as', 'are', 'be', 'from', 'by', 'but', 'not', 'have', 'has', 'had',
    'what', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few',
    'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'too', 'very', 'can',
    'will', 'just', 'should', 'now', 'do', 'does', 'did', 'am', 'me', 'us',
    'so', 'if', 'then', 'than', 'about', 'out', 'up', 'down', 'over', 'under',
  };

  static const Set<String> _categories = {
    'idea', 'health', 'work', 'personal', 'finance', 'shopping',
    'travel', 'birthday', 'meeting', 'reminder', 'task'
  };

  MemoryConnectionService(this._isar);

  Future<List<RelatedMemory>> getRelatedMemories(Memory targetMemory) async {
    // Fetch all memories
    final allMemoryModels = await _isar.memoryModels.where().findAll();

    List<RelatedMemory> relatedMemories = [];

    final targetTitleWords = _extractKeywords(targetMemory.title);
    final targetContentWords = _extractKeywords(targetMemory.content);
    final targetTags = targetMemory.tags.map((t) => t.toLowerCase()).toSet();

    // Parse person name of target memory if available
    final targetParsed = SmartParserImpl().parse(targetMemory.content);
    final targetPerson = targetParsed.personName;

    // Deduplicate models using a set of IDs
    final seenIds = <int>{};

    for (final model in allMemoryModels) {
      if (model.id == targetMemory.id) continue;
      if (seenIds.contains(model.id)) continue;
      seenIds.add(model.id);
      
      double score = 0.0;
      List<String> rawReasons = [];
      
      // 1. Same Category (+20)
      if (model.type == targetMemory.type) {
        score += 20.0;
        rawReasons.add("Same type: ${model.type}");
      }

      // Parse person name of candidate memory
      final modelParsed = SmartParserImpl().parse(model.content);
      final modelPerson = modelParsed.personName;

      // 2. Same Tags (+15 per tag)
      final modelTags = model.tags.map((t) => t.toLowerCase()).toSet();
      final commonTags = targetTags.intersection(modelTags);
      if (commonTags.isNotEmpty) {
        score += (commonTags.length * 15.0);
        for (final tag in commonTags) {
          final originalTag = model.tags.firstWhere(
            (t) => t.toLowerCase() == tag,
            orElse: () => tag,
          );
          
          if (_categories.contains(originalTag.toLowerCase())) {
            rawReasons.add("Same type: $originalTag");
          } else if (_isPersonName(originalTag, targetPerson, modelPerson)) {
            rawReasons.add("Same person: $originalTag");
          } else {
            rawReasons.add("Same tag: $originalTag");
          }
        }
      }

      // 3. Created within 3 days (+15)
      final daysDiff = targetMemory.createdAt.difference(model.createdAt).inDays.abs();
      if (daysDiff <= 3) {
        score += 15.0;
        final text = daysDiff == 0 ? "Same day" : "$daysDiff day${daysDiff == 1 ? '' : 's'} apart";
        rawReasons.add("Created nearby: $text");
      }

      // 4. Same Reminder Day (+10)
      if (targetMemory.reminderAt != null && model.reminderAt != null) {
        if (targetMemory.reminderAt!.year == model.reminderAt!.year &&
            targetMemory.reminderAt!.month == model.reminderAt!.month &&
            targetMemory.reminderAt!.day == model.reminderAt!.day) {
          score += 10.0;
          rawReasons.add("Same reminder day");
        }
      }

      // 5. Shared Title Keywords (+10 per word)
      final modelTitleWords = _extractKeywords(model.title);
      final commonTitleWords = targetTitleWords.intersection(modelTitleWords);
      if (commonTitleWords.isNotEmpty) {
        score += (commonTitleWords.length * 10.0);
      }

      // 6. Shared Content Keywords (+5 per word)
      final modelContentWords = _extractKeywords(model.content);
      final commonContentWords = targetContentWords.intersection(modelContentWords);
      if (commonContentWords.isNotEmpty) {
        score += (commonContentWords.length * 5.0);
      }

      // Add common keyword reason if any keyword overlaps in title or content
      final allCommonWords = commonTitleWords.union(commonContentWords);
      if (allCommonWords.isNotEmpty) {
        rawReasons.add("Common keyword: ${allCommonWords.first}");
      }

      // Convert score to percentage
      int finalPercentage = score.round();
      if (finalPercentage > 100) finalPercentage = 100;

      // Only include memories that have some similarity (e.g., >= 15%)
      if (finalPercentage >= 15) {
        // Deduplicate connection reasons cleanly
        final reasons = rawReasons.toSet().toList();
        
        relatedMemories.add(
          RelatedMemory(
            memory: _mapModelToEntity(model),
            similarityPercentage: finalPercentage,
            reasons: reasons,
          ),
        );
      }
    }

    // Sort by descending similarity score
    relatedMemories.sort((a, b) => b.similarityPercentage.compareTo(a.similarityPercentage));

    // Return top 5
    return relatedMemories.take(5).toList();
  }

  bool _isPersonName(String tag, String? targetPerson, String? modelPerson) {
    final lowerTag = tag.toLowerCase().trim();
    if (_categories.contains(lowerTag)) return false;
    if (targetPerson != null && lowerTag == targetPerson.toLowerCase().trim()) return true;
    if (modelPerson != null && lowerTag == modelPerson.toLowerCase().trim()) return true;
    if (lowerTag.startsWith('dr')) return true;
    if (RegExp(r'^[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+$').hasMatch(tag)) return true;
    return false;
  }

  Set<String> _extractKeywords(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty && !_stopWords.contains(w) && w.length > 2).toSet();
  }

  Memory _mapModelToEntity(MemoryModel model) {
    return Memory(
      id: model.id,
      title: model.title,
      content: model.content,
      type: model.type,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      tags: model.tags.toList(),
      isPinned: model.isPinned,
      reminderAt: model.reminderAt,
    );
  }
}
