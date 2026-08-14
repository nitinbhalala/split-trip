import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/modules/Group/controller/add_split_expense_controller.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Group/screen/widgets/add_split_expense_widgets.dart';

class AddSplitExpenseScreen extends StatefulWidget {
  final GroupDetailController controller;
  final String groupName;
  final GroupMessageModel? editingMessage;
  final ExpenseMetadataModel? initialMeta;

  const AddSplitExpenseScreen({
    super.key,
    required this.controller,
    required this.groupName,
    this.editingMessage,
    this.initialMeta,
  });

  @override
  State<AddSplitExpenseScreen> createState() => _AddSplitExpenseScreenState();
}

class _AddSplitExpenseScreenState extends State<AddSplitExpenseScreen> {
  late final AddSplitExpenseController splitController;
  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    splitController = Get.put(
      AddSplitExpenseController(
        groupDetailController: widget.controller,
        editingMessage: widget.editingMessage,
        initialMeta: widget.initialMeta,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<AddSplitExpenseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = bottomInset > 0;

    // Detect keyboard closing from ANY source (Done button, back gesture, swipe dismiss)
    if (isKeyboardOpen) {
      _wasKeyboardOpen = true;
    } else if (_wasKeyboardOpen) {
      _wasKeyboardOpen = false;
      if (!splitController.isEditingDescription) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!splitController.isEditingDescription) {
            splitController.validateAndShowSnackbarIfNeeded();
          }
        });
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: AppSize.sp(20)),
          onPressed: () {
            if (splitController.step.value == 3) {
              splitController.step.value = 2;
            } else if (splitController.step.value == 2) {
              splitController.step.value = 1;
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: true,
          child: Obx(() {
            if (splitController.step.value == 1) {
              return _buildAmountInputStep(theme);
            } else if (splitController.step.value == 2) {
              return _buildPayerSelectionStep(theme);
            } else {
              return _buildSplitAllocationStep(theme, isKeyboardOpen);
            }
          }),
        ),
      ),
    );
  }

  // ── Step 1: Amount Input Screen ────────────────────────────────────────────
  Widget _buildAmountInputStep(ThemeData theme) {
    return Column(
      children: [
        const Spacer(),

        // Subtitle
        Text(
          "Enter amount to split",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSize.gapH(12),

        // Amount Display (GPay Style)
        Obx(
          () => Text(
            AppHelper.formatCurrency(
              double.tryParse(splitController.amountStr.value) ?? 0.0,
            ),
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: AppSize.sp(50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),

        // Next Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Obx(
            () => AppElevatedButton(
              title: "Next",
              onPressed: splitController.totalAmount > 0
                  ? () {
                      splitController.step.value = 2;
                    }
                  : () {},
            ),
          ),
        ),

        // Custom Numeric Keypad
        AddSplitNumericKeypad(
          onKeyPress: (val) => splitController.onKeyPress(val),
        ),
      ],
    );
  }

  // ── Step 2: Payer Selection Screen (Who Paid?) ─────────────────────────────
  Widget _buildPayerSelectionStep(ThemeData theme) {
    final membersList = widget.controller.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Who paid for this?", style: theme.textTheme.titleLarge),
              AppSize.gapH(4),
              Obx(
                () => Text(
                  AppHelper.formatCurrency(splitController.totalAmount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: AppSize.sp(30),
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSize.gapH(4),
              Text(
                "Select the group member who paid the bill upfront",
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        AppSize.gapH(12),
        Expanded(
          child: membersList.isEmpty
              ? Center(
                  child: Text(
                    "No members in group.",
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  padding: AppSize.symmetric(horizontal: 16),
                  itemCount: membersList.length,
                  separatorBuilder: (_, _) => AppSize.gapH(8),
                  itemBuilder: (context, index) {
                    final member = membersList[index];
                    final memberId = member.id ?? index;

                    return Obx(() {
                      final isSelected =
                          splitController.selectedPayerId.value == memberId;
                      return Material(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.35,
                              )
                            : theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            width: isSelected ? 1 : 0.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          dense: true,
                          leading: CircleAvatar(
                            radius: AppSize.r(16),
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHigh,
                            child: Text(
                              (member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : "M"),
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          title: Text(
                            member.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: AppSize.sp(22),
                                )
                              : Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: theme.colorScheme.outline,
                                  size: AppSize.sp(22),
                                ),
                          onTap: () {
                            splitController.selectedPayerId.value = memberId;
                          },
                        ),
                      );
                    });
                  },
                ),
        ),

        // Bottom Next Button
        Padding(
          padding: AppSize.symmetric(horizontal: 20, vertical: 16),
          child: Obx(
            () => AppElevatedButton(
              title: "Next",
              isEnabled: splitController.selectedPayerId.value != null,
              onPressed: splitController.selectedPayerId.value != null
                  ? () {
                      splitController.step.value = 3;
                    }
                  : () {},
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Split Allocation Screen ────────────────────────────────────────
  Widget _buildSplitAllocationStep(ThemeData theme, bool isKeyboardOpen) {
    final membersList = widget.controller.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Info
        Padding(
          padding: AppSize.only(left: 20, right: 20, bottom: 8, top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter amount to split",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: AppSize.sp(14),
                ),
              ),

              AppSize.gapH(4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(
                    () => Text(
                      AppHelper.formatCurrency(splitController.totalAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppSize.sp(34),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Payer Info Badge
                ],
              ),
              AppSize.gapH(6),

              // Inline Direct Typing Description Input
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 131, maxWidth: 160),
                child: CustomTextField(
                  title: "",
                  titleStyle: const TextStyle(fontSize: 0),
                  controller: splitController.descController,
                  focusNode: splitController.descFocusNode,
                  maxLines: 3,
                  keyBoardType: TextInputType.multiline,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  borderRadius: 20,
                  hint: "What's this for?",
                  hintTextStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  contentPadding: AppSize.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  onTap: () {
                    splitController.isEditingDescription = true;
                  },
                  onChanged: (val) {
                    splitController.isEditingDescription = true;
                    splitController.description.value = val;
                  },
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: AppSize.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: AppSize.sp(14),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  AppSize.gapW(6),
                  Text(
                    "Paid by ${splitController.paidByMemberName}",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AppSize.gapH(8),

        // Split Mode Selector Tabs
        Obx(
          () => AddSplitModeSelector(
            splitMode: splitController.splitMode.value,
            onModeSelected: (index) {
              splitController.setSplitMode(index);
            },
          ),
        ),
        AppSize.gapH(12),

        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(
            () => Text(
              splitController.getSplitModeTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        AppSize.gapH(8),

        // Members List with Individual Amounts/Shares/Percentages
        Expanded(
          child: membersList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off_rounded, size: 48),
                      AppSize.gapH(8),
                      const Text("No members in group yet."),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Add members first"),
                      ),
                    ],
                  ),
                )
              : GetBuilder<AddSplitExpenseController>(
                  builder: (controller) {
                    final currentMode = controller.splitMode.value;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: membersList.length,
                      itemBuilder: (context, index) {
                        final member = membersList[index];
                        final memberId = member.id ?? index;
                        final isChecked = controller.selectedMemberIds.contains(
                          memberId,
                        );

                        final double displayShare = controller
                            .calculateDisplayShare(memberId);

                        final String defaultTextStr = currentMode == 2
                            ? "1"
                            : (currentMode == 3 ? "0.00" : "");

                        return AddSplitMemberListItem(
                          member: member,
                          isChecked: isChecked,
                          splitMode: currentMode,
                          displayShare: displayShare,
                          controller: controller.getController(
                            memberId,
                            defaultText: defaultTextStr,
                          ),
                          onCheckboxChanged: (val) {
                            controller.toggleMemberSelection(memberId, val);
                          },
                          onChanged: () => controller.notifyUpdate(),
                          onTap: () {
                            controller.isEditingDescription = false;
                          },
                          onTextChanged: (val) {
                            controller.isEditingDescription = false;
                            if (currentMode == 1) {
                              controller.onMemberAmountChanged(memberId, val);
                            } else if (currentMode == 3) {
                              controller.onMemberPercentageChanged(
                                memberId,
                                val,
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
        ),

        // Bottom Button: "Done" when keyboard is open, "Send request" when keyboard is closed
        Padding(
          padding: AppSize.symmetric(horizontal: 20, vertical: 16),
          child: Obx(() {
            final isEnable = isKeyboardOpen || splitController.isValid;
            return Center(
              child: AppElevatedButton(
                title: isKeyboardOpen
                    ? "Done"
                    : (splitController.isEditMode
                          ? "Update request"
                          : "Send request"),
                isEnabled: isEnable,
                width: isKeyboardOpen ? AppSize.w(310) : double.infinity,
                height: isKeyboardOpen ? AppSize.h(33) : null,
                borderRadius: isKeyboardOpen ? 25 : null,
                onPressed: isKeyboardOpen
                    ? () {
                        FocusScope.of(context).unfocus();
                      }
                    : () => splitController.submitExpense(),
              ),
            );
          }),
        ),
      ],
    );
  }
}
