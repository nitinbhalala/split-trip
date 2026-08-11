import 'package:flutter/material.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';

class AppStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const AppStatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSize.symmetric(horizontal: 5, vertical: 2),
      color: color.withValues(alpha: 0.12),
      borderRadius: 4,
      borderColor: color.withValues(alpha: 0.3),
      child: AppAutoSizeText(
        text: text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class AppInfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppInfoBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSize.symmetric(horizontal: 5, vertical: 2),
      color: backgroundColor ?? color.withValues(alpha: 0.08),
      borderRadius: 4,
      borderColor: borderColor ?? color.withValues(alpha: 0.25),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          AppSize.gapW(4),
          AppAutoSizeText(
            text: text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
