import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('Общие'),
          _SettingsTile(icon: Icons.language_rounded, title: 'Язык интерфейса', subtitle: 'Русский'),
          _SettingsTile(icon: Icons.notifications_none_rounded, title: 'Уведомления', subtitle: 'Включены'),
          SizedBox(height: 14),
          _SectionTitle('Аккаунт'),
          _SettingsTile(icon: Icons.person_outline_rounded, title: 'Профиль', subtitle: 'Заглушка до подключения API'),
          _SettingsTile(icon: Icons.shield_outlined, title: 'Безопасность', subtitle: 'Заглушка до подключения API'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1F1F1F),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent.shade200),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
