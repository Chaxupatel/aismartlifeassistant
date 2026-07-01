import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/services/app_open_ad_manager.dart';
import '../../../main.dart';

/// An upgraded, premium splash screen displaying application branding.
/// Animates logo entry (bounce-scale and fade-in), runs a loop specular reflection shine
/// sweep, fades in text elements sequentially, and fades out before entering onboarding.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shineController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _taglineFade;
  late Animation<double> _shineOffset;
  
  double _exitOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    // Controller for entrance animations
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Controller for continuous specular shine loop
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Staggered curves
    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );

    _taglineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    // Specular shine offset timeline animation
    _shineOffset = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );

    // Kick off entrance
    _entranceController.forward();

    // Load App Open Ad and execute splash sequence
    _exitSplashSequence();
  }

  Future<void> _exitSplashSequence() async {
    final startTime = DateTime.now();

    // 1. Wait for background initialization tasks in main.dart to complete
    try {
      await appInitializationCompleter.future;
    } catch (e) {
      debugPrint('Initialization error awaited during splash: $e');
    }

    // 2. Start preloading the App Open Ad immediately
    AppOpenAdManager.instance.loadAd();

    // 3. Ensure the premium logo and shine entrance animations play for at least 2600ms
    final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
    final remainingTime = 2600 - elapsedTime;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }
    if (!mounted) return;

    // 4. Check if the App Open ad has already finished loading
    if (AppOpenAdManager.instance.isAdAvailable) {
      AppOpenAdManager.instance.showAdIfAvailable(
        onAdDismissed: () {
          _proceedToNextScreen();
        },
      );
    } else {
      // 5. Ad is not loaded yet. Wait a bit longer (up to an additional 2000ms)
      // to give it a chance to load. We check every 200ms.
      int elapsed = 0;
      const checkInterval = 200;
      const maxWait = 2000;
      bool adLoaded = false;

      while (elapsed < maxWait && !adLoaded && mounted) {
        await Future.delayed(const Duration(milliseconds: checkInterval));
        elapsed += checkInterval;
        if (AppOpenAdManager.instance.isAdAvailable) {
          adLoaded = true;
          break;
        }
      }

      if (adLoaded && mounted) {
        AppOpenAdManager.instance.showAdIfAvailable(
          onAdDismissed: () {
            _proceedToNextScreen();
          },
        );
      } else {
        // Timeout reached or widget unmounted, proceed directly
        _proceedToNextScreen();
      }
    }
  }

  Future<void> _proceedToNextScreen() async {
    if (!mounted) return;
    setState(() => _exitOpacity = 0.0);
    
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // authStateChanges always emits immediately with the current user
    // (null if not signed in, or the restored User if a session exists).
    final user = await ref
        .read(authRepositoryProvider)
        .authStateChanges
        .first;
    if (!mounted) return;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trigger preloading of the global adaptive banner ad early so it is fully loaded
    // and ready to display immediately when the user reaches the Home screen dashboard.
    ref.read(globalAdProvider.notifier).preloadAd(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: _exitOpacity,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: GradientBackground(
        useSafeArea: false,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Elastic scale logo container
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(_logoScale),
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(isDark ? 0.35 : 0.2),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Container(
                          width: 140,
                          height: 140,
                          color: isDark ? Colors.black26 : Colors.white10,
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Animate shine sweep line via ShaderMask
                              AnimatedBuilder(
                                animation: _shineOffset,
                                builder: (context, child) {
                                  return Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: ShaderMask(
                                        blendMode: BlendMode.srcATop,
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: const [
                                              Colors.transparent,
                                              Color(0x3BFFFFFF),
                                              Colors.transparent,
                                            ],
                                            stops: [
                                              (_shineOffset.value - 0.25).clamp(0.0, 1.0),
                                              _shineOffset.value.clamp(0.0, 1.0),
                                              (_shineOffset.value + 0.25).clamp(0.0, 1.0),
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                  
                  // App Name branding text
                  FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // App Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Remember Everything. Live Better.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineFade,
                child: Center(
                  child: Text(
                    'Version ${AppStrings.appVersion}',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                          : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
