class TransactionModel {
  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final double amount;
  final String type; // INCOME, EXPENSE, TRANSFER
  final DateTime transactionDate;
  final String? note;
  final String? receiptUrl;
  final bool isAutoDetected;
  final String? rawMessage;
  final String? rawHash;
  final String status; // CONFIRMED, PENDING, REJECTED

  TransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    required this.amount,
    required this.type,
    required this.transactionDate,
    this.note,
    this.receiptUrl,
    this.isAutoDetected = false,
    this.rawMessage,
    this.rawHash,
    this.status = 'CONFIRMED',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      note: json['note'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      isAutoDetected: json['is_auto_detected'] as bool? ?? false,
      rawMessage: json['raw_message'] as String?,
      rawHash: json['raw_hash'] as String?,
      status: json['status'] as String? ?? 'CONFIRMED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'transaction_date': transactionDate.toIso8601String(),
      'note': note,
      'receipt_url': receiptUrl,
      'is_auto_detected': isAutoDetected,
      'raw_message': rawMessage,
      'raw_hash': rawHash,
      'status': status,
    };
  }
}
