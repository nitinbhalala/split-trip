
import 'package:flutter/material.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/interstitial_ad_helper.dart';

// /// A button that shows an interstitial ad on every tap before running
// /// [onPressed] — drop this in anywhere a tap should be monetized (e.g. a
// /// dialog's confirm action) instead of a plain button; the ad-show logic
// /// lives here so callers never need to wire it up themselves. The ad is
// /// preloaded as soon as this widget is built, so it's usually already ready
// /// by the time the user actually taps.

class AppAdsButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;

  final double? height;
  final double width;
  final double elevation;

  final bool isLoading;
  final bool isEnabled;

  final BorderRadius? borderRadius;
  final Color? color;

  final IconData? icon;
  final double iconSize;
  final Color textColor;
  final TextStyle? textStyle;
  final Color? iconColor;

  /// Top-right small Ads label
  final String adsText;

  /// Ad unit shown on tap.
  final String? adUnitId;

  /// Whether to show interstitial ad on tap.
  final bool showAds;

  const AppAdsButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height,
    this.width = double.infinity,
    this.elevation = 0,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderRadius,
    this.color,
    this.icon,
    this.iconSize = 18,
    this.textColor = AppColors.white,
    this.textStyle,
    this.iconColor,
    this.adsText = 'Ads',
    this.adUnitId,

    // Default: Ads enabled
    this.showAds = true,
  });

  @override
  State<AppAdsButton> createState() => _AppAdsButtonState();
}

class _AppAdsButtonState extends State<AppAdsButton> {
  InterstitialAdHelper? _interstitialAdHelper;

  @override
  void initState() {
    super.initState();

    // Only create/load interstitial when ads are enabled.
    if (widget.showAds) {
      _interstitialAdHelper = InterstitialAdHelper(
        adUnitId: widget.adUnitId ?? AdUnitIds.adsButtonInterstitial,
        placement: 'ads_button',
      )..preload();
    }
  }

  @override
  void dispose() {
    _interstitialAdHelper?.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.showAds) {
      // _interstitialAdHelper?.show();
      // Only if ready now — never pops up late over the next screen (D).
      _interstitialAdHelper?.showIfReady();
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final radius = widget.borderRadius ?? BorderRadius.circular(AppSize.r(12));

    final enabledColor = widget.color ?? AppColors.primaryDark;

    final disabledColor = theme.colorScheme.outline.withValues(alpha: 0.5);

    return SizedBox(
      height: widget.height ?? AppSize.h(50),
      width: widget.width,
      child: Material(
        color: Colors.transparent,
        elevation: widget.elevation,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: widget.isEnabled ? enabledColor : disabledColor,
            borderRadius: radius,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: (!widget.isEnabled || widget.isLoading) ? null : _handleTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: widget.isLoading
                        ? AppLoader(
                            size: AppSize.w(22),
                            color: widget.isEnabled ? AppColors.white : null,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: AppSize.sp(widget.iconSize),
                                  color: widget.isEnabled
                                      ? (widget.iconColor ?? AppColors.white)
                                      : theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                ),
                                AppSize.gapW(6),
                              ],
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style:
                                    widget.textStyle ??
                                    theme.textTheme.titleMedium?.copyWith(
                                      color: widget.isEnabled
                                          ? widget.textColor
                                          : AppColors.white,
                                      fontSize: AppSize.sp(14),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Ads label only when showAds = true
                if (widget.adsText.isNotEmpty)
                  Positioned(
                    top: AppSize.h(3),
                    right: AppSize.w(5),
                    child: Text(
                      widget.adsText,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: AppSize.sp(7),
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}