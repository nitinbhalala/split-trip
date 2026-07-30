class DBCategory {
  final int? id;
  final String name;
  final String iconName;
  final int colorValue; // Hex color value, e.g. 0xFFBA68C8

  DBCategory({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
    };
  }

  factory DBCategory.fromMap(Map<String, dynamic> map) {
    return DBCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      colorValue: map['color_value'] as int,
    );
  }
}
