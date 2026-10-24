class DebtModel {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final String type; // 'DEBT' (Tôi nợ), 'LOAN' (Cho vay)
  final DateTime? dueDate;
  final double? monthlyAmount; // Số tiền phải trả hàng tháng (chia tháng)
  final bool isSettled;
  final String? note;
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.type,
    this.dueDate,
    this.monthlyAmount,
    this.isSettled = false,
    this.note,
    required this.createdAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personName: json['person_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      monthlyAmount: json['monthly_amount'] != null
          ? (json['monthly_amount'] as num).toDouble()
          : null,
      isSettled: json['is_settled'] as bool? ?? false,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'person_name': personName,
      'amount': amount,
      'type': type,
      'due_date': dueDate?.toIso8601String(),
      'monthly_amount': monthlyAmount,
      'is_settled': isSettled,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DebtModel copyWith({
    String? id,
    String? userId,
    String? personName,
    double? amount,
    String? type,
    DateTime? dueDate,
    double? monthlyAmount,
    bool? isSettled,
    String? note,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      isSettled: isSettled ?? this.isSettled,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
