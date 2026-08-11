import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/modules/Report/controller/report_controller.dart';
import 'package:split_trip/modules/Report/screen/widgets/app_status_badge.dart';

class ReportMemberBreakdownTile extends StatelessWidget {
  final GroupMemberModel member;
  final ReportController controller;

  const ReportMemberBreakdownTile({
    super.key,
    required this.member,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final name = member.name;
      final share = controller.memberExpenses[name] ?? 0.0;
      final pct = controller.memberPercentages[name] ?? 0.0;
      final netBal = controller.memberNetBalances[name] ?? 0.0;
      final paidAmt = controller.memberPaidAmounts[name] ?? 0.0;
      final splitCount = controller.memberSplitCounts[name] ?? 0;
      final isPending = netBal < -0.01;
      final isGetsBack = netBal > 0.01;
      final pendingAmt = isPending ? netBal.abs() : 0.0;
      final getsBackAmt = isGetsBack ? netBal : 0.0;
      final color = controller.memberColors[name] ?? AppColors.primary;
      final isExpanded = controller.expandedMembers.contains(name);

      return AppCard(
        padding: AppSize.all(6),
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: 10,
        borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row: Avatar, Name, Status Badge, Share, Expand Icon ──────
            GestureDetector(
              onTap: () => controller.toggleMemberExpanded(name),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.18),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "M",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  AppSize.gapW(10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPending) ...[
                          AppSize.gapW(6),
                          const AppStatusBadge(
                            text: "Pending",
                            color: AppColors.warning,
                          ),
                        ] else if (isGetsBack) ...[
                          AppSize.gapW(6),
                          const AppStatusBadge(
                            text: "Gets Back",
                            color: AppColors.income,
                          ),
                        ] else ...[
                          AppSize.gapW(6),
                          const AppStatusBadge(
                            text: "Settled",
                            color: AppColors.income,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppAutoSizeText(
                        text: AppHelper.formatCurrency(share),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppAutoSizeText(
                        text: "Split Share",
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  AppSize.gapW(4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: AppSize.sp(23),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            // ── Collapsible Sub-metrics Section (Visible on Icon Tap) ─────
            if (isExpanded) ...[
              AppSize.gapH(10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  AppInfoBadge(
                    icon: Icons.pie_chart_outline_rounded,
                    text: "$splitCount ${splitCount == 1 ? 'Split' : 'Splits'}",
                    color: theme.colorScheme.onSurfaceVariant,
                    backgroundColor: theme.colorScheme.surface,
                    borderColor: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                  AppInfoBadge(
                    icon: Icons.payments_rounded,
                    text: "Paid: ${AppHelper.formatCurrency(paidAmt)}",
                    color: AppColors.income,
                  ),
                  if (isPending)
                    AppInfoBadge(
                      icon: Icons.pending_actions_rounded,
                      text: "Pending: ${AppHelper.formatCurrency(pendingAmt)}",
                      color: AppColors.warning,
                    ),
                  if (isGetsBack)
                    AppInfoBadge(
                      icon: Icons.call_received_rounded,
                      text:
                          "Gets Back: ${AppHelper.formatCurrency(getsBackAmt)}",
                      color: AppColors.income,
                    ),
                ],
              ),

              AppSize.gapH(9),

              // ── Progress Bar & Percentage Share ──────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${pct.toStringAsFixed(1)}% of total spend",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AppSize.gapH(4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
