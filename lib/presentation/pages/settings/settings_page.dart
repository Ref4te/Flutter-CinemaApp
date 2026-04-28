import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/settings/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, language, child) {
            return AlertDialog(
              title: Text(AppStrings.t('choose_language')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LanguageItem(
                    title: 'Русский',
                    selected: language == 'Русский',
                    onTap: () {
                      AppSettings.setLanguage('Русский');
                      Navigator.pop(context);
                    },
                  ),
                  _LanguageItem(
                    title: 'Қазақша',
                    selected: language == 'Қазақша',
                    onTap: () {
                      AppSettings.setLanguage('Қазақша');
                      Navigator.pop(context);
                    },
                  ),
                  _LanguageItem(
                    title: 'English',
                    selected: language == 'English',
                    onTap: () {
                      AppSettings.setLanguage('English');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Cinema Booking',
      applicationVersion: '1.0.0',
      children: const [
        SizedBox(height: 12),
        Text(
          'Авторы проекта:\n'
              'Манат Ақжол\n'
              'Қарабаев Бақдәулет\n'
              'Болатов Қазыбек\n'
              'Ералиев Елнур',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, language, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.t('settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: AppStrings.t('language'),
                subtitle: language,
                onTap: () => _showLanguageDialog(context),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.notificationsEnabled,
                builder: (context, enabled, child) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_none,
                        color: Color(0xFFE53935),
                      ),
                      title: Text(AppStrings.t('notifications')),
                      subtitle: Text(
                        enabled
                            ? AppStrings.t('enabled')
                            : AppStrings.t('disabled'),
                      ),
                      value: enabled,
                      onChanged: (value) async {
                        await AppSettings.setNotificationsEnabled(value);
                        if (!value) {
                          await LocalNotificationService.instance.cancelAllReminders();
                        }
                      },
                    ),
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AppSettings.isDarkTheme,
                builder: (context, isDark, child) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SwitchListTile(
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: const Color(0xFFE53935),
                      ),
                      title: Text(AppStrings.t('theme')),
                      subtitle: Text(
                        isDark ? AppStrings.t('dark') : AppStrings.t('light'),
                      ),
                      value: isDark,
                      onChanged: (value) {
                        AppSettings.setDarkTheme(value);
                      },
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: AppStrings.t('about'),
                subtitle: AppStrings.t('authors'),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFFE53935))
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Icon(icon, color: const Color(0xFFE53935)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}