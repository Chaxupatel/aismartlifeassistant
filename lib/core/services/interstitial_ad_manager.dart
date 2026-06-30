import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Class managing the Interstitial Ad lifecycle and displaying it after reminder creation thresholds.
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _reminderCount = 0;

  /// Fetch the Interstitial Ad Unit ID dynamically from Remote Config with fallback
  String get _adUnitId {
    if (kIsWeb) return '';
    try {
      final String id = FirebaseRemoteConfig.instance.getString('ad_unit_interstitial');
      if (id.isNotEmpty) return id;
    } catch (e) {
      debugPrint('Error loading ad_unit_interstitial from Remote Config: $e');
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712' // Test Android Interstitial ID
        : 'ca-app-pub-3940256099942544/4411468910'; // Test iOS Interstitial ID
  }

  /// Get creation interval threshold from Remote Config (defaults to 5)
  int get _adInterval {
    try {
      final val = FirebaseRemoteConfig.instance.getInt('interstitial_ad_interval');
      return val > 0 ? val : 5;
    } catch (e) {
      debugPrint('Error loading interstitial_ad_interval from Remote Config: $e');
      return 5;
    }
  }

  /// Preload the Interstitial Ad
  void loadAd() {
    if (kIsWeb) return;
    if (_isLoading || _interstitialAd != null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          debugPrint('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Increment count and show ad if interval threshold is reached
  void checkAndShowAd(BuildContext context, {required VoidCallback onComplete}) {
    _reminderCount++;
    final interval = _adInterval;
    debugPrint('Reminder creation count: $_reminderCount / $interval');

    if (_reminderCount >= interval) {
      _reminderCount = 0; // reset count
      
      if (_interstitialAd == null) {
        debugPrint('InterstitialAd is null, preloading and continuing execution.');
        loadAd();
        onComplete();
        return;
      }

      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('InterstitialAd showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('InterstitialAd dismissed.');
          ad.dispose();
          _interstitialAd = null;
          loadAd(); // preload next
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('InterstitialAd failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          loadAd(); // try loading again
          onComplete();
        },
      );

      _interstitialAd!.show();
    } else {
      // Just run callback directly if not enough reminders created yet
      onComplete();
    }
  }
}
