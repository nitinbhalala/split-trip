import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/services/backup/backup_service.dart';

class GroupController extends GetxController {
  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxMap<int, double> groupPendingExpenses = <int, double>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  /// Loads all groups & calculates pending (unsettled) expenses from SQLite database.
  Future<void> loadGroups() async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final result = await db.getAll(
        table: DBConstants.groupsTable,
        orderBy: "${DBConstants.id} DESC",
      );

      final loadedGroups = result.map((e) => GroupModel.fromMap(e)).toList();
      groups.value = loadedGroups;

      // Calculate total pending (unsettled) expenses for each group
      final Map<int, double> tempPending = {};
      for (var g in loadedGroups) {
        if (g.id != null) {
          final membersData = await db.getWhere(
            table: DBConstants.groupMembersTable,
            where: "${DBConstants.memberGroupId} = ?",
            args: [g.id],
            orderBy: "${DBConstants.id} ASC",
          );
          final members =
              membersData.map((e) => GroupMemberModel.fromMap(e)).toList();

          final messagesData = await db.getWhere(
            table: DBConstants.groupMessagesTable,
            where: "${DBConstants.msgGroupId} = ?",
            args: [g.id],
            orderBy: "${DBConstants.id} ASC",
          );

          double totalPending = 0.0;
          for (var mData in messagesData) {
            final msg = GroupMessageModel.fromMap(mData);
            if (msg.isExpense) {
              final meta = ExpenseMetadataModel.parse(msg, members);
              if (!meta.isClosed) {
                meta.splits.forEach((memberName, share) {
                  final bool isPaid = (memberName == meta.paidByName) ||
                      meta.paidMemberNames.contains(memberName);
                  if (!isPaid) {
                    totalPending += share;
                  }
                });
              }
            }
          }
          tempPending[g.id!] = totalPending;
        }
      }
      groupPendingExpenses.value = tempPending;
    } catch (e) {
      debugPrint("Error loading groups: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds a new group into SQLite database.
  Future<bool> addGroup(
    String name,
    String description, {
    String iconName = "group_work",
    int colorValue = 0xFF3B82F6,
    String imagePath = "",
  }) async {
    if (name.trim().isEmpty) return false;
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final now = DateTime.now().toIso8601String();
      final group = GroupModel(
        name: name.trim(),
        description: description.trim(),
        iconName: iconName,
        colorValue: colorValue,
        imagePath: imagePath,
        createdAt: now,
        updatedAt: now,
      );

      final id = await db.insert(
        table: DBConstants.groupsTable,
        values: group.toMap(),
      );

      if (id > 0) {
        // Automatically add Admin member using Profile details (First Name + Last Name)
        String adminName = "";
        if (Get.isRegistered<ProfileController>()) {
          final profile = Get.find<ProfileController>();
          final fName = profile.firstName.value.trim();
          final lName = profile.lastName.value.trim();
          adminName = "$fName $lName".trim();
        }

        if (adminName.isEmpty) {
          final profileResult = await db.getWhere(
            table: DBConstants.profileTable,
            where: "id = ?",
            args: [1],
          );
          if (profileResult.isNotEmpty) {
            final data = profileResult.first;
            final fName = ((data['first_name'] as String?) ?? "").trim();
            final lName = ((data['last_name'] as String?) ?? "").trim();
            adminName = "$fName $lName".trim();
          }
        }

        if (adminName.isEmpty) {
          adminName = "You";
        }

        final adminMember = GroupMemberModel(
          groupId: id,
          name: adminName,
          createdAt: now,
        );

        await db.insert(
          table: DBConstants.groupMembersTable,
          values: adminMember.toMap(),
        );

        await loadGroups();
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding group: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Deletes a group from SQLite database along with its members & messages.
  Future<bool> deleteGroup(int id) async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;

      // Delete group members
      await db.delete(
        table: DBConstants.groupMembersTable,
        where: "${DBConstants.memberGroupId} = ?",
        args: [id],
      );

      // Delete group messages
      await db.delete(
        table: DBConstants.groupMessagesTable,
        where: "${DBConstants.msgGroupId} = ?",
        args: [id],
      );

      // Delete group record
      final count = await db.delete(
        table: DBConstants.groupsTable,
        where: "${DBConstants.id} = ?",
        args: [id],
      );

      if (count > 0) {
        final tag = "group_$id";
        if (Get.isRegistered<GroupDetailController>(tag: tag)) {
          Get.delete<GroupDetailController>(tag: tag);
        }
        await loadGroups();
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting group: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
