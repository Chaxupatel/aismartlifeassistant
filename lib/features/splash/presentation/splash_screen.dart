import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';

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

    // Wait for Firebase Auth to restore the persisted session, then navigate.
    // We wait at least 2.6 s for the entrance animation to complete, but also
    // wait for the first authStateChanges emission so we never read a stale
    // null before Firebase has finished restoring the cached credential.
    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _exitOpacity = 0.0);
      Timer(const Duration(milliseconds: 350), () async {
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
      });
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: _exitOpacity,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: GradientBackground(
        useSafeArea: false,
        child: Center(
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
                    child: GlassContainer(
                      width: 140,
                      height: 140,
                      borderRadius: 36,
                      blur: 25,
                      opacity: isDark ? 0.15 : 0.25,
                      color: isDark ? Colors.black : Colors.white,
                      borderColor: isDark ? Colors.white24 : Colors.black12,
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 36,
                              ),
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
                  'Your AI-Powered Life Assistant',
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
      ),
    );
  }
}
