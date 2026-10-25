import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/screens/auth/register_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisterSuccessScreen Widget Tests', () {
    testWidgets('Displays success message, registered email, and Continue button', (tester) async {
      const testEmail = 'nguyenvanlong@example.com';

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterSuccessScreen(
            email: testEmail,
          ),
        ),
      );

      // Animation 600ms
      await tester.pump(const Duration(milliseconds: 600));

      // Xác minh hiển thị tiêu đề, email, nút Tiếp tục
      expect(find.text('Đăng ký thành công!'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Xác minh KHÔNG hiển thị thời gian hay số giây đếm ngược
      expect(find.textContaining(RegExp(r'\b\d+\s*s\b|\b\d+\s*giây\b', caseSensitive: false)), findsNothing);
    });

    testWidgets('Stays on screen without auto-closing when delay is not set', (tester) async {
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
      expect(didPop, isFalse);

      // Chờ qua 5 giây
      await tester.pump(const Duration(seconds: 5));

      // Vẫn ở trên màn hình, không tự động đóng
      expect(didPop, isFalse);
      expect(find.text('Đăng ký thành công!'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('Pops and returns when "Tiếp tục" button is pressed', (tester) async {
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
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Nhấn nút "Tiếp tục"
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Màn hình pop quay lại
      expect(didPop, isTrue);
      expect(find.text('Đăng ký thành công!'), findsNothing);
    });

    testWidgets('Triggers onComplete callback directly when "Tiếp tục" is pressed', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterSuccessScreen(
            email: 'oncomplete@test.com',
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(completed, isFalse);

      // Nhấn nút "Tiếp tục"
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(completed, isTrue);
    });
  });
}
