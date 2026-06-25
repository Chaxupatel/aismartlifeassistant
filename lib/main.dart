import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'package:alarm/alarm.dart';

import 'firebase_options.dart';

/// Entry point of the AI Smart Life Assistant application.
void main() async {
  // Ensure widget bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core services
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Crashlytics
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

  // Initialize Hive local storage
  await Hive.initFlutter();
  
  // Open the reminders and settings boxes asynchronously
  await Hive.openBox<Map>('reminders_box');
  await Hive.openBox('settings_box');

  // Initialize Notification Service for local notifications & alarms
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Initialize Alarm package
  await Alarm.init();
  
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
    // Listen for alarms ringing
    Alarm.ringStream.stream.listen((alarmSettings) {
      // Navigate to alarm ring screen when alarm triggers
      ref.read(appRouterProvider).push('/alarm-ring', extra: alarmSettings);
    });
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
