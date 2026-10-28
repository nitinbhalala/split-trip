import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:split_trip/data/service/pref_keys.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/install/device_info_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Reports a new install to the app panel once (Android and iOS).
///
/// Skipped in debug builds and while test ads are on. A failed call saves
/// nothing, so it is retried on the next app start.
class AppInstallService {
  AppInstallService._internal();
  static final AppInstallService instance = AppInstallService._internal();

  static const String _endpoint =
      'https://api-app-panel.rudramjari.com/api/app-installs';

  bool _isTracking = false;

  /// Calls POST /app-installs once when app installs or first opens.
  Future<void> trackAppInstall() async {
    // if (kDebugMode) {
    //   debugPrint(
    //     '[AppInstallService] ℹ️ Install tracking skipped '
    //     '(debug build).',
    //   );
    if (kDebugMode || AdUnitIds.testAds) {
      debugPrint(
        '[AppInstallService] ℹ️ Install tracking skipped '
        '(debug/test ads enabled).',
      );
      return;
    }
    if (_isTracking) return;
    if (!Get.isRegistered<SharedPreferencesService>()) return;
    _isTracking = true;

    HttpClient? client;
    try {
      final prefs = Get.find<SharedPreferencesService>();

      // 1. Check if already successfully tracked
      if (prefs.getBool(PrefKeys.appInstallCalled)) {
        debugPrint(
          '[AppInstallService] ℹ️ App install already tracked. Skipping.',
        );
        return;
      }

      // 2. Retrieve or generate permanent installId
      String installId = prefs.getString(PrefKeys.installId);
      if (installId.isEmpty) {
        installId = _uuidV4();
        await prefs.setString(PrefKeys.installId, installId);
      }

      // 3. Fetch device info
      final deviceInfo = await DeviceInfoService.instance.getDeviceInfo();

      // 4. Construct payload
      final requestBody = <String, dynamic>{
        'installId': installId,
        'packageName': deviceInfo['packageName'],
        'platform': deviceInfo['platform'],
        'appVersion': deviceInfo['appVersion'],
        'osVersion': deviceInfo['osVersion'],
        'deviceModel': deviceInfo['deviceModel'],
        'timezone': deviceInfo['timezone'],
      };

      debugPrint('[AppInstallService] 📡 Tracking install -> $_endpoint');
      debugPrint(
        '[AppInstallService] 📤 Request Body: ${jsonEncode(requestBody)}',
      );

      // 5. Send POST request
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client
          .postUrl(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 5));

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('[AppInstallService] 📥 Status Code: ${response.statusCode}');
      debugPrint('[AppInstallService] 📥 Raw Response: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final status = decoded['data']?['status']?.toString() ?? 'TRACKED';
          debugPrint('[AppInstallService] ✅ Install tracked status: $status');
        } catch (_) {}

        // Mark as called so subsequent app launches won't re-track
        await prefs.setBool(PrefKeys.appInstallCalled, true);
      } else {
        debugPrint(
          '[AppInstallService] ⚠️ Non-200 response from server: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[AppInstallService] ❌ Failed to track app install: $e');
    } finally {
      client?.close();
      _isTracking = false;
    }
  }

  /// Reset the app install flag (for testing purposes)
  Future<void> resetAppInstallFlag() async {
    if (!Get.isRegistered<SharedPreferencesService>()) return;
    await Get.find<SharedPreferencesService>().setBool(
      PrefKeys.appInstallCalled,
      false,
    );
    debugPrint('[AppInstallService] 🔄 Reset app install flag.');
  }

  /// Random UUID v4 (RFC 4122).
  static String _uuidV4() {
    final rnd = Random.secure();
    final b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
