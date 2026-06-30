import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/glass_native_ad_widget.dart';
import 'providers/reminders_provider.dart';

/// Screen listing all tasks and reminders.
class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Periodic timer to rebuild UI and keep countdowns current
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getRemainingTimeText(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);
    
    if (difference.isNegative) {
      return '';
    }
    
    if (difference.inDays > 0) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      return 'Starts in ${days}d ${hours}h';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return 'Starts in ${hours}h ${minutes}m';
    } else if (difference.inMinutes > 0) {
      return 'Starts in ${difference.inMinutes}m';
    } else {
      final seconds = difference.inSeconds;
      return seconds > 0 ? 'Starts in ${seconds}s' : 'Starting now';
    }
  }

  int get _adInterval => 5;

  int _getListItemCount(int remindersCount) {
    if (remindersCount == 0) return 0;
    return remindersCount + (remindersCount / _adInterval).floor();
  }

  bool _isAdIndex(int index) {
    return (index + 1) % (_adInterval + 1) == 0;
  }

  int _getReminderIndex(int index) {
    return index - (index / (_adInterval + 1)).floor();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected() {
    if (_selectedIds.isNotEmpty) {
      ref.read(remindersProvider.notifier).deleteMultipleReminders(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected reminders deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch reminders state from Riverpod
    final reminders = ref.watch(remindersProvider);

    // Filter reminders based on search query
    final filteredReminders = reminders.where((reminder) {
      return reminder.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return GradientBackground(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.s),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminders',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_isSelectionMode)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                    onPressed: _deleteSelected,
                    tooltip: 'Delete Selected',
                  ),
              ],
            ),
          ),

          // Search / Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.xs),
              borderRadius: 12,
              blur: 10,
              opacity: isDark ? 0.05 : 0.08,
              color: isDark ? Colors.black : Colors.white,
              borderColor: isDark ? Colors.white10 : Colors.black12,
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.s),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 14,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search reminders...',
                        hintStyle: TextStyle(
                          color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.m),

          // Reminders List view
          Expanded(
            child: filteredReminders.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty ? 'No reminders available.' : 'No matches found.',
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
                      bottom: 190, // Avoid bottom navigation and ad overlap
                    ),
                    itemCount: _getListItemCount(filteredReminders.length),
                    itemBuilder: (context, index) {
                      if (_isAdIndex(index)) {
                        return GlassNativeAdWidget.small();
                      }
                      final reminderIndex = _getReminderIndex(index);
                      final reminder = filteredReminders[reminderIndex];
                      final isSelected = _selectedIds.contains(reminder.id);
                      
                      return GestureDetector(
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedIds.add(reminder.id);
                            });
                          }
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(reminder.id);
                          } else {
                            context.push('/reminders/${reminder.id}');
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSizes.m),
                          child: GlassContainer(
                            blur: 15,
                            opacity: isDark ? 0.06 : 0.1,
                            color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark ? Colors.black : Colors.white),
                            borderColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : (isDark ? Colors.white10 : Colors.black12),
                            padding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  bottom: -15,
                                  child: Icon(
                                    _getRecurrenceWatermarkIcon(reminder.repeatType),
                                    size: 90,
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(AppSizes.m),
                                  child: Row(
                                    children: [
                                      _buildRecurrenceLeftDecorator(reminder.repeatType, isDark),
                                      if (_isSelectionMode)
                                        Padding(
                                          padding: const EdgeInsets.only(right: AppSizes.m),
                                          child: Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: isSelected ? AppColors.primary : (isDark ? Colors.white38 : Colors.black38),
                                          ),
                                        )
                                      else
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
                                          ),
                                        ),
                                      if (!_isSelectionMode)
                                        const SizedBox(width: AppSizes.m),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.title,
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                                          decorationColor: isDark ? Colors.white60 : Colors.black45,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${reminder.dateTime.day}/${reminder.dateTime.month}/${reminder.dateTime.year} - ${reminder.dateTime.hour.toString().padLeft(2, '0')}:${reminder.dateTime.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (reminder.repeatType != 'One Time') ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              _getRecurrenceMicroIcon(reminder.repeatType),
                                              size: 12,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              reminder.repeatType,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          if (reminder.enableNotification || reminder.enableAlarm) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              reminder.enableAlarm ? Icons.alarm_rounded : Icons.notifications_active_outlined,
                                              size: 12,
                                              color: isDark ? Colors.white38 : Colors.black38,
                                            ),
                                          ],
                                        ],
                                      ),
                                        if (!reminder.isCompleted && reminder.dateTime.isAfter(DateTime.now())) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.timelapse_rounded,
                                                size: 12,
                                                color: AppColors.accent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getRemainingTimeText(reminder.dateTime),
                                                style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSizes.s),
                                
                                // Tag Label
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
          
      // Floating Action Buttons (Above bottom navigation bar)
      if (!_isSelectionMode)
            Positioned(
              left: AppSizes.m,
              right: AppSizes.m,
              bottom: 155, // Positioned safely above the glass navigation capsule and ad banner
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // AI Button
                  GestureDetector(
                    onTap: () => context.push('/ai-reminder-creation'),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  
                  // Add Button
                  GestureDetector(
                    onTap: () => context.push('/reminders/add'),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRecurrenceWatermarkIcon(String repeatType) {
    switch (repeatType) {
      case 'Daily':
        return Icons.autorenew_rounded;
      case 'Weekly':
        return Icons.calendar_view_week_rounded;
      case 'Monthly':
        return Icons.calendar_month_rounded;
      case 'Yearly':
        return Icons.auto_awesome_rounded;
      case 'One Time':
      default:
        return Icons.alarm_rounded;
    }
  }

  Widget _buildRecurrenceLeftDecorator(String repeatType, bool isDark) {
    switch (repeatType) {
      case 'Daily':
        return Container(
          width: 5,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.cyanAccent, AppColors.primary],
            ),
          ),
        );
      case 'Weekly':
        return Container(
          width: 5,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purpleAccent, Colors.pinkAccent],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (_) => Container(width: 4, height: 2, color: isDark ? Colors.black38 : Colors.white60)),
          ),
        );
      case 'Monthly':
        return Container(
          width: 8,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 2, height: 28, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(1))),
              Container(width: 2, height: 28, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(1))),
            ],
          ),
        );
      case 'Yearly':
        return Container(
          width: 12,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                child: Icon(Icons.star_rounded, size: 10, color: Colors.amber),
              ),
            ],
          ),
        );
      case 'One Time':
      default:
        return Container(
          width: 4,
          height: 20,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    }
  }

  IconData _getRecurrenceMicroIcon(String repeatType) {
    switch (repeatType) {
      case 'Daily':
        return Icons.sync_rounded;
      case 'Weekly':
        return Icons.view_week_rounded;
      case 'Monthly':
        return Icons.calendar_month_rounded;
      case 'Yearly':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.replay_rounded;
    }
  }
}
