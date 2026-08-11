import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/const/app_data.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/data/service/image_picker_service.dart';
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
  String _imagePath = "";

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
      _imagePath = widget.initialGroup!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await ImagePickerService.showPickerSheet(
      context,
      showRemoveOption: _imagePath.isNotEmpty,
    );
    if (result == null) return;

    if (result.isRemoved) {
      setState(() {
        _imagePath = "";
      });
    } else if (result.file != null) {
      setState(() {
        _imagePath = result.file!.path;
      });
    }
  }

  Color _getAvatarColor(String name) {
    if (name.trim().isEmpty) return const Color(0xFF3B82F6);
    final index = name.trim().codeUnits.fold(0, (sum, char) => sum + char);
    return _allColors[index.abs() % _allColors.length];
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      AppSnackbar.error(message: "Please enter a valid group name.");
      return;
    }

    Get.back();

    final avatarColor = _getAvatarColor(groupName);

    if (isEditMode) {
      final desc = _descController.text.trim();
      final iconName = _selectedIconName;
      final colorVal = avatarColor.toARGB32();
      final imgPath = _imagePath;
      bool success = false;

      if (widget.groupDetailController != null) {
        success = await widget.groupDetailController!.updateGroupDetails(
          name: groupName,
          description: desc,
          iconName: iconName,
          colorValue: colorVal,
          imagePath: imgPath,
        );
      } else if (widget.groupController != null &&
          widget.initialGroup!.id != null) {
        final controller =
            widget.groupDetailController ??
            GroupDetailController(groupId: widget.initialGroup!.id!);
        success = await controller.updateGroupDetails(
          name: groupName,
          description: desc,
          iconName: iconName,
          colorValue: colorVal,
          imagePath: imgPath,
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
            imagePath: imgPath,
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
        colorValue: avatarColor.toARGB32(),
        imagePath: _imagePath,
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
    final hasImage = _imagePath.isNotEmpty && File(_imagePath).existsSync();
    final avatarColor = _getAvatarColor(_nameController.text);

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
              AppSize.gapH(16),

              // Title
              Text(
                isEditMode ? "Edit Group Details" : "Create New Group",
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSize.gapH(16),

              // Group Image / Avatar Upload Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: AppSize.w(76),
                        height: AppSize.w(76),
                        decoration: BoxDecoration(
                          color: avatarColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: avatarColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: hasImage
                            ? ClipOval(
                                child: Image.file(
                                  File(_imagePath),
                                  width: AppSize.w(76),
                                  height: AppSize.w(76),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                _nameController.text.trim().isNotEmpty
                                    ? _nameController.text
                                          .trim()[0]
                                          .toUpperCase()
                                    : "?",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: AppSize.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            hasImage
                                ? Icons.edit_rounded
                                : Icons.camera_alt_rounded,
                            size: AppSize.sp(14),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSize.gapH(6),
              Center(
                child: Text(
                  hasImage ? "Tap to change photo" : "Tap to upload photo",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppSize.gapH(16),

              // Group Name Input
              CustomTextField(
                title: "Group Name",
                textStyle: theme.textTheme.bodyMedium,
                hintTextStyle: theme.textTheme.bodySmall,
                titleStyle: theme.textTheme.labelSmall,
                isDense: true,
                controller: _nameController,
                hint: "Enter group name (e.g., Goa Trip)",
                borderRadius: 8,
                contentPadding: AppSize.symmetric(vertical: 10, horizontal: 10),
                onChanged: (_) => setState(() {}),
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
                contentPadding: AppSize.symmetric(vertical: 10, horizontal: 10),
                onChanged: (_) => setState(() {}),
              ),
              AppSize.gapH(20),

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
