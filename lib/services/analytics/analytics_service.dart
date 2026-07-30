import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Call this at app launch to configure analytics settings
  static Future<void> init() async {
    try {
      // Disable analytics collection in debug mode
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      // Prevent crash
    }
  }

  /// Returns the FirebaseAnalyticsObserver instance to register in navigatorObservers.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom event.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Prevent crash if analytics log fails
    }
  }

  /// Logs when user signs in.
  static Future<void> logLogin({String loginMethod = "Google"}) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
    } catch (e) {
      // Prevent crash
    }
  }

  /// Logs when user signs out.
  static Future<void> logLogout() async {
    await logEvent(name: "logout");
  }

  /// Logs a database backup event.
  static Future<void> logBackup({required bool success, String? error}) async {
    await logEvent(
      name: "backup_to_drive",
      parameters: {
        "success": success ? 1 : 0,
        if (error != null) "error": error,
      },
    );
  }

  /// Logs a database restore event.
  static Future<void> logRestore({required bool success, String? error}) async {
    await logEvent(
      name: "restore_from_drive",
      parameters: {
        "success": success ? 1 : 0,
        if (error != null) "error": error,
      },
    );
  }
}
