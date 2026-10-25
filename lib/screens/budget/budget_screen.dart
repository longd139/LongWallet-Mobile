import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils/category_icon_helper.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../providers/wallet_provider.dart';
import '../ai/ai_financial_plan_sheet.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().fetchBudgets();
    });
  }

  void _showSetBudgetBottomSheet([BudgetModel? existingBudget]) {
    final budgetProvider = context.read<BudgetProvider>();
    final categories = budgetProvider.categories;
    final amountController = TextEditingController(
      text: existingBudget != null
          ? ThousandsSeparatorInputFormatter.format(existingBudget.amountLimit)
          : '',
    );
    String? selectedCategoryId = existingBudget?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existingBudget == null ? 'Thiết lập hạn mức chi tiêu' : 'Cập nhật hạn mức chi tiêu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn danh mục:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark.withOpacity(0.5) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: categories.map((cat) {
                      final catIcon = CategoryIconHelper.getIcon(cat.icon);
                      final catColor = CategoryIconHelper.hexToColor(cat.color);
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(catIcon, size: 18, color: catColor),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => selectedCategoryId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Số tiền hạn mức (VNĐ):', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: 3.000.000',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryEmerald),
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark.withOpacity(0.5) : const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick suggestion chips
                  Wrap(
                    spacing: 8,
                    children: [500000, 1000000, 2000000, 5000000].map((amt) {
                      return ActionChip(
                        label: Text(_currencyFormat.format(amt), style: const TextStyle(fontSize: 11)),
                        backgroundColor: isDark ? AppTheme.cardDark.withOpacity(0.4) : const Color(0xFFF1F5F9),
                        onPressed: () {
                          setModalState(() {
                            amountController.text = ThousandsSeparatorInputFormatter.format(amt);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final rawText = amountController.text.replaceAll(',', '').replaceAll('.', '').trim();
                      final amount = double.tryParse(rawText);
                      if (amount == null || amount <= 0 || selectedCategoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn danh mục và nhập số tiền hợp lệ')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      try {
                        await budgetProvider.setBudget(
                          categoryId: selectedCategoryId!,
                          amountLimit: amount,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã lưu hạn mức ngân sách thành công!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Lưu hạn mức'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;

    final totalBudget = budgetProvider.totalBudgetLimit;
    final totalSpent = budgetProvider.calculateTotalSpentForMonth(transactions);
    final remaining = totalBudget - totalSpent;
    final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân sách chi tiêu'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await budgetProvider.fetchBudgets();
          await txProvider.fetchTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Selector Bar
              _buildMonthSelector(budgetProvider),
              const SizedBox(height: 16),

              // Total Budget Hero Card
              _buildHeroBudgetCard(totalBudget, totalSpent, remaining, overallProgress),
              const SizedBox(height: 24),

              // Category Budgets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hạn mức theo danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showSetBudgetBottomSheet(),
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryEmerald),
                    label: const Text(
                      'Thêm mới',
                      style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Budgets List or Empty State
              if (budgetProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
                  ),
                )
              else if (budgetProvider.budgets.isEmpty)
                _buildEmptyState()
              else
                ...budgetProvider.budgets.map((budget) {
                  final category = budgetProvider.getCategoryById(budget.categoryId);
                  final catSpent = budgetProvider.calculateSpentForCategory(budget.categoryId, transactions);
                  return _buildCategoryBudgetCard(budget, category, catSpent, budgetProvider);
                }),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BudgetProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.cardDark.withOpacity(0.6) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            onPressed: () => provider.changeMonth(-1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryEmerald),
              const SizedBox(width: 8),
              Text(
                provider.displayMonthYear,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            onPressed: () => provider.changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBudgetCard(
    double totalBudget,
    double totalSpent,
    double remaining,
    double progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverBudget = totalBudget > 0 && totalSpent > totalBudget;
    final progressColor = isOverBudget
        ? AppTheme.expenseRed
        : (progress > 0.8 ? const Color(0xFFF59E0B) : AppTheme.primaryEmerald);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  isOverBudget
                      ? const Color(0xFF450A0A)
                      : const Color(0xFF064E3B).withOpacity(0.6),
                ]
              : [
                  Colors.white,
                  isOverBudget
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFECFDF5),
                ],
        ),
        border: Border.all(
          color: progressColor.withOpacity(isDark ? 0.4 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(isDark ? 0.12 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng hạn mức ngân sách',
                style: TextStyle(
                  color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: progressColor.withOpacity(0.4)),
                ),
                child: Text(
                  isOverBudget ? 'Vượt hạn mức' : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(totalBudget),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppTheme.cardDark : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 16),
          // Summary Details Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã chi tiêu',
                      style: TextStyle(
                        color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(totalSpent),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? AppTheme.cardDark : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      remaining >= 0 ? 'Còn lại' : 'Vượt quá',
                      style: TextStyle(
                        color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(remaining.abs()),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: remaining >= 0 ? AppTheme.incomeGreen : AppTheme.expenseRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetCard(
    BudgetModel budget,
    CategoryModel? category,
    double spent,
    BudgetProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final limit = budget.amountLimit;
    final ratio = limit > 0 ? (spent / limit) : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final isExceeded = spent > limit;

    Color statusColor;
    String statusText;
    if (isExceeded) {
      statusColor = AppTheme.expenseRed;
      statusText = 'Vượt ${((ratio - 1.0) * 100).toInt()}%';
    } else if (ratio >= 0.8) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Đã dùng ${(ratio * 100).toInt()}%';
    } else {
      statusColor = AppTheme.primaryEmerald;
      statusText = 'Còn lại ${_currencyFormat.format(limit - spent)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExceeded
              ? AppTheme.expenseRed.withOpacity(0.5)
              : (isDark ? AppTheme.cardDark.withOpacity(0.5) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  final catIcon = CategoryIconHelper.getIcon(category?.icon);
                  final catColor = category != null
                      ? CategoryIconHelper.hexToColor(category.color)
                      : statusColor;

                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      catIcon,
                      color: catColor,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Danh mục',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                onSelected: (val) {
                  if (val == 'edit') {
                    _showSetBudgetBottomSheet(budget);
                  } else if (val == 'delete') {
                    provider.deleteBudget(budget.id);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chỉnh sửa',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppTheme.expenseRed),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: AppTheme.expenseRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? AppTheme.cardDark : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã chi: ${_currencyFormat.format(spent)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              Text(
                'Hạn mức: ${_currencyFormat.format(limit)}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.cardDark.withOpacity(0.3) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppTheme.primaryEmerald),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có ngân sách cho tháng này',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đặt hạn mức chi tiêu cho từng danh mục giúp bạn quản lý tài chính khoa học và tránh chi tiêu quá tay.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final walletProvider = context.read<WalletProvider>();
              AiFinancialPlanSheet.show(
                context,
                totalBalance: walletProvider.totalBalance,
                goal: {
                  'name': 'Honda Winner X V4',
                  'targetAmount': 50000000.0,
                  'currentBalance': walletProvider.goalWallet?.currentBalance ?? 0.0,
                },
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text('Gemini AI tự tạo ngân sách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _showSetBudgetBottomSheet(),
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryEmerald),
            label: const Text(
              'Thiết lập thủ công',
              style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald.withOpacity(0.12),
              elevation: 0,
              shadowColor: Colors.transparent,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
