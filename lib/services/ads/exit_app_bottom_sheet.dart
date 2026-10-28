import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/services/ads/ad_cache_manager.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
// import 'package:split_trip/services/ads/native_ad_widget.dart';
import 'package:split_trip/services/ads/native_ad_widget.dart';
import 'package:split_trip/services/ads/native_or_banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shared cache placement ID between [ExitAppBottomSheet.preload] and the
/// sheet's own [NativeAdWidget] — must match exactly, or the widget ends up
/// requesting a second, separate ad instead of reusing the preloaded one.
const String _kExitDialogNativePlacementId = 'exit_dialog_native';
const String _kExitDialogBannerPlacementId = 'exit_dialog_banner';

/// Bottom sheet shown when the user presses back from the app's root screen
/// ([MainScreen]) — "Exit App?" with Exit/Cancel actions and a native ad,
/// rather than closing the app outright on a single back press.
class ExitAppBottomSheet {
  ExitAppBottomSheet._();

  /// Kicks off the sheet's native ad load as soon as the home screen is
  /// reached — well before the user ever presses back — so by the time
  /// [show] actually opens the sheet, the ad is already cached and ready
  /// instead of visibly loading in front of them. Safe to call from every
  /// build (e.g. [MainScreen]'s): [AdCacheManager.requestNativeAd] itself
  /// no-ops once a load for this placement is in flight or already cached.
  static void preload(BuildContext context) {
    if (!AdUnitIds.adsEnabled) return;
    AdCacheManager.instance.requestNativeAd(
      placementId: _kExitDialogNativePlacementId,
      adUnitId: AdUnitIds.exitDialogNative,
      // factoryId: 'advanced',
      // Must match the sheet's slot below, or the preload is never used.
      factoryId: 'listTile',
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  // static Future<void> show(BuildContext context) {
  //   return showModalBottomSheet<void>(
  //     context: context,
  //     backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) => const ExitAppSheetContent(),
  //   );
  // }

  /// Longest the user waits on back before the sheet opens anyway.
  static const Duration _maxAdWait = Duration(seconds: 5);

  static bool _opening = false;

  /// Every open: a fresh ad request, and the sheet opens only once that ad
  /// has loaded — so it appears with the ad already in place. Native first;
  /// if it fails, the banner; if both fail (or [_maxAdWait] passes), the
  /// sheet opens without waiting further.
  static Future<void> show(BuildContext context) async {
    if (_opening) return; // back pressed again while the ad loads
    _opening = true;
    try {
      if (AdUnitIds.adsEnabled) await _loadFreshAd(context);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => const ExitAppSheetContent(),
      );
    } finally {
      _opening = false;
    }
  }

  static Future<void> _loadFreshAd(BuildContext context) async {
    final m = AdCacheManager.instance;
    final deadline = DateTime.now().add(_maxAdWait);
    Duration left() {
      final d = deadline.difference(DateTime.now());
      return d.isNegative ? Duration.zero : d;
    }

    // Drop last open's ad so this open always makes a new request.
    m.invalidatePlacements([
      _kExitDialogNativePlacementId,
      _kExitDialogBannerPlacementId,
    ], reason: 'exit sheet opened → fresh ad');

    m.requestNativeAd(
      placementId: _kExitDialogNativePlacementId,
      adUnitId: AdUnitIds.exitDialogNative,
      factoryId: 'listTile',
      isDark: Theme.of(context).brightness == Brightness.dark,
      reuseUnshown: false,
    );
    final native = await m.waitUntilSettled(
      placementId: _kExitDialogNativePlacementId,
      native: true,
      timeout: left(),
    );
    if (native != AdLoadState.failed || !context.mounted) return;

    // Native failed → the sheet's fallback banner, loaded before it opens.
    m.requestBannerAd(
      placementId: _kExitDialogBannerPlacementId,
      adUnitId: AdUnitIds.exitDialogBanner,
      adWidth: MediaQuery.sizeOf(context).width.truncate(),
      fixedSize: AdSize.largeBanner,
      reuseUnshown: false,
    );
    await m.waitUntilSettled(
      placementId: _kExitDialogBannerPlacementId,
      native: false,
      timeout: left(),
    );
  }
}

class ExitAppSheetContent extends StatelessWidget {
  const ExitAppSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        // padding: AppSize.symmetric(horizontal: 20, vertical: 12),
        // No side padding here, so the ad below is full width; the sheet's
        // own content keeps its 20 via the inner Padding.
        padding: AppSize.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSize.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSize.w(40),
                      height: AppSize.h(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: theme.colorScheme.outline.withValues(alpha: .4),
                      ),
                    ),
                  ),
                  AppSize.gapH(20),
                  Text(
                    "Exit App?",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSize.gapH(8),
                  Text(
                    "Are you sure you want to exit Split Trip?",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSize.gapH(20),
                  Row(
                    spacing: AppSize.w(10),
                    children: [
                      _SheetActionButton(
                        label: "Exit",
                        onTap: () => SystemNavigator.pop(),
                        textColor: theme.colorScheme.onSurface,
                        background: theme.colorScheme.surfaceContainerHighest,
                        borderColor: theme.colorScheme.outline.withValues(
                          alpha: .9,
                        ),
                      ),
                      _SheetActionButton(
                        label: "Cancel",
                        textColor: AppColors.white,
                        background: AppColors.primary,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSize.gapH(10),
            // NativeAdWidget(
            //   height: AppSize.h(140),
            //   factoryId: 'advanced',
            //   adUnitId: AdUnitIds.exitDialogNative,
            //   placementId: _kExitDialogNativePlacementId,
            // ),
            // Native first; if it fails, a slightly big banner (320x100).
            NativeOrBannerAdWidget(
              // nativeHeight: AppSize.h(140),
              // nativeHeight: kAdvancedNativeAdHeight,
              // nativeFactoryId: 'advanced',
              // Small native (same look as the screens' fallback natives).
              nativeHeight: 80,
              nativeFactoryId: 'listTile',
              nativeAdUnitId: AdUnitIds.exitDialogNative,
              nativePlacementId: _kExitDialogNativePlacementId,
              bannerAdUnitId: AdUnitIds.exitDialogBanner,
              // bannerPlacementId: 'exit_dialog_banner',
              bannerPlacementId: _kExitDialogBannerPlacementId,
              bannerSize: AdSize.largeBanner,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _SheetActionButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
        child: Material(
          color: background,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: AppSize.symmetric(horizontal: 22, vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
