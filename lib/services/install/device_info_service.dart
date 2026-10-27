import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Device / app details sent with the install report.
class DeviceInfoService {
  DeviceInfoService._internal();
  static final DeviceInfoService instance = DeviceInfoService._internal();

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfoPlugin = DeviceInfoPlugin();

      String platform = 'android';
      String osVersion = 'unknown';
      String deviceModel = 'unknown';

      if (Platform.isAndroid) {
        platform = 'android';
        final androidInfo = await deviceInfoPlugin.androidInfo;
        osVersion = androidInfo.version.release;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}'.trim();
      } else if (Platform.isIOS) {
        platform = 'ios';
        final iosInfo = await deviceInfoPlugin.iosInfo;
        osVersion = iosInfo.systemVersion;
        // deviceModel = iosInfo.model;
        // Hardware id (e.g. "iPhone15,2") — `model` is only "iPhone".
        deviceModel = iosInfo.utsname.machine;
      }

      return {
        // Detected, never hard-coded, so the right app is always reported.
        'packageName': packageInfo.packageName,
        'platform': platform,
        'appVersion': packageInfo.version,
        'osVersion': osVersion,
        'deviceModel': deviceModel,
        'timezone': DateTime.now().timeZoneName,
      };
    } catch (e) {
      debugPrint('[DeviceInfoService] ⚠️ Error fetching device info: $e');
      return {
        'packageName': '',
        'platform': Platform.isIOS ? 'ios' : 'android',
        'appVersion': '1.0.0',
        'osVersion': 'unknown',
        'deviceModel': 'unknown',
        'timezone': DateTime.now().timeZoneName,
      };
    }
  }
}
