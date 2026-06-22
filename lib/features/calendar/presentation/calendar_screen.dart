import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/providers/reminders_provider.dart';

/// Screen exhibiting calendar events and monthly views using TableCalendar.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // --- RECURRENCE & DATE HELPERS ---

  /// Determines if a reminder is active on a specific [date].
  bool _isReminderActiveOnDay(Reminder reminder, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final reminderDate = DateTime(
      reminder.dateTime.year,
      reminder.dateTime.month,
      reminder.dateTime.day,
    );

    // Cannot occur before the start date
    if (targetDate.isBefore(reminderDate)) {
      return false;
    }

    switch (reminder.repeatType) {
      case 'One Time':
        return targetDate.year == reminderDate.year &&
            targetDate.month == reminderDate.month &&
            targetDate.day == reminderDate.day;
      case 'Daily':
        return true;
      case 'Weekly':
        return targetDate.weekday == reminderDate.weekday;
      case 'Monthly':
        return targetDate.day == reminderDate.day;
      case 'Yearly':
        return targetDate.month == reminderDate.month &&
            targetDate.day == reminderDate.day;
      default:
        return false;
    }
  }

  /// Determines if a reminder is active during the week containing [selectedDay].
  bool _isReminderActiveInWeek(Reminder reminder, DateTime selectedDay) {
    final monday = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final reminderDate = DateTime(
      reminder.dateTime.year,
      reminder.dateTime.month,
      reminder.dateTime.day,
    );

    // Cannot occur before start week
    if (reminderDate.isAfter(weekEnd)) {
      return false;
    }

    switch (reminder.repeatType) {
      case 'One Time':
        final rDate = DateTime(reminder.dateTime.year, reminder.dateTime.month, reminder.dateTime.day);
        return (rDate.isAtSameMomentAs(weekStart) || rDate.isAfter(weekStart)) &&
            (rDate.isAtSameMomentAs(weekEnd) || rDate.isBefore(weekEnd));
      case 'Daily':
        return true;
      case 'Weekly':
        return true; // Always occurs once a week
      case 'Monthly':
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          if (day.day == reminderDate.day && (day.isAfter(reminderDate) || day.isAtSameMomentAs(reminderDate))) {
            return true;
          }
        }
        return false;
      case 'Yearly':
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          if (day.month == reminderDate.month && day.day == reminderDate.day && (day.isAfter(reminderDate) || day.isAtSameMomentAs(reminderDate))) {
            return true;
          }
        }
        return false;
      default:
        return false;
    }
  }

  /// Calculates the next occurrence of a reminder after [afterDate].
  DateTime? _getNextOccurrence(Reminder reminder, DateTime afterDate) {
    final start = reminder.dateTime;
    if (start.isAfter(afterDate)) {
      return start;
    }

    switch (reminder.repeatType) {
      case 'One Time':
        return start.isAfter(afterDate) ? start : null;
      case 'Daily':
        final candidate = DateTime(afterDate.year, afterDate.month, afterDate.day, start.hour, start.minute);
        return candidate.isAfter(afterDate) ? candidate : candidate.add(const Duration(days: 1));
      case 'Weekly':
        int daysToAdd = start.weekday - afterDate.weekday;
        if (daysToAdd < 0) daysToAdd += 7;
        final candidate = DateTime(afterDate.year, afterDate.month, afterDate.day, start.hour, start.minute).add(Duration(days: daysToAdd));
        return candidate.isAfter(afterDate) ? candidate : candidate.add(const Duration(days: 7));
      case 'Monthly':
        DateTime candidate = DateTime(afterDate.year, afterDate.month, start.day, start.hour, start.minute);
        if (candidate.isAfter(afterDate)) {
          return candidate;
        } else {
          int nextMonth = afterDate.month + 1;
          int nextYear = afterDate.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear += 1;
          }
          final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
          final safeDay = start.day.clamp(1, daysInMonth);
          return DateTime(nextYear, nextMonth, safeDay, start.hour, start.minute);
        }
      case 'Yearly':
        DateTime candidate = DateTime(afterDate.year, start.month, start.day, start.hour, start.minute);
        return candidate.isAfter(afterDate) ? candidate : DateTime(afterDate.year + 1, start.month, start.day, start.hour, start.minute);
      default:
        return null;
    }
  }

  // --- RENDER HELPERS ---

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Work':
        return Colors.indigoAccent;
      case 'Health':
        return Colors.tealAccent;
      case 'Personal':
        return Colors.orangeAccent;
      case 'Shopping':
        return Colors.pinkAccent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch reminders state from Hive
    final reminders = ref.watch(remindersProvider);

    // Grouping events for selected day (Daily Reminders)
    final dailyReminders = reminders.where((r) => _isReminderActiveOnDay(r, _selectedDay ?? _focusedDay)).toList();

    // Grouping events for selected day's week (Weekly Reminders)
    final weeklyReminders = reminders.where((r) => _isReminderActiveInWeek(r, _selectedDay ?? _focusedDay)).toList();

    // Evaluating upcoming reminders starting after the selected day
    final upcomingCalculated = <Map<String, dynamic>>[];
    final afterLimit = DateTime(
      (_selectedDay ?? _focusedDay).year,
      (_selectedDay ?? _focusedDay).month,
      (_selectedDay ?? _focusedDay).day,
      23,
      59,
      59,
    );

    for (final r in reminders) {
      final nextOcc = _getNextOccurrence(r, afterLimit);
      if (nextOcc != null) {
        upcomingCalculated.add({
          'reminder': r,
          'nextOcc': nextOcc,
        });
      }
    }
    upcomingCalculated.sort((a, b) => (a['nextOcc'] as DateTime).compareTo(b['nextOcc'] as DateTime));

    return GradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.s),
            child: Text(
              'Calendar Dashboard',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Monthly Calendar Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
            child: GlassContainer(
              blur: 24,
              opacity: isDark ? 0.08 : 0.14,
              color: isDark ? Colors.black : Colors.white,
              borderColor: isDark ? Colors.white10 : Colors.black12,
              padding: const EdgeInsets.all(AppSizes.s),
              child: TableCalendar<Reminder>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                
                // Fetch events to show marker dots
                eventLoader: (day) {
                  return reminders.where((r) => _isReminderActiveOnDay(r, day)).toList();
                },

                // Calendar Styling
                daysOfWeekHeight: 24,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                  weekendTextStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 14,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 4.5,
                  markerMargin: const EdgeInsets.only(top: 6),
                  markersMaxCount: 3,
                  markersAnchor: 0.7,
                  markerDecoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.m),

          // Lists Container
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                left: AppSizes.m,
                right: AppSizes.m,
                bottom: 120, // Avoid navigation overlap
              ),
              children: [
                // 1. DAILY REMINDERS
                _buildSectionHeader(
                  context,
                  title: 'Daily Reminders',
                  subtitle: _selectedDay == null
                      ? 'Select a date'
                      : '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                  isDark: isDark,
                ),
                const SizedBox(height: AppSizes.s),
                if (dailyReminders.isEmpty)
                  _buildEmptyState('No reminders active on this day.', isDark)
                else
                  ...dailyReminders.map((r) => _buildReminderCard(r, isDark, exactDateTime: r.repeatType == 'One Time' ? null : DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, r.dateTime.hour, r.dateTime.minute))),

                const SizedBox(height: AppSizes.l),

                // 2. WEEKLY REMINDERS
                _buildSectionHeader(
                  context,
                  title: 'Weekly Reminders',
                  subtitle: 'Scheduled this week',
                  isDark: isDark,
                ),
                const SizedBox(height: AppSizes.s),
                if (weeklyReminders.isEmpty)
                  _buildEmptyState('No reminders active during this week.', isDark)
                else
                  ...weeklyReminders.map((r) => _buildReminderCard(r, isDark)),

                const SizedBox(height: AppSizes.l),

                // 3. UPCOMING REMINDERS
                _buildSectionHeader(
                  context,
                  title: 'Upcoming Reminders',
                  subtitle: 'Future schedule preview',
                  isDark: isDark,
                ),
                const SizedBox(height: AppSizes.s),
                if (upcomingCalculated.isEmpty)
                  _buildEmptyState('No future reminders scheduled.', isDark)
                else
                  ...upcomingCalculated.take(5).map((map) {
                    final r = map['reminder'] as Reminder;
                    final nextOcc = map['nextOcc'] as DateTime;
                    return _buildReminderCard(r, isDark, exactDateTime: nextOcc);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text, bool isDark) {
    return GlassContainer(
      blur: 10,
      opacity: isDark ? 0.04 : 0.08,
      color: isDark ? Colors.black : Colors.white,
      borderColor: isDark ? Colors.white10 : Colors.black12,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.m, horizontal: AppSizes.m),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black45,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, bool isDark, {DateTime? exactDateTime}) {
    final displayDate = exactDateTime ?? reminder.dateTime;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s),
      child: GlassContainer(
        blur: 15,
        opacity: isDark ? 0.06 : 0.1,
        color: isDark ? Colors.black : Colors.white,
        borderColor: isDark ? Colors.white10 : Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: 12),
        child: Row(
          children: [
            // Checkbox completion toggle
            InkWell(
              onTap: () {
                ref.read(remindersProvider.notifier).toggleReminder(reminder.id);
              },
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                reminder.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded,
                color: reminder.isCompleted ? AppColors.success : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.m),

            // Text Info
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/reminders/${reminder.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: isDark ? Colors.white54 : Colors.black45,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${displayDate.day}/${displayDate.month} at ${displayDate.hour.toString().padLeft(2, '0')}:${displayDate.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (reminder.repeatType != 'One Time') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.replay_rounded, size: 11, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            reminder.repeatType,
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSizes.s),

            // Category Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getCategoryColor(reminder.category).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reminder.category,
                style: TextStyle(
                  color: _getCategoryColor(reminder.category),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
