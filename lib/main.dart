import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'package:alarm/alarm.dart';

import 'core/services/app_open_ad_manager.dart';
import 'core/services/interstitial_ad_manager.dart';
import 'core/services/remote_config_service.dart';
import 'firebase_options.dart';

/// Global flag and completer to coordinate startup loading with the Splash Screen
bool isAppInitialized = false;
final Completer<void> appInitializationCompleter = Completer<void>();

/// Entry point of the AI Smart Life Assistant application.
void main() {
  // Ensure widget bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is required to store the state of all Riverpod providers
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Initialize independent services in parallel to speed up app boot time dramatically
      await Future.wait([
        MobileAds.instance.initialize().then((_) {
          AppOpenAdManager.instance.initializeLifecycleListener();
          AppOpenAdManager.instance.loadAd();
          InterstitialAdManager.instance.loadAd(); // Preload Interstitial on startup
        }),
        Hive.initFlutter().then((_) => Future.wait([
          Hive.openBox<Map>('reminders_box'),
          Hive.openBox('settings_box'),
        ])),
        Alarm.init(),
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).then((_) async {
          // Initialize our lazy analytics observer now that Firebase is running
          lazyAnalyticsObserver.initialize();

          // Initialize Remote Config values dynamically
          await ref.read(remoteConfigServiceProvider).initialize();

          if (!kIsWeb) {
            // Pass all uncaught "fatal" errors from the framework to Crashlytics
            FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

            // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
            PlatformDispatcher.instance.onError = (error, stack) {
              FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
              return true;
            };

            // Disable Crashlytics collection in debug mode to avoid cluttering logs
            await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

            // Disable Analytics collection in debug mode to avoid cluttering logs
            await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
          }
          // Initialize NotificationService (FCM) after Firebase app is ready
          final service = NotificationService();
          await service.init();
          await service.requestPermissions();
        }),
      ]);

      // Listen for alarms ringing
      Alarm.ringStream.stream.listen((alarmSettings) {
        // Navigate to alarm ring screen when alarm triggers
        ref.read(appRouterProvider).push('/alarm-ring', extra: alarmSettings);
      });

      isAppInitialized = true;
      if (!appInitializationCompleter.isCompleted) {
        appInitializationCompleter.complete();
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (!appInitializationCompleter.isCompleted) {
        appInitializationCompleter.completeError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to themeMode changes from our theme provider
    final themeMode = ref.watch(themeModeProvider);
    
    // Read the configured GoRouter navigation configuration
    final router = ref.read(appRouterProvider);

    return MaterialApp.router(
      title: 'AI Smart Life Assistant',
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
