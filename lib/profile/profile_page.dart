import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const userName = 'Гость CinemaApp';
    const userEmail = 'guest@cinemaapp.local';

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ProfileHeader(userName: userName, userEmail: userEmail),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_rounded),
                  title: const Text('Настройки профиля'),
                  subtitle: const Text('Изменить имя, email, пароль (заглушка)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.notifications_active_rounded),
                  title: Text('Уведомления'),
                  subtitle: Text('Настройки будут добавлены через API'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white12,
              child: Icon(
                Icons.person_rounded,
                size: 52,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              userEmail,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'Аватар и email сейчас заглушки до подключения сервиса аккаунтов.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки профиля')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingsField(label: 'Имя', value: 'Гость CinemaApp'),
          _SettingsField(label: 'Email', value: 'guest@cinemaapp.local'),
          _SettingsField(label: 'Телефон', value: '+0 (000) 000-00-00'),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Редактирование и сохранение пока работает как UI-заглушка. '
                'Интеграция с БД/API будет добавлена на следующем этапе.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit_rounded),
      ),
    );
  }
}
