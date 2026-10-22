import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/services/supabase_service.dart';

class TransactionProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _pendingTransactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get pendingTransactions => _pendingTransactions;
  bool get isLoading => _isLoading;

  int get pendingCount => _pendingTransactions.length;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _supabaseService.getTransactions();
      _pendingTransactions = await _supabaseService.getPendingTransactions();
    } catch (e) {
      print('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmPendingTransaction(String id) async {
    await _supabaseService.updateTransactionStatus(id, 'CONFIRMED');
    _pendingTransactions.removeWhere((tx) => tx.id == id);
    await fetchTransactions();
    notifyListeners();
  }

  Future<void> rejectPendingTransaction(String id) async {
    await _supabaseService.updateTransactionStatus(id, 'REJECTED');
    _pendingTransactions.removeWhere((tx) => tx.id == id);
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
