import 'package:flutter/material.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';

class SummaryAmountCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final bool isDark;
  final EdgeInsets? padding;
  const SummaryAmountCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: padding ?? AppSize.symmetric(horizontal: 12, vertical: 10),

      color: isDark
          ? color.withValues(alpha: 0.12)
          : color.withValues(alpha: 0.08),
      borderRadius: 9,
      borderColor: color.withValues(alpha: 0.25),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp(12),
            ),
          ),
          AppSize.gapH(4),
          AppAutoSizeText(
            
            text: amount,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp(16),
            ),
          ),
        ],
      ),
    );
  }
}
