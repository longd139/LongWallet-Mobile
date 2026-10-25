import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RegisterSuccessScreen extends StatefulWidget {
  final String email;
  final Duration? delay;
  final VoidCallback? onComplete;

  const RegisterSuccessScreen({
    super.key,
    required this.email,
    this.delay,
    this.onComplete,
  });

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen>
    with TickerProviderStateMixin {
  Timer? _timer;

  // Animation controllers
  late AnimationController _iconController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  late AnimationController _confettiController;
  late AnimationController _contentController;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    // 1. Icon checkmark animation (nảy đàn hồi và tỏa xung lực)
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOutCubic,
    );

    // 2. Confetti pháo giấy chúc mừng
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _initParticles();

    // 3. Nội dung chữ & email trượt nhẹ và mờ dần thành rõ
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    );
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutQuad,
    ));

    // Kích hoạt chuỗi hiệu ứng
    _iconController.forward();
    _confettiController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });

    // Chỉ tự động đóng nếu có cấu hình delay cụ thể (mặc định không tự đóng)
    if (widget.delay != null) {
      _timer = Timer(widget.delay!, () {
        if (mounted) {
          if (widget.onComplete != null) {
            widget.onComplete!();
          } else {
            Navigator.of(context).maybePop();
          }
        }
      });
    }
  }

  void _initParticles() {
    final random = math.Random();
    const colors = [
      AppTheme.primaryEmerald,
      Color(0xFF10B981),
      Color(0xFF34D399),
      Color(0xFFFBBF24), // Gold
      Color(0xFF60A5FA), // Blue
      Color(0xFFF472B6), // Pink
      Color(0xFFA78BFA), // Purple
      Color(0xFFFB923C), // Orange
    ];

    _particles = List.generate(45, (index) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 0.5 + random.nextDouble() * 0.9;
      final size = 6.0 + random.nextDouble() * 6.0;
      final color = colors[random.nextInt(colors.length)];
      final rotationSpeed = (random.nextDouble() - 0.5) * 8.0;
      final isCircle = random.nextBool();

      return _ConfettiParticle(
        angle: angle,
        speed: speed,
        size: size,
        color: color,
        rotationSpeed: rotationSpeed,
        isCircle: isCircle,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _iconController.dispose();
    _confettiController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    _timer?.cancel();
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).maybePop();
      }
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
        body: Stack(
          children: [
            // Hiệu ứng pháo giấy confetti toàn màn hình
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _confettiController.value,
                      particles: _particles,
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon thành công với hiệu ứng sóng xung kích lan tỏa (Ripple Pulse) + Nảy đàn hồi (Elastic)
                      AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Sóng xung kích ngoài 1
                                Transform.scale(
                                  scale: 0.8 + (_pulseAnimation.value * 0.9),
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryEmerald.withOpacity(
                                          (1.0 - _pulseAnimation.value) * 0.5,
                                        ),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Sóng xung kích ngoài 2
                                Transform.scale(
                                  scale: 0.6 + (_pulseAnimation.value * 0.6),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryEmerald.withOpacity(
                                        (1.0 - _pulseAnimation.value) * 0.25,
                                      ),
                                    ),
                                  ),
                                ),

                                // Vòng tròn chính và Icon Checkmark nảy bật lên
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryEmerald,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryEmerald.withOpacity(0.4),
                                          blurRadius: 28,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 52,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Phần nội dung chữ chuyển động Slide + Fade In
                      FadeTransition(
                        opacity: _contentFadeAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: Column(
                            children: [
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

                              const Text(
                                'Tài khoản của bạn đã được khởi tạo thành công.\nHãy nhấn Tiếp tục để đăng nhập vào ví của bạn.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Hộp hiển thị email vừa đăng ký
                              if (widget.email.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? AppTheme.cardDark : AppTheme.borderLight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Nút Tiếp tục để người dùng chủ động quay lại màn hình Login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _navigateBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryEmerald,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tiếp tục',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height * 0.35);
    final opacity = progress < 0.75 ? 1.0 : (1.0 - (progress - 0.75) / 0.25).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.speed * progress * math.min(size.width, size.height) * 0.65;
      final gravity = progress * progress * 90;
      final x = center.dx + math.cos(p.angle) * distance;
      final y = center.dy + math.sin(p.angle) * distance + gravity;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * math.pi);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
