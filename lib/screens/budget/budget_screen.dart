import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';

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
      text: existingBudget != null ? existingBudget.amountLimit.toStringAsFixed(0) : '',
    );
    String? selectedCategoryId = existingBudget?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existingBudget == null ? 'Thiết lập hạn mức chi tiêu' : 'Cập nhật hạn mức chi tiêu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn danh mục:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    dropdownColor: AppTheme.surfaceDark,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardDark.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Row(
                          children: [
                            const Icon(Icons.label_outline_rounded, size: 18, color: AppTheme.primaryEmerald),
                            const SizedBox(width: 8),
                            Text(cat.name, style: const TextStyle(color: Colors.white)),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: 3000000',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryEmerald),
                      filled: true,
                      fillColor: AppTheme.cardDark.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick suggestion chips
                  Wrap(
                    spacing: 8,
                    children: [500000, 1000000, 2000000, 5000000].map((amt) {
                      return ActionChip(
                        label: Text(_currencyFormat.format(amt), style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.cardDark.withOpacity(0.4),
                        onPressed: () {
                          setModalState(() {
                            amountController.text = amt.toString();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryEmerald),
            tooltip: 'Thêm hạn mức',
            onPressed: () => _showSetBudgetBottomSheet(),
          ),
        ],
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
                  const Text(
                    'Hạn mức theo danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BudgetProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardDark.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            onPressed: () => provider.changeMonth(-1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryEmerald),
              const SizedBox(width: 8),
              Text(
                provider.displayMonthYear,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
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
          colors: [
            const Color(0xFF1E293B),
            isOverBudget
                ? const Color(0xFF450A0A)
                : const Color(0xFF064E3B).withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: progressColor.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.12),
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
              const Text(
                'Tổng hạn mức ngân sách',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
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
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
              backgroundColor: AppTheme.cardDark,
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
                    const Text('Đã chi tiêu', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(totalSpent),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppTheme.cardDark),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      remaining >= 0 ? 'Còn lại' : 'Vượt quá',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExceeded ? AppTheme.expenseRed.withOpacity(0.5) : AppTheme.cardDark.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Danh mục',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                color: AppTheme.surfaceDark,
                onSelected: (val) {
                  if (val == 'edit') {
                    _showSetBudgetBottomSheet(budget);
                  } else if (val == 'delete') {
                    provider.deleteBudget(budget.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
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
              backgroundColor: AppTheme.cardDark,
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
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardDark.withOpacity(0.3)),
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
            onPressed: () => _showSetBudgetBottomSheet(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thiết lập ngay'),
          ),
        ],
      ),
    );
  }
}
