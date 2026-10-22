import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  void _showAddWalletDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    String? selectedPackage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Thêm ví mới / Tài khoản ngân hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên ví (VD: Vietcombank chính)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPackage,
                      decoration: const InputDecoration(labelText: 'Liên kết ngân hàng (Tự động đọc số dư)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ví tiền mặt thông thường')),
                        ...AppConstants.bankPackages.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }),
                      ],
                      onChanged: (val) => setModalState(() => selectedPackage = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountCtrl,
                      decoration: const InputDecoration(labelText: 'Số tài khoản / 4 số cuối thẻ (tùy chọn)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số dư ban đầu (VND)', hintText: '0'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final balance = double.tryParse(balanceCtrl.text.replaceAll(',', '')) ?? 0;
                        final bankCode = selectedPackage != null ? AppConstants.bankPackages[selectedPackage] : 'CASH';

                        await context.read<WalletProvider>().addWallet(
                          name: name,
                          bankCode: bankCode,
                          accountNumber: accountCtrl.text.trim().isNotEmpty ? accountCtrl.text.trim() : null,
                          packageName: selectedPackage,
                          initialBalance: balance,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Thêm ví'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý ví tiền'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWalletDialog(context),
          ),
        ],
      ),
      body: walletProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: walletProvider.wallets.length,
              itemBuilder: (context, index) {
                final wallet = walletProvider.wallets[index];
                final isBank = wallet.packageName != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isBank ? Colors.blue.withOpacity(0.2) : AppTheme.primaryEmerald.withOpacity(0.2),
                      child: Icon(
                        isBank ? Icons.account_balance : Icons.wallet,
                        color: isBank ? Colors.blue : AppTheme.primaryEmerald,
                      ),
                    ),
                    title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (wallet.accountNumber != null)
                          Text('STK: ${wallet.accountNumber}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        if (isBank)
                          const Row(
                            children: [
                              Icon(Icons.sync, size: 12, color: AppTheme.primaryEmerald),
                              SizedBox(width: 4),
                              Text('Tự động bắt số dư', style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11)),
                            ],
                          ),
                      ],
                    ),
                    trailing: Text(
                      currencyFormatter.format(wallet.currentBalance),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
