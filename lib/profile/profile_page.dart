import 'package:flutter/material.dart';

import '../settings/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String _mockName = 'Гость Кинотеатра';
  static const String _mockEmail = 'user_placeholder@cinema.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ProfileHeader(name: _mockName, email: _mockEmail),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1D1D1D),
            child: ListTile(
              leading: const Icon(
                Icons.manage_accounts_outlined,
                color: Color(0xFFE53935),
              ),
              title: const Text('Настройка профиля'),
              subtitle: const Text(
                'Пока используем заглушки, API и БД подключим позже',
                style: TextStyle(color: Color(0xFF9A9A9A)),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.cloud_off_outlined,
            title: 'Статус синхронизации',
            subtitle: 'Работаем в офлайн-режиме с локальными заглушками',
          ),
          const _InfoCard(
            icon: Icons.verified_user_outlined,
            title: 'Безопасность аккаунта',
            subtitle: '2FA и смена пароля будут доступны после API',
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFF2B2B2B),
            child: Icon(
              Icons.person,
              size: 44,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
      ),
    );
  }
}
