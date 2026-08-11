import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/divider/app_divider.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_alert_dialog.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final GroupDetailController controller;
  final GroupMessageModel msg;
  final ExpenseMetadataModel initialMeta;

  const ExpenseDetailScreen({
    super.key,
    required this.controller,
    required this.msg,
    required this.initialMeta,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late ExpenseMetadataModel meta;

  @override
  void initState() {
    super.initState();
    meta = widget.initialMeta;
  }

  void _confirmCloseRequest(BuildContext context) {
    AppAlertDialog.show(
      actionsAlignment: MainAxisAlignment.spaceAround,
      titleText: "Do you want to close this request?",
      contentText:
          "Your friends will not be able to make any additional payments.",
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
          onPressed: () async {
            Get.back();
            meta = ExpenseMetadataModel(
              title: meta.title,
              paidByName: meta.paidByName,
              paidById: meta.paidById,
              splits: meta.splits,
              paidMemberNames: meta.paidMemberNames,
              isClosed: true,
            );
            if (widget.msg.id != null) {
              await widget.controller.updateExpenseMetadata(
                widget.msg.id!,
                meta.toMap(),
              );
            }
            setState(() {});
          },
          child: Text(
            "Close request",
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

    // Calculate total paid amount (payer's share + shares of members marked as paid)
    double totalPaidAmount = 0.0;
    meta.splits.forEach((name, share) {
      if (meta.paidMemberNames.contains(name) || name == meta.paidByName) {
        totalPaidAmount += share;
      }
    });

    final double remainingAmount = (widget.msg.amount - totalPaidAmount) > 0
        ? (widget.msg.amount - totalPaidAmount)
        : 0.0;

    final int paidCount = meta.splits.keys
        .where((n) => meta.paidMemberNames.contains(n) || n == meta.paidByName)
        .length;
    final int totalSplitCount = meta.splits.length;

    final double progressValue = widget.msg.amount > 0
        ? (totalPaidAmount / widget.msg.amount).clamp(0.0, 1.0)
        : 0.0;

    // Condition: Close request button is ONLY shown if NO non-payer member has paid yet
    final bool hasAnyNonPayerPaid = meta.paidMemberNames.any(
      (name) => name != meta.paidByName,
    );
    final bool canCloseRequest = !meta.isClosed && !hasAnyNonPayerPaid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: AppSize.sp(20)),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: AppSize.symmetric(horizontal: 12, vertical: 0),
          child: Column(
            children: [
              // Header Avatar
              CircleAvatar(
                radius: AppSize.r(30),
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: AppSize.sp(30),
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSize.gapH(5),

              // Expense Title & Total Amount
              Text(
                meta.title.isNotEmpty ? meta.title : "Split Request",
                style: theme.textTheme.titleLarge,
              ),
              AppSize.gapH(5),
              Row(
                mainAxisAlignment: .center,
                children: [
                  Text(
                    "Total: ",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  AppAutoSizeText(
                    text: AppHelper.formatCurrency(widget.msg.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: "Inter",
                    ),
                  ),
                ],
              ),
              AppSize.gapH(10),

              // Progress Bar / Closed Banner / All Paid Banner
              if (meta.isClosed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      size: AppSize.sp(20),
                    ),
                    AppSize.gapW(8),
                    Text(
                      "Request closed • No payment required",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else if (paidCount == totalSplitCount)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: AppSize.sp(20),
                    ),
                    AppSize.gapW(8),
                    Text(
                      "All paid",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: .w600,
                      ),
                    ),
                  ],
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: AppSize.h(6),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                AppSize.gapH(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppAutoSizeText(
                      text: "${AppHelper.formatCurrency(totalPaidAmount)} paid",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: .w600,
                      ),
                    ),
                    AppAutoSizeText(
                      text: "${AppHelper.formatCurrency(remainingAmount)} left",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: .w600,
                      ),
                    ),
                  ],
                ),
              ],
              AppSize.gapH(10),
              AppDivider(thickness: 1.2),
              AppSize.gapH(1),

              // Status line: "3 of 4 paid" & "Send reminder" button
              Row(
                mainAxisAlignment: .start,
                children: [
                  Text(
                    meta.isClosed
                        ? "Request closed"
                        : "$paidCount of $totalSplitCount paid",
                    style: theme.textTheme.labelLarge,
                  ),
                  Spacer(),
                  if (canCloseRequest) ...[
                    Icon(
                      Icons.login_sharp,
                      size: AppSize.sp(15),
                      color: theme.colorScheme.error,
                    ),
                    AppSize.gapW(3),
                    TextButton(
                      onPressed: () => _confirmCloseRequest(context),
                      child: Text(
                        "Close request",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              AppSize.gapH(1),

              // Member Split List
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: meta.splits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final memberName = meta.splits.keys.elementAt(index);
                    final shareAmount = meta.splits[memberName] ?? 0.0;

                    final bool isPayer = (memberName == meta.paidByName);
                    final bool isPaid =
                        isPayer || meta.paidMemberNames.contains(memberName);

                    return Container(
                      padding: AppSize.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? theme.colorScheme.surfaceContainerLow
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPaid
                              ? theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                )
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: AppSize.r(20),
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),

                                    child: Text(
                                      memberName.isNotEmpty
                                          ? memberName[0].toUpperCase()
                                          : "M",
                                      style: theme.textTheme.labelLarge!
                                          .copyWith(
                                            color: isPaid
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  if (isPaid)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: AppSize.sp(11),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              AppSize.gapW(14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memberName,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(
                                      meta.isClosed
                                          ? "Request closed"
                                          : (isPayer
                                                ? "Sent this request"
                                                : (isPaid ? "Paid" : "Unpaid")),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: meta.isClosed
                                                ? theme.colorScheme.error
                                                : (isPayer
                                                      ? theme
                                                            .colorScheme
                                                            .onSurfaceVariant
                                                      : (isPaid
                                                            ? Colors.green
                                                            : theme
                                                                  .colorScheme
                                                                  .error)),
                                            fontWeight: !isPayer
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              AppAutoSizeText(
                                text: AppHelper.formatCurrency(shareAmount),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: .w600,
                                  fontFamily: "Inter",
                                ),
                              ),
                            ],
                          ),

                          // Action Buttons ONLY for Non-Payer Members when request is NOT closed
                          if (!meta.isClosed &&
                              !isPayer &&
                              widget.msg.id != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isPaid)
                                  InkWell(
                                    onTap: () async {
                                      meta.paidMemberNames.remove(memberName);
                                      await widget.controller
                                          .updateExpenseMetadata(
                                            widget.msg.id!,
                                            meta.toMap(),
                                          );
                                      setState(() {});
                                    },
                                    child: Text(
                                      "Mark as unpaid",
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: .w600,
                                          ),
                                    ),
                                  )
                                else ...[
                                  InkWell(
                                    onTap: () async {
                                      if (!meta.paidMemberNames.contains(
                                        memberName,
                                      )) {
                                        meta.paidMemberNames.add(memberName);
                                      }
                                      await widget.controller
                                          .updateExpenseMetadata(
                                            widget.msg.id!,
                                            meta.toMap(),
                                          );
                                      setState(() {});
                                    },
                                    child: Text(
                                      "Mark as paid",
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: .w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          AppSize.gapH(2),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Close Request Button at the bottom (Shown ONLY if no payment has been made yet)
            ],
          ),
        ),
      ),
    );
  }
}
