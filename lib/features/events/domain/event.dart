import 'package:flutter/material.dart';

/// Represents a scheduled life event, meeting, or personal milestone.
class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String type; // e.g. Social, Work, Travel
  final IconData icon;
  final Color color;

  const Event({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.type,
    required this.icon,
    required this.color,
  });

  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? location,
    String? type,
    IconData? icon,
    Color? color,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
