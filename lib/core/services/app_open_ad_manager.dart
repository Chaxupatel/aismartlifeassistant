import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Class managing the App Open Ad lifecycle and displaying it on app foregrounding.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  // Test App Open Ad Unit IDs
  final String _adUnitId = kIsWeb
      ? ''
      : Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395921' // Android App Open Test ID
          : 'ca-app-pub-3940256099942544/5575463023'; // iOS App Open Test ID

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _loadTime;
  bool _isLoading = false;

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
