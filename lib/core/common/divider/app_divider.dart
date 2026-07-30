import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDivider extends StatelessWidget {
  final bool isVertical;
  final double? thickness;
  final double? space;
  final Color? color;

  const AppDivider({
    super.key,
    this.isVertical = false,
    this.thickness = 0.6,
    this.space = 1,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color defaultColor =
        color ?? Theme.of(Get.context!).colorScheme.outline;

    if (isVertical) {
      return VerticalDivider(
        width: space,
        thickness: thickness,
        color: defaultColor,
      );
    }

    return Divider(height: space, thickness: thickness, color: defaultColor);
  }
}
