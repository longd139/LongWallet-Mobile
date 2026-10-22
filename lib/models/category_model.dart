class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String type; // INCOME, EXPENSE
  final String icon;
  final String color;
  final bool isDefault;

  CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String? ?? 'tag',
      color: json['color'] as String? ?? '#3B82F6',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }
}
