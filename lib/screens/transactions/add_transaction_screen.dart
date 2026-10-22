import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';

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
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Chi tiêu')),
                    selected: _selectedType == 'EXPENSE',
                    selectedColor: AppTheme.expenseRed.withOpacity(0.2),
                    onSelected: (val) => setState(() => _selectedType = 'EXPENSE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Thu nhập')),
                    selected: _selectedType == 'INCOME',
                    selectedColor: AppTheme.incomeGreen.withOpacity(0.2),
                    onSelected: (val) => setState(() => _selectedType = 'INCOME'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Số tiền (VND)',
                prefixText: '₫ ',
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
