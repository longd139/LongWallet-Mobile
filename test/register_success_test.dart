import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/screens/auth/register_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterSuccessScreen Widget Tests', () {
    testWidgets('Displays success message and registered email correctly', (tester) async {
      const testEmail = 'nguyenvanlong@example.com';

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterSuccessScreen(
            email: testEmail,
            delay: Duration(seconds: 10),
          ),
        ),
      );

      // Animation 600ms
      await tester.pump(const Duration(milliseconds: 600));

      // Xác minh hiển thị tiêu đề và email
      expect(find.text('Đăng ký thành công!'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);

      // Xác minh KHÔNG hiển thị thời gian hay số giây đếm ngược
      expect(find.textContaining(RegExp(r'\b\d+\s*s\b|\b\d+\s*giây\b', caseSensitive: false)), findsNothing);
    });

    testWidgets('Automatically pops after specified delay', (tester) async {
      const testEmail = 'longtest@gmail.com';
      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterSuccessScreen(
                        email: testEmail,
                        delay: Duration(seconds: 2),
                      ),
                    ),
                  );
                  didPop = true;
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      // Nhấn mở RegisterSuccessScreen
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Đăng ký thành công!'), findsOneWidget);
      expect(didPop, isFalse);

      // Chờ sau 2 giây cho Timer fire
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Màn hình đã tự động pop quay về trang ban đầu
      expect(didPop, isTrue);
      expect(find.text('Đăng ký thành công!'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('Pops immediately when "Đăng nhập ngay" button is pressed', (tester) async {
      const testEmail = 'longtest@gmail.com';
      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterSuccessScreen(
                        email: testEmail,
                        delay: Duration(seconds: 10),
                      ),
                    ),
                  );
                  didPop = true;
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      // Mở màn hình
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Đăng ký thành công!'), findsOneWidget);

      // Nhấn nút "Đăng nhập ngay"
      await tester.tap(find.text('Đăng nhập ngay'));
      await tester.pumpAndSettle();

      // Màn hình pop ngay
      expect(didPop, isTrue);
      expect(find.text('Đăng ký thành công!'), findsNothing);
    });
  });
}
