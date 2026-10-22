import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'bank_parser_service.dart';
import 'supabase_service.dart';

class NotificationService {
  static const MethodChannel _methodChannel = MethodChannel('com.longwallet/native');
  static const EventChannel _eventChannel = EventChannel('com.longwallet/notification_stream');

  StreamSubscription? _subscription;
  final SupabaseService _supabaseService = SupabaseService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  /// Check if Android NotificationListener permission is granted
  Future<bool> isPermissionGranted() async {
    try {
      final bool isEnabled = await _methodChannel.invokeMethod('isNotificationServiceEnabled');
      return isEnabled;
    } on PlatformException {
      return false;
    }
  }

  /// Request POST_NOTIFICATIONS permission for Android 13+
  Future<void> requestPostNotificationPermission() async {
    try {
      await _methodChannel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      print('Failed to request notification permission: ${e.message}');
    }
  }

  /// Open Android Notification Access Settings
  Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      print('Failed to open settings: ${e.message}');
    }
  }

  /// Show a system notification in the phone status bar
  Future<void> showNotification({required String title, required String message}) async {
    try {
      await _methodChannel.invokeMethod('showSystemNotification', {
        'title': title,
        'message': message,
      });
    } on PlatformException catch (e) {
      print('Failed to show system notification: ${e.message}');
    }
  }

  /// Update persistent (ongoing) notification in the phone status bar
  Future<void> updateOngoingNotification({required String title, required String message}) async {
    try {
      await _methodChannel.invokeMethod('updateOngoingNotification', {
        'title': title,
        'message': message,
      });
    } on PlatformException catch (e) {
      print('Failed to update ongoing notification: ${e.message}');
    }
  }

  /// Cancel persistent notification when there are no unconfirmed transactions
  Future<void> cancelOngoingNotification() async {
    try {
      await _methodChannel.invokeMethod('cancelOngoingNotification');
    } on PlatformException catch (e) {
      print('Failed to cancel ongoing notification: ${e.message}');
    }
  }

  /// Start listening to background banking notifications
  void startListening({Function(ParsedBankTransaction)? onNewTransaction}) {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) async {
      if (event is Map) {
        final packageName = event['packageName'] as String? ?? '';
        final title = event['title'] as String? ?? '';
        final message = event['message'] as String? ?? '';
        final timestamp = (event['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

        // Parse banking notification
        final parsed = BankParserService.parseNotification(
          packageName: packageName,
          title: title,
          message: message,
          timestamp: timestamp,
        );

        if (parsed != null) {
          print('Auto-detected transaction: ${parsed.amount} VND (${parsed.type})');

          final formattedAmount = _currencyFormat.format(parsed.amount);
          final isIncome = parsed.type == 'INCOME';

          // Bắn thông báo lên thanh thông báo của điện thoại theo đúng yêu cầu:
          // + tiền: hỏi "Tiền này từ đâu?"
          // - tiền: hỏi "Bạn đã chi tiêu cái gì?"
          final notiTitle = isIncome
              ? '💰 Tiền này từ đâu? (+${formattedAmount})'
              : '💸 Bạn đã chi tiêu cái gì? (-${formattedAmount})';
          final notiMessage = isIncome
              ? 'Khoản tiền +${formattedAmount} vừa về ví. Chạm để ghi nhận nguồn tiền!'
              : 'Bạn vừa thanh toán -${formattedAmount}. Chạm để phân loại chi tiêu!';

          await showNotification(title: notiTitle, message: notiMessage);

          onNewTransaction?.call(parsed);

          // Find matching wallet by bank package or fallback to first wallet
          try {
            final wallets = await _supabaseService.getWallets();
            if (wallets.isNotEmpty) {
              final matchingWallet = wallets.firstWhere(
                (w) => w.packageName == packageName,
                orElse: () => wallets.first,
              );

              // Auto record as PENDING transaction
              await _supabaseService.createTransaction(
                walletId: matchingWallet.id,
                amount: parsed.amount,
                type: parsed.type,
                note: parsed.content,
                isAutoDetected: true,
                rawMessage: message,
                rawHash: parsed.rawHash,
                status: 'PENDING',
              );
            }
          } catch (e) {
            print('Error auto-saving transaction: $e');
          }
        }
      }
    }, onError: (error) {
      print('Notification stream error: $error');
    });
  }

  /// Simulate a bank notification (Used for instant testing & demoing)
  Future<void> simulateTransactionNotification({
    required double amount,
    required String type, // 'INCOME' or 'EXPENSE'
    String bankName = 'Vietcombank',
    String? content,
  }) async {
    final formattedAmount = _currencyFormat.format(amount);
    final isIncome = type == 'INCOME';

    final notiTitle = isIncome
        ? '💰 Tiền này từ đâu? (+${formattedAmount})'
        : '💸 Bạn đã chi tiêu cái gì? (-${formattedAmount})';
    final notiMessage = isIncome
        ? 'Khoản tiền +${formattedAmount} vừa về qua $bankName. Chạm để chọn nguồn tiền!'
        : 'Bạn vừa thanh toán -${formattedAmount} qua $bankName. Chạm để phân loại chi tiêu!';

    // 1. Bắn thông báo ngay lên thanh thông báo hệ thống của điện thoại
    await showNotification(title: notiTitle, message: notiMessage);

    // 2. Tự động lưu giao dịch PENDING vào database
    try {
      final wallets = await _supabaseService.getWallets();
      if (wallets.isNotEmpty) {
        final wallet = wallets.first;
        await _supabaseService.createTransaction(
          walletId: wallet.id,
          amount: amount,
          type: type,
          note: content ?? (isIncome ? 'Biến động số dư ($bankName)' : 'Chi tiêu ($bankName)'),
          isAutoDetected: true,
          rawMessage: '$bankName: ${isIncome ? '+' : '-'}$amount VND. $content',
          rawHash: '${DateTime.now().millisecondsSinceEpoch}_sim',
          status: 'PENDING',
        );
      }
    } catch (e) {
      print('Error simulating transaction: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
