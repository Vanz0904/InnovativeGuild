import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/stat_card.dart';
import '../auth/login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _biometric = true;
  bool _pushNotifs = true;
  bool _emailNotifs = false;
  bool _twoFactor = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
          children: [
            Text('Profile', style: AppTextStyles.displayMd),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.trustGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('CB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Chisomo Banda', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4ADE80)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('chisomo.banda@email.com', style: AppTextStyles.bodySm.copyWith(color: Colors.white.withOpacity(0.7))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                          child: Text('Trust Score 94', style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: StatCard(label: 'Total deals', value: '42', icon: Icons.handshake_rounded, accentColor: AppColors.primary)),
                const SizedBox(width: 14),
                Expanded(child: StatCard(label: 'Disputes won', value: '3/3', icon: Icons.shield_rounded, accentColor: AppColors.success)),
              ],
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Account'),
            const SizedBox(height: 12),
            _SettingsGroup(children: [
              _SettingsTile(icon: Icons.person_outline_rounded, label: 'Personal information', onTap: () {}),
              _SettingsTile(icon: Icons.account_balance_outlined, label: 'Linked bank accounts', onTap: () {}),
              _SettingsTile(icon: Icons.badge_outlined, label: 'Identity verification', trailing: _Badge(text: 'Verified', color: AppColors.success), onTap: () {}),
            ]),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Security'),
            const SizedBox(height: 12),
            _SettingsGroup(children: [
              _SettingsSwitchTile(icon: Icons.fingerprint_rounded, label: 'Biometric login', value: _biometric, onChanged: (v) => setState(() => _biometric = v)),
              _SettingsSwitchTile(icon: Icons.security_rounded, label: 'Two-factor authentication', value: _twoFactor, onChanged: (v) => setState(() => _twoFactor = v)),
              _SettingsTile(icon: Icons.password_rounded, label: 'Change password', onTap: () {}),
              _SettingsTile(icon: Icons.devices_other_rounded, label: 'Active sessions', trailing: _Badge(text: '2 devices', color: AppColors.info), onTap: () {}),
            ]),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Preferences'),
            const SizedBox(height: 12),
            _SettingsGroup(children: [
              _SettingsSwitchTile(icon: Icons.notifications_outlined, label: 'Push notifications', value: _pushNotifs, onChanged: (v) => setState(() => _pushNotifs = v)),
              _SettingsSwitchTile(icon: Icons.mail_outline_rounded, label: 'Email notifications', value: _emailNotifs, onChanged: (v) => setState(() => _emailNotifs = v)),
              _SettingsTile(icon: Icons.language_rounded, label: 'Language', trailing: const Text('English', style: TextStyle(color: AppColors.textMuted)), onTap: () {}),
            ]),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Support'),
            const SizedBox(height: 12),
            _SettingsGroup(children: [
              _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help center', onTap: () {}),
              _SettingsTile(icon: Icons.description_outlined, label: 'Terms & Privacy Policy', onTap: () {}),
              _SettingsTile(icon: Icons.info_outline_rounded, label: 'About SafeGuard', onTap: () {}),
            ]),
            const SizedBox(height: 28),
            SecondaryButton(
              label: 'Log Out',
              icon: Icons.logout_rounded,
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 14),
            Center(child: Text('SafeGuard v1.0.0', style: AppTextStyles.bodySm)),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              children[i],
              if (i != children.length - 1) const Divider(height: 1, indent: 56),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary))),
            if (trailing != null) trailing!,
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary))),
          Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: AppTextStyles.bodySm.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
