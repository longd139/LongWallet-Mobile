import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../core/services/supabase_service.dart';

class BudgetProvider extends ChangeNotifier {
  final SupabaseService? _injectedService;

  BudgetProvider({SupabaseService? supabaseService})
      : _injectedService = supabaseService;

  SupabaseService get _supabaseService => _injectedService ?? SupabaseService();

  List<BudgetModel> _budgets = [];
  List<CategoryModel> _categories = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  List<CategoryModel> get categories => _categories;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get currentMonthYear => DateFormat('yyyy-MM').format(_selectedDate);
  String get displayMonthYear => 'Tháng ${DateFormat('MM/yyyy').format(_selectedDate)}';

  Future<void> fetchBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_categories.isEmpty) {
        _categories = await _supabaseService.getCategories();
      }
      _budgets = await _supabaseService.getBudgets(currentMonthYear);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching budgets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeMonth(int monthOffset) {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + monthOffset, 1);
    fetchBudgets();
  }

  Future<void> setBudget({
    required String categoryId,
    required double amountLimit,
  }) async {
    try {
      final updatedBudget = await _supabaseService.setBudget(
        categoryId: categoryId,
        amountLimit: amountLimit,
        monthYear: currentMonthYear,
      );

      final index = _budgets.indexWhere((b) => b.id == updatedBudget.id || (b.categoryId == categoryId && b.monthYear == currentMonthYear));
      if (index >= 0) {
        _budgets[index] = updatedBudget;
      } else {
        _budgets.add(updatedBudget);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error setting budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _supabaseService.deleteBudget(budgetId);
      _budgets.removeWhere((b) => b.id == budgetId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting budget: $e');
      rethrow;
    }
  }

  double calculateSpentForCategory(String categoryId, List<TransactionModel> transactions) {
    double spent = 0;
    for (final tx in transactions) {
      if (tx.type == 'EXPENSE' && tx.categoryId == categoryId) {
        final txMonthYear = DateFormat('yyyy-MM').format(tx.transactionDate);
        if (txMonthYear == currentMonthYear) {
          spent += tx.amount;
        }
      }
    }
    return spent;
  }

  double calculateTotalSpentForMonth(List<TransactionModel> transactions) {
    double spent = 0;
    for (final tx in transactions) {
      if (tx.type == 'EXPENSE') {
        final txMonthYear = DateFormat('yyyy-MM').format(tx.transactionDate);
        if (txMonthYear == currentMonthYear) {
          spent += tx.amount;
        }
      }
    }
    return spent;
  }

  double get totalBudgetLimit {
    return _budgets.fold(0.0, (sum, b) => sum + b.amountLimit);
  }

  CategoryModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }
}
