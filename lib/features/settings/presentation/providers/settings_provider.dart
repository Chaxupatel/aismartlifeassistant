import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/settings_repository.dart';

// Provider for the repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = Hive.box('settings_box');
  return SettingsRepository(box);
});

// A model class for settings state
class SettingsState {
  final bool pushNotificationsEnabled;
  final bool smartBriefingsEnabled;
  final String notificationTone;
  final String alarmRingtone;
  final double alarmVolume;

  SettingsState({
    required this.pushNotificationsEnabled,
    required this.smartBriefingsEnabled,
    required this.notificationTone,
    required this.alarmRingtone,
    required this.alarmVolume,
  });

  SettingsState copyWith({
    bool? pushNotificationsEnabled,
    bool? smartBriefingsEnabled,
    String? notificationTone,
    String? alarmRingtone,
    double? alarmVolume,
  }) {
    return SettingsState(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      smartBriefingsEnabled: smartBriefingsEnabled ?? this.smartBriefingsEnabled,
      notificationTone: notificationTone ?? this.notificationTone,
      alarmRingtone: alarmRingtone ?? this.alarmRingtone,
      alarmVolume: alarmVolume ?? this.alarmVolume,
    );
  }
}

// Notifier to manage and broadcast settings state
class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsRepository _repository;

  @override
  SettingsState build() {
    _repository = ref.watch(settingsRepositoryProvider);
    return SettingsState(
      pushNotificationsEnabled: _repository.pushNotificationsEnabled,
      smartBriefingsEnabled: _repository.smartBriefingsEnabled,
      notificationTone: _repository.notificationTone,
      alarmRingtone: _repository.alarmRingtone,
      alarmVolume: _repository.alarmVolume,
    );
  }

  void togglePushNotifications(bool value) {
    _repository.setPushNotificationsEnabled(value);
    state = state.copyWith(pushNotificationsEnabled: value);
  }

  void toggleSmartBriefings(bool value) {
    _repository.setSmartBriefingsEnabled(value);
    state = state.copyWith(smartBriefingsEnabled: value);
  }

  void updateNotificationTone(String tone) {
    _repository.setNotificationTone(tone);
    state = state.copyWith(notificationTone: tone);
  }

  void updateAlarmRingtone(String tone) {
    _repository.setAlarmRingtone(tone);
    state = state.copyWith(alarmRingtone: tone);
  }

  void updateAlarmVolume(double volume) {
    _repository.setAlarmVolume(volume);
    state = state.copyWith(alarmVolume: volume);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
