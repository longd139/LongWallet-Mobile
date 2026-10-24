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

class FixedExpenseItemDef {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final double defaultValue;
  final List<double> quickOptions;

  const FixedExpenseItemDef({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.defaultValue,
    required this.quickOptions,
  });
}

class _AiFinancialPlanSheetState extends State<AiFinancialPlanSheet> {
  final _aiService = AiService();
  final _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  int _step = 0; // 0: Phân tích & Hỏi câu hỏi, 1: Hiển thị ngân sách hoàn chỉnh
  int _currentQuestionIndex = 0; // 0: Thu nhập, 1: Chọn loại phí, 2: Nhập tiền từng khoản, 3: Tiền ăn/ngày
  static const int _totalQuestions = 4;

  bool _isLoading = true;
  String? _error;

  AiInitialAnalysis? _initialAnalysis;
  AiFinancialPlan? _finalPlan;
  bool _isFinalizing = false;
  bool _isApplying = false;

  // Định nghĩa các loại chi phí cố định hàng tháng phổ biến
  static const List<FixedExpenseItemDef> _fixedExpenseDefs = [
    FixedExpenseItemDef(
      key: 'rent',
      title: 'Tiền thuê trọ / nhà',
      subtitle: 'Tiền phòng trọ, căn hộ, mặt bằng định kỳ',
      icon: Icons.home_work_rounded,
      defaultValue: 2000000,
      quickOptions: [1500000, 2000000, 2500000, 3500000],
    ),
    FixedExpenseItemDef(
      key: 'utilities',
      title: 'Điện & Nước sinh hoạt',
      subtitle: 'Hóa đơn tiền điện, nước, dịch vụ phòng trọ/nhà',
      icon: Icons.bolt_rounded,
      defaultValue: 300000,
      quickOptions: [150000, 300000, 500000, 800000],
    ),
    FixedExpenseItemDef(
      key: 'internet',
      title: 'Internet & Gói 4G',
      subtitle: 'Cáp quang WiFi hoặc gói cước data di động',
      icon: Icons.wifi_rounded,
      defaultValue: 200000,
      quickOptions: [100000, 180000, 250000, 350000],
    ),
    FixedExpenseItemDef(
      key: 'vehicle',
      title: 'Xăng xe & Gửi xe đi lại',
      subtitle: 'Tiền đổ xăng xe máy, vé tháng gửi xe',
      icon: Icons.two_wheeler_rounded,
      defaultValue: 300000,
      quickOptions: [150000, 300000, 500000, 800000],
    ),
    FixedExpenseItemDef(
      key: 'education',
      title: 'Học phí & Khóa học',
      subtitle: 'Học phí trường học, trả góp khóa học IT/tiếng Anh...',
      icon: Icons.school_rounded,
      defaultValue: 1000000,
      quickOptions: [500000, 1000000, 2000000, 3000000],
    ),
    FixedExpenseItemDef(
      key: 'other',
      title: 'Chi phí cố định khác',
      subtitle: 'Bảo hiểm, phần mềm định kỳ, hỗ trợ gia đình...',
      icon: Icons.receipt_long_rounded,
      defaultValue: 500000,
      quickOptions: [200000, 500000, 1000000, 2000000],
    ),
  ];

  // Controllers cho 4 bước khảo sát
  final _incomeController = TextEditingController(text: '8.000.000');
  final Set<String> _selectedFixedKeys = {'rent', 'utilities', 'internet', 'vehicle'};
  final Map<String, TextEditingController> _fixedControllers = {};
  final _dailyFoodController = TextEditingController(text: '60.000');

  @override
  void initState() {
    super.initState();
    // Khởi tạo các controller cho từng khoản cố định
    for (final def in _fixedExpenseDefs) {
      _fixedControllers[def.key] = TextEditingController(
        text: ThousandsSeparatorInputFormatter.format(def.defaultValue),
      );
    }
    _fetchInitialAnalysis();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _dailyFoodController.dispose();
    for (final ctrl in _fixedControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// Lấy hoặc tự động khởi tạo controller an toàn (kể cả sau Hot Reload)
  TextEditingController _getFixedController(FixedExpenseItemDef def) {
    return _fixedControllers.putIfAbsent(
      def.key,
      () => TextEditingController(
        text: ThousandsSeparatorInputFormatter.format(def.defaultValue),
      ),
    );
  }

  /// Tự động tính tổng chi phí cố định từ các khoản người dùng đã chọn
  double _calculateTotalFixed() {
    double total = 0.0;
    for (final def in _fixedExpenseDefs) {
      if (_selectedFixedKeys.contains(def.key)) {
        final ctrl = _getFixedController(def);
        total += ThousandsSeparatorInputFormatter.parse(ctrl.text);
      }
    }
    return total;
  }

  /// Tự động quy đổi tiền ăn mỗi ngày ra cả tháng (nhân 30 ngày)
  double _calculateMonthlyFood() {
    final daily = ThousandsSeparatorInputFormatter.parse(_dailyFoodController.text);
    return daily * 30;
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

      final monthlyIncome = ThousandsSeparatorInputFormatter.parse(_incomeController.text);
      final foodAllowance = _calculateMonthlyFood();
      final fixedExpenses = _calculateTotalFixed();

      final fixedDetails = <Map<String, dynamic>>[];
      for (final def in _fixedExpenseDefs) {
        if (_selectedFixedKeys.contains(def.key)) {
          final ctrl = _fixedControllers[def.key];
          final amount = ThousandsSeparatorInputFormatter.parse(ctrl?.text ?? '0');
          fixedDetails.add({
            'key': def.key,
            'name': def.title,
            'amount': amount,
          });
        }
      }

      final answers = <String, dynamic>{
        'monthly_income': monthlyIncome,
        'fixed_expenses': fixedExpenses,
        'fixed_details': fixedDetails,
        'food_allowance': foodAllowance,
      };

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
                          _step == 0 ? 'Khảo sát Tài chính Thông minh' : 'Kế hoạch Ngân sách Hoàn chỉnh',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _step == 0
                              ? 'Bước 1/2: Tìm hiểu dòng tiền (${_currentQuestionIndex + 1}/$_totalQuestions)'
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
                      ? _buildLoadingState(isDark, 'Đang tính toán ngân sách tối ưu theo lựa chọn của bạn...')
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
      ),
    );
  }

  /// Nút điều hướng khảo sát Bước 0 (Tiếp tục / Câu trước / Tạo ngân sách)
  Widget _buildStep0NavigationButtons(bool isDark) {
    final isLast = _currentQuestionIndex >= _totalQuestions - 1;

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
                isLast ? 'Tạo ngân sách cá nhân hóa ngay' : 'Tiếp tục',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
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
        isLast ? 'Tạo ngân sách cá nhân hóa ngay' : 'Tiếp tục',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Bước 0: Nhận xét tài chính và hiển thị 4 câu hỏi khảo sát trực quan
  Widget _buildStep0Questionnaire(bool isDark) {
    final analysis = _initialAnalysis;
    if (analysis == null) {
      return _buildLoadingState(isDark, 'Đang tải dữ liệu khảo sát...');
    }

    final progress = (_currentQuestionIndex + 1) / _totalQuestions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // 1. Card nhận xét dòng tiền ban đầu
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
        const SizedBox(height: 18),

        // 2. Thanh tiến trình khảo sát
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Khảo sát dòng tiền thực tế',
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
                'Câu ${_currentQuestionIndex + 1} / $_totalQuestions',
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

        // 3. Card hiển thị nội dung câu hỏi tương ứng
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildCurrentQuestionCard(isDark),
        ),
      ],
    );
  }

  /// Trả về widget của câu hỏi hiện tại dựa vào `_currentQuestionIndex`
  Widget _buildCurrentQuestionCard(bool isDark) {
    switch (_currentQuestionIndex) {
      case 0:
        return _buildQuestionIncome(isDark);
      case 1:
        return _buildQuestionSelectFixedTypes(isDark);
      case 2:
        return _buildQuestionInputFixedAmounts(isDark);
      case 3:
      default:
        return _buildQuestionDailyFood(isDark);
    }
  }

  /// CÂU 1 / 4: Thu nhập hoặc tiền chu cấp dự kiến tháng này
  Widget _buildQuestionIncome(bool isDark) {
    final quickOptions = [3000000.0, 5000000.0, 8000000.0, 12000000.0, 15000000.0, 20000000.0];

    return Container(
      key: const ValueKey('q_income'),
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
            'Thu nhập hoặc tiền chu cấp dự kiến tháng này của bạn?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.35,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bao gồm lương cứng, thưởng, hỗ trợ gia đình hoặc các nguồn thu khác',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // TextField nhập số tiền
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            scrollPadding: const EdgeInsets.only(bottom: 140),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            decoration: InputDecoration(
              suffixText: 'đ',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

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
            children: quickOptions.map((opt) {
              final label = '${(opt / 1000000).toStringAsFixed(0)} triệu';
              return ActionChip(
                label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                onPressed: () {
                  _incomeController.text = ThousandsSeparatorInputFormatter.format(opt);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// CÂU 2 / 4: Tích chọn các loại chi phí cố định (Option box)
  Widget _buildQuestionSelectFixedTypes(bool isDark) {
    return Container(
      key: const ValueKey('q_select_fixed'),
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
            'Những loại phí chi tiêu hàng tháng bạn phải chi trả?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.35,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tích chọn những khoản bạn thực tế có chi trả. Nếu ở cùng gia đình và không tốn tiền trọ/điện nước, bạn hãy bỏ tích.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Nút chọn nhanh: Chọn tất cả / Bỏ chọn tất cả
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFixedKeys.addAll(_fixedExpenseDefs.map((d) => d.key));
                  });
                },
                icon: const Icon(Icons.select_all_rounded, size: 16),
                label: const Text('Chọn tất cả', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFixedKeys.clear();
                  });
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Bỏ chọn hết', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Danh sách Option Boxes
          ..._fixedExpenseDefs.map((def) {
            final isSelected = _selectedFixedKeys.contains(def.key);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFixedKeys.remove(def.key);
                  } else {
                    _selectedFixedKeys.add(def.key);
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2E1065).withOpacity(0.4) : const Color(0xFFF3E8FF))
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        def.icon,
                        size: 20,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            def.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF6B21A8))
                                  : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            def.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// CÂU 3 / 4: Nhập số tiền cụ thể cho từng khoản đã chọn (Tự động cộng dồn tổng)
  Widget _buildQuestionInputFixedAmounts(bool isDark) {
    final selectedDefs = _fixedExpenseDefs.where((d) => _selectedFixedKeys.contains(d.key)).toList();
    final totalFixed = _calculateTotalFixed();

    return Container(
      key: const ValueKey('q_input_fixed_amounts'),
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
            'Chi phí cụ thể cho từng khoản bạn đã chọn?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.35,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập số tiền cho từng khoản. Hệ thống tự động tính tổng theo thời gian thực mà không bắt bạn phải nhẩm!',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          if (selectedDefs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bạn không có khoản chi phí cố định nào (ví dụ ở cùng gia đình). Bấm "Tiếp tục" để sang câu hỏi ăn uống.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Banner tổng chi phí cố định (Tự động cộng dồn)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TỔNG CHI PHÍ CỐ ĐỊNH:',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_currencyFormatter.format(totalFixed)} / tháng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedDefs.length} khoản',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Từng khoản đã chọn với TextField và chip chọn nhanh
            ...selectedDefs.map((def) {
              final ctrl = _getFixedController(def);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(def.icon, size: 18, color: const Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            def.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      scrollPadding: const EdgeInsets.only(bottom: 140),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        suffixText: 'đ',
                        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: def.quickOptions.map((opt) {
                        final label = opt >= 1000000
                            ? '${(opt / 1000000).toStringAsFixed(opt % 1000000 == 0 ? 0 : 1)} triệu'
                            : '${(opt / 1000).toInt()}k';
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDE9FE),
                          onPressed: () {
                            ctrl.text = ThousandsSeparatorInputFormatter.format(opt);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// CÂU 4 / 4: Chi phí ăn uống mỗi ngày (Nhập theo ngày, tự quy đổi tháng)
  Widget _buildQuestionDailyFood(bool isDark) {
    final quickDailyOptions = [40000.0, 60000.0, 80000.0, 100000.0, 150000.0];
    final monthlyFood = _calculateMonthlyFood();

    return Container(
      key: const ValueKey('q_daily_food'),
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
            'Mức chi phí ăn uống trung bình mỗi ngày của bạn?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.35,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chỉ cần ước tính 1 ngày bạn ăn khoảng bao nhiêu tiền, hệ thống sẽ tự động nhân 30 ngày để tính mức ăn uống cả tháng cho bạn.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Card quy đổi ra cả tháng nổi bật
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUY ĐỔI ĂN UỐNG CẢ THÁNG (30 NGÀY):',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_currencyFormatter.format(monthlyFood)} / tháng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ô nhập số tiền mỗi ngày
          Text(
            'Số tiền ăn uống / ngày:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dailyFoodController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            scrollPadding: const EdgeInsets.only(bottom: 140),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            decoration: InputDecoration(
              suffixText: 'đ / ngày',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Chọn nhanh theo mức ăn uống mỗi ngày:',
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
            children: quickDailyOptions.map((opt) {
              final dailyK = (opt / 1000).toInt();
              final monthlyTr = (opt * 30 / 1000000).toStringAsFixed(1);
              return ActionChip(
                label: Text(
                  '${dailyK}k/ngày (~$monthlyTr tr)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                onPressed: () {
                  _dailyFoodController.text = ThousandsSeparatorInputFormatter.format(opt);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ],
      ),
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
