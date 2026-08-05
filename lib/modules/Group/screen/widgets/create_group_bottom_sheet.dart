import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/core/common/widgets/app_icon_picker.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/const/app_data.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';

class CreateGroupBottomSheet extends StatefulWidget {
  final GroupController? groupController;
  final GroupDetailController? groupDetailController;
  final GroupModel? initialGroup;
  final Function(GroupModel updatedGroup)? onGroupUpdated;

  const CreateGroupBottomSheet({
    super.key,
    this.groupController,
    this.groupDetailController,
    this.initialGroup,
    this.onGroupUpdated,
  });

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedIconName = "group_work";
  Color _selectedColor = const Color(0xFF3B82F6);

  final List<Color> _allColors = [
    ...AppData.row1Colors,
    ...AppData.row2Colors,
    ...AppData.row3Colors,
  ];

  bool get isEditMode => widget.initialGroup != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      _nameController.text = widget.initialGroup!.name;
      _descController.text = widget.initialGroup!.description;
      _selectedIconName = widget.initialGroup!.iconName;
      _selectedColor = Color(widget.initialGroup!.colorValue);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      AppSnackbar.error(message: "Please enter a valid group name.");
      return;
    }

    Get.back();

    if (isEditMode) {
      final desc = _descController.text.trim();
      final iconName = _selectedIconName;
      final colorVal = _selectedColor.toARGB32();
      bool success = false;

      if (widget.groupDetailController != null) {
        success = await widget.groupDetailController!.updateGroupDetails(
          name: groupName,
          description: desc,
          iconName: iconName,
          colorValue: colorVal,
        );
      } else if (widget.groupController != null &&
          widget.initialGroup!.id != null) {
        // Fallback update via controller
        final controller =
            widget.groupDetailController ??
            GroupDetailController(groupId: widget.initialGroup!.id!);
        success = await controller.updateGroupDetails(
          name: groupName,
          description: desc,
          iconName: iconName,
          colorValue: colorVal,
        );
      }

      if (success) {
        AppSnackbar.success(message: "Group updated successfully!");
        if (widget.onGroupUpdated != null) {
          final updated = GroupModel(
            id: widget.initialGroup!.id,
            name: groupName,
            description: desc,
            iconName: iconName,
            colorValue: colorVal,
            createdAt: widget.initialGroup!.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
          widget.onGroupUpdated!(updated);
        }
      } else {
        AppSnackbar.error(message: "Failed to update group. Please try again.");
      }
    } else {
      final controller = widget.groupController ?? Get.find<GroupController>();
      final success = await controller.addGroup(
        groupName,
        _descController.text.trim(),
        iconName: _selectedIconName,
        colorValue: _selectedColor.toARGB32(),
      );

      if (success) {
        AppSnackbar.success(
          message: "Group '$groupName' created successfully!",
        );
      } else {
        AppSnackbar.error(message: "Failed to create group. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: AppSize.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSize.gapH(20),

              // Title
              Text(
                isEditMode ? "Edit Group Details" : "Create New Group",
                style: theme.textTheme.titleLarge!.copyWith(fontWeight: .w500),
              ),
              AppSize.gapH(20),

              // Live Preview Card Header (Row Layout)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: AppSize.w(40),
                    height: AppSize.w(40),
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      AppIcons.getIcon(_selectedIconName),
                      color: AppColors.white,
                      size: AppSize.sp(22),
                    ),
                  ),
                  AppSize.gapW(14),
                  Expanded(
                    child: CustomTextField(
                      isDense: true,
                      title: "",
                      titleStyle: const TextStyle(fontSize: 0),
                      controller: _nameController,
                      hint: "Group Name (e.g., Goa Trip)",
                      textStyle: theme.textTheme.bodyMedium,
                      hintTextStyle: theme.textTheme.bodySmall,
                      borderRadius: 8,
                      contentPadding: AppSize.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              AppSize.gapH(14),

              // Description Input
              CustomTextField(
                title: "Description (Optional)",
                textStyle: theme.textTheme.bodyMedium,
                hintTextStyle: theme.textTheme.bodySmall,
                titleStyle: theme.textTheme.labelSmall,
                isDense: true,
                controller: _descController,
                hint: "Enter group description...",
                borderRadius: 8,
                contentPadding: AppSize.symmetric(vertical: 8, horizontal: 4),
                onChanged: (_) => setState(() {}),
              ),
              AppSize.gapH(20),

              // Color Selection Title
              Text("Select Group Color", style: theme.textTheme.titleSmall),
              AppSize.gapH(10),

              // Color Picker Horizontal List
              SizedBox(
                height: AppSize.h(48),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _allColors.length,
                  separatorBuilder: (_, _) => AppSize.gapW(10),
                  itemBuilder: (context, index) {
                    final color = _allColors[index];
                    final isSelected =
                        color.toARGB32() == _selectedColor.toARGB32();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: AppSize.w(38),
                        height: AppSize.w(38),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.onSurface,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: AppSize.sp(18),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              AppSize.gapH(20),

              // Icon Selection Title
              Text("Select Group Icon", style: theme.textTheme.titleSmall),
              AppSize.gapH(10),

              // Categorized Icon Picker Box
              Container(
                height: AppSize.h(240),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: AppIconPicker(
                  selectedIconName: _selectedIconName,
                  selectedColor: _selectedColor,
                  onIconSelected: (iconName) {
                    setState(() {
                      _selectedIconName = iconName;
                    });
                  },
                ),
              ),
              AppSize.gapH(24),

              // Save / Create Button
              AppElevatedButton(
                title: isEditMode ? "Save Changes" : "Create Group",
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
