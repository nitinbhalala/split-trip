import 'dart:convert';
import 'package:split_trip/data/model/group_member_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';

class ExpenseMetadataModel {
  final String title;
  final String paidByName;
  final int? paidById;
  final Map<String, double> splits;
  final List<String> paidMemberNames;
  final bool isClosed;

  ExpenseMetadataModel({
    required this.title,
    required this.paidByName,
    this.paidById,
    required this.splits,
    required this.paidMemberNames,
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'paid_by_name': paidByName,
      if (paidById != null) 'paid_by_id': paidById,
      'splits': splits,
      'paid_member_names': paidMemberNames,
      'is_closed': isClosed,
    };
  }

  factory ExpenseMetadataModel.parse(
    GroupMessageModel msg,
    List<GroupMemberModel> members,
  ) {
    final String defaultMemberName = members.isNotEmpty
        ? members.first.name
        : (msg.senderName.toLowerCase() != "me" ? msg.senderName : "Admin");

    try {
      if (msg.messageText.trim().startsWith('{')) {
        final Map<String, dynamic> data = jsonDecode(msg.messageText);
        final String title = data['title'] as String? ?? ""; //dharmik changeapp
        String paidByName = data['paid_by_name'] as String? ?? msg.senderName;
        if (paidByName.toLowerCase() == "me") {
          paidByName = defaultMemberName;
        }

        final int? paidById = data['paid_by_id'] as int?;

        final Map<String, dynamic> splitsRaw =
            data['splits'] as Map<String, dynamic>? ?? {};
        final Map<String, double> splits = {};
        splitsRaw.forEach((key, val) {
          final cleanKey = key.toLowerCase() == "me" ? defaultMemberName : key;
          splits[cleanKey] = (val as num).toDouble();
        });

        final List<dynamic> paidRaw =
            data['paid_member_names'] as List<dynamic>? ?? [];
        final List<String> paidMemberNames = paidRaw.map((e) {
          final s = e.toString();
          return s.toLowerCase() == "me" ? defaultMemberName : s;
        }).toList();

        // Ensure payer is in paidMemberNames
        if (!paidMemberNames.contains(paidByName)) {
          paidMemberNames.add(paidByName);
        }

        final bool isClosed = data['is_closed'] as bool? ?? false;

        return ExpenseMetadataModel(
          title: title,
          paidByName: paidByName,
          paidById: paidById,
          splits: splits,
          paidMemberNames: paidMemberNames,
          isClosed: isClosed,
        );
      }
    } catch (_) {}

    // Fallback for plain text or legacy messages
    final String payerName = msg.senderName.toLowerCase() != "me"
        ? msg.senderName
        : defaultMemberName;

    final double share = members.isNotEmpty
        ? (msg.amount / members.length)
        : msg.amount;
    final Map<String, double> defaultSplits = {};
    for (var m in members) {
      defaultSplits[m.name] = share;
    }
    if (defaultSplits.isEmpty) {
      defaultSplits[payerName] = msg.amount;
    }

    return ExpenseMetadataModel(
      title: msg.messageText.isNotEmpty ? msg.messageText : "Expense",
      paidByName: payerName,
      splits: defaultSplits,
      paidMemberNames: [payerName],
    );
  }
}
