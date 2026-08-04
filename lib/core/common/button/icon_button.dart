import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? height;
  final double? width;
  final double elevation;
  final bool isLoading;
  final bool isEnabled;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? color;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final Color iconColor;
  final Color? disabledColor;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.height,
    this.width,
    this.elevation = 0,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderRadius,
    this.gradient,
    this.color,
    this.iconSize = 20,
    this.padding,
    this.iconColor = AppColors.white,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 12;

    return SizedBox(
      height: height ?? AppSize.h(45),
      width: width ?? AppSize.w(45),
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: (!isEnabled || isLoading) ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: gradient,
              color: gradient == null
                  ? (isEnabled
                        ? (color ?? AppColors.primaryDark)
                        : (disabledColor ??
                              context.theme.colorScheme.outline.withValues(
                                alpha: 0.4,
                              )))
                  : null,
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Center(
                child: isLoading
                    ? AppLoader(
                        size: AppSize.w(22),
                        color: isEnabled ? AppColors.white : null,
                      )
                    : Icon(
                        icon,
                        size: AppSize.sp(iconSize),
                        color: isEnabled
                            ? iconColor
                            : context.theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
