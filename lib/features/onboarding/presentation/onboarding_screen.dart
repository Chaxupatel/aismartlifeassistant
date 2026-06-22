import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gradient_background.dart';

/// Onboarding screen displaying key application utilities using a [PageView].
/// It contains 4 slides with premium custom-rendered vector illustrations.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Smart Reminders',
      'desc': 'Organize your days seamlessly. Receive smart notifications that adapt to your schedule and location contextually.',
    },
    {
      'title': 'AI Reminder Creation',
      'desc': 'Simply speak or type natural sentences. The assistant automatically extracts deadlines, locations, and tasks to schedule reminders.',
    },
    {
      'title': 'Events & Calendar',
      'desc': 'Consolidate travel plans, work keynotes, and social gatherings in one place. Synchronizes across standard calendars automatically.',
    },
    {
      'title': 'Productivity Dashboard',
      'desc': 'Track completed tasks, view analytics reports, and let the AI optimizer highlight free slots to suggest time blocks.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GradientBackground(
      child: Column(
        children: [
          // Top Bar (Skip Button)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Slider Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                final slide = _onboardingData[index];
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.l, vertical: AppSizes.s),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom vector-based premium illustration
                        _buildIllustration(index, isDark),
                        const SizedBox(height: AppSizes.l),
                        
                        // Text description card
                        GlassContainer(
                          blur: 24,
                          opacity: isDark ? 0.08 : 0.15,
                          color: isDark ? Colors.black : Colors.white,
                          borderColor: isDark ? const Color(0x22FFFFFF) : const Color(0x55FFFFFF),
                          padding: const EdgeInsets.all(AppSizes.l),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slide['title']!,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSizes.m),
                              Text(
                                slide['desc']!,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Page Indicators & Buttons Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.l),
            child: Column(
              children: [
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                
                // Navigation Action Button
                PrimaryButton(
                  label: _currentPage == _onboardingData.length - 1
                      ? 'Get Started'
                      : 'Next',
                  onPressed: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a high-fidelity premium illustration using nested shapes.
  Widget _buildIllustration(int index, bool isDark) {
    switch (index) {
      case 0:
        return _buildSmartRemindersIllustration(isDark);
      case 1:
        return _buildAIReminderIllustration(isDark);
      case 2:
        return _buildEventsIllustration(isDark);
      case 3:
        return _buildDashboardIllustration(isDark);
      default:
        return const SizedBox(height: 220);
    }
  }

  // Slide 1: Smart Reminders (Clock and floating check tasks)
  Widget _buildSmartRemindersIllustration(bool isDark) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Glowing Ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
            ),
          ),
          // Central Bell card
          GlassContainer(
            width: 110,
            height: 110,
            borderRadius: 24,
            blur: 15,
            padding: EdgeInsets.zero,
            color: isDark ? Colors.black : Colors.white,
            child: const Center(
              child: Icon(
                Icons.notifications_active_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
          ),
          // Floating task bubble 1 (Top Left)
          Positioned(
            left: 20,
            top: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 16,
              blur: 10,
              color: isDark ? Colors.black : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('Call Mom', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Floating task bubble 2 (Bottom Right)
          Positioned(
            right: 20,
            bottom: 30,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 16,
              blur: 10,
              color: isDark ? Colors.black : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.radio_button_off_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('Buy Milk', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 2: AI Reminder Creation (AI Chat Bubbles and wave effects)
  Widget _buildAIReminderIllustration(bool isDark) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Message wave rings
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary.withOpacity(0.15), width: 1),
            ),
          ),
          // Central Sparkle/AI icon
          GlassContainer(
            width: 100,
            height: 100,
            borderRadius: 24,
            blur: 15,
            padding: EdgeInsets.zero,
            color: isDark ? Colors.black : Colors.white,
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
          ),
          // User input bubble (Top Right)
          Positioned(
            right: 10,
            top: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 12,
              blur: 10,
              opacity: 0.2,
              color: AppColors.primary,
              borderColor: AppColors.primary.withOpacity(0.3),
              child: const Text(
                '"remind me at 5 PM"',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // AI output confirmation bubble (Bottom Left)
          Positioned(
            left: 10,
            bottom: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 12,
              blur: 10,
              color: isDark ? Colors.black : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.secondary, size: 14),
                  const SizedBox(width: 4),
                  Text('Reminder Set!', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 3: Events & Calendar Tracking (Calendar card and maps location pin)
  Widget _buildEventsIllustration(bool isDark) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Calendar Board
          GlassContainer(
            width: 150,
            height: 120,
            borderRadius: 20,
            blur: 15,
            padding: const EdgeInsets.all(8),
            color: isDark ? Colors.black : Colors.white,
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 6,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      18,
                      (index) => Container(
                        decoration: BoxDecoration(
                          color: index == 14 ? AppColors.accent : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Event Detail Card (Bottom Right)
          Positioned(
            right: 15,
            bottom: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 12,
              blur: 10,
              color: isDark ? Colors.black : Colors.white,
              child: const Row(
                children: [
                  Icon(Icons.flight_takeoff_rounded, color: AppColors.accent, size: 14),
                  SizedBox(width: 4),
                  Text('Trip to NYC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Floating Location Pin (Top Left)
          Positioned(
            left: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.15),
              ),
              child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // Slide 4: Productivity Dashboard (Circular chart and upward trends)
  Widget _buildDashboardIllustration(bool isDark) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring Chart
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 0.75,
              strokeWidth: 10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          // Central Progress Label
          GlassContainer(
            width: 80,
            height: 80,
            borderRadius: 40, // Perfect Circle
            blur: 10,
            padding: EdgeInsets.zero,
            color: isDark ? Colors.black : Colors.white,
            child: const Center(
              child: Text(
                '75%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ),
          ),
          // Floating Stats Line Card (Bottom Left)
          Positioned(
            left: 10,
            bottom: 20,
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: 12,
              blur: 10,
              color: isDark ? Colors.black : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 4),
                  Text('+12% Focus', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Floating Trophy Star (Top Right)
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
