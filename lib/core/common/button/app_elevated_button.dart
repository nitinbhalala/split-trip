import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class AppElevatedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final double? height;
  final double width;
  final double elevation;
  final bool isLoading;
  final bool isEnabled;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Color? color;
  final IconData? icon;
  final ButtonContentOrder contentOrder;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final Color textColor;
  final Color? isEnbleColor;
  final TextStyle? textStyle; // 👈 ADD
  final Color? iconColorEnble;
  final double iconTextBetweenSpace;
  final bool showIconLoader;
  const AppElevatedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height,
    this.width = double.infinity,
    this.elevation = 0,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderRadius,
    this.gradient,
    this.color,
    this.icon,
    this.contentOrder = ButtonContentOrder.iconFirst,
    this.iconSize = 18,
    this.padding,
    this.textColor = AppColors.white,
    this.textStyle,
    this.isEnbleColor,
    this.iconColorEnble,
    this.iconTextBetweenSpace = 8, // 👈 NEW
    this.showIconLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);

    return SizedBox(
      height: height ?? AppSize.h(50),
      width: width,
      child: Material(
        elevation: elevation,
        borderRadius: radius,

        child: InkWell(
          borderRadius: radius,
          onTap: (!isEnabled || isLoading) ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: isEnabled
                  ? (color ?? AppColors.primaryDark)
                  : (isEnbleColor ?? const Color.fromARGB(255, 88, 143, 197)),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: 0),
              child: Center(
                child: isLoading
                    ? AppLoader(
                        size: AppSize.w(24),
                        color: isEnabled ? AppColors.white : null,
                      )
                    : _buildContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      color: isEnabled ? textColor : AppColors.white,
      fontSize: AppSize.sp(14),
    );
    final textWidget = Text(
      title,
      style: textStyle ?? defaultStyle, // 👈 ONLY CHANGE
    );

    if (icon == null) {
      /// ✅ OLD LOGIC — unchanged
      return textWidget;
    }

    // final iconWidget = Icon(
    //   icon,
    //   size: AppSize.sp(iconSize),
    //   color: isEnabled
    //       ? AppColors.white
    //       : iconColorEnble ??
    //             context.theme.colorScheme.onSurfaceVariant.withValues(
    //               alpha: 0.5,
    //             ),
    // );
    final iconWidget = showIconLoader
        ? SizedBox(
            width: AppSize.w(iconSize),
            height: AppSize.h(iconSize),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
        : Icon(
            icon,
            size: AppSize.sp(iconSize),
            color: isEnabled
                ? AppColors.white
                : iconColorEnble ??
                      context.theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
          );

    final children = contentOrder == ButtonContentOrder.iconFirst
        ? [iconWidget, AppSize.gapW(iconTextBetweenSpace), textWidget]
        : [textWidget, AppSize.gapW(iconTextBetweenSpace), iconWidget];

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

enum ButtonContentOrder { iconFirst, textFirst }

class AppElevatedButtonWithIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final double? height;
  final double width;
  final double elevation;
  final bool isLoading;
  final bool isEnabled;
  final ButtonContentOrder contentOrder;

  const AppElevatedButtonWithIcon({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.height,
    this.width = double.infinity,
    this.elevation = 0,
    this.isLoading = false,
    this.isEnabled = true,
    this.contentOrder = ButtonContentOrder.iconFirst,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r(12));

    Widget iconWidget = Icon(
      icon,
      size: AppSize.sp(18),
      color: isEnabled
          ? AppColors.white
          : context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );

    Widget textWidget = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: isEnabled
            ? AppColors.white
            : context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        fontSize: AppSize.sp(18),
      ),
    );

    List<Widget> rowChildren = contentOrder == ButtonContentOrder.iconFirst
        ? [iconWidget, AppSize.gapW(8), textWidget]
        : [textWidget, AppSize.gapW(8), iconWidget];

    return SizedBox(
      height: height ?? AppSize.h(50),
      width: width,
      child: Material(
        elevation: elevation,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: (!isEnabled || isLoading) ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,

              color: isEnabled
                  ? AppColors.primaryDark
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            child: Center(
              child: isLoading
                  ? AppLoader(
                      size: AppSize.w(24),
                      color: isEnabled ? AppColors.white : null,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: rowChildren, // 🔥 USED HERE
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
