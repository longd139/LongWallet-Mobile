import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:longwallet/models/wallet_model.dart';
import 'package:longwallet/providers/wallet_provider.dart';
import 'package:longwallet/screens/wallets/wallets_screen.dart';

class MockWalletProvider extends ChangeNotifier implements WalletProvider {
  final List<WalletModel> _wallets;
  MockWalletProvider(this._wallets);

  @override
  List<WalletModel> get wallets => _wallets;

  @override
  bool get isLoading => false;

  @override
  WalletModel? get goalWallet => null;

  @override
  List<WalletModel> get standardWallets => _wallets;

  @override
  double get totalBalance => _wallets.fold(0, (sum, w) => sum + w.currentBalance);

  String? lastUpdatedId;
  String? lastUpdatedName;
  String? lastUpdatedAccountNumber;
  double? lastUpdatedBalance;

  @override
  Future<void> updateWallet({
    required String walletId,
    required String name,
    String? bankCode,
    String? accountNumber,
    String? packageName,
    required double currentBalance,
  }) async {
    lastUpdatedId = walletId;
    lastUpdatedName = name;
    lastUpdatedAccountNumber = accountNumber;
    lastUpdatedBalance = currentBalance;

    final idx = _wallets.indexWhere((w) => w.id == walletId);
    if (idx != -1) {
      _wallets[idx] = WalletModel(
        id: walletId,
        userId: _wallets[idx].userId,
        name: name,
        bankCode: bankCode,
        accountNumber: accountNumber,
        packageName: packageName,
        currentBalance: currentBalance,
        icon: _wallets[idx].icon,
        color: _wallets[idx].color,
      );
      notifyListeners();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Edit Wallet Interaction Tests', () {
    late List<WalletModel> testWallets;
    late MockWalletProvider mockProvider;

    setUp(() {
      testWallets = [
        WalletModel(
          id: 'w-cash',
          userId: 'u-1',
          name: 'Ví tiền mặt',
          bankCode: 'CASH',
          currentBalance: 150000,
          icon: 'wallet',
          color: '#10B981',
        ),
        WalletModel(
          id: 'w-bank',
          userId: 'u-1',
          name: 'Ngân hàng',
          bankCode: 'VCB',
          accountNumber: '9999',
          packageName: 'com.VCB',
          currentBalance: 5000000,
          icon: 'bank',
          color: '#3B82F6',
        ),
      ];
      mockProvider = MockWalletProvider(testWallets);
    });

    testWidgets('Cards display without pencil edit icon', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<WalletProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: WalletsScreen(),
          ),
        ),
      );

      // Xác minh hiển thị tên 2 ví
      expect(find.text('Ví tiền mặt'), findsOneWidget);
      expect(find.text('Ngân hàng'), findsOneWidget);
      expect(find.text('STK: 9999'), findsOneWidget);

      // Đảm bảo TUYỆT ĐỐI không có icon cây bút chì / edit báo hiệu
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.edit_note), findsNothing);
      expect(find.byIcon(Icons.mode_edit), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('Tapping on a wallet card opens edit bottom sheet with prefilled info', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<WalletProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: WalletsScreen(),
          ),
        ),
      );

      // Ấn vào Card ví Ngân hàng
      await tester.tap(find.text('Ngân hàng'));
      await tester.pumpAndSettle();

      // Xác minh bottom sheet chỉnh sửa ví mở ra
      expect(find.text('Chỉnh sửa ví'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);

      // Xác minh các trường thông tin được điền sẵn
      expect(find.widgetWithText(TextField, 'Ngân hàng'), findsOneWidget);
      expect(find.widgetWithText(TextField, '9999'), findsOneWidget);
      expect(find.widgetWithText(TextField, '5.000.000'), findsOneWidget);
    });

    testWidgets('Can edit account number and balance then save', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<WalletProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: WalletsScreen(),
          ),
        ),
      );

      // Ấn vào card ví Ngân hàng
      await tester.tap(find.text('Ngân hàng'));
      await tester.pumpAndSettle();

      // Sửa số tài khoản thành 8888
      final accountField = find.widgetWithText(TextField, '9999');
      await tester.enterText(accountField, '8888');

      // Sửa số dư thành 10000000
      final balanceField = find.widgetWithText(TextField, '5.000.000');
      await tester.enterText(balanceField, '10000000');

      await tester.pump();

      // Bấm Lưu thay đổi
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      // Modal đóng lại
      expect(find.text('Chỉnh sửa ví'), findsNothing);

      // Kiểm tra mockProvider đã nhận đúng dữ liệu mới
      expect(mockProvider.lastUpdatedId, 'w-bank');
      expect(mockProvider.lastUpdatedAccountNumber, '8888');
      expect(mockProvider.lastUpdatedBalance, 10000000.0);

      // Card trên màn hình cập nhật STK mới
      expect(find.text('STK: 8888'), findsOneWidget);
    });
  });
}
