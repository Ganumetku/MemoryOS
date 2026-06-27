import '../entities/life_area.dart';

class LifeAreaParser {
  /// Auto-detect Life Area from memory content using keyword matching.
  String detectLifeArea(String content) {
    final textLower = content.toLowerCase();

    bool matchAny(List<String> keywords) {
      final pattern = r'\b(' + keywords.map((k) => RegExp.escape(k)).join('|') + r')\b';
      return RegExp(pattern, caseSensitive: false).hasMatch(textLower);
    }

    if (matchAny(['doctor', 'dentist', 'medical', 'clinical', 'checkup', 'medicine', 'health', 'hospital', 'clinic'])) {
      return LifeArea.health.name;
    }

    if (matchAny(['gym', 'workout', 'run', 'exercise', 'cardio', 'lift', 'fit', 'sports', 'fitness', 'yoga', 'jog', 'running', 'jogging'])) {
      return LifeArea.fitness.name;
    }

    if (matchAny(['pitch', 'venture', 'startup', 'funding', 'cofounder', 'equity', 'launch', 'product', 'saas', 'demo day', 'pitching'])) {
      return LifeArea.startup.name;
    }

    if (matchAny(['meeting', 'appointment', 'office', 'boss', 'client', 'project', 'deadline', 'presentation', 'work', 'job', 'salary', 'colleague', 'meetings', 'flutter', 'architecture', 'idea'])) {
      return LifeArea.work.name;
    }

    if (matchAny(['pay', 'bill', 'rent', 'finance', 'bank', 'invoice', 'tax', 'credit', 'cash', 'expense', 'money', 'bills', 'taxes', 'expenses'])) {
      return LifeArea.finance.name;
    }

    if (matchAny(['flight', 'trip', 'hotel', 'travel', 'vacation', 'airport', 'booking', 'ticket', 'flights', 'trips', 'hotels', 'tickets'])) {
      return LifeArea.travel.name;
    }

    if (matchAny(['buy', 'store', 'shopping', 'milk', 'grocery', 'groceries', 'market', 'purchase', 'price'])) {
      return LifeArea.shopping.name;
    }

    if (matchAny(['wife', 'husband', 'kid', 'kids', 'son', 'daughter', 'family', 'dad', 'mom', 'sister', 'brother', 'parents', 'parent', 'cousin', 'sons', 'daughters'])) {
      return LifeArea.family.name;
    }

    if (matchAny(['book', 'course', 'study', 'learn', 'coding', 'tutorial', 'read', 'research', 'class', 'school', 'university', 'lecture', 'learning', 'books', 'courses', 'classes'])) {
      return LifeArea.learning.name;
    }

    if (matchAny(['party', 'event', 'birthday', 'anniversary', 'wedding', 'concert', 'festival', 'celebration'])) {
      return LifeArea.events.name;
    }

    if (matchAny(['personal', 'home', 'diary', 'journal'])) {
      return LifeArea.personal.name;
    }

    return LifeArea.other.name;
  }
}
