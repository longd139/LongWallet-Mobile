import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/models/debt_model.dart';

void main() {
  group('DebtModel Serialization Tests', () {
    test('DebtModel fromJson and toJson should serialize and deserialize correctly', () {
      final now = DateTime.now();
      final model = DebtModel(
        id: 'd-1',
        userId: 'u-1',
        personName: 'Anh Nam',
        amount: 2000000,
        paidAmount: 500000,
        type: 'DEBT',
        dueDate: now.add(const Duration(days: 10)),
        isSettled: false,
        note: 'Vay đóng tiền nhà',
        createdAt: now,
      );

      final json = model.toJson();
      final fromJson = DebtModel.fromJson(json);

      expect(fromJson.id, 'd-1');
      expect(fromJson.userId, 'u-1');
      expect(fromJson.personName, 'Anh Nam');
      expect(fromJson.amount, 2000000.0);
      expect(fromJson.paidAmount, 500000.0);
      expect(fromJson.remainingAmount, 1500000.0);
      expect(fromJson.progress, 0.25);
      expect(fromJson.type, 'DEBT');
      expect(fromJson.isSettled, isFalse);
      expect(fromJson.note, 'Vay đóng tiền nhà');
    });
  });

  group('Partial Payment and Installment Logic Tests', () {
    final now = DateTime.now();

    test('Partial payment does not mark debt as settled and tracks remaining balance', () {
      // Nợ 1.000.000 đ, trả 500.000 đ -> Chưa hoàn thành, còn nợ 500.000 đ
      var debt = DebtModel(
        id: 'd-partial',
        userId: 'u-1',
        personName: 'Shopee SpayLater',
        amount: 1000000,
        paidAmount: 0,
        monthlyAmount: 500000,
        type: 'DEBT',
        isSettled: false,
        createdAt: now,
      );

      expect(debt.isSettled, isFalse);
      expect(debt.remainingAmount, 1000000.0);
      expect(debt.progress, 0.0);

      // Trả đợt 1: 500.000 đ
      final payment1 = 500000.0;
      final newPaid1 = debt.paidAmount + payment1;
      debt = debt.copyWith(
        paidAmount: newPaid1,
        isSettled: newPaid1 >= debt.amount,
      );

      expect(debt.paidAmount, 500000.0);
      expect(debt.remainingAmount, 500000.0);
      expect(debt.progress, 0.5);
      expect(debt.isSettled, isFalse, reason: 'Chưa trả đủ 1.000.000đ thì không được coi là đã xong');

      // Trả đợt 2: trả tiếp 500.000 đ nữa (đủ nợ)
      final payment2 = 500000.0;
      final newPaid2 = debt.paidAmount + payment2;
      debt = debt.copyWith(
        paidAmount: newPaid2,
        isSettled: newPaid2 >= debt.amount,
      );

      expect(debt.paidAmount, 1000000.0);
      expect(debt.remainingAmount, 0.0);
      expect(debt.progress, 1.0);
      expect(debt.isSettled, isTrue, reason: 'Đã trả đủ 1.000.000đ thì hoàn thành');
    });

    test('Overpayment or extra interest payment marks debt as settled and remaining balance is 0', () {
      // Vay 1.000.000 đ, có lãi nên tổng trả thành 1.100.000 đ
      var debt = DebtModel(
        id: 'd-interest',
        userId: 'u-1',
        personName: 'Vay tín chấp lãi',
        amount: 1000000,
        paidAmount: 0,
        type: 'DEBT',
        isSettled: false,
        createdAt: now,
      );

      // Trả 1.100.000 đ (dư 100.000 đ do lãi)
      final payment = 1100000.0;
      debt = debt.copyWith(
        paidAmount: payment,
        isSettled: payment >= debt.amount,
      );

      expect(debt.paidAmount, 1100000.0);
      expect(debt.remainingAmount, 0.0, reason: 'Dư nợ còn lại không âm');
      expect(debt.progress, 1.0, reason: 'Tiến độ clamp ở 100%');
      expect(debt.isSettled, isTrue);
    });

    test('monthlyDue caps at remainingAmount when remaining is less than monthly installment', () {
      // Nợ 1.000.000 đ, mỗi tháng trả 600.000 đ. Đã trả 600.000 đ, còn nợ 400.000 đ.
      // Kỳ tiếp theo chỉ cần trả 400.000 đ chứ không phải 600.000 đ.
      final debt = DebtModel(
        id: 'd-cap',
        userId: 'u-1',
        personName: 'Vay góp',
        amount: 1000000,
        paidAmount: 600000,
        monthlyAmount: 600000,
        type: 'DEBT',
        isSettled: false,
        createdAt: now,
      );

      expect(debt.remainingAmount, 400000.0);
      expect(debt.monthlyDue, 400000.0);
    });
  });

  group('Debt Calculation Logic Tests', () {
    final now = DateTime.now();

    final debtUnsettled1 = DebtModel(
      id: 'd-1',
      userId: 'u-1',
      personName: 'Ngân hàng',
      amount: 5000000,
      paidAmount: 1000000, // Đã trả 1 triệu -> còn 4 triệu
      type: 'DEBT',
      isSettled: false,
      createdAt: now,
    );

    final debtUnsettled2 = DebtModel(
      id: 'd-2',
      userId: 'u-1',
      personName: 'Bạn Tuấn',
      amount: 1500000,
      paidAmount: 0, // Còn 1.5 triệu
      type: 'DEBT',
      isSettled: false,
      createdAt: now,
    );

    final debtSettled = DebtModel(
      id: 'd-3',
      userId: 'u-1',
      personName: 'Chị Hoa',
      amount: 3000000,
      paidAmount: 3000000,
      type: 'DEBT',
      isSettled: true, // Đã trả
      createdAt: now,
    );

    final loanUnsettled = DebtModel(
      id: 'd-4',
      userId: 'u-1',
      personName: 'Em Hùng',
      amount: 2000000,
      paidAmount: 500000, // Đã thu 500k -> còn 1.5 triệu
      type: 'LOAN',
      isSettled: false,
      createdAt: now,
    );

    final loanSettled = DebtModel(
      id: 'd-5',
      userId: 'u-1',
      personName: 'Bác Ba',
      amount: 1000000,
      paidAmount: 1000000,
      type: 'LOAN',
      isSettled: true,
      createdAt: now,
    );

    final allItems = [debtUnsettled1, debtUnsettled2, debtSettled, loanUnsettled, loanSettled];

    test('totalDebt calculates sum of remainingAmount of active debts', () {
      final totalDebt = allItems
          .where((d) => d.type == 'DEBT' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.remainingAmount);

      // (5.000.000 - 1.000.000) + 1.500.000 = 4.000.000 + 1.500.000 = 5.500.000
      expect(totalDebt, 5500000.0);
    });

    test('totalLoan calculates sum of remainingAmount of active loans', () {
      final totalLoan = allItems
          .where((d) => d.type == 'LOAN' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.remainingAmount);

      // 2.000.000 - 500.000 = 1.500.000
      expect(totalLoan, 1500000.0);
    });

    test('settling a debt reduces totalDebt to reflect payment', () {
      final updatedDebtList = allItems.map((d) {
        if (d.id == 'd-1') {
          return d.copyWith(isSettled: true, paidAmount: d.amount);
        }
        return d;
      }).toList();

      final newTotalDebt = updatedDebtList
          .where((d) => d.type == 'DEBT' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.remainingAmount);

      // 5.500.000 - 4.000.000 = 1.500.000
      expect(newTotalDebt, 1500000.0);
    });

    test('totalMonthlyDebtDue calculates installment amount when monthlyAmount is set', () {
      final bankInstallmentDebt = DebtModel(
        id: 'd-bank',
        userId: 'u-1',
        personName: 'Vay ngân hàng MB',
        amount: 24000000, // Tổng vay 24 triệu
        monthlyAmount: 2000000, // Trả 2 triệu / tháng
        type: 'DEBT',
        isSettled: false,
        createdAt: now,
      );

      final lumpSumDebt = DebtModel(
        id: 'd-lump',
        userId: 'u-1',
        personName: 'Vay bạn',
        amount: 500000, // Trả 1 lần 500k (không có monthlyAmount)
        type: 'DEBT',
        isSettled: false,
        createdAt: now,
      );

      final debts = [bankInstallmentDebt, lumpSumDebt];
      final monthlyDue = debts
          .where((d) => d.type == 'DEBT' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.monthlyDue);

      // 2.000.000 + 500.000 = 2.500.000
      expect(monthlyDue, 2500000.0);
    });

    test('monthlyDue handles null or zero monthlyAmount safely without exception', () {
      final nullMonthlyDebt = DebtModel(
        id: 'd-null',
        userId: 'u-1',
        personName: 'Shopee',
        amount: 50000.0,
        paidAmount: 50000.0,
        monthlyAmount: null,
        type: 'DEBT',
        isSettled: false,
        createdAt: now,
      );

      expect(nullMonthlyDebt.monthlyDue, 0.0);
      expect(nullMonthlyDebt.remainingAmount, 0.0);
    });
  });
}
