class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final double amountLimit;
  final String monthYear; // Format: YYYY-MM

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amountLimit,
    required this.monthYear,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amountLimit: (json['amount_limit'] as num).toDouble(),
      monthYear: json['month_year'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount_limit': amountLimit,
      'month_year': monthYear,
    };
  }
}
