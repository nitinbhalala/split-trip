import 'package:flutter/material.dart';
import 'package:split_trip/core/sizer/app_size.dart';

class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color iconColor;
  final VoidCallback? onTap;
  final BoxShape? shape;
  final bool showBackground;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final BoxBorder? border;
  final Color? labalColor;
  const AppCircleIconButton({
    super.key,
    required this.icon,
    this.label,

    this.iconColor = Colors.white,
    this.onTap,
    this.showBackground = false,
    this.backgroundColor,
    this.gradient,
    this.size = 44,
    this.iconSize = 20,
    this.padding,
    this.shape,
    this.borderRadius,
    this.border,
    this.labalColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget iconWidget = Icon(icon, color: iconColor, size: iconSize);

    if (showBackground) {
      iconWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: shape ?? BoxShape.circle,
          borderRadius: (shape ?? BoxShape.circle) == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius ?? 12)
              : null,
          gradient: gradient,
          color: gradient != null
              ? null
              : (backgroundColor ?? iconColor.withValues(alpha: .12)),
          border: border,
        ),
        child: Center(child: iconWidget),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Padding(
        padding: padding ?? AppSize.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,

            if (label != null && label!.isNotEmpty) ...[
              AppSize.gapH(6),
              Text(
                label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: AppSize.sp(11),
                  color: labalColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
