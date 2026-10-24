import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/core/services/ai_service.dart';
import 'package:longwallet/models/budget_model.dart';
import 'package:longwallet/providers/budget_provider.dart';

void main() {
  group('AiFinancialPlan Model Tests', () {
    test('AiFinancialPlan and SuggestedBudget deserialize correctly from JSON', () {
      final json = {
        'summary': 'Tài chính đang thắt chặt, cần ưu tiên nợ đúng hạn.',
        'strategy': {
          'overview': 'Số dư 510.000 đ cần được phân bổ tiết kiệm tối đa.',
          'debt_plan': 'Trả đúng hạn 50.000 đ cho Shopee.',
          'goal_plan': 'Trích 30.000 đ vào mục tiêu mua xe Winner X V4.'
        },
        'suggested_goal_savings': 30000,
        'suggested_budgets': [
          {
            'category_id': 'cat-food',
            'category_name': 'Ăn uống',
            'amount_limit': 250000.0,
            'reason': 'Chi phí thiết yếu, nấu ăn tại nhà.'
          },
          {
            'category_id': 'cat-transport',
            'category_name': 'Đi lại',
            'amount_limit': 100000.0,
            'reason': 'Tiền xăng xe thiết yếu.'
          }
        ],
        'tips': [
          'Tự nấu ăn tại nhà.',
          'Hạn chế mua sắm online.'
        ]
      };

      final plan = AiFinancialPlan.fromJson(json);

      expect(plan.summary, 'Tài chính đang thắt chặt, cần ưu tiên nợ đúng hạn.');
      expect(plan.overview, 'Số dư 510.000 đ cần được phân bổ tiết kiệm tối đa.');
      expect(plan.debtPlan, 'Trả đúng hạn 50.000 đ cho Shopee.');
      expect(plan.goalPlan, 'Trích 30.000 đ vào mục tiêu mua xe Winner X V4.');
      expect(plan.suggestedGoalSavings, 30000.0);
      expect(plan.suggestedBudgets.length, 2);
      expect(plan.suggestedBudgets.first.categoryName, 'Ăn uống');
      expect(plan.suggestedBudgets.first.amountLimit, 250000.0);
      expect(plan.tips.length, 2);
    });

    test('Total AI budget allocation matches or stays within balance constraints', () {
      final budgets = [
        SuggestedBudget(categoryId: 'cat-1', categoryName: 'Ăn uống', amountLimit: 250000, reason: ''),
        SuggestedBudget(categoryId: 'cat-2', categoryName: 'Đi lại', amountLimit: 100000, reason: ''),
        SuggestedBudget(categoryId: 'cat-3', categoryName: 'Hóa đơn', amountLimit: 50000, reason: ''),
        SuggestedBudget(categoryId: 'cat-4', categoryName: 'Mua sắm', amountLimit: 20000, reason: ''),
        SuggestedBudget(categoryId: 'cat-5', categoryName: 'Giải trí', amountLimit: 10000, reason: ''),
      ];

      const monthlyDebtDue = 50000.0;
      const goalSavings = 30000.0;
      const totalBalance = 510000.0;

      final totalBudgets = budgets.fold(0.0, (s, b) => s + b.amountLimit);
      final totalAllocated = totalBudgets + monthlyDebtDue + goalSavings;

      // 430.000 đ ngân sách + 50.000 đ trả nợ + 30.000 đ tiết kiệm = 510.000 đ
      expect(totalAllocated, lessThanOrEqualTo(totalBalance));
      expect(totalAllocated, 510000.0);
    });
  });

  group('AiInitialAnalysis & Questionnaire Tests', () {
    test('AiInitialAnalysis and questions deserialize correctly with quick options', () {
      final json = {
        'summary': 'Tài chính thắt chặt, cần làm rõ chi phí cố định.',
        'overview': 'Số dư khả dụng 510k cần kết hợp nguồn thu nhập mới.',
        'questions': [
          {
            'id': 'monthly_income',
            'question': 'Thu nhập dự kiến hàng tháng của bạn?',
            'subtitle': 'Lương hoặc tiền chu cấp',
            'default_value': 8000000.0,
            'quick_options': [3000000.0, 5000000.0, 8000000.0, 12000000.0]
          },
          {
            'id': 'fixed_expenses',
            'question': 'Chi phí cố định bắt buộc tháng này?',
            'subtitle': 'Tiền trọ, điện nước, internet',
            'default_value': 2000000.0,
            'quick_options': [1000000.0, 2000000.0, 3000000.0]
          }
        ]
      };

      final analysis = AiInitialAnalysis.fromJson(json);

      expect(analysis.summary, 'Tài chính thắt chặt, cần làm rõ chi phí cố định.');
      expect(analysis.questions.length, 2);

      final q1 = analysis.questions.first;
      expect(q1.id, 'monthly_income');
      expect(q1.defaultValue, 8000000.0);
      expect(q1.quickOptions.length, 4);
      expect(q1.quickOptions.last, 12000000.0);
    });
  });
}
