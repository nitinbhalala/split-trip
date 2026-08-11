import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/modules/Report/controller/report_controller.dart';

class ReportSummaryCard extends StatelessWidget {
  final ReportController controller;

  const ReportSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      return AppCard(
        padding: AppSize.symmetric(horizontal: 12, vertical: 7),
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: 7,
        showBorder: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Group Expense",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSize.gapH(4),
                  AppAutoSizeText(
                    text: AppHelper.formatCurrency(
                      controller.totalExpense.value,
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              padding: AppSize.symmetric(horizontal: 12, vertical: 7),

              borderRadius: 5,
              showBorder: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${controller.totalExpenseCount.value} Splits",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSize.gapH(2),
                  Text(
                    "${controller.members.length} Members",
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
