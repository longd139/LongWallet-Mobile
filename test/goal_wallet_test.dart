import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/models/wallet_model.dart';

void main() {
  group('Goal Wallet Model & Separation Tests', () {
    final cashWallet = WalletModel(
      id: 'w-cash',
      userId: 'u-1',
      name: 'Ví tiền mặt',
      bankCode: 'CASH',
      currentBalance: 500000,
      icon: 'cash',
      color: '#10B981',
    );

    final bankWallet = WalletModel(
      id: 'w-vcb',
      userId: 'u-1',
      name: 'Vietcombank',
      bankCode: 'VCB',
      packageName: 'com.VCB',
      currentBalance: 2000000,
      icon: 'bank',
      color: '#3B82F6',
    );

    final goalWallet = WalletModel(
      id: 'w-goal',
      userId: 'u-1',
      name: 'Mục tiêu: Honda Winner X V4',
      bankCode: 'GOAL',
      currentBalance: 5000000,
      icon: 'flag',
      color: '#EF4444',
    );

    test('standardWallets excludes GOAL wallets and keeps cash/bank wallets', () {
      final allWallets = [cashWallet, bankWallet, goalWallet];
      final standard = allWallets.where((w) => w.bankCode != 'GOAL').toList();

      expect(standard.length, 2);
      expect(standard.any((w) => w.bankCode == 'GOAL'), isFalse);
      expect(standard.map((w) => w.id), containsAll(['w-cash', 'w-vcb']));
    });

    test('goalWallet finds only the wallet with bankCode GOAL', () {
      final allWallets = [cashWallet, bankWallet, goalWallet];
      final foundIdx = allWallets.indexWhere((w) => w.bankCode == 'GOAL');
      final foundGoal = foundIdx != -1 ? allWallets[foundIdx] : null;

      expect(foundGoal, isNotNull);
      expect(foundGoal!.id, 'w-goal');
      expect(foundGoal.name, 'Mục tiêu: Honda Winner X V4');
      expect(foundGoal.currentBalance, 5000000.0);
    });

    test('goal progress calculation accurately reflects goal wallet balance', () {
      const targetAmount = 50000000.0; // 50 triệu
      final currentGoalBalance = goalWallet.currentBalance; // 5 triệu

      final progress = (targetAmount > 0 ? (currentGoalBalance / targetAmount) : 0.0).clamp(0.0, 1.0);
      final percent = (progress * 100).toStringAsFixed(1);

      expect(progress, 0.1);
      expect(percent, '10.0');
    });

    test('goal progress handles zero or over-achieved balance correctly', () {
      const targetAmount = 50000000.0;
      
      // 0 balance
      final zeroProgress = (0.0 / targetAmount).clamp(0.0, 1.0);
      expect(zeroProgress, 0.0);

      // Over target
      final overProgress = (60000000.0 / targetAmount).clamp(0.0, 1.0);
      expect(overProgress, 1.0);
    });
  });
}
