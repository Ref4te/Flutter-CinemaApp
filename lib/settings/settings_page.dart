import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка профиля')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Имя профиля',
            subtitle: 'Гость Кинотеатра (заглушка, сохранение позже через API)',
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'user_placeholder@cinema.app (данные пока из заглушки)',
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Пароль и безопасность',
            subtitle: 'Раздел появится после интеграции backend/API',
          ),
          _SettingsTile(
            icon: Icons.sync_problem_outlined,
            title: 'Синхронизация данных',
            subtitle: 'Сейчас используется локальный mock без БД',
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1D1D1D),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: const Color(0xFFE53935)),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF9A9A9A)),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
