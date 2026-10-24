import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../core/services/supabase_service.dart';

class DebtProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<DebtModel> _debts = [];
  bool _isLoading = false;

  List<DebtModel> get debts => _debts;
  bool get isLoading => _isLoading;

  /// Tổng dư nợ còn lại mình đang nợ người khác (chưa trả)
  double get totalDebt => _debts
      .where((d) => d.type == 'DEBT' && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.remainingAmount);

  /// Số tiền nợ cần phải trả trong tháng này (chia tháng hoặc trả 1 lần)
  double get totalMonthlyDebtDue => _debts
      .where((d) => d.type == 'DEBT' && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.monthlyDue);

  /// Tổng số tiền người khác đang còn nợ mình (cho vay chưa thu hồi)
  double get totalLoan => _debts
      .where((d) => d.type == 'LOAN' && !d.isSettled)
      .fold(0.0, (sum, d) => sum + d.remainingAmount);

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
    double? monthlyAmount,
    String? note,
  }) async {
    final newDebt = await _supabaseService.createDebt(
      personName: personName,
      amount: amount,
      type: type,
      dueDate: dueDate,
      monthlyAmount: monthlyAmount,
      note: note,
    );
    _debts.insert(0, newDebt);
    notifyListeners();
  }

  /// Ghi nhận thanh toán 1 phần hoặc nhiều tháng
  Future<void> recordPayment(DebtModel debt, double paymentAmount) async {
    final newPaid = debt.paidAmount + paymentAmount;
    final isFullySettled = newPaid >= debt.amount;
    await _supabaseService.recordDebtPayment(debt.id, newPaid, isFullySettled);
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = _debts[idx].copyWith(
        paidAmount: newPaid,
        isSettled: isFullySettled,
      );
      notifyListeners();
    }
  }

  /// Tất toán toàn bộ hoặc hoàn tác trạng thái
  Future<void> toggleSettle(DebtModel debt) async {
    final newStatus = !debt.isSettled;
    final newPaid = newStatus ? debt.amount : 0.0;
    await _supabaseService.recordDebtPayment(debt.id, newPaid, newStatus);
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = _debts[idx].copyWith(
        paidAmount: newPaid,
        isSettled: newStatus,
      );
      notifyListeners();
    }
  }

  Future<void> deleteDebt(String id) async {
    await _supabaseService.deleteDebt(id);
    _debts.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}
