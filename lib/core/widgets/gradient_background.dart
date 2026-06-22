import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A premium layout background that renders ambient radial/glowing elements.
/// It uses [RadialGradient] within round spheres to create soft, feathered,
/// studio-lighting style backdrops for the [GlassContainer] to rest upon.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const GradientBackground({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundContent = Stack(
      children: [
        // Base dark/light background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkBgStart, AppColors.darkBgEnd]
                  : [AppColors.lightBgStart, AppColors.lightBgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Neon ambient sphere 1 (Top Right)
        Positioned(
          top: -150,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(isDark ? 0.35 : 0.45),
                  AppColors.primary.withOpacity(0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Neon ambient sphere 2 (Bottom Left)
        Positioned(
          bottom: -180,
          left: -180,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withOpacity(isDark ? 0.25 : 0.35),
                  AppColors.accent.withOpacity(0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Neon ambient sphere 3 (Center Right - subtle)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: -200,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(isDark ? 0.22 : 0.32),
                  AppColors.secondary.withOpacity(0.0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Screen Content
        useSafeArea ? SafeArea(child: child) : child,
      ],
    );

    return Scaffold(
      body: backgroundContent,
      resizeToAvoidBottomInset: false, // Prevents keyboard layout shifts
    );
  }
}
