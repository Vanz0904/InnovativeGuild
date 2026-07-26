import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/state/session.dart';
import '../../core/network/api_exception.dart';
import 'register_screen.dart';
import '../admin/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<Session>();
      await session.login(email, password);
      if (!mounted) return;

      if (session.currentUser!.role.name == 'admin') {
        // Regular users signing in with an admin account are still
        // routed correctly, but admins are expected to use the
        // dedicated Administrator Access screen — nudge them there
        // instead of silently dropping them into the buyer/seller UI.
        setState(() {
          _loading = false;
          _error = 'This is an administrator account. Please use "Administrator access" below.';
        });
        await session.logout();
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not reach the server. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.trustGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const SafeGuardLogo(size: 28, checkColor: AppColors.navy),
              ),
              const SizedBox(height: 32),
              Text('Welcome back', style: AppTextStyles.displayMd),
              const SizedBox(height: 8),
              Text('Sign in to manage your protected transactions', style: AppTextStyles.bodyMd),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                controller: _passwordController,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger))),
                    ],
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?', style: AppTextStyles.label.copyWith(color: AppColors.primaryLight)),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Sign In', icon: Icons.login_rounded, isLoading: _loading, onPressed: _login),
              const SizedBox(height: 28),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: AppTextStyles.bodyMd,
                    children: [
                      TextSpan(
                        text: 'Create one',
                        style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.textMuted),
                  label: Text('Administrator access', style: AppTextStyles.bodySm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
