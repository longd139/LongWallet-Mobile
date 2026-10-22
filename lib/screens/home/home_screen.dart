import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/pending_transactions_screen.dart';
import '../wallets/wallets_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<TransactionProvider>().fetchTransactions();
      _checkNotificationPermission();
    });
  }

  void _checkNotificationPermission() async {
    final granted = await _notificationService.isPermissionGranted();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bật quyền đọc thông báo để tự động ghi nhận biến động số dư ngân hàng'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Cài đặt',
            onPressed: () => _notificationService.openSettings(),
          ),
        ),
      );
    } else {
      _notificationService.startListening(onNewTransaction: (tx) {
        if (mounted) {
          context.read<TransactionProvider>().fetchTransactions();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeDashboard(),
      const WalletsScreen(),
      const StatsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryEmerald),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primaryEmerald),
            label: 'Ví tiền',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primaryEmerald),
            label: 'Báo cáo',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        backgroundColor: AppTheme.primaryEmerald,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHomeDashboard() {
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await walletProvider.fetchWallets();
          await txProvider.fetchTransactions();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Xin chào,', style: TextStyle(color: AppTheme.textMuted)),
                      Text(
                        authProvider.user?.email ?? 'Người dùng',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => authProvider.signOut(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Balance Card
              Card(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng số dư',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(walletProvider.totalBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pending Auto-detected Transactions Alert
              if (txProvider.pendingCount > 0)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingTransactionsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notification_important, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bạn có ${txProvider.pendingCount} biến động số dư ngân hàng chờ duyệt!',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.amber),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Recent Transactions Header
              const Text(
                'Giao dịch gần đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Transactions List
              if (txProvider.transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Chưa có giao dịch nào', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txProvider.transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = txProvider.transactions[index];
                    final isExpense = tx.type == 'EXPENSE';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isExpense
                            ? AppTheme.expenseRed.withOpacity(0.15)
                            : AppTheme.incomeGreen.withOpacity(0.15),
                        child: Icon(
                          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen,
                        ),
                      ),
                      title: Text(
                        tx.note ?? (isExpense ? 'Chi tiêu' : 'Thu nhập'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(tx.transactionDate),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: Text(
                        '${isExpense ? '-' : '+'}${currencyFormatter.format(tx.amount)}',
                        style: TextStyle(
                          color: isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
