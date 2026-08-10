import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/providers/reminders_provider.dart';
import '../domain/rule_based_parser.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/no_connection_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/widgets/no_notification_permission_dialog.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final ParsedReminderResult? parsedReminder;
  bool isScheduled;

  ChatMessage({
    required this.text,
    required this.isMe,
    this.parsedReminder,
    this.isScheduled = false,
  });
}

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  // Mock Suggested Reminders
  final List<Map<String, dynamic>> _suggestedReminders = [
    {
      'title': 'Drink 1L Water',
      'category': 'Health',
      'repeat': 'Daily',
      'hour': 14,
      'minute': 0,
      'icon': Icons.water_drop_rounded,
      'color': Colors.tealAccent,
    },
    {
      'title': 'Mid-day Stretch Break',
      'category': 'Health',
      'repeat': 'Daily',
      'hour': 15,
      'minute': 30,
      'icon': Icons.accessibility_new_rounded,
      'color': Colors.greenAccent,
    },
    {
      'title': 'Weekly Goal Planning',
      'category': 'Personal',
      'repeat': 'Weekly',
      'hour': 9,
      'minute': 0,
      'icon': Icons.track_changes_rounded,
      'color': Colors.orangeAccent,
    },
    {
      'title': 'Review Team Tasks',
      'category': 'Work',
      'repeat': 'Daily',
      'hour': 10,
      'minute': 0,
      'icon': Icons.work_outline_rounded,
      'color': Colors.indigoAccent,
    },
  ];

  // Mock Productivity Tips
  final List<Map<String, dynamic>> _productivityTips = [
    {
      'tip': 'You have 3 busy tasks scheduled this afternoon. Set up a deep work focus session to knock them out.',
      'label': 'Schedule 2h Focus Session',
      'title': 'Deep Work Session',
      'category': 'Work',
      'duration': 120,
    },
    {
      'tip': 'Planning tasks the evening before improves next-day execution by 40%. Schedule a tomorrow review block.',
      'label': 'Schedule Review Block',
      'title': 'Tomorrow Task Review',
      'category': 'Personal',
      'duration': 15,
    }
  ];

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      ChatMessage(
        text: 'Hello! I am Remindly, your AI assistant. How can I help organize your schedule today?',
        isMe: false,
      ),
      ChatMessage(
        text: 'Type a message like "remind me to buy groceries tomorrow at 6 PM" to create reminders directly from our conversation!',
        isMe: false,
      ),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialConnection());
  }

  Future<void> _checkInitialConnection() async {
    final isOffline = await ConnectivityService.instance.isOffline();
    if (isOffline && mounted) {
      final connected = await NoConnectionDialog.show(
        context,
        message: 'An active internet connection is required to talk to the AI Assistant. Please turn on your network.',
      );
      if (connected != true && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- ACTIONS ---

  Future<void> _handleQuickAddReminder(Map<String, dynamic> sug) async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    if (!status.isGranted) {
      await NoNotificationPermissionDialog.show(context);
      return;
    }

    final now = DateTime.now();
    var reminderDate = DateTime(now.year, now.month, now.day, sug['hour'] as int, sug['minute'] as int);
    
    // If time is past, set to tomorrow for Daily, else keep it
    if (reminderDate.isBefore(now)) {
      reminderDate = reminderDate.add(const Duration(days: 1));
    }

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: sug['title'] as String,
      dateTime: reminderDate,
      category: sug['category'] as String,
      repeatType: sug['repeat'] as String,
      enableNotification: true,
      enableAlarm: false,
      description: 'Quick-suggested by AI Assistant.',
    );

    ref.read(remindersProvider.notifier).addReminder(reminder);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added Reminder: "${reminder.title}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleProductivityTrigger(Map<String, dynamic> tip) async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    if (!status.isGranted) {
      await NoNotificationPermissionDialog.show(context);
      return;
    }

    final now = DateTime.now();
    // Schedule focus block 5 mins from now
    final startTime = now.add(const Duration(minutes: 5));

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: tip['title'] as String,
      dateTime: startTime,
      category: tip['category'] as String,
      repeatType: 'One Time',
      enableNotification: true,
      enableAlarm: true, // Focus blocks should alarm
      description: 'Productivity block recommended by AI Assistant. Duration: ${tip['duration']} mins.',
    );

    ref.read(remindersProvider.notifier).addReminder(reminder);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduled Productivity Block: "${reminder.title}"'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleConfirmConversationReminder(ChatMessage msg) async {
    final parsed = msg.parsedReminder;
    if (parsed == null || msg.isScheduled) return;

    final status = await Permission.notification.status;
    if (!mounted) return;
    if (!status.isGranted) {
      await NoNotificationPermissionDialog.show(context);
      return;
    }

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: parsed.title,
      dateTime: parsed.dateTime,
      category: parsed.category,
      repeatType: parsed.repeatType,
      enableNotification: parsed.enableNotification,
      enableAlarm: parsed.enableAlarm,
      description: parsed.description,
    );

    ref.read(remindersProvider.notifier).addReminder(reminder);

    setState(() {
      msg.isScheduled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduled Conversational Reminder: "${reminder.title}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // --- SEND CHAT ACTION ---

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final isOffline = await ConnectivityService.instance.isOffline();
    if (isOffline && mounted) {
      await NoConnectionDialog.show(
        context,
        message: 'An active internet connection is required to interact with the AI Assistant. Please turn on your network.',
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
      _textController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Process and respond
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      // Use rule-based parser on user input
      final parsed = RuleBasedParser.parse(text);
      
      // Determine if a meaningful reminder was extracted
      // Check if title is not default, or if keywords match
      final lowerText = text.toLowerCase();
      final hasReminderIntent = lowerText.contains('remind') ||
          lowerText.contains('wake') ||
          lowerText.contains('alarm') ||
          lowerText.contains('alert') ||
          lowerText.contains('schedule');

      setState(() {
        _isTyping = false;
        
        if (hasReminderIntent && parsed.title != 'Reminder' && parsed.title != 'Wake Up') {
          // Found a reminder! Append response with confirmation details
          _messages.add(ChatMessage(
            text: 'I detected a new reminder request in our conversation. Would you like me to schedule this for you?',
            isMe: false,
            parsedReminder: parsed,
          ));
        } else {
          // Conversational reply fallback
          _messages.add(ChatMessage(
            text: _getConversationalReply(text),
            isMe: false,
          ));
        }
      });
      _scrollToBottom();
    });
  }

  String _getConversationalReply(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello there! Let me know if you want to set any reminders, track calendar tasks, or build up your schedule!';
    } else if (lower.contains('productivity') || lower.contains('work')) {
      return 'To optimize productivity, I suggest organizing your tasks by Category (e.g. Work, Personal) and setting aside dedicated Deep Work sessions during your peak energy hours.';
    } else if (lower.contains('cricket') || lower.contains('sports')) {
      return 'I notice you have Cricket matches tracked in your Events section. Ensure you set reminders so you do not miss the match starts!';
    } else {
      return 'I am on it! You can tell me to schedule any task (e.g. "remind me to pay bills on 15th every month") and I will configure it for you.';
    }
  }

  // --- RENDER WIDGETS ---

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
            Text('AI Assistant'),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 100), // App Bar offset

            // 1. TOP PANEL: SUGGESTIONS & PRODUCTIVITY
            _buildInsightsPanel(isDark),

            // 2. MAIN CHAT AREA
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.s),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator(isDark);
                  }

                  final message = _messages[index];
                  return _buildMessageBubble(message, isDark);
                },
              ),
            ),

            // 3. BOTTOM CHAT INPUT BAR
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsPanel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
          child: Text(
            'Smart Recommendations & Insights',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.1,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),

        // Horizontal Slider
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
            children: [
              // SUGGESTED REMINDERS SECTION
              ..._suggestedReminders.map((sug) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: AppSizes.s, bottom: 8),
                  child: GlassContainer(
                    blur: 15,
                    opacity: isDark ? 0.06 : 0.12,
                    color: isDark ? Colors.black : Colors.white,
                    borderColor: isDark ? Colors.white10 : Colors.black12,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(sug['icon'] as IconData, size: 14, color: sug['color'] as Color),
                            const SizedBox(width: 4),
                            Text(
                              sug['category'] as String,
                              style: TextStyle(
                                color: sug['color'] as Color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            sug['title'] as String,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${sug['repeat']} • ${sug['hour'].toString().padLeft(2, '0')}:${sug['minute'].toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontSize: 9,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _handleQuickAddReminder(sug),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // PRODUCTIVITY TIPS SECTION
              ..._productivityTips.map((tip) {
                return Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: AppSizes.s, bottom: 8),
                  child: GlassContainer(
                    blur: 15,
                    opacity: isDark ? 0.08 : 0.15,
                    color: isDark ? Colors.black : Colors.white,
                    borderColor: isDark ? Colors.white10 : Colors.black12,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text(
                              'Productivity Insight',
                              style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            tip['tip'] as String,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            onTap: () => _handleProductivityTrigger(tip),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tip['label'] as String,
                                style: const TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.m),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Standard Text Bubble
            GlassContainer(
              blur: 15,
              opacity: message.isMe
                  ? (isDark ? 0.15 : 0.22)
                  : (isDark ? 0.05 : 0.08),
              color: message.isMe ? AppColors.primary : (isDark ? Colors.black : Colors.white),
              borderColor: message.isMe
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? Colors.white10 : Colors.black12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: 16,
              child: Text(
                message.text,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),

            // Inline parsed reminder card
            if (message.parsedReminder != null) ...[
              const SizedBox(height: 6),
              _buildInlineReminderCard(message, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineReminderCard(ChatMessage message, bool isDark) {
    final parsed = message.parsedReminder!;
    final categoryColor = _getCategoryColor(parsed.category);

    return GlassContainer(
      blur: 20,
      opacity: isDark ? 0.12 : 0.16,
      color: isDark ? Colors.black : Colors.white,
      borderColor: isDark ? Colors.white12 : Colors.black12,
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  parsed.category,
                  style: TextStyle(color: categoryColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  parsed.repeatType,
                  style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            parsed.title,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(width: 4),
              Text(
                '${parsed.dateTime.day}/${parsed.dateTime.month}/${parsed.dateTime.year} at ${TimeOfDay(hour: parsed.dateTime.hour, minute: parsed.dateTime.minute).format(context)}',
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          message.isScheduled
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Scheduled Successfully',
                        style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () => _handleConfirmConversationReminder(message),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 14),
                  label: const Text(
                    'Schedule Reminder',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.m),
        child: GlassContainer(
          blur: 15,
          opacity: isDark ? 0.05 : 0.08,
          color: isDark ? Colors.black : Colors.white,
          borderColor: isDark ? Colors.white10 : Colors.black12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.m),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.xs),
        borderRadius: 24,
        blur: 15,
        opacity: isDark ? 0.1 : 0.15,
        color: isDark ? Colors.black : Colors.white,
        borderColor: isDark ? Colors.white12 : Colors.black12,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ask your assistant anything...',
                  hintStyle: TextStyle(
                    color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.6),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
