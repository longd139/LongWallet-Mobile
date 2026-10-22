import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    double totalExpense = 0;
    double totalIncome = 0;

    for (var tx in transactions) {
      if (tx.type == 'EXPENSE') {
        totalExpense += tx.amount;
      } else if (tx.type == 'INCOME') {
        totalIncome += tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo chi tiêu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Income vs Expense Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: AppTheme.incomeGreen.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng thu', style: TextStyle(color: AppTheme.incomeGreen, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(totalIncome),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: AppTheme.expenseRed.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng chi', style: TextStyle(color: AppTheme.expenseRed, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(totalExpense),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Net balance
            Card(
              child: ListTile(
                title: const Text('Chênh lệch thu chi', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Thu nhập ròng tháng này', style: TextStyle(color: AppTheme.textMuted)),
                trailing: Text(
                  currencyFormatter.format(totalIncome - totalExpense),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: (totalIncome - totalExpense) >= 0 ? AppTheme.incomeGreen : AppTheme.expenseRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
