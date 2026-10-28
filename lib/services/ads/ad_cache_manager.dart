import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/data/service/network_service.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';

/// A single placement failing to fill (no-fill/network) is normal ad-network
/// behavior, not a bug — logging every one of those as an error would just
/// be noise. Only a placement that keeps failing this many times in a row
/// (config mistake, wrong ad unit ID, factory not registered, etc.) gets
/// logged once with [AppLogger.error] (Split Trip has no Crashlytics).
const int _kReportAfterConsecutiveFailures = 5;

enum AdLoadState { notLoaded, loading, loaded, failed }

class NativeAdCacheEntry {
  NativeAdCacheEntry(this.placementId);

  /// Current owner key — changes when another placement adopts this ad.
  String placementId;
  NativeAd? ad;
  AdLoadState state = AdLoadState.notLoaded;
  int failCount = 0;
  DateTime? lastAttempt;
  DateTime? loadedAt;

  /// True after the first impression — no longer free to hand to another slot.
  bool impressed = false;

  /// `factoryId|isDark` — the native factory bakes these into the view, so
  /// an ad is only handed to a slot asking for the same look.
  String? styleKey;
}

class BannerAdCacheEntry {
  BannerAdCacheEntry(this.placementId);

  /// Current owner key — changes when another placement adopts this ad.
  String placementId;
  BannerAd? ad;
  AdLoadState state = AdLoadState.notLoaded;
  int failCount = 0;
  DateTime? lastAttempt;
  DateTime? loadedAt;

  /// True after the first impression — no longer free to hand to another slot.
  bool impressed = false;

  /// `anchored:<widthDp>` — an ad is only handed to a slot of the same size.
  String? sizeKey;
}

/// Centralized owner of every NativeAd/BannerAd instance in the app, keyed
/// by a stable `placementId` (one per on-screen ad slot — NOT the raw ad
/// unit ID, since the same ad unit ID can be reused across placements,
/// especially under [AdUnitIds.testAds] where every native/banner slot
/// shares Google's single public test unit).
///
/// Screens/widgets never create or dispose ads themselves — they ask this
/// manager for the current state of their placement and get notified (via
/// [generation]) when it changes:
///  - a cached, already-loaded ad for that placement (reuse, no request)
///  - a load already in progress for that placement (no duplicate request)
///  - nothing yet (issue exactly one load request)
///
/// Ads only ever get invalidated (disposed + cache cleared) on a background →
/// foreground app transition — never on ordinary in-app screen navigation,
/// where the widget owning a placement is simply unmounted and remounted
/// while the cached ad underneath survives untouched. Whether a resume
/// invalidates anything at all is gated by [reloadAdsOnResume]: off (the
/// current setting) means every cached native/banner ad — and its
/// impression — just keeps showing indefinitely, resume or not; on means
/// only ads older than [_staleAfter] get reloaded, so a brief background dip
/// (switching apps for a few seconds, answering a notification) still leaves
/// every still-fresh cached ad alone rather than firing a simultaneous
/// reload burst across every placement the user has ever visited this
/// session.
class AdCacheManager extends GetxService with WidgetsBindingObserver {
  static AdCacheManager get instance => Get.find<AdCacheManager>();

  final Map<String, NativeAdCacheEntry> _native = {};
  final Map<String, BannerAdCacheEntry> _banner = {};

  /// Bumped on every cache mutation (loaded/failed/invalidated) so widgets
  /// listening via [Obx] re-render to pick up the new cached ad — this is a
  /// read-side signal only; it never itself triggers a load.
  final RxInt generation = 0.obs;

  static const Duration _retryCooldown = Duration(seconds: 30);

  /// How long a cached, already-loaded ad may sit before a background →
  /// foreground return will bother reloading it. Short app switches
  /// (checking a notification, a few seconds/minutes away) are far more
  /// common than genuinely stale content, so this stays generous rather than
  /// reloading on every single resume. Only consulted when
  /// [reloadAdsOnResume] is `true`.
  static const Duration _staleAfter = Duration(minutes: 0);

  /// Master on/off switch for reloading ANY cached ad (native or banner) on
  /// a background → foreground return. `true` = reload whatever's crossed
  /// [_staleAfter] (the behavior above); `false` = never reload on resume at
  /// all — every placement just keeps showing its already-cached ad/
  /// impression indefinitely, no matter how long the app sat backgrounded.
  /// Off here: the ported behavior must not change, this
  /// just wires the infrastructure up for later.
  static const bool reloadAdsOnResume = false;

  bool _wasBackgrounded = false;

  AdCacheManager init() {
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final entry in _native.values) {
      entry.ad?.dispose();
    }
    for (final entry in _banner.values) {
      entry.ad?.dispose();
    }
    _native.clear();
    _banner.clear();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive`/`hidden` fire for transient interruptions (system dialogs,
    // notification shade, an incoming call) — only `paused` means the app
    // actually left the foreground, and only a `resumed` that follows a
    // real `paused` counts as a background → foreground return.
    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      if (reloadAdsOnResume) {
        _invalidateStaleAds();
      }
      // else: reloadAdsOnResume is off — leave every cached native/banner ad
      // (and its impression) exactly as-is, no matter how long the app was
      // backgrounded.
    }
  }

  /// Only reloads ads that are actually old enough to matter — a
  /// `loading`/`notLoaded`/`failed` entry is left untouched (nothing stale to
  /// reload; a `loading` one has a request already in flight, so pulling it
  /// out from under that callback would just cause a duplicate request once
  /// the widget notices "no ad" and asks again).
  void _invalidateStaleAds() {
    final now = DateTime.now();
    bool isStale(DateTime? loadedAt) =>
        loadedAt == null || now.difference(loadedAt) >= _staleAfter;

    final staleNativeKeys = _native.entries
        .where(
          (e) =>
              e.value.state == AdLoadState.loaded && isStale(e.value.loadedAt),
        )
        .map((e) => e.key)
        .toList();
    final staleBannerKeys = _banner.entries
        .where(
          (e) =>
              e.value.state == AdLoadState.loaded && isStale(e.value.loadedAt),
        )
        .map((e) => e.key)
        .toList();

    if (staleNativeKeys.isEmpty && staleBannerKeys.isEmpty) return;

    debugPrint(
      '[AdCache] 🔄 App returned from background — invalidating ${staleNativeKeys.length} stale '
      'native + ${staleBannerKeys.length} stale banner ad(s) (kept ${_native.length - staleNativeKeys.length} '
      'native + ${_banner.length - staleBannerKeys.length} banner still-fresh, untouched).',
    );
    // for (final key in staleNativeKeys) {
    //   _native.remove(key)?.ad?.dispose();
    // }
    // for (final key in staleBannerKeys) {
    //   _banner.remove(key)?.ad?.dispose();
    // }
    // generation.value++;
    invalidatePlacements([...staleNativeKeys, ...staleBannerKeys]);
  }

  /// Placements whose ad survives leaving the screen — the main screen's
  /// (bottom banner + exit sheet, preloaded there). Every other placement is
  /// cleared once its screen closes, so each visit loads a fresh ad.
  static const Set<String> keepAcrossVisits = {
    'main_bottom_banner',
    'exit_dialog_native',
    'exit_dialog_banner',
  };

  /// A slot for [placementId] left the screen. Unless it is a main-screen
  /// placement or another open slot still shows it:
  ///  - ad already **shown** (impression) or failed → cleared, so the next
  ///    visit requests a fresh one;
  ///  - ad loaded but **never shown**, or still loading → kept, and handed
  ///    first to the next slot that needs one (see [_adoptUnshownNative]).
  void onSlotClosed(String placementId) {
    if (keepAcrossVisits.contains(placementId)) return;
    if (nativeSlotOwner[placementId] != null ||
        bannerSlotOwner[placementId] != null) {
      return;
    }
    // invalidatePlacements([
    //   placementId,
    // ], reason: 'screen closed → fresh ad on next visit');
    final native = _native[placementId];
    final banner = _banner[placementId];
    bool keep(AdLoadState? state, bool impressed) =>
        state == AdLoadState.loading ||
        (state == AdLoadState.loaded && !impressed);
    final keepNative = keep(native?.state, native?.impressed ?? false);
    final keepBanner = keep(banner?.state, banner?.impressed ?? false);
    if (native != null && keepNative) {
      logAd('native', 'KEPT_UNSHOWN', placementId, native.state.name);
    }
    if (banner != null && keepBanner) {
      logAd('banner', 'KEPT_UNSHOWN', placementId, banner.state.name);
    }
    if ((native != null && !keepNative) || (banner != null && !keepBanner)) {
      // Only the side that was shown/failed; an unshown twin stays cached.
      if (native != null && !keepNative) {
        _native.remove(placementId);
        native.ad?.dispose();
        logAd('native', 'INVALIDATED', placementId, 'shown → fresh next visit');
      }
      if (banner != null && !keepBanner) {
        _banner.remove(placementId);
        banner.ad?.dispose();
        logAd('banner', 'INVALIDATED', placementId, 'shown → fresh next visit');
      }
      generation.value++;
    }
  }

  bool _bannerAbsent(String placementId) {
    final state = _banner[placementId]?.state;
    return state != AdLoadState.loaded && state != AdLoadState.loading;
  }

  bool _hasUnshownNative() => _native.entries.any(
    (e) =>
        !keepAcrossVisits.contains(e.key) &&
        e.value.state == AdLoadState.loaded &&
        e.value.ad != null &&
        !e.value.impressed &&
        nativeSlotOwner[e.key] == null,
  );

  /// Completes once [placementId]'s ad is no longer loading — with
  /// `loaded`, `failed`, or null (nothing requested) — or after [timeout]
  /// with whatever state it has then.
  Future<AdLoadState?> waitUntilSettled({
    required String placementId,
    required bool native,
    required Duration timeout,
  }) {
    AdLoadState? state() =>
        native ? _native[placementId]?.state : _banner[placementId]?.state;
    bool settled(AdLoadState? s) =>
        s == null || s == AdLoadState.loaded || s == AdLoadState.failed;
    if (settled(state())) return Future.value(state());

    final done = Completer<AdLoadState?>();
    final timer = Timer(timeout, () {
      if (!done.isCompleted) done.complete(state());
    });
    final worker = ever(generation, (_) {
      if (settled(state()) && !done.isCompleted) done.complete(state());
    });
    return done.future.whenComplete(() {
      timer.cancel();
      worker.dispose();
    });
  }

  /// Size key used to match banners — same for request and reuse.
  static String bannerSizeKey(int adWidth, AdSize? fixedSize) =>
      fixedSize != null
      ? 'fixed:${fixedSize.width}x${fixedSize.height}'
      : 'anchored:$adWidth';

  /// Style key used to match natives — same for request and reuse.
  static String nativeStyleKey(String factoryId, bool isDark) =>
      '$factoryId|$isDark';

  /// Gives [placementId] a cached, never-shown native with this look from
  /// another placement. For fallback slots picking a format before any
  /// request. [notify] false = safe to call during build.
  bool adoptUnshownNativeFor(
    String placementId,
    String styleKey, {
    bool notify = true,
  }) => _adoptUnshownNative(placementId, styleKey, notify: notify);

  /// Banner twin of [adoptUnshownNativeFor].
  bool adoptUnshownBannerFor(
    String placementId,
    String sizeKey, {
    bool notify = true,
  }) => _adoptUnshownBanner(placementId, sizeKey, notify: notify);

  /// Disposes these placements' native + banner entries and notifies slots,
  /// so mounted slots request fresh ads right away.
  // void invalidatePlacements(Iterable<String> placementIds) {
  void invalidatePlacements(Iterable<String> placementIds, {String? reason}) {
    var removed = 0;
    for (final id in placementIds) {
      final native = _native.remove(id);
      if (native != null) {
        native.ad?.dispose();
        removed++;
        logAd('native', 'INVALIDATED', id, reason);
      }
      final banner = _banner.remove(id);
      if (banner != null) {
        banner.ad?.dispose();
        removed++;
        logAd('banner', 'INVALIDATED', id, reason);
      }
    }
    if (removed > 0) generation.value++;
  }

  /// Moves a loaded, never-shown native ad with the same look from another
  /// placement (nobody on screen holds it) to [placementId] — no new request.
  // bool _adoptUnshownNative(String placementId, String styleKey) {
  bool _adoptUnshownNative(
    String placementId,
    String styleKey, {
    bool notify = true,
  }) {
    String? donorKey;
    for (final e in _native.entries) {
      final v = e.value;
      if (e.key != placementId &&
          // Main-screen ads (e.g. the preloaded exit sheet) stay theirs.
          !keepAcrossVisits.contains(e.key) &&
          v.state == AdLoadState.loaded &&
          v.ad != null &&
          !v.impressed &&
          v.styleKey == styleKey &&
          nativeSlotOwner[e.key] == null) {
        donorKey = e.key;
        break;
      }
    }
    if (donorKey == null) return false;
    final entry = _native.remove(donorKey)!;
    entry.placementId = placementId;
    _native[placementId] = entry;
    logAd('native', 'CACHE_REUSE', placementId, 'from $donorKey (unshown)');
    // generation.value++;
    if (notify) generation.value++;
    return true;
  }

  /// Banner twin of [_adoptUnshownNative] — matches on size instead of look.
  // bool _adoptUnshownBanner(String placementId, String sizeKey) {
  bool _adoptUnshownBanner(
    String placementId,
    String sizeKey, {
    bool notify = true,
  }) {
    String? donorKey;
    for (final e in _banner.entries) {
      final v = e.value;
      if (e.key != placementId &&
          !keepAcrossVisits.contains(e.key) &&
          v.state == AdLoadState.loaded &&
          v.ad != null &&
          !v.impressed &&
          v.sizeKey == sizeKey &&
          bannerSlotOwner[e.key] == null) {
        donorKey = e.key;
        break;
      }
    }
    if (donorKey == null) return false;
    final entry = _banner.remove(donorKey)!;
    entry.placementId = placementId;
    _banner[placementId] = entry;
    logAd('banner', 'CACHE_REUSE', placementId, 'from $donorKey (unshown)');
    // generation.value++;
    if (notify) generation.value++;
    return true;
  }

  NativeAdCacheEntry? nativeEntry(String placementId) => _native[placementId];

  BannerAdCacheEntry? bannerEntry(String placementId) => _banner[placementId];

  /// Tracks which live [NativeAdWidget] instance (identified by an opaque
  /// token) currently owns rendering the cached [NativeAd] for a placement —
  /// the plugin does not allow the same underlying [NativeAd] object to be
  /// mounted inside two `AdWidget`s at once.
  final RxMap<String, Object> nativeSlotOwner = <String, Object>{}.obs;

  void claimNativeSlot(String placementId, Object token) {
    nativeSlotOwner[placementId] = token;
  }

  void releaseNativeSlot(String placementId, Object token) {
    if (nativeSlotOwner[placementId] == token) {
      nativeSlotOwner.remove(placementId);
    }
  }

  /// Same one-`AdWidget`-per-ad guard as [nativeSlotOwner], for cached
  /// [BannerAd]s.
  final RxMap<String, Object> bannerSlotOwner = <String, Object>{}.obs;

  void claimBannerSlot(String placementId, Object token) {
    bannerSlotOwner[placementId] = token;
  }

  void releaseBannerSlot(String placementId, Object token) {
    if (bannerSlotOwner[placementId] == token) {
      bannerSlotOwner.remove(placementId);
    }
  }

  bool _canRetry(DateTime? lastAttempt) {
    if (lastAttempt == null) return true;
    return DateTime.now().difference(lastAttempt) >= _retryCooldown;
  }

  /// Requests a Native ad for [placementId]. No-ops if a load is already in
  /// flight, an ad is already cached, or a recent failure is still within
  /// its retry cooldown — the caller does not need to check state first.
  // void requestNativeAd({
  void requestNativeAd({
    required String placementId,
    required String adUnitId,
    required String factoryId,
    required bool isDark,
    // false = always a fresh request (e.g. exit sheet), never an unshown ad
    // adopted from another placement.
    bool reuseUnshown = true,
  // }) {
  }) async {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) return;

    // final styleKey = '$factoryId|$isDark';
    final styleKey = nativeStyleKey(factoryId, isDark);

    // 1) Reuse an unshown ad from another placement before loading a new one.
    final existing = _native[placementId];
    if (reuseUnshown &&
        existing?.state != AdLoadState.loaded &&
        existing?.state != AdLoadState.loading &&
        _adoptUnshownNative(placementId, styleKey)) {
      return;
    }

    // final entry = _native.putIfAbsent(placementId, () => NativeAdCacheEntry());
    // if (entry.state == AdLoadState.loading ||
    //     entry.state == AdLoadState.loaded) {
    //   return;
    // }
    // if (entry.state == AdLoadState.failed && !_canRetry(entry.lastAttempt)) {
    //   return;
    // }
    final entry = _native.putIfAbsent(
      placementId,
      () => NativeAdCacheEntry(placementId),
    );
    // 2) Already loaded → show from cache. 3) In flight → wait for it.
    if (entry.state == AdLoadState.loaded) {
      logAd('native', 'CACHE_HIT', placementId);
      return;
    }
    if (entry.state == AdLoadState.loading) {
      logAd('native', 'WAIT_LOADING', placementId);
      return;
    }
    // 4) Failed recently → wait out the cooldown.
    if (entry.state == AdLoadState.failed && !_canRetry(entry.lastAttempt)) {
      logAd(
        'native',
        'SKIP_COOLDOWN',
        placementId,
        '${_cooldownLeft(entry.lastAttempt)}s left',
      );
      return;
    }

    // 5) Load exactly once.
    entry.state = AdLoadState.loading;
    entry.lastAttempt = DateTime.now();
    entry.styleKey = styleKey;
    entry.impressed = false;

    // No internet → no request; failed like a no-fill (cooldown, fallback).
    if (!await _isOnline('native', placementId, entry)) return;

    // Dynamic ID (every screen except the main one): the next ID from the
    // list, picked only now that a load really goes out.
    final unitId = AdUnitIds.resolveNative(adUnitId);
    if (unitId.isEmpty) {
      entry.state = AdLoadState.failed;
      entry.failCount++;
      logAd('native', 'LOAD_FAILED', placementId, 'no native ID in the list');
      generation.value++;
      return;
    }

    // debugPrint(
    //   '[Native] Load Started | Placement: $placementId | AdUnit: $unitId',
    // );
    logAd(
      'native',
      'LOAD_START',
      placementId,
      'factory: $factoryId | dark: $isDark | AdUnit: $unitId',
    );
    AppLogger.warning(
      '[Native] Loading... | Placement: $placementId | AdUnit: $unitId',
      useDebug: true,
    );

    NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      factoryId: factoryId,
      customOptions: {'isDark': isDark},
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final nativeAd = ad as NativeAd;
          final adapterName =
              nativeAd.responseInfo?.mediationAdapterClassName ?? '';
          // debugPrint(
          //   '[Native] Loaded | Placement: $placementId | AdUnit: $unitId',
          // );
          logAd('native', 'LOADED', entry.placementId, 'AdUnit: $unitId');
          AppLogger.success(
            '[Native] Mediation Adapter: $adapterName | Placement: $placementId',
            useDebug: true,
          );
          // Invalidated while loading → this ad has no owner any more.
          if (!identical(_native[entry.placementId], entry)) {
            ad.dispose();
            return;
          }
          entry.ad = nativeAd;
          entry.state = AdLoadState.loaded;
          entry.failCount = 0;
          entry.loadedAt = DateTime.now();
          generation.value++;
        },
        onAdFailedToLoad: (ad, error) {
          // logAdError(
          //   '[Native] Load Failed: code=${error.code}, message=${error.message} | Placement: $placementId | AdUnit: $unitId',
          // );
          logAd(
            'native',
            'LOAD_FAILED',
            entry.placementId,
            'code=${error.code}, message=${error.message} | '
                'fail #${entry.failCount + 1} | retry after ${_retryCooldown.inSeconds}s',
          );
          ad.dispose();
          entry.ad = null;
          entry.state = AdLoadState.failed;
          entry.failCount++;
          generation.value++;
          AppLogger.error(
            '[Native] Load Failed: code=${error.code}, message=${error.message} | Placement: $placementId',
          );
          if (entry.failCount == _kReportAfterConsecutiveFailures) {
            AppLogger.error(
              'Native ad "$placementId" (AdUnit: $unitId) failed to load '
              '$_kReportAfterConsecutiveFailures times in a row: '
              'code=${error.code}, message=${error.message}',
            );
          }
        },
        // Ad revenue → Firebase `ad_impression`. entry.placementId = the slot
        // that actually showed it (follows the ad if another slot adopted it).
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          AnalyticsService.trackAdRevenue(
            ad: ad,
            valueMicros: valueMicros,
            currencyCode: currencyCode,
            adFormat: AnalyticsAdFormat.native,
            placement: entry.placementId,
          );
        },
        onAdImpression: (ad) {
          // debugPrint(
          //   '[Native] Impression | Placement: $placementId | AdUnit: $unitId',
          // );
          entry.impressed = true;
          logAd('native', 'IMPRESSION', entry.placementId);
        },
      ),
    ).load();
  }

  /// False (no ad request) when there is no internet: [entry] is marked
  /// failed — the banner slot falls back / hides, retry after the cooldown —
  /// or when the entry was dropped while checking.
  Future<bool> _isOnline(String type, String placementId, dynamic entry) async {
    final online = await NetworkService.hasInternetCached();
    final map = type == 'native' ? _native : _banner;
    if (!identical(map[placementId], entry)) return false;
    if (online) return true;
    entry.state = AdLoadState.failed;
    logAd(type, 'SKIP_OFFLINE', placementId, 'no internet → no request');
    generation.value++;
    return false;
  }

  int _cooldownLeft(DateTime? lastAttempt) => lastAttempt == null
      ? 0
      : (_retryCooldown - DateTime.now().difference(lastAttempt)).inSeconds;

  /// Fire this from the button/tap handler that navigates to a screen with a
  /// [BannerAdWidget] — e.g. right before `Get.toNamed(AppRoutes.profile)` —
  /// so the load already has a head start over the ~300ms page transition
  /// instead of only starting once that screen's widget mounts. Safe to call
  /// from a Controller (no BuildContext needed) and safe to call repeatedly:
  /// [requestBannerAd] itself no-ops once a load is in flight or cached, and
  /// the destination screen's own [BannerAdWidget] just picks up whatever
  /// this already started/finished.
  void preloadBanner({required String placementId, required String adUnitId}) {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) return;
    // Cache first: an unshown native is waiting — the screen's
    // banner-or-native slot will use it, so don't fire a banner request.
    if (_bannerAbsent(placementId) && _hasUnshownNative()) {
      logAd('banner', 'PRELOAD_SKIPPED', placementId, 'unshown native cached');
      return;
    }
    final context = Get.context;
    if (context == null) return;
    final width = MediaQuery.of(context).size.width.truncate();
    requestBannerAd(
      placementId: placementId,
      adUnitId: adUnitId,
      adWidth: width,
    );
  }

  /// Requests a Banner ad for [placementId]. Same dedup/retry rules as
  /// [requestNativeAd].
  void requestBannerAd({
    required String placementId,
    required String adUnitId,
    required int adWidth,
    // Fixed size (e.g. AdSize.largeBanner) instead of the anchored adaptive.
    AdSize? fixedSize,
    // false = always a fresh request, see [requestNativeAd].
    bool reuseUnshown = true,
  }) async {
    if (!AdUnitIds.adsEnabled || adUnitId.isEmpty) return;

    // final sizeKey = 'anchored:$adWidth';
    // final sizeKey = fixedSize != null
    //     ? 'fixed:${fixedSize.width}x${fixedSize.height}'
    //     : 'anchored:$adWidth';
    final sizeKey = bannerSizeKey(adWidth, fixedSize);

    // 1) Reuse an unshown ad from another placement before loading a new one.
    final existing = _banner[placementId];
    if (existing?.state != AdLoadState.loaded &&
        existing?.state != AdLoadState.loading &&
        reuseUnshown &&
        _adoptUnshownBanner(placementId, sizeKey)) {
      return;
    }

    // final entry = _banner.putIfAbsent(placementId, () => BannerAdCacheEntry());
    // if (entry.state == AdLoadState.loading ||
    //     entry.state == AdLoadState.loaded) {
    //   return;
    // }
    // if (entry.state == AdLoadState.failed && !_canRetry(entry.lastAttempt)) {
    //   return;
    // }
    final entry = _banner.putIfAbsent(
      placementId,
      () => BannerAdCacheEntry(placementId),
    );
    // 2) Already loaded → show from cache. 3) In flight → wait for it.
    if (entry.state == AdLoadState.loaded) {
      logAd('banner', 'CACHE_HIT', placementId);
      return;
    }
    if (entry.state == AdLoadState.loading) {
      logAd('banner', 'WAIT_LOADING', placementId);
      return;
    }
    // 4) Failed recently → wait out the cooldown.
    if (entry.state == AdLoadState.failed && !_canRetry(entry.lastAttempt)) {
      logAd(
        'banner',
        'SKIP_COOLDOWN',
        placementId,
        '${_cooldownLeft(entry.lastAttempt)}s left',
      );
      return;
    }

    // 5) Load exactly once.
    entry.state = AdLoadState.loading;
    entry.lastAttempt = DateTime.now();
    entry.sizeKey = sizeKey;
    entry.impressed = false;

    // No internet → no request; failed like a no-fill (cooldown, fallback).
    if (!await _isOnline('banner', placementId, entry)) return;

    // Dynamic ID (every screen except the main one): the next ID from the
    // list, picked only now that a load really goes out.
    final unitId = AdUnitIds.resolveBanner(adUnitId);
    if (unitId.isEmpty) {
      entry.state = AdLoadState.failed;
      entry.failCount++;
      logAd('banner', 'LOAD_FAILED', placementId, 'no banner ID in the list');
      generation.value++;
      return;
    }

    // debugPrint(
    //   '[Banner] Load Started | Placement: $placementId | AdUnit: $unitId',
    // );
    logAd(
      'banner',
      'LOAD_START',
      placementId,
      'size: $sizeKey | AdUnit: $unitId',
    );
    AppLogger.warning(
      '[Banner] Loading... | Placement: $placementId | AdUnit: $unitId',
      useDebug: true,
    );

    // final adSize =
    //     // ignore: deprecated_member_use
    //     await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);
    final adSize =
        fixedSize ??
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);
    // if (adSize == null) return;
    // No size → mark failed, otherwise the entry stays stuck in `loading`.
    if (adSize == null) {
      entry.state = AdLoadState.failed;
      entry.failCount++;
      logAd('banner', 'LOAD_FAILED', placementId, 'adaptive size unavailable');
      generation.value++;
      return;
    }
    BannerAd(
      adUnitId: unitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final bannerAd = ad as BannerAd;
          final adapterName =
              bannerAd.responseInfo?.mediationAdapterClassName ?? '';
          // debugPrint(
          //   '[Banner] Loaded | Placement: $placementId | AdUnit: $unitId',
          // );
          // Auto-refresh of a banner already showing — nothing to change.
          if (entry.state == AdLoadState.loaded) {
            logAd('banner', 'REFRESHED', entry.placementId);
            return;
          }
          logAd('banner', 'LOADED', entry.placementId, 'AdUnit: $unitId');
          AppLogger.success(
            '[Banner] Mediation Adapter: $adapterName | Placement: $placementId',
            useDebug: true,
          );
          // Invalidated while loading → this ad has no owner any more.
          if (!identical(_banner[entry.placementId], entry)) {
            ad.dispose();
            return;
          }
          entry.ad = bannerAd;
          entry.state = AdLoadState.loaded;
          entry.failCount = 0;
          entry.loadedAt = DateTime.now();
          generation.value++;
        },
        onAdFailedToLoad: (ad, error) {
          // logAdError(
          //   '[Banner] Load Failed: code=${error.code}, message=${error.message} | Placement: $placementId | AdUnit: $unitId',
          // );
          // Also fires for the SDK's own internal banner auto-refresh. If a
          // refresh attempt gets no-fill/network error on an ad that was
          // already showing successfully, `ad` here IS the still-mounted,
          // on-screen entry.ad — disposing it would blank the banner slot
          // for up to `_retryCooldown` even though a good creative was
          // already visible. Only a failure on the very first load should
          // actually clear the slot and go to the failed/retry path.
          if (entry.state == AdLoadState.loaded) {
            entry.failCount++;
            logAd(
              'banner',
              'REFRESH_FAILED',
              entry.placementId,
              'code=${error.code} | keeping the visible ad',
            );
            return;
          }
          logAd(
            'banner',
            'LOAD_FAILED',
            entry.placementId,
            'code=${error.code}, message=${error.message} | '
                'fail #${entry.failCount + 1} | retry after ${_retryCooldown.inSeconds}s',
          );
          ad.dispose();
          entry.ad = null;
          entry.state = AdLoadState.failed;
          entry.failCount++;
          generation.value++;
          AppLogger.error(
            '[Banner] Load Failed: code=${error.code}, message=${error.message} | Placement: $placementId',
          );
          if (entry.failCount == _kReportAfterConsecutiveFailures) {
            AppLogger.error(
              'Banner ad "$placementId" (AdUnit: $unitId) failed to load '
              '$_kReportAfterConsecutiveFailures times in a row: '
              'code=${error.code}, message=${error.message}',
            );
          }
        },
        // Ad revenue → Firebase `ad_impression`. entry.placementId = the slot
        // that actually showed it (follows the ad if another slot adopted it).
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          AnalyticsService.trackAdRevenue(
            ad: ad,
            valueMicros: valueMicros,
            currencyCode: currencyCode,
            adFormat: AnalyticsAdFormat.banner,
            placement: entry.placementId,
          );
        },
        onAdImpression: (ad) {
          // debugPrint(
          //   '[Banner] Impression | Placement: $placementId | AdUnit: $unitId',
          // );
          entry.impressed = true;
          logAd('banner', 'IMPRESSION', entry.placementId);
        },
      ),
    ).load();
  }
}
