import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_model.dart';
import '../../models/debt_model.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  String? get currentUserId => client.auth.currentUser?.id;

  // ===================== WALLETS =====================
  Future<List<WalletModel>> getWallets() async {
    final response = await client
        .from('wallets')
        .select()
        .eq('is_archived', false)
        .order('created_at', ascending: true);

    return (response as List).map((e) => WalletModel.fromJson(e)).toList();
  }

  Future<WalletModel> createWallet({
    required String name,
    String? bankCode,
    String? accountNumber,
    String? packageName,
    double initialBalance = 0,
    String icon = 'wallet',
    String color = '#10B981',
  }) async {
    final response = await client.from('wallets').insert({
      'user_id': currentUserId,
      'name': name,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'package_name': packageName,
      'current_balance': initialBalance,
      'icon': icon,
      'color': color,
    }).select().single();

    return WalletModel.fromJson(response);
  }

  // ===================== TRANSACTIONS =====================
  Future<List<TransactionModel>> getTransactions({int limit = 50}) async {
    final response = await client
        .from('transactions')
        .select()
        .order('transaction_date', ascending: false)
        .limit(limit);

    return (response as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final response = await client
        .from('transactions')
        .select()
        .eq('status', 'PENDING')
        .order('created_at', ascending: false);

    return (response as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel> createTransaction({
    required String walletId,
    String? categoryId,
    required double amount,
    required String type,
    DateTime? date,
    String? note,
    bool isAutoDetected = false,
    String? rawMessage,
    String? rawHash,
    String status = 'CONFIRMED',
  }) async {
    final response = await client.from('transactions').insert({
      'user_id': currentUserId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'transaction_date': (date ?? DateTime.now()).toIso8601String(),
      'note': note,
      'is_auto_detected': isAutoDetected,
      'raw_message': rawMessage,
      'raw_hash': rawHash,
      'status': status,
    }).select().single();

    return TransactionModel.fromJson(response);
  }

  Future<void> updateTransactionStatus(
    String id,
    String newStatus, {
    String? note,
    String? categoryId,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (note != null && note.isNotEmpty) updateData['note'] = note;
    if (categoryId != null && categoryId.isNotEmpty) updateData['category_id'] = categoryId;

    await client
        .from('transactions')
        .update(updateData)
        .eq('id', id);
  }

  // ===================== CATEGORIES =====================
  Future<List<CategoryModel>> getCategories() async {
    final response = await client
        .from('categories')
        .select()
        .order('created_at', ascending: true);

    return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    final response = await client
        .from('categories')
        .insert({
          'user_id': currentUserId,
          'name': name,
          'type': type,
          'icon': icon,
          'color': color,
          'is_default': false,
        })
        .select()
        .single();

    return CategoryModel.fromJson(response);
  }

  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    final response = await client
        .from('categories')
        .update({
          'name': name,
          'type': type,
          'icon': icon,
          'color': color,
        })
        .eq('id', id)
        .select()
        .single();

    return CategoryModel.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }

  // ===================== BUDGETS =====================
  Future<List<BudgetModel>> getBudgets(String monthYear) async {
    final response = await client
        .from('budgets')
        .select()
        .eq('month_year', monthYear);

    return (response as List).map((e) => BudgetModel.fromJson(e)).toList();
  }

  Future<BudgetModel> setBudget({
    required String categoryId,
    required double amountLimit,
    required String monthYear,
  }) async {
    final response = await client.from('budgets').upsert({
      'user_id': currentUserId,
      'category_id': categoryId,
      'amount_limit': amountLimit,
      'month_year': monthYear,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,category_id,month_year').select().single();

    return BudgetModel.fromJson(response);
  }

  Future<void> deleteBudget(String id) async {
    await client.from('budgets').delete().eq('id', id);
  }

  // ===================== DEBTS =====================
  Future<List<DebtModel>> getDebts() async {
    final response = await client
        .from('debts')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => DebtModel.fromJson(e)).toList();
  }

  Future<DebtModel> createDebt({
    required String personName,
    required double amount,
    required String type,
    DateTime? dueDate,
    double? monthlyAmount,
    String? note,
  }) async {
    final response = await client.from('debts').insert({
      'user_id': currentUserId,
      'person_name': personName,
      'amount': amount,
      'type': type,
      'due_date': dueDate?.toIso8601String(),
      'monthly_amount': monthlyAmount,
      'note': note,
      'is_settled': false,
    }).select().single();

    return DebtModel.fromJson(response);
  }

  Future<void> recordDebtPayment(String id, double newPaidAmount, bool isSettled) async {
    await client.from('debts').update({
      'paid_amount': newPaidAmount,
      'is_settled': isSettled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> updateDebtSettled(String id, bool isSettled) async {
    await client.from('debts').update({
      'is_settled': isSettled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteDebt(String id) async {
    await client.from('debts').delete().eq('id', id);
  }
}
