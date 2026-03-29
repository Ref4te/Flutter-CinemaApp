import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String _mockName = 'Гость';
  static const String _mockEmail = 'guest@cinemaapp.dev';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ProfileHeader(name: _mockName, email: _mockEmail),
          SizedBox(height: 16),
          _SectionTitle('Настройка профиля'),
          SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.edit_outlined,
            title: 'Изменить имя',
            subtitle: 'Пока используется заглушка, будет подключено через API',
          ),
          _ProfileActionTile(
            icon: Icons.mail_outline,
            title: 'Изменить почту',
            subtitle: 'Пока используется заглушка, будет подключено через API',
          ),
          _ProfileActionTile(
            icon: Icons.lock_outline,
            title: 'Изменить пароль',
            subtitle: 'Пока используется заглушка, будет подключено через API',
          ),
          _ProfileActionTile(
            icon: Icons.logout,
            title: 'Выйти из аккаунта',
            subtitle: 'Временно заглушка до подключения backend',
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFF8E24AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Аватар и почта временно берутся из заглушек',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
