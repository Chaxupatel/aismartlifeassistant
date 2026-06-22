import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
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
      child: Column(
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
                Row(
                  children: [
                    if (_isSelectionMode)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.error,
                          size: 28,
                        ),
                        onPressed: _deleteSelected,
                        tooltip: 'Delete Selected',
                      )
                    else ...[
                      IconButton(
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        onPressed: () => context.push('/ai-reminder-creation'),
                        tooltip: 'Create with AI',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () => context.push('/reminders/add'),
                      ),
                    ],
                  ],
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
                      bottom: 120, // Avoid bottom navigation overlap
                    ),
                    itemCount: filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = filteredReminders[index];
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
                            padding: const EdgeInsets.all(AppSizes.m),
                            child: Row(
                              children: [
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
                                            const Icon(
                                              Icons.replay_rounded,
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
