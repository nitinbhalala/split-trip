class GroupMemberModel {
  final int? id;
  final int groupId;
  final String name;
  final String? phone;
  final String? createdAt;

  GroupMemberModel({
    this.id,
    required this.groupId,
    required this.name,
    this.phone,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'group_id': groupId,
      'name': name,
      'phone': phone,
      'created_at': createdAt,
    };
  }

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id'] as int?,
      groupId: (map['group_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? "",
      phone: map['phone'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}
