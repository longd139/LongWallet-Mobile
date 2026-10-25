import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RegisterSuccessScreen extends StatefulWidget {
  final String email;
  final Duration delay;

  const RegisterSuccessScreen({
    super.key,
    required this.email,
    this.delay = const Duration(seconds: 2),
  });

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    _timer = Timer(widget.delay, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final textColor = isDark ? Colors.white : AppTheme.textDark;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        _timer?.cancel();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon thành công với vòng sáng emerald
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryEmerald.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryEmerald.withOpacity(0.25),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryEmerald,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tiêu đề
                  Text(
                    'Đăng ký thành công!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mô tả
                  const Text(
                    'Tài khoản của bạn đã được khởi tạo thành công.\nHệ thống đang đưa bạn về trang đăng nhập...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Box hiển thị email vừa đăng ký
                  if (widget.email.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.cardDark : AppTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                            color: AppTheme.primaryEmerald,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.email,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Progress loading nhỏ thanh lịch (không hiển thị số giây)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút chuyển ngay nếu người dùng không muốn đợi
                  TextButton(
                    onPressed: _navigateBack,
                    child: const Text(
                      'Đăng nhập ngay',
                      style: TextStyle(
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
