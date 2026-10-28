import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/services/ads/ad_cache_manager.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A reusable Banner Ad widget (adaptive banner).
///
/// Loading/caching/disposal of the underlying [BannerAd] is fully owned by
/// [AdCacheManager], keyed by [placementId] — this widget only asks the
/// manager for an ad and renders whatever is currently cached.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    this.placementId,
    this.loadDebounce = _kDefaultAdLoadDebounce,
    this.adSize,
  });

  /// Static ad unit ID for the screen this widget is used on (see AdUnitIds).
  final String adUnitId;

  /// Stable identity of this on-screen ad slot, used as the cache key in
  /// [AdCacheManager] — e.g. `'home_bottom_banner'`. Must be unique per
  /// simultaneously-mountable ad slot; slots that are never on screen
  /// together may safely share one. Defaults to [adUnitId] when omitted,
  /// which is only safe when that ID is itself already unique to this slot
  /// (not the case under [AdUnitIds.testAds]).
  final String? placementId;

  /// Ad slot must stay on screen this long before an actual load request is
  /// issued to the cache manager — avoids wasted AdMob requests when the
  /// user scrolls/navigates past a slot quickly.
  final Duration loadDebounce;

  /// Fixed banner size (e.g. [AdSize.largeBanner] 320x100), shown centred.
  /// Null = anchored adaptive banner at screen width.
  final AdSize? adSize;

  String get _placementId => placementId ?? adUnitId;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

const Duration _kDefaultAdLoadDebounce = Duration(milliseconds: 0);

class _BannerAdWidgetState extends State<BannerAdWidget> {
  Timer? _loadDebounceTimer;
  Worker? _generationWorker;

  /// [AdCacheManager.bannerSlotOwner] — the plugin throws "This AdWidget is
  /// already in the Widget tree" if one cached BannerAd is mounted twice.
  final Object _slotToken = Object();
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
        AdCacheManager.instance.claimBannerSlot(
          widget._placementId,
          _slotToken,
        );
      }
    });
    _generationWorker = ever(
      AdCacheManager.instance.generation,
      (_) => _requestAd(),
    );
    _loadDebounceTimer = Timer(widget.loadDebounce, _requestAd);
  }

  void _requestAd() {
    if (!mounted) return;
    if (!AdUnitIds.adsEnabled || widget.adUnitId.isEmpty) return;
    final width = MediaQuery.of(context).size.width.truncate();

    AdCacheManager.instance.requestBannerAd(
      placementId: widget._placementId,
      adUnitId: widget.adUnitId,
      adWidth: width,
      fixedSize: widget.adSize,
    );
  }

  @override
  void dispose() {
    _loadDebounceTimer?.cancel();
    _generationWorker?.dispose();
    final placementId = widget._placementId;
    final token = _slotToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdCacheManager.instance.releaseBannerSlot(placementId, token);
      // Not a main-screen ad → cleared, so the next visit loads a fresh one.
      AdCacheManager.instance.onSlotClosed(placementId);
    });
    // logAd('banner', 'SLOT_RELEASE', placementId, 'ad stays cached');
    logAd('banner', 'SLOT_RELEASE', placementId);
    // The cached BannerAd itself is NOT disposed here — AdCacheManager owns
    // its lifecycle so it survives normal screen navigation.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdUnitIds.adsEnabled || widget.adUnitId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      AdCacheManager.instance.generation.value;

      // Only the owning instance may mount the AdWidget. A covered duplicate
      // renders nothing, and takes the slot back once the owner is disposed.
      final owner =
          AdCacheManager.instance.bannerSlotOwner[widget._placementId];
      if (owner != _slotToken) {
        if (owner == null && !_reclaimScheduled) {
          _reclaimScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _reclaimScheduled = false;
            if (mounted) {
              AdCacheManager.instance.claimBannerSlot(
                widget._placementId,
                _slotToken,
              );
            }
          });
        }
        _readyToRenderAd = false;
        return const SizedBox.shrink();
      }

      // Wait one frame after gaining the slot so the previous owner has
      // already rebuilt without its AdWidget before this one mounts it.
      if (!_readyToRenderAd) {
        if (!_renderDelayScheduled) {
          _renderDelayScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _renderDelayScheduled = false;
            if (mounted &&
                AdCacheManager.instance.bannerSlotOwner[widget._placementId] ==
                    _slotToken) {
              setState(() => _readyToRenderAd = true);
            }
          });
        }
        return const SizedBox.shrink();
      }

      final entry = AdCacheManager.instance.bannerEntry(widget._placementId);
      final bannerAd = entry?.ad;

      if (entry?.state == AdLoadState.failed) {
        if (!_loggedCollapse) {
          _loggedCollapse = true;
          logAd(
            'banner',
            'COLLAPSE',
            widget._placementId,
            'load failed → 0 height',
          );
        }
        return const SizedBox.shrink();
      }

      if (entry == null ||
          entry.state != AdLoadState.loaded ||
          bannerAd == null) {
        return const SizedBox.shrink();
      }

      if (!identical(_loggedAd, bannerAd)) {
        _loggedAd = bannerAd;
        _loggedCollapse = false;
        logAd(
          'banner',
          'SHOW',
          widget._placementId,
          '${bannerAd.size.width}x${bannerAd.size.height}',
        );
      }

      return SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          width: double.infinity,
          height: bannerAd.size.height.toDouble(),
          // child: AdWidget(ad: bannerAd),
          child: widget.adSize == null
              ? AdWidget(ad: bannerAd)
              : Center(
                  child: SizedBox(
                    width: bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: bannerAd),
                  ),
                ),
        ),
      );
    });
  }
}
