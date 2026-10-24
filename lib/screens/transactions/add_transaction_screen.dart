import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _selectedType = 'EXPENSE'; // 'EXPENSE', 'INCOME', 'GOAL'
  String? _selectedWalletId;
  String _goalTitle = 'Honda Winner X V4';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadGoalInfo();
    final standardWallets = context.read<WalletProvider>().standardWallets;
    if (standardWallets.isNotEmpty) {
      _selectedWalletId = standardWallets.first.id;
    } else {
      final wallets = context.read<WalletProvider>().wallets;
      if (wallets.isNotEmpty) {
        _selectedWalletId = wallets.first.id;
      }
    }
  }

  Future<void> _loadGoalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString('goal_title');
    if (title != null && title.isNotEmpty && mounted) {
      setState(() => _goalTitle = title);
    }
    // Khởi tạo/đảm bảo đã có ví mục tiêu
    if (mounted) {
      await context.read<WalletProvider>().ensureGoalWallet(_goalTitle);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_isSubmitting) return;

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

    setState(() => _isSubmitting = true);

    try {
      final walletProvider = context.read<WalletProvider>();
      final txProvider = context.read<TransactionProvider>();

      if (_selectedType == 'GOAL') {
        // Chuyển tiền vào mục tiêu
        final goalWallet = await walletProvider.ensureGoalWallet(_goalTitle);
        if (_selectedWalletId == goalWallet.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể chuyển từ ví mục tiêu sang chính nó. Vui lòng chọn ví nguồn khác!')),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        await walletProvider.transferToGoal(
          sourceWalletId: _selectedWalletId!,
          goalWalletId: goalWallet.id,
          amount: amount,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );
        await txProvider.fetchTransactions();
      } else {
        // Chi tiêu hoặc Thu nhập thông thường
        await txProvider.addTransaction(
          walletId: _selectedWalletId!,
          amount: amount,
          type: _selectedType,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );
        await walletProvider.fetchWallets();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedType == 'GOAL' ? 'Đã tích lũy vào mục tiêu thành công!' : 'Đã lưu giao dịch thành công!'),
            backgroundColor: _selectedType == 'GOAL' ? const Color(0xFFEF4444) : AppTheme.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // Nếu đang ở tab GOAL thì ví nguồn phải là standardWallets (loại trừ ví mục tiêu)
    final availableWallets = _selectedType == 'GOAL'
        ? walletProvider.standardWallets
        : walletProvider.wallets;

    // Đảm bảo selectedWalletId hợp lệ trong danh sách ví hiển thị
    if (_selectedWalletId != null &&
        availableWallets.isNotEmpty &&
        !availableWallets.any((w) => w.id == _selectedWalletId)) {
      _selectedWalletId = availableWallets.first.id;
    }

    final goalWallet = walletProvider.goalWallet;

    Color themeColor;
    String prefixSign;
    if (_selectedType == 'EXPENSE') {
      themeColor = AppTheme.expenseRed;
      prefixSign = '- ₫ ';
    } else if (_selectedType == 'INCOME') {
      themeColor = AppTheme.incomeGreen;
      prefixSign = '+ ₫ ';
    } else {
      themeColor = const Color(0xFFEF4444);
      prefixSign = '🎯 ₫ ';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm giao dịch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3-way Type Selector: Chi tiêu / Thu nhập / Vào mục tiêu
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppTheme.cardDark.withOpacity(0.8)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  // 1. Chi tiêu (Expense)
                  _buildTypeTabItem(
                    type: 'EXPENSE',
                    label: 'Chi tiêu',
                    icon: Icons.arrow_downward_rounded,
                    activeColor: AppTheme.expenseRed,
                  ),

                  // 2. Thu nhập (Income)
                  _buildTypeTabItem(
                    type: 'INCOME',
                    label: 'Thu nhập',
                    icon: Icons.arrow_upward_rounded,
                    activeColor: AppTheme.incomeGreen,
                  ),

                  // 3. Vào mục tiêu (Goal)
                  _buildTypeTabItem(
                    type: 'GOAL',
                    label: 'Mục tiêu',
                    icon: Icons.flag_rounded,
                    activeColor: const Color(0xFFEF4444),
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
                color: themeColor,
              ),
              decoration: InputDecoration(
                labelText: _selectedType == 'GOAL' ? 'Số tiền tích lũy (VND)' : 'Số tiền (VND)',
                prefixText: prefixSign,
                prefixStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 20),

            // Wallet Selector
            if (availableWallets.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                decoration: InputDecoration(
                  labelText: _selectedType == 'GOAL' ? 'Trích tiền từ ví' : 'Chọn ví',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                items: availableWallets.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text('${w.name} (${currencyFormatter.format(w.currentBalance)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),

            // Goal Destination Info Card (chỉ hiện khi chọn tab Mục tiêu)
            if (_selectedType == 'GOAL') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chuyển vào ví mục tiêu:',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goalWallet?.name ?? 'Mục tiêu: $_goalTitle',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Đã gom được',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                        Text(
                          currencyFormatter.format(goalWallet?.currentBalance ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Note Input
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                hintText: _selectedType == 'GOAL'
                    ? 'Ví dụ: Trích thưởng tháng này, tiết kiệm tiền ăn...'
                    : 'Ăn trưa, cafe, đổ xăng...',
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _saveTransaction,
              style: _selectedType == 'GOAL'
                  ? ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _selectedType == 'GOAL' ? 'Chuyển tiền vào mục tiêu' : 'Lưu giao dịch',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabItem({
    required String type,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            // Nếu chuyển sang GOAL, reset lại ví nguồn sang standardWallet đầu tiên
            if (type == 'GOAL') {
              final stdWallets = context.read<WalletProvider>().standardWallets;
              if (stdWallets.isNotEmpty) {
                _selectedWalletId = stdWallets.first.id;
              }
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
