import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/reminder.dart';
import '../../data/reminder_repository.dart';
import 'package:ai_smart_life_assistant/core/services/notification_service.dart';
import 'package:ai_smart_life_assistant/features/auth/presentation/providers/auth_provider.dart';

import 'package:ai_smart_life_assistant/core/services/home_widget_service.dart';

/// Provider exposing the [ReminderRepository] implementation.
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return SyncedReminderRepository();
});

/// Notifier class managing the global list of active and completed reminders in memory, backed by Hive local storage and scheduled via local notifications.
class RemindersNotifier extends Notifier<List<Reminder>> {
  late ReminderRepository _repository;
  final _notificationService = NotificationService();

  @override
  List<Reminder> build() {
    _repository = ref.watch(reminderRepositoryProvider);
    
    // Watch authStateProvider to trigger reload/sync whenever the authentication state changes
    ref.watch(authStateProvider);
    
    _loadInitialData();
    return []; // Start with an empty list while loading asynchronously
  }

  Future<void> _loadInitialData() async {
    final list = await _repository.getReminders();
    
    // Check if the database has any seeded mockup reminders with IDs '1'..'5'
    final hasMockData = list.any((r) => ['1', '2', '3', '4', '5'].contains(r.id));
    if (hasMockData) {
      // Clear out the mockup reminders from Hive repository and local notification schedule
      for (final id in ['1', '2', '3', '4', '5']) {
        await _repository.deleteReminder(id);
        await _notificationService.cancelNotification(id);
      }
      // Load the cleaned list
      state = await _repository.getReminders();
    } else {
      state = list;
    }
    _notificationService.scheduleDailyBriefings();
    HomeWidgetService.instance.updateWidgets(state);
  }

  void addReminder(Reminder reminder) {
    final updated = reminder.copyWith(updatedAt: DateTime.now());
    state = [...state, updated];
    _repository.addReminder(updated);
    _notificationService.scheduleNotification(updated);
    _notificationService.scheduleDailyBriefings();
    HomeWidgetService.instance.updateWidgets(state);
  }

  void toggleReminder(String id) {
    final target = state.firstWhere((r) => r.id == id, orElse: () => state.first);
    
    // Auto-remove completed 'One Time' reminders
    if (!target.isCompleted && target.repeatType == 'One Time') {
      deleteReminder(id);
      return;
    }

    state = [
      for (final r in state)
        if (r.id == id)
          r.copyWith(isCompleted: !r.isCompleted, updatedAt: DateTime.now())
        else
          r
    ];
    
    // Find and persist the updated reminder
    final updated = state.firstWhere((r) => r.id == id);
    _repository.addReminder(updated);
    
    // Toggle notification schedule
    if (updated.isCompleted) {
      _notificationService.cancelNotification(id);
    } else {
      _notificationService.scheduleNotification(updated);
    }
    _notificationService.scheduleDailyBriefings();
    HomeWidgetService.instance.updateWidgets(state);
  }

  void updateReminder(Reminder updated) {
    final updatedWithTime = updated.copyWith(updatedAt: DateTime.now());
    state = [
      for (final r in state)
        if (r.id == updatedWithTime.id) updatedWithTime else r
    ];
    _repository.addReminder(updatedWithTime);
    _notificationService.scheduleNotification(updatedWithTime);
    _notificationService.scheduleDailyBriefings();
    HomeWidgetService.instance.updateWidgets(state);
  }

  void deleteReminder(String id) {
    state = state.where((r) => r.id != id).toList();
    _repository.deleteReminder(id);
    _notificationService.cancelNotification(id);
    _notificationService.scheduleDailyBriefings();
    HomeWidgetService.instance.updateWidgets(state);
  }

  void deleteMultipleReminders(List<String> ids) {
    state = state.where((r) => !ids.contains(r.id)).toList();
    for (final id in ids) {
      _repository.deleteReminder(id);
      _notificationService.cancelNotification(id);
    }
    _notificationService.scheduleDailyBriefings();
    HomeWidgetService.instance.updateWidgets(state);
  }
}

/// Provider exposing the list of active reminders.
final remindersProvider = NotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);

/// Notifier class managing the active date selected on the horizontal weekly calendar strip.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

/// Provider exposing the active selected date.
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);
