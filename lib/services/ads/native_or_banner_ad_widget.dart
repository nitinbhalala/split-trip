import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:split_trip/services/ads/ad_cache_manager.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/banner_ad_widget.dart';
import 'package:split_trip/services/ads/native_ad_widget.dart';

/// Native first; only once the native has definitely FAILED does the slot
/// switch to a Banner. The banner is not requested at all before that.
/// Mirror of [BannerOrNativeAdWidget].
class NativeOrBannerAdWidget extends StatefulWidget {
  const NativeOrBannerAdWidget({
    super.key,
    required this.nativeAdUnitId,
    required this.bannerAdUnitId,
    required this.nativePlacementId,
    required this.bannerPlacementId,
    this.nativeFactoryId = 'listTile',
    this.nativeHeight = 80,
    this.visible = true,
    this.bannerSize,
  });

  final String nativeAdUnitId;
  final String bannerAdUnitId;

  /// Cache key for the native attempt — see [AdCacheManager].
  final String nativePlacementId;

  /// Cache key for the banner fallback. Must differ from [nativePlacementId].
  final String bannerPlacementId;
  final String nativeFactoryId;
  final double nativeHeight;

  /// See [NativeAdWidget.visible].
  final bool visible;

  /// Fixed size for the fallback banner (e.g. [AdSize.largeBanner]); null =
  /// anchored adaptive. See [BannerAdWidget.adSize].
  final AdSize? bannerSize;

  @override
  State<NativeOrBannerAdWidget> createState() => _NativeOrBannerAdWidgetState();
}

class _NativeOrBannerAdWidgetState extends State<NativeOrBannerAdWidget> {
  // bool _loggedFallback = false;
  /// Set once the native fails. From then on this slot stays on the banner —
  /// if the native placement is retried elsewhere and goes back to
  /// `loading`, the banner already showing here is not swapped out.
  bool _fellBack = false;
  bool _cacheChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cacheChecked) return;
    _cacheChecked = true;
    _preferCachedAd();
  }

  /// Cache first: a loaded ad that was never shown — native or banner, own
  /// or left behind by another screen — is used before any new request.
  /// Runs once, before the first build.
  void _preferCachedAd() {
    if (!AdUnitIds.adsEnabled) return;
    final m = AdCacheManager.instance;
    final nativeState = m.nativeEntry(widget.nativePlacementId)?.state;
    final bannerState = m.bannerEntry(widget.bannerPlacementId)?.state;

    // Own native cached or on its way → normal native path.
    if (nativeState == AdLoadState.loaded ||
        nativeState == AdLoadState.loading) {
      return;
    }
    // Own banner cached or on its way (left unshown last visit) → use it.
    if (bannerState == AdLoadState.loaded ||
        bannerState == AdLoadState.loading) {
      _useBanner('own banner ${bannerState!.name}');
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (m.adoptUnshownNativeFor(
      widget.nativePlacementId,
      AdCacheManager.nativeStyleKey(widget.nativeFactoryId, isDark),
      notify: false,
    )) {
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (m.adoptUnshownBannerFor(
      widget.bannerPlacementId,
      AdCacheManager.bannerSizeKey(width, widget.bannerSize),
      notify: false,
    )) {
      _useBanner('unshown banner from cache');
    }
  }

  void _useBanner(String why) {
    _fellBack = true;
    logAd(
      'native',
      'CACHE_FIRST',
      widget.nativePlacementId,
      '$why → banner ${widget.bannerPlacementId}, no native request',
    );
  }

  @override
  void dispose() {
    // Clear both placements, so the next visit starts fresh.
    final nativeId = widget.nativePlacementId;
    final bannerId = widget.bannerPlacementId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdCacheManager.instance.onSlotClosed(nativeId);
      AdCacheManager.instance.onSlotClosed(bannerId);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdUnitIds.adsEnabled) return const SizedBox.shrink();

    return Obx(() {
      AdCacheManager.instance.generation.value;
      final nativeFailed =
          AdCacheManager.instance
              .nativeEntry(widget.nativePlacementId)
              ?.state ==
          AdLoadState.failed;

      // if (!nativeFailed) {
      if (!_fellBack && !nativeFailed) {
        // Loading or loaded — the native slot handles shimmer / ad itself.
        // return NativeAdWidget(
        //   adUnitId: widget.nativeAdUnitId,
        //   placementId: widget.nativePlacementId,
        //   factoryId: widget.nativeFactoryId,
        //   height: widget.nativeHeight,
        //   visible: widget.visible,
        // );
        // SafeArea like BannerAdWidget, so a bottom-bar native sits right
        // above the system nav bar; inside a safe body it adds nothing.
        return SafeArea(
          top: false,
          child: NativeAdWidget(
            adUnitId: widget.nativeAdUnitId,
            placementId: widget.nativePlacementId,
            factoryId: widget.nativeFactoryId,
            height: widget.nativeHeight,
            visible: widget.visible,
          ),
        );
      }

      // if (!_loggedFallback) {
      //   _loggedFallback = true;
      if (!_fellBack) {
        _fellBack = true;
        logAd(
          'native',
          'FALLBACK',
          widget.nativePlacementId,
          'native failed → banner ${widget.bannerPlacementId}',
        );
      }
      return BannerAdWidget(
        adUnitId: widget.bannerAdUnitId,
        placementId: widget.bannerPlacementId,
        adSize: widget.bannerSize,
      );
    });
  }
}
