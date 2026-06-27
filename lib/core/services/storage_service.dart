import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  bool getHasCompletedOnboarding();
  Future<void> setHasCompletedOnboarding(bool completed);
}

class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;

  StorageServiceImpl(this._prefs);

  static const _onboardingKey = 'hasCompletedOnboarding';

  @override
  bool getHasCompletedOnboarding() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<void> setHasCompletedOnboarding(bool completed) async {
    await _prefs.setBool(_onboardingKey, completed);
  }
}
