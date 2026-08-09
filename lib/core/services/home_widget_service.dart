import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../../features/reminders/domain/reminder.dart';

/// Service managing synchronization between Flutter reminders state
/// and native Android Home Screen widgets.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Updates task statistics and active reminder list JSON on home screen widgets.
  Future<void> updateWidgets(List<Reminder> reminders) async {
    try {
      final total = reminders.length;
      final completed = reminders.where((r) => r.isCompleted).length;
      final statsText = '$completed/$total Completed';

      // Find active (uncompleted) reminders sorted by date/time
      final activeReminders = reminders
          .where((r) => !r.isCompleted)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Serialize active tasks to JSON array
      final List<Map<String, dynamic>> tasksJsonList = activeReminders.map((r) {
        final hour = r.dateTime.hour.toString().padLeft(2, '0');
        final minute = r.dateTime.minute.toString().padLeft(2, '0');
        final day = r.dateTime.day.toString().padLeft(2, '0');
        final month = r.dateTime.month.toString().padLeft(2, '0');
        return {
          'id': r.id,
          'title': r.title,
          'category': r.category,
          'timeStr': '$day/$month at $hour:$minute',
          'isCompleted': r.isCompleted,
        };
      }).toList();

      final jsonString = jsonEncode(tasksJsonList);

      // Save key-value data to shared widget storage
      await HomeWidget.saveWidgetData('widget_task_stats', statsText);
      await HomeWidget.saveWidgetData('widget_tasks_json', jsonString);
      await HomeWidget.saveWidgetData('widget_has_tasks', activeReminders.isNotEmpty);

      // Trigger native widget update for TaskSummaryWidgetReceiver
      await HomeWidget.updateWidget(
        name: 'TaskSummaryWidgetReceiver',
        androidName: 'TaskSummaryWidgetReceiver',
        qualifiedAndroidName: 'com.chaxu.ai_smart_life_assistant.TaskSummaryWidgetReceiver',
      );
      // Trigger native widget update for QuickActionWidgetReceiver
      await HomeWidget.updateWidget(
        name: 'QuickActionWidgetReceiver',
        androidName: 'QuickActionWidgetReceiver',
        qualifiedAndroidName: 'com.chaxu.ai_smart_life_assistant.QuickActionWidgetReceiver',
      );
    } catch (e) {
      // Ignore widget update failures if platform not supported
    }
  }
}
