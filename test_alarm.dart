import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
void main() {
  final details = AndroidNotificationDetails(
    'alarms_channel_v2',
    'Alarms V2',
    fullScreenIntent: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    category: AndroidNotificationCategory.alarm,
    additionalFlags: Int32List.fromList(<int>[4]),
  );
  print(details.category);
}
