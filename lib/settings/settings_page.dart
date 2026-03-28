import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль и настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFF2A2A2A),
            child: Icon(Icons.person_outline, size: 44, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Text(
            'Гость',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          const _SettingsTile(
            icon: Icons.language,
            title: 'Язык интерфейса',
            subtitle: 'Русский',
          ),
          const _SettingsTile(
            icon: Icons.notifications_none,
            title: 'Уведомления',
            subtitle: 'В разработке',
          ),
          const _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Безопасность',
            subtitle: 'В разработке',
          ),
          const _SettingsTile(
            icon: Icons.help_outline,
            title: 'Помощь',
            subtitle: 'FAQ и поддержка',
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
      color: const Color(0xFF1B1B1B),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
