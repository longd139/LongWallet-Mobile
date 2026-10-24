import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/debt_model.dart';
import '../../providers/debt_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_input_formatter.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().fetchDebts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDebtDialog(BuildContext context, {String defaultType = 'DEBT'}) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? selectedDueDate;
    String selectedType = defaultType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Text(
                    'Thêm ghi chép nợ mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loại nợ: Tôi nợ / Cho vay
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'DEBT'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'DEBT'
                                    ? const Color(0xFFEF4444)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Tôi nợ (Đi vay)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: selectedType == 'DEBT'
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'LOAN'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'LOAN'
                                    ? AppTheme.primaryEmerald
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Cho vay (Cần đòi)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: selectedType == 'LOAN'
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: selectedType == 'DEBT' ? 'Nợ ai (Chủ nợ)' : 'Cho ai vay (Người mượn)',
                      hintText: 'Ví dụ: Anh Nam, Ngân hàng, Bạn Tuấn...',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selectedType == 'DEBT' ? const Color(0xFFEF4444) : AppTheme.primaryEmerald,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Số tiền (VNĐ)',
                      hintText: '1.000.000',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Chọn hạn trả nợ (DatePicker)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedDueDate != null
                                ? 'Hạn trả: ${DateFormat('dd/MM/yyyy').format(selectedDueDate!)}'
                                : 'Chọn hạn trả nợ (Không bắt buộc)',
                            style: TextStyle(
                              color: selectedDueDate != null
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (selectedDueDate != null)
                            GestureDetector(
                              onTap: () => setModalState(() => selectedDueDate = null),
                              child: const Icon(Icons.close, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: noteCtrl,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      hintText: 'Mượn tiền đóng bảo hiểm, tiền trọ...',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final amount = ThousandsSeparatorInputFormatter.parse(amountCtrl.text);

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập tên người nợ / người cho vay')),
                        );
                        return;
                      }

                      if (amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
                        );
                        return;
                      }

                      await context.read<DebtProvider>().addDebt(
                        personName: name,
                        amount: amount,
                        type: selectedType,
                        dueDate: selectedDueDate,
                        note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(selectedType == 'DEBT'
                                ? 'Đã thêm khoản nợ cần trả!'
                                : 'Đã thêm khoản cho vay!'),
                            backgroundColor: selectedType == 'DEBT'
                                ? const Color(0xFFEF4444)
                                : AppTheme.primaryEmerald,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType == 'DEBT'
                          ? const Color(0xFFEF4444)
                          : AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Lưu khoản nợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = context.watch<DebtProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ nợ chi tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm ghi chép nợ',
            onPressed: () => _showAddDebtDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // 1. Tôi nợ
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(isDark ? 0.4 : 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFFEF4444)),
                            SizedBox(width: 4),
                            Text(
                              'Tôi nợ (Cần trả)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormatter.format(debtProvider.totalDebt),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Cho vay
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withOpacity(isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryEmerald.withOpacity(isDark ? 0.4 : 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 14, color: AppTheme.primaryEmerald),
                            SizedBox(width: 4),
                            Text(
                              'Cho vay (Cần thu)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormatter.format(debtProvider.totalLoan),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: const Color(0xFFEF4444),
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tôi nợ'),
                    const SizedBox(width: 6),
                    _buildBadge(debtProvider.myDebts.where((d) => !d.isSettled).length, const Color(0xFFEF4444)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Cho vay'),
                    const SizedBox(width: 6),
                    _buildBadge(debtProvider.myLoans.where((d) => !d.isSettled).length, AppTheme.primaryEmerald),
                  ],
                ),
              ),
            ],
          ),

          // Tab views
          Expanded(
            child: debtProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Tôi nợ
                      _buildDebtList(debtProvider.myDebts, isDark, currencyFormatter, isDebt: true),

                      // Tab 2: Cho vay
                      _buildDebtList(debtProvider.myLoans, isDark, currencyFormatter, isDebt: false),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtDialog(
          context,
          defaultType: _tabController.index == 0 ? 'DEBT' : 'LOAN',
        ),
        backgroundColor: _tabController.index == 0 ? const Color(0xFFEF4444) : AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Thêm khoản nợ' : 'Thêm cho vay'),
      ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildDebtList(
    List<DebtModel> list,
    bool isDark,
    NumberFormat currencyFormatter, {
    required bool isDebt,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDebt ? Icons.check_circle_outline_rounded : Icons.savings_outlined,
              size: 54,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isDebt ? 'Bạn hiện không có khoản nợ nào!' : 'Chưa có khoản cho vay nào!',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isSettled = item.isSettled;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSettled
                          ? Colors.grey.withOpacity(0.2)
                          : (isDebt
                              ? const Color(0xFFEF4444).withOpacity(0.18)
                              : AppTheme.primaryEmerald.withOpacity(0.18)),
                      child: Icon(
                        isDebt ? Icons.person_rounded : Icons.handshake_rounded,
                        color: isSettled
                            ? Colors.grey
                            : (isDebt ? const Color(0xFFEF4444) : AppTheme.primaryEmerald),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.personName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isSettled ? TextDecoration.lineThrough : null,
                              color: isSettled
                                  ? AppTheme.textMuted
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(item.amount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isSettled ? TextDecoration.lineThrough : null,
                            color: isSettled
                                ? AppTheme.textMuted
                                : (isDebt ? const Color(0xFFEF4444) : AppTheme.primaryEmerald),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSettled
                                ? Colors.grey.withOpacity(0.15)
                                : (isDebt
                                    ? const Color(0xFFEF4444).withOpacity(0.12)
                                    : AppTheme.primaryEmerald.withOpacity(0.12)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSettled ? 'Đã xong' : 'Chưa trả',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSettled
                                  ? Colors.grey
                                  : (isDebt ? const Color(0xFFEF4444) : AppTheme.primaryEmerald),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (item.dueDate != null || (item.note != null && item.note!.isNotEmpty)) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      if (item.dueDate != null) ...[
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hạn: ${DateFormat('dd/MM/yyyy').format(item.dueDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (item.note != null && item.note!.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.note!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.read<DebtProvider>().toggleSettle(item),
                      icon: Icon(
                        isSettled ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: isSettled ? Colors.grey : AppTheme.primaryEmerald,
                      ),
                      label: Text(
                        isSettled ? 'Đánh dấu chưa trả' : 'Đã thanh toán',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSettled ? Colors.grey : AppTheme.primaryEmerald,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                      tooltip: 'Xóa khoản nợ',
                      onPressed: () => _confirmDeleteDebt(context, item.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteDebt(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bản ghi nợ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DebtProvider>().deleteDebt(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
