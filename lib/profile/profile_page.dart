import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String _placeholderName = 'Иван Петров';
  static const String _placeholderEmail = 'ivan.petrov@example.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFE53935),
                  child: Icon(
                    Icons.person,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _placeholderName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  _placeholderEmail,
                  style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ProfileActionTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Настройка профиля',
            subtitle: 'Изменить имя, аватар и контактные данные',
          ),
          const _ProfileActionTile(
            icon: Icons.security_outlined,
            title: 'Безопасность',
            subtitle: 'Смена пароля и управление сессиями (заглушка)',
          ),
          const _ProfileActionTile(
            icon: Icons.payment_outlined,
            title: 'Способы оплаты',
            subtitle: 'Банковские карты и кошельки (заглушка API)',
          ),
          const _ProfileActionTile(
            icon: Icons.support_agent_outlined,
            title: 'Поддержка',
            subtitle: 'Чат и FAQ (пока заглушка)',
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
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
        onTap: () {},
      ),
    );
  }
}
