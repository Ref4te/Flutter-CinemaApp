import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/app_settings.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      print("User signed out successfully");
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1D1D1D) : Colors.white;
    final secondaryTextColor =
    isDark ? const Color(0xFF9A9A9A) : const Color(0xFF6B7280);
    final primaryTextColor =
    isDark ? Colors.white : const Color(0xFF1F2937);

    final User? user = FirebaseAuth.instance.currentUser;

    final String login = (user?.email?.split('@').first?.trim().isNotEmpty ?? false)
        ? user!.email!.split('@').first
        : 'guest';
    final String email = user?.email ?? 'No email provided';

    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, language, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.t('profile')),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE53935),
                      child: Icon(
                        Icons.person,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      login,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _ProfileActionTile(
                icon: Icons.manage_accounts_outlined,
                title: AppStrings.t('profile_settings'),
                subtitle: AppStrings.t('profile_settings_sub'),
                cardColor: cardColor,
                textColor: primaryTextColor,
                subColor: secondaryTextColor,
              ),
              _ProfileActionTile(
                icon: Icons.security_outlined,
                title: AppStrings.t('security'),
                subtitle: AppStrings.t('security_sub'),
                cardColor: cardColor,
                textColor: primaryTextColor,
                subColor: secondaryTextColor,
              ),
              _ProfileActionTile(
                icon: Icons.payment_outlined,
                title: AppStrings.t('payment_methods'),
                subtitle: AppStrings.t('payment_methods_sub'),
                cardColor: cardColor,
                textColor: primaryTextColor,
                subColor: secondaryTextColor,
              ),
              _ProfileActionTile(
                icon: Icons.support_agent_outlined,
                title: AppStrings.t('support'),
                subtitle: AppStrings.t('support_sub'),
                cardColor: cardColor,
                textColor: primaryTextColor,
                subColor: secondaryTextColor,
              ),

              const SizedBox(height: 10),

              _ProfileActionTile(
                icon: Icons.logout,
                title: AppStrings.t('logout'),
                subtitle: AppStrings.t('logout_sub'),
                iconColor: Colors.redAccent,
                titleColor: Colors.redAccent,
                cardColor: cardColor,
                textColor: primaryTextColor,
                subColor: secondaryTextColor,
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  final Color cardColor;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: cardColor == Colors.white ? 3 : 0,
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: iconColor ?? const Color(0xFFE53935)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: titleColor ?? textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: subColor, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap ??
                () {
              print('Нажато: $title');
            },
      ),
    );
  }
}
