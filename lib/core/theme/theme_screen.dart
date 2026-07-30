import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';

import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/core/theme/theme_controller.dart';

class ThemeScreen extends StatelessWidget {
  ThemeScreen({super.key});

  final ThemeController controller = Get.find<ThemeController>();

  final List<Map<String, dynamic>> options = [
    {
      "title": "Light Mode",
      "mode": ThemeMode.light,
      "icon": Icons.light_mode_rounded,
    },
    {
      "title": "Dark Mode",
      "mode": ThemeMode.dark,
      "icon": Icons.dark_mode_rounded,
    },
    {
      "title": "System Default",
      "mode": ThemeMode.system,
      "icon": Icons.settings_suggest_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: "Theme Mode",
        showBackButton: true,
        centerTitle: true,
      ),
      body: Obx(() {
        final selectedMode = controller.themeMode;

        return ListView.builder(
          padding: AppSize.symmetric(horizontal: 12),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedMode == option["mode"];

            return InkWell(
              onTap: () {
                controller.changeTheme(option["mode"]);
                Get.back();
              },
              child: Card(
                margin: AppSize.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSize.r(5)),
                  side: BorderSide(
                    color: Theme.of(
                      Get.context!,
                    ).colorScheme.outline.withValues(alpha: .06),
                  ),
                ),
                child: Padding(
                  padding: AppSize.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        option["title"],
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall!.copyWith(),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_outlined
                            : Icons.radio_button_off_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
