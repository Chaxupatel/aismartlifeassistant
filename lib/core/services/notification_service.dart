import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart' hide NotificationSettings;
import 'package:alarm/alarm.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/reminders/domain/reminder.dart';

/// A timezone-aware wrapper service handling scheduling, updates, and cancellations
/// for OS-level notifications and alarms, as well as Firebase Cloud Messaging.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Initializes timezone databases, registers default notification settings, and configures FCM listeners.
  Future<void> init() async {
    // Initialize timezone location data
    tz.initializeTimeZones();

    // Detect the device's actual local timezone so notifications fire at the correct local time
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fallback to UTC if device timezone detection fails
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle clicking notifications
      },
    );

    // Initialize Firebase Cloud Messaging listeners
    _initFcmListeners();
  }

  void _initFcmListeners() {
    // 1. Foreground messaging handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _plugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel',
              'Cloud Messages',
              channelDescription: 'Notifications received from Firebase Cloud Messaging',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // 2. Background/Terminated click messaging handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened via FCM notification: ${message.data}');
    });

    // 3. Fetch device FCM Token for test dispatching
    FirebaseMessaging.instance.getToken().then((token) {
      print('=== FIREBASE FCM DEVICE TOKEN ===');
      print(token);
      print('=================================');
    }).catchError((err) {
      print('Failed to retrieve FCM Device Token: $err');
    });
  }

  /// Triggers runtime permission requests on Android 13+ and iOS systems.
  Future<void> requestPermissions() async {
    // Request Android 13+ notifications runtime permission
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Request iOS alerts, badges, and sound permissions
    final iosImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Request Firebase Cloud Messaging permissions
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      print('Failed to request FCM permissions: $e');
    }
  }

  /// Schedules a notification or alarm on the native scheduler according to recurrence rules.
  Future<void> scheduleNotification(Reminder reminder) async {
    // Skip if both alerts are disabled
    if (!reminder.enableNotification && !reminder.enableAlarm) return;

    // Use a unique 32-bit numeric ID for the notification scheduler
    // Android notification IDs must be 32-bit integers. millisecondsSinceEpoch exceeds this.
    final id = reminder.id.hashCode & 0x7FFFFFFF;

    // If Alarm is enabled, use the alarm package for full-screen robust alarms
    if (reminder.enableAlarm) {
      final box = Hive.box('settings_box');
      final volume = box.get('alarmVolume', defaultValue: 0.8) as double;
      
      final alarmSettings = AlarmSettings(
        id: id,
        dateTime: reminder.dateTime,
        assetAudioPath: 'assets/audio/alarm.wav',
        loopAudio: true,
        vibrate: true,
        volumeSettings: VolumeSettings.fade(
          volume: volume,
          fadeDuration: const Duration(seconds: 3),
          showSystemUI: false,
        ),
        notificationSettings: NotificationSettings(
          title: reminder.title,
          body: reminder.description ?? '',
          stopButton: 'Stop',
          icon: 'notification_icon',
        ),
        payload: reminder.snoozeDuration.toString(),
      );
      
      await Alarm.set(alarmSettings: alarmSettings);
      
      // We don't also need to schedule a local notification if the alarm package handles it
      if (!reminder.enableNotification) return;
    }

    // Otherwise, or additionally, schedule standard local notification
    final channelId = 'reminders_channel';
    final channelName = 'Reminders';
    final channelDesc = 'Standard reminders';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Resolve date boundary timezone
    final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // If it's a one-time reminder scheduled in the past, discard scheduling
    if (reminder.repeatType == 'One Time' && scheduledDate.isBefore(now)) {
      return;
    }

    // Resolve recurrence pattern mapping
    DateTimeComponents? matchComponents;
    switch (reminder.repeatType) {
      case 'Daily':
        matchComponents = DateTimeComponents.time;
        break;
      case 'Weekly':
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case 'Monthly':
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case 'Yearly':
        matchComponents = DateTimeComponents.dateAndTime;
        break;
      case 'One Time':
      default:
        matchComponents = null;
        break;
    }

    if (matchComponents == null) {
      // Schedule single one-time notification
      await _plugin.zonedSchedule(
        id: id,
        title: reminder.title,
        body: reminder.description,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      // Schedule recurring notification
      await _plugin.zonedSchedule(
        id: id,
        title: reminder.title,
        body: reminder.description,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    }
  }

  /// Cancels any scheduled notification or alarm associated with the reminder ID.
  Future<void> cancelNotification(String reminderId) async {
    final id = reminderId.hashCode & 0x7FFFFFFF;
    await Alarm.stop(id);
    await _plugin.cancel(id: id);
  }
}
