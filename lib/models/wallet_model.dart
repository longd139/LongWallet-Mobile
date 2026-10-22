class WalletModel {
  final String id;
  final String userId;
  final String name;
  final String? bankCode;
  final String? accountNumber;
  final String? packageName;
  final double currentBalance;
  final String icon;
  final String color;
  final bool isArchived;

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    this.bankCode,
    this.accountNumber,
    this.packageName,
    required this.currentBalance,
    required this.icon,
    required this.color,
    this.isArchived = false,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      bankCode: json['bank_code'] as String?,
      accountNumber: json['account_number'] as String?,
      packageName: json['package_name'] as String?,
      currentBalance: (json['current_balance'] as num).toDouble(),
      icon: json['icon'] as String? ?? 'wallet',
      color: json['color'] as String? ?? '#10B981',
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'package_name': packageName,
      'current_balance': currentBalance,
      'icon': icon,
      'color': color,
      'is_archived': isArchived,
    };
  }
}
