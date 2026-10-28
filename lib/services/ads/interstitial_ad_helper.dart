import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:split_trip/data/service/network_service.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';

/// A single no-fill/network load failure is normal ad-network behavior, not
/// a bug — only a unit that keeps failing to load this many times in a row
/// gets logged with [AppLogger.error] (Split Trip has no Crashlytics).
const int _kReportAfterConsecutiveFailures = 5;

/// Helper for loading and showing Interstitial Ads.
/// Call [preload] once (e.g., in screen init), then [show] when ready.
class InterstitialAdHelper {
  // InterstitialAdHelper({required this.adUnitId});
  InterstitialAdHelper({required this.adUnitId, this.placement});

  /// Static ad unit ID for the screen this helper is used on (see AdUnitIds).
  final String adUnitId;

  /// Slot / moment name for ad revenue (`ad_placement`), e.g. `back`,
  /// `delete`. Falls back to the ad unit ID.
  final String? placement;

  /// When any Interstitial last closed (or failed to show), app-wide. The
  /// App Open service reads it so the resume caused by closing an
  /// Interstitial is not counted as a return from recents.
  static DateTime? lastClosedAt;

  InterstitialAd? _interstitialAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _showWhenLoaded = false;
  int _loadFailCount = 0;

  /// AdMob interstitials expire about an hour after loading.
  static const Duration _maxAdAge = Duration(hours: 1);

  /// After a failed load, no new load for this long (no-fill retry storm).
  static const Duration _retryCooldown = Duration(seconds: 30);

  DateTime? _loadedAt;
  DateTime? _lastFailAt;

  /// An ad of this helper is on screen right now. Its object is no longer in
  /// [_interstitialAd]; its own callbacks dispose it when it closes.
  bool _isShowing = false;

  /// Set by [dispose]: an ad that finishes loading afterwards is disposed at
  /// once (it would otherwise leak), and nothing loads again.
  bool _disposed = false;

  /// Drops a loaded ad older than [_maxAdAge] (never shown — it could fail
  /// or earn nothing) so a fresh one can load.
  void _dropIfExpired() {
    final at = _loadedAt;
    if (!_isLoaded || at == null) return;
    if (DateTime.now().difference(at) < _maxAdAge) return;
    // debugPrint('[Ads] [Interstitial] Expired (>1 h) — dropped | AdUnit: $adUnitId');
    debugPrint('$_tag EXPIRED (>1 h in cache) → dropped, a fresh one loads');
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
    _loadedAt = null;
  }

  /// Puts the loaded ad on screen. The helper lets go of the object first,
  /// so no load can overwrite it and [dispose] can't kill it mid-show.
  bool _showLoaded() {
    final ad = _interstitialAd;
    if (!_isLoaded || ad == null) return false;
    // debugPrint('[Ads] [Interstitial] Show requested | AdUnit: $adUnitId');
    final at = _loadedAt;
    final age = at == null
        ? '?'
        : '${DateTime.now().difference(at).inSeconds}s';
    debugPrint('$_tag SHOW from cache (was in cache $age)');
    _interstitialAd = null;
    _isLoaded = false;
    _loadedAt = null;
    _isShowing = true;
    ad.show();
    return true;
  }

  /// Completes when the ad shown by [showIfReadyAndWait] closes.
  Completer<void>? _closed;

  void _completeClosed() {
    final c = _closed;
    _closed = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Completes with the current load's result (true = loaded) — see
  /// [loadAndWait].
  Completer<bool>? _loadResult;

  void _completeLoad(bool loaded) {
    final c = _loadResult;
    _loadResult = null;
    if (c != null && !c.isCompleted) c.complete(loaded);
  }

  /// Log prefix with the slot name, e.g. `[Interstitial:back]`.
  String get _tag => '[Ads] [Interstitial:${placement ?? adUnitId}]';

  /// Preload the interstitial ad so it's ready to display instantly.
  /// [reason] is only for the log (why this load was asked for).
  // void preload() {
  // void preload({String reason = 'request'}) {
  void preload({String reason = 'request'}) async {
    if (!AdUnitIds.adsEnabled) {
      debugPrint(
        '[Ads] [Interstitial] 🚫 Ads disabled (AdUnitIds.adsEnabled=false). Skipping preload.',
      );
      return;
    }
    if (adUnitId.isEmpty) {
      debugPrint(
        '[Ads] [Interstitial] 🚫 No ad unit ID provided. Skipping preload.',
      );
      return;
    }

    // Already loaded or in flight — a second load would leak the first ad.
    // if (_isLoaded || _isLoading) return;
    if (_disposed) return;
    _dropIfExpired();
    // Also not while its ad is on screen (C), nor right after a failure.
    // if (_isLoaded || _isLoading || _isShowing) return;
    if (_isLoaded) {
      debugPrint('$_tag SKIP load ($reason) — an ad is already in cache');
      return;
    }
    if (_isLoading) {
      debugPrint('$_tag SKIP load ($reason) — already loading');
      return;
    }
    if (_isShowing) {
      debugPrint('$_tag SKIP load ($reason) — its ad is on screen');
      return;
    }
    final failAt = _lastFailAt;
    if (failAt != null && DateTime.now().difference(failAt) < _retryCooldown) {
      // debugPrint(
      //   '[Ads] [Interstitial] Retry cooldown — skip load | AdUnit: $adUnitId',
      // );
      debugPrint(
        '$_tag SKIP load ($reason) — failed '
        '${DateTime.now().difference(failAt).inSeconds}s ago, retry after 30s',
      );
      return;
    }

    // No internet → no request (counts as a failed load: 30 s cooldown).
    // _isLoading is set first so a second call meanwhile is skipped.
    _isLoading = true;
    final online = await NetworkService.hasInternetCached();
    _isLoading = false;
    if (_disposed) {
      _completeLoad(false);
      return;
    }
    if (!online) {
      debugPrint('$_tag SKIP load ($reason) — no internet, no request');
      _lastFailAt = DateTime.now();
      _completeLoad(false);
      return;
    }

    // Dynamic ID: the next one from the interstitial list, taken now.
    final unitId = AdUnitIds.resolveInterstitial(adUnitId);
    if (unitId.isEmpty) {
      debugPrint('$_tag SKIP load ($reason) — no interstitial ID in the list');
      _completeLoad(false);
      return;
    }
    // debugPrint('[Ads] [Interstitial] Load Started | AdUnit: $adUnitId');
    debugPrint('$_tag LOAD_START | reason: $reason | AdUnit: $unitId');
    _showWhenLoaded = false;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          // debugPrint('[Ads] [Interstitial] Loaded | AdUnit: $unitId');
          debugPrint('$_tag LOADED → in cache, waiting for its turn');
          _isLoading = false;
          // Helper already disposed (screen gone) → don't keep the ad (B).
          if (_disposed) {
            ad.dispose();
            _completeLoad(false);
            return;
          }
          _loadedAt = DateTime.now();
          _lastFailAt = null;
          _interstitialAd = ad;
          // Ad revenue → Firebase `ad_impression`.
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            AnalyticsService.trackAdRevenue(
              ad: ad,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              adFormat: AnalyticsAdFormat.interstitial,
              placement: placement,
            );
          };
          _isLoaded = true;
          _loadFailCount = 0;
          _completeLoad(true);
          _interstitialAd!
              .fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[Ads] [Interstitial] Show | AdUnit: $unitId');
            },
            onAdImpression: (ad) {
              debugPrint('[Ads] [Interstitial] Impression | AdUnit: $unitId');
            },
            onAdDismissedFullScreenContent: (ad) {
              // debugPrint('[Ads] [Interstitial] Closed | AdUnit: $unitId');
              // debugPrint('$_tag CLOSED → next ad loads now and waits in cache');
              debugPrint(
                '$_tag CLOSED → no new load (next one loads when its screen '
                'opens and the next action is due)',
              );
              lastClosedAt = DateTime.now();
              ad.dispose();
              // _interstitialAd = null;
              // _isLoaded = false;
              _isShowing = false;
              _completeClosed();
              // Preload next ad
              // preload();
              // if (!_disposed) preload(reason: 'after_close');
              // No reload after a show: a loaded ad must not sit waiting.
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              lastClosedAt = DateTime.now();
              logAdError(
                '[Ads] [Interstitial] Show Failed: code=${error.code}, message=${error.message}, domain=${error.domain} | AdUnit: $unitId',
              );
              ad.dispose();
              // _interstitialAd = null;
              // _isLoaded = false;
              _isShowing = false;
              _completeClosed();
              // if (!_disposed) preload(reason: 'after_show_failed');
              // A load already succeeded here — failing to SHOW it is rare
              // and usually points to a real problem (activity gone,
              // memory pressure, SDK bug), so report it immediately rather
              // than waiting for repeats.
              AppLogger.error(
                'Interstitial ad (AdUnit: $unitId) failed to SHOW after a '
                'successful load: code=${error.code}, message=${error.message}',
              );
            },
          );

          if (_showWhenLoaded) {
            _showWhenLoaded = false;
            show();
          }
        },
        onAdFailedToLoad: (error) {
          logAdError(
            '[Ads] [Interstitial] Load Failed: code=${error.code}, message=${error.message}, domain=${error.domain} | AdUnit: $unitId',
          );
          _isLoaded = false;
          _isLoading = false;
          _lastFailAt = DateTime.now();
          _loadFailCount++;
          debugPrint(
            '$_tag LOAD_FAILED (code ${error.code}) → nothing in cache, '
            'no new load for 30s',
          );
          _completeLoad(false);
          AppLogger.error(
            '[Ads] [Interstitial] Load Failed: code=${error.code}, message=${error.message} | AdUnit: $unitId',
          );
          if (_loadFailCount == _kReportAfterConsecutiveFailures) {
            AppLogger.error(
              'Interstitial ad (AdUnit: $unitId) failed to load '
              '$_kReportAfterConsecutiveFailures times in a row: '
              'code=${error.code}, message=${error.message}',
            );
          }
        },
      ),
    );
  }

  /// Show the preloaded interstitial. Returns true if shown.
  bool show() {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) {
      debugPrint(
        '[Ads] [Interstitial] 🚫 Cannot show: no ad unit ID provided.',
      );
      return false;
    }

    // if (_isLoaded && _interstitialAd != null) {
    //   debugPrint('[Ads] [Interstitial] Show requested | AdUnit: $adUnitId');
    //   _interstitialAd!.show();
    //   _isLoaded = false;
    //   return true;
    // }
    if (_isShowing) return false;
    _dropIfExpired();
    if (_showLoaded()) return true;
    _showWhenLoaded = true;
    return false;
  }

  /// Shows the ad only if it is ready right now. Unlike [show], it never
  /// queues a late show (an ad popping up seconds after the tap); if nothing
  /// is ready it starts a load for next time and returns false.
  bool showIfReady() {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) return false;
    // if (_isLoaded && _interstitialAd != null) {
    //   debugPrint('[Ads] [Interstitial] Show requested | AdUnit: $adUnitId');
    //   _interstitialAd!.show();
    //   _isLoaded = false;
    //   return true;
    // }
    if (_isShowing || _disposed) return false;
    _dropIfExpired();
    if (_showLoaded()) return true;
    // preload();
    // preload(reason: 'not_ready_at_show');
    // Not ready → nothing is loaded here; loads happen only on screen open.
    debugPrint('$_tag NOT_READY at show → no ad this time');
    return false;
  }

  /// [showIfReady], then waits until the ad closes — for flows that must run
  /// only after the ad (e.g. delete after the ad). Completes right away when
  /// nothing was shown.
  Future<bool> showIfReadyAndWait() async {
    // Its ad is already on screen (e.g. a quick second tap): leave that
    // ad's waiter alone, show nothing (C).
    if (_isShowing) return false;
    _completeClosed();
    final closed = Completer<void>();
    _closed = closed;
    if (!showIfReady()) {
      _closed = null;
      return false;
    }
    await closed.future;
    return true;
  }

  /// Loads the ad (or uses the one already loaded) and waits for the
  /// result, without showing it: true = ready to show, false = no fill /
  /// load error / [timeout] passed. An ad that arrives after the timeout is
  /// kept for next time — it never pops up late.
  Future<bool> loadAndWait({required Duration timeout}) async {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) return false;
    if (_isShowing || _disposed) return false;
    _dropIfExpired();
    if (_isLoaded && _interstitialAd != null) return true;
    final waiter = _loadResult ??= Completer<bool>();
    // preload();
    preload(reason: 'wait_for_ad');
    if (!_isLoading && !_isLoaded) _completeLoad(false); // load not started
    try {
      return await waiter.future.timeout(timeout);
    } on TimeoutException {
      debugPrint(
        '[Ads] [Interstitial] Load wait timed out | AdUnit: $adUnitId',
      );
      return false;
    }
  }

  /// Dispose resources.
  void dispose() {
    debugPrint('[Ads] [Interstitial] Disposed | AdUnit: $adUnitId');
    _disposed = true;
    // Only the loaded, unshown ad. One on screen is disposed by its own
    // close callback, so its close (and lastClosedAt) still happens.
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
    _isLoading = false;
    _showWhenLoaded = false;
    _completeClosed();
    _completeLoad(false);
  }

  bool get isLoaded => _isLoaded;

  /// A fresh (not expired) ad is loaded and nothing of this helper is on
  /// screen — [showIfReady] would show it now.
  bool get isReadyToShow {
    _dropIfExpired();
    return !_isShowing && _isLoaded && _interstitialAd != null;
  }

  /// True while an ad shown by [showIfReadyAndWait] is on screen.
  // bool get isShowing => _closed != null;
  bool get isShowing => _isShowing;

  static final Map<String, int> _globalAttempts = {};
  int _showAttemptsCount = 0;

  /// Shows the preloaded interstitial ad only on every [frequency]-th call.
  /// If [key] is provided, tracking is done globally across instances
  /// (persists across screen pushes). An optional [delaySeconds] can be
  /// applied. An optional [checkMounted] function checks if the widget/
  /// screen is still active before showing. An optional [onAdWillShow]
  /// callback is triggered immediately if the ad will show.
  void showWithFrequency({
    String? key,
    int frequency = 4,
    int delaySeconds = 1,
    bool Function()? checkMounted,
    VoidCallback? onAdWillShow,
  }) {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) {
      return;
    }

    int attempts;
    if (key != null) {
      attempts = (_globalAttempts[key] ?? 0) + 1;
      _globalAttempts[key] = attempts;
    } else {
      _showAttemptsCount++;
      attempts = _showAttemptsCount;
    }

    final bool willTrigger = (attempts - 1) % frequency == 0;
    debugPrint(
      '[Ads] [Interstitial] showWithFrequency: attempts=$attempts, frequency=$frequency, willTrigger=$willTrigger | AdUnit: $adUnitId',
    );

    if (willTrigger) {
      if (onAdWillShow != null) {
        onAdWillShow();
      }
      Future.delayed(Duration(seconds: delaySeconds), () {
        if (checkMounted == null || checkMounted()) {
          show();
        }
      });
    }
  }
}
