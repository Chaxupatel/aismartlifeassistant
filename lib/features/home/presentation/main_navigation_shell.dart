import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/ad_banner_widget.dart';

/// Navigation shell wrapper using [StatefulNavigationShell] from go_router.
/// Upgraded to render a floating, capsule-shaped glass navigation bar with
/// micro-animations (active tab scaling and glowing indicator bars).
class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Keep navigation capsule below keyboard
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.l),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.s + 4),
                      borderRadius: 30, // Capsule shape
                      blur: 24,
                      opacity: isDark ? 0.12 : 0.22,
                      color: isDark ? Colors.black : Colors.white,
                      borderColor: isDark
                          ? const Color(0x22FFFFFF)
                          : const Color(0x44FFFFFF),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            context,
                            index: 0,
                            icon: Icons.home_rounded,
                            label: 'Home',
                          ),
                          _buildNavItem(
                            context,
                            index: 1,
                            icon: Icons.calendar_month_rounded,
                            label: 'Calendar',
                          ),
                          _buildNavItem(
                            context,
                            index: 2,
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Reminders',
                          ),
                          _buildNavItem(
                            context,
                            index: 3,
                            icon: Icons.event_note_rounded,
                            label: 'Events',
                          ),
                          _buildNavItem(
                            context,
                            index: 4,
                            icon: Icons.person_outline_rounded,
                            label: 'Profile',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const AdBannerWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : Colors.black54;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Micro-animated icon scale
            AnimatedScale(
              scale: isSelected ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: AppSizes.iconM,
              ),
            ),
            const SizedBox(height: 4),
            // Glowing indicator bar instead of text to look extremely clean,
            // or a tiny microdot. Let's paint a glowing capsule line.
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSelected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
