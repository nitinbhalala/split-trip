import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_trip/data/service/network_service.dart';
import 'package:split_trip/data/service/pref_keys.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/interstitial_ad_helper.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/services/firebase/remote_config_service.dart';

/// A single no-fill/network load failure is normal ad-network behavior, not
/// a bug — only a unit that keeps failing to load this many times in a row
/// gets logged with [AppLogger.error] (Split Trip has no Crashlytics).
const int _kReportAfterConsecutiveFailures = 5;

/// Central service for Google Mobile Ads SDK init & the two "open" ads.
/// Registered with GetX (permanent) at app startup via `Get.putAsync`.
///
/// | How the user opens the app         | Ad                    | Remote Config        |
/// |------------------------------------|-----------------------|----------------------|
/// | Direct launch (cold start)         | Startup Interstitial  | `splittrip_open`       |
/// | Return from recents / background   | App Open ad           | `splittrip_recent_app` |
///
/// Both show on every Nth time (`count % N == 0`); `N <= 0` means never.
/// Neither shows before the main screen was reached this process (Splash /
/// Login never get an open ad).
///
/// All other ad types (Banner/Native/Interstitial) are static, screen-wise
/// IDs from [AdUnitIds] passed directly into the ad widget/helper used on
/// each screen — this service only owns the app-wide open ads.
class AppOpenAdService extends GetxService with WidgetsBindingObserver {
  static const String _lastShownDateKey = 'last_app_open_ad_date';

  /// Shown on arrival, but never waited for longer than this.
  static const Duration _giveUpAfter = Duration(seconds: 8);

  /// A resume this soon after a full-screen ad closed is that ad handing the
  /// screen back, not the user returning from recents.
  static const Duration _adResumeWindow = Duration(seconds: 4);

  /// See [ignoreNextReturn].
  static const Duration _externalFlowWindow = Duration(seconds: 10);

  // Static so callers don't have to wait for the async `Get.putAsync`.
  static AppOpenAdService? _instance;
  static bool _mainScreenReached = false;
  static DateTime? _externalFlowStartedAt;

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  bool _isLoadingAppOpenAd = false;
  bool _showAfterLoad = false;
  Timer? _giveUpTimer;
  DateTime? _appOpenAdLoadTime;
  DateTime? _lastAdDismissedTime;
  int _loadFailCount = 0;

  bool _wasBackgrounded = false;
  bool _backgroundedByExternalFlow = false;

  bool _startupHandled = false;
  bool _startupWanted = false;
  bool _isShowingStartupAd = false;

  /// Set the moment the App Open Ad is actually shown, for the lifetime of
  /// this app process (this service is `permanent: true`, so a fresh cold
  /// start always gets a fresh instance and thus a fresh `false` here).
  /// Every later `resumed` lifecycle event in the same process (backgrounding
  /// and returning, pulling down/closing the status bar, coming back from a
  /// permission dialog) is just this same app open continuing, not a new
  /// one, so it must not show the ad again.
  // bool _hasShownAppOpenAdThisSession = false;

  /// Maximum duration before a loaded ad is considered stale/expired.
  // final Duration _maxAdAge = const Duration(hours: 1);
  // AdMob App Open ads expire after 4 h.
  final Duration _maxAdAge = const Duration(hours: 4);

  Future<AppOpenAdService> init() async {
    debugPrint('[Ads] [AppOpen] Initializing AppOpenAdService & AdMob SDK...');
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);

    // Attempt to load & show App Open Ad on cold start
    // showAppOpenAdIfAvailable();
    // Cold start now gets the startup Interstitial (`splittrip_open`) once the
    // main screen opens; the App Open ad is only for returns from recents.
    await _registerAppLaunch();
    _instance = this;
    if (_mainScreenReached) _runStartupInterstitial();

    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _giveUpTimer?.cancel();
    _appOpenAd?.dispose();
    if (identical(_instance, this)) _instance = null;
    super.onClose();
  }

  /// Call when the main screen opens. Before this, returns from recents are
  /// not counted and no open ad shows.
  static void onMainScreenOpened() {
    if (_mainScreenReached) return;
    _mainScreenReached = true;
    // If init() hasn't finished yet, it runs the startup ad itself.
    _instance?._runStartupInterstitial();
  }

  /// Call right before the app itself opens another app / system screen
  /// (image picker, share sheet, Google / Apple sign-in, browser, settings,
  /// in-app update). Coming back from it is not a return from recents.
  static void ignoreNextReturn() {
    _externalFlowStartedAt = DateTime.now();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     // Guard: ignore the resume event caused by closing/dismissing the ad
  //     // itself (prevents an infinite show → resume → show loop).
  //     if (_lastAdDismissedTime != null &&
  //         DateTime.now().difference(_lastAdDismissedTime!) <
  //             const Duration(seconds: 4)) {
  //       return;
  //     }
  //
  //     // Deferred to after the next frame: showing the App Open Ad opens a
  //     // separate full-screen native Activity, and doing that synchronously
  //     // from this lifecycle callback while the widget tree is mid-rebuild
  //     // can cause Flutter framework element-tree assertions.
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       showAppOpenAdIfAvailable();
  //     });
  //   }
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_wasBackgrounded) return;
      _wasBackgrounded = true;
      final flowAt = _externalFlowStartedAt;
      _externalFlowStartedAt = null;
      _backgroundedByExternalFlow =
          _isShowingAppOpenAd ||
          _isShowingStartupAd ||
          (flowAt != null &&
              DateTime.now().difference(flowAt) < _externalFlowWindow);
      return;
    }

    // Only a real paused → resumed counts; inactive / hidden alone
    // (notification shade, system dialog) never reach here as a return.
    if (state != AppLifecycleState.resumed || !_wasBackgrounded) return;
    _wasBackgrounded = false;

    if (_backgroundedByExternalFlow) {
      _backgroundedByExternalFlow = false;
      debugPrint('[Ads] [AppOpen] Resume from an in-app flow — not a return');
      return;
    }

    // Guard: ignore the resume event caused by closing/dismissing a
    // full-screen ad (prevents an infinite show → resume → show loop).
    if (_closedWithinResumeWindow(_lastAdDismissedTime) ||
        _closedWithinResumeWindow(InterstitialAdHelper.lastClosedAt)) {
      return;
    }

    _onReturnedFromRecents();
  }

  bool _closedWithinResumeWindow(DateTime? closedAt) =>
      closedAt != null && DateTime.now().difference(closedAt) < _adResumeWindow;

  Future<void> _onReturnedFromRecents() async {
    if (!_mainScreenReached) return;
    final count = await _registerRecentsReturn();
    final every = RemoteConfigService.recentAppAdEvery;
    debugPrint('[Ads] [AppOpen] Return #$count (ad on every $every)');
    if (every <= 0) return;

    if (count % every == 0) {
      debugPrint(
        '[Ads] [AppOpen] Return #$count → DUE (every $every): show now',
      );
      // Deferred to after the next frame: showing the App Open Ad opens a
      // separate full-screen native Activity, and doing that synchronously
      // from this lifecycle callback while the widget tree is mid-rebuild
      // can cause Flutter framework element-tree assertions.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAppOpenAdIfAvailable();
      });
      // } else if ((count + 1) % every == 0) {
      //   // The next return is the ad's: start loading now so it's ready.
      //   debugPrint(
      //     '[Ads] [AppOpen] Return #$count → not due, but #${count + 1} is: '
      //     'PRELOAD now (waits in cache)',
      //   );
      //   _preloadAppOpenAd();
      // } else {
    } else {
      // No preload: the ad is requested only once its return is due.
      debugPrint(
        '[Ads] [AppOpen] Return #$count → not due (every $every): no load',
      );
    }
  }

  /// Checks eligibility (once-per-day limit) and loads/shows the App Open Ad.
  // Now: shows the cached ad, or loads one and shows it on arrival (giving
  // up after [_giveUpAfter]). Frequency is decided by the caller.
  Future<void> showAppOpenAdIfAvailable() async {
    if (!AdUnitIds.adsEnabled) return;
    if (AdUnitIds.appOpen.isEmpty) return;
    if (!_mainScreenReached) return;
    if (_isShowingAppOpenAd || _isShowingStartupAd) return;
    // if (_isLoadingAppOpenAd) return;
    if (_isLoadingAppOpenAd) {
      debugPrint(
        '[Ads] [AppOpen] Already loading → shows when it arrives (max 8 s)',
      );
      _waitForAppOpenAd();
      return;
    }

    // if (_hasShownAppOpenAdThisSession) {
    //   // One-time-per-app-open rule — covers every later resume: backgrounding/
    //   // returning, the status bar being pulled down and closed, coming back
    //   // from a permission dialog, etc.
    //   return;
    // }
    //
    // final prefs = await SharedPreferences.getInstance();
    // final today = _todayDateString();
    // final lastShownDate = prefs.getString(_lastShownDateKey);
    //
    // // 1-time-per-day gate. Remove this block if you want the App Open Ad to
    // // show on every cold start / resume instead of once a day.
    // if (lastShownDate == today) {
    //   return;
    // }
    final today = _todayDateString();

    // Reuse an unexpired preloaded ad if we already have one.
    if (_isAdAvailable()) {
      debugPrint('[Ads] [AppOpen] SHOW from cache');
      _showAppOpenAd(today);
      return;
    }

    debugPrint(
      '[Ads] [AppOpen] Nothing in cache → LOAD_START now, shows when it arrives '
      '(max 8 s, later = stays in cache)',
    );
    _waitForAppOpenAd();
    _loadAppOpenAd();
  }

  void _waitForAppOpenAd() {
    _showAfterLoad = true;
    _giveUpTimer?.cancel();
    // An ad that arrives later stays cached for the next turn.
    _giveUpTimer = Timer(_giveUpAfter, () => _showAfterLoad = false);
  }

  // Unused: App Open loads only when its return is due (no preload).
  // void _preloadAppOpenAd() {
  //   if (!AdUnitIds.adsEnabled || AdUnitIds.appOpen.isEmpty) return;
  //   if (_isLoadingAppOpenAd || _isShowingAppOpenAd || _isAdAvailable()) return;
  //   debugPrint('[Ads] [AppOpen] Preload for the next return');
  //   _loadAppOpenAd();
  // }

  // void _loadAppOpenAd() {
  void _loadAppOpenAd() async {
    if (_isLoadingAppOpenAd) return;
    // No internet → no request.
    _isLoadingAppOpenAd = true;
    if (!await NetworkService.hasInternetCached()) {
      debugPrint('[Ads] [AppOpen] No internet → no request');
      _isLoadingAppOpenAd = false;
      _showAfterLoad = false;
      return;
    }
    debugPrint('[Ads] [AppOpen] Load Started | AdUnit: ${AdUnitIds.appOpen}');
    _isLoadingAppOpenAd = true;

    AppOpenAd.load(
      adUnitId: AdUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          debugPrint('[Ads] [AppOpen] Loaded | AdUnit: ${AdUnitIds.appOpen}');
          // Ad revenue → Firebase `ad_impression`.
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            AnalyticsService.trackAdRevenue(
              ad: ad,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              adFormat: AnalyticsAdFormat.appOpen,
              placement: 'app_open',
            );
          };
          _appOpenAd = ad;
          _isLoadingAppOpenAd = false;
          _appOpenAdLoadTime = DateTime.now();
          _loadFailCount = 0;
          // _showAppOpenAd(today);
          if (_showAfterLoad && _isAppInForeground) {
            _showAfterLoad = false;
            _giveUpTimer?.cancel();
            _showAppOpenAd(_todayDateString());
          } else {
            debugPrint('[Ads] [AppOpen] Cached, waiting for its turn');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          logAdError(
            '[Ads] [AppOpen] Load Failed: code=${error.code}, message=${error.message}, domain=${error.domain} | AdUnit: ${AdUnitIds.appOpen}',
          );
          _isLoadingAppOpenAd = false;
          _showAfterLoad = false;
          _appOpenAd = null;
          _loadFailCount++;
          AppLogger.error(
            '[Ads] [AppOpen] Load Failed: code=${error.code}, message=${error.message} | AdUnit: ${AdUnitIds.appOpen}',
          );
          if (_loadFailCount == _kReportAfterConsecutiveFailures) {
            AppLogger.error(
              'App Open ad (AdUnit: ${AdUnitIds.appOpen}) failed to load '
              '$_kReportAfterConsecutiveFailures times in a row: '
              'code=${error.code}, message=${error.message}',
            );
          }
        },
      ),
    );
  }

  void _showAppOpenAd(String todayDate) {
    final ad = _appOpenAd;
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (AppOpenAd ad) async {
        debugPrint('[Ads] [AppOpen] Show | AdUnit: ${AdUnitIds.appOpen}');
        _isShowingAppOpenAd = true;
        // _hasShownAppOpenAdThisSession = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastShownDateKey, todayDate);
      },
      onAdImpression: (AppOpenAd ad) {
        debugPrint('[Ads] [AppOpen] Impression | AdUnit: ${AdUnitIds.appOpen}');
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        logAdError(
          '[Ads] [AppOpen] Show Failed: code=${error.code}, message=${error.message}, domain=${error.domain} | AdUnit: ${AdUnitIds.appOpen}',
        );
        _lastAdDismissedTime = DateTime.now();
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        // A load already succeeded here — failing to SHOW it is rare and
        // usually points to a real problem, so report it immediately
        // rather than waiting for repeats.
        AppLogger.error(
          'App Open ad (AdUnit: ${AdUnitIds.appOpen}) failed to SHOW after '
          'a successful load: code=${error.code}, message=${error.message}',
        );
      },
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        // debugPrint('[Ads] [AppOpen] Closed | AdUnit: ${AdUnitIds.appOpen}');
        debugPrint(
          '[Ads] [AppOpen] CLOSED → no new load (next one loads when its '
          'return is due)',
        );
        _lastAdDismissedTime = DateTime.now();
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
    );

    // Marked before show() so the pause it causes is never counted as the
    // user leaving the app.
    _isShowingAppOpenAd = true;
    ad.show();
  }

  bool _isAdAvailable() {
    return _appOpenAd != null &&
        _appOpenAdLoadTime != null &&
        DateTime.now().difference(_appOpenAdLoadTime!) < _maxAdAge;
  }

  // ─── Startup Interstitial (cold start, `splittrip_open`) ─────────────────

  /// Runs once per process, when the main screen first opens. Never
  /// awaited, so startup never waits for an ad.
  // void _runStartupInterstitial() {
  void _runStartupInterstitial() async {
    if (_startupHandled) return;
    _startupHandled = true;

    final adUnitId = AdUnitIds.startupInterstitial;
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) return;

    final launches = _appLaunchCount;
    final every = RemoteConfigService.openAdEvery;
    if (every <= 0 || launches % every != 0) {
      debugPrint(
        '[Ads] [StartupAd] Skipped: launch #$launches — shows on every $every',
      );
      return;
    }

    // No internet → no request (this launch gets no startup ad).
    if (!await NetworkService.hasInternetCached()) {
      debugPrint('[StartupAd] Launch #$launches — no internet, no request');
      return;
    }

    // Dynamic ID: the next one from the interstitial list.
    final unitId = AdUnitIds.resolveInterstitial(adUnitId);
    if (unitId.isEmpty) return;
    debugPrint(
      '[Ads] [StartupAd] Launch #$launches — Load Started | AdUnit: $unitId',
    );
    _startupWanted = true;
    Timer(_giveUpAfter, () {
      if (_startupWanted) debugPrint('[Ads] [StartupAd] Gave up after 8 s');
      _startupWanted = false;
    });

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_startupWanted || !_isAppInForeground || _isShowingAppOpenAd) {
            debugPrint('[Ads] [StartupAd] Loaded too late — dropped');
            _startupWanted = false;
            ad.dispose();
            return;
          }
          _startupWanted = false;
          // Ad revenue → Firebase `ad_impression`.
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            AnalyticsService.trackAdRevenue(
              ad: ad,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              adFormat: AnalyticsAdFormat.interstitial,
              placement: 'startup',
            );
          };
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[Ads] [StartupAd] Show | AdUnit: $unitId');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[Ads] [StartupAd] Closed | AdUnit: $unitId');
              _onStartupAdClosed(ad);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              logAdError(
                '[Ads] [StartupAd] Show Failed: code=${error.code}, message=${error.message} | AdUnit: $unitId',
              );
              _onStartupAdClosed(ad);
            },
          );
          _isShowingStartupAd = true;
          ad.show();
        },
        onAdFailedToLoad: (error) {
          _startupWanted = false;
          logAdError(
            '[Ads] [StartupAd] Load Failed: code=${error.code}, message=${error.message} | AdUnit: $unitId',
          );
        },
      ),
    );
  }

  void _onStartupAdClosed(InterstitialAd ad) {
    _isShowingStartupAd = false;
    InterstitialAdHelper.lastClosedAt = DateTime.now();
    ad.dispose();
  }

  // ─── Counters (persisted, never reset) ─────────────────────────────────

  SharedPreferencesService? get _prefs =>
      Get.isRegistered<SharedPreferencesService>()
      ? Get.find<SharedPreferencesService>()
      : null;

  int get _appLaunchCount => _prefs?.getInt(PrefKeys.appLaunchCount) ?? 0;

  /// +1 once per process (this service is created once per cold start).
  Future<void> _registerAppLaunch() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setInt(PrefKeys.appLaunchCount, _appLaunchCount + 1);
  }

  Future<int> _registerRecentsReturn() async {
    final prefs = _prefs;
    if (prefs == null) return 0;
    final count = prefs.getInt(PrefKeys.recentsReturnCount) + 1;
    await prefs.setInt(PrefKeys.recentsReturnCount, count);
    return count;
  }

  bool get _isAppInForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  String _todayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Call this to reset today's limit for testing purposes.
  Future<void> resetAppOpenAdTodayLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastShownDateKey);
  }
}
