import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _checkExistingUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExistingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('registered_users') ?? [];
    if (users.isEmpty) {
      setState(() => _isRegisterMode = true);
    }
    _fadeCtrl.forward();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    if (password.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('registered_users') ?? [];
    final hashedPw = _hashPassword(password);

    if (_isRegisterMode) {
      final confirm = _confirmController.text;
      if (password != confirm) {
        setState(() {
          _error = 'Passwords do not match.';
          _loading = false;
        });
        return;
      }

      if (users.contains(username)) {
        setState(() {
          _error = 'Username already taken.';
          _loading = false;
        });
        return;
      }

      users.add(username);
      await prefs.setStringList('registered_users', users);
      await prefs.setString('pw_$username', hashedPw);
      await prefs.setString('current_user', username);
      widget.onLoginSuccess();
    } else {
      if (!users.contains(username)) {
        setState(() {
          _error = 'Username not found.';
          _loading = false;
        });
        return;
      }

      final storedHash = prefs.getString('pw_$username') ?? '';
      if (storedHash != hashedPw) {
        setState(() {
          _error = 'Incorrect password.';
          _loading = false;
        });
        return;
      }

      await prefs.setString('current_user', username);
      widget.onLoginSuccess();
    }

    if (mounted) setState(() => _loading = false);
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _error = null;
      _confirmController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGlow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.accent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isRegisterMode ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegisterMode
                        ? 'Register to save your pattern history'
                        : 'Sign in to access your history',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    toggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _confirmController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirm,
                      toggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.weakColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.weakColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.weakColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppTheme.weakColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.bg,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isRegisterMode ? 'Register' : 'Sign In',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isRegisterMode
                          ? 'Already have an account? Sign In'
                          : 'Don\'t have an account? Register',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.textHint, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      onSubmitted: (_) => _handleSubmit(),
    );
  }
}
