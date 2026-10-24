import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../transactions/add_transaction_screen.dart';
import '../wallets/wallets_screen.dart';
import '../budget/budget_screen.dart';
import '../stats/stats_screen.dart';
import '../categories/categories_screen.dart';

import '../../core/widgets/custom_bottom_nav_bar.dart';
import 'widgets/pending_question_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Default to 'Me' tab
  late final PageController _pageController;
  final NotificationService _notificationService = NotificationService();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<TransactionProvider>().fetchTransactions();
      _notificationService.requestPostNotificationPermission();
      _checkNotificationPermission();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          context.read<WalletProvider>().fetchWallets();
        }
      });
    }
  }

  void _showSimulateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131D2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🧪 Thử nghiệm thông báo ngân hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Bắn thông báo giả lập lên thanh trạng thái điện thoại và hiển thị câu hỏi tương ứng trong Giao dịch gần đây.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                tileColor: AppTheme.incomeGreen.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppTheme.incomeGreen.withOpacity(0.3)),
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.incomeGreen,
                  child: Icon(Icons.arrow_downward, color: Colors.black),
                ),
                title: const Text('Thử nhận tiền (+200.000 ₫)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hỏi: "Tiền này từ đâu?"', style: TextStyle(color: AppTheme.incomeGreen, fontSize: 12)),
                trailing: const Icon(Icons.send_rounded, color: AppTheme.incomeGreen),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _notificationService.simulateTransactionNotification(
                    amount: 200000,
                    type: 'INCOME',
                    bankName: 'Vietcombank',
                    content: 'Chuyen tien tieu vat',
                  );
                  if (mounted) {
                    await context.read<TransactionProvider>().fetchTransactions();
                    await context.read<WalletProvider>().fetchWallets();
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: AppTheme.expenseRed.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppTheme.expenseRed.withOpacity(0.3)),
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.expenseRed,
                  child: Icon(Icons.arrow_upward, color: Colors.white),
                ),
                title: const Text('Thử chi tiền (-45.000 ₫)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hỏi: "Bạn đã chi tiêu cái gì?"', style: TextStyle(color: AppTheme.expenseRed, fontSize: 12)),
                trailing: const Icon(Icons.send_rounded, color: AppTheme.expenseRed),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _notificationService.simulateTransactionNotification(
                    amount: 45000,
                    type: 'EXPENSE',
                    bankName: 'MB Bank',
                    content: 'Thanh toan HighLand Coffee',
                  );
                  if (mounted) {
                    await context.read<TransactionProvider>().fetchTransactions();
                    await context.read<WalletProvider>().fetchWallets();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeDashboard(),
      const WalletsScreen(),
      const BudgetScreen(),
      const StatsScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Only navigate through tabs
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
          );
        },
        items: const [
          CustomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Me',
            activeColor: AppTheme.primaryEmerald, // Glowing Emerald
            activeHaloColor: Color(0x3D10B981),
          ),
          CustomNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Ví',
            activeColor: Color(0xFF38BDF8), // Pastel Sky Blue
            activeHaloColor: Color(0x3D0284C7),
          ),
          CustomNavItem(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Ngân sách',
            activeColor: Color(0xFFA855F7), // Vivid Purple
            activeHaloColor: Color(0x3D9333EA),
          ),
          CustomNavItem(
            icon: Icons.explore_outlined,
            label: 'Explore',
            activeColor: Color(0xFFFBBF24), // Warm Peach/Amber
            activeHaloColor: Color(0x3DF59E0B),
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            activeColor: Color(0xFF818CF8), // Pastel Indigo
            activeHaloColor: Color(0x3D6366F1),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                );
              },
              backgroundColor: AppTheme.primaryEmerald,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                        _getUserDisplayName(authProvider),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryEmerald),
                    tooltip: 'Quản lý ví',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletsScreen()),
                      );
                    },
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
              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Giao dịch gần đây',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (txProvider.pendingCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${txProvider.pendingCount}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _showSimulateDialog,
                    icon: const Icon(Icons.science_outlined, size: 16, color: AppTheme.primaryEmerald),
                    label: const Text(
                      'Thử thông báo',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryEmerald, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Interactive Question Cards for Pending Bank Transactions
              if (txProvider.pendingTransactions.isNotEmpty) ...[
                ...txProvider.pendingTransactions.map((tx) {
                  return PendingQuestionCard(
                    transaction: tx,
                    onConfirm: (note) async {
                      await txProvider.confirmPendingTransaction(tx.id, note: note);
                      await walletProvider.fetchWallets();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Đã ghi nhận: $note'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    onReject: () async {
                      await txProvider.rejectPendingTransaction(tx.id);
                    },
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],

              // 2. Confirmed Transactions List
              if (txProvider.pendingTransactions.isEmpty && txProvider.transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Chưa có giao dịch nào', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else if (txProvider.transactions.isNotEmpty)
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

  String _getUserDisplayName(AuthProvider auth) {
    final metaName = auth.user?.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }
    final email = auth.user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }
    return 'Người dùng';
  }

  Widget _buildProfileScreen() {
    final authProvider = context.watch<AuthProvider>();
    final email = authProvider.user?.email ?? 'Người dùng';
    final name = _getUserDisplayName(authProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFFED7AA), // Pastel peach from reference
              child: Icon(
                Icons.person_rounded,
                size: 52,
                color: Color(0xFF7C2D12),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Slogan badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
              ),
              child: const Text(
                'Cày cuốc gom tiền – Quyết liền Winner X',
                style: TextStyle(
                  color: AppTheme.primaryEmerald,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Settings card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryEmerald),
                    title: const Text('Lắng nghe biến động ngân hàng'),
                    subtitle: const Text('Tự động ghi nhận chi tiêu từ SMS/Noti'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _notificationService.openSettings(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blueAccent),
                    title: const Text('Quản lý ví & Tài khoản'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category_outlined, color: Color(0xFFF59E0B)),
                    title: const Text('Quản lý danh mục'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                      );
                    },
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: AppTheme.textMuted),
                    title: Text('Phiên bản ứng dụng'),
                    trailing: Text('v1.0.0', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout button
            ElevatedButton.icon(
              onPressed: () => authProvider.signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseRed.withOpacity(0.15),
                foregroundColor: AppTheme.expenseRed,
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppTheme.expenseRed.withOpacity(0.3)),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất tài khoản'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
