import 'dart:convert';
import 'package:crypto/crypto.dart';

class ParsedBankTransaction {
  final double amount;
  final String type; // INCOME or EXPENSE
  final String? accountNumber;
  final String content;
  final String rawHash;
  final String? suggestedCategory;

  ParsedBankTransaction({
    required this.amount,
    required this.type,
    this.accountNumber,
    required this.content,
    required this.rawHash,
    this.suggestedCategory,
  });
}

class BankParserService {
  /// Generate SHA-256 hash to prevent duplicate bank notification processing
  static String generateRawHash(String packageName, String message, int timestamp) {
    final raw = '$packageName|$message|$timestamp';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Parse incoming Vietnamese banking / wallet push notifications
  static ParsedBankTransaction? parseNotification({
    required String packageName,
    required String title,
    required String message,
    required int timestamp,
  }) {
    final cleanText = message.replaceAll(',', '').replaceAll('.', '');
    
    // 1. Detect transaction type (+ or -)
    String type = 'EXPENSE';
    if (message.contains('+') || 
        message.toLowerCase().contains('nhan tien') || 
        message.toLowerCase().contains('nap tien') ||
        message.toLowerCase().contains('cong vao')) {
      type = 'INCOME';
    } else if (message.contains('-') || 
               message.toLowerCase().contains('thanh toan') || 
               message.toLowerCase().contains('chuyen tien') ||
               message.toLowerCase().contains('tru tien')) {
      type = 'EXPENSE';
    }

    // 2. Extract Amount (e.g. 50,000 VND, 50000d, 1,200,000VND)
    final amountRegex = RegExp(r'([+-]?\s*\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:VND|d|đ)', caseSensitive: false);
    final match = amountRegex.firstMatch(message);
    
    double amount = 0;
    if (match != null) {
      final rawNum = match.group(1)!
          .replaceAll('+', '')
          .replaceAll('-', '')
          .replaceAll(' ', '')
          .replaceAll(',', '')
          .replaceAll('.', '');
      amount = double.tryParse(rawNum) ?? 0;
    }

    if (amount <= 0) {
      // Fallback: look for any number before VND
      final fallbackRegex = RegExp(r'(\d+)\s*(?:VND|d|đ)', caseSensitive: false);
      final fbMatch = fallbackRegex.firstMatch(cleanText);
      if (fbMatch != null) {
        amount = double.tryParse(fbMatch.group(1)!) ?? 0;
      }
    }

    if (amount <= 0) return null; // Not a monetary notification

    // 3. Extract Account Number (e.g. TK 0123456789, thẻ ...1234)
    String? accountNumber;
    final accRegex = RegExp(r'(?:TK|tai khoan|the|so du)\s*[:#]?\s*(\d{4,16})', caseSensitive: false);
    final accMatch = accRegex.firstMatch(message);
    if (accMatch != null) {
      accountNumber = accMatch.group(1);
    }

    // 4. Extract Content / Note (ND: ... or Ref: ...)
    String content = title.isNotEmpty ? '$title - $message' : message;
    final noteRegex = RegExp(r'(?:ND|Noi dung|Ref|Ly do)\s*[:]\s*(.+?)(?:\.|$)', caseSensitive: false);
    final noteMatch = noteRegex.firstMatch(message);
    if (noteMatch != null) {
      content = noteMatch.group(1)!.trim();
    }

    // 5. Suggest Category based on Vietnamese keywords
    final suggestedCategory = suggestCategory(content);

    // 6. Generate anti-duplicate hash
    final rawHash = generateRawHash(packageName, message, timestamp);

    return ParsedBankTransaction(
      amount: amount,
      type: type,
      accountNumber: accountNumber,
      content: content,
      rawHash: rawHash,
      suggestedCategory: suggestedCategory,
    );
  }

  /// Auto classify category from message keywords
  static String? suggestCategory(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains('grab') || lower.contains('be group') || lower.contains('xanh sm') || 
        lower.contains('gojek') || lower.contains('petro') || lower.contains('xang')) {
      return 'Di chuyển';
    }
    if (lower.contains('highland') || lower.contains('coffee') || lower.contains('cafe') || 
        lower.contains('tea') || lower.contains('phuc long') || lower.contains('pho') || 
        lower.contains('kfc') || lower.contains('shopeefood') || lower.contains('baemin')) {
      return 'Ăn uống';
    }
    if (lower.contains('shopee') || lower.contains('tiki') || lower.contains('lazada') || 
        lower.contains('tiktok') || lower.contains('circle k') || lower.contains('winmart')) {
      return 'Mua sắm';
    }
    if (lower.contains('dien') || lower.contains('evn') || lower.contains('nuoc') || 
        lower.contains('internet') || lower.contains('viettel') || lower.contains('fpt')) {
      return 'Hóa đơn & Tiện ích';
    }
    if (lower.contains('luong') || lower.contains('salary') || lower.contains('payroll')) {
      return 'Lương';
    }

    return null;
  }
}
