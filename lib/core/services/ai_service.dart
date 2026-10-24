import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/category_model.dart';
import '../../models/debt_model.dart';
import '../constants/app_constants.dart';

class SuggestedBudget {
  final String categoryId;
  final String categoryName;
  double amountLimit;
  final String reason;

  SuggestedBudget({
    required this.categoryId,
    required this.categoryName,
    required this.amountLimit,
    required this.reason,
  });

  factory SuggestedBudget.fromJson(Map<String, dynamic> json) {
    return SuggestedBudget(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      amountLimit: (json['amount_limit'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': categoryName,
        'amount_limit': amountLimit,
        'reason': reason,
      };
}

class AiFinancialPlan {
  final String summary;
  final String overview;
  final String debtPlan;
  final String goalPlan;
  final double suggestedGoalSavings;
  final List<SuggestedBudget> suggestedBudgets;
  final List<String> tips;

  AiFinancialPlan({
    required this.summary,
    required this.overview,
    required this.debtPlan,
    required this.goalPlan,
    required this.suggestedGoalSavings,
    required this.suggestedBudgets,
    required this.tips,
  });

  factory AiFinancialPlan.fromJson(Map<String, dynamic> json) {
    final strategy = json['strategy'] as Map<String, dynamic>? ?? {};
    final budgetsList = json['suggested_budgets'] as List? ?? [];
    final tipsList = json['tips'] as List? ?? [];

    return AiFinancialPlan(
      summary: json['summary']?.toString() ?? '',
      overview: strategy['overview']?.toString() ?? '',
      debtPlan: strategy['debt_plan']?.toString() ?? '',
      goalPlan: strategy['goal_plan']?.toString() ?? '',
      suggestedGoalSavings: (json['suggested_goal_savings'] as num?)?.toDouble() ?? 0.0,
      suggestedBudgets: budgetsList
          .map((b) => SuggestedBudget.fromJson(b as Map<String, dynamic>))
          .toList(),
      tips: tipsList.map((t) => t.toString()).toList(),
    );
  }
}

class AiService {
  /// Danh sách các địa chỉ backend tiềm năng (Điện thoại thật qua USB/LAN, Máy ảo Emulator, Web/Desktop)
  static List<String> get candidateBaseUrls {
    if (kIsWeb) {
      return ['http://localhost:5000'];
    }
    if (Platform.isAndroid) {
      return [
        'http://127.0.0.1:5000',   // Điện thoại thật khi cắm cáp USB (đã cấu hình adb reverse)
        'http://192.168.1.7:5000', // Điện thoại thật qua chung mạng Wi-Fi
        'http://10.0.2.2:5000',    // Máy ảo Android Emulator
      ];
    }
    return ['http://localhost:5000'];
  }

  /// Gửi dữ liệu tài chính lên backend để Gemini AI phân tích và lập kế hoạch ngân sách
  Future<AiFinancialPlan> generateFinancialPlan({
    required double totalBalance,
    required List<DebtModel> debts,
    required Map<String, dynamic>? goal,
    required List<CategoryModel> categories,
  }) async {
    final payload = {
      'totalBalance': totalBalance,
      'debts': debts.map((d) => {
        'personName': d.personName,
        'amount': d.amount,
        'paidAmount': d.paidAmount,
        'remainingAmount': d.remainingAmount,
        'monthlyDue': d.monthlyDue,
        'dueDate': d.dueDate?.toIso8601String(),
      }).toList(),
      'goal': goal,
      'categories': categories.map((c) => {
        'id': c.id,
        'name': c.name,
      }).toList(),
    };

    dynamic lastError;

    for (final base in candidateBaseUrls) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      try {
        final uri = Uri.parse('$base/api/ai/financial-plan');
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode != 200) {
          throw Exception('Lỗi từ AI Server (${response.statusCode}): $responseBody');
        }

        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        if (json['success'] != true || json['data'] == null) {
          throw Exception(json['error'] ?? 'Không nhận được dữ liệu hợp lệ từ AI');
        }

        return AiFinancialPlan.fromJson(json['data'] as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
        // Tiếp tục thử URL tiếp theo trong danh sách candidateBaseUrls
      } finally {
        client.close();
      }
    }

    throw Exception(
      'Không thể kết nối đến máy chủ Backend (${candidateBaseUrls.join(", ")}).\n'
      'Chi tiết: $lastError\n'
      'Vui lòng đảm bảo backend đang chạy tại cổng 5000.',
    );
  }
}
