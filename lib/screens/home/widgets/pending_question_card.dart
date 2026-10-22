import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_theme.dart';

class PendingQuestionCard extends StatefulWidget {
  final TransactionModel transaction;
  final Function(String note) onConfirm;
  final VoidCallback onReject;

  const PendingQuestionCard({
    super.key,
    required this.transaction,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  State<PendingQuestionCard> createState() => _PendingQuestionCardState();
}

class _PendingQuestionCardState extends State<PendingQuestionCard> {
  late TextEditingController _noteController;
  String? _selectedChip;

  final List<String> _incomeOptions = [
    'Lương',
    'Thưởng',
    'Chuyển khoản',
    'Được tặng',
    'Bán đồ',
    'Thu nợ',
    'Khác',
  ];

  final List<String> _expenseOptions = [
    'Ăn uống',
    'Cà phê',
    'Mua sắm',
    'Đổ xăng',
    'Đi chợ / Siêu thị',
    'Hóa đơn',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == 'INCOME';
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final formattedAmount = currencyFormatter.format(widget.transaction.amount);

    final primaryAccent = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    final options = isIncome ? _incomeOptions : _expenseOptions;
    final questionTitle = isIncome ? 'Tiền này từ đâu?' : 'Bạn đã chi tiêu cái gì?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E), // Deep luxury navy slate
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryAccent.withOpacity(0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with question badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryAccent.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    questionTitle,
                    style: TextStyle(
                      color: primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ngân hàng',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}$formattedAmount',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryAccent,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm - dd/MM').format(widget.transaction.transactionDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),

                if (widget.transaction.rawMessage != null && widget.transaction.rawMessage!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.transaction.rawMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 14),
                Text(
                  isIncome ? 'Chọn nhanh nguồn tiền:' : 'Chọn nhanh mục chi:',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),

                // Quick chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((opt) {
                    final isSelected = _selectedChip == opt;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedChip = opt;
                          _noteController.text = opt;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryAccent
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? primaryAccent
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Note textfield
                TextField(
                  controller: _noteController,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isIncome ? 'Hoặc nhập nguồn tiền...' : 'Hoặc nhập nội dung chi tiêu...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onReject,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Bỏ qua'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final note = _noteController.text.trim().isNotEmpty
                            ? _noteController.text.trim()
                            : (_selectedChip ?? (isIncome ? 'Khoản thu' : 'Chi tiêu'));
                        widget.onConfirm(note);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: isIncome ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Xác nhận',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
