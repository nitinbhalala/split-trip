
import 'package:flutter/material.dart';
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/core/common/widgets/app_circle_icon_button.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class AppIconPicker extends StatelessWidget {
  final String? selectedIconName;
  final ValueChanged<String> onIconSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? unselectedIconColor;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  const AppIconPicker({
    super.key,
    required this.onIconSelected,
    this.selectedIconName,
    this.selectedColor,
    this.unselectedColor,
    this.unselectedIconColor,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final categorizedIcons = AppIcons.categorizedIconNames;

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: categorizedIcons.length,
      itemBuilder: (context, index) {
        final categoryName = categorizedIcons.keys.elementAt(index);
        final iconNames = categorizedIcons[categoryName] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: AppSize.symmetric(vertical: 10.0),
              child: Text(
                categoryName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 1.0,
              ),
              itemCount: iconNames.length,
              itemBuilder: (context, gridIndex) {
                final iconName = iconNames[gridIndex];
                final iconData = AppIcons.getIcon(iconName);
                final isSelected = iconName == selectedIconName;

                return AppCircleIconButton(
                  icon: iconData,
                  showBackground: true,
                  size: 44,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  backgroundColor: isSelected
                      ? (selectedColor ?? Theme.of(context).primaryColor)
                      : (unselectedColor ?? Colors.grey.shade400),
                  iconColor: isSelected
                      ? AppColors.white
                      : (unselectedIconColor ?? Colors.black54),
                  onTap: () => onIconSelected(iconName),
                );
              },
            ),
            AppSize.gapH(8),
          ],
        );
      },
    );
  }
}
