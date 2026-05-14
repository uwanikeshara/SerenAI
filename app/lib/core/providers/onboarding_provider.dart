import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  return OnboardingService.hasSeenOnboarding();
});

final permissionsStatusProvider = FutureProvider<bool>((ref) async {
  return OnboardingService.hasSeenPermissions();
});

class OnboardingService {
  static const _key = 'serenai_onboarded';
  static const _permsKey = 'has_seen_permissions';
  static const _pointsKey = 'has_seen_points_tip';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<bool> hasSeenPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permsKey) ?? false;
  }

  static Future<bool> hasSeenPointsTip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pointsKey) ?? false;
  }

  static Future<void> markPointsTipSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pointsKey, true);
  }
}

final pointsTipStatusProvider = FutureProvider<bool>((ref) async {
  return OnboardingService.hasSeenPointsTip();
});

