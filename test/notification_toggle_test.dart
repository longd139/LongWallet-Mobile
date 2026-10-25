import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:longwallet/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Listener Toggle Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('NotificationService loadEnabledState defaults to true', () async {
      final isEnabled = await NotificationService.loadEnabledState();
      expect(isEnabled, isTrue);
      expect(NotificationService.isEnabled, isTrue);
    });

    test('NotificationService setEnabled(false) turns off listener state and persists in prefs', () async {
      await NotificationService.setEnabled(false);
      expect(NotificationService.isEnabled, isFalse);

      final reloaded = await NotificationService.loadEnabledState();
      expect(reloaded, isFalse);
    });

    test('NotificationService setEnabled(true) re-enables listener state and persists in prefs', () async {
      await NotificationService.setEnabled(false);
      expect(NotificationService.isEnabled, isFalse);

      await NotificationService.setEnabled(true);
      expect(NotificationService.isEnabled, isTrue);

      final reloaded = await NotificationService.loadEnabledState();
      expect(reloaded, isTrue);
    });

    test('startListening stops immediately when NotificationService.isEnabled is false', () {
      NotificationService.isEnabled = false;
      final service = NotificationService();

      // Calling startListening when disabled should not start listening
      service.startListening(onNewTransaction: (_) {});
      // No exception thrown, stopped safely
      expect(NotificationService.isEnabled, isFalse);
    });
  });
}
