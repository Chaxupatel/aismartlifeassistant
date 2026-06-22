class ParsedReminderResult {
  final String title;
  final DateTime dateTime;
  final String repeatType; // One Time, Daily, Weekly, Monthly, Yearly
  final bool enableNotification;
  final bool enableAlarm;
  final String category;
  final String description;

  ParsedReminderResult({
    required this.title,
    required this.dateTime,
    required this.repeatType,
    required this.enableNotification,
    required this.enableAlarm,
    required this.category,
    required this.description,
  });

  @override
  String toString() {
    return 'ParsedReminderResult(title: $title, dateTime: $dateTime, repeatType: $repeatType, notification: $enableNotification, alarm: $enableAlarm, category: $category)';
  }
}

class RuleBasedParser {
  /// Parses a natural language sentence into a [ParsedReminderResult].
  static ParsedReminderResult parse(String text) {
    final originalText = text;
    String workingText = text.trim();
    String lower = workingText.toLowerCase();

    // 1. Detect Alert Type (Alarm vs Notification)
    // Default: notification enabled, alarm disabled
    bool enableAlarm = false;
    bool enableNotification = true;

    final alarmKeywords = ['alarm', 'wake me up', 'wake up', 'wake me', 'alert me'];
    for (final keyword in alarmKeywords) {
      if (lower.contains(keyword)) {
        enableAlarm = true;
        enableNotification = false; // Louder alarm preferred
        break;
      }
    }

    // 2. Parse Recurrence (Repeat Type)
    String repeatType = 'One Time';
    int? targetWeekday; // Monday = 1, Sunday = 7
    int? targetDayOfMonth;

    // Detect Weekdays (Monday to Sunday)
    final weekdayMap = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    if (lower.contains('every day') || lower.contains('everyday') || lower.contains('daily')) {
      repeatType = 'Daily';
    } else if (lower.contains('every month') || lower.contains('monthly')) {
      repeatType = 'Monthly';
    } else if (lower.contains('every year') || lower.contains('yearly') || lower.contains('annually')) {
      repeatType = 'Yearly';
    } else {
      // Check for weekly recurrence e.g. "every Monday", "on Mondays"
      for (final entry in weekdayMap.entries) {
        final day = entry.key;
        if (lower.contains('every $day') || lower.contains('on ${day}s') || lower.contains('each $day')) {
          repeatType = 'Weekly';
          targetWeekday = entry.value;
          break;
        }
      }
    }

    // If repeat is still One Time, check if a specific weekday is mentioned without "every"
    // e.g. "Remind me on Monday" -> One Time reminder, but on next Monday
    if (repeatType == 'One Time') {
      for (final entry in weekdayMap.entries) {
        final day = entry.key;
        if (RegExp('\\bon\\s+$day\\b').hasMatch(lower) || RegExp('\\bthis\\s+$day\\b').hasMatch(lower) || RegExp('\\bnext\\s+$day\\b').hasMatch(lower)) {
          targetWeekday = entry.value;
          break;
        }
      }
    }

    // Parse Day of Month (e.g. "on 15th", "on the 15th", "on 15")
    final dayOfMonthRegex = RegExp(r'\bon\s+(the\s+)?(\d{1,2})(st|nd|rd|th)?\b');
    final dayOfMonthMatch = dayOfMonthRegex.firstMatch(lower);
    if (dayOfMonthMatch != null) {
      targetDayOfMonth = int.tryParse(dayOfMonthMatch.group(2) ?? '');
      // If it contains "every month" or "monthly", we ensure repeatType is Monthly
      if (lower.contains('month') || lower.contains('monthly')) {
        repeatType = 'Monthly';
      }
    }

    // 3. Parse Time (hour and minute)
    int hour = 9; // Default: 9 AM
    int minute = 0;

    // Pattern 1: HH:MM AM/PM or HH:MM (e.g., 5:30 PM, 14:30, 9:00 am)
    final timePattern1 = RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm)?\b');
    // Pattern 2: H AM/PM (e.g., 5 AM, 12 pm, 9am)
    final timePattern2 = RegExp(r'\b(\d{1,2})\s*(am|pm)\b');
    // Pattern 3: at H (e.g., at 5, at 14)
    final timePattern3 = RegExp(r'\bat\s+(\d{1,2})\b');

    var match = timePattern1.firstMatch(lower);
    if (match != null) {
      final h = int.tryParse(match.group(1) ?? '') ?? 9;
      final m = int.tryParse(match.group(2) ?? '') ?? 0;
      final amPm = match.group(3);
      hour = h;
      minute = m;
      if (amPm == 'pm' && hour < 12) hour += 12;
      if (amPm == 'am' && hour == 12) hour = 0;
    } else {
      match = timePattern2.firstMatch(lower);
      if (match != null) {
        final h = int.tryParse(match.group(1) ?? '') ?? 9;
        final amPm = match.group(2);
        hour = h;
        minute = 0;
        if (amPm == 'pm' && hour < 12) hour += 12;
        if (amPm == 'am' && hour == 12) hour = 0;
      } else {
        match = timePattern3.firstMatch(lower);
        if (match != null) {
          final h = int.tryParse(match.group(1) ?? '') ?? 9;
          hour = h;
          minute = 0;
          // If no AM/PM, make a smart guess:
          // If it is 1 to 6, they probably mean PM (e.g. at 5 -> 5 PM / 17:00), unless it is "wake me up" (then 5 AM).
          if (hour <= 6) {
            if (enableAlarm) {
              // AM for waking up
            } else {
              hour += 12; // PM for standard reminders
            }
          }
        }
      }
    }

    // 4. Resolve Date (DateTime calculation)
    final now = DateTime.now();
    DateTime targetDate = DateTime(now.year, now.month, now.day);

    if (lower.contains('tomorrow')) {
      targetDate = targetDate.add(const Duration(days: 1));
    } else if (targetWeekday != null) {
      // Find the next occurrence of this weekday
      int daysToAdd = targetWeekday - now.weekday;
      if (daysToAdd <= 0) {
        daysToAdd += 7; // Must be in the future
      }
      targetDate = targetDate.add(Duration(days: daysToAdd));
    } else if (targetDayOfMonth != null) {
      // Set to the target day of the current month
      // Check if it's a valid day for this month (e.g. Feb 30th)
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final safeDay = targetDayOfMonth.clamp(1, daysInMonth);
      
      targetDate = DateTime(now.year, now.month, safeDay);
      // If the date is in the past, schedule for the next month
      if (targetDate.isBefore(DateTime(now.year, now.month, now.day))) {
        targetDate = DateTime(now.year, now.month + 1, safeDay);
      }
    }

    // Combine Date and Time
    DateTime finalDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // If it's a one-time reminder and the final time is in the past for today, push to tomorrow
    if (repeatType == 'One Time' && finalDateTime.isBefore(now) && !lower.contains('tomorrow') && targetWeekday == null && targetDayOfMonth == null) {
      finalDateTime = finalDateTime.add(const Duration(days: 1));
    }

    // 5. Clean Title (Extract core reminder title)
    // Create a list of patterns to remove
    final removePatterns = [
      // Helpers
      RegExp(r'\b(please\s+)?(remind\s+me\s+to|remind\s+me|wake\s+me\s+up\s+to|wake\s+me\s+up|wake\s+me\s+at|wake\s+me|set\s+an\s+alarm\s+for|alert\s+me\s+to|alert\s+me)\b', caseSensitive: false),
      // Recurrence
      RegExp(r'\b(every\s+day|everyday|daily|every\s+month|monthly|every\s+year|yearly|annually)\b', caseSensitive: false),
      RegExp(r'\b(every|on|each)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)s?\b', caseSensitive: false),
      // Time
      RegExp(r'\bat\s+\d{1,2}(:\d{2})?\s*(am|pm)?\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}(:\d{2})?\s*(am|pm)\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}(:\d{2})?\b', caseSensitive: false),
      // Date phrases
      RegExp(r'\btomorrow\b', caseSensitive: false),
      RegExp(r'\bon\s+(the\s+)?\d{1,2}(st|nd|rd|th)?(\s+every\s+month)?\b', caseSensitive: false),
      RegExp(r'\b(on|this|next)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false),
      // Leftovers
      RegExp(r'\b(at|on|for|to|the)\b$', caseSensitive: false),
    ];

    String title = workingText;
    for (final pattern in removePatterns) {
      title = title.replaceAll(pattern, '');
    }

    // Strip multiple spaces, trailing/leading punctuation
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title.replaceAll(RegExp(r'^[,\.\s]+|[,\.\s]+$'), '');

    // Edge Cases: If title is empty or extremely short, guess based on input context
    if (title.isEmpty || title.length < 2) {
      if (enableAlarm) {
        title = 'Wake Up';
      } else {
        title = 'Reminder';
      }
    } else {
      // Capitalize first letter
      title = title[0].toUpperCase() + title.substring(1);
    }

    // 6. Category classification using RegExp word boundaries
    String category = 'General';
    final workRegex = RegExp(r'\b(work|office|meeting|sync|team|standup|review|feedback|code|email|client|project|presentation|report|job)\b', caseSensitive: false);
    final healthRegex = RegExp(r'\b(gym|workout|exercise|run|walk|doctor|appointment|checkup|medicine|pill|pills|health|yoga|dentist|meds|training)\b', caseSensitive: false);
    final personalRegex = RegExp(r'\b(buy|pay|bill|shopping|grocery|groceries|dinner|lunch|coffee|friend|family|mom|dad|birthday|gift|clean|laundry|electricity|rent|water|gas)\b', caseSensitive: false);

    final lowerTitle = title.toLowerCase();
    
    if (workRegex.hasMatch(lowerTitle) || workRegex.hasMatch(lower)) {
      category = 'Work';
    } else if (healthRegex.hasMatch(lowerTitle) || healthRegex.hasMatch(lower)) {
      category = 'Health';
    } else if (personalRegex.hasMatch(lowerTitle) || personalRegex.hasMatch(lower)) {
      category = 'Personal';
    }

    return ParsedReminderResult(
      title: title,
      dateTime: finalDateTime,
      repeatType: repeatType,
      enableNotification: enableNotification,
      enableAlarm: enableAlarm,
      category: category,
      description: 'Automatically parsed from voice/text input: "$originalText"',
    );
  }
}
