import 'dart:async';
import 'package:flutter/services.dart';
import 'bank_parser_service.dart';
import 'supabase_service.dart';

class NotificationService {
  static const MethodChannel _methodChannel = MethodChannel('com.longwallet/native');
  static const EventChannel _eventChannel = EventChannel('com.longwallet/notification_stream');

  StreamSubscription? _subscription;
  final SupabaseService _supabaseService = SupabaseService();

  /// Check if Android NotificationListener permission is granted
  Future<bool> isPermissionGranted() async {
    try {
      final bool isEnabled = await _methodChannel.invokeMethod('isNotificationServiceEnabled');
      return isEnabled;
    } on PlatformException {
      return false;
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

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
