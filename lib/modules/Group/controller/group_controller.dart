import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/services/backup/backup_service.dart';

class GroupController extends GetxController {
  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  /// Loads all groups from SQLite database.
  Future<void> loadGroups() async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final result = await db.getAll(
        table: DBConstants.groupsTable,
        orderBy: "${DBConstants.id} DESC",
      );

      groups.value = result.map((e) => GroupModel.fromMap(e)).toList();
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

  /// Deletes a group from SQLite database.
  Future<bool> deleteGroup(int id) async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final count = await db.delete(
        table: DBConstants.groupsTable,
        where: "${DBConstants.id} = ?",
        args: [id],
      );

      if (count > 0) {
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
