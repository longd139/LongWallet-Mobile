import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:longwallet/screens/auth/login_screen.dart';
import 'package:longwallet/providers/auth_provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoading = false;

  @override
  User? get user => null;

  @override
  bool get isAuthenticated => false;

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp(String email, String password, {String? fullName}) async {}

  @override
  Future<void> signOut() async {}

  @override
  void resetSigningUpState() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Login to Register Smooth Transition Tests', () {
    testWidgets('Toggling between Login and Register transitions smoothly without errors', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockAuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      // Ban đầu ở giao diện Đăng nhập
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Chưa có tài khoản? Đăng ký ngay'), findsOneWidget);
      expect(find.text('Họ và tên'), findsNothing);
      expect(find.text('Xác nhận mật khẩu'), findsNothing);

      // Điền email và password
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      // Bấm chuyển sang giao diện Đăng ký
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký ngay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160)); // Giữa transition
      await tester.pump(const Duration(milliseconds: 200)); // Hoàn thành transition

      // Đã chuyển sang giao diện Đăng ký
      expect(find.text('Đăng ký tài khoản'), findsOneWidget);
      expect(find.text('Đã có tài khoản? Đăng nhập ngay'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);

      // Email và password được giữ nguyên mượt mà
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);

      // Bấm chuyển ngược lại giao diện Đăng nhập
      await tester.tap(find.text('Đã có tài khoản? Đăng nhập ngay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      await tester.pump(const Duration(milliseconds: 200));

      // Đã quay về giao diện Đăng nhập
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Chưa có tài khoản? Đăng ký ngay'), findsOneWidget);
      expect(find.text('Họ và tên'), findsNothing);
      expect(find.text('Xác nhận mật khẩu'), findsNothing);
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
