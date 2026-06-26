import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Import presentation layer pages
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_navigation_shell.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/reminders/presentation/reminder_list_screen.dart';
import '../../features/reminders/presentation/add_reminder_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../features/reminders/presentation/edit_reminder_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/ai_assistant/presentation/ai_reminder_creation_screen.dart';
import '../../features/reminders/presentation/alarm_ring_screen.dart';
import 'package:alarm/alarm.dart';

// Global keys for navigation contexts
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Lazy navigator observer for Firebase Analytics to prevent eager dependency crash on boot
final lazyAnalyticsObserver = LazyFirebaseAnalyticsObserver();

class LazyFirebaseAnalyticsObserver extends NavigatorObserver {
  FirebaseAnalyticsObserver? _delegate;

  void initialize() {
    _delegate = FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _delegate?.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _delegate?.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _delegate?.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _delegate?.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _delegate?.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    _delegate?.didStopUserGesture();
  }
}

/// Provider exposing the configured [GoRouter] setup to the application.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    observers: [
      lazyAnalyticsObserver,
    ],
    routes: [
      // Splash Initial Path
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding Tutorial Paths
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Shared Global Floating Routes (Pushed on top of tabs)
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: '/ai-reminder-creation',
        builder: (context, state) => const AIReminderCreationScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/alarm-ring',
        builder: (context, state) {
          final settings = state.extra as AlarmSettings;
          return AlarmRingScreen(alarmSettings: settings);
        },
      ),

      // Main Stateful Tab Bar Structure
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Index 0: Home Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          
          // Index 1: Calendar View
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),

          // Index 2: Reminders Task Section
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (context, state) => const ReminderListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return AddReminderScreen(
                        prefilledTitle: extra?['title'] as String?,
                        prefilledDateTime: extra?['dateTime'] as DateTime?,
                        prefilledCategory: extra?['category'] as String?,
                        prefilledDescription: extra?['description'] as String?,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ReminderDetailScreen(reminderId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return EditReminderScreen(reminderId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Index 3: Events Scheduler
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),

          // Index 4: User Profile Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
