import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingsTile(
            icon: Icons.language,
            title: 'Язык интерфейса',
            subtitle: 'Русский',
          ),
          _SettingsTile(
            icon: Icons.notifications_none,
            title: 'Уведомления',
            subtitle: 'Включены',
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Тема',
            subtitle: 'Тёмная',
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'О приложении',
            subtitle: 'Тут позже будет информация и API настройки',
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
