import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/widgets/app_alert_dialog.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
import 'package:split_trip/modules/Group/screen/widgets/create_group_bottom_sheet.dart';
import 'package:split_trip/modules/Group/screen/widgets/group_empty_state.dart';
import 'package:split_trip/modules/Group/screen/widgets/group_list_item.dart';

class DashbordScreen extends StatefulWidget {
  const DashbordScreen({super.key});

  @override
  State<DashbordScreen> createState() => _DashbordScreenState();
}

class _DashbordScreenState extends State<DashbordScreen> {
  late final GroupController _groupController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _groupController = Get.isRegistered<GroupController>()
        ? Get.find<GroupController>()
        : Get.put(GroupController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateGroupBottomSheet(groupController: _groupController);
      },
    ).then((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _confirmDeleteGroup(int groupId, String groupName) {
    AppAlertDialog.show(
      titleText: "Delete Group", //dharmik snackbar sho
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
            // final success = await _groupController.deleteGroup(groupId);
            // if (success) {
            //   AppSnackbar.success(message: "Group deleted successfully.");
            // }
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
    return Scaffold(
      appBar: const CommonAppBar(title: "Dashbord", showBackButton: false),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: AppSize.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              // Search Bar
              CustomTextField(
                title: "",
                controller: _searchController,
                hint: "Search groups...",
                prefixIcon: const Icon(Icons.search_rounded),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              AppSize.gapH(14),

              // Dynamic Group List from SQLite Database
              Expanded(
                child: Obx(() {
                  if (_groupController.isLoading.value &&
                      _groupController.groups.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredGroups = _groupController.groups
                      .where(
                        (g) => g.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

                  if (filteredGroups.isEmpty) {
                    return GroupEmptyState(searchQuery: _searchQuery);
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: AppSize.only(bottom: 80),
                    itemCount: filteredGroups.length,
                    separatorBuilder: (_, _) => AppSize.gapH(10),
                    itemBuilder: (context, index) {
                      final item = filteredGroups[index];
                      final pendingExp =
                          _groupController.groupPendingExpenses[item.id] ?? 0.0;
                      return GroupListItem(
                        item: item,
                        totalExpense: pendingExp,
                        onDeleteConfirm: _confirmDeleteGroup,
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _showCreateGroupDialog,
      //   backgroundColor: AppColors.primaryDark,
      //   foregroundColor: AppColors.white,
      //   isExtended: true,
      //   extendedIconLabelSpacing: 4,

      //   elevation: 4,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //   icon: Icon(Icons.group_add_rounded, size: AppSize.sp(20)),
      //   extendedPadding: AppSize.symmetric(horizontal: 10, vertical: 0),
      //   label: Text(
      //     "Create Group",
      //     style: Theme.of(context).textTheme.titleSmall,
      //   ),
      // ),
      floatingActionButton: AppElevatedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          _showCreateGroupDialog();
        },
        color: AppColors.primaryDark,
        width: AppSize.w(150),
        height: AppSize.h(44),
        elevation: 4,
        borderRadius: 6,
        icon: Icons.group_add_rounded,
        title: "Create Group",
      ),
    );
  }
}
