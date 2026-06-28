class SynonymDictionary {
  static const Map<String, List<String>> _synonymGroups = {
    'doctor': ['hospital', 'clinic', 'appointment', 'medicine', 'health', 'dr', 'doc', 'physician', 'dentist', 'checkup', 'treatment', 'medical'],
    'health': ['fitness', 'wellness', 'medical', 'gym', 'workout', 'exercise', 'doctor', 'treatment', 'checkup'],
    'work': ['office', 'job', 'meeting', 'project', 'meeting notes', 'task', 'todo', 'career', 'presentation', 'interview'],
    'finance': ['money', 'bank', 'bill', 'payment', 'expenses', 'spend', 'salary', 'invoice', 'credit', 'tax', 'rent'],
    'learning': ['learn', 'study', 'flutter', 'dart', 'course', 'read', 'book', 'programming', 'tutorial', 'bloc', 'class'],
    'ideas': ['idea', 'thought', 'inspiration', 'brainstorm', 'concept', 'draft'],
    'shopping': ['buy', 'store', 'groceries', 'list', 'shopping list', 'purchase', 'order', 'supermarket', 'shop'],
    'family': ['mom', 'dad', 'parent', 'sister', 'brother', 'wife', 'husband', 'son', 'daughter', 'kids', 'relative'],
  };

  /// Returns synonyms for a clean query word.
  static Set<String> getSynonyms(String word) {
    final w = word.toLowerCase().trim();
    if (w.isEmpty) return const {};
    final result = <String>{};
    for (final entry in _synonymGroups.entries) {
      final key = entry.key;
      final values = entry.value;
      if (key == w || values.contains(w)) {
        result.add(key);
        result.addAll(values);
      }
    }
    result.remove(w);
    return result;
  }
}
