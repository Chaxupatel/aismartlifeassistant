import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gradient_background.dart';
import 'providers/reminders_provider.dart';
import '../domain/reminder.dart';

/// Screen showcasing full details of a specific reminder.
class ReminderDetailScreen extends ConsumerWidget {
  final String reminderId;

  const ReminderDetailScreen({
    super.key,
    required this.reminderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch the active reminders list
    final reminders = ref.watch(remindersProvider);

    // Find the reminder matching this screen ID
    Reminder? reminder;
    for (final r in reminders) {
      if (r.id == reminderId) {
        reminder = r;
        break;
      }
    }

    final activeReminder = reminder;

    if (activeReminder == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Reminder Detail'),
        ),
        body: const GradientBackground(
          child: Center(
            child: Text('Reminder not found.', style: TextStyle(color: Colors.white70)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reminder Detail'),
        actions: [
          // Edit reminder action
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => context.push('/reminders/$reminderId/edit'),
          ),
          // Delete reminder action
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () {
              ref.read(remindersProvider.notifier).deleteReminder(reminderId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder Deleted'),
                  backgroundColor: AppColors.error,
                ),
              );
              context.pop();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSizes.m,
            right: AppSizes.m,
            top: 110,
            bottom: AppSizes.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Detail Glass Card
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeReminder.category,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.s),
                        Text(
                          'Status: ${activeReminder.isCompleted ? "Completed" : "Active"}',
                          style: TextStyle(
                            color: activeReminder.isCompleted ? AppColors.success : AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.m),
                    
                    // Reminder Title
                    Text(
                      activeReminder.title,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        decoration: activeReminder.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: AppSizes.l),
                    
                    // Information Rows
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Scheduled Date',
                      value: '${activeReminder.dateTime.day}/${activeReminder.dateTime.month}/${activeReminder.dateTime.year}',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.access_time_rounded,
                      title: 'Scheduled Time',
                      value: '${activeReminder.dateTime.hour.toString().padLeft(2, '0')}:${activeReminder.dateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.replay_rounded,
                      title: 'Repeat Schedule',
                      value: activeReminder.repeatType,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: 'Alert Options',
                      value: [
                        if (activeReminder.enableNotification) 'Notification',
                        if (activeReminder.enableAlarm) 'Alarm',
                        if (!activeReminder.enableNotification && !activeReminder.enableAlarm) 'None',
                      ].join(', '),
                    ),
                    if (activeReminder.description != null && activeReminder.description!.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow(
                        context,
                        icon: Icons.notes_rounded,
                        title: 'Notes',
                        value: activeReminder.description!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // Action button
              PrimaryButton(
                label: activeReminder.isCompleted ? 'Mark as Active' : 'Mark as Completed',
                onPressed: () {
                  ref.read(remindersProvider.notifier).toggleReminder(reminderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(activeReminder.isCompleted ? 'Marked task as Active' : 'Completed Task!'),
                      backgroundColor: activeReminder.isCompleted ? AppColors.warning : AppColors.success,
                    ),
                  );
                  context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
