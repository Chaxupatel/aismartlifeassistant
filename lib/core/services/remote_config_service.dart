import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_ad_config.dart';

/// Service managing Firebase Remote Config parameters.
/// Allows toggling and adjusting app features dynamically from the Firebase Console.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: kDebugMode
              ? Duration
                    .zero // Fetch instantly in debug mode for rapid testing
              : const Duration(hours: 4), // 4 hours in production
        ),
      );

      final String defaultAppOpenId = Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395921'
          : 'ca-app-pub-3940256099942544/5575463023';

      final String defaultBannerId = Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-3940256099942544/2435281174';

      final String defaultNativeId = 'ca-app-pub-3940256099942544/2247696110';

      final String defaultInterstitialId = Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';

      // Define default local fallback configurations
      await _remoteConfig.setDefaults({
        'ads_enabled': false,
        'enable_ai_suggestions': true,
        'enable_voice_input': false,
        'ad_interval_reminders': 5,
        'support_email': 'caxu2003@gmail.com',
        'app_open_ad_cooldown_seconds': 120,
        'ad_unit_app_open': defaultAppOpenId,
        'ad_unit_banner': defaultBannerId,
        'ad_unit_native': defaultNativeId,
        'ad_unit_interstitial': defaultInterstitialId,
        'interstitial_ad_interval': 4,
      });

      // Fetch latest values and apply them immediately
      final activated = await _remoteConfig.fetchAndActivate();
      adsEnabled = _remoteConfig.getBool('ads_enabled');
      final fetchedInterval = _remoteConfig.getInt('interstitial_ad_interval');
      debugPrint(
        'Firebase Remote Config initialized. Activated new configs: $activated, ads_enabled: $adsEnabled, interstitial_ad_interval: $fetchedInterval',
      );
    } catch (e) {
      debugPrint('Error initializing Firebase Remote Config: $e');
    }
  }

  /// Getters for remote variables with robust type checking
  bool get enableAISuggestions =>
      _remoteConfig.getBool('enable_ai_suggestions');
  bool get enableVoiceInput => _remoteConfig.getBool('enable_voice_input');
  int get adIntervalReminders => _remoteConfig.getInt('ad_interval_reminders');
  String get supportEmail => _remoteConfig.getString('support_email');
  int get appOpenAdCooldownSeconds =>
      _remoteConfig.getInt('app_open_ad_cooldown_seconds');
  String get adUnitAppOpen => _remoteConfig.getString('ad_unit_app_open');
  String get adUnitBanner => _remoteConfig.getString('ad_unit_banner');
  String get adUnitNative => _remoteConfig.getString('ad_unit_native');
  String get adUnitInterstitial =>
      _remoteConfig.getString('ad_unit_interstitial');
  int get interstitialAdInterval =>
      _remoteConfig.getInt('interstitial_ad_interval');
  bool get adsEnabledValue => _remoteConfig.getBool('ads_enabled');
}

/// Riverpod provider for accessing RemoteConfigService globally
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});
