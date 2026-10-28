import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/services/ads/ad_cache_manager.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A reusable Native Ad widget.
///
/// Loading/caching/disposal of the underlying [NativeAd] is fully owned by
/// [AdCacheManager], keyed by [placementId] — this widget only asks the
/// manager for an ad and renders whatever is currently cached.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    this.placementId,
    this.loadDebounce = _kDefaultAdLoadDebounce,
    this.factoryId = 'listTile',
    this.height = 80,
    this.visible = true,
  });

  /// Static ad unit ID for the screen this widget is used on (see AdUnitIds).
  final String adUnitId;

  /// Stable identity of this on-screen ad slot, used as the cache key in
  /// [AdCacheManager] — e.g. `'home_list_native'`. Must be unique per
  /// simultaneously-mountable ad slot (two slots that can be visible at the
  /// same time, even on different screens, must use different IDs); slots
  /// that are never on screen together may safely share one. Defaults to
  /// [adUnitId] when omitted, which is only safe when that ID is itself
  /// already unique to this slot (not the case under [AdUnitIds.testAds]).
  final String? placementId;

  /// Must match a factoryId registered natively in MainActivity
  /// (`GoogleMobileAdsPlugin.registerNativeAdFactory`). Defaults to a
  /// compact 'listTile' style; pass 'advanced' for a large
  /// headline+media+CTA card style — both must be registered natively first.
  final String factoryId;

  /// Fixed height for the ad slot — must match the natively-inflated
  /// layout's actual rendered height (wrap_content ends up unpredictable
  /// inside a platform view), so callers using a taller factoryId (e.g.
  /// 'advanced') must pass a taller value here too.
  final double height;

  /// Ad slot must stay on screen this long before an actual load request is
  /// issued to the cache manager — avoids wasted AdMob requests both when the
  /// user scrolls past a slot quickly (the widget gets disposed before the
  /// timer fires) and when flicking rapidly between tabs (see [visible] — the
  /// timer resets every time visibility toggles). Defaults to 500ms.
  final Duration loadDebounce;

  /// Whether this ad slot is actually the one the user is looking at right
  /// now — pass `false` for a slot living on an [IndexedStack] tab that
  /// isn't the current tab (kept mounted-but-offscreen rather than disposed,
  /// so its state — including this flag — persists across tab switches).
  /// Defaults to `true`, correct for a normal pushed screen where "mounted"
  /// already means "on screen".
  final bool visible;

  String get _placementId => placementId ?? adUnitId;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

const Duration _kDefaultAdLoadDebounce = Duration(milliseconds: 500);

/// Slot height for `factoryId: 'advanced'`. Fixed (not screen-scaled) so it
/// matches the native layout in dp/pt: header 40 + media (AdMob minimum
/// 120x120) + body + CTA 40 — any smaller and the AdMob validator flags it.
const double kAdvancedNativeAdHeight = 300;

class _NativeAdWidgetState extends State<NativeAdWidget> {
  Timer? loadDebounceTimer;
  Worker? generationWorker;
  bool requestScheduled = false;

  /// [AdCacheManager.nativeSlotOwner] — see that field for why this exists.
  final Object slotToken = Object();
  bool _reclaimScheduled = false;
  bool _readyToRenderAd = false;
  bool _renderDelayScheduled = false;

  /// Last ad / state logged by this slot — so SHOW/COLLAPSE log once, not on
  /// every rebuild.
  Object? _loggedAd;
  bool _loggedCollapse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AdCacheManager.instance.claimNativeSlot(widget._placementId, slotToken);
      }
    });
    generationWorker = ever(AdCacheManager.instance.generation, (_) {
      // A generation bump elsewhere doesn't mean THIS slot needs a fresh ad
      // — only react to it while actually on screen; an invisible slot just
      // picks up whatever's cached once didUpdateWidget below sees it
      // become visible again.
      if (widget.visible) requestAd();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!requestScheduled && widget.visible) {
      requestScheduled = true;
      loadDebounceTimer = Timer(widget.loadDebounce, requestAd);
    }
  }

  @override
  void didUpdateWidget(covariant NativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    loadDebounceTimer?.cancel();
    if (widget.visible) {
      // Coming back into view after being invisible — wait out the same
      // "actually stayed here" debounce as the very first mount before
      // requesting, so rapidly flicking through tabs never fires a request
      // for one just passed through. requestNativeAd() itself no-ops if
      // it's already loaded/loading, so this is a no-op once the timer does
      // fire in the common case where nothing needed to change.
      requestScheduled = true;
      loadDebounceTimer = Timer(widget.loadDebounce, requestAd);
    }
    // else: left view before the debounce above fired — cancelled it, so no
    // request ever goes out for a tab the user only flicked past.
  }

  void requestAd() {
    if (!mounted) return;
    if (!widget.visible) return;
    if (!AdUnitIds.adsEnabled || widget.adUnitId.isEmpty) return;
    AdCacheManager.instance.requestNativeAd(
      placementId: widget._placementId,
      adUnitId: widget.adUnitId,
      factoryId: widget.factoryId,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  @override
  void dispose() {
    loadDebounceTimer?.cancel();
    generationWorker?.dispose();
    final placementId = widget._placementId;
    final token = slotToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdCacheManager.instance.releaseNativeSlot(placementId, token);
      // Not a main-screen ad → cleared, so the next visit loads a fresh one.
      AdCacheManager.instance.onSlotClosed(placementId);
    });
    // logAd('native', 'SLOT_RELEASE', placementId, 'ad stays cached');
    logAd('native', 'SLOT_RELEASE', placementId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdUnitIds.adsEnabled || widget.adUnitId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      AdCacheManager.instance.generation.value;

      final owner =
          AdCacheManager.instance.nativeSlotOwner[widget._placementId];
      if (owner != slotToken) {
        if (owner == null && !_reclaimScheduled) {
          _reclaimScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _reclaimScheduled = false;
            if (mounted) {
              AdCacheManager.instance.claimNativeSlot(
                widget._placementId,
                slotToken,
              );
            }
          });
        }
        _readyToRenderAd = false;
        return const SizedBox.shrink();
      }

      if (!_readyToRenderAd) {
        if (!_renderDelayScheduled) {
          _renderDelayScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _renderDelayScheduled = false;
            if (mounted &&
                AdCacheManager.instance.nativeSlotOwner[widget._placementId] ==
                    slotToken) {
              setState(() => _readyToRenderAd = true);
            }
          });
        }
        return const SizedBox.shrink();
      }

      final entry = AdCacheManager.instance.nativeEntry(widget._placementId);
      final nativeAd = entry?.ad;

      if (entry?.state == AdLoadState.failed) {
        if (!_loggedCollapse) {
          _loggedCollapse = true;
          logAd(
            'native',
            'COLLAPSE',
            widget._placementId,
            'load failed → 0 height',
          );
        }
        return const SizedBox.shrink();
      }

      if (entry == null ||
          entry.state != AdLoadState.loaded ||
          nativeAd == null) {
        return Padding(
          // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          // Same full width as the loaded ad.
          padding: const EdgeInsets.symmetric(vertical: 5),
          // Split Trip has no shimmer widget — a plain placeholder box.
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      if (!identical(_loggedAd, nativeAd)) {
        _loggedAd = nativeAd;
        _loggedCollapse = false;
        logAd(
          'native',
          'SHOW',
          widget._placementId,
          '${widget.factoryId} | height ${widget.height}',
        );
      }

      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        child: Material(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: .08),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: widget.height,
            child: AdWidget(ad: nativeAd),
          ),
        ),
      );
    });
  }
}
