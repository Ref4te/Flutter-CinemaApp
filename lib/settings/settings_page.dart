import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _profile = _ProfileStub(
    fullName: 'Алексей К.',
    email: 'alexey.demo@cinema.app',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
  );

  static const List<_ProfileSettingItem> _settings = [
    _ProfileSettingItem(
      icon: Icons.person_outline,
      title: 'Личные данные',
      subtitle: 'Изменить имя, телефон и дату рождения',
    ),
    _ProfileSettingItem(
      icon: Icons.lock_outline,
      title: 'Безопасность',
      subtitle: 'Сменить пароль и управлять сессиями',
    ),
    _ProfileSettingItem(
      icon: Icons.payment_outlined,
      title: 'Способы оплаты',
      subtitle: 'Карты и кошельки (заглушка без API)',
    ),
    _ProfileSettingItem(
      icon: Icons.notifications_none,
      title: 'Уведомления',
      subtitle: 'Push, Email и SMS (локальная заглушка)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeaderCard(profile: _profile),
          const SizedBox(height: 16),
          const Text(
            'Настройки профиля',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._settings.map(
            (item) => _SettingsTile(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final _ProfileStub profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1D1D1D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundImage: NetworkImage(profile.avatarUrl),
              backgroundColor: const Color(0xFF2A2A2A),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Редактирование профиля будет подключено через API.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Редактировать'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF9A9A9A))),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Раздел "$title" пока работает на заглушке.')),
          );
        },
      ),
    );
  }
}

class _ProfileStub {
  const _ProfileStub({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
  });

  final String fullName;
  final String email;
  final String avatarUrl;
}

class _ProfileSettingItem {
  const _ProfileSettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
