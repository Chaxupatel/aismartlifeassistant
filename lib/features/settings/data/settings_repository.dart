import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  final Box _box;

  SettingsRepository(this._box);

  bool get pushNotificationsEnabled =>
      _box.get('pushNotificationsEnabled', defaultValue: true);
  Future<void> setPushNotificationsEnabled(bool value) =>
      _box.put('pushNotificationsEnabled', value);

  bool get smartBriefingsEnabled =>
      _box.get('smartBriefingsEnabled', defaultValue: false);
  Future<void> setSmartBriefingsEnabled(bool value) =>
      _box.put('smartBriefingsEnabled', value);

  String get notificationTone =>
      _box.get('notificationTone', defaultValue: 'Default (Chime)');
  Future<void> setNotificationTone(String value) =>
      _box.put('notificationTone', value);

  String get alarmRingtone =>
      _box.get('alarmRingtone', defaultValue: 'Classic Alarm');
  Future<void> setAlarmRingtone(String value) =>
      _box.put('alarmRingtone', value);

  double get alarmVolume => _box.get('alarmVolume', defaultValue: 0.8);
  Future<void> setAlarmVolume(double value) => _box.put('alarmVolume', value);
}
