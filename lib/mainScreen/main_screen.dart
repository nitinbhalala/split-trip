import 'package:split_trip/core/theme/app_color.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/mainScreen/main_controller.dart';
import 'package:split_trip/modules/Group/screen/group_screen.dart';
import 'package:split_trip/modules/Report/screen/report_screen.dart';
import 'package:split_trip/modules/Settings/screen/settings_screen.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/banner_ad_widget.dart';
import 'package:split_trip/services/ads/exit_app_bottom_sheet.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  Future<void> _handlePop(BuildContext context) async {
    // Any tab other than Dashboard just goes back to Dashboard first — only
    // a back press from Dashboard itself should prompt to exit the app.
    if (controller.currentIndex.value != 0) {
      controller.changeTab(0);
      return;
    }
    // No preload: the exit sheet requests a fresh ad on every open.
    await ExitAppBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [DashbordScreen(), ReportScreen(), SettingsScreen()];

    // return Obx(() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop(context);
      },
      child: Obx(() {
      return Scaffold(
        extendBody: false,
        resizeToAvoidBottomInset: true,
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: screens,
        ),

        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          // Same colour as the page so the area behind a shorter banner
          // (or the home-indicator gap) blends in, light and dark.
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              // Required — without it the column fills the whole screen.
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.white12 : Colors.black12,
                        blurRadius: 1,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _BottomNavItem(
                          icon: Icons.home,
                          label: "Dashbord",
                          index: 0,
                        ),
                      ),
                      Expanded(
                        child: _BottomNavItem(
                          icon: Icons.pie_chart_rounded,
                          label: "Report",
                          index: 1,
                        ),
                      ),

                      Expanded(
                        child: _BottomNavItem(
                          icon: Icons.settings,
                          label: "Settings",
                          index: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Banner ad below the bottom nav bar — hidden entirely
                // (SizedBox.shrink) if ads are disabled or no ad loads.
                BannerAdWidget(
                  adUnitId: AdUnitIds.mainBottomBanner,
                  placementId: 'main_bottom_banner',
                ),
              ],
            ),
          ),
        ),
      );
    // });
      }),
    );

  }
}

class _BottomNavItem extends GetView<MainController> {
  final IconData icon;
  final String label;
  final int index;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.currentIndex.value == index;

      return InkWell(
        borderRadius: BorderRadius.circular(100),
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => controller.changeTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              scale: selected ? 1.12 : 1,
              child: Icon(
                icon,
                size: selected ? 23 : 22,
                color: selected
                    ? AppColors.primaryDark
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppColors.primaryDark
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: Text(label),
            ),
          ],
        ),
      );
    });
  }
}
