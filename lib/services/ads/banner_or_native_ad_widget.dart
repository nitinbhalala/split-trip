import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/services/ads/banner_ad_widget.dart';
import 'package:split_trip/services/ads/native_ad_widget.dart';
import 'package:split_trip/services/ads/ad_cache_manager.dart';
import 'package:split_trip/services/ads/ad_log.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';

/// Tries a Banner ad first; if it fails to load (no fill / network error),
/// falls back to a Native ad ([NativeAdWidget]) in the same spot instead of
/// leaving the slot empty. Always prefers whichever format actually has a
/// loaded ad, maximizing fill/impressions for that slot.
class BannerOrNativeAdWidget extends StatefulWidget {
  const BannerOrNativeAdWidget({
    super.key,
    required this.bannerAdUnitId,
    required this.nativeAdUnitId,
    required this.bannerPlacementId,
    required this.nativePlacementId,
    this.nativeFactoryId = 'listTile',
    this.nativeHeight = 80,
    this.loadDebounce = const Duration(milliseconds: 0),
  });

  final String bannerAdUnitId;
  final String nativeAdUnitId;

  /// Cache key for the banner attempt — see [AdCacheManager].
  final String bannerPlacementId;

  /// Cache key for the native fallback — see [AdCacheManager]. Must differ
  /// from [bannerPlacementId] (different ad types = separate cache entries).
  final String nativePlacementId;
  final String nativeFactoryId;
  final double nativeHeight;
  final Duration loadDebounce;

  @override
  State<BannerOrNativeAdWidget> createState() => _BannerOrNativeAdWidgetState();
}

class _BannerOrNativeAdWidgetState extends State<BannerOrNativeAdWidget> {
  Timer? _loadDebounceTimer;
  Worker? _generationWorker;
  // bool _loggedFallback = false;
  /// Set once the banner fails. From then on this slot stays on the native
  /// and never asks for the banner again — no swap or blank flash when the
  /// banner's 30 s cooldown ends.
  bool _fellBack = false;

  @override
  void initState() {
    super.initState();
    _generationWorker = ever(
      AdCacheManager.instance.generation,
      (_) => _requestBanner(),
    );
    _loadDebounceTimer = Timer(widget.loadDebounce, _requestBanner);
  }

  bool _cacheChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cacheChecked) return;
    _cacheChecked = true;
    _preferCachedAd();
  }

  /// Cache first: a loaded ad that was never shown — banner or native, own
  /// or left behind by another screen — is used before any new request.
  /// Runs once, before the first build.
  void _preferCachedAd() {
    if (!AdUnitIds.adsEnabled) return;
    final m = AdCacheManager.instance;
    final bannerState = m.bannerEntry(widget.bannerPlacementId)?.state;
    final nativeState = m.nativeEntry(widget.nativePlacementId)?.state;

    // Own banner cached or on its way → normal banner path.
    if (bannerState == AdLoadState.loaded ||
        bannerState == AdLoadState.loading) {
      return;
    }
    // Own native cached or on its way (left unshown last visit) → use it.
    if (nativeState == AdLoadState.loaded ||
        nativeState == AdLoadState.loading) {
      _useNative('own native ${nativeState!.name}');
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (m.adoptUnshownBannerFor(
      widget.bannerPlacementId,
      AdCacheManager.bannerSizeKey(width, null),
      notify: false,
    )) {
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (m.adoptUnshownNativeFor(
      widget.nativePlacementId,
      AdCacheManager.nativeStyleKey(widget.nativeFactoryId, isDark),
      notify: false,
    )) {
      _useNative('unshown native from cache');
    }
  }

  void _useNative(String why) {
    _fellBack = true;
    logAd(
      'banner',
      'CACHE_FIRST',
      widget.bannerPlacementId,
      '$why → native ${widget.nativePlacementId}, no banner request',
    );
  }

  void _requestBanner() {
    if (!mounted) return;
    if (_fellBack) return;
    if (!AdUnitIds.adsEnabled || widget.bannerAdUnitId.isEmpty) return;
    final width = MediaQuery.of(context).size.width.truncate();

    AdCacheManager.instance.requestBannerAd(
      placementId: widget.bannerPlacementId,
      adUnitId: widget.bannerAdUnitId,
      adWidth: width,
    );
  }

  @override
  void dispose() {
    _loadDebounceTimer?.cancel();
    _generationWorker?.dispose();
    // The banner may still be loading with no BannerAdWidget mounted yet —
    // clear both placements here too, so the next visit starts fresh.
    final bannerId = widget.bannerPlacementId;
    final nativeId = widget.nativePlacementId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdCacheManager.instance.onSlotClosed(bannerId);
      AdCacheManager.instance.onSlotClosed(nativeId);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdUnitIds.adsEnabled) return const SizedBox.shrink();

    return Obx(() {
      AdCacheManager.instance.generation.value;
      final bannerEntry = AdCacheManager.instance.bannerEntry(
        widget.bannerPlacementId,
      );
      final bannerAd = bannerEntry?.ad;

      if (!_fellBack &&
          bannerEntry != null &&
          bannerEntry.state == AdLoadState.loaded &&
          bannerAd != null) {
        // BannerAdWidget owns the one-AdWidget-per-ad slot guard — rendering
        // the cached BannerAd directly here would bypass it.
        return BannerAdWidget(
          adUnitId: widget.bannerAdUnitId,
          placementId: widget.bannerPlacementId,
        );
      }

      if (!_fellBack && bannerEntry?.state != AdLoadState.failed) {
        // Still waiting on the banner's first attempt — give it the chance
        // to load before falling back, so the native ad isn't requested
        // needlessly on every screen visit.
        return const SizedBox.shrink();
      }

      // Banner failed to load (no fill / error) — fall back to native so
      // the slot doesn't sit empty.
      // if (!_loggedFallback) {
      //   _loggedFallback = true;
      if (!_fellBack) {
        _fellBack = true;
        logAd(
          'banner',
          'FALLBACK',
          widget.bannerPlacementId,
          'banner failed → native ${widget.nativePlacementId}',
        );
      }
      // return NativeAdWidget(
      //   adUnitId: widget.nativeAdUnitId,
      //   placementId: widget.nativePlacementId,
      //   factoryId: widget.nativeFactoryId,
      //   height: widget.nativeHeight,
      // );
      // SafeArea like BannerAdWidget, so a bottom-bar native clears the
      // system nav bar; inside an already-safe body it adds nothing.
      return SafeArea(
        top: false,
        child: NativeAdWidget(
          adUnitId: widget.nativeAdUnitId,
          placementId: widget.nativePlacementId,
          factoryId: widget.nativeFactoryId,
          height: widget.nativeHeight,
        ),
      );
    });
  }
}
