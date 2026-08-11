import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';

class AddPeopleBottomSheet extends StatefulWidget {
  final GroupDetailController controller;

  const AddPeopleBottomSheet({
    super.key,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context,
    GroupDetailController controller,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddPeopleBottomSheet(controller: controller),
    );
  }

  @override
  State<AddPeopleBottomSheet> createState() => _AddPeopleBottomSheetState();
}

class _AddPeopleBottomSheetState extends State<AddPeopleBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: true,
      child: Padding(
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
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSize.gapH(16),
            Obx(
              () => Text(
                "Add people to ${widget.controller.groupName.value}",
                style: theme.textTheme.titleMedium,
              ),
            ),
            AppSize.gapH(16),

            CustomTextField(
              title: "",
              controller: _nameController,
              hint: "Member Name (e.g. john doe)",
              prefixIcon: const Icon(Icons.person),
            ),
            AppSize.gapH(12),

            CustomTextField(
              title: "",
              controller: _phoneController,
              hint: "Phone / Contact (Optional)",
              prefixIcon: const Icon(Icons.phone_rounded),
              keyBoardType: TextInputType.phone,
            ),
            AppSize.gapH(20),

            AppElevatedButton(
              title: "Add Member",
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  Get.back();
                  final success = await widget.controller.addMember(
                    name: name,
                    phone: _phoneController.text.trim(),
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
      ),
    );
  }
}
