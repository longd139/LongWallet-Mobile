import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/services/supabase_service.dart';
import '../core/services/notification_service.dart';

class TransactionProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _pendingTransactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get pendingTransactions => _pendingTransactions;
  bool get isLoading => _isLoading;

  int get pendingCount => _pendingTransactions.length;

  void _syncOngoingNotification() {
    if (_pendingTransactions.isEmpty) {
      _notificationService.cancelOngoingNotification();
      return;
    }

    final incomeCount = _pendingTransactions.where((tx) => tx.type == 'INCOME').length;
    final expenseCount = _pendingTransactions.where((tx) => tx.type == 'EXPENSE').length;

    String message;
    if (incomeCount > 0 && expenseCount > 0) {
      message = 'Đang có $expenseCount khoản chi tiêu và $incomeCount khoản thu nhập cần làm rõ';
    } else if (incomeCount > 0) {
      message = incomeCount == 1
          ? 'Đang có 1 khoản thu nhập cần làm rõ (Tiền này từ đâu?)'
          : 'Đang có $incomeCount khoản thu nhập cần làm rõ';
    } else {
      message = expenseCount == 1
          ? 'Đang có 1 khoản chi tiêu cần làm rõ (Bạn đã chi tiêu cái gì?)'
          : 'Đang có $expenseCount khoản chi tiêu cần làm rõ';
    }

    _notificationService.updateOngoingNotification(
      title: 'LongWallet',
      message: message,
    );
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _supabaseService.getTransactions();
      _pendingTransactions = await _supabaseService.getPendingTransactions();
      _syncOngoingNotification();
    } catch (e) {
      print('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmPendingTransaction(
    String id, {
    String? note,
    String? categoryId,
  }) async {
    await _supabaseService.updateTransactionStatus(
      id,
      'CONFIRMED',
      note: note,
      categoryId: categoryId,
    );
    _pendingTransactions.removeWhere((tx) => tx.id == id);
    await fetchTransactions();
    notifyListeners();
  }

  Future<void> rejectPendingTransaction(String id) async {
    await _supabaseService.updateTransactionStatus(id, 'REJECTED');
    _pendingTransactions.removeWhere((tx) => tx.id == id);
    _syncOngoingNotification();
    notifyListeners();
  }

  Future<void> addTransaction({
    required String walletId,
    String? categoryId,
    required double amount,
    required String type,
    DateTime? date,
    String? note,
  }) async {
    await _supabaseService.createTransaction(
      walletId: walletId,
      categoryId: categoryId,
      amount: amount,
      type: type,
      date: date,
      note: note,
      status: 'CONFIRMED',
    );
    await fetchTransactions();
  }
}
