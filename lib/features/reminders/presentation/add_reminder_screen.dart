import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../domain/reminder.dart';
import 'providers/reminders_provider.dart';
import '../../../core/services/interstitial_ad_manager.dart';

/// Screen to create a new task reminder.
class AddReminderScreen extends ConsumerStatefulWidget {
  final String? prefilledTitle;
  final DateTime? prefilledDateTime;
  final String? prefilledCategory;
  final String? prefilledDescription;

  const AddReminderScreen({
    super.key,
    this.prefilledTitle,
    this.prefilledDateTime,
    this.prefilledCategory,
    this.prefilledDescription,
  });

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String _selectedCategory = 'General';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  // Recurrence & Alarm Options
  String _selectedRepeatType = 'One Time';
  bool _enableNotification = true;
  bool _enableAlarm = false;
  int _snoozeDuration = 5;

  final List<String> _categories = ['General', 'Work', 'Health', 'Personal', 'Shopping'];
  final List<int> _snoozeOptions = [5, 10, 15, 30];
  final List<String> _repeatTypes = ['One Time', 'Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prefilledTitle ?? '');
    _descController = TextEditingController(text: widget.prefilledDescription ?? '');
    
    if (widget.prefilledCategory != null && _categories.contains(widget.prefilledCategory)) {
      _selectedCategory = widget.prefilledCategory!;
    }
    
    if (widget.prefilledDateTime != null) {
      _selectedDate = widget.prefilledDateTime!;
      _selectedTime = TimeOfDay.fromDateTime(widget.prefilledDateTime!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final notes = _descController.text;
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newReminder = Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: notes.isNotEmpty ? notes : null,
        dateTime: finalDateTime,
        category: _selectedCategory,
        isCompleted: false,
        repeatType: _selectedRepeatType,
        enableNotification: _enableNotification,
        enableAlarm: _enableAlarm,
        snoozeDuration: _snoozeDuration,
      );

      // Add to shared riverpod state
      ref.read(remindersProvider.notifier).addReminder(newReminder);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder Saved Successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      InterstitialAdManager.instance.checkAndShowAd(
        context,
        onComplete: () {
          if (mounted) {
            context.pop();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Reminder'),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSizes.m,
            right: AppSizes.m,
            top: AppSizes.l,
            bottom: 190, // Ensure bottom content is scrollable above navigation capsule and ad banner
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100), // Spacing for AppBar
                
                // Form Container
                GlassContainer(
                  blur: 20,
                  opacity: isDark ? 0.08 : 0.12,
                  color: isDark ? Colors.black : Colors.white,
                  borderColor: isDark ? Colors.white12 : Colors.black12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Textfield
                      CustomTextField(
                        controller: _titleController,
                        labelText: 'Title',
                        prefixIcon: Icons.edit_note_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a reminder title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.m),
                      
                      // Notes Textfield
                      CustomTextField(
                        controller: _descController,
                        labelText: 'Notes/Description',
                        prefixIcon: Icons.description_outlined,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: AppSizes.m),

                      // Date Picker Row
                      _buildSelectorRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        onTap: _selectDate,
                      ),
                      const Divider(),

                      // Time Picker Row
                      _buildSelectorRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: _selectedTime.format(context),
                        onTap: _selectTime,
                      ),
                      const Divider(),

                      // Repeat Schedule Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.replay_rounded, size: 20, color: isDark ? Colors.white60 : Colors.black54),
                                const SizedBox(width: AppSizes.s),
                                Text(
                                  'Repeat',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            DropdownButton<String>(
                              value: _selectedRepeatType,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              dropdownColor: isDark ? Colors.black87 : Colors.white,
                              items: _repeatTypes.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRepeatType = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Notification Toggle Row
                      _buildSwitchRow(
                        icon: Icons.notifications_active_outlined,
                        label: 'Push Notification',
                        value: _enableNotification,
                        onChanged: (val) {
                          setState(() {
                            _enableNotification = val;
                          });
                        },
                        isDark: isDark,
                      ),
                      const Divider(),

                      // Alarm Toggle Row
                      _buildSwitchRow(
                        icon: Icons.alarm_rounded,
                        label: 'Set Alarm Alert',
                        value: _enableAlarm,
                        onChanged: (val) {
                          setState(() {
                            _enableAlarm = val;
                          });
                        },
                        isDark: isDark,
                      ),
                      
                      // Snooze Duration (Visible only if alarm is enabled)
                      if (_enableAlarm) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.snooze_rounded, size: 20, color: isDark ? Colors.white60 : Colors.black54),
                                  const SizedBox(width: AppSizes.s),
                                  Text(
                                    'Snooze Duration',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<int>(
                                value: _snoozeDuration,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                dropdownColor: isDark ? Colors.black87 : Colors.white,
                                items: _snoozeOptions.map((duration) {
                                  return DropdownMenuItem(
                                    value: duration,
                                    child: Text('$duration mins'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _snoozeDuration = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.m),

                // Category Selector
                Text(
                  'Select Category',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.s),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSizes.s),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Save button
                PrimaryButton(
                  label: 'Save Reminder',
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
                const SizedBox(width: AppSizes.s),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
              const SizedBox(width: AppSizes.s),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
