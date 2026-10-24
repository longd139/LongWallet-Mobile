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
import '../debts/debts_screen.dart';
import '../../providers/debt_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../providers/theme_provider.dart';

import '../../core/widgets/custom_bottom_nav_bar.dart';
import 'widgets/pending_question_card.dart';
import '../ai/ai_financial_plan_sheet.dart';

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

  String _goalTitle = 'Honda Winner X V4';
  double _goalTargetAmount = 50000000;
  String _goalSlogan = 'Cày cuốc gom tiền – Quyết liền Winner X';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadGoal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<TransactionProvider>().fetchTransactions();
      context.read<DebtProvider>().fetchDebts();
      _notificationService.requestPostNotificationPermission();
      _checkNotificationPermission();
    });
  }

  void _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final title = prefs.getString('goal_title') ?? 'Honda Winner X V4';
      setState(() {
        _goalTitle = title;
        _goalTargetAmount = prefs.getDouble('goal_target') ?? 50000000;
        _goalSlogan = prefs.getString('goal_slogan') ?? 'Cày cuốc gom tiền – Quyết liền Winner X';
      });
      context.read<WalletProvider>().ensureGoalWallet(title);
    }
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
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Only navigate through tabs
            children: screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
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
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 76),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                  );
                },
                backgroundColor: AppTheme.primaryEmerald,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeDashboard() {
    final walletProvider = context.watch<WalletProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final debtProvider = context.watch<DebtProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await walletProvider.fetchWallets();
          await txProvider.fetchTransactions();
          await debtProvider.fetchDebts();
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
              const SizedBox(height: 16),

              // Goal Motivation Card (Winner X V4)
              _buildGoalCard(walletProvider.goalWallet?.currentBalance ?? 0.0),

              // Total Balance Card
              Card(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
              const SizedBox(height: 12),

              // Total Debt Card (Tổng nợ)
              _buildDebtCard(debtProvider),
              const SizedBox(height: 12),

              // AI Financial Advisor Card (Gemini 3.5 Flash)
              _buildAiAdvisorCard(walletProvider, debtProvider),
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
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTargetShort(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return millions % 1 == 0 ? '${millions.toInt()}tr' : '${millions.toStringAsFixed(1)}tr';
    }
    return currencyFormatter.format(amount);
  }

  Widget _buildDebtCard(DebtProvider debtProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDebt = debtProvider.totalDebt;
    final monthlyDue = debtProvider.totalMonthlyDebtDue;
    final totalLoan = debtProvider.totalLoan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DebtsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A22) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(isDark ? 0.35 : 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(isDark ? 0.08 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cần trả tháng này',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Sổ nợ',
                        style: TextStyle(
                          color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currencyFormatter.format(monthlyDue),
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (totalDebt > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(isDark ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tổng dư nợ: ${currencyFormatter.format(totalDebt)}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Không có nợ tồn đọng ✨',
                      style: TextStyle(
                        color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              if (totalLoan > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: AppTheme.primaryEmerald),
                    const SizedBox(width: 4),
                    Text(
                      'Đang cho vay: +${currencyFormatter.format(totalLoan)}',
                      style: const TextStyle(
                        color: AppTheme.primaryEmerald,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAdvisorCard(WalletProvider walletProvider, DebtProvider debtProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AiFinancialPlanSheet.show(
            context,
            totalBalance: walletProvider.totalBalance,
            goal: {
              'name': _goalName,
              'targetAmount': _goalTargetAmount,
              'currentBalance': walletProvider.goalWallet?.currentBalance ?? 0.0,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                  : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.4 : 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Trợ lý AI Lập Ngân Sách',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Gemini',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tự động phân bổ số dư, cân đối nợ & mua Winner X',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Phân tích',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(double currentBalance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_goalTargetAmount > 0 ? (currentBalance / _goalTargetAmount) : 0.0).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showEditGoalDialog,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141923) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDC2626).withOpacity(isDark ? 0.35 : 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(isDark ? 0.08 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Thông tin & Tiến trình tiết kiệm
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded, size: 12, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text(
                                'MỤC TIÊU LỚN',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _goalTitle,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _goalSlogan,
                      style: TextStyle(
                        color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFFEE2E2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${currencyFormatter.format(currentBalance)} / ${_formatTargetShort(_goalTargetAmount)}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right: Hình ảnh chiếc xe Winner X V4 (Cloudinary URL, Nền trong suốt, kích thước lớn)
              SizedBox(
                width: 140,
                height: 112,
                child: Image.network(
                  AppConstants.winnerXImageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.two_wheeler_rounded,
                        color: Color(0xFFEF4444),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditGoalDialog() {
    final titleController = TextEditingController(text: _goalTitle);
    final amountController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.format(_goalTargetAmount),
    );
    final sloganController = TextEditingController(text: _goalSlogan);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Text(
                            'Chỉnh sửa mục tiêu tài chính',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      labelText: 'Tên mục tiêu',
                      hintText: 'Ví dụ: Honda Winner X V4',
                      prefixIcon: Icon(Icons.two_wheeler_rounded, color: Color(0xFFEF4444)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Số tiền mục tiêu (VNĐ)',
                      hintText: '50.000.000',
                      prefixIcon: Icon(Icons.monetization_on_outlined, color: AppTheme.primaryEmerald),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick suggestion chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildQuickAmountChip('30 triệu', 30000000, amountController, setSheetState, isDark),
                      _buildQuickAmountChip('45 triệu', 45000000, amountController, setSheetState, isDark),
                      _buildQuickAmountChip('50 triệu', 50000000, amountController, setSheetState, isDark),
                      _buildQuickAmountChip('60 triệu', 60000000, amountController, setSheetState, isDark),
                      _buildQuickAmountChip('80 triệu', 80000000, amountController, setSheetState, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sloganController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Khẩu hiệu động lực',
                      hintText: 'Ví dụ: Cày cuốc gom tiền – Quyết liền Winner X',
                      prefixIcon: Icon(
                        Icons.format_quote_rounded,
                        color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final newTitle = titleController.text.trim();
                      final rawAmount = amountController.text.replaceAll(',', '').replaceAll('.', '').trim();
                      final newAmount = double.tryParse(rawAmount);
                      final newSlogan = sloganController.text.trim();

                      if (newTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tên mục tiêu')),
                        );
                        return;
                      }

                      if (newAmount == null || newAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập số tiền mục tiêu hợp lệ')),
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('goal_title', newTitle);
                      await prefs.setDouble('goal_target', newAmount);
                      await prefs.setString('goal_slogan', newSlogan.isNotEmpty ? newSlogan : 'Quyết tâm gom tiền!');

                      setState(() {
                        _goalTitle = newTitle;
                        _goalTargetAmount = newAmount;
                        _goalSlogan = newSlogan.isNotEmpty ? newSlogan : 'Quyết tâm gom tiền!';
                      });

                      if (mounted) {
                        context.read<WalletProvider>().ensureGoalWallet(newTitle);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật mục tiêu tài chính!'),
                            backgroundColor: AppTheme.primaryEmerald,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Lưu mục tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountChip(
    String label,
    double value,
    TextEditingController controller,
    StateSetter setSheetState,
    bool isDark,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isDark
          ? AppTheme.cardDark.withOpacity(0.6)
          : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1),
      ),
      onPressed: () {
        setSheetState(() {
          controller.text = ThousandsSeparatorInputFormatter.format(value);
        });
      },
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
                  // Mục chỉnh Sáng / Tối (Icon solid 1 màu, không dùng icon bàn phím)
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      final isDark = themeProvider.isDarkMode;
                      return SwitchListTile.adaptive(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        title: Text(
                          isDark ? 'Giao diện tối' : 'Giao diện sáng',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isDark ? 'Đang bật chế độ ban đêm' : 'Đang bật chế độ ban ngày',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        value: isDark,
                        activeColor: AppTheme.primaryEmerald,
                        onChanged: (_) => themeProvider.toggleTheme(),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),
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
