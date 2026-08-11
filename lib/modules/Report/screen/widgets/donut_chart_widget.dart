import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class DonutChartWidget extends StatelessWidget {
  final Map<String, double> memberExpenses;
  final Map<String, Color> memberColors;
  final double totalExpense;
  final double totalPendingAmount;
  final double size;
  final double strokeWidth;

  const DonutChartWidget({
    super.key,
    required this.memberExpenses,
    required this.memberColors,
    required this.totalExpense,
    this.totalPendingAmount = 0.0,
    this.size = 200,
    this.strokeWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<_ChartData> chartData = [];
    if (totalExpense <= 0 || memberExpenses.isEmpty) {
      chartData.add(
        _ChartData(
          'Empty',
          1.0,
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
        ),
      );
    } else {
      memberExpenses.forEach((name, amount) {
        if (amount > 0) {
          final color = memberColors[name] ?? Colors.blue;
          chartData.add(_ChartData(name, amount, color));
        }
      });
    }

    final innerHoleDiameter = (size - (strokeWidth * 2)).clamp(40.0, size);
    final innerSquareSize = innerHoleDiameter * 0.72;

    final tooltipBehavior = TooltipBehavior(
      color: AppColors.transparent,
      enable: totalExpense > 0 && memberExpenses.isNotEmpty,
      header: '',
      canShowMarker: false,
      builder:
          (
            dynamic data,
            dynamic point,
            dynamic series,
            int pointIndex,
            int seriesIndex,
          ) {
            final _ChartData item = data as _ChartData;
            if (item.name == 'Empty') return const SizedBox.shrink();
            return AppCard(
              padding: AppSize.symmetric(horizontal: 10, vertical: 6),

              color: theme.colorScheme.outline,
              borderRadius: 6,
              showBorder: false,
              child: Text(
                "${item.name}: ${AppHelper.formatCurrency(item.value)}",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Syncfusion Doughnut Chart

          // Center Text Badge (Strictly constrained within inner donut hole)
          SizedBox(
            width: innerSquareSize,
            height: innerSquareSize,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: AppSize.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Total Spend",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppSize.gapH(2),
                      AppAutoSizeText(
                        text: AppHelper.formatCurrency(totalExpense),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (totalPendingAmount > 0.01) ...[
                        AppSize.gapH(4),
                        AppCard(
                          padding: AppSize.symmetric(
                            vertical: 3,
                            horizontal: 5,
                          ),
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: 5,
                          showBorder: false,
                          child: AppAutoSizeText(
                            text:
                                "${AppHelper.formatCurrency(totalPendingAmount)} Pending",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SfCircularChart(
            margin: EdgeInsets.zero,
            tooltipBehavior: tooltipBehavior,
            series: <CircularSeries<_ChartData, String>>[
              DoughnutSeries<_ChartData, String>(
                dataSource: chartData,
                xValueMapper: (_ChartData data, _) => data.name,
                yValueMapper: (_ChartData data, _) => data.value,
                pointColorMapper: (_ChartData data, _) => data.color,
                enableTooltip: totalExpense > 0 && memberExpenses.isNotEmpty,
                innerRadius: '75%',
                radius: '100%',
                animationDuration: 1000,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String name;
  final double value;
  final Color color;

  _ChartData(this.name, this.value, this.color);
}
