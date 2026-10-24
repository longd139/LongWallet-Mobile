import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_input_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'EXPENSE';
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<WalletProvider>().wallets;
    if (wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '').replaceAll('.', '').trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ví')),
      );
      return;
    }

    await context.read<TransactionProvider>().addTransaction(
      walletId: _selectedWalletId!,
      amount: amount,
      type: _selectedType,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().wallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm giao dịch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardDark.withOpacity(0.8)),
              ),
              child: Row(
                children: [
                  // Chi tiêu (Expense)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'EXPENSE'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == 'EXPENSE'
                              ? AppTheme.expenseRed
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == 'EXPENSE'
                              ? [
                                  BoxShadow(
                                    color: AppTheme.expenseRed.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                              color: _selectedType == 'EXPENSE'
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chi tiêu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _selectedType == 'EXPENSE'
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedType == 'EXPENSE'
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Thu nhập (Income)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'INCOME'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == 'INCOME'
                              ? AppTheme.incomeGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == 'INCOME'
                              ? [
                                  BoxShadow(
                                    color: AppTheme.incomeGreen.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                              color: _selectedType == 'INCOME'
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thu nhập',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _selectedType == 'INCOME'
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _selectedType == 'INCOME'
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _selectedType == 'EXPENSE' ? AppTheme.expenseRed : AppTheme.incomeGreen,
              ),
              decoration: InputDecoration(
                labelText: 'Số tiền (VND)',
                prefixText: _selectedType == 'EXPENSE' ? '- ₫ ' : '+ ₫ ',
                prefixStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _selectedType == 'EXPENSE' ? AppTheme.expenseRed : AppTheme.incomeGreen,
                ),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 20),

            // Wallet Selector
            if (wallets.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                decoration: const InputDecoration(labelText: 'Chọn ví'),
                items: wallets.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text('${w.name} (${w.bankCode ?? "Tiền mặt"})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
            const SizedBox(height: 20),

            // Note Input
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ăn trưa, cafe, đổ xăng...',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Lưu giao dịch'),
            ),
          ],
        ),
      ),
    );
  }
}
