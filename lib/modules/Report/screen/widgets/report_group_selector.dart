import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/custom_drop_down.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Report/controller/report_controller.dart';

class ReportGroupSelector extends StatelessWidget {
  final ReportController controller;

  const ReportGroupSelector({super.key, required this.controller});

  Widget _buildGroupAvatar(GroupModel? group, {double radius = 14}) {
    final hasImage =
        group != null &&
        group.imagePath.isNotEmpty &&
        File(group.imagePath).existsSync();

    if (hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(group.imagePath)),
      );
    }

    final bgColor = group != null
        ? Color(group.colorValue)
        : const Color(0xFF3B82F6);
    final initialText = (group != null && group.name.isNotEmpty)
        ? group.name[0].toUpperCase()
        : "G";

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initialText,
        style: TextStyle(
          fontSize: radius * 0.9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final selectedGroup = controller.selectedGroup.value;
      final currentSelectedId =
          controller.groups
              .firstWhereOrNull((g) => g.id == selectedGroup?.id)
              ?.id ??
          (controller.groups.isNotEmpty ? controller.groups.first.id : null);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Group", style: theme.textTheme.labelMedium),
          AppSize.gapH(5),
          CustomDropdown<int>(
            hint: "Select Group",
            selectedValue: currentSelectedId,
            items: controller.groups.map((group) {
              return DropdownItem<int>(
                value: group.id ?? 0,
                label: group.name,
                leading: _buildGroupAvatar(group, radius: 14),
              );
            }).toList(),
            onChanged: (groupId) {
              if (groupId != null) {
                final group = controller.groups.firstWhereOrNull(
                  (g) => g.id == groupId,
                );
                if (group != null) {
                  controller.selectGroup(group);
                }
              }
            },
          ),
        ],
      );
    });
  }
}
