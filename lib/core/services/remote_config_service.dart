import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service managing Firebase Remote Config parameters.
/// Allows toggling and adjusting app features dynamically from the Firebase Console.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: kDebugMode 
            ? Duration.zero // Fetch instantly in debug mode for rapid testing
            : const Duration(hours: 4), // 4 hours in production
      ));

      // Define default local fallback configurations
      await _remoteConfig.setDefaults(const {
        'enable_ai_suggestions': true,
        'enable_voice_input': false,
        'ad_interval_reminders': 5,
        'support_email': 'caxu2003@gmail.com',
      });

      // Fetch latest values and apply them immediately
      final activated = await _remoteConfig.fetchAndActivate();
      debugPrint('Firebase Remote Config initialized. Activated new configs: $activated');
    } catch (e) {
      debugPrint('Error initializing Firebase Remote Config: $e');
    }
  }

  /// Getters for remote variables with robust type checking
  bool get enableAISuggestions => _remoteConfig.getBool('enable_ai_suggestions');
  bool get enableVoiceInput => _remoteConfig.getBool('enable_voice_input');
  int get adIntervalReminders => _remoteConfig.getInt('ad_interval_reminders');
  String get supportEmail => _remoteConfig.getString('support_email');
}

/// Riverpod provider for accessing RemoteConfigService globally
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});
