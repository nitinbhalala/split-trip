import 'package:flutter/material.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_member_model.dart';

/// Custom GPay Style Numeric Keypad Widget
class AddSplitNumericKeypad extends StatelessWidget {
  final void Function(String) onKeyPress;

  const AddSplitNumericKeypad({super.key, required this.onKeyPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> keys = [
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      ".",
      "0",
      "DEL",
    ];

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.5 : 0.7,
      ),
      padding: AppSize.symmetric(vertical: 12, horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          return InkWell(
            onTap: () => onKeyPress(key),
            borderRadius: BorderRadius.circular(12),
            child: AppCard(
              showBorder: false,
              boxShadow: isDark ? false : true,
              color: theme.colorScheme.surface,
              borderRadius: 10,
              borderColor: theme.colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.3 : 0.6,
              ),
              child: Center(
                child: key == "DEL"
                    ? Icon(Icons.backspace_outlined, size: AppSize.sp(22))
                    : Text(key, style: theme.textTheme.titleLarge?.copyWith()),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Split Mode Selector Tabs Widget (GPay Style: 👤|👤, 123, ⊕, %)
class AddSplitModeSelector extends StatelessWidget {
  final int splitMode;
  final void Function(int) onModeSelected;

  const AddSplitModeSelector({
    super.key,
    required this.splitMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mode 0: Equal Split (👤|👤)
          _buildSplitModeTab(
            context: context,
            index: 0,
            selected: splitMode == 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: AppSize.sp(20),
                  color: splitMode == 0
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                Container(
                  height: AppSize.h(12),
                  width: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: splitMode == 0
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                Icon(
                  Icons.person,
                  size: AppSize.sp(20),
                  color: splitMode == 0
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // Mode 1: Amount Split (123)
          _buildSplitModeTab(
            context: context,
            index: 1,
            selected: splitMode == 1,
            child: Icon(
              Icons.onetwothree_sharp,
              size: AppSize.sp(30),
              color: splitMode == 1
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // Mode 2: Share Split (⊕ Pie Chart)
          _buildSplitModeTab(
            context: context,
            index: 2,
            selected: splitMode == 2,
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: AppSize.sp(22),
              color: splitMode == 2
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // Mode 3: Percentage Split (%)
          _buildSplitModeTab(
            context: context,
            index: 3,
            selected: splitMode == 3,
            child: Icon(
              Icons.percent,
              size: AppSize.sp(22),
              color: splitMode == 3
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitModeTab({
    required BuildContext context,
    required int index,
    required Widget child,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => onModeSelected(index),
      child: Container(
        padding: AppSize.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Member Item Widget in Split Allocation List
class AddSplitMemberListItem extends StatelessWidget {
  final GroupMemberModel member;
  final bool isChecked;
  final int splitMode;
  final double displayShare;
  final TextEditingController controller;
  final void Function(bool?) onCheckboxChanged;
  final VoidCallback onChanged;
  final void Function(String)? onTextChanged;
  final void Function()? onTap;

  const AddSplitMemberListItem({
    super.key,
    required this.member,
    required this.isChecked,
    required this.splitMode,
    required this.displayShare,
    required this.controller,
    required this.onCheckboxChanged,
    required this.onChanged,
    this.onTextChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSize.symmetric(vertical: 8),
      child: Row(
        children: [
          // Checkbox Selection
          Checkbox(
            value: isChecked,
            activeColor: AppColors.primary,
            shape: const CircleBorder(),
            onChanged: onCheckboxChanged,
          ),

          // Member Avatar
          CircleAvatar(
            radius: AppSize.r(18),
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              (member.name.isNotEmpty ? member.name[0].toUpperCase() : "M"),
              style: theme.textTheme.labelLarge!.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          AppSize.gapW(12),

          // Member Name & Calculated Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(member.name, style: theme.textTheme.titleMedium),
                if (isChecked) ...[
                  AppSize.gapH(2),
                  AppAutoSizeText(
                    text: AppHelper.formatCurrency(displayShare),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right Side Control according to Split Mode (Only shown if member is checked)
          if (!isChecked || splitMode == 0)
            const SizedBox.shrink()
          else if (splitMode == 1)
            SizedBox(
              width: AppSize.w(90),
              child: CustomTextField(
                isDOllar: true,
                dollarFontSize: AppSize.sp(13),
                title: "",
                controller: controller,
                keyBoardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.right,
                isMoney: true,
                isDense: true,
                allBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                onTap: onTap,
                onChanged: (val) {
                  onTextChanged?.call(val);
                  onChanged();
                },
              ),
            )
          else if (splitMode == 2)
            // Stepper Controls (- 1 +) for Shares Mode
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    int val = int.tryParse(controller.text) ?? 1;
                    if (val > 1) {
                      controller.text = (val - 1).toString();
                      onChanged();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: CircleAvatar(
                    radius: AppSize.r(16),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.remove,
                      size: AppSize.sp(18),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: AppSize.symmetric(horizontal: 12),
                  child: Text(
                    controller.text.isEmpty ? "1" : controller.text,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                InkWell(
                  onTap: () {
                    int val = int.tryParse(controller.text) ?? 1;
                    controller.text = (val + 1).toString();
                    onChanged();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: CircleAvatar(
                    radius: AppSize.r(16),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.add,
                      size: AppSize.sp(18),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            )
          else if (splitMode == 3) ...[
            // Underlined TextField + % for Percentages Mode
            SizedBox(
              width: AppSize.w(90),
              child: CustomTextField(
                title: "",
                controller: controller,
                keyBoardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.right,
                allBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                isDense: true,
                onTap: onTap,
                onChanged: (val) {
                  onTextChanged?.call(val);
                  onChanged();
                },
              ),
            ),
            AppSize.gapW(4),
            Icon(Icons.percent_rounded, size: AppSize.sp(14)),
          ],
        ],
      ),
    );
  }
}
