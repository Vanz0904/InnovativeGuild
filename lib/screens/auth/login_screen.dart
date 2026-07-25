import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/safeguard_logo.dart';
import '../../core/widgets/app_shell.dart';
import 'register_screen.dart';
import '../admin/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _loading = false;

  void _login() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    });
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
              Row(
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
                ],
              ),
              const SizedBox(height: 32),
              Text('Welcome back', style: AppTextStyles.displayMd),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your protected transactions',
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?', style: AppTextStyles.label.copyWith(color: AppColors.primaryLight)),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Sign In', icon: Icons.login_rounded, isLoading: _loading, onPressed: _login),
              const SizedBox(height: 16),
              SecondaryButton(
                label: 'Sign in with Face ID',
                icon: Icons.face_retouching_natural_rounded,
                onPressed: _login,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR CONTINUE WITH', style: AppTextStyles.bodySm),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _SocialButton(icon: Icons.g_mobiledata_rounded, label: 'Google')),
                  const SizedBox(width: 12),
                  Expanded(child: _SocialButton(icon: Icons.apple_rounded, label: 'Apple')),
                ],
              ),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

