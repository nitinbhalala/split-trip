import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';

class ReportController extends GetxController {
  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final Rxn<GroupModel> selectedGroup = Rxn<GroupModel>();
  final RxBool isLoading = false.obs;

  // Selected Group Report Metrics
  final RxDouble totalExpense = 0.0.obs;
  final RxInt totalExpenseCount = 0.obs;
  final RxList<GroupMemberModel> members = <GroupMemberModel>[].obs;
  final RxMap<String, double> memberExpenses = <String, double>{}.obs;
  final RxMap<String, double> memberPercentages = <String, double>{}.obs;
  final RxMap<String, Color> memberColors = <String, Color>{}.obs;
  final RxMap<String, double> memberPendingAmounts = <String, double>{}.obs;
  final RxMap<String, double> memberPaidAmounts = <String, double>{}.obs;
  final RxMap<String, int> memberSplitCounts = <String, int>{}.obs;
  final RxMap<String, double> memberNetBalances = <String, double>{}.obs;
  final RxSet<String> expandedMembers = <String>{}.obs;

  void toggleMemberExpanded(String name) {
    if (expandedMembers.contains(name)) {
      expandedMembers.remove(name);
    } else {
      expandedMembers.add(name);
    }
  }

  static const List<Color> chartPalette = [
    Color(0xFF3B82F6), // Vibrant Blue
    Color(0xFF10B981), // Emerald Green
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFEC4899), // Hot Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFF84CC16), // Lime Green
    Color(0xFF14B8A6), // Teal
    // Additional colors
    Color(0xFFA855F7), // Violet
    Color(0xFF0EA5E9), // Ocean Blue
    Color(0xFF22C55E), // Green
    Color(0xFFE11D48), // Rose
    Color(0xFF7C3AED), // Deep Violet
    Color(0xFF0891B2), // Dark Cyan
    Color(0xFF65A30D), // Olive Green
    Color(0xFFDB2777), // Deep Pink
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF9333EA), // Bright Purple
    Color(0xFFDC2626), // Crimson
    Color(0xFF059669), // Deep Emerald
    Color(0xFF0284C7), // Deep Sky
    Color(0xFFBE123C), // Ruby
    Color(0xFF4F46E5), // Deep Indigo
    Color(0xFFEA580C), // Burnt Orange
    Color(0xFF16A34A), // Forest Green
  ];

  @override
  void onInit() {
    super.onInit();
    loadGroups();
  }

  /// Loads available groups and selects the first group by default.
  Future<void> loadGroups() async {
    isLoading.value = true;
    try {
      if (Get.isRegistered<GroupController>()) {
        final gc = Get.find<GroupController>();
        await gc.loadGroups();
        groups.value = gc.groups;
      } else {
        final db = DatabaseHelper.instance;
        final groupsData = await db.getAll(table: DBConstants.groupsTable);
        groups.value = groupsData.map((e) => GroupModel.fromMap(e)).toList();
      }

      if (groups.isNotEmpty) {
        // Select first group if none is selected
        if (selectedGroup.value == null ||
            !groups.any((g) => g.id == selectedGroup.value?.id)) {
          selectGroup(groups.first);
        } else {
          await loadGroupReport(selectedGroup.value!);
        }
      } else {
        selectedGroup.value = null;
        _resetMetrics();
      }
    } catch (e) {
      debugPrint("Error loading groups in ReportController: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Selects a group and loads its expense report data.
  Future<void> selectGroup(GroupModel group) async {
    selectedGroup.value = group;
    await loadGroupReport(group);
  }

  /// Calculates total expenses, per-member expense shares, and chart colors for selected group.
  Future<void> loadGroupReport(GroupModel group) async {
    if (group.id == null) return;
    isLoading.value = true;
    expandedMembers.clear();
    try {
      final db = DatabaseHelper.instance;

      // 1. Fetch Group Members
      final membersData = await db.getWhere(
        table: DBConstants.groupMembersTable,
        where: "${DBConstants.memberGroupId} = ?",
        args: [group.id],
        orderBy: "${DBConstants.id} ASC",
      );
      final currentMembers = membersData
          .map((e) => GroupMemberModel.fromMap(e))
          .toList();
      members.value = currentMembers;

      // 2. Fetch Group Messages
      final messagesData = await db.getWhere(
        table: DBConstants.groupMessagesTable,
        where: "${DBConstants.msgGroupId} = ?",
        args: [group.id],
        orderBy: "${DBConstants.id} ASC",
      );
      final messages = messagesData
          .map((e) => GroupMessageModel.fromMap(e))
          .toList();

      // 3. Process Active Expense Requests & Split Allocations
      double groupTotal = 0.0;
      int expenseCount = 0;
      final Map<String, double> tempExpenses = {};

      final Map<String, double> tempPending = {};
      final Map<String, double> tempNetBalances = {};
      final Map<String, double> tempPaid = {};
      final Map<String, int> tempSplitCounts = {};

      for (var m in currentMembers) {
        tempExpenses[m.name] = 0.0;
        tempPending[m.name] = 0.0;
        tempNetBalances[m.name] = 0.0;
        tempPaid[m.name] = 0.0;
        tempSplitCounts[m.name] = 0;
      }

      for (var msg in messages) {
        if (!msg.isExpense) continue;
        final meta = ExpenseMetadataModel.parse(msg, currentMembers);
        if (meta.isClosed) continue;

        groupTotal += msg.amount;
        expenseCount++;
        final payerName = meta.paidByName;

        meta.splits.forEach((memberName, share) {
          tempExpenses[memberName] = (tempExpenses[memberName] ?? 0.0) + share;
          tempSplitCounts[memberName] = (tempSplitCounts[memberName] ?? 0) + 1;

          final bool isPaid =
              (memberName == payerName) ||
              meta.paidMemberNames.contains(memberName);
          if (isPaid) {
            tempPaid[memberName] = (tempPaid[memberName] ?? 0.0) + share;
          } else {
            tempNetBalances[memberName] =
                (tempNetBalances[memberName] ?? 0.0) - share;
            tempNetBalances[payerName] =
                (tempNetBalances[payerName] ?? 0.0) + share;
          }
        });
      }

      // Calculate net pending (negative net balance) for each member
      tempNetBalances.forEach((name, bal) {
        if (bal < -0.01) {
          tempPending[name] = bal.abs();
        } else {
          tempPending[name] = 0.0;
        }
      });

      totalExpense.value = groupTotal;
      totalExpenseCount.value = expenseCount;
      memberExpenses.value = tempExpenses;
      memberNetBalances.value = tempNetBalances;
      memberPendingAmounts.value = tempPending;
      memberPaidAmounts.value = tempPaid;
      memberSplitCounts.value = tempSplitCounts;

      // 4. Calculate Share Percentages & Assign Unique Chart Colors
      final Map<String, double> tempPercentages = {};
      final Map<String, Color> tempColors = {};
      int colorIndex = 0;

      tempExpenses.forEach((name, share) {
        final pct = groupTotal > 0 ? (share / groupTotal) * 100 : 0.0;
        tempPercentages[name] = pct;
        tempColors[name] = chartPalette[colorIndex % chartPalette.length];
        colorIndex++;
      });

      memberPercentages.value = tempPercentages;
      memberColors.value = tempColors;
    } catch (e) {
      debugPrint("Error calculating group report: $e");
      _resetMetrics();
    } finally {
      isLoading.value = false;
    }
  }

  void _resetMetrics() {
    totalExpense.value = 0.0;
    totalExpenseCount.value = 0;
    members.clear();
    memberExpenses.clear();
    memberPercentages.clear();
    memberColors.clear();
    memberPendingAmounts.clear();
    memberPaidAmounts.clear();
    memberSplitCounts.clear();
    memberNetBalances.clear();
    expandedMembers.clear();
  }
}
