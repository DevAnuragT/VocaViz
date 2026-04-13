import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocaviz/core/utils/preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('onboarding preference defaults to false', () async {
    final completed = await AppPreferences.hasCompletedOnboarding();
    expect(completed, isFalse);
  });

  test('setOnboardingCompleted persists true', () async {
    await AppPreferences.setOnboardingCompleted();
    final completed = await AppPreferences.hasCompletedOnboarding();
    expect(completed, isTrue);
  });

  test('clearAll resets onboarding preference', () async {
    await AppPreferences.setOnboardingCompleted();
    await AppPreferences.clearAll();

    final completed = await AppPreferences.hasCompletedOnboarding();
    expect(completed, isFalse);
  });
}
