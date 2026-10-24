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
      expect(fromJson.type, 'DEBT');
      expect(fromJson.isSettled, isFalse);
      expect(fromJson.note, 'Vay đóng tiền nhà');
    });
  });

  group('Debt Calculation Logic Tests', () {
    final now = DateTime.now();

    final debtUnsettled1 = DebtModel(
      id: 'd-1',
      userId: 'u-1',
      personName: 'Ngân hàng',
      amount: 5000000,
      type: 'DEBT',
      isSettled: false,
      createdAt: now,
    );

    final debtUnsettled2 = DebtModel(
      id: 'd-2',
      userId: 'u-1',
      personName: 'Bạn Tuấn',
      amount: 1500000,
      type: 'DEBT',
      isSettled: false,
      createdAt: now,
    );

    final debtSettled = DebtModel(
      id: 'd-3',
      userId: 'u-1',
      personName: 'Chị Hoa',
      amount: 3000000,
      type: 'DEBT',
      isSettled: true, // Đã trả
      createdAt: now,
    );

    final loanUnsettled = DebtModel(
      id: 'd-4',
      userId: 'u-1',
      personName: 'Em Hùng',
      amount: 2000000,
      type: 'LOAN',
      isSettled: false,
      createdAt: now,
    );

    final loanSettled = DebtModel(
      id: 'd-5',
      userId: 'u-1',
      personName: 'Bác Ba',
      amount: 1000000,
      type: 'LOAN',
      isSettled: true,
      createdAt: now,
    );

    final allItems = [debtUnsettled1, debtUnsettled2, debtSettled, loanUnsettled, loanSettled];

    test('totalDebt calculates sum of DEBT type that are not settled', () {
      final totalDebt = allItems
          .where((d) => d.type == 'DEBT' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.amount);

      // 5.000.000 + 1.500.000 = 6.500.000 (khoản 3.000.000 đã trả không được tính)
      expect(totalDebt, 6500000.0);
    });

    test('totalLoan calculates sum of LOAN type that are not settled', () {
      final totalLoan = allItems
          .where((d) => d.type == 'LOAN' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.amount);

      // 2.000.000 (khoản 1.000.000 đã trả không được tính)
      expect(totalLoan, 2000000.0);
    });

    test('settling a debt reduces totalDebt to reflect payment', () {
      final updatedDebtList = allItems.map((d) {
        if (d.id == 'd-1') {
          return d.copyWith(isSettled: true);
        }
        return d;
      }).toList();

      final newTotalDebt = updatedDebtList
          .where((d) => d.type == 'DEBT' && !d.isSettled)
          .fold(0.0, (sum, d) => sum + d.amount);

      // 6.500.000 - 5.000.000 = 1.500.000
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
          .fold(0.0, (sum, d) {
            final m = (d.monthlyAmount != null && d.monthlyAmount! > 0) ? d.monthlyAmount! : d.amount;
            return sum + m;
          });

      // 2.000.000 + 500.000 = 2.500.000 (thay vì 24.500.000)
      expect(monthlyDue, 2500000.0);
    });
  });
}
