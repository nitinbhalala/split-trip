import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
import 'package:split_trip/services/backup/backup_service.dart';

class GroupDetailController extends GetxController {
  final int groupId;
  final RxString groupName = "".obs;
  final RxString groupDescription = "".obs;
  final RxString iconName = "".obs;
  final RxInt colorValue = 0.obs;

  GroupDetailController({required this.groupId});

  final RxList<GroupMemberModel> members = <GroupMemberModel>[].obs;
  final RxList<GroupMessageModel> messages = <GroupMessageModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGroupData();
  }

  /// Loads members and messages for this group.
  Future<void> loadGroupData() async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;

      // 1. Fetch Group Details
      final groupData = await db.getById(
        table: DBConstants.groupsTable,
        id: groupId,
      );
      if (groupData != null) {
        groupName.value = (groupData['name'] as String?) ?? "";
        groupDescription.value = (groupData['description'] as String?) ?? "";
        iconName.value = (groupData['icon_name'] as String?) ?? "group_work";
        colorValue.value = (groupData['color_value'] as int?) ?? 0xFF3B82F6;
      }

      // 2. Fetch Members
      final membersData = await db.getWhere(
        table: DBConstants.groupMembersTable,
        where: "${DBConstants.memberGroupId} = ?",
        args: [groupId],
        orderBy: "${DBConstants.id} ASC",
      );
      members.value = membersData.map((e) => GroupMemberModel.fromMap(e)).toList();

      // 3. Fetch Messages
      final messagesData = await db.getWhere(
        table: DBConstants.groupMessagesTable,
        where: "${DBConstants.msgGroupId} = ?",
        args: [groupId],
        orderBy: "${DBConstants.id} ASC",
      );
      messages.value = messagesData.map((e) => GroupMessageModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Error loading group detail data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates group title in SQLite database.
  Future<bool> updateGroupName(String newName) async {
    return updateGroupDetails(name: newName);
  }

  /// Updates full group details in SQLite database.
  Future<bool> updateGroupDetails({
    required String name,
    String? description,
    String? iconName,
    int? colorValue,
  }) async {
    if (name.trim().isEmpty) return false;
    try {
      final db = DatabaseHelper.instance;
      final values = <String, dynamic>{
        'name': name.trim(),
        if (description != null) 'description': description.trim(),
        if (iconName != null) 'icon_name': iconName,
        if (colorValue != null) 'color_value': colorValue,
      };

      final count = await db.update(
        table: DBConstants.groupsTable,
        values: values,
        where: "${DBConstants.id} = ?",
        args: [groupId],
      );

      if (count > 0) {
        groupName.value = name.trim();
        if (description != null) groupDescription.value = description.trim();
        if (iconName != null) this.iconName.value = iconName;
        if (colorValue != null) this.colorValue.value = colorValue;
        if (Get.isRegistered<GroupController>()) {
          Get.find<GroupController>().loadGroups();
        }
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating group details: $e");
      return false;
    }
  }

  /// Adds a new member to the group.
  Future<bool> addMember({required String name, String? phone}) async {
    if (name.trim().isEmpty) return false;
    try {
      final db = DatabaseHelper.instance;
      final now = DateTime.now().toIso8601String();
      final member = GroupMemberModel(
        groupId: groupId,
        name: name.trim(),
        phone: phone?.trim(),
        createdAt: now,
      );

      final id = await db.insert(
        table: DBConstants.groupMembersTable,
        values: member.toMap(),
      );

      if (id > 0) {
        await loadGroupData();
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding member: $e");
      return false;
    }
  }

  /// Deletes a member from the group.
  Future<bool> deleteMember(int memberId) async {
    try {
      final db = DatabaseHelper.instance;
      final count = await db.delete(
        table: DBConstants.groupMembersTable,
        where: "${DBConstants.id} = ?",
        args: [memberId],
      );

      if (count > 0) {
        await loadGroupData();
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting member: $e");
      return false;
    }
  }

  /// Sends a normal text chat message.
  Future<bool> sendMessage({
    required String text,
    String senderName = "Me",
  }) async {
    if (text.trim().isEmpty) return false;
    try {
      final db = DatabaseHelper.instance;
      final now = DateTime.now().toIso8601String();
      final message = GroupMessageModel(
        groupId: groupId,
        senderName: senderName,
        messageText: text.trim(),
        amount: 0.0,
        isExpense: false,
        createdAt: now,
      );

      final id = await db.insert(
        table: DBConstants.groupMessagesTable,
        values: message.toMap(),
      );

      if (id > 0) {
        await loadGroupData();
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error sending message: $e");
      return false;
    }
  }

  /// Posts a GPay-style Split Expense Request into the group chat feed.
  Future<bool> addSplitExpenseRequest({
    required String title,
    required double amount,
  }) async {
    if (amount <= 0) return false;
    try {
      final db = DatabaseHelper.instance;
      final now = DateTime.now().toIso8601String();
      final message = GroupMessageModel(
        groupId: groupId,
        senderName: "Me",
        messageText: title.trim().isEmpty ? "Expense" : title.trim(),
        amount: amount,
        isExpense: true,
        createdAt: now,
      );

      final id = await db.insert(
        table: DBConstants.groupMessagesTable,
        values: message.toMap(),
      );

      if (id > 0) {
        await loadGroupData();
        await BackupService.markDataChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding split expense: $e");
      return false;
    }
  }
}
