import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/providers/reminders_provider.dart';
import '../domain/rule_based_parser.dart';
import '../../../core/services/interstitial_ad_manager.dart';

class AIReminderCreationScreen extends ConsumerStatefulWidget {
  const AIReminderCreationScreen({super.key});

  @override
  ConsumerState<AIReminderCreationScreen> createState() => _AIReminderCreationScreenState();
}

class _AIReminderCreationScreenState extends ConsumerState<AIReminderCreationScreen> {
  final _inputController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Suggestion examples
  final List<String> _suggestions = [
    'Wake me up every day at 5 AM',
    'Remind me every Monday at 9 AM',
    'Pay electricity bill on 15th every month',
  ];

  // Active values derived from parser / editing
  String _parsedTitle = 'New Reminder';
  String _parsedDescription = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedRepeatType = 'One Time';
  String _selectedCategory = 'General';
  bool _enableNotification = true;
  bool _enableAlarm = false;

  bool _isAdjustmentExpanded = false;

  final List<String> _categories = ['General', 'Work', 'Health', 'Personal', 'Shopping'];
  final List<String> _repeatTypes = ['One Time', 'Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedTitle = 'New Reminder';
        _parsedDescription = '';
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedRepeatType = 'One Time';
        _selectedCategory = 'General';
        _enableNotification = true;
        _enableAlarm = false;

        _titleController.text = '';
        _descController.text = '';
      });
      return;
    }

    // Run rule-based parser in real-time
    final parsed = RuleBasedParser.parse(text);
    setState(() {
      _parsedTitle = parsed.title;
      _parsedDescription = parsed.description;
      _selectedDate = parsed.dateTime;
      _selectedTime = TimeOfDay(hour: parsed.dateTime.hour, minute: parsed.dateTime.minute);
      _selectedRepeatType = parsed.repeatType;
      _selectedCategory = parsed.category;
      _enableNotification = parsed.enableNotification;
      _enableAlarm = parsed.enableAlarm;

      // Sync custom edit controllers
      _titleController.text = _parsedTitle;
      _descController.text = _parsedDescription;
    });
  }

  void _useSuggestion(String text) {
    _inputController.text = text;
    // Position cursor at the end
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
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
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
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
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _parsedTitle;

    final notes = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : _parsedDescription;

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
    );

    // Save reminder using Riverpod and local notification scheduling
    ref.read(remindersProvider.notifier).addReminder(newReminder);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI Reminder Created: "$title"'),
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Reminder Creator'),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSizes.m,
            right: AppSizes.m,
            top: 100, // Spacing for custom header app bar
            bottom: AppSizes.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro text
              Text(
                'Create Reminders using Natural Language',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type or speak how you want to be reminded. The assistant will parse title, date, recurrence, and alerts.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // Input glass block
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                padding: const EdgeInsets.all(AppSizes.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _inputController,
                      maxLines: 3,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Pay electric bill on 15th every month...',
                        hintStyle: TextStyle(
                          color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_inputController.text.length} characters',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // Suggestion chips
              Text(
                'Suggestions',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.s),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                    onPressed: () => _useSuggestion(suggestion),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.l),

              // Realtime Preview Title
              Row(
                children: [
                  const Icon(Icons.preview_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Real-time Parsed Preview',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.s),

              // Preview Glass Card
              GlassContainer(
                blur: 24,
                opacity: isDark ? 0.12 : 0.18,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? const Color(0x33FFFFFF) : const Color(0x22000000),
                padding: const EdgeInsets.all(AppSizes.m + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Category Badge & Recurrence Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(_selectedCategory).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getCategoryColor(_selectedCategory).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedCategory == 'Work'
                                    ? Icons.work_outline
                                    : _selectedCategory == 'Health'
                                        ? Icons.favorite_border
                                        : _selectedCategory == 'Personal'
                                            ? Icons.person_outline
                                            : Icons.tag,
                                size: 12,
                                color: _getCategoryColor(_selectedCategory),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCategory,
                                style: TextStyle(
                                  color: _getCategoryColor(_selectedCategory),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Recurrence Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _selectedRepeatType,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.m),

                    // Title
                    Text(
                      _parsedTitle,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Date & Time Row
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Alerts Trigger Row
                    Row(
                      children: [
                        Icon(
                          _enableAlarm ? Icons.alarm_rounded : Icons.notifications_active_outlined,
                          size: 16,
                          color: _enableAlarm ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _enableAlarm
                              ? 'Loud Alarm Alert (Sound & Heavy Vibration)'
                              : 'Standard System Notification Alert',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    if (_parsedDescription.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.04 : 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _parsedDescription,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // Expandable adjustment details section
              ExpansionPanelList(
                elevation: 0,
                expandedHeaderPadding: EdgeInsets.zero,
                children: [
                  ExpansionPanel(
                    backgroundColor: Colors.transparent,
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: isDark ? Colors.white60 : Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Adjust Parsed Details',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    body: GlassContainer(
                      blur: 15,
                      opacity: isDark ? 0.05 : 0.08,
                      color: isDark ? Colors.black : Colors.white,
                      borderColor: isDark ? Colors.white10 : Colors.black12,
                      padding: const EdgeInsets.all(AppSizes.m),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom Title Input
                          CustomTextField(
                            controller: _titleController,
                            labelText: 'Edit Title',
                            prefixIcon: Icons.edit_note_rounded,
                            onChanged: (val) {
                              setState(() {
                                _parsedTitle = val.trim().isNotEmpty ? val.trim() : 'New Reminder';
                              });
                            },
                          ),
                          const SizedBox(height: AppSizes.m),

                          // Custom Description Input
                          CustomTextField(
                            controller: _descController,
                            labelText: 'Edit Notes / Description',
                            prefixIcon: Icons.description_outlined,
                            onChanged: (val) {
                              setState(() {
                                _parsedDescription = val.trim();
                              });
                            },
                          ),
                          const SizedBox(height: AppSizes.m),

                          // Date and Time Pickers
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                  ),
                                  onPressed: _selectDate,
                                  icon: const Icon(Icons.date_range_rounded, size: 16),
                                  label: Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.s),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                  ),
                                  onPressed: _selectTime,
                                  icon: const Icon(Icons.access_time_rounded, size: 16),
                                  label: Text(
                                    _selectedTime.format(context),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.m),

                          // Category and Repeat selection
                          Row(
                            children: [
                              // Category
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primary),
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
                              // Repeat Type
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedRepeatType,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Repeat',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primary),
                                    ),
                                  ),
                                  dropdownColor: isDark ? Colors.black87 : Colors.white,
                                  items: _repeatTypes.map((rep) {
                                    return DropdownMenuItem(value: rep, child: Text(rep));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedRepeatType = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.m),

                          // Toggles
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Alarm Alert', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Triggers maximum sound and custom vibration patterns.', style: TextStyle(fontSize: 11)),
                            value: _enableAlarm,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _enableAlarm = val;
                                if (val) {
                                  _enableNotification = false;
                                } else {
                                  _enableNotification = true;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    isExpanded: _isAdjustmentExpanded,
                  ),
                ],
                expansionCallback: (panelIndex, isExpanded) {
                  setState(() {
                    _isAdjustmentExpanded = isExpanded;
                  });
                },
              ),
              const SizedBox(height: AppSizes.xl),

              // Confirm and save button
              PrimaryButton(
                label: 'Create Reminder',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _inputController.text.trim().isEmpty ? null : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
