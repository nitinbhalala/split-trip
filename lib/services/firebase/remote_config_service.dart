import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Ad frequencies controlled from Firebase Remote Config.
///
/// Values last fetched are cached on the device by Remote Config itself, so a
/// launch without internet still uses them. Before the first successful fetch
/// the defaults below apply.
class RemoteConfigService {
  RemoteConfigService._();

  /// Interstitial on a direct app open (cold start): shown on every Nth launch.
  static const String keyOpen = 'splittrip_open';

  /// App Open ad on return from recents: shown on every Nth return.
  static const String keyRecentApp = 'splittrip_recent_app';

  /// Interstitial on every Nth back (← icon or system back).
  static const String keyBack = 'splittrip_back';

  // Removed — theme change now shows its ad on every change; save/cancel
  // and delete have no ad.
  // /// Interstitial on every Nth ✕ cancel / ✓ save tap (one shared count).
  // static const String keySaveCancel = 'splittrip_save_cancel';
  //
  // /// Interstitial on every Nth delete (before the item is deleted).
  // static const String keyDelete = 'splittrip_delete';
  //
  // /// Interstitial on every Nth theme change (before the theme is applied).
  // static const String keyThemeChange = 'splittrip_theme_change';

  // Used only when nothing was ever fetched and nothing is cached. Otherwise
  // the cached value, or the live Firebase value once fetched, is used.
  static const int _defaultOpen = 1;
  static const int _defaultRecentApp = 1;
  static const int _defaultBack = 3;
  // static const int _defaultSaveCancel = 3;
  // static const int _defaultDelete = 1;
  // static const int _defaultThemeChange = 1;

  static FirebaseRemoteConfig? _rc;

  /// Activates the cached values right away (no network wait on startup),
  /// then fetches fresh ones in the background. A fresh value is used from
  /// its next read on.
  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );
      await rc.setDefaults(const {
        keyOpen: _defaultOpen,
        keyRecentApp: _defaultRecentApp,
        keyBack: _defaultBack,
        // keySaveCancel: _defaultSaveCancel,
        // keyDelete: _defaultDelete,
        // keyThemeChange: _defaultThemeChange,
      });
      await rc.activate();
      _rc = rc;
      _log('cached');
      unawaited(
        rc
            .fetchAndActivate()
            .then((_) => _log('fetched'))
            .catchError((e) => debugPrint('[RemoteConfig] fetch failed: $e')),
      );
    } catch (e) {
      debugPrint('[RemoteConfig] init failed, using defaults: $e');
    }
  }

  static int _int(String key, int fallback) {
    try {
      return _rc?.getInt(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Every Nth app open shows the Interstitial. 0 or less = never.
  static int get openAdEvery => _int(keyOpen, _defaultOpen);

  /// Every Nth return from recents shows the App Open ad. 0 or less = never.
  static int get recentAppAdEvery => _int(keyRecentApp, _defaultRecentApp);

  /// Every Nth back shows the Interstitial. 0 or less = never.
  static int get backAdEvery => _int(keyBack, _defaultBack);

  // /// Every Nth ✕/✓ tap shows the Interstitial. 0 or less = never.
  // static int get saveCancelAdEvery => _int(keySaveCancel, _defaultSaveCancel);
  //
  // /// Every Nth delete shows the Interstitial. 0 or less = never.
  // static int get deleteAdEvery => _int(keyDelete, _defaultDelete);
  //
  // /// Every Nth theme change shows the Interstitial. 0 or less = never.
  // static int get themeChangeAdEvery =>
  //     _int(keyThemeChange, _defaultThemeChange);

  static void _log(String from) {
    debugPrint(
      '[RemoteConfig] $from: $keyOpen=$openAdEvery, '
      // '$keyRecentApp=$recentAppAdEvery, $keyBack=$backAdEvery, '
      // '$keySaveCancel=$saveCancelAdEvery, $keyDelete=$deleteAdEvery, '
      // '$keyThemeChange=$themeChangeAdEvery',
      '$keyRecentApp=$recentAppAdEvery, $keyBack=$backAdEvery',
    );
  }
}
