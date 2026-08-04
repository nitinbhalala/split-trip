class GroupMessageModel {
  final int? id;
  final int groupId;
  final String senderName;
  final String messageText;
  final double amount;
  final bool isExpense;
  final String? createdAt;

  GroupMessageModel({
    this.id,
    required this.groupId,
    required this.senderName,
    required this.messageText,
    this.amount = 0.0,
    this.isExpense = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'group_id': groupId,
      'sender_name': senderName,
      'message_text': messageText,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
      id: map['id'] as int?,
      groupId: (map['group_id'] as int?) ?? 0,
      senderName: (map['sender_name'] as String?) ?? "Me",
      messageText: (map['message_text'] as String?) ?? "",
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isExpense: (map['is_expense'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }
}
