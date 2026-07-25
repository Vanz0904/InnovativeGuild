import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0;
  bool _loading = false;
  bool _agree = false;

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      setState(() => _loading = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_step == 0) {
              Navigator.pop(context);
            } else {
              setState(() => _step--);
            }
          },
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(3, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      height: 5,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _stepContent(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: _step < 2 ? 'Continue' : 'Verify & Create Account',
                icon: _step < 2 ? Icons.arrow_forward_rounded : Icons.verified_user_rounded,
                isLoading: _loading,
                onPressed: (_step == 2 && !_agree) ? null : _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _PersonalDetailsStep(key: const ValueKey('s0'));
      case 1:
        return _SecurityStep(key: const ValueKey('s1'));
      default:
        return _VerificationStep(
          key: const ValueKey('s2'),
          agree: _agree,
          onAgreeChanged: (v) => setState(() => _agree = v),
        );
    }
  }
}

class _PersonalDetailsStep extends StatelessWidget {
  const _PersonalDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal details', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Tell us a bit about yourself to get started', style: AppTextStyles.bodyMd),
        const SizedBox(height: 26),
        const CustomTextField(label: 'Full name', hint: 'Chisomo Banda', icon: Icons.person_outline_rounded),
        const SizedBox(height: 18),
        const CustomTextField(label: 'Email address', hint: 'you@example.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 18),
        const CustomTextField(label: 'Phone number', hint: '+265 99 123 4567', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
      ],
    );
  }
}

class _SecurityStep extends StatefulWidget {
  const _SecurityStep({super.key});

  @override
  State<_SecurityStep> createState() => _SecurityStepState();
}

class _SecurityStepState extends State<_SecurityStep> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Secure your account', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('Choose a strong password to protect your funds', style: AppTextStyles.bodyMd),
        const SizedBox(height: 26),
        CustomTextField(
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure1,
          suffix: IconButton(
            icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
            onPressed: () => setState(() => _obscure1 = !_obscure1),
          ),
          helperText: 'Use 8+ characters with a mix of letters, numbers & symbols',
        ),
        const SizedBox(height: 18),
        CustomTextField(
          label: 'Confirm password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure2,
          suffix: IconButton(
            icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StrengthBar(color: AppColors.success),
            const SizedBox(width: 6),
            _StrengthBar(color: AppColors.success),
            const SizedBox(width: 6),
            _StrengthBar(color: AppColors.success),
            const SizedBox(width: 6),
            _StrengthBar(color: AppColors.border),
          ],
        ),
        const SizedBox(height: 8),
        Text('Strong password', style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final Color color;
  const _StrengthBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final bool agree;
  final ValueChanged<bool> onAgreeChanged;

  const _VerificationStep({super.key, required this.agree, required this.onAgreeChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Identity verification', style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text('SafeGuard verifies every user to keep the marketplace fraud-free', style: AppTextStyles.bodyMd),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.trustGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              Text('Upload a government ID', style: AppTextStyles.h3.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                'National ID, passport, or driver\'s license',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.75)),
              ),
              const SizedBox(height: 16),
              SecondaryButton(label: 'Choose document', icon: Icons.upload_file_rounded, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.skyTint, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selfie verification', style: AppTextStyles.h3),
                    const SizedBox(height: 3),
                    Text('Confirms you match your ID', style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SecurityInfoBanner(
          text: 'Your documents are encrypted end-to-end and reviewed only for identity verification, never shared with other users.',
          icon: Icons.enhanced_encryption_rounded,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Checkbox(
              value: agree,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (v) => onAgreeChanged(v ?? false),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: AppTextStyles.bodySm,
                  children: [
                    TextSpan(text: 'Terms of Service', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
