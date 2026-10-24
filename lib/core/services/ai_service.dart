import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/category_model.dart';
import '../../models/debt_model.dart';
import '../constants/app_constants.dart';

class AiQuestion {
  final String id;
  final String question;
  final String subtitle;
  final double defaultValue;
  final List<double> quickOptions;

  AiQuestion({
    required this.id,
    required this.question,
    required this.subtitle,
    required this.defaultValue,
    required this.quickOptions,
  });

  factory AiQuestion.fromJson(Map<String, dynamic> json) {
    final opts = json['quick_options'] as List? ?? [];
    return AiQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      defaultValue: (json['default_value'] as num?)?.toDouble() ?? 0.0,
      quickOptions: opts.map((o) => (o as num).toDouble()).toList(),
    );
  }
}

class AiInitialAnalysis {
  final String summary;
  final String overview;
  final List<AiQuestion> questions;

  AiInitialAnalysis({
    required this.summary,
    required this.overview,
    required this.questions,
  });

  factory AiInitialAnalysis.fromJson(Map<String, dynamic> json) {
    final qList = json['questions'] as List? ?? [];
    return AiInitialAnalysis(
      summary: json['summary']?.toString() ?? '',
      overview: json['overview']?.toString() ?? '',
      questions: qList.map((q) => AiQuestion.fromJson(q as Map<String, dynamic>)).toList(),
    );
  }
}

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
  final int? estimatedMonthsToGoal;
  final double suggestedGoalSavings;
  final List<SuggestedBudget> suggestedBudgets;
  final List<String> tips;

  AiFinancialPlan({
    required this.summary,
    required this.overview,
    required this.debtPlan,
    required this.goalPlan,
    this.estimatedMonthsToGoal,
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
      estimatedMonthsToGoal: strategy['estimated_months_to_goal'] as int?,
      suggestedGoalSavings: (json['suggested_goal_savings'] as num?)?.toDouble() ?? 0.0,
      suggestedBudgets: budgetsList
          .map((b) => SuggestedBudget.fromJson(b as Map<String, dynamic>))
          .toList(),
      tips: tipsList.map((t) => t.toString()).toList(),
    );
  }
}

class AiService {
  /// Danh sách các địa chỉ backend tiềm năng (Ưu tiên Production Render Cloud, dự phòng localhost/LAN)
  static List<String> get candidateBaseUrls {
    return [
      AppConstants.backendUrl,
      if (kIsWeb) 'http://localhost:5000',
      if (!kIsWeb && Platform.isAndroid) ...[
        'http://127.0.0.1:5000',   // Điện thoại thật khi cắm cáp USB (đã cấu hình adb reverse)
        'http://10.0.2.2:5000',    // Máy ảo Android Emulator
        'http://192.168.1.7:5000', // Điện thoại thật qua Wi-Fi LAN
      ],
      if (!kIsWeb && !Platform.isAndroid) 'http://localhost:5000',
    ];
  }

  Future<dynamic> _postToBackend(String path, Map<String, dynamic> payload) async {
    dynamic lastError;

    for (final base in candidateBaseUrls) {
      final client = HttpClient();
      // Render Cloud có thể cần ~25-30 giây để đánh thức (wake up / cold start) nếu đang ngủ
      client.connectionTimeout = base.startsWith('https://')
          ? const Duration(seconds: 35)
          : const Duration(seconds: 5);

      try {
        final uri = Uri.parse('$base$path');
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

        return json['data'];
      } catch (e) {
        lastError = e;
      } finally {
        client.close();
      }
    }

    throw Exception(
      'Không thể kết nối đến máy chủ Backend (${AppConstants.backendUrl}).\n'
      'Chi tiết: $lastError\n'
      'Vui lòng kiểm tra kết nối mạng hoặc thử lại sau giây lát.',
    );
  }

  /// Bước 1: Phân tích ban đầu và lấy danh sách câu hỏi tương tác chi tiêu cố định
  Future<AiInitialAnalysis> getInitialAnalysis({
    required double totalBalance,
    required List<DebtModel> debts,
    required Map<String, dynamic>? goal,
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
    };

    final data = await _postToBackend('/api/ai/initial-analysis', payload);
    return AiInitialAnalysis.fromJson(data as Map<String, dynamic>);
  }

  /// Bước 2: Nhận câu trả lời của người dùng và lập kế hoạch ngân sách hoàn chỉnh
  Future<AiFinancialPlan> finalizeBudgetPlan({
    required double totalBalance,
    required List<DebtModel> debts,
    required Map<String, dynamic>? goal,
    required List<CategoryModel> categories,
    required Map<String, dynamic> answers,
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
      'answers': answers,
    };

    final data = await _postToBackend('/api/ai/finalize-budget', payload);
    return AiFinancialPlan.fromJson(data as Map<String, dynamic>);
  }

  /// Tương thích ngược
  Future<AiFinancialPlan> generateFinancialPlan({
    required double totalBalance,
    required List<DebtModel> debts,
    required Map<String, dynamic>? goal,
    required List<CategoryModel> categories,
  }) async {
    return finalizeBudgetPlan(
      totalBalance: totalBalance,
      debts: debts,
      goal: goal,
      categories: categories,
      answers: {},
    );
  }
}
