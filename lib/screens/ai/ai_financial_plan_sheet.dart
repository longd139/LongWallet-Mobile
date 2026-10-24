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

  int _step = 0; // 0: Phân tích & Hỏi câu hỏi, 1: Hiển thị ngân sách hoàn chỉnh
  int _currentQuestionIndex = 0; // Chỉ số câu hỏi đang được hỏi (hỏi từng câu một)
  bool _isLoading = true;
  String? _error;

  AiInitialAnalysis? _initialAnalysis;
  AiFinancialPlan? _finalPlan;
  bool _isFinalizing = false;
  bool _isApplying = false;

  // Controllers lưu câu trả lời của các câu hỏi
  final Map<String, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialAnalysis();
  }

  @override
  void dispose() {
    for (final ctrl in _answerControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchInitialAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final debtProvider = context.read<DebtProvider>();
      final analysis = await _aiService.getInitialAnalysis(
        totalBalance: widget.totalBalance,
        debts: debtProvider.debts,
        goal: widget.goal,
      );

      // Khởi tạo controllers cho các câu hỏi
      for (final q in analysis.questions) {
        if (!_answerControllers.containsKey(q.id)) {
          _answerControllers[q.id] = TextEditingController(
            text: ThousandsSeparatorInputFormatter.format(q.defaultValue),
          );
        }
      }

      if (mounted) {
        setState(() {
          _initialAnalysis = analysis;
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

  Future<void> _submitAnswersAndFinalize() async {
    setState(() {
      _isFinalizing = true;
      _error = null;
    });

    try {
      final debtProvider = context.read<DebtProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      List<CategoryModel> categories = categoryProvider.categories;
      if (categories.isEmpty) {
        await categoryProvider.fetchCategories();
        categories = categoryProvider.categories;
      }
      final expenseCategories = categories.where((c) => c.type == 'EXPENSE').toList();

      final answers = <String, dynamic>{};
      for (final entry in _answerControllers.entries) {
        answers[entry.key] = ThousandsSeparatorInputFormatter.parse(entry.value.text);
      }

      final plan = await _aiService.finalizeBudgetPlan(
        totalBalance: widget.totalBalance,
        debts: debtProvider.debts,
        goal: widget.goal,
        categories: expenseCategories,
        answers: answers,
      );

      if (mounted) {
        setState(() {
          _finalPlan = plan;
          _step = 1; // Chuyển sang bước hiển thị kết quả ngân sách
          _isFinalizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isFinalizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $_error')),
        );
      }
    }
  }

  Future<void> _applyPlan() async {
    final plan = _finalPlan;
    if (plan == null) return;

    setState(() => _isApplying = true);
    try {
      await context.read<BudgetProvider>().applyAiBudgetPlan(plan.suggestedBudgets);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Đã áp dụng ngân sách chi tiêu tối ưu của Gemini AI!'),
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
      height: size.height * 0.90,
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
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
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
                      Text(
                        _step == 0 ? 'Phân tích & Khảo sát AI' : 'Kế hoạch Ngân sách Hoàn chỉnh',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _step == 0
                            ? 'Bước 1/2: Tìm hiểu dòng tiền (${_currentQuestionIndex + 1}/${_initialAnalysis?.questions.length ?? 3})'
                            : 'Bước 2/2: Ngân sách đã cá nhân hóa',
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
                ? _buildLoadingState(isDark, 'Gemini AI đang phân tích dòng tiền hiện tại...')
                : _isFinalizing
                    ? _buildLoadingState(isDark, 'Đang tính toán ngân sách tối ưu theo câu trả lời của bạn...')
                    : _error != null
                        ? _buildErrorState()
                        : _step == 0
                            ? (_initialAnalysis != null
                                ? _buildStep0Questionnaire(isDark)
                                : _buildLoadingState(isDark, 'Đang tải dữ liệu phân tích...'))
                            : (_finalPlan != null
                                ? _buildStep1FinalPlan(isDark)
                                : _buildLoadingState(isDark, 'Đang tính toán kế hoạch ngân sách...')),
          ),

          // Bottom Action
          if (!_isLoading && !_isFinalizing && _error == null)
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
                child: _step == 0
                    ? _buildStep0NavigationButtons(isDark)
                    : Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _step = 0;
                              _currentQuestionIndex = 0;
                            }),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Hỏi lại'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
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
                                _isApplying ? 'Đang lưu...' : 'Áp dụng ngân sách này',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Widget điều hướng câu hỏi cho Bước 0 (Tiếp tục / Quay lại / Tạo ngân sách)
  Widget _buildStep0NavigationButtons(bool isDark) {
    final questions = _initialAnalysis?.questions ?? [];
    final total = questions.length;
    final isLast = total == 0 || _currentQuestionIndex >= total - 1;

    if (_currentQuestionIndex > 0) {
      return Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentQuestionIndex--),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Câu trước'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLast
                  ? _submitAnswersAndFinalize
                  : () => setState(() => _currentQuestionIndex++),
              icon: Icon(
                isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isLast
                    ? 'Tạo ngân sách cá nhân hóa ngay'
                    : 'Tiếp tục (Câu ${_currentQuestionIndex + 2}/$total)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: isLast
          ? _submitAnswersAndFinalize
          : () => setState(() => _currentQuestionIndex++),
      icon: Icon(
        isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        isLast
            ? 'Tạo ngân sách cá nhân hóa ngay'
            : 'Tiếp tục (Câu 2/$total)',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Bước 0: Nhận xét tài chính ban đầu và đặt câu hỏi chi tiêu cố định TỪNG CÂU MỘT
  Widget _buildStep0Questionnaire(bool isDark) {
    final analysis = _initialAnalysis;
    if (analysis == null) {
      return _buildLoadingState(isDark, 'Đang tải câu hỏi khảo sát...');
    }

    final questions = analysis.questions;
    if (questions.isEmpty) {
      return _buildLoadingState(isDark, 'Không có câu hỏi khảo sát.');
    }

    final safeIndex = _currentQuestionIndex.clamp(0, questions.length - 1);
    final q = questions[safeIndex];
    final ctrl = _answerControllers[q.id];
    final progress = (safeIndex + 1) / questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        // 1. Card nhận xét dòng tiền hiện tại
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
                  : [const Color(0xFFEDE9FE), const Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, color: Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Phân tích tài chính ban đầu',
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
                analysis.summary,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                analysis.overview,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Thanh tiến trình khảo sát
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Khảo sát dòng tiền',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Câu ${safeIndex + 1} / ${questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? Colors.white10 : const Color(0xFFEDE9FE),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Card hiển thị DUY NHẤT 1 CÂU HỎI HIỆN TẠI
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey<String>(q.id),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.35 : 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.08 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.question,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.35,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (q.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    q.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // TextField nhập số tiền
                if (ctrl != null)
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: InputDecoration(
                      suffixText: 'đ',
                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                const SizedBox(height: 14),

                // Quick options chips
                if (q.quickOptions.isNotEmpty && ctrl != null) ...[
                  Text(
                    'Chọn nhanh:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: q.quickOptions.map((opt) {
                      final label = opt >= 1000000
                          ? '${(opt / 1000000).toStringAsFixed(opt % 1000000 == 0 ? 0 : 1)} triệu'
                          : '${(opt / 1000).toInt()}k';
                      return ActionChip(
                        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        onPressed: () {
                          ctrl.text = ThousandsSeparatorInputFormatter.format(opt);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bước 1: Kế hoạch ngân sách hoàn chỉnh sau khi trả lời câu hỏi
  Widget _buildStep1FinalPlan(bool isDark) {
    final plan = _finalPlan;
    if (plan == null) {
      return _buildLoadingState(isDark, 'Đang tải kế hoạch ngân sách...');
    }
    final totalBudget = plan.suggestedBudgets.fold(0.0, (s, b) => s + b.amountLimit);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
                  : [const Color(0xFFEDE9FE), const Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Kế hoạch ngân sách đã cá nhân hóa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.summary,
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
              if (plan.overview.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  plan.overview,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nợ & Mục tiêu
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: Color(0xFFEF4444), size: 16),
                        SizedBox(width: 6),
                        Text('Chiến lược Nợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.debtPlan,
                      style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: AppTheme.primaryEmerald, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('Tích lũy Mục tiêu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald)),
                        ),
                      ],
                    ),
                    if (plan.suggestedGoalSavings > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${_currencyFormatter.format(plan.suggestedGoalSavings)} / tháng',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      plan.goalPlan,
                      style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Ngân sách đề xuất
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hạn mức ngân sách đề xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Tổng: ${_currencyFormatter.format(totalBudget)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Đã cân đối theo chi phí cố định và mức ăn uống của bạn:',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        ...plan.suggestedBudgets.map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
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
                      Text(b.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(b.reason, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Text(_currencyFormatter.format(b.amountLimit), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        if (plan.tips.isNotEmpty) ...[
          const Text('Mẹo hành động hôm nay:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...plan.tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(t, style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildLoadingState(bool isDark, String message) {
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
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
            const Text('Không thể tạo kế hoạch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? 'Đã có lỗi xảy ra', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchInitialAnalysis,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
