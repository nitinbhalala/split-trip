import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/theme/theme_controller.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> themes = [
      {
        'mode': ThemeMode.system,
        'title': 'System Default',
        'subtitle': 'Use the system default theme setting',
        'icon': Icons.settings_brightness_rounded,
        'color': Colors.blue,
      },
      {
        'mode': ThemeMode.light,
        'title': 'Light Theme',
        'subtitle': 'Clean, bright interface',
        'icon': Icons.light_mode_rounded,
        'color': Colors.orange,
      },
      {
        'mode': ThemeMode.dark,
        'title': 'Dark Theme',
        'subtitle': 'Elegant, dark interface to protect eyes',
        'icon': Icons.dark_mode_rounded,
        'color': Colors.indigo,
      },
    ];

    return Scaffold(
      appBar: const CommonAppBar(title: "Select Theme", showBackButton: true),
      body: Obx(() {
        final currentMode = themeController.themeMode;

        return SafeArea(
          bottom: true,
          top: false,
          child: ListView.separated(
            padding: AppSize.symmetric(horizontal: 16, vertical: 16),
            itemCount: themes.length,
            separatorBuilder: (context, index) => AppSize.gapH(12),
            itemBuilder: (context, index) {
              final t = themes[index];
              final ThemeMode mode = t['mode'] as ThemeMode;
              final isSelected = currentMode == mode;

              return AppCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: AppSize.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: AppSize.w(36),
                    height: AppSize.w(36),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (t['color'] as Color).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      t['icon'] as IconData,
                      color: isSelected ? Colors.white : t['color'] as Color,
                      size: AppSize.sp(20),
                    ),
                  ),
                  title: Text(
                    t['title'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSize.sp(13.5),
                    ),
                  ),
                  subtitle: Text(
                    t['subtitle'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: AppSize.sp(10.5),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: AppSize.sp(22),
                        )
                      : null,
                  onTap: () {
                    themeController.changeTheme(mode);
                    Get.back();
                    AppSnackbar.success(
                      message: "Theme updated to '${t['title']}' successfully!",
                    );
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
