
import 'package:flutter/material.dart';
import 'package:split_trip/core/sizer/app_size.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? color; // Background color
  final double? borderRadius; // Custom radius
  final Color? borderColor; // Border color
  final double? borderWidth; // Border thickness
  final EdgeInsetsGeometry? padding; // Inner spacing
  final EdgeInsetsGeometry? margin; // Outer spacing
  final VoidCallback? onTap; // Click action (Optional)
  final bool showBorder; // Border dikhana hai ya nahi
  final bool boxShadow; // Border dikhana hai ya nahi
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.padding,
    this.margin,
    this.onTap,
    this.showBorder = true,
    this.boxShadow = false,
    this.width,
    this.height,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    // Default values matching your UI
    final finalRadius = borderRadius ?? AppSize.r(8);
    final finalPadding =
        padding ?? AppSize.symmetric(vertical: 5, horizontal: 10);
    final finalColor = color ?? Theme.of(context).colorScheme.surface;
    final finalBorderColor =
        borderColor ?? Theme.of(context).colorScheme.outline;

    Widget cardWidget = Container(
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      decoration: BoxDecoration(
        boxShadow: boxShadow == true
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, .1),
                ),
              ]
            : null,
        color: finalColor,
        borderRadius: BorderRadius.circular(finalRadius),
        border: showBorder
            ? Border.all(color: finalBorderColor, width: borderWidth ?? 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(finalRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: finalPadding, child: child),
      ),
    );

    if (onTap != null) {
      cardWidget = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
