import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'glass_container.dart';
import '../constants/app_colors.dart';

/// A premium, glassmorphic Native Ad widget that uses AdMob Native Templates.
/// Auto-styles elements to integrate seamlessly with the app's dark/light glass aesthetic.
class GlassNativeAdWidget extends StatefulWidget {
  final TemplateType templateType;
  final double height;

  const GlassNativeAdWidget({
    super.key,
    required this.templateType,
    required this.height,
  });

  /// Factory for a small inline native ad (best for list views)
  factory GlassNativeAdWidget.small() {
    return const GlassNativeAdWidget(
      templateType: TemplateType.small,
      height: 90,
    );
  }

  /// Factory for a medium inline native ad (best for home/dashboard layouts)
  factory GlassNativeAdWidget.medium() {
    return const GlassNativeAdWidget(
      templateType: TemplateType.medium,
      height: 320,
    );
  }

  @override
  State<GlassNativeAdWidget> createState() => _GlassNativeAdWidgetState();
}

class _GlassNativeAdWidgetState extends State<GlassNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    String adUnitId = 'ca-app-pub-3940256099942544/2247696110';
    try {
      final String remoteId = FirebaseRemoteConfig.instance.getString('ad_unit_native');
      if (remoteId.isNotEmpty) {
        adUnitId = remoteId;
      }
    } catch (e) {
      debugPrint('Error loading ad_unit_native from Remote Config: $e');
    }

    
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('GlassNativeAdWidget failed to load: $error');
          if (mounted) {
            setState(() {
              _isAdFailed = true;
            });
          }
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: Colors.transparent, // Let our GlassContainer draw the background
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.primary,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12.0,
        ),
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ad failed, collapse space
    if (_isAdFailed) {
      return const SizedBox.shrink();
    }

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        borderRadius: 16,
        padding: EdgeInsets.zero, // Let AdMob template draw its interior layout
        blur: 15,
        opacity: isDarkTheme ? 0.06 : 0.1,
        color: isDarkTheme ? Colors.black : Colors.white,
        borderColor: isDarkTheme ? Colors.white10 : Colors.black12,
        child: SizedBox(
          height: widget.height,
          child: _isAdLoaded && _nativeAd != null
              ? AdWidget(ad: _nativeAd!)
              : Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ads_click_rounded,
                        size: 16,
                        color: isDarkTheme ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading Sponsored Ad...',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
