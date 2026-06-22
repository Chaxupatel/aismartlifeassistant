import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../domain/event.dart';
import 'providers/events_provider.dart';

/// Screen representing life events, social gatherings, and user milestones.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Cricket Matches',
    'Movies',
    'OTT Releases',
    'Birthdays',
    'Holidays',
  ];

  String _getCountdownText(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 0) {
      return 'Passed';
    } else if (difference < 30) {
      return 'In $difference days';
    } else {
      final months = (difference / 30).floor();
      if (months == 1) {
        return 'In 1 month';
      }
      return 'In $months months';
    }
  }

  Color _getBadgeColor(String status) {
    if (status == 'Today') {
      return AppColors.error;
    } else if (status == 'Tomorrow') {
      return AppColors.warning;
    } else if (status == 'Passed') {
      return Colors.grey;
    } else {
      return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch the events list state from Riverpod
    final events = ref.watch(eventsProvider);

    // Filter events based on selected category
    final filteredEvents = _selectedCategory == 'All'
        ? events
        : events.where((e) => e.type == _selectedCategory).toList();

    // Sort events so that closer ones come first
    final sortedEvents = List<Event>.from(filteredEvents)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return GradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.s),
            child: Text(
              'Explore Events',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Horizontal Category Pills
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.s, bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white10 : Colors.black12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.s),

          // Events lists
          Expanded(
            child: sortedEvents.isEmpty
                ? Center(
                    child: Text(
                      'No events scheduled in this category.',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppSizes.m,
                      right: AppSizes.m,
                      bottom: 120, // Prevents bottom navigation overlap
                    ),
                    itemCount: sortedEvents.length,
                    itemBuilder: (context, index) {
                      final event = sortedEvents[index];
                      final color = event.color;
                      final icon = event.icon;
                      final countdown = _getCountdownText(event.dateTime);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.m),
                        child: GlassContainer(
                          blur: 20,
                          opacity: isDark ? 0.08 : 0.12,
                          color: isDark ? Colors.black : Colors.white,
                          borderColor: isDark ? Colors.white10 : Colors.black12,
                          padding: const EdgeInsets.all(AppSizes.m),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event Category Icon Indicator
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSizes.m),
                              
                              // Event texts
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          size: 12,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} - ${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            style: TextStyle(
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                              const SizedBox(width: AppSizes.s),

                              // Time Countdown Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getBadgeColor(countdown).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getBadgeColor(countdown).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  countdown,
                                  style: TextStyle(
                                    color: _getBadgeColor(countdown),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
