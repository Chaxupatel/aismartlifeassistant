/// Represents a reminder domain entity with custom recurrence schedules and alert configurations.
class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String category;
  final bool isCompleted;
  final String repeatType; // One Time, Daily, Weekly, Monthly, Yearly
  final bool enableNotification;
  final bool enableAlarm;
  final int snoozeDuration; // in minutes
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.category,
    this.isCompleted = false,
    this.repeatType = 'One Time',
    this.enableNotification = true,
    this.enableAlarm = false,
    this.snoozeDuration = 5,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? category,
    bool? isCompleted,
    String? repeatType,
    bool? enableNotification,
    bool? enableAlarm,
    int? snoozeDuration,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatType: repeatType ?? this.repeatType,
      enableNotification: enableNotification ?? this.enableNotification,
      enableAlarm: enableAlarm ?? this.enableAlarm,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the entity into a serialized Map to save in Hive.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted,
      'repeatType': repeatType,
      'enableNotification': enableNotification,
      'enableAlarm': enableAlarm,
      'snoozeDuration': snoozeDuration,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Restores the entity from a serialized Map retrieved from Hive.
  factory Reminder.fromMap(Map<dynamic, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      category: map['category'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      repeatType: map['repeatType'] as String? ?? 'One Time',
      enableNotification: map['enableNotification'] as bool? ?? true,
      enableAlarm: map['enableAlarm'] as bool? ?? false,
      snoozeDuration: map['snoozeDuration'] as int? ?? 5,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.parse(map['dateTime'] as String),
    );
  }
}
