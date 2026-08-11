import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/divider/app_divider.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_alert_dialog.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';

/// ── GPay Style Split Request Card Widget ────────────────────────────────────
class GPaySplitCardWidget extends StatelessWidget {
  final GroupMessageModel msg;
  final List<GroupMemberModel> members;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;

  const GPaySplitCardWidget({
    super.key,
    required this.msg,
    required this.members,
    required this.onTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = ExpenseMetadataModel.parse(msg, members);

    String formattedTime = "";
    if (msg.createdAt != null) {
      try {
        final dt = DateTime.parse(msg.createdAt!);
        formattedTime = DateFormat('dd MMM').format(dt);
      } catch (_) {}
    }

    double totalPaidAmount = 0.0;
    meta.splits.forEach((name, share) {
      if (meta.paidMemberNames.contains(name) || name == meta.paidByName) {
        totalPaidAmount += share;
      }
    });

    final int splitMemberCount = meta.splits.length;
    final int paidCount = meta.splits.keys
        .where((n) => meta.paidMemberNames.contains(n) || n == meta.paidByName)
        .length;
    final bool isAllPaid = (paidCount == splitMemberCount);

    // Can edit if split is active (not closed) AND no other member has paid yet
    final bool canEdit =
        !meta.isClosed &&
        (meta.paidMemberNames.isEmpty ||
            (meta.paidMemberNames.length == 1 &&
                meta.paidMemberNames.contains(meta.paidByName)));

        
       
    final double progressValue = msg.amount > 0
        ? (totalPaidAmount / msg.amount).clamp(0.0, 1.0)
        : 0.0;
    final double remainingAmount = (msg.amount - totalPaidAmount).clamp(
      0.0,
      msg.amount,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: meta.isClosed ? null : onTap,

        child: AppCard(
          showBorder: meta.isClosed ? false : true,
          color: meta.isClosed
              ? Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          margin: AppSize.symmetric(vertical: 10),
          width: MediaQuery.of(context).size.width * 0.82,
          padding: AppSize.symmetric(vertical: 12, horizontal: 12),
          borderRadius: meta.isClosed ? 10 : 15,
          borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Split Request", style: theme.textTheme.labelMedium),
                  InkWell(
                    onTap: onEditTap,
                    child: Row(
                      crossAxisAlignment: .start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canEdit && onEditTap != null) ...[
                          AppSize.gapW(6),

                          // onPressed: onEditTap,
                          Icon(
                            Icons.edit_square,
                            size: AppSize.sp(13),
                            color: theme.colorScheme.primary,
                          ),
                          AppSize.gapW(2),
                          Text(
                            "Edit Split ",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: meta.isClosed
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (meta.title != "")
                Padding(
                  padding: AppSize.symmetric(vertical: 2),
                  child: Text(
                    meta.title,
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: theme.textTheme.labelLarge?.color,
                    ),
                  ),
                ),

              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(
                    AppHelper.formatCurrency(msg.amount),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: AppSize.sp(22),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppSize.gapW(5),
                  Text(
                    "Paid by ${meta.paidByName}",
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: meta.isClosed
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // if (!meta.isClosed) ...[
              //   AppSize.gapH(1),
              //   Row(
              //     children: [
              //       Expanded(
              //         child: Text(
              //           "${AppHelper.formatCurrency(perPerson)} / person ($splitMemberCount members)",
              //           style: theme.textTheme.bodyMedium,
              //         ),
              //       ),
              //     ],
              //   ),
              //   AppSize.gapH(6),
              // ],
              if (meta.isClosed)
                const SizedBox.shrink()
              else if (isAllPaid)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.income,
                      size: AppSize.sp(16),
                    ),
                    AppSize.gapW(6),
                    Text(
                      "All paid",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.income,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    AppSize.gapW(8),
                    AppAutoSizeText(
                      text: AppHelper.formatCurrency(remainingAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              AppSize.gapH(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        meta.isClosed
                            ? Icons.error_outline_rounded
                            : Icons.access_time_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      if (!meta.isClosed) ...[
                        AppSize.gapW(2),
                        Text(
                          "$paidCount of $splitMemberCount paid • ",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: meta.isClosed
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        AppSize.gapW(2),
                      ],
                      Text(
                        meta.isClosed
                            ? "No payment required"
                            : (formattedTime.isNotEmpty
                                  ? formattedTime
                                  : "Just now"),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: meta.isClosed
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (!meta.isClosed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Tap to view",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Text Chat Bubble Widget ──────────────────────────────────────────────────
class TextChatBubbleWidget extends StatelessWidget {
  final GroupMessageModel msg;

  const TextChatBubbleWidget({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = (msg.senderName).toLowerCase() == "me";

    String formattedTime = "";
    if (msg.createdAt != null) {
      try {
        final dt = DateTime.parse(msg.createdAt!);
        formattedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              msg.messageText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            AppSize.gapH(2),
            Text(
              formattedTime.isNotEmpty ? formattedTime : "Just now",
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: isMe
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Overall Balance Item Tile Widget ─────────────────────────────────────────
class OverallBalanceTileWidget extends StatefulWidget {
  final String name;
  final double balance;
  final String statusText;
  final Color statusColor;
  final Function(String name)? onMarkPaid;

  const OverallBalanceTileWidget({
    super.key,
    required this.name,
    required this.balance,
    required this.statusText,
    required this.statusColor,
    this.onMarkPaid,
  });

  @override
  State<OverallBalanceTileWidget> createState() =>
      _OverallBalanceTileWidgetState();
}

class _OverallBalanceTileWidgetState extends State<OverallBalanceTileWidget> {
  bool isExpanded = false;

  void _confirmMarkAsPaid(BuildContext context) {
    AppAlertDialog.show(
      titleText: "Confirm Payment",
      actionsAlignment: MainAxisAlignment.spaceAround,
      contentText:
          "Are you sure you want to mark all pending split expenses for '${widget.name}' as paid?",
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            "Cancel",
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            setState(() {
              isExpanded = false;
            });
            widget.onMarkPaid?.call(widget.name);
          },
          child: Text(
            "Confirm",
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwes = widget.balance < -0.01;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              // Only allow expanding for members who owe money
              if (isOwes) {
                setState(() {
                  isExpanded = !isExpanded;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: AppSize.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: AppSize.r(16),
                    backgroundColor: widget.statusColor.withValues(alpha: 0.15),
                    child: Text(
                      widget.name.isNotEmpty
                          ? widget.name[0].toUpperCase()
                          : "M",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: widget.statusColor,
                      ),
                    ),
                  ),
                  AppSize.gapW(12),
                  Text(
                    widget.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSize.gapW(12),
                  const Spacer(),
                  AppAutoSizeText(
                    textAlign: TextAlign.right,
                    text: widget.statusText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      color: widget.statusColor,
                    ),
                  ),
                  if (isOwes) ...[
                    AppSize.gapW(4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: AppSize.sp(18),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isExpanded && isOwes) ...[
            AppDivider(thickness: 1.2),
            Padding(
              padding: AppSize.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Right Action: Cancel
                  TextButton(
                    child: Text(
                      "Cancel",
                      style: theme.textTheme.labelMedium!.copyWith(
                        fontWeight: .w600,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isExpanded = false;
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () => _confirmMarkAsPaid(context),
                    child: Text(
                      "Mark as paid",
                      style: theme.textTheme.labelMedium!.copyWith(
                        fontWeight: .w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ── Pending Settlement Tile Widget ─────────────────────────────────────────
class PendingSettlementTileWidget extends StatelessWidget {
  final String debtor;
  final String creditor;
  final double amount;
  final String title;

  const PendingSettlementTileWidget({
    super.key,
    required this.debtor,
    required this.creditor,
    required this.amount,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSize.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSize.r(16),
            backgroundColor: AppColors.warning.withValues(alpha: 0.15),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.warning,
              size: AppSize.sp(16),
            ),
          ),
          AppSize.gapW(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: debtor),
                      const TextSpan(text: " owes "),
                      TextSpan(
                        text: creditor,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppHelper.formatCurrency(amount),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Chat Empty State Widget ─────────────────────────────────────────────────
class GroupChatEmptyStateWidget extends StatelessWidget {
  final GroupDetailController controller;
  final VoidCallback? onAddMemberTap;

  const GroupChatEmptyStateWidget({
    super.key,
    required this.controller,
    this.onAddMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: AppSize.symmetric(horizontal: 24),
            child: Obx(() {
              final bool isAlone = controller.members.length <= 1;
              final groupName = controller.groupName.value;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: AppSize.all(15),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAlone ? Icons.person_add_alt_1_rounded : Icons.message,
                      size: AppSize.sp(40),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppSize.gapH(16),
                  Text(
                    isAlone
                        ? "Add friends to your group"
                        : "No expenses or messages yet",
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  AppSize.gapH(8),
                  Text(
                    isAlone
                        ? "You're currently the only member in '$groupName'. Add members to start splitting trip expenses!"
                        : "Tap '+' to split an expense with group members or start typing below.",
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (onAddMemberTap != null) ...[
                    AppSize.gapH(20),
                    AppElevatedButton(
                      width: AppSize.w(195),
                      onPressed: onAddMemberTap,
                      icon: Icons.person_add_rounded,
                      title: isAlone ? "Add Members" : "Add More Members",
                    ),
                  ],
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

/// ── Total Group Expenses Banner Widget ──────────────────────────────────────
class GroupTotalExpensesBannerWidget extends StatelessWidget {
  final double totalExpense;

  const GroupTotalExpensesBannerWidget({super.key, required this.totalExpense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSize.symmetric(horizontal: 10, vertical: 10),
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      borderRadius: AppSize.r(8),
      showBorder: false,
      child: Column(
        children: [
          Text(
            "Total Group Expenses",
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSize.gapH(4),
          AppAutoSizeText(
            text: AppHelper.formatCurrency(totalExpense),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: AppSize.sp(22),
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Overall Balances List Widget ─────────────────────────────────────────────
class OverallBalancesListWidget extends StatelessWidget {
  final Map<String, double> netBalances;
  final Map<String, double>? memberSettledAmounts;
  final Function(String name)? onMarkPaid;

  const OverallBalancesListWidget({
    super.key,
    required this.netBalances,
    this.memberSettledAmounts,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: netBalances.length,
      separatorBuilder: (_, _) => AppSize.gapH(6),
      itemBuilder: (context, index) {
        final name = netBalances.keys.elementAt(index);
        final bal = netBalances[name] ?? 0.0;
        final settledAmt = memberSettledAmounts?[name] ?? 0.0;

        final isOwed = bal > 0.01;
        final isOwes = bal < -0.01;

        final String statusText = isOwed
            ? "gets back ${AppHelper.formatCurrency(bal)}"
            : (isOwes
                  ? "owes ${AppHelper.formatCurrency(bal.abs())}"
                  : (settledAmt > 0
                        ? "(${AppHelper.formatCurrency(settledAmt)}) settled up "
                        : "settled up"));

        final Color statusColor = isOwed
            ? AppColors.income
            : (isOwes ? AppColors.error : theme.colorScheme.onSurfaceVariant);

        return OverallBalanceTileWidget(
          name: name,
          balance: bal,
          statusText: statusText,
          statusColor: statusColor,
          onMarkPaid: onMarkPaid,
        );
      },
    );
  }
}

/// ── Pending Settlements List Widget ─────────────────────────────────────────
class PendingSettlementsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> settlementList;

  const PendingSettlementsListWidget({super.key, required this.settlementList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (settlementList.isEmpty) {
      return AppAutoSizeText(
        alignment: Alignment.center,
        text: "All group expenses are completely settled! 🎉",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.income,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: settlementList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = settlementList[index];
        return PendingSettlementTileWidget(
          debtor: item['debtor'] as String,
          creditor: item['creditor'] as String,
          amount: item['amount'] as double,
          title: item['title'] as String,
        );
      },
    );
  }
}
