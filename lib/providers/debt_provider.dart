import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../core/services/supabase_service.dart';

class DebtProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<DebtModel> _debts = [];
  bool _isLoading = false;

  List<DebtModel> get debts => _debts;
  bool get isLoading => _isLoading;

  /// Tổng số tiền mình đang nợ người khác (chưa trả)
  double get totalDebt => _debts
      .where((d) => d.type == 'DEBT' && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.amount);

  /// Tổng số tiền người khác đang nợ mình (cho vay chưa thu hồi)
  double get totalLoan => _debts
      .where((d) => d.type == 'LOAN' && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.amount);

  List<DebtModel> get myDebts => _debts.where((d) => d.type == 'DEBT').toList();
  List<DebtModel> get myLoans => _debts.where((d) => d.type == 'LOAN').toList();

  Future<void> fetchDebts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _debts = await _supabaseService.getDebts();
    } catch (e) {
      print('Error fetching debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt({
    required String personName,
    required double amount,
    required String type,
    DateTime? dueDate,
    String? note,
  }) async {
    final newDebt = await _supabaseService.createDebt(
      personName: personName,
      amount: amount,
      type: type,
      dueDate: dueDate,
      note: note,
    );
    _debts.insert(0, newDebt);
    notifyListeners();
  }

  Future<void> toggleSettle(DebtModel debt) async {
    final newStatus = !debt.isSettled;
    await _supabaseService.updateDebtSettled(debt.id, newStatus);
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = _debts[idx].copyWith(isSettled: newStatus);
      notifyListeners();
    }
  }

  Future<void> deleteDebt(String id) async {
    await _supabaseService.deleteDebt(id);
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}
