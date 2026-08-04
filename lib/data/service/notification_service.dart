import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:open_filex/open_filex.dart';

class NotificationService {
  NotificationService._();

  // static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    debugPrint("NotificationService disabled.");
  }

  /// Request notification permission for Android 13+ / iOS when needed (e.g. on Login Screen)
  static Future<void> requestPermission() async {
    debugPrint("NotificationService permission request disabled.");
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint("NotificationService showNotification disabled.");
  }
}
