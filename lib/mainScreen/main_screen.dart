import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/mainScreen/main_controller.dart';
import 'package:split_trip/modules/Home/screen/dashbord_screen.dart';
import 'package:split_trip/modules/Settings/screen/settings_screen.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashbordScreen(),
      // TranscationsScreen(),
      // EntryScreen(),
      // ReportScreen(),
      SettingsScreen(),
    ];

    return Obx(() {
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
          child: Container(
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
                    icon: Icons.receipt_long_rounded,
                    label: "Transactions",
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.add_box,
                    label: "Add Entry",
                    index: 2,
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.pie_chart_rounded,
                    label: "Report",
                    index: 3,
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.settings,
                    label: "Settings",
                    index: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
    final isAddEntry = index == 2;
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
            if (isAddEntry) ...[
              Container(
                width: AppSize.w(32),
                height: AppSize.w(32),
                margin: AppSize.only(bottom: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.savings,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: AppSize.sp(23),
                ),
              ),
              AppSize.gapH(2),
            ] else ...[
              AnimatedScale(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                scale: selected ? 1.12 : 1,
                child: Icon(
                  icon,
                  size: selected ? 23 : 22,
                  color: selected ? AppColors.primary : const Color(0xFF9CA3AF),
                ),
              ),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : const Color(0xFF9CA3AF),
              ),
              child: Text(label),
            ),
          ],
        ),
      );
    });
  }
}
