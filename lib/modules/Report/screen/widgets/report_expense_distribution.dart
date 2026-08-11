import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/modules/Report/controller/report_controller.dart';
import 'package:split_trip/modules/Report/screen/widgets/donut_chart_widget.dart';

class ReportExpenseDistribution extends StatelessWidget {
  final ReportController controller;

  const ReportExpenseDistribution({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Expense Distribution",
          style: theme.textTheme.titleMedium,
        ),
        AppSize.gapH(9),
        AppCard(
          padding: AppSize.symmetric(horizontal: 12, vertical: 10),
          borderRadius: 7,
          child: Obx(() {
            final totalPending = controller.memberPendingAmounts.values
                .fold(0.0, (s, a) => s + a);

            return Column(
              children: [
                Center(
                  child: DonutChartWidget(
                    memberExpenses: controller.memberExpenses,
                    memberColors: controller.memberColors,
                    totalExpense: controller.totalExpense.value,
                    totalPendingAmount: totalPending,
                    size: 210,
                    strokeWidth: 26,
                  ),
                ),
                AppSize.gapH(16),

                // Inline Color Badges / Legends
                if (controller.memberExpenses.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: controller.memberExpenses.keys.map((name) {
                      final color =
                          controller.memberColors[name] ?? Colors.blue;
                      final pct =
                          controller.memberPercentages[name] ?? 0.0;
                      final pendingAmt =
                          controller.memberPendingAmounts[name] ?? 0.0;
                      final isPending = pendingAmt > 0.01;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSize.gapW(6),
                          Text(
                            "$name (${pct.toStringAsFixed(1)}%${isPending ? ' • Pending' : ''})",
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isPending
                                  ? AppColors.warning
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
