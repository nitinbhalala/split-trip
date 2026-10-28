import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:split_trip/services/ads/android_ad_unit_id.dart';
import 'package:split_trip/services/ads/ios_ad_unit_id.dart';

class AdUnitIds {
  AdUnitIds._();

  static const bool adsEnabled = true;

  /// Test ads in debug/profile builds, live IDs only in release — no test
  /// ads shipped by mistake, no live-ad clicks while developing.
  static const bool testAds = !kReleaseMode;

  // Google test IDs differ per platform — an Android test ID never fills on iOS.
  static String get _testBanner => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';
  static String get _testInterstitial => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
  static String get _testNative => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/3986624511'
      : 'ca-app-pub-3940256099942544/2247696110';
  static String get _testAppOpen => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/5575463023'
      : 'ca-app-pub-3940256099942544/9257395921';
  // Rewarded removed (not used).
  // static String get _testRewarded => Platform.isIOS
  //     ? 'ca-app-pub-3940256099942544/1712485313'
  //     : 'ca-app-pub-3940256099942544/5224354917';

  // ─── Dynamic banner / native IDs (every screen except the main screen) ─
  // Screens pass these markers; [AdCacheManager] swaps in the next ID from
  // the platform list (round-robin) only when it actually loads an ad.
  static const String dynamicBanner = 'dynamic:banner';
  static const String dynamicNative = 'dynamic:native';
  // Every Interstitial also comes from a list, in sequence (1 → 2 → 3 → 1…).
  static const String dynamicInterstitial = 'dynamic:interstitial';
  static int _interstitialCursor = 0;
  static List<String> get _interstitialIds => testAds
      ? [_testInterstitial]
      : (Platform.isIOS
            ? IosAdUnitId.interstitialIds
            : AndroidAdUnitId.interstitialIds);

  /// [adUnitId] as is, or — for [dynamicInterstitial] — the next ID from the
  /// list, taken only when a load really goes out. '' = empty list (no ad).
  static String resolveInterstitial(String adUnitId) =>
      adUnitId == dynamicInterstitial
      ? _next(_interstitialIds, () => _interstitialCursor++)
      : adUnitId;
  static int _bannerCursor = 0;
  static int _nativeCursor = 0;

  static List<String> get _bannerIds => testAds
      ? [_testBanner]
      : (Platform.isIOS ? IosAdUnitId.bannerIds : AndroidAdUnitId.bannerIds);
  static List<String> get _nativeIds => testAds
      ? [_testNative]
      : (Platform.isIOS ? IosAdUnitId.nativeIds : AndroidAdUnitId.nativeIds);

  /// [adUnitId] as is, or — for [dynamicBanner] — the next ID from the list.
  /// '' when the list is empty (no ad).
  static String resolveBanner(String adUnitId) => adUnitId == dynamicBanner
      ? _next(_bannerIds, () => _bannerCursor++)
      : adUnitId;

  /// [adUnitId] as is, or — for [dynamicNative] — the next ID from the list.
  static String resolveNative(String adUnitId) => adUnitId == dynamicNative
      ? _next(_nativeIds, () => _nativeCursor++)
      : adUnitId;

  static String _next(List<String> ids, int Function() cursor) {
    final valid = ids.where((id) => id.isNotEmpty).toList();
    if (valid.isEmpty) return '';
    return valid[cursor() % valid.length];
  }

  /// Live ID for the current platform — see [AndroidAdUnitId] / [IosAdUnitId].
  static String _live(String android, String ios) =>
      Platform.isIOS ? ios : android;

  // ─── App Open (return from recents, Remote Config `splittrip_recent_app`) ─
  static String get appOpen => testAds
      ? _testAppOpen
      : _live(AndroidAdUnitId.appOpen, IosAdUnitId.appOpen);

  // ─── Startup Interstitial (cold start, Remote Config `splittrip_open`) ───
  static String get startupInterstitial => dynamicInterstitial;

  // ─── Main Screen (below the bottom nav bar, fixed ID) ────────────
  static String get mainBottomBanner => testAds
      ? _testBanner
      : _live(AndroidAdUnitId.mainBottomBanner, IosAdUnitId.mainBottomBanner);

  // // ─── Exit App bottom sheet: native, banner fallback (fixed IDs) ──────
  // static String get exitDialogNative => testAds
  //     ? _testNative
  //     : _live(AndroidAdUnitId.exitDialogNative, IosAdUnitId.exitDialogNative);
  // static String get exitDialogBanner => testAds
  //     ? _testBanner
  //     : _live(AndroidAdUnitId.exitDialogBanner, IosAdUnitId.exitDialogBanner);
  // ─── Exit App bottom sheet: native, banner fallback (dynamic lists) ──
  static String get exitDialogNative => dynamicNative;
  static String get exitDialogBanner => dynamicBanner;

  // ─── Screen banners (dynamic) ────────────────────────────────────
  static String get selectCurrencyBanner => dynamicBanner;
  static String get profileBanner => dynamicBanner;
  static String get groupInfoBanner => dynamicBanner;
  static String get expenseDetailBanner => dynamicBanner;
  static String get selectCategoryBanner => dynamicBanner;
  static String get addCategoryBanner => dynamicBanner;
  static String get groupDetailBanner => dynamicBanner;
  // One slot for all three Add Split Expense steps (amount, payer, split).
  static String get addSplitExpenseBanner => dynamicBanner;

  // ─── Fallback natives: shown only when the screen's banner fails ─────
  static String get selectCurrencyNative => dynamicNative;
  static String get profileNative => dynamicNative;
  static String get groupInfoNative => dynamicNative;
  static String get expenseDetailNative => dynamicNative;
  static String get selectCategoryNative => dynamicNative;
  static String get addCategoryNative => dynamicNative;
  static String get groupDetailNative => dynamicNative;
  static String get addSplitExpenseNative => dynamicNative;

  // ─── Theme Selection Screen: native first, large banner fallback ─────
  // Now banner first, native fallback (BannerOrNativeAdWidget).
  static String get themeNative => dynamicNative;
  static String get themeBanner => dynamicBanner;

  // ─── Back (← icon / system back), Remote Config `splittrip_back` ─────
  static String get backInterstitial => dynamicInterstitial;

  // Remote Config `splittrip_save_cancel` / `splittrip_delete` removed.
  // // ─── ✕ Cancel / ✓ Save (one shared count), `splittrip_save_cancel` ───
  // static String get saveCancelInterstitial => dynamicInterstitial;
  //
  // // ─── Delete group / member / category (before deleting), `splittrip_delete`
  // static String get deleteInterstitial => dynamicInterstitial;

  // // ─── Theme change (before applying it), `splittrip_theme_change` ─────
  // ─── Delete group (before deleting), on every delete ─────────────────
  static String get deleteGroupInterstitial => dynamicInterstitial;

  // ─── Theme change (before applying it), on every change ──────────────
  static String get themeChangeInterstitial => dynamicInterstitial;

  // ─── Google Drive Backup / Restore / Delete Backup (before the action) ─
  static String get backupRestoreInterstitial => dynamicInterstitial;

  // ─── AppAdsButton (core/common/button/app_ads_button.dart) default ───
  static String get adsButtonInterstitial => dynamicInterstitial;

  // Rewarded removed (not used).
  // // ─── Rewarded: turn on Daily Auto Backup ─────────────────────────────
  // static String get dailyAutoBackupRewarded => testAds
  //     ? _testRewarded
  //     : _live(
  //         AndroidAdUnitId.dailyAutoBackupRewarded,
  //         IosAdUnitId.dailyAutoBackupRewarded,
  //       );
        
}
