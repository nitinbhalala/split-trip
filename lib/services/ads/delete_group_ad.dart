import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/data/service/network_service.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/interstitial_ad_helper.dart';

/// Interstitial shown on every group delete (Dashbord list + Group Info),
/// after the user confirms and before the group is deleted. Never blocks the
/// delete: no internet / no fill / timeout → the delete goes ahead.
class DeleteGroupAd {
  DeleteGroupAd._();

  static final InterstitialAdHelper _helper = InterstitialAdHelper(
    adUnitId: AdUnitIds.deleteGroupInterstitial,
    placement: 'delete_group',
  );

  /// Longest the user waits for the ad to load.
  static const Duration _maxAdWait = Duration(seconds: 8);

  static bool _running = false;

  /// Shows "Ad loading...", then the ad. Returns once the ad is closed (or
  /// right away when there is none) — then delete. Never throws.
  static Future<void> showBeforeDelete() async {
    if (!AdUnitIds.adsEnabled || _running) return;
    _running = true;
    try {
      _showLoader();
      final ready =
          await NetworkService.hasInternet(
            timeout: const Duration(seconds: 3),
          ) &&
          await _helper.loadAndWait(timeout: _maxAdWait);
      await _hideLoader();
      // Let the loader's close transition finish before the ad opens.
      await Future.delayed(const Duration(milliseconds: 250));
      if (ready) {
        await _helper.showIfReadyAndWait();
      } else {
        AppLogger.log("Delete group ad not available — deleting.");
      }
    } catch (e) {
      await _hideLoader();
      AppLogger.error("Delete group ad failed: $e");
    } finally {
      _running = false;
    }
  }

  /// Button label with a small "Ads" tag at its top-right.
  static Widget label(String title, {TextStyle? style}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: style),
        const SizedBox(width: 3),
        Opacity(
          opacity: 0.85,
          child: Text(
            "Ads",
            style: (style ?? const TextStyle()).copyWith(
              fontSize: AppSize.sp(7),
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  static void _showLoader() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 280,
            color: Theme.of(Get.context!).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  "Ad loading...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
    );
  }

  static Future<void> _hideLoader() async {
    // Let the Get.dialog transition start before closing it.
    await Future.delayed(const Duration(milliseconds: 200));
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
