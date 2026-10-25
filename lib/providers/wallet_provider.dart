import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../core/services/supabase_service.dart';

class WalletProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<WalletModel> _wallets = [];
  bool _isLoading = false;

  List<WalletModel> get wallets => _wallets;
  bool get isLoading => _isLoading;

  WalletModel? get goalWallet {
    final idx = _wallets.indexWhere((w) => w.bankCode == 'GOAL');
    return idx != -1 ? _wallets[idx] : null;
  }

  // Danh sách các ví khả dụng để chi tiêu/nguồn tiền (loại trừ ví mục tiêu)
  List<WalletModel> get standardWallets => _wallets.where((w) => w.bankCode != 'GOAL').toList();

  double get totalBalance => _wallets.fold(0, (sum, w) => sum + w.currentBalance);

  Future<void> fetchWallets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _supabaseService.getWallets();

      // Dọn dẹp tự động nếu có nhiều hơn 1 ví mục tiêu (GOAL)
      final goalWallets = fetched.where((w) => w.bankCode == 'GOAL').toList();
      if (goalWallets.length > 1) {
        // Ưu tiên giữ ví có số dư > 0 hoặc ví đầu tiên
        goalWallets.sort((a, b) {
          if (a.currentBalance > 0 && b.currentBalance == 0) return -1;
          if (b.currentBalance > 0 && a.currentBalance == 0) return 1;
          return a.id.compareTo(b.id);
        });

        final keepGoal = goalWallets.first;
        final duplicates = goalWallets.sublist(1);

        // Xóa bất đồng bộ các ví mục tiêu thừa trong Supabase
        for (final dup in duplicates) {
          try {
            await _supabaseService.deleteWallet(dup.id);
          } catch (err) {
            debugPrint('Lỗi dọn dẹp ví mục tiêu thừa: $err');
          }
        }

        final duplicateIds = duplicates.map((w) => w.id).toSet();
        _wallets = fetched.where((w) => !duplicateIds.contains(w.id)).toList();
      } else {
        _wallets = fetched;
      }
    } catch (e) {
      debugPrint('Error fetching wallets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      await _supabaseService.deleteWallet(walletId);
      _wallets.removeWhere((w) => w.id == walletId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting wallet: $e');
      rethrow;
    }
  }

  Future<WalletModel> ensureGoalWallet(String goalTitle) async {
    final existing = goalWallet;
    if (existing != null) {
      return existing;
    }

    // Nếu _wallets rỗng (chưa tải xong), tải từ database trước để tránh tạo trùng
    if (_wallets.isEmpty) {
      await fetchWallets();
      final afterFetch = goalWallet;
      if (afterFetch != null) {
        return afterFetch;
      }
    }

    final newWallet = await _supabaseService.createWallet(
      name: 'Mục tiêu: $goalTitle',
      bankCode: 'GOAL',
      initialBalance: 0,
      icon: 'flag',
      color: '#EF4444',
    );
    _wallets.add(newWallet);
    notifyListeners();
    return newWallet;
  }

  Future<void> transferToGoal({
    required String sourceWalletId,
    required String goalWalletId,
    required double amount,
    String? note,
  }) async {
    final cleanNote = note?.trim();
    final expenseNote = cleanNote != null && cleanNote.isNotEmpty
        ? 'Chuyển vào mục tiêu: $cleanNote'
        : 'Chuyển tiền vào mục tiêu';
    final incomeNote = cleanNote != null && cleanNote.isNotEmpty
        ? 'Tích lũy mục tiêu: $cleanNote'
        : 'Tích lũy vào mục tiêu';

    // 1. Trừ tiền ở ví nguồn
    await _supabaseService.createTransaction(
      walletId: sourceWalletId,
      amount: amount,
      type: 'EXPENSE',
      note: expenseNote,
      status: 'CONFIRMED',
    );

    // 2. Cộng tiền vào ví mục tiêu
    await _supabaseService.createTransaction(
      walletId: goalWalletId,
      amount: amount,
      type: 'INCOME',
      note: incomeNote,
      status: 'CONFIRMED',
    );

    // Đồng bộ lại danh sách ví và số dư
    await fetchWallets();
  }

  Future<void> addWallet({
    required String name,
    String? bankCode,
    String? accountNumber,
    String? packageName,
    double initialBalance = 0,
    String icon = 'wallet',
    String color = '#10B981',
  }) async {
    final newWallet = await _supabaseService.createWallet(
      name: name,
      bankCode: bankCode,
      accountNumber: accountNumber,
      packageName: packageName,
      initialBalance: initialBalance,
      icon: icon,
      color: color,
    );
    _wallets.add(newWallet);
    notifyListeners();
  }

  Future<void> updateWallet({
    required String walletId,
    required String name,
    String? bankCode,
    String? accountNumber,
    String? packageName,
    required double currentBalance,
  }) async {
    final updated = await _supabaseService.updateWallet(
      walletId: walletId,
      name: name,
      bankCode: bankCode,
      accountNumber: accountNumber,
      packageName: packageName,
      currentBalance: currentBalance,
    );
    final index = _wallets.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      _wallets[index] = updated;
      notifyListeners();
    }
  }
}
