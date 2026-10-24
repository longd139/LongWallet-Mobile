import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/debt_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../core/utils/category_icon_helper.dart';
import '../../core/utils/currency_input_formatter.dart';

class AiFinancialPlanSheet extends StatefulWidget {
  final double totalBalance;
  final Map<String, dynamic>? goal;

  const AiFinancialPlanSheet({
    super.key,
    required this.totalBalance,
    this.goal,
  });

  static void show(BuildContext context, {required double totalBalance, Map<String, dynamic>? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiFinancialPlanSheet(
        totalBalance: totalBalance,
        goal: goal,
      ),
    );
  }

  @override
  State<AiFinancialPlanSheet> createState() => _AiFinancialPlanSheetState();
}

class _AiFinancialPlanSheetState extends State<AiFinancialPlanSheet> {
  final _aiService = AiService();
  final _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isLoading = true;
  String? _error;
  AiFinancialPlan? _plan;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _fetchAiPlan();
  }

  Future<void> _fetchAiPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final debtProvider = context.read<DebtProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      // Đảm bảo có danh mục
      List<CategoryModel> categories = categoryProvider.categories;
      if (categories.isEmpty) {
        await categoryProvider.fetchCategories();
        categories = categoryProvider.categories;
      }

      // Chỉ gửi các danh mục EXPENSE (chi tiêu)
      final expenseCategories = categories.where((c) => c.type == 'EXPENSE').toList();

      final plan = await _aiService.generateFinancialPlan(
        totalBalance: widget.totalBalance,
        debts: debtProvider.debts,
        goal: widget.goal,
        categories: expenseCategories,
      );

      if (mounted) {
        setState(() {
          _plan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyPlan() async {
    if (_plan == null) return;

    setState(() => _isApplying = true);
    try {
      await context.read<BudgetProvider>().applyAiBudgetPlan(_plan!.suggestedBudgets);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Đã áp dụng ngân sách chi tiêu do Gemini AI đề xuất!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi áp dụng ngân sách: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kế hoạch Tài chính AI',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Phân tích bởi Google Gemini 3.5 Flash',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: _isLoading
                ? _buildLoadingState(isDark)
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(isDark),
          ),

          // Bottom Action
          if (_plan != null && !_isLoading)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isApplying ? null : _applyPlan,
                  icon: _isApplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    _isApplying ? 'Đang lưu ngân sách...' : 'Áp dụng ngân sách này ngay',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.2),
                    const Color(0xFF3B82F6).withOpacity(0.2),
                  ],
                ),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gemini AI đang phân tích...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang cân đối số dư ví, các khoản nợ và mục tiêu mua xe của bạn để tạo ngân sách chi tiêu tối ưu nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Không thể tạo kế hoạch',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchAiPlan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final plan = _plan!;
    final totalBudget = plan.suggestedBudgets.fold(0.0, (s, b) => s + b.amountLimit);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // 1. Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
                  : [const Color(0xFFEDE9FE), const Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đánh giá dòng tiền hôm nay',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.summary,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Debt & Goal Strategies
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debt Strategy
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Chiến lược Nợ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.debtPlan,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Goal Strategy
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: AppTheme.primaryEmerald, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Tích lũy Mục tiêu',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald),
                          ),
                        ),
                      ],
                    ),
                    if (plan.suggestedGoalSavings > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${_currencyFormatter.format(plan.suggestedGoalSavings)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      plan.goalPlan,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Suggested Budgets Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ngân sách đề xuất chi tiêu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tổng: ${_currencyFormatter.format(totalBudget)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'AI đã tự động cân đối hạn mức theo thứ tự ưu tiên sinh hoạt:',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        // Budgets List
        ...plan.suggestedBudgets.map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryEmerald.withOpacity(0.15),
                  child: Icon(
                    CategoryIconHelper.getIcon(b.categoryName),
                    size: 18,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.reason,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currencyFormatter.format(b.amountLimit),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // 4. Tips Card
        if (plan.tips.isNotEmpty) ...[
          const Text(
            'Mẹo hành động hôm nay:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...plan.tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
