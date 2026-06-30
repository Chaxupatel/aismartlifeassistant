import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Class managing the App Open Ad lifecycle and displaying it on app foregrounding.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  /// Fetch the App Open Ad Unit ID dynamically from Remote Config with fallback
  String get _adUnitId {
    if (kIsWeb) return '';
    try {
      final String id = FirebaseRemoteConfig.instance.getString('ad_unit_app_open');
      if (id.isNotEmpty) return id;
    } catch (e) {
      debugPrint('Error loading ad_unit_app_open from Remote Config: $e');
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/9257395921'
        : 'ca-app-pub-3940256099942544/5575463023';
  }

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _loadTime;
  bool _isLoading = false;
  DateTime? _lastAdShowTime;

  /// Fetch cooldown duration from Remote Config with local fallback
  int get _cooldownSeconds {
    try {
      return FirebaseRemoteConfig.instance.getInt('app_open_ad_cooldown_seconds');
    } catch (e) {
      debugPrint('Error reading open ad cooldown from Remote Config: $e');
      return 120; // fallback to 120 seconds
    }
  }

  /// Check if the cooldown interval is still active
  bool get _isCooldownActive {
    if (_lastAdShowTime == null) return false;
    final elapsedSeconds = DateTime.now().difference(_lastAdShowTime!).inSeconds;
    final cooldown = _cooldownSeconds;
    debugPrint('AppOpenAd Cooldown: $elapsedSeconds seconds elapsed out of $cooldown.');
    return elapsedSeconds < cooldown;
  }

  /// Check if the loaded ad has expired (AdMob App Open ads expire after 4 hours).
  bool get _isAdExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!).inHours >= 4;
  }

  /// Check if an ad is currently loaded and valid.
  bool get isAdAvailable {
    return _appOpenAd != null && !_isAdExpired;
  }

  /// Load the App Open Ad.
  Future<void> loadAd({VoidCallback? onAdLoaded, VoidCallback? onAdFailed}) async {
    if (kIsWeb) return;
    if (_isLoading || isAdAvailable) {
      if (isAdAvailable) onAdLoaded?.call();
      return;
    }

    _isLoading = true;
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _loadTime = DateTime.now();
          _isLoading = false;
          debugPrint('AppOpenAd loaded successfully.');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _appOpenAd = null;
          _loadTime = null;
          debugPrint('AppOpenAd failed to load: $error');
          onAdFailed?.call();
        },
      ),
    );
  }

  /// Show the ad if it is loaded and not already showing.
  void showAdIfAvailable({VoidCallback? onAdDismissed}) {
    if (kIsWeb) {
      onAdDismissed?.call();
      return;
    }

    if (_isCooldownActive) {
      debugPrint('AppOpenAd skipped due to active cooldown timer.');
      onAdDismissed?.call();
      return;
    }

    if (!isAdAvailable) {
      debugPrint('Tried to show AppOpenAd but it is not available.');
      loadAd();
      onAdDismissed?.call();
      return;
    }

    if (_isShowingAd) {
      debugPrint('Tried to show AppOpenAd but it is already showing.');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        _lastAdShowTime = DateTime.now(); // Reset cooldown timer on successful show
        debugPrint('AppOpenAd showed full screen content.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
        onAdDismissed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd dismissed.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Preload next ad
        onAdDismissed?.call();
      },
    );

    _appOpenAd!.show();
  }

  /// Initialize the app lifecycle listener to show ads on resume.
  void initializeLifecycleListener() {
    if (kIsWeb) return;
    // Start listening to app state transitions from google_mobile_ads
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground) {
        debugPrint('App returned to foreground. Attempting to show AppOpenAd.');
        showAdIfAvailable();
      }
    });
  }
}
