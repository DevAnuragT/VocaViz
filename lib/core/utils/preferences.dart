import 'package:shared_preferences/shared_preferences.dart';

/// App preferences using SharedPreferences.
class AppPreferences {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _historyEnabledKey = 'history_enabled';

  /// Check if user has completed onboarding.
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Mark onboarding as completed.
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Check if history is enabled.
  static Future<bool> isHistoryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_historyEnabledKey) ?? true;
  }

  /// Set history enabled/disabled.
  static Future<void> setHistoryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_historyEnabledKey, enabled);
  }

  /// Clear all preferences (for testing).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
