import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A reusable widget that loads and renders an Anchored Adaptive AdMob banner ad.
/// Automatically calculates screen dimensions and handles lifecycle events.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  AdSize? _adSize;
  Orientation? _currentOrientation;
  double? _currentWidth;

  // Google's official Test Ad Unit IDs for Adaptive Banners
  final String _adUnitId = kIsWeb
      ? ''
      : Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741' // Android Adaptive Test Banner ID
          : 'ca-app-pub-3940256099942544/2435281174'; // iOS Adaptive Test Banner ID

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) {
      final mediaQuery = MediaQuery.of(context);
      if (mediaQuery.orientation != _currentOrientation || mediaQuery.size.width != _currentWidth) {
        _currentOrientation = mediaQuery.orientation;
        _currentWidth = mediaQuery.size.width;
        _calculateAdSize();
      }
    }
  }

  Future<void> _calculateAdSize() async {
    final width = _currentWidth!.truncate();
    final orientation = _currentOrientation!;

    // Get the anchored adaptive ad size
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
    if (size != null && mounted) {
      setState(() {
        _adSize = size;
      });
      _loadAd();
    }
  }

  void _loadAd() {
    if (_adSize == null) return;

    // Clean up any existing ad before loading a new one
    _bannerAd?.dispose();
    _isAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: _adSize!,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('AdBannerWidget failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isAdLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _adSize!.width.toDouble(),
      height: _adSize!.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
