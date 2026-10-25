import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'register_success_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showRegisterSuccess = false;
  String _registeredEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  bool get _isPasswordMismatch {
    if (!_isSignUp) return false;
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    return confirm.isNotEmpty && pass != confirm;
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return false;

    if (_isSignUp) {
      final fullName = _fullNameController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();
      if (fullName.isEmpty) return false;
      if (confirmPassword.isEmpty) return false;
      if (password != confirmPassword) return false;
      if (password.length < 6) return false;
    }

    return true;
  }

  void _handleSubmit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra và điền đầy đủ thông tin hợp lệ')),
      );
      return;
    }

    try {
      if (_isSignUp) {
        await auth.signUp(email, password, fullName: _fullNameController.text.trim());
        if (mounted) {
          setState(() {
            _showRegisterSuccess = true;
            _registeredEmail = email;
          });
        }
      } else {
        await auth.signIn(email, password);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showRegisterSuccess) {
      return RegisterSuccessScreen(
        email: _registeredEmail,
        onComplete: () {
          if (mounted) {
            setState(() {
              _showRegisterSuccess = false;
              _isSignUp = false;
              _emailController.text = _registeredEmail;
              _passwordController.clear();
              _confirmPasswordController.clear();
            });
          }
        },
      );
    }

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Title
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 72,
                  color: AppTheme.primaryEmerald,
                ),
                const SizedBox(height: 16),
                const Text(
                  'LongWallet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cày cuốc gom tiền – Quyết liền Winner X',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.primaryEmerald,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quản lý chi tiêu & Tự động ghi nhận biến động số dư',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 36),

                if (_isSignUp) ...[
                  TextField(
                    controller: _fullNameController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    errorText: _isSignUp &&
                            _passwordController.text.isNotEmpty &&
                            _passwordController.text.length < 6
                        ? 'Mật khẩu phải từ 6 ký tự trở lên'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                if (_isSignUp) ...[
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      errorText: _isPasswordMismatch ? 'Mật khẩu xác nhận không khớp' : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: (auth.isLoading || !_isFormValid) ? null : _handleSubmit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Đăng ký tài khoản' : 'Đăng nhập'),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Đã có tài khoản? Đăng nhập ngay'
                        : 'Chưa có tài khoản? Đăng ký ngay',
                    style: const TextStyle(color: AppTheme.primaryEmerald),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
