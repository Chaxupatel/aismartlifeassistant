import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/remote_config_service.dart';
import '../../core/constants/app_ad_config.dart'; // Import adsEnabled flag

// Google's official Test Ad Unit IDs for Adaptive Banners with Remote Config integration
String get _globalAdUnitId {
  if (kIsWeb) return '';
  try {
    final String id = RemoteConfigService.instance.adUnitBanner;
    if (id.isNotEmpty) return id;
  } catch (e) {
    debugPrint('Error loading ad_unit_banner from Remote Config: $e');
  }
  return Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';
}

/// State class for globally managed ad preloading.
class GlobalAdState {
  final BannerAd? bannerAd;
  final bool isLoaded;
  final bool isFailed;
  final AdSize? adSize;

  GlobalAdState({
    this.bannerAd,
    this.isLoaded = false,
    this.isFailed = false,
    this.adSize,
  });

  GlobalAdState copyWith({
    BannerAd? bannerAd,
    bool? isLoaded,
    bool? isFailed,
    AdSize? adSize,
  }) {
    return GlobalAdState(
      bannerAd: bannerAd ?? this.bannerAd,
      isLoaded: isLoaded ?? this.isLoaded,
      isFailed: isFailed ?? this.isFailed,
      adSize: adSize ?? this.adSize,
    );
  }
}

/// Notifier that manages the lifecycle of the preloaded global ad.
class GlobalAdNotifier extends Notifier<GlobalAdState> {
  @override
  GlobalAdState build() => GlobalAdState();

  bool _isPreloading = false;

  Future<void> preloadAd(BuildContext context, {bool force = false}) async {
    if (kIsWeb) return;

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width.truncate();
    final orientation = mediaQuery.orientation;

    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
    if (size == null) {
      return;
    }

    // Prevent duplicate preload requests if already loading/loaded with same size
    if (!force && (_isPreloading || (state.isLoaded && state.adSize == size))) {
      return;
    }

    _isPreloading = true;

    // Dispose previous ad instance before loading a new one
    state.bannerAd?.dispose();
    state = GlobalAdState(adSize: size, isFailed: false);

    final bannerAd = BannerAd(
      adUnitId: _globalAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          state = state.copyWith(
            bannerAd: ad as BannerAd,
            isLoaded: true,
            isFailed: false,
          );
          _isPreloading = false;
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Preloaded Ad failed to load: $err');
          ad.dispose();
          state = state.copyWith(
            bannerAd: null,
            isLoaded: false,
            isFailed: true,
            adSize: null,
          );
          _isPreloading = false;
        },
      ),
    );

    bannerAd.load();
  }
}

/// Global provider to access and load the AdMob banner ad.
final globalAdProvider = NotifierProvider<GlobalAdNotifier, GlobalAdState>(GlobalAdNotifier.new);

/// A reusable widget that loads and renders an Anchored Adaptive AdMob banner ad.
/// Reads from [globalAdProvider] to support preloaded ads with zero transition delay.
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  Orientation? _currentOrientation;
  double? _currentWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) {
      final mediaQuery = MediaQuery.of(context);
      if (mediaQuery.orientation != _currentOrientation || mediaQuery.size.width != _currentWidth) {
        _currentOrientation = mediaQuery.orientation;
        _currentWidth = mediaQuery.size.width;
        
        // Re-preload the ad if orientation or screen width changes (force update size)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(globalAdProvider.notifier).preloadAd(context, force: true);
          }
        });
      }
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: const Center(
        child: _AdShimmerLoader(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final adState = ref.watch(globalAdProvider);

    // If ad loading failed or size hasn't been computed, collapse space
    if (adState.isFailed || adState.adSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: adState.adSize!.width.toDouble(),
      height: adState.adSize!.height.toDouble(),
      child: adState.isLoaded && adState.bannerAd != null
          ? AdWidget(ad: adState.bannerAd!)
          : _buildPlaceholder(context), // Pre-reserved space with shimmer loading UI
    );
  }
}

class _AdShimmerLoader extends StatefulWidget {
  const _AdShimmerLoader();

  @override
  State<_AdShimmerLoader> createState() => _AdShimmerLoaderState();
}

class _AdShimmerLoaderState extends State<_AdShimmerLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white38 : Colors.black38;

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.ads_click_rounded,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Sponsored',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
