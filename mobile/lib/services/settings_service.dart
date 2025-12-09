import 'package:shared_preferences/shared_preferences.dart';

enum RecommendationMode { nearby, interest, balanced }

class SettingsService {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  static const _recModeKey = 'rec_mode';

  Future<RecommendationMode> getRecommendationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_recModeKey) ?? 'balanced';
    switch (v) {
      case 'nearby':
        return RecommendationMode.nearby;
      case 'interest':
        return RecommendationMode.interest;
      default:
        return RecommendationMode.balanced;
    }
  }

  Future<void> setRecommendationMode(RecommendationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = mode == RecommendationMode.nearby
        ? 'nearby'
        : (mode == RecommendationMode.interest ? 'interest' : 'balanced');
    await prefs.setString(_recModeKey, key);
  }
}
