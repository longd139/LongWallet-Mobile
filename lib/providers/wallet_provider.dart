import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../core/services/supabase_service.dart';

class WalletProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<WalletModel> _wallets = [];
  bool _isLoading = false;

  List<WalletModel> get wallets => _wallets;
  bool get isLoading => _isLoading;

  double get totalBalance => _wallets.fold(0, (sum, w) => sum + w.currentBalance);

  Future<void> fetchWallets() async {
    _isLoading = true;
    notifyListeners();
    try {
      _wallets = await _supabaseService.getWallets();
    } catch (e) {
      print('Error fetching wallets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
}
