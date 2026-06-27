import '../entities/life_area.dart';
import '../parser/life_area_parser.dart';
import 'life_area_analytics_service.dart';

/// Central service for Life Areas, delegating to parser and analytics services.
class LifeAreaService {
  final LifeAreaParser _parser;
  final LifeAreaAnalyticsService _analyticsService;

  LifeAreaService(this._parser, this._analyticsService);

  /// Returns the names of all supported Life Areas.
  List<String> get areas => LifeArea.values.map((a) => a.name).toList();

  /// Returns all LifeArea entity objects.
  List<LifeArea> get allAreas => LifeArea.values;

  /// Auto-detect Life Area from memory content.
  String detectLifeArea(String content) {
    return _parser.detectLifeArea(content);
  }

  /// Delegates to analytics service
  Future<Map<String, double>> getLifeBalance() {
    return _analyticsService.getLifeBalance();
  }

  /// Delegates to analytics service
  Future<Map<String, String>> getLifeAreaInsights() {
    return _analyticsService.getLifeAreaInsights();
  }
}
