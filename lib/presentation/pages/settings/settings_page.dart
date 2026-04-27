import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../data/repositories/booking_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String _adminEmail = 'manat11@mail.ru';
  static const String _allMoviesScope = 'для всех фильмов';

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
                      AppSettings.language.value = 'Русский';
                      Navigator.pop(context);
                    },
                  ),
                  _LanguageItem(
                    title: 'Қазақша',
                    selected: language == 'Қазақша',
                    onTap: () {
                      AppSettings.language.value = 'Қазақша';
                      Navigator.pop(context);
                    },
                  ),
                  _LanguageItem(
                    title: 'English',
                    selected: language == 'English',
                    onTap: () {
                      AppSettings.language.value = 'English';
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
        final user = FirebaseAuth.instance.currentUser;
        final isAdmin = user?.email == _adminEmail;

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
                      onChanged: (value) {
                        AppSettings.notificationsEnabled.value = value;
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
                        AppSettings.isDarkTheme.value = value;
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
              if (isAdmin) ...[
                const SizedBox(height: 8),
                const Text(
                  'Настройки администратора',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _AdminActionTile(
                  icon: Icons.delete_forever,
                  title: 'Полное удаление сеансов',
                  subtitle: 'Область действия: $_allMoviesScope',
                  color: Colors.redAccent,
                  onTap: () => _confirmAdminAction(
                    context: context,
                    title: 'Удалить все сеансы',
                    description:
                        'Будут удалены все сеансы и связанные билеты ($_allMoviesScope). Продолжить?',
                    action: () => BookingRepository().deleteSessions(),
                    successMessage:
                        'Все сеансы и связанные билеты удалены ($_allMoviesScope).',
                  ),
                ),
                _AdminActionTile(
                  icon: Icons.event_seat_outlined,
                  title: 'Удаление брони',
                  subtitle: 'Сброс занятых мест, сеансы остаются активными',
                  color: Colors.orangeAccent,
                  onTap: () => _confirmAdminAction(
                    context: context,
                    title: 'Очистить брони',
                    description:
                        'Все места будут помечены как свободные, а билеты удалены ($_allMoviesScope). Продолжить?',
                    action: () => BookingRepository().clearBookedSeats(),
                    successMessage:
                        'Брони очищены, сеансы оставлены активными ($_allMoviesScope).',
                  ),
                ),
                _AdminActionTile(
                  icon: Icons.auto_fix_high,
                  title: 'Генерация расписания',
                  subtitle:
                      '3 дня, 3 зала, шаг 20 минут, часы работы 10:00–01:00',
                  color: const Color(0xFFE53935),
                  onTap: () => _confirmAdminAction(
                    context: context,
                    title: 'Сгенерировать расписание',
                    description:
                        'Будет сгенерировано случайное расписание на 3 дня для всех фильмов.',
                    action: () => BookingRepository().generateScheduleForAdmin(),
                    successMessage:
                        'Расписание сгенерировано: 3 дня, 3 зала, интервал 20 минут.',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAdminAction({
    required BuildContext context,
    required String title,
    required String description,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
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

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
