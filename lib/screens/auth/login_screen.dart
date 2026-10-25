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
  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Sign Up Controllers
  final _fullNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  int _transitionDirection = 1; // 1: Login -> SignUp (từ phải vào), -1: SignUp -> Login (từ trái vào)

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  bool _showRegisterSuccess = false;
  String _registeredEmail = '';

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _fullNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordMismatch {
    final pass = _registerPasswordController.text;
    final confirm = _confirmPasswordController.text;
    return confirm.isNotEmpty && pass != confirm;
  }

  bool get _isLoginFormValid {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();
    return email.isNotEmpty && password.isNotEmpty;
  }

  bool get _isRegisterFormValid {
    final fullName = _fullNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      return false;
    }
    if (password != confirm) return false;
    if (password.length < 6) return false;
    return true;
  }

  void _toggleAuthMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      if (!_isSignUp) {
        _transitionDirection = 1;
        _registerEmailController.text = _loginEmailController.text;
        _registerPasswordController.text = _loginPasswordController.text;
        _confirmPasswordController.clear();
        _isSignUp = true;
      } else {
        _transitionDirection = -1;
        _loginEmailController.text = _registerEmailController.text;
        _loginPasswordController.text = _registerPasswordController.text;
        _isSignUp = false;
      }
    });
  }

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (!_isLoginFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu')),
      );
      return;
    }

    try {
      await auth.signIn(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  void _handleRegister() async {
    final auth = context.read<AuthProvider>();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (!_isRegisterFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra và điền đầy đủ thông tin hợp lệ')),
      );
      return;
    }

    try {
      await auth.signUp(email, password, fullName: fullName);
      if (mounted) {
        setState(() {
          _showRegisterSuccess = true;
          _registeredEmail = email;
        });
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
              _loginEmailController.text = _registeredEmail;
              _loginPasswordController.clear();
              _registerPasswordController.clear();
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
                const SizedBox(height: 24),

                // Animated Form Transition
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final isIncoming = (_isSignUp && child.key == const ValueKey('signup_form')) ||
                          (!_isSignUp && child.key == const ValueKey('login_form'));

                      final inOffset = Tween<Offset>(
                        begin: Offset(_transitionDirection * 0.25, 0.0),
                        end: Offset.zero,
                      );
                      final outOffset = Tween<Offset>(
                        begin: Offset(-_transitionDirection * 0.25, 0.0),
                        end: Offset.zero,
                      );

                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                        child: SlideTransition(
                          position: (isIncoming ? inOffset : outOffset).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _isSignUp
                        ? _buildSignUpForm(auth)
                        : _buildLoginForm(auth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    return Padding(
      key: const ValueKey('login_form'),
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loginEmailController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (auth.isLoading || !_isLoginFormValid) ? null : _handleLogin,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Đăng nhập'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _toggleAuthMode,
            child: const Text(
              'Chưa có tài khoản? Đăng ký ngay',
              style: TextStyle(color: AppTheme.primaryEmerald),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSignUpForm(AuthProvider auth) {
  return Padding(
    key: const ValueKey('signup_form'),
    padding: const EdgeInsets.only(top: 8.0),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          TextField(
            controller: _registerEmailController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
              ),
              errorText: _registerPasswordController.text.isNotEmpty &&
                      _registerPasswordController.text.length < 6
                  ? 'Mật khẩu phải từ 6 ký tự trở lên'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (auth.isLoading || !_isRegisterFormValid) ? null : _handleRegister,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Đăng ký tài khoản'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _toggleAuthMode,
            child: const Text(
              'Đã có tài khoản? Đăng nhập ngay',
              style: TextStyle(color: AppTheme.primaryEmerald),
            ),
          ),
        ],
      ),
    ),
  );
}
}
