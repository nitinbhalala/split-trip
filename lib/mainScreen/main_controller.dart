// import 'dart:io';

import 'package:get/get.dart';
// import 'package:in_app_update/in_app_update.dart';
// import 'package:split_trip/core/common/widgets/app_logger.dart';
// import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/modules/Report/controller/report_controller.dart';
import 'package:split_trip/services/ads/app_open_ad_service.dart';

class MainController extends GetxController {
  RxInt currentIndex = 0.obs;

  @override
  void onReady() {
    super.onReady();
    // Main screen reached: startup Interstitial (`splittrip_open`) now, and
    // returns from recents count for the App Open ad (`splittrip_recent_app`).
    AppOpenAdService.onMainScreenOpened();
  }

  // in_app_update removed — no in-app update check any more.
  // @override
  // void onReady() {
  //   super.onReady();
  //   checkForUpdate();
  // }

  // Future<void> checkForUpdate() async {
  //   if (!Platform.isAndroid) {
  //     AppLogger.log(
  //       "In-app updates are only supported on Android.",
  //       tag: "MainController",
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
  //     if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
  //       if (updateInfo.immediateUpdateAllowed) {
  //         await InAppUpdate.performImmediateUpdate();
  //       } else if (updateInfo.flexibleUpdateAllowed) {
  //         await InAppUpdate.startFlexibleUpdate();
  //
  //         AppSnackbar.info(
  //           message: "Update downloaded. Restarting app to apply...",
  //           duration: const Duration(seconds: 4),
  //         );
  //
  //         await Future.delayed(const Duration(seconds: 3));
  //         await InAppUpdate.completeFlexibleUpdate();
  //       }
  //     }
  //   } catch (e) {
  //     AppLogger.error("In-app update check error: $e");
  //   }
  // }

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 1 && Get.isRegistered<ReportController>()) {
      Get.find<ReportController>().loadGroups();
    }
  }
}
