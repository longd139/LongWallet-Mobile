import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';

class PendingTransactionsScreen extends StatelessWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final pendingList = txProvider.pendingTransactions;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch ngân hàng chờ duyệt'),
      ),
      body: pendingList.isEmpty
          ? const Center(
              child: Text(
                'Không có giao dịch nào chờ duyệt',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final tx = pendingList[index];
                final isExpense = tx.type == 'EXPENSE';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '⚡ Auto-Detected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryEmerald,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${isExpense ? '-' : '+'}${currencyFormatter.format(tx.amount)}',
                              style: TextStyle(
                                color: isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tx.note ?? 'Biến động số dư',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        if (tx.rawMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            tx.rawMessage!,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                txProvider.rejectPendingTransaction(tx.id);
                              },
                              icon: const Icon(Icons.close, color: AppTheme.expenseRed, size: 18),
                              label: const Text('Bỏ qua', style: TextStyle(color: AppTheme.expenseRed)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                txProvider.confirmPendingTransaction(tx.id);
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
