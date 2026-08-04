import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSize.gapH(16),
              Text(
                "Add people to ${widget.controller.groupName.value}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSize.gapH(16),

              CustomTextField(
                title: "",
                controller: nameController,
                hint: "Member Name (e.g. john doe)",
                prefixIcon: Icon(Icons.person),
              ),
              AppSize.gapH(12),

              CustomTextField(
                title: "",
                controller: phoneController,
                hint: "Phone / Contact (Optional)",
                prefixIcon: Icon(Icons.phone_rounded),
                keyBoardType: TextInputType.phone,
              ),
              AppSize.gapH(20),

              AppElevatedButton(
                title: "Add Member",
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Get.back();
                    final success = await widget.controller.addMember(
                      name: name,
                      phone: phoneController.text.trim(),
                    );
                    if (success) {
                      AppSnackbar.success(message: "$name added to group!");
                    }
                  } else {
                    AppSnackbar.error(
                      message: "Please enter a valid member name.",
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveMember(int memberId, String memberName) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text("Do You want to remove $memberName from  group?"),
        content: Text(
          // "They will not be able to send or view new messages in this group"
          "This member will be removed from the group and will no longer participate in future expense splits.",
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          InkWell(
            onTap: () => Get.back(),
            child: Text(
              "Cancel",
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: AppColors.primary,
                fontWeight: .w500,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSize.only(left: 12, right: 12, top: 0, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Obx(() {
                final colorVal = widget.controller.colorValue.value != 0
                    ? widget.controller.colorValue.value
                    : widget.group.colorValue;
                final iconStr = widget.controller.iconName.value.isNotEmpty
                    ? widget.controller.iconName.value
                    : widget.group.iconName;
                return CircleAvatar(
                  radius: AppSize.sp(30),
                  backgroundColor: Color(colorVal),
                  child: Icon(
                    AppIcons.getIcon(iconStr),
                    color: AppColors.white,
                    size: AppSize.sp(30),
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
                final desc = widget.controller.groupDescription.value.isNotEmpty
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
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
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
                    title: Text(member.name, style: theme.textTheme.titleSmall),
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

                  // Row(
                  //   children: [
                  //     // Avatar
                  //     CircleAvatar(
                  //       radius: AppSize.sp(16),
                  //       backgroundColor: theme.colorScheme.primary,
                  //       child: Text(
                  //         member.name.isNotEmpty
                  //             ? member.name[0].toUpperCase()
                  //             : "M",
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.w700,

                  //           color: AppColors.white,
                  //         ),
                  //       ),
                  //     ),
                  //     AppSize.gapW(14),

                  //     // Name
                  //     Expanded(
                  //       child: Text(
                  //         member.name,
                  //         style: theme.textTheme.titleSmall,
                  //       ),
                  //     ),

                  //     // Admin Badge OR Minus Remove Button (Image 3 Style)
                  //     if (isOwner)
                  //       Container(
                  //         padding: AppSize.symmetric(
                  //           horizontal: 12,
                  //           vertical: 4,
                  //         ),
                  //         decoration: BoxDecoration(
                  //           color: const Color(
                  //             0xFF1D4ED8,
                  //           ), // GPay Blue Admin Badge
                  //           borderRadius: BorderRadius.circular(16),
                  //         ),
                  //         child: Text(
                  //           "Admin",
                  //           style: theme.textTheme.labelMedium!.copyWith(
                  //             color: AppColors.white,
                  //           ),
                  //         ),
                  //       )
                  //     else
                  //       Center(
                  //         child: GestureDetector(
                  //           child: Icon(
                  //             Icons
                  //                 .do_not_disturb_on_outlined, // Minus Remove Button
                  //             color: theme.colorScheme.onSurfaceVariant,
                  //             size: AppSize.sp(22),
                  //           ),
                  //           onTap: () {
                  //             if (member.id != null) {
                  //               _confirmRemoveMember(member.id!, member.name);
                  //             }
                  //           },
                  //         ),
                  //       ),
                  //   ],
                  // );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
