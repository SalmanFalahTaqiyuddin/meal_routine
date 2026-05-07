import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:nyobaapihehe/main.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_validateForm);
    _passCtrl.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _emailCtrl.text.isNotEmpty && _passCtrl.text.isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  void _showErrorFlushbar(String message) {
    Flushbar(
      message: message,
      icon: const Icon(Icons.error_outline, color: Colors.white, size: 20),
      backgroundColor: Colors.redAccent,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    ).show(context);
  }

  void _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.length < 6) {
      _showErrorFlushbar('Email atau kata sandi tidak valid');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.login(_emailCtrl.text, _passCtrl.text);
    setState(() => _loading = false);

    if (result['success'] == true) {
      // Sukses — langsung pindah, tidak perlu notif
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // Gagal — tampilkan error
      _showErrorFlushbar(result['message']);
    }
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_validateForm);
    _passCtrl.removeListener(_validateForm);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text('Malikah', style: theme.textTheme.displayLarge),
              const SizedBox(height: 36),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Kata sandi (6+ karakter)',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Text(
                        _showPassword ? 'Sembunyikan' : 'Tampilkan',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isFormValid && !_loading) ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? theme.primaryColor
                        : theme.primaryColor.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.primaryColor.withOpacity(
                      0.5,
                    ),
                    disabledForegroundColor: Colors.white.withOpacity(0.8),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lanjutkan'),
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Dengan mengeklik Setuju & Bergabung, Anda menyetujui ',
                  style: theme.textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: 'Perjanjian Pengguna',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: 'Kebijakan Privasi',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ', dan '),
                    TextSpan(
                      text: 'Kebijakan Cookie',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' MealRoutine.'),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Baru bergabung? ', style: theme.textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: Text(
                        'Bergabung',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
