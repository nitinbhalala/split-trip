import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';

class AddSplitExpenseController extends GetxController {
  final GroupDetailController groupDetailController;

  AddSplitExpenseController({required this.groupDetailController});

  final RxInt step =
      1.obs; // 1: Enter Amount, 2: Select Payer, 3: Split Allocation
  final RxString amountStr = "0".obs;
  final RxString description = "".obs;
  final TextEditingController descController = TextEditingController();
  final FocusNode descFocusNode = FocusNode();
  bool isEditingDescription = false;

  // Selected Payer Member ID
  final RxnInt selectedPayerId = RxnInt();

  // Split Modes: 0 = Split Evenly (👤|👤), 1 = Amounts (123), 2 = Shares (⊕), 3 = Percentages (%)
  final RxInt splitMode = 0.obs;

  // Controllers & Selection per member
  final Map<int, TextEditingController> customControllers = {};
  final RxSet<int> selectedMemberIds = <int>{}.obs;

  // Track members whose percentages have been explicitly typed by user
  final Set<int> editedMemberIds = {};

  @override
  void onInit() {
    super.onInit();
    descFocusNode.addListener(() {
      if (descFocusNode.hasFocus) {
        isEditingDescription = true;
      }
    });

    // Select all members by default
    for (var m in groupDetailController.members) {
      if (m.id != null) {
        selectedMemberIds.add(m.id!);
        customControllers[m.id!] = TextEditingController();
      }
    }

    // Default selected payer to first member
    if (groupDetailController.members.isNotEmpty) {
      selectedPayerId.value = groupDetailController.members.first.id;
    }
  }

  @override
  void onClose() {
    descController.dispose();
    descFocusNode.dispose();
    for (var c in customControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  String get paidByMemberName {
    final member = groupDetailController.members.firstWhereOrNull(
      (m) => m.id == selectedPayerId.value,
    );
    return member?.name ?? "Me";
  }

  TextEditingController getController(int memberId, {String defaultText = ""}) {
    if (!customControllers.containsKey(memberId)) {
      customControllers[memberId] = TextEditingController(text: defaultText);
    }
    return customControllers[memberId]!;
  }

  void onKeyPress(String val) {
    if (val == "DEL") {
      if (amountStr.value.length > 1) {
        amountStr.value = amountStr.value.substring(
          0,
          amountStr.value.length - 1,
        );
      } else {
        amountStr.value = "0";
      }
    } else if (val == ".") {
      if (!amountStr.value.contains(".")) {
        amountStr.value = "${amountStr.value}.";
      }
    } else {
      if (amountStr.value == "0") {
        amountStr.value = val;
      } else if (amountStr.value.length < 9) {
        amountStr.value = "${amountStr.value}$val";
      }
    }
  }

  void notifyUpdate() {
    selectedMemberIds.refresh();
    update();
  }

  void toggleMemberSelection(int memberId, bool? val) {
    if (val == true) {
      selectedMemberIds.add(memberId);
      if (splitMode.value == 1) {
        getController(memberId).text = evenShare.toStringAsFixed(2);
      } else if (splitMode.value == 2) {
        getController(memberId).text = "1";
      }
    } else {
      selectedMemberIds.remove(memberId);
      editedMemberIds.remove(memberId);
    }

    if (splitMode.value == 3) {
      initializePercentagesIfNeeded();
    }

    selectedMemberIds.refresh();
    update();
  }

  void setSplitMode(int mode) {
    splitMode.value = mode;
    editedMemberIds.clear();

    if (selectedMemberIds.isNotEmpty) {
      if (mode == 1) {
        // Amounts mode: set each selected member controller to even share amount
        final share = evenShare;
        for (final id in selectedMemberIds) {
          getController(id).text = share.toStringAsFixed(2);
        }
      } else if (mode == 2) {
        // Shares mode: set each selected member controller to 1 share
        for (final id in selectedMemberIds) {
          getController(id).text = "1";
        }
      } else if (mode == 3) {
        // Percentages mode: set each selected member controller to equal percentage
        initializePercentagesIfNeeded();
      }
    }

    notifyUpdate();
  }

  /// Initialize / reset percentages evenly among selected members
  void initializePercentagesIfNeeded() {
    editedMemberIds.clear();
    if (selectedMemberIds.isEmpty) return;
    final splitPct = 100.0 / selectedMemberIds.length;
    for (final id in selectedMemberIds) {
      getController(id, defaultText: "0.00").text = splitPct.toStringAsFixed(2);
    }
  }

  /// Handle percentage typing in Mode 3 with Google Pay style auto-balancing (no snackbar while typing)
  void onMemberPercentageChanged(int memberId, String value) {
    editedMemberIds.add(memberId);

    // Calculate sum of percentages of edited selected members
    double editedSum = 0.0;
    for (final id in selectedMemberIds) {
      if (editedMemberIds.contains(id)) {
        final ctrl = customControllers[id];
        editedSum += _parseValue(ctrl?.text);
      }
    }

    // Auto-balance unedited selected members
    final uneditedMembers = selectedMemberIds
        .where((id) => !editedMemberIds.contains(id))
        .toList();

    if (uneditedMembers.isNotEmpty) {
      final remainingPct = 100.0 - editedSum;
      if (remainingPct > 0) {
        final splitPct = remainingPct / uneditedMembers.length;
        for (final uId in uneditedMembers) {
          getController(uId, defaultText: "0.00").text = splitPct
              .toStringAsFixed(2);
        }
      } else {
        for (final uId in uneditedMembers) {
          getController(uId, defaultText: "0.00").text = "0.00";
        }
      }
    }

    notifyUpdate();
  }

  /// Handle custom amount typing in Mode 1 (no snackbar while typing)
  void onMemberAmountChanged(int memberId, String value) {
    notifyUpdate();
  }

  final RxString errorMessage = "".obs;

  void showPopupError(String msg) {
    errorMessage.value = msg;
    if (msg.isNotEmpty) {
      AppSnackbar.error(message: msg);
    }
  }

  void clearError() {
    errorMessage.value = "";
  }

  /// Trigger popup toast ONLY when user finishes typing / closes keyboard / taps Done
  void validateAndShowSnackbarIfNeeded() {
    if (splitMode.value == 1) {
      final totalEntered = calculateTotalEnteredAmount();
      if (totalEntered > totalAmount + 0.01) {
        final extraAmount = totalEntered - totalAmount;
        showPopupError(
          "Exceeded total by ${AppHelper.formatCurrency(extraAmount)}",
        );
      } else if ((totalEntered - totalAmount).abs() > 0.01) {
        final remaining = totalAmount - totalEntered;
        if (remaining > 0) {
          showPopupError(
            "Entered amount is short by ${AppHelper.formatCurrency(remaining)}.",
          );
        } else {
          clearError();
        }
      } else {
        clearError();
      }
    } else if (splitMode.value == 3) {
      final totalPct = calculateTotalPercentage();
      if (totalPct > 100.001) {
        final extraPct = totalPct - 100.0;
        showPopupError(
          "Percentages must add up to 100%. Reduce by ${extraPct.toStringAsFixed(2)}% to continue.",
        );
      } else if ((totalPct - 100.0).abs() > 0.05) {
        final remainingPct = 100.0 - totalPct;
        if (remainingPct > 0) {
          showPopupError(
            "Percentages must add up to 100%. Add ${remainingPct.toStringAsFixed(2)}% to continue.",
          );
        } else {
          clearError();
        }
      } else {
        clearError();
      }
    } else {
      clearError();
    }
  }

  double _parseValue(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get totalAmount => _parseValue(amountStr.value);

  double get evenShare {
    final count = selectedMemberIds.isNotEmpty ? selectedMemberIds.length : 1;
    return totalAmount / count;
  }

  double calculateTotalEnteredAmount() {
    double total = 0.0;
    for (final id in selectedMemberIds) {
      final ctrl = customControllers[id];
      total += _parseValue(ctrl?.text);
    }
    return total;
  }

  double calculateTotalPercentage() {
    double total = 0.0;
    for (final id in selectedMemberIds) {
      final ctrl = customControllers[id];
      total += _parseValue(ctrl?.text);
    }
    return total;
  }

  double calculateDisplayShare(int memberId) {
    final isChecked = selectedMemberIds.contains(memberId);
    if (!isChecked) return 0.0;

    if (splitMode.value == 0) {
      return evenShare;
    } else if (splitMode.value == 1) {
      final ctrl = customControllers[memberId];
      return _parseValue(ctrl?.text);
    } else if (splitMode.value == 2) {
      double totalShares = 0;
      for (final id in selectedMemberIds) {
        final s = _parseValue(getController(id, defaultText: "1").text);
        totalShares += (s > 0 ? s : 1.0);
      }
      final myShare = _parseValue(
        getController(memberId, defaultText: "1").text,
      );
      return (totalShares > 0)
          ? (totalAmount * (myShare > 0 ? myShare : 1.0) / totalShares)
          : 0.0;
    } else if (splitMode.value == 3) {
      final myPercent = _parseValue(
        getController(memberId, defaultText: "0.00").text,
      );
      return (totalAmount * (myPercent / 100));
    }
    return 0.0;
  }

  /// Validation rule for enabling "Send Request" button
  bool get isValid {
    // Case 1: At least 1 member must be selected
    if (selectedMemberIds.isEmpty) return false;
    if (totalAmount <= 0) return false;

    if (splitMode.value == 0) {
      return true;
    } else if (splitMode.value == 1) {
      // Amount mode: Sum of entered amounts must equal totalAmount
      final totalEntered = calculateTotalEnteredAmount();
      return (totalEntered - totalAmount).abs() < 0.1;
    } else if (splitMode.value == 2) {
      // Shares mode: Total shares must be > 0
      double totalShares = 0;
      for (final id in selectedMemberIds) {
        final s = _parseValue(getController(id, defaultText: "1").text);
        totalShares += (s > 0 ? s : 1.0);
      }
      return totalShares > 0;
    } else if (splitMode.value == 3) {
      // Percentages mode: Total percentage must equal 100%
      final totalPct = calculateTotalPercentage();
      return (totalPct - 100.0).abs() < 0.1;
    }
    return true;
  }

  String getSplitModeTitle() {
    switch (splitMode.value) {
      case 0:
        return "Split evenly";
      case 1:
        return "Split by unequal amounts";
      case 2:
        return "Split by shares";
      case 3:
        return "Split by percentages";
      default:
        return "Split evenly";
    }
  }

  Future<void> submitExpense() async {
    if (!isValid) return;

    final descText = description.value.trim();
    final titleStr = descText;
    final payer = paidByMemberName;

    final Map<String, double> splitsMap = {};
    for (final id in selectedMemberIds) {
      final member = groupDetailController.members.firstWhereOrNull(
        (m) => m.id == id,
      );
      final name = member?.name ?? "Member #$id";
      splitsMap[name] = calculateDisplayShare(id);
    }

    final metadata = ExpenseMetadataModel(
      title: titleStr,
      paidByName: payer,
      paidById: selectedPayerId.value,
      splits: splitsMap,
      paidMemberNames: [payer],
    );

    final jsonPayload = jsonEncode(metadata.toMap());

    final success = await groupDetailController.addSplitExpenseRequest(
      title: jsonPayload,
      amount: totalAmount,
      senderName: payer,
    );

    if (success) {
      Get.back();
      AppSnackbar.success(message: "Split request sent to group!");
    } else {
      AppSnackbar.error(message: "Failed to send split request.");
    }
  }
}
