import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:split_trip/core/const/app_string.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';

/// `ad_format` values of the `ad_impression` event.
class AnalyticsAdFormat {
  AnalyticsAdFormat._();
  static const String banner = 'banner';
  static const String native = 'native';
  static const String interstitial = 'interstitial';
  // static const String rewarded = 'rewarded'; // Rewarded removed (not used).
  static const String appOpen = 'app_open';
}

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

  /// Ad revenue: the standard `ad_impression` event (no app prefix — Firebase
  /// and AdMob revenue reports read only this exact name). Call it from every
  /// ad's `onPaidEvent`, i.e. once per paid impression.
  ///
  /// Sends nothing in debug builds or with test ads, and never throws.
  /// Register `ad_placement` and `app_name` as event-scope custom dimensions
  /// in GA4.
  static Future<void> trackAdRevenue({
    required Ad ad,
    required double valueMicros,
    required String currencyCode,
    required String adFormat,
    String? placement,
  }) async {
    final value = valueMicros / 1000000.0;
    final currency = currencyCode.isNotEmpty ? currencyCode : 'USD';
    final adPlacement = placement ?? ad.adUnitId;
    if (kDebugMode || AdUnitIds.testAds || Firebase.apps.isEmpty) {
      debugPrint(
        '[Analytics] (debug/test, not sent) ad_impression | $adFormat | '
        '$adPlacement | $value $currency',
      );
      return;
    }
    try {
      await _analytics.logAdImpression(
        adPlatform: 'AdMob',
        adSource:
            ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName ??
            'unknown',
        adFormat: adFormat,
        adUnitName: ad.adUnitId,
        value: value,
        currency: currency,
        parameters: {
          'ad_placement': adPlacement,
          'app_name': AppString.appname,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] ad_impression failed: $e');
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

  /// `android` / `ios` — sent with the Daily Auto Backup events.
  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Daily Auto Backup turned ON / OFF — `daily_auto_backup_on` /
  /// `daily_auto_backup_off` (GA4 event count = how many times). Also sets
  /// the user property `daily_auto_backup` (`on` / `off`) to split users.
  /// [source] = `settings` / `popup`; [ad] (ON only) = `rewarded`,
  /// `interstitial_fallback` or `no_ad`.
  static Future<void> logDailyAutoBackup({
    required bool enabled,
    required String source,
    String? ad,
  }) async {
    final name = enabled ? "daily_auto_backup_on" : "daily_auto_backup_off";
    debugPrint('[Analytics] $name | source: $source | ad: $ad | $_platform');
    await logEvent(
      name: name,
      parameters: {
        "source": source,
        "ad": ?ad,
        "platform": _platform,
        "app_name": AppString.appname,
      },
    );
    try {
      await _analytics.setUserProperty(
        name: "daily_auto_backup",
        value: enabled ? "on" : "off",
      );
    } catch (e) {
      // Prevent crash
    }
  }

  /// Logs a database backup event.
  static Future<void> logBackup({required bool success, String? error}) async {
    await logEvent(
      name: "backup_to_drive",
      parameters: {"success": success ? 1 : 0, "error": ?error},
    );
  }

  /// Logs a database restore event.
  static Future<void> logRestore({required bool success, String? error}) async {
    await logEvent(
      name: "restore_from_drive",
      parameters: {"success": success ? 1 : 0, "error": ?error},
    );
  }
}
