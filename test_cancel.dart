import 'package:flutter_local_notifications/flutter_local_notifications.dart';
void main() {
  final plugin = FlutterLocalNotificationsPlugin();
  plugin.cancel(id: 1);
}
