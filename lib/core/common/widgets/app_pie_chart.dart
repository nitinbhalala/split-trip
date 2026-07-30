import 'package:flutter/material.dart';
import 'package:split_trip/core/sizer/app_size.dart';

/// A premium, reusable solid Pie Chart widget with an optional centered card overlay.
class AppPieChart extends StatelessWidget {
  final CustomPainter painter;
  final double size;
  final Widget? child;

  const AppPieChart({
    super.key,
    required this.painter,
    this.size = 110,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diameter = AppSize.w(size);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: painter)),
          if (child != null)
            Container(
              width: diameter * 0.70,
              height: diameter * 0.70,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:  0.06),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: child,
            ),
        ],
      ),
    );
  }
}
