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
        children: const [
          ListTile(
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Аккаунт'),
            subtitle: Text('Заглушка для будущих настроек профиля'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.notifications_none_rounded),
            title: Text('Уведомления'),
            subtitle: Text('Заглушка для управления уведомлениями'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.language_rounded),
            title: Text('Язык приложения'),
            subtitle: Text('Русский'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('О приложении'),
            subtitle: Text('Здесь позже появится информация о версии'),
          ),
        ],
      ),
    );
  }
}
