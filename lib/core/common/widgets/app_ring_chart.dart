import 'package:flutter/material.dart';
import 'package:split_trip/core/sizer/app_size.dart';

/// A premium, reusable widget for Ring and Donut charts that handles
/// dynamic sizing, LayoutBuilder constraints, and text auto-scaling in the center.
class AppRingChart extends StatelessWidget {
  final CustomPainter painter;
  final double size;
  final Widget child; // Center text / column inside the ring chart

  const AppRingChart({
    super.key,
    required this.painter,
    this.size = 110,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.w(size),
      height: AppSize.w(size),
      constraints: BoxConstraints(maxWidth: size, maxHeight: size),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = constraints.maxWidth;
          final innerSize = diameter * 0.72;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: painter)),
              Container(
                width: innerSize,
                height: innerSize,
                alignment: Alignment.center,
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }
}
