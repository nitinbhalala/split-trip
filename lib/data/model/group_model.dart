class GroupModel {
  final int? id;
  final String name;
  final String description;
  final String iconName;
  final int colorValue;
  final String? createdAt;
  final String? updatedAt;

  GroupModel({
    this.id,
    required this.name,
    this.description = "",
    this.iconName = "group_work",
    this.colorValue = 0xFF3B82F6,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_value': colorValue,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? "",
      description: (map['description'] as String?) ?? "",
      iconName: (map['icon_name'] as String?) ?? "group_work",
      colorValue: (map['color_value'] as int?) ?? 0xFF3B82F6,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
