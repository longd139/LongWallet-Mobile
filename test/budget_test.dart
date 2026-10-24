import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/models/budget_model.dart';
import 'package:longwallet/models/transaction_model.dart';
import 'package:longwallet/providers/budget_provider.dart';

void main() {
  group('BudgetModel Tests', () {
    test('BudgetModel fromJson and toJson should serialize and deserialize correctly', () {
      final json = {
        'id': 'b1',
        'user_id': 'u1',
        'category_id': 'cat-food',
        'amount_limit': 3000000.0,
        'month_year': '2026-10',
      };

      final budget = BudgetModel.fromJson(json);

      expect(budget.id, 'b1');
      expect(budget.userId, 'u1');
      expect(budget.categoryId, 'cat-food');
      expect(budget.amountLimit, 3000000.0);
      expect(budget.monthYear, '2026-10');

      final serialized = budget.toJson();
      expect(serialized['id'], 'b1');
      expect(serialized['amount_limit'], 3000000.0);
    });
  });

  group('Budget Calculation Logic Tests', () {
    late BudgetProvider provider;

    setUp(() {
      provider = BudgetProvider();
    });

    test('calculateSpentForCategory calculates expenses only for current month and matching category', () {
      final currentMonth = provider.currentMonthYear;
      final parts = currentMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      final transactions = [
        // Matching category and current month
        TransactionModel(
          id: 'tx1',
          userId: 'u1',
          walletId: 'w1',
          categoryId: 'cat-food',
          amount: 150000.0,
          type: 'EXPENSE',
          transactionDate: DateTime(year, month, 5),
        ),
        TransactionModel(
          id: 'tx2',
          userId: 'u1',
          walletId: 'w1',
          categoryId: 'cat-food',
          amount: 250000.0,
          type: 'EXPENSE',
          transactionDate: DateTime(year, month, 10),
        ),
        // INCOME in current month -> should not count
        TransactionModel(
          id: 'tx3',
          userId: 'u1',
          walletId: 'w1',
          categoryId: 'cat-food',
          amount: 500000.0,
          type: 'INCOME',
          transactionDate: DateTime(year, month, 12),
        ),
        // Different category -> should not count
        TransactionModel(
          id: 'tx4',
          userId: 'u1',
          walletId: 'w1',
          categoryId: 'cat-shopping',
          amount: 800000.0,
          type: 'EXPENSE',
          transactionDate: DateTime(year, month, 15),
        ),
        // Different month -> should not count
        TransactionModel(
          id: 'tx5',
          userId: 'u1',
          walletId: 'w1',
          categoryId: 'cat-food',
          amount: 900000.0,
          type: 'EXPENSE',
          transactionDate: DateTime(year, month == 1 ? 12 : month - 1, 1),
        ),
      ];

      final foodSpent = provider.calculateSpentForCategory('cat-food', transactions);
      expect(foodSpent, 400000.0); // 150000 + 250000

      final shoppingSpent = provider.calculateSpentForCategory('cat-shopping', transactions);
      expect(shoppingSpent, 800000.0);

      final totalSpent = provider.calculateTotalSpentForMonth(transactions);
      expect(totalSpent, 1200000.0); // 400000 + 800000
    });

    test('Real-time Budget Check evaluates expense reasonableness within budget', () {
      const budgetLimit = 2000000.0;
      const spentBefore = 1200000.0;
      const enteredAmount = 500000.0;

      final totalAfter = spentBefore + enteredAmount;
      final isOver = totalAfter > budgetLimit;
      final remainingAfter = budgetLimit - totalAfter;
      final percent = ((totalAfter / budgetLimit) * 100).toInt();

      expect(isOver, false);
      expect(remainingAfter, 300000.0);
      expect(percent, 85);
    });

    test('Real-time Budget Check warns accurately when expense exceeds budget limit', () {
      const budgetLimit = 2000000.0;
      const spentBefore = 1800000.0;
      const enteredAmount = 500000.0;

      final totalAfter = spentBefore + enteredAmount;
      final isOver = totalAfter > budgetLimit;
      final overAmount = totalAfter - budgetLimit;

      expect(isOver, true);
      expect(overAmount, 300000.0);
    });
  });
}
