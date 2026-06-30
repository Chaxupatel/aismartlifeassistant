import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:alarm/alarm.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import 'providers/reminders_provider.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _stopAlarm() async {
    // 1. Stop the ringing audio
    await Alarm.stop(widget.alarmSettings.id);

    // 2. Complete/Delete One Time reminders automatically
    final payloadStr = widget.alarmSettings.payload;
    if (payloadStr != null && payloadStr.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payloadStr);
        final String? reminderId = data['id'];
        if (reminderId != null) {
          final box = Hive.box<Map>('reminders_box');
          final reminderMap = box.get(reminderId);
          if (reminderMap != null) {
            final repeatType = reminderMap['repeatType'] as String? ?? 'One Time';
            if (repeatType == 'One Time') {
              // Trigger Riverpod notifier completion which auto-deletes One Time from database and syncs to cloud
              ref.read(remindersProvider.notifier).toggleReminder(reminderId);
            }
          }
        }
      } catch (e) {
        debugPrint('AlarmRingScreen: Error completing One Time reminder: $e');
      }
    }

    if (mounted) context.pop();
  }

  void _snoozeAlarm() async {
    final now = DateTime.now();
    // Parse snooze duration from JSON payload, fallback to string format
    final payloadStr = widget.alarmSettings.payload;
    int snoozeMinutes = 5;
    if (payloadStr != null && payloadStr.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payloadStr);
        snoozeMinutes = data['snooze'] as int? ?? 5;
      } catch (_) {
        snoozeMinutes = int.tryParse(payloadStr) ?? 5;
      }
    }
    
    final snoozeTime = now.add(Duration(minutes: snoozeMinutes));
    
    final newSettings = widget.alarmSettings.copyWith(
      dateTime: snoozeTime,
    );
    
    await Alarm.set(alarmSettings: newSettings);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for alarm
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3E50), Color(0xFF000000)],
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alarm_on_rounded, size: 80, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
                Text(
                  widget.alarmSettings.notificationSettings.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.s),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.l),
                  child: Text(
                    widget.alarmSettings.notificationSettings.body,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Snooze Button
                    GestureDetector(
                      onTap: _snoozeAlarm,
                      child: GlassContainer(
                        blur: 20,
                        opacity: 0.2,
                        color: Colors.white,
                        borderColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: const Text('Snooze', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: AppSizes.l),
                    
                    // Stop Button
                    GestureDetector(
                      onTap: _stopAlarm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Text('Stop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
