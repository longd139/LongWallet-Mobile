import 'package:flutter/services.dart';

/// Formatter tự động chèn dấu chấm (.) ngăn cách hàng nghìn khi người dùng gõ số tiền
/// Ví dụ: 30000 -> 30.000, 50000000 -> 50.000.000
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  /// Format chuỗi số nguyên hoặc số thành định dạng có dấu chấm (e.g. 50000000 -> 50.000.000)
  static String format(dynamic value) {
    if (value == null) return '';
    String raw = value.toString();
    if (raw.contains('.')) {
      raw = raw.split('.').first;
    }
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Parse chuỗi có dấu chấm/phẩy/ký hiệu tiền tệ thành số double an toàn
  static double parse(String? text, {double defaultValue = 0.0}) {
    if (text == null || text.trim().isEmpty) return defaultValue;
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digits) ?? defaultValue;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Chỉ giữ lại chữ số
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Định dạng thêm dấu chấm (.) mỗi 3 chữ số từ phải sang trái
    final buffer = StringBuffer();
    final len = digitsOnly.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();

    // Giữ vị trí con trỏ thông minh dựa trên số lượng chữ số nằm trước con trỏ
    int digitsBeforeCursor = 0;
    final cursorEnd = newValue.selection.end.clamp(0, newValue.text.length);
    for (int i = 0; i < cursorEnd; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    int newCursorPos = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newCursorPos = i + 1;
        break;
      }
    }
    if (digitCount < digitsBeforeCursor) {
      newCursorPos = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formatted.length),
      ),
    );
  }
}
