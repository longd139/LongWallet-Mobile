class DebtModel {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final String type; // 'DEBT' (Tôi nợ), 'LOAN' (Cho vay)
  final DateTime? dueDate;
  final double? monthlyAmount; // Số tiền phải trả hàng tháng (chia tháng)
  final double paidAmount; // Số tiền đã thanh toán luỹ kế
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
    this.paidAmount = 0.0,
    this.isSettled = false,
    this.note,
    required this.createdAt,
  });

  /// Số tiền còn nợ / còn phải thu
  double get remainingAmount {
    if (isSettled) return 0.0;
    final diff = amount - paidAmount;
    return diff > 0 ? diff : 0.0;
  }

  /// Tiến độ thanh toán (0.0 -> 1.0)
  double get progress {
    if (amount <= 0) return 0.0;
    return (paidAmount / amount).clamp(0.0, 1.0);
  }

  /// Số tiền cần trả / cần thu trong kỳ tháng này
  double get monthlyDue {
    if (isSettled) return 0.0;
    final rem = remainingAmount;
    if (monthlyAmount != null && monthlyAmount! > 0) {
      return monthlyAmount! > rem ? rem : monthlyAmount!;
    }
    return rem;
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    final amountVal = (json['amount'] as num).toDouble();
    final paidVal = json['paid_amount'] != null
        ? (json['paid_amount'] as num).toDouble()
        : 0.0;
    final isSettledVal = json['is_settled'] as bool? ?? false;

    return DebtModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personName: json['person_name'] as String,
      amount: amountVal,
      type: json['type'] as String,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      monthlyAmount: json['monthly_amount'] != null
          ? (json['monthly_amount'] as num).toDouble()
          : null,
      paidAmount: paidVal,
      isSettled: isSettledVal || (paidVal >= amountVal && amountVal > 0),
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
      'paid_amount': paidAmount,
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
    double? paidAmount,
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
      paidAmount: paidAmount ?? this.paidAmount,
      isSettled: isSettled ?? this.isSettled,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
