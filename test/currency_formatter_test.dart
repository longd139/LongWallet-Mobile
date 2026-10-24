import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/core/utils/currency_input_formatter.dart';

void main() {
  group('ThousandsSeparatorInputFormatter Static Tests', () {
    test('format correctly adds dot separators for thousands', () {
      expect(ThousandsSeparatorInputFormatter.format('500'), '500');
      expect(ThousandsSeparatorInputFormatter.format('1000'), '1.000');
      expect(ThousandsSeparatorInputFormatter.format('30000'), '30.000');
      expect(ThousandsSeparatorInputFormatter.format('1500000'), '1.500.000');
      expect(ThousandsSeparatorInputFormatter.format('50000000'), '50.000.000');
      expect(ThousandsSeparatorInputFormatter.format(50000000), '50.000.000');
      expect(ThousandsSeparatorInputFormatter.format(''), '');
      expect(ThousandsSeparatorInputFormatter.format(null), '');
    });

    test('parse correctly parses dotted and comma separated amounts into double', () {
      expect(ThousandsSeparatorInputFormatter.parse('30.000'), 30000.0);
      expect(ThousandsSeparatorInputFormatter.parse('50.000.000'), 50000000.0);
      expect(ThousandsSeparatorInputFormatter.parse('50,000,000'), 50000000.0);
      expect(ThousandsSeparatorInputFormatter.parse('1.500.000 đ'), 1500000.0);
      expect(ThousandsSeparatorInputFormatter.parse(''), 0.0);
      expect(ThousandsSeparatorInputFormatter.parse(null), 0.0);
    });
  });

  group('ThousandsSeparatorInputFormatter TextInputFormatter Tests', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('formatEditUpdate formats input with dots while typing', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(
        text: '30000',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '30.000');
      expect(result.selection.end, 6);
    });

    test('formatEditUpdate adds dot as user types additional digits', () {
      const oldValue = TextEditingValue(
        text: '30.000',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: '30.0000',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '300.000');
      expect(result.selection.end, 7);
    });

    test('formatEditUpdate handles empty or cleared input gracefully', () {
      const oldValue = TextEditingValue(text: '30.000');
      const newValue = TextEditingValue(text: '');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '');
      expect(result.selection.end, 0);
    });

    test('formatEditUpdate filters out non-digit characters', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(
        text: '30abc000',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, '30.000');
    });
  });
}
