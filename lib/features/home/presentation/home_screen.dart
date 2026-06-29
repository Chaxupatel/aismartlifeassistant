import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/providers/reminders_provider.dart';
import '../../events/presentation/providers/events_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// The responsive and state-connected main Home Dashboard screen of the application.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _quickAddFormKey = GlobalKey<FormState>();
  final _quickAddController = TextEditingController();
  String _selectedCategory = 'General';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);

  final List<String> _categories = ['General', 'Work', 'Health', 'Personal'];

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  void _handleQuickAdd(DateTime selectedDate) {
    if (_quickAddFormKey.currentState!.validate()) {
      final title = _quickAddController.text;
      final finalDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newReminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        dateTime: finalDateTime,
        category: _selectedCategory,
        isCompleted: false,
      );

      ref.read(remindersProvider.notifier).addReminder(newReminder);
      _quickAddController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quickly Added: "$title"'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch shared providers
    final reminders = ref.watch(remindersProvider);
    final events = ref.watch(eventsProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // Filter reminders by selected date
    final filteredReminders = reminders.where((r) {
      final isSameDay =
          r.dateTime.year == selectedDate.year &&
          r.dateTime.month == selectedDate.month &&
          r.dateTime.day == selectedDate.day;

      if (!isSameDay) return false;

      // If selected date is today, hide reminders that have already passed
      final isToday =
          selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day;

      if (isToday) {
        return r.dateTime.isAfter(DateTime.now());
      }

      return true;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Filter upcoming reminders (strictly after selected date)
    final upcomingReminders = reminders.where((r) {
      final dateOnly = DateTime(
        r.dateTime.year,
        r.dateTime.month,
        r.dateTime.day,
      );
      return dateOnly.isAfter(selectedDate);
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Get days of the current week (Monday to Sunday)
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(
      7,
      (index) => currentMonday.add(Duration(days: index)),
    );

    // Check responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 720;

    // Watch authStateProvider and get displayName
    final authState = ref.watch(authStateProvider);
    final user =
        authState.value ?? ref.read(authRepositoryProvider).currentUser;
    final displayName = user?.displayName;
    final firstName = displayName != null && displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').first
        : 'User';

    // Define dashboard widgets for modular layouts
    final headerWidget = _buildHeader(context, firstName, isDark);
    final calendarWidget = _buildCalendarPreview(
      weekDays,
      selectedDate,
      isDark,
    );
    final todayRemindersWidget = _buildTodayReminders(
      filteredReminders,
      selectedDate,
      isDark,
    );
    final upcomingRemindersWidget = _buildUpcomingReminders(
      upcomingReminders,
      isDark,
    );

    final quickAddWidget = _buildQuickAdd(selectedDate, isDark);
    final aiWidget = _buildAIAssistantCard(isDark);
    final eventsWidget = _buildEventsCard(events, isDark);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSizes.m,
              right: AppSizes.m,
              top: AppSizes.m,
              bottom: 190, // Margin to prevent overlap with both the floating glass navigation bar and the ad
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerWidget,
                const SizedBox(height: AppSizes.l),

                if (isWide) ...[
                  // Grid/Row layout for Wide screen sizes (Tablets, Desktops)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Calendar and lists
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            calendarWidget,
                            const SizedBox(height: AppSizes.l),
                            todayRemindersWidget,
                            const SizedBox(height: AppSizes.l),
                            upcomingRemindersWidget,
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.l),
                      // Right Column: Interaction cards
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            quickAddWidget,
                            const SizedBox(height: AppSizes.l),
                            aiWidget,
                            const SizedBox(height: AppSizes.l),
                            eventsWidget,
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mobile single column layout
                  calendarWidget,
                  const SizedBox(height: AppSizes.l),
                  todayRemindersWidget,
                  const SizedBox(height: AppSizes.l),
                  upcomingRemindersWidget,
                  const SizedBox(height: AppSizes.l),
                  quickAddWidget,
                  const SizedBox(height: AppSizes.l),
                  aiWidget,
                  const SizedBox(height: AppSizes.l),
                  eventsWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SUB-COMPONENTS ---

  Widget _buildHeader(BuildContext context, String firstName, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Smart Life',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hello, $firstName!',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/ai-assistant'),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPreview(
    List<DateTime> weekDays,
    DateTime selectedDate,
    bool isDark,
  ) {
    final List<String> dayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendar Preview',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.s),
        GlassContainer(
          blur: 15,
          opacity: isDark ? 0.06 : 0.1,
          color: isDark ? Colors.black : Colors.white,
          borderColor: isDark ? Colors.white10 : Colors.black12,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.m,
            horizontal: AppSizes.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = weekDays[index];
              final isToday =
                  date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final isSelected =
                  date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).selectDate(date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayNames[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white60 : Colors.black54),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayReminders(
    List<Reminder> filteredReminders,
    DateTime selectedDate,
    bool isDark,
  ) {
    final now = DateTime.now();
    final isSelectedToday =
        selectedDate.day == now.day &&
        selectedDate.month == now.month &&
        selectedDate.year == now.year;

    final title = isSelectedToday
        ? "Today's Reminders"
        : "Reminders for ${selectedDate.day}/${selectedDate.month}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.s),
        if (filteredReminders.isEmpty) ...[
          GlassContainer(
            blur: 15,
            opacity: isDark ? 0.04 : 0.08,
            color: isDark ? Colors.black : Colors.white,
            borderColor: isDark ? Colors.white10 : Colors.black12,
            padding: const EdgeInsets.all(AppSizes.l),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 36,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reminders scheduled for this day.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.lightTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Column(
            children: filteredReminders.map((reminder) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s),
                child: GlassContainer(
                  blur: 15,
                  opacity: isDark ? 0.06 : 0.1,
                  color: isDark ? Colors.black : Colors.white,
                  borderColor: isDark ? Colors.white10 : Colors.black12,
                  padding: const EdgeInsets.all(AppSizes.m),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          ref
                              .read(remindersProvider.notifier)
                              .toggleReminder(reminder.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(
                          reminder.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off_rounded,
                          color: reminder.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.m),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/reminders/${reminder.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  decoration: reminder.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: isDark
                                      ? Colors.white60
                                      : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${reminder.dateTime.hour.toString().padLeft(2, '0')}:${reminder.dateTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reminder.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildUpcomingReminders(
    List<Reminder> upcomingReminders,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Reminders',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.s),
        if (upcomingReminders.isEmpty) ...[
          GlassContainer(
            blur: 15,
            opacity: isDark ? 0.04 : 0.08,
            color: isDark ? Colors.black : Colors.white,
            borderColor: isDark ? Colors.white10 : Colors.black12,
            padding: const EdgeInsets.all(AppSizes.m),
            child: Center(
              child: Text(
                'No upcoming tasks scheduled.',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ] else ...[
          Column(
            children: upcomingReminders.take(3).map((reminder) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s),
                child: GlassContainer(
                  blur: 10,
                  opacity: isDark ? 0.05 : 0.08,
                  color: isDark ? Colors.black : Colors.white,
                  borderColor: isDark ? Colors.white10 : Colors.black12,
                  padding: const EdgeInsets.all(AppSizes.m),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.m),
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${reminder.dateTime.day}/${reminder.dateTime.month}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAdd(DateTime selectedDate, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add Reminder',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.s),
        GlassContainer(
          blur: 20,
          opacity: isDark ? 0.08 : 0.12,
          color: isDark ? Colors.black : Colors.white,
          borderColor: isDark ? Colors.white12 : Colors.black12,
          padding: const EdgeInsets.all(AppSizes.m),
          child: Form(
            key: _quickAddFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _quickAddController,
                  labelText: 'Task Title',
                  prefixIcon: Icons.add_task_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.m),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        dropdownColor: isDark ? Colors.black87 : Colors.white,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.s),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        label: Text(
                          _selectedTime.format(context),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.m),
                PrimaryButton(
                  label: 'Add Task',
                  onPressed: () => _handleQuickAdd(selectedDate),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIAssistantCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Assistant Recommendations',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.s),
        GlassContainer(
          blur: 24,
          opacity: isDark ? 0.1 : 0.15,
          color: isDark ? Colors.black : Colors.white,
          borderColor: isDark ? Colors.white12 : Colors.black12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s),
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.m),
              Text(
                'Create reminders and schedule tasks quickly using natural language. Try the AI Assistant to plan your day.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSizes.l),
              PrimaryButton(
                label: 'Create with AI',
                icon: Icons.auto_awesome,
                onPressed: () => context.push('/ai-reminder-creation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventsCard(dynamic events, bool isDark) {
    final nextEvent = events.isNotEmpty ? events.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Events',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/events'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        if (nextEvent == null) ...[
          GlassContainer(
            blur: 15,
            opacity: isDark ? 0.04 : 0.08,
            color: isDark ? Colors.black : Colors.white,
            borderColor: isDark ? Colors.white10 : Colors.black12,
            padding: const EdgeInsets.all(AppSizes.m),
            child: const Center(
              child: Text(
                'No events scheduled.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
          ),
        ] else ...[
          GlassContainer(
            blur: 20,
            opacity: isDark ? 0.08 : 0.12,
            color: isDark ? Colors.black : Colors.white,
            borderColor: isDark ? Colors.white10 : Colors.black12,
            padding: const EdgeInsets.all(AppSizes.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nextEvent.color.withValues(alpha: 0.15),
                    border: Border.all(
                      color: nextEvent.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(nextEvent.icon, color: nextEvent.color, size: 22),
                ),
                const SizedBox(width: AppSizes.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextEvent.title,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${nextEvent.dateTime.day}/${nextEvent.dateTime.month}/${nextEvent.dateTime.year} - ${nextEvent.dateTime.hour.toString().padLeft(2, '0')}:${nextEvent.dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nextEvent.location,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
