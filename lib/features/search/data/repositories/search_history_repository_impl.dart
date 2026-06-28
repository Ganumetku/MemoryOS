import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/search_history_repository.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  final SharedPreferences _prefs;
  static const _historyKey = 'search_history_list';

  SearchHistoryRepositoryImpl(this._prefs);

  @override
  Future<List<String>> getRecentSearches() async {
    return _prefs.getStringList(_historyKey) ?? [];
  }

  @override
  Future<void> saveSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final current = _prefs.getStringList(_historyKey) ?? [];
    // Remove if already exists (case-insensitive check)
    current.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    
    // Insert at front
    current.insert(0, clean);

    // Keep only last 10
    final limited = current.take(10).toList();
    await _prefs.setStringList(_historyKey, limited);
  }

  @override
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
