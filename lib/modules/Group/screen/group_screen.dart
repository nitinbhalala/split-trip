import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
import 'package:split_trip/modules/Group/screen/widgets/create_group_bottom_sheet.dart';
import 'package:split_trip/modules/Group/screen/widgets/group_empty_state.dart';
import 'package:split_trip/modules/Group/screen/widgets/group_list_item.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
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
    );
  }

  void _confirmDeleteGroup(int groupId, String groupName) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Group"),
        content: Text("Are you sure you want to delete '$groupName'?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Get.back();
              final success = await _groupController.deleteGroup(groupId);
              if (success) {
                AppSnackbar.success(message: "Group deleted successfully.");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Groups", showBackButton: false),
      body: Padding(
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
                    return GroupListItem(
                      item: item,
                      onDeleteConfirm: _confirmDeleteGroup,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text(
          "Create Group",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
