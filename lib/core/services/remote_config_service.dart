import 'dart:convert';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_ad_config.dart';

/// Service managing Firebase Remote Config parameters.
/// Allows toggling and adjusting app features dynamically from the Firebase Console.
class RemoteConfigService {
  // Static singleton instance for direct access outside Riverpod contexts (e.g. ad managers)
  static final RemoteConfigService instance = RemoteConfigService();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  Map<String, dynamic> _parsedConfig = {};

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: kDebugMode
              ? Duration.zero // Fetch instantly in debug mode for rapid testing
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

            // Define default local fallback configurations inside unified app_config JSON parameter
      final String defaultAppConfigJson = json.encode({
        "ShowAds": true, // Default to true so test ads show immediately during testing
        "AppOpenAdId": defaultAppOpenId,
        "BannerAdId": defaultBannerId,
        "InterstitialAdId": defaultInterstitialId,
        "NativeAdId": defaultNativeId,
        "LatestAppVersion": "1.0.0",
        "app_open_ad_cooldown_seconds": 120,
        "interstitial_ad_interval": 3,
        "is_force_update": false
      });

      await _remoteConfig.setDefaults({
        'config': defaultAppConfigJson,
        'enable_ai_suggestions': true,
        'enable_voice_input': false,
        'support_email': 'caxu2003@gmail.com',
      });

      // Fetch latest values and apply them immediately
      final activated = await _remoteConfig.fetchAndActivate();
      _parseConfig();
      
      // Keep global adsEnabled flag in sync
      adsEnabled = showAds;
      
      debugPrint(
        'Firebase Remote Config initialized. Activated new configs: $activated, ShowAds: $showAds, interstitial_ad_interval: $interstitialAdInterval',
      );
    } catch (e) {
      debugPrint('Error initializing Firebase Remote Config: $e');
      // Always parse defaults if fetch fails
      _parseConfig();
    }
  }

  void _parseConfig() {
    try {
      final jsonStr = _remoteConfig.getString('config');
      debugPrint('RemoteConfigService: Fetched config JSON string = $jsonStr');
      if (jsonStr.isNotEmpty) {
        _parsedConfig = json.decode(jsonStr) as Map<String, dynamic>;
        debugPrint('RemoteConfigService: Successfully parsed config JSON = $_parsedConfig');
      } else {
        debugPrint('RemoteConfigService: config JSON is empty.');
      }
    } catch (e) {
      debugPrint('RemoteConfigService: Error parsing config JSON: $e');
    }
  }

  // Unified getters with safe fallback defaults
  bool get showAds => _parsedConfig['ShowAds'] as bool? ?? false;
  String get adUnitAppOpen => _parsedConfig['AppOpenAdId'] as String? ?? '';
  String get adUnitBanner => _parsedConfig['BannerAdId'] as String? ?? '';
  String get adUnitInterstitial => _parsedConfig['InterstitialAdId'] as String? ?? '';
  String get adUnitNative => _parsedConfig['NativeAdId'] as String? ?? '';
  String get latestAppVersion => _parsedConfig['LatestAppVersion'] as String? ?? '1.0.0';
  int get appOpenAdCooldownSeconds => _parsedConfig['app_open_ad_cooldown_seconds'] as int? ?? 120;
  int get interstitialAdInterval => _parsedConfig['interstitial_ad_interval'] as int? ?? 3;
  bool get isForceUpdate => _parsedConfig['is_force_update'] as bool? ?? false;

  // Individual parameters outside the json config block
  bool get enableAISuggestions => _remoteConfig.getBool('enable_ai_suggestions');
  bool get enableVoiceInput => _remoteConfig.getBool('enable_voice_input');
  String get supportEmail => _remoteConfig.getString('support_email');
}

/// Riverpod provider for accessing RemoteConfigService globally
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService.instance;
});
