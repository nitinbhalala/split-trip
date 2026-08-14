import 'dart:io';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/app_alert_dialog.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Group/screen/widgets/add_people_bottom_sheet.dart';
import 'package:split_trip/modules/Group/screen/widgets/create_group_bottom_sheet.dart';

class GroupInfoScreen extends StatefulWidget {
  final GroupModel group;
  final GroupDetailController controller;
  final List<Color>? gradient;
  final IconData? icon;

  const GroupInfoScreen({
    super.key,
    required this.group,
    required this.controller,
    this.gradient,
    this.icon,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  void _showEditGroupBottomSheet() {
    final currentGroup = GroupModel(
      id: widget.group.id,
      name: widget.controller.groupName.value.isNotEmpty
          ? widget.controller.groupName.value
          : widget.group.name,
      description: widget.controller.groupDescription.value.isNotEmpty
          ? widget.controller.groupDescription.value
          : widget.group.description,
      iconName: widget.controller.iconName.value.isNotEmpty
          ? widget.controller.iconName.value
          : widget.group.iconName,
      colorValue: widget.controller.colorValue.value != 0
          ? widget.controller.colorValue.value
          : widget.group.colorValue,
      imagePath: widget.controller.imagePath.value.isNotEmpty
          ? widget.controller.imagePath.value
          : widget.group.imagePath,
      createdAt: widget.group.createdAt,
      updatedAt: widget.group.updatedAt,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateGroupBottomSheet(
          groupDetailController: widget.controller,
          initialGroup: currentGroup,
        );
      },
    );
  }

  void _showAddPeopleDialog() {
    AddPeopleBottomSheet.show(context, widget.controller);
  }

  void _confirmRemoveMember(int memberId, String memberName) {
    AppAlertDialog.show(
      borderRadius: 10,
      titleText: "Do You want to remove $memberName from  group?",
      contentText:
          "This member will be removed from the group and will no longer participate in future expense splits.",
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            "Cancel",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: AppColors.primary,
              fontWeight: .w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            final success = await widget.controller.deleteMember(memberId);
            if (success) {
              AppSnackbar.success(message: "$memberName removed from group.");
            }
          },
          child: Text(
            "Remove from group",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: AppColors.primary,
              fontWeight: .w500,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteGroup() {
    final groupName = widget.controller.groupName.value.isNotEmpty
        ? widget.controller.groupName.value
        : widget.group.name;
    final groupId = widget.group.id;
    if (groupId == null) return;

    AppAlertDialog.show(
      titleText: "Delete Group",
      contentText: "Are you sure you want to delete '$groupName'?",
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            "Cancel",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            final groupController = Get.isRegistered<GroupController>()
                ? Get.find<GroupController>()
                : Get.put(GroupController());
            final success = await groupController.deleteGroup(groupId);
            if (success) {
              Get.until((route) => route.isFirst);
              AppSnackbar.success(
                message: "Group '$groupName' deleted successfully.",
              );
            } else {
              AppSnackbar.error(message: "Failed to delete group.");
            }
          },
          child: Text(
            "Delete",
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: "",
        enableBottomBorder: false,
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: AppSize.only(left: 12, right: 12, top: 0, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Obx(() {
                  final imgPath = widget.controller.imagePath.value.isNotEmpty
                      ? widget.controller.imagePath.value
                      : widget.group.imagePath;
                  final hasImg =
                      imgPath.isNotEmpty && File(imgPath).existsSync();

                  if (hasImg) {
                    return CircleAvatar(
                      radius: AppSize.sp(34),
                      backgroundImage: FileImage(File(imgPath)),
                    );
                  }

                  final colorVal = widget.controller.colorValue.value != 0
                      ? widget.controller.colorValue.value
                      : widget.group.colorValue;
                  final groupName = widget.controller.groupName.value.isNotEmpty
                      ? widget.controller.groupName.value
                      : widget.group.name;
                  final firstChar = groupName.trim().isNotEmpty
                      ? groupName.trim()[0].toUpperCase()
                      : "?";

                  return CircleAvatar(
                    radius: AppSize.sp(34),
                    backgroundColor: Color(colorVal),
                    child: Text(
                      firstChar,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),

              AppSize.gapH(5),

              // Group Name Title with Edit Pen Icon (Image 3 Style)
              Center(
                child: Obx(
                  () => InkWell(
                    onTap: _showEditGroupBottomSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: AppSize.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.controller.groupName.value.isNotEmpty
                                  ? widget.controller.groupName.value
                                  : widget.group.name,
                              style: theme.textTheme.headlineSmall?.copyWith(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          AppSize.gapW(8),
                          Icon(
                            Icons.edit_outlined,
                            size: AppSize.sp(16),
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Description Subtitle Line (If present)
              Center(
                child: Obx(() {
                  final desc =
                      widget.controller.groupDescription.value.isNotEmpty
                      ? widget.controller.groupDescription.value
                      : widget.group.description;
                  if (desc.trim().isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: AppSize.only(top: 2, bottom: 4),
                    child: Text(
                      desc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
              AppSize.gapH(10),

              // "+ Add people" Button Row (Image 3 Style)
              InkWell(
                onTap: _showAddPeopleDialog,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: AppSize.sp(22),
                    ),
                    AppSize.gapW(5),
                    Text(
                      " Add people",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSize.gapH(12),

              // "Group members (X)" Section Title (Image 3 Style)
              Obx(
                () => Text(
                  "Group members (${widget.controller.members.length})",
                  style: theme.textTheme.titleMedium?.copyWith(),
                ),
              ),
              AppSize.gapH(12),

              // Group Members List
              Obx(() {
                final members = widget.controller.members;
                if (members.isEmpty) {
                  return Padding(
                    padding: AppSize.symmetric(vertical: 16),
                    child: Text("No members added yet."),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => AppSize.gapH(0),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isOwner = index == 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: CircleAvatar(
                        radius: AppSize.sp(16),
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : "M",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: theme.textTheme.titleSmall,
                      ),
                      trailing: isOwner
                          ? Container(
                              padding: AppSize.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "Admin",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.do_not_disturb_on_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: AppSize.sp(24),
                              ),
                              onPressed: () {
                                if (member.id != null) {
                                  _confirmRemoveMember(member.id!, member.name);
                                }
                              },
                            ),
                    );
                  },
                );
              }),
              AppSize.gapH(16),
              Center(
                child: TextButton.icon(
                  onPressed: _confirmDeleteGroup,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: AppSize.sp(20),
                  ),
                  label: Text(
                    "Delete group",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
